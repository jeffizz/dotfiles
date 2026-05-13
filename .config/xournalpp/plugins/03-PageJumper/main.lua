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

function utf8sub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local byte = string.byte(str, startIndex)
		startIndex = startIndex + getByteCount(byte)
		startChar = startChar - 1
	end

	local currentIndex = startIndex
	while numChars > 0 and currentIndex <= #str do
		local byte = string.byte(str, currentIndex)
		currentIndex = currentIndex + getByteCount(byte)
		numChars = numChars - 1
	end

	return str:sub(startIndex, currentIndex - 1)
end

function getByteCount(byte)
	if byte >= 0 and byte <= 127 then
		return 1
	elseif byte >= 192 and byte <= 223 then
		return 2
	elseif byte >= 224 and byte <= 239 then
		return 3
	elseif byte >= 240 and byte <= 247 then
		return 4
	end
	return 1
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

	local message = ""
	local prefix = (pendingJumpContext.mode == "search") and "🔍 Search Results"
		or string.format("Smart Jump (Mode %d)", pendingJumpContext.mode)

	if totalPages > 1 then
		message = string.format("%s (Page %d/%d):\n\n", prefix, p, totalPages)
	else
		message = string.format("%s:\n\n", prefix)
	end

	if p > 1 then
		table.insert(dialogOptions, "⬅️ Prev")
		table.insert(dialogTargets, "prev")
	end

	local term = pendingJumpContext.searchTerm or ""

	for i = startIdx, endIdx do
		table.insert(dialogOptions, items[i].label)
		table.insert(dialogTargets, items[i].target)
		if items[i].snippet then
			local snippet = utf8sub(items[i].snippet, 1, 100)
			local highlightedSnippet = highlightKeyword(snippet, term)
			message = message .. string.format("[%s%d] %s\n", items[i].prefix, items[i].pageNo, highlightedSnippet)
		end
	end

	if p < totalPages then
		table.insert(dialogOptions, "Next ➡️")
		table.insert(dialogTargets, "next")
	end

	table.insert(dialogOptions, "🚫 Cancel")
	table.insert(dialogTargets, "cancel")

	pendingJumpTargets = dialogTargets

	app.openDialog(message, dialogOptions, "handleJumpDialogResult")
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

function highlightKeyword(text, term)
	if not text or not term or term == "" then
		return text
	end

	local escapedTerm = term:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")

	local caseInsensitivePattern = escapedTerm:gsub("%a", function(char)
		return string.format("[%s%s]", string.lower(char), string.upper(char))
	end)

	local pattern = "(" .. caseInsensitivePattern .. ")"
	local highlighted, _ = text:gsub(pattern, "⭐%1", 1)
	return highlighted
end

function searchAndJump()
	local doc = app.getDocumentStructure()
	if not doc or not doc.pages then
		return
	end

	local current = doc.currentPage
	local pdfPath = doc.pdfBackgroundFilename
	local pdfToInternalMap = buildPdfToInternalMap(doc)

	if not pdfPath or pdfPath == "" then
		showNote("❌ No PDF background found for search.")
		return
	end

	local txt = getClipboardText()
	if not txt or txt == "" then
		showNote("❌ Clipboard is empty.")
		return
	end

	local db = fetchMetadata()
	local mutoolExec = (db["Common"] and db["Common"]["MutoolPath"]) or "mutool"
	local printedOffset = tonumber(db["PageJumpper"] and db["PageJumpper"]["PrintedOffset"]) or 0

	local os_name = package.config:sub(1, 1) == "\\" and "win" or "unix"
	local nullDev = os_name == "win" and "nul" or "/dev/null"
	local safePath = '"' .. pdfPath:gsub('"', '\\"') .. '"'

	local safeTerm = ""
	if os_name == "win" then
		safeTerm = '"' .. txt:gsub('"', '""') .. '"'
	else
		safeTerm = "'" .. txt:gsub("'", "'\\''") .. "'"
	end

	local searchTerm = txt:lower()
	local allTargets = {}

	-- --- A: mutool PDF search ---
	local seenPages = {}

	local cmd = string.format('"%s" grep -i -n %s %s 2>%s', mutoolExec, safeTerm, safePath, nullDev)
	local f = io.popen(cmd, "r")
	if f then
		local output = f:read("*a")
		f:close()

		for line in output:gmatch("[^\r\n]+") do
			local pageStr, lineTxt = line:match("^(%d+)%s+(.*)$")
			if pageStr then
				local pageNo = tonumber(pageStr)

				if not seenPages[pageNo] then
					local targetInternal = pdfToInternalMap[pageNo]
					if targetInternal then
						seenPages[pageNo] = true
						local displayPageNo = pageNo - printedOffset
						table.insert(allTargets, {
							label = string.format("P%d", displayPageNo),
							target = targetInternal,
							pageNo = displayPageNo,
							prefix = "P",
							snippet = lineTxt,
						})
					end
				end
			end
		end
	end

	-- --- B: Xournal++ Note Search ---
	local seenXoPages = {}
	local allXoppTexts = app.getTexts("all") or {}
	for _, txtObj in pairs(allXoppTexts) do
		if type(txtObj) == "table" and txtObj.text and txtObj.text:lower():find(searchTerm, 1, true) then
			local xoPage = txtObj.page
			if not seenXoPages[xoPage] then
				seenXoPages[xoPage] = true
				table.insert(allTargets, {
					label = string.format("X%d", xoPage),
					target = xoPage,
					pageNo = xoPage,
					prefix = "X",
					snippet = txtObj.text:gsub("[\r\n]+", " "),
				})
			end
		end
	end

	if #allTargets == 0 then
		local displayTxt = #txt > 20 and (txt:sub(1, 20) .. "...") or txt
		showNote("🔍 Text not found in PDF:\n" .. displayTxt)
		return
	end

	table.sort(allTargets, function(a, b)
		return a.target < b.target
	end)

	pendingJumpContext = {
		origin = current,
		mode = "search",
		allTargets = allTargets,
		searchTerm = txt,
		dialogPage = 1,
	}

	renderJumpDialog()
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
	local pdfToInternalMap = buildPdfToInternalMap(doc)

	for _, n in ipairs(nums) do
		local targetInternal = nil
		if mode == 1 then
			if n > 0 and n <= #doc.pages then
				targetInternal = n
			end
		else
			local targetPdfNo = (mode == 3) and (n + printedOffset) or n
			targetInternal = pdfToInternalMap[targetPdfNo]
		end

		if targetInternal then
			table.insert(allTargets, {
				label = string.format("P%d", n),
				target = targetInternal,
				pageNo = n,
			})
		end
	end

	if #allTargets == 0 then
		showNote("❌ Parsed successfully but unable to locate target page.")
		return
	end

	pendingJumpContext = { origin = current, mode = mode, allTargets = allTargets, dialogPage = 1 }
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

	showNote(
		string.format(
			"📄 Page: %d / %d\n🖼️ pdfPageNo: %s\n🛠️ Mutool: %s\n📏 Size: %s x %s\n📝 Format: %s\n🎨 BgColor: %s",
			pageNo,
			#doc.pages,
			tostring(pdfBgPage),
			mutoolPath,
			tostring(width),
			tostring(height),
			tostring(format),
			tostring(bgColor)
		)
	)
end

function buildPdfToInternalMap(doc)
	local map = {}
	if not doc or not doc.pages then
		return map
	end
	for i = 1, #doc.pages do
		local bgNo = doc.pages[i].pdfBackgroundPageNo
		if bgNo and bgNo > 0 and not map[bgNo] then
			map[bgNo] = i
		end
	end
	return map
end

local function parseOutlineTree(text, printedOffset, pdfToInternalMap)
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		if not line:match("^warning:") then
			table.insert(lines, line)
		end
	end

	local root = { children = {}, title = "ROOT", level = -1 }
	local stack = { [-1] = root }

	local isFlat = not text:match("[%+%-]")
	local startRecording = isFlat

	for _, line in ipairs(lines) do
		local symbol, indent, title, page = line:match('^([%+|%-])(%s*)"(.*)".-#page=(%d+)')
		if symbol then
			local level = #indent
			local isLeaf = (symbol == "|")
			local targetPage = tonumber(page)
			local displayPage = targetPage - (printedOffset or 0)
			local targetInternal = pdfToInternalMap[targetPage]
			local node = {
				title = title,
				targetPage = targetInternal,
				displayPage = displayPage,
				isLeaf = isLeaf,
				level = level,
				children = {},
			}

			if not startRecording and not isLeaf then
				startRecording = true
			end

			if startRecording then
				local parentLevel = level - 1
				while parentLevel >= -1 and not stack[parentLevel] do
					parentLevel = parentLevel - 1
				end
				local parent = stack[parentLevel] or root

				table.insert(parent.children, node)
				stack[level] = node

				for i = level + 1, 20 do
					stack[i] = nil
				end
			end
		end
	end
	return root
end

local function getChapterPrefix(title)
	local t = title:match("^[ \t]*(.-)[ \t]*$")
	if not t or t == "" then
		return nil
	end

	local colon_pos = t:find("：")
	local eng_colon = t:find(":")

	local first_colon = nil
	if colon_pos and eng_colon then
		first_colon = math.min(colon_pos, eng_colon)
	else
		first_colon = colon_pos or eng_colon
	end

	if first_colon and first_colon <= 30 then
		local prefix = t:sub(1, first_colon - 1)
		prefix = prefix:match("^[ \t]*(.-)[ \t]*$")
		if prefix and prefix ~= "" then
			return prefix
		end
	end

	local min_pos = #t + 1
	local function checkPos(pos)
		if pos and pos < min_pos then
			min_pos = pos
		end
	end

	checkPos(t:find(" "))
	checkPos(t:find("\t"))
	checkPos(t:find("\227\128\128"))
	checkPos(t:find("\194\160"))

	if min_pos <= #t then
		local prefix = t:sub(1, min_pos - 1)
		if prefix ~= "" then
			return prefix
		end
	end

	return nil
end

function renderOutlineDialog()
	if not pendingJumpContext or not pendingJumpContext.allNodes then
		return
	end

	local nodes = pendingJumpContext.allNodes
	local totalItems = #nodes
	local totalPages = math.ceil(totalItems / ITEMS_PER_PAGE)
	local p = pendingJumpContext.dialogPage

	local startIdx = (p - 1) * ITEMS_PER_PAGE + 1
	local endIdx = math.min(p * ITEMS_PER_PAGE, totalItems)

	local dialogOptions = {}
	local dialogTargets = {}

	local message = "📖 Outline: " .. pendingJumpContext.parentTitle .. "\n"
	if totalPages > 1 then
		message = message .. "(Page " .. p .. "/" .. totalPages .. ")\n"
	end
	message = message .. "\n"

	if pendingJumpContext.history and #pendingJumpContext.history > 0 then
		table.insert(dialogOptions, "⬆️ Back")
		table.insert(dialogTargets, "back")
	end
	if p > 1 then
		table.insert(dialogOptions, "⬅️ Prev")
		table.insert(dialogTargets, "prev")
	end

	for i = startIdx, endIdx do
		local node = nodes[i]
		local marker = (node.isLeaf or #node.children == 0) and "" or "📂"
		local prefix = getChapterPrefix(node.title)
		local btnLabel = ""
		if prefix then
			btnLabel = string.format("%s%s", prefix, marker)
		else
			btnLabel = string.format("P%d%s", node.displayPage, marker)
		end
		table.insert(dialogOptions, btnLabel)
		table.insert(dialogTargets, i)
		message = message .. string.format("[P%d]\t %s%s\n", node.displayPage, node.title, marker)
	end

	if p < totalPages then
		table.insert(dialogOptions, "Next ➡️")
		table.insert(dialogTargets, "next")
	end

	table.insert(dialogOptions, "🚫 Close")
	table.insert(dialogTargets, "cancel")

	pendingJumpTargets = dialogTargets
	app.openDialog(message, dialogOptions, "handleOutlineDialogResult")
end

function handleOutlineDialogResult(selectedIndex)
	if not pendingJumpContext or not pendingJumpTargets or not selectedIndex then
		return
	end
	local idx = tonumber(selectedIndex)
	if not idx then
		return
	end

	local cmd = pendingJumpTargets[idx] or pendingJumpTargets[idx + 1]

	if cmd == "next" then
		pendingJumpContext.dialogPage = pendingJumpContext.dialogPage + 1
		renderOutlineDialog()
	elseif cmd == "prev" then
		pendingJumpContext.dialogPage = pendingJumpContext.dialogPage - 1
		renderOutlineDialog()
	elseif cmd == "cancel" then
		pendingJumpContext = nil
	elseif cmd == "back" then
		local lastContext = table.remove(pendingJumpContext.history)
		pendingJumpContext.allNodes = lastContext.nodes
		pendingJumpContext.parentTitle = lastContext.title
		pendingJumpContext.dialogPage = lastContext.page or 1
		renderOutlineDialog()
	elseif type(cmd) == "number" then
		local selectedNode = pendingJumpContext.allNodes[cmd]

		if selectedNode.isLeaf or #selectedNode.children == 0 then
			local key = getFileKey()
			if not teleportStations[key] then
				teleportStations[key] = { a = 0, b = 0 }
			end
			teleportStations[key].a = app.getDocumentStructure().currentPage
			scrollToPage(selectedNode.targetPage)
			pendingJumpContext = nil
		else
			table.insert(pendingJumpContext.history, {
				nodes = pendingJumpContext.allNodes,
				title = pendingJumpContext.parentTitle,
				page = pendingJumpContext.dialogPage,
			})
			pendingJumpContext.allNodes = selectedNode.children
			pendingJumpContext.parentTitle = selectedNode.title
			pendingJumpContext.dialogPage = 1
			renderOutlineDialog()
		end
	end
end

function showPdfOutline()
	local doc = app.getDocumentStructure()
	if not doc or not doc.pdfBackgroundFilename or doc.pdfBackgroundFilename == "" then
		showNote("❌ No PDF background found.")
		return
	end

	local db = fetchMetadata()
	local mutoolExec = db["Common"] and db["Common"]["MutoolPath"]

	if not mutoolExec or mutoolExec == "" then
		showNote(
			"⚠️ Mutool is not configured!\n\nPlease copy the mutool executable path to your clipboard, then use the menu:\n[Config from Clipboard (Path/Offset)]"
		)
		return
	end
	local printedOffset = tonumber(db["PageJumpper"] and db["PageJumpper"]["PrintedOffset"]) or 0

	local os_name = package.config:sub(1, 1) == "\\" and "win" or "unix"
	local safePath = '"' .. doc.pdfBackgroundFilename:gsub('"', '\\"') .. '"'

	local cmd =
		string.format('"%s" show %s outline 2>%s', mutoolExec, safePath, os_name == "win" and "nul" or "/dev/null")

	local f = io.popen(cmd, "r")
	if not f then
		showNote("❌ Failed to run mutool.")
		return
	end
	local output = f:read("*a")
	f:close()

	if not output or output == "" then
		showNote("🔍 No outline found in this PDF.")
		return
	end

	local pdfToInternalMap = buildPdfToInternalMap(doc)
	local tree = parseOutlineTree(output, printedOffset, pdfToInternalMap)
	if #tree.children == 0 then
		showNote("🔍 Outline is empty after filtering.")
		return
	end

	pendingJumpContext = {
		origin = doc.currentPage,
		mode = "outline",
		parentTitle = "Table of Contents",
		allNodes = tree.children,
		dialogPage = 1,
		history = {},
	}

	renderOutlineDialog()
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
	app.registerUi({ ["menu"] = "PDF Outline", ["callback"] = "showPdfOutline", ["accelerator"] = "<Alt>a" })
	app.registerUi({ ["menu"] = "Clipboard Search", ["callback"] = "searchAndJump", ["accelerator"] = "<Alt>f" })
	app.registerUi({ ["menu"] = "Smart Jump", ["callback"] = "autoParseAndJump", ["accelerator"] = "<Alt>g" })
	app.registerUi({ ["menu"] = "Go to Page (g)", ["callback"] = "gotoPage", ["accelerator"] = "g" })
	app.registerUi({ ["menu"] = "Config from Clipboard (Path/Offset)", ["callback"] = "processClipboardConfig" })
	app.registerUi({ ["menu"] = "Debug: Page Info", ["callback"] = "showPageInfo" })

	loadSavedPages()
end
