-- Custom Keyboard Shortcuts Plugin for Xournal++

function initUi()
	app.registerUi({
		["menu"] = "Open New Window",
		["callback"] = "openNewWindow",
		["accelerator"] = "<Alt>n",
	})

	app.registerUi({
		["menu"] = "-- Custom Shortcuts --",
		["callback"] = "dummyCallback",
		["accelerator"] = "", -- No accelerator needed, we handle keys in the plugin
	})

	app.registerUi({
		["menu"] = "Next Page (v)",
		["callback"] = "nextPage",
		["accelerator"] = "v",
	})

	app.registerUi({
		["menu"] = "Previous Page (r)",
		["callback"] = "previousPage",
		["accelerator"] = "r",
	})

	app.registerUi({
		["menu"] = "Text Tool (w)",
		["callback"] = "textTool",
		["accelerator"] = "w",
	})

	app.registerUi({
		["menu"] = "Hand Tool(q)",
		["callback"] = "handTool",
		["accelerator"] = "q",
	})

	app.registerUi({
		["menu"] = "Pen Tool (a)",
		["callback"] = "penTool",
		["accelerator"] = "a",
	})

	app.registerUi({
		["menu"] = "Select PDF Text (s)",
		["callback"] = "pdfTextTool",
		["accelerator"] = "s",
	})

	app.registerUi({
		["menu"] = "Highlighter Tool (d)",
		["callback"] = "highlighterTool",
		["accelerator"] = "d",
	})

	app.registerUi({
		["menu"] = "Select Object (f)",
		["callback"] = "selectObject",
		["accelerator"] = "f",
	})

	app.registerUi({
		["menu"] = "Go to Page (g)",
		["callback"] = "gotoPage",
		["accelerator"] = "g",
	})
	for i = 0, 9 do
		app.registerUi({ ["menu"] = "Color " .. i, ["callback"] = "color" .. i, ["accelerator"] = tostring(i) })
	end
	app.registerUi({ ["menu"] = "Color 10", ["callback"] = "color10", ["accelerator"] = "0" })
end

-- Dummy callback (not used)
function dummyCallback() end

function nextPage()
	app.uiAction({ ["action"] = "ACTION_GOTO_NEXT" })
end

function previousPage()
	app.uiAction({ ["action"] = "ACTION_GOTO_BACK" })
end

function textTool()
	app.uiAction({ ["action"] = "ACTION_TOOL_TEXT" })
end

function handTool()
	app.uiAction({ ["action"] = "ACTION_TOOL_HAND" })
end

function highlighterTool()
	app.uiAction({ ["action"] = "ACTION_TOOL_HIGHLIGHTER" })
end

function pdfTextTool()
	app.uiAction({ ["action"] = "ACTION_TOOL_SELECT_PDF_TEXT_LINEAR" })
end

function penTool()
	app.uiAction({ ["action"] = "ACTION_TOOL_PEN" })
end

function selectObject()
	app.uiAction({ ["action"] = "ACTION_TOOL_SELECT_OBJECT" })
end

function gotoPage()
	app.uiAction({ ["action"] = "ACTION_GOTO_PAGE" })
end

function openNewWindow()
	local cmd = "open -n -a Xournal++ &"
	os.execute(cmd)
end
