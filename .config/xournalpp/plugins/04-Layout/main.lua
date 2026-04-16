local lastPressTime = 0
local lastPressColumn = 0

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

	local zoomLevelsSingle = { 1, 0.83, 0.55, 0.42, 0.32, 0.30 }
	local zoomLevelsDouble = { 1, 0.73, 0.48, 0.37, 0.30, 0.30 }

	local zoomLevel = 1
	if isDoubleTap then
		zoomLevel = zoomLevelsDouble[columns] or 1
	else
		zoomLevel = zoomLevelsSingle[columns] or 1
	end

	app.setZoom(zoomLevel)
	app.changeActionState("select-tool", app.C.Tool_hand)
end
