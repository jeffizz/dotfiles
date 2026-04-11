function initUi()
	for i = 1, 6 do
		local funcName = "layout" .. i .. "Column"

		_G[funcName] = function()
			setLayout(i)
		end

		app.registerUi({
			["menu"] = i .. "-Column Layout",
			["callback"] = funcName,
			["accelerator"] = "<Meta>" .. i,
		})
	end
end

function setLayout(columns)
	app.changeActionState("set-columns-or-rows", columns)

	local zoomLevels = { 1, 0.83, 0.55, 0.42, 0.32, 0.30 }
	local zoomLevel = zoomLevels[columns] or 1

	app.setZoom(zoomLevel)

	app.changeActionState("select-tool", app.C.Tool_hand)
end
