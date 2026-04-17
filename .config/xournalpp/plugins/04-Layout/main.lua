local utils = require("utils")

local lastPressTime = 0
local lastPressColumn = 0

local zoomLevelsSingle = { 1, 0.81, 0.54, 0.42, 0.32, 0.30 }
local zoomLevelsDouble = { 1, 0.72, 0.47, 0.37, 0.30, 0.30 }
local configLoaded = false

local function loadLayoutConfig()
	if configLoaded then
		return
	end

	local dbText = utils.getMetadataText()
	local db = {}
	if dbText ~= "" then
		db = utils.parseINI(dbText)
	end

	local needSave = false
	db["Layout"] = db["Layout"] or {}

	if db["Layout"]["zoomLevelsSingle"] then
		local arr = utils.parseArray(db["Layout"]["zoomLevelsSingle"])
		if #arr >= 6 then
			zoomLevelsSingle = arr
		end
	else
		db["Layout"]["zoomLevelsSingle"] = table.concat(zoomLevelsSingle, ",")
		needSave = true
	end

	if db["Layout"]["zoomLevelsDouble"] then
		local arr = utils.parseArray(db["Layout"]["zoomLevelsDouble"])
		if #arr >= 6 then
			zoomLevelsDouble = arr
		end
	else
		db["Layout"]["zoomLevelsDouble"] = table.concat(zoomLevelsDouble, ",")
		needSave = true
	end

	if needSave then
		if utils.writeMetadata(db) then
			configLoaded = true
		end
	else
		configLoaded = true
	end
end

function initUi()
	for i = 1, 6 do
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

function setLayout(columns)
	loadLayoutConfig()

	local currentTime = os.clock()
	local isDoubleTap = false

	if (currentTime - lastPressTime) <= 0.5 and lastPressColumn == columns then
		isDoubleTap = true
	end

	if isDoubleTap then
		lastPressTime = 0
		lastPressColumn = 0
	else
		lastPressTime = currentTime
		lastPressColumn = columns
	end

	app.changeActionState("set-columns-or-rows", columns)

	local zoomLevel = 1
	if isDoubleTap then
		zoomLevel = zoomLevelsDouble[columns] or 1
	else
		zoomLevel = zoomLevelsSingle[columns] or 1
	end

	app.setZoom(zoomLevel)
	app.changeActionState("select-tool", app.C.Tool_hand)
end
