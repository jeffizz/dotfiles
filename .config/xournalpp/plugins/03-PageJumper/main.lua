local metadata = require("metadata")

local savedPages = {}
local teleportStations = {}
local lastClickTime = 0

local slotStates = {
	[1] = { lastTime = 0, originPage = 0 },
	[2] = { lastTime = 0, originPage = 0 },
	[3] = { lastTime = 0, originPage = 0 },
}

local metadataCache = {
	fileKey = nil,
	db = nil,
}

pendingJumpContext = nil
pendingJumpTargets = nil

local ITEMS_PER_PAGE = 8

local function getTmpDir()
	local dir = os.getenv("TMPDIR") or os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
	if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
		return dir:sub(1, -2)
	end
	return dir
end

local dataFile = getTmpDir() .. "/xournalpp_saved_pages.lua"

local function showNote(msg)
	if app.openDialog then
		app.openDialog(msg, { ["OK"] = "ok" })
	end
end

local function getFileKey()
	local doc = app.getDocumentStructure()
	local path = (doc.pdfBackgroundFilename and doc.pdfBackgroundFilename ~= "") and doc.pdfBackgroundFilename
		or "default"
	local hash = 0
	for i = 1, #path do
		hash = (hash * 31 + string.byte(path, i)) % 2147483647
	end
	return tostring(hash)
end

local function fetchMetadata()
	local currentKey = getFileKey()
	if metadataCache.fileKey == currentKey and metadataCache.db then
		return metadataCache.db
	end
	local text = metadata.getMetadataText()
	local db = metadata.parseINI(text)
	metadataCache.fileKey = currentKey
	metadataCache.db = db
	return db
end

local function updateMetadata(db)
	if metadata.writeMetadata(db) then
		metadataCache.db = db
		return true
	end
	return false
end

local function getClipboardText()
	local os_name = package.config:sub(1, 1) == "\\" and "win" or "unix"
	local text = ""
	if os_name == "win" then
		local f = io.popen("powershell -command Get-Clipboard", "r")
		if f then
			text = f:read("*a")
			f:close()
		end
	else
		local f = io.popen("uname -s", "r")
		local uname = f and f:read("*a") or ""
		if f then
			f:close()
		end
		if uname:match("Darwin") then
			f = io.popen("pbpaste 2>/dev/null", "r")
			if f then
				text = f:read("*a")
				f:close()
			end
		else
			f = io.popen("xclip -selection clipboard -o 2>/dev/null", "r")
			if f then
				text = f:read("*a")
				f:close()
			end
			if not text or text == "" then
				f = io.popen("wl-paste 2>/dev/null", "r")
				if f then
					text = f:read("*a")
					f:close()
				end
			end
		end
	end
	return text and text:match("^%s*(.-)%s*$") or ""
end

function processClipboardConfig()
	local txt = getClipboardText()
	local db = fetchMetadata()
	db["Common"] = db["Common"] or {}
	db["PageJumpper"] = db["PageJumpper"] or {}

	if txt:match("[/\\]mutool%.?e?x?e?$") or txt:match("^mutool$") then
		db["Common"]["MutoolPath"] = txt
		if updateMetadata(db) then
			showNote("✅ Mutool path configured:\n" .. txt)
		end
	elseif tonumber(txt) then
		db["PageJumpper"]["PrintedOffset"] = txt
		if updateMetadata(db) then
			showNote("✅ Printed offset set to: " .. txt)
		end
	else
		showNote("❓ Unrecognized clipboard content.\nProvide a mutool path or a numeric offset.")
	end
end

local function extractNumbersFromPage(doc, current)
	local uniqueNums = {}
	local db = fetchMetadata()
	local mutoolExec = (db["Common"] and db["Common"]["MutoolPath"]) or "mutool"

	local allTexts = app.getTexts("page") or {}
	for _, txt in pairs(allTexts) do
		if type(txt) == "table" and txt.text then
			for numStr in txt.text:gmatch("%f[%w][Pp]age%s*(%d+)") do
				uniqueNums[tonumber(numStr)] = true
			end
			for numStr in txt.text:gmatch("%f[%w][Pp]%s*(%d+)") do
				uniqueNums[tonumber(numStr)] = true
			end
		end
	end

	local pageInfo = doc.pages[current]
	local pdfBgNo = pageInfo and pageInfo.pdfBackgroundPageNo or 0
	local pdfPath = doc.pdfBackgroundFilename

	if pdfPath and pdfPath ~= "" and pdfBgNo > 0 then
		local os_name = package.config:sub(1, 1) == "\\" and "win" or "unix"
		local safePath = '"' .. pdfPath:gsub('"', '\\"') .. '"'
		local cmd = string.format(
			'"%s" draw -F txt -o - %s %d 2>%s',
			mutoolExec,
			safePath,
			pdfBgNo,
			os_name == "win" and "nul" or "/dev/null"
		)

		local f = io.popen(cmd, "r")
		if f then
			local pdfText = f:read("*a")
			f:close()
			if pdfText and pdfText ~= "" then
				for numStr in pdfText:gmatch("%f[%w][%w]?[Pp]age%s*(%d+)") do
					uniqueNums[tonumber(numStr)] = true
				end
				for numStr in pdfText:gmatch("%f[%w][Pp]%s*(%d+)") do
					uniqueNums[tonumber(numStr)] = true
				end
			end
		end
	end

	local nums = {}
	for n, _ in pairs(uniqueNums) do
		table.insert(nums, n)
	end
	table.sort(nums)
	return nums
end

local function scrollToPage(target)
	if target and target > 0 then
		app.scrollToPage(target, false)
	end
end

function renderJumpDialog()
	if not pendingJumpContext then
		return
	end

	local items = pendingJumpContext.allTargets
	local totalItems = #items
	local totalPages = math.ceil(totalItems / ITEMS_PER_PAGE)
	local p = pendingJumpContext.dialogPage

	local startIdx = (p - 1) * ITEMS_PER_PAGE + 1
	local endIdx = math.min(p * ITEMS_PER_PAGE, totalItems)

	local dialogOptions = {}
	local dialogTargets = {}

	if p > 1 then
		table.insert(dialogOptions, "⬅️ Prev")
		table.insert(dialogTargets, "prev")
	end

	for i = startIdx, endIdx do
		table.insert(dialogOptions, items[i].label)
		table.insert(dialogTargets, items[i].target)
	end

	if p < totalPages then
		table.insert(dialogOptions, "Next ➡️")
		table.insert(dialogTargets, "next")
	end

	table.insert(dialogOptions, "🚫 Cancel")
	table.insert(dialogTargets, "cancel")

	pendingJumpTargets = dialogTargets

	local title = ""
	if totalPages > 1 then
		title = string.format("Smart Jump (Mode %d) - Page %d/%d:", pendingJumpContext.mode, p, totalPages)
	else
		title = string.format("Smart Jump (Mode %d):", pendingJumpContext.mode)
	end

	app.openDialog(title, dialogOptions, "handleJumpDialogResult")
end

function handleJumpDialogResult(selectedIndex)
	if not pendingJumpContext or not pendingJumpTargets or not selectedIndex then
		return
	end
	local idx = tonumber(selectedIndex)
	if not idx then
		return
	end

	local target = pendingJumpTargets[idx] or pendingJumpTargets[idx + 1]

	if target == "next" then
		pendingJumpContext.dialogPage = pendingJumpContext.dialogPage + 1
		renderJumpDialog()
		return
	elseif target == "prev" then
		pendingJumpContext.dialogPage = pendingJumpContext.dialogPage - 1
		renderJumpDialog()
		return
	elseif target == "cancel" then
		pendingJumpContext = nil
		pendingJumpTargets = nil
		return
	elseif target then
		local key = getFileKey()
		if not teleportStations[key] then
			teleportStations[key] = { a = 0, b = 0 }
		end
		teleportStations[key].a = pendingJumpContext.origin
		scrollToPage(target)
	end

	pendingJumpContext = nil
	pendingJumpTargets = nil
end

local function findInternalPageByPdfNo(targetPdfNo, doc)
	if targetPdfNo <= 0 then
		return nil
	end
	for i = 1, #doc.pages do
		if doc.pages[i].pdfBackgroundPageNo == targetPdfNo then
			return i
		end
	end
	return nil
end

function autoParseAndJump()
	local doc = app.getDocumentStructure()
	if not doc or not doc.pages then
		return
	end

	local current = doc.currentPage
	local db = fetchMetadata()
	local pdfPath = doc.pdfBackgroundFilename

	local mode = 1
	local printedOffset = 0

	if pdfPath and pdfPath ~= "" then
		if db["PageJumpper"] and db["PageJumpper"]["PrintedOffset"] then
			mode = 3
			printedOffset = tonumber(db["PageJumpper"]["PrintedOffset"]) or 0
		else
			mode = 2
		end
	end

	local nums = extractNumbersFromPage(doc, current)
	if #nums == 0 then
		showNote("🔍 No page markers found on the current page.")
		return
	end

	local allTargets = {}

	for _, n in ipairs(nums) do
		local targetInternal = nil
		if mode == 1 then
			if n > 0 and n <= #doc.pages then
				targetInternal = n
			end
		else
			local targetPdfNo = (mode == 3) and (n + printedOffset) or n
			targetInternal = findInternalPageByPdfNo(targetPdfNo, doc)
		end

		if targetInternal then
			table.insert(allTargets, { label = string.format("P%d", n), target = targetInternal })
		end
	end

	if #allTargets == 0 then
		showNote("❌ Parsed successfully but unable to locate target page.")
		return
	end

	pendingJumpContext = {
		origin = current,
		mode = mode,
		allTargets = allTargets,
		dialogPage = 1,
	}

	renderJumpDialog()
end

function toggleTeleport()
	local key = getFileKey()
	local current = app.getDocumentStructure().currentPage
	local now = os.clock()
	if (now - lastClickTime) < 0.2 then
		teleportStations[key] = nil
		showNote("Teleport Points Reset")
		lastClickTime = 0
		return
	end
	lastClickTime = now
	if not teleportStations[key] then
		teleportStations[key] = { a = 0, b = 0 }
	end
	local tp = teleportStations[key]
	if tp.a == 0 then
		tp.a = current
		showNote("Point A set: " .. current)
	elseif tp.b == 0 then
		if current == tp.a then
			showNote("Point B not set.")
		else
			tp.b = current
			scrollToPage(tp.a)
		end
	else
		local distA = math.abs(current - tp.a)
		local distB = math.abs(current - tp.b)
		if distA <= distB then
			tp.a = current
			scrollToPage(tp.b)
		else
			tp.b = current
			scrollToPage(tp.a)
		end
	end
end

local function handleSlotAction(slot)
	local key = getFileKey()
	local current = app.getDocumentStructure().currentPage
	local now = os.clock()
	local state = slotStates[slot]
	if (now - state.lastTime) < 0.5 then
		local targetToSave = state.originPage
		if current ~= targetToSave then
			app.scrollToPage(targetToSave, false)
		end
		if not savedPages[key] then
			savedPages[key] = {}
		end
		if type(savedPages[key][0]) == "table" and #savedPages[key][0] > 0 then
			if savedPages[key][0][#savedPages[key][0]] == targetToSave then
				table.remove(savedPages[key][0])
			end
		end
		savedPages[key][slot] = targetToSave
		saveSavedPages()
		showNote("✅ Slot " .. slot .. " Saved")
		state.lastTime = 0
	else
		state.lastTime = now
		state.originPage = current
		if savedPages[key] and savedPages[key][slot] then
			local key = getFileKey()
			if not teleportStations[key] then
				teleportStations[key] = { a = 0, b = 0 }
			end
			teleportStations[key].a = current
			scrollToPage(savedPages[key][slot])
		end
	end
end

function slotAction1()
	handleSlotAction(1)
end
function slotAction2()
	handleSlotAction(2)
end
function slotAction3()
	handleSlotAction(3)
end

function gotoPage()
	local key = getFileKey()
	teleportStations[key] = { a = 0, b = 0 }
	teleportStations[key].a = app.getDocumentStructure().currentPage
	app.activateAction("goto-page")
end

function showPageInfo()
	local doc = app.getDocumentStructure()
	if not doc then
		return
	end
	local pageNo = doc.currentPage or 0
	local page = doc.pages[pageNo] or {}
	local db = fetchMetadata()
	local mutoolPath = (db["Common"] and db["Common"]["MutoolPath"]) or "mutool"

	local width = page.pageWidth or "Unknown"
	local height = page.pageHeight or "Unknown"
	local format = page.pageTypeFormat or "Unknown"
	local config = page.pageTypeConfig or "Unknown"
	local bgColor = page.backgroundColor or "Unknown"
	local pdfBgPage = page.pdfBackgroundPageNo or 0
	local isAnnotated = page.isAnnotated and "true" or "false"

	showNote(
		string.format(
			"📄 Page: %d / %d\n"
				.. "🖼️ pdfPageNo: %s\n"
				.. "🛠️ Mutool: %s\n"
				.. "📏 Size (W x H): %s x %s\n"
				.. "📝 pageTypeFormat: %s\n"
				.. "⚙️ pageTypeConfig: %s\n"
				.. "🎨 backgroundColor: %s\n",
			pageNo,
			#doc.pages,
			tostring(pdfBgPage),
			mutoolPath,
			tostring(width),
			tostring(height),
			tostring(format),
			tostring(config),
			tostring(bgColor)
		)
	)
end

function loadSavedPages()
	local file = io.open(dataFile, "r")
	if file then
		local content = file:read("*a")
		file:close()
		local chunk = load(content)
		if chunk then
			savedPages = chunk()
		end
	end
	if not savedPages then
		savedPages = {}
	end
end

function saveSavedPages()
	local file = io.open(dataFile, "w")
	if file then
		file:write("return " .. serializeTable(savedPages))
		file:close()
	end
end

function serializeTable(val)
	if type(val) == "table" then
		local res = "{"
		for k, v in pairs(val) do
			local k_str = (type(k) == "string") and '["' .. k .. '"]' or "[" .. k .. "]"
			res = res .. k_str .. "=" .. serializeTable(v) .. ","
		end
		return res .. "}"
	elseif type(val) == "string" then
		return '"' .. val .. '"'
	else
		return tostring(val)
	end
end

function initUi()
	app.registerUi({ ["menu"] = "Teleport: Switch A/B", ["callback"] = "toggleTeleport", ["accelerator"] = "<Alt>w" })
	app.registerUi({ ["menu"] = "Slot 1 (Save/Go)", ["callback"] = "slotAction1", ["accelerator"] = "<Alt>1" })
	app.registerUi({ ["menu"] = "Slot 2 (Save/Go)", ["callback"] = "slotAction2", ["accelerator"] = "<Alt>2" })
	app.registerUi({ ["menu"] = "Slot 3 (Save/Go)", ["callback"] = "slotAction3", ["accelerator"] = "<Alt>3" })
	app.registerUi({ ["menu"] = "Smart Jump", ["callback"] = "autoParseAndJump", ["accelerator"] = "<Alt>g" })
	app.registerUi({ ["menu"] = "Go to Page (g)", ["callback"] = "gotoPage", ["accelerator"] = "g" })

	app.registerUi({ ["menu"] = "Config from Clipboard (Path/Offset)", ["callback"] = "processClipboardConfig" })
	app.registerUi({ ["menu"] = "Debug: Page Info", ["callback"] = "showPageInfo" })

	loadSavedPages()
end
