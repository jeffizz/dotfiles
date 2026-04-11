local savedPages = {}
local teleportStations = {}
local lastClickTime = 0

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
	elseif app.msgbox then
		app.msgbox(msg, { [1] = "OK" })
	end
end

function initUi()
	-- 1. Stack
	app.registerUi({
		["menu"] = "Back to Previous Position",
		["callback"] = "popPage0",
		["accelerator"] = "<Alt>q",
	})

	-- 2. Teleport Pads
	app.registerUi({
		["menu"] = "Teleport: Switch A/B",
		["callback"] = "toggleTeleport",
		["accelerator"] = "<Alt>w",
	})

	-- 3. Slots
	app.registerUi({ ["menu"] = "Save to Slot 1", ["callback"] = "SaveSlot1", ["accelerator"] = "<Alt>z" })
	app.registerUi({ ["menu"] = "Go to Slot 1", ["callback"] = "returnToSlot1", ["accelerator"] = "<Alt>1" })
	app.registerUi({ ["menu"] = "Save to Slot 2", ["callback"] = "SaveSlot2", ["accelerator"] = "<Alt>x" })
	app.registerUi({ ["menu"] = "Go to Slot 2", ["callback"] = "returnToSlot2", ["accelerator"] = "<Alt>2" })
	app.registerUi({ ["menu"] = "Save to Slot 3", ["callback"] = "SaveSlot3", ["accelerator"] = "<Alt>c" })
	app.registerUi({ ["menu"] = "Go to Slot 3", ["callback"] = "returnToSlot3", ["accelerator"] = "<Alt>3" })

	loadSavedPages()
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

function getFileKey()
	local doc = app.getDocumentStructure()
	local path = (doc.pdfBackgroundFilename and doc.pdfBackgroundFilename ~= "") and doc.pdfBackgroundFilename
		or "default"
	local hash = 0
	for i = 1, #path do
		hash = (hash * 31 + string.byte(path, i)) % 2147483647
	end
	return tostring(hash)
end

function gotoPage(target)
	if target and target > 0 then
		app.scrollToPage(target, false)
	end
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
	elseif current == tp.a then
		if tp.b ~= 0 then
			gotoPage(tp.b)
		else
			showNote("Point B not set. Move to another page and press Alt+W.")
		end
	elseif tp.b == 0 or current ~= tp.b then
		tp.b = current
		gotoPage(tp.a)
	else
		gotoPage(tp.a)
	end
end

function popPage0()
	local key = getFileKey()
	if savedPages[key] and savedPages[key][0] and #savedPages[key][0] > 0 then
		local target = table.remove(savedPages[key][0])
		saveSavedPages()
		gotoPage(target)
	end
end

function pushPage0()
	local key = getFileKey()
	local current = app.getDocumentStructure().currentPage
	if not savedPages[key] then
		savedPages[key] = {}
	end
	if type(savedPages[key][0]) ~= "table" then
		savedPages[key][0] = {}
	end

	local stack = savedPages[key][0]
	if #stack == 0 or stack[#stack] ~= current then
		table.insert(stack, current)
		if #stack > 50 then
			table.remove(stack, 1)
		end
		saveSavedPages()
	end
end

function SaveSlot(slot)
	local key = getFileKey()
	local current = app.getDocumentStructure().currentPage
	if not savedPages[key] then
		savedPages[key] = {}
	end
	savedPages[key][slot] = current
	saveSavedPages()
	showNote("Slot " .. slot .. " Saved: Page " .. current)
end

function returnToSlot(slot)
	local key = getFileKey()
	if savedPages[key] and savedPages[key][slot] then
		pushPage0()
		gotoPage(savedPages[key][slot])
	else
		showNote("Slot " .. slot .. " is empty")
	end
end

function SaveSlot1()
	SaveSlot(1)
end
function returnToSlot1()
	returnToSlot(1)
end
function SaveSlot2()
	SaveSlot(2)
end
function returnToSlot2()
	returnToSlot(2)
end
function SaveSlot3()
	SaveSlot(3)
end
function returnToSlot3()
	returnToSlot(3)
end
