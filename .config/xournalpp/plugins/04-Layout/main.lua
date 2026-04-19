-- ============================================================================
-- main.lua | DYNAMIC LAYOUT & ZOOM CYCLE ENGINE
-- ============================================================================
local metadata = require("metadata")

local configLoaded = false
local currentDocFingerprint = ""

local DEFAULT_ZOOMS = {
	{ 1.00, 1.00, 0.80 }, -- Layout 1
	{ 0.81, 0.72, 0.66 }, -- Layout 2
	{ 0.54, 0.47, 0.40 }, -- Layout 3
	{ 0.42, 0.37, 0.30 }, -- Layout 4
	{ 0.32, 0.30, 0.30 }, -- Layout 5
	{ 0.30, 0.30, 0.30 }, -- Layout 6
	{ 0.30, 0.30, 0.30 }, -- Layout 7
	{ 0.30, 0.30, 0.30 }, -- Layout 8
}

local zoomLevels = {}

local currentZoomIndices = { 1, 1, 1, 1, 1, 1, 1, 1 }

local function loadLayoutConfig()
	local newFingerprint = metadata.getFingerprint()
	if configLoaded and currentDocFingerprint == newFingerprint then
		return
	end

	currentDocFingerprint = newFingerprint
	configLoaded = false

	local dbText = metadata.getMetadataText()
	local db = {}
	if dbText ~= "" then
		db = metadata.parseINI(dbText)
	end

	local needSave = false
	db["Layout"] = db["Layout"] or {}

	for i = 1, 8 do
		local key = "col_" .. i
		if db["Layout"][key] then
			local arr = metadata.parseArray(db["Layout"][key])
			if #arr >= 3 then
				zoomLevels[i] = { arr[1], arr[2], arr[3] }
			else
				zoomLevels[i] = { DEFAULT_ZOOMS[i][1], DEFAULT_ZOOMS[i][2], DEFAULT_ZOOMS[i][3] }
				db["Layout"][key] = table.concat(zoomLevels[i], ",")
				needSave = true
			end
		else
			zoomLevels[i] = { DEFAULT_ZOOMS[i][1], DEFAULT_ZOOMS[i][2], DEFAULT_ZOOMS[i][3] }
			db["Layout"][key] = table.concat(zoomLevels[i], ",")
			needSave = true
		end
	end

	if needSave then
		if metadata.writeMetadata(db) then
			configLoaded = true
		end
	else
		configLoaded = true
	end
end

local function saveCurrentLayoutConfig()
	local dbText = metadata.getMetadataText()
	local db = {}
	if dbText ~= "" then
		db = metadata.parseINI(dbText)
	end

	db["Layout"] = db["Layout"] or {}
	for i = 1, 8 do
		if zoomLevels[i] then
			db["Layout"]["col_" .. i] = table.concat(zoomLevels[i], ",")
		end
	end

	metadata.writeMetadata(db)
end

function setLayout(columns)
	loadLayoutConfig()

	local currentLayout = app.getActionState("set-columns-or-rows")

	if currentLayout == columns then
		currentZoomIndices[columns] = (currentZoomIndices[columns] % 3) + 1
	else
		app.changeActionState("set-columns-or-rows", columns)
		currentZoomIndices[columns] = 1
	end

	local zoomLevel = zoomLevels[columns][currentZoomIndices[columns]]
	app.setZoom(zoomLevel)
	app.changeActionState("select-tool", app.C.Tool_hand)
end

local function updateZoomLevel(levelIndex)
	loadLayoutConfig()
	local currentLayout = app.getActionState("set-columns-or-rows")

	if not currentLayout or currentLayout < 1 or currentLayout > 8 then
		app.openDialog("⚠️ Cannot update zoom: Invalid layout column state.", { "OK" })
		return
	end

	local currentZoom = app.getZoom()

	currentZoom = tonumber(string.format("%.2f", currentZoom))

	zoomLevels[currentLayout][levelIndex] = currentZoom

	currentZoomIndices[currentLayout] = levelIndex

	saveCurrentLayoutConfig()
	app.openDialog(
		string.format("✅ Layout %d - Level %d zoom updated to: %.2f", currentLayout, levelIndex, currentZoom),
		{ "OK" }
	)
end

function setZoomLevel1()
	updateZoomLevel(1)
end
function setZoomLevel2()
	updateZoomLevel(2)
end
function setZoomLevel3()
	updateZoomLevel(3)
end

function resetCurrentLayoutZoom()
	loadLayoutConfig()
	local currentLayout = app.getActionState("set-columns-or-rows")

	if not currentLayout or currentLayout < 1 or currentLayout > 8 then
		return
	end

	zoomLevels[currentLayout] =
		{ DEFAULT_ZOOMS[currentLayout][1], DEFAULT_ZOOMS[currentLayout][2], DEFAULT_ZOOMS[currentLayout][3] }
	currentZoomIndices[currentLayout] = 1

	saveCurrentLayoutConfig()

	app.setZoom(zoomLevels[currentLayout][1])
end

function setupLayoutIcons()
	local isWindows = package.config:sub(1, 1) == "\\"
	local iconDir, mkdirCmd = "", ""

	if isWindows then
		iconDir = os.getenv("LOCALAPPDATA") .. "\\icons\\"
		mkdirCmd = 'if not exist "' .. iconDir .. '" mkdir "' .. iconDir .. '"'
	else
		iconDir = os.getenv("HOME") .. "/.local/share/icons/"
		mkdirCmd = 'mkdir -p "' .. iconDir .. '"'
	end

	os.execute(mkdirCmd)

	local svgTemplate =
		[[<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><rect width="64" height="64" rx="14" fill="%s"/><text x="32" y="%d" font-family="-apple-system, Arial, sans-serif" font-size="%d" font-weight="bold" fill="#FFFFFF" text-anchor="middle">%s</text></svg>]]
	local svgTemplate2 =
		[[<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><circle cx="32" cy="32" r="32" fill="%s"/><text x="32" y="%d" font-family="-apple-system, Arial, sans-serif" font-size="%d" font-weight="bold" fill="#FFFFFF" text-anchor="middle">%s</text></svg>]]

	local files = {
		["layout_zl1.svg"] = string.format(svgTemplate, "#3498DB", 42, 28, "SZ1"),
		["layout_zl2.svg"] = string.format(svgTemplate, "#2ECC71", 40, 22, "SZ2"),
		["layout_zl3.svg"] = string.format(svgTemplate, "#9B59B6", 39, 18, "SZ3"),
		["layout_reset.svg"] = string.format(svgTemplate2, "#E74C3C", 40, 22, "RST"),
	}

	for filename, content in pairs(files) do
		local f = io.open(iconDir .. filename, "w")
		if f then
			f:write(content)
			f:close()
		end
	end

	app.openDialog("✅ Layout Icons successfully written to:\n" .. iconDir, { "OK" })
end

function initUi()
	app.registerUi({
		menu = "Layout: Setup Icons",
		callback = "setupLayoutIcons",
	})
	app.registerUi({
		menu = "Layout: Set Zoom Level 1",
		callback = "setZoomLevel1",
		toolbarId = "layout_zl1",
		iconName = "layout_zl1",
	})
	app.registerUi({
		menu = "Layout: Set Zoom Level 2",
		callback = "setZoomLevel2",
		toolbarId = "layout_zl2",
		iconName = "layout_zl2",
	})
	app.registerUi({
		menu = "Layout: Set Zoom Level 3",
		callback = "setZoomLevel3",
		toolbarId = "layout_zl3",
		iconName = "layout_zl3",
	})
	app.registerUi({
		menu = "Layout: Reset Current",
		callback = "resetCurrentLayoutZoom",
		toolbarId = "layout_reset",
		iconName = "layout_reset",
	})
	for i = 1, 8 do
		local funcName = "layout" .. i .. "Column"
		_G[funcName] = function()
			setLayout(i)
		end
		app.registerUi({
			["menu"] = i .. "-Column Layout",
			["callback"] = funcName,
			["accelerator"] = "<Ctrl>" .. i,
		})
	end
end
