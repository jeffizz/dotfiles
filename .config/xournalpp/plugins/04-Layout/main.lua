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
	app.uiAction({ ["action"] = "ACTION_SET_COLUMNS_" .. columns })
	app.uiAction({ ["action"] = "ACTION_ZOOM_100" })

	local zoomOutCounts = { 0, 2, 6, 9, 12, 13 }
	local count = zoomOutCounts[columns] or 0

	for i = 1, count do
		app.uiAction({ ["action"] = "ACTION_ZOOM_OUT" })
	end

	app.uiAction({ ["action"] = "ACTION_TOOL_HAND" })
end
