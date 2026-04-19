-- Custom Keyboard Shortcuts Plugin for Xournal++

function initUi()
	app.registerUi({
		["menu"] = "Next Page (v)",
		["callback"] = "nextPage",
		["accelerator"] = "v",
	})

	app.registerUi({
		["menu"] = "Previous Page (q)",
		["callback"] = "previousPage",
		["accelerator"] = "q",
	})

	app.registerUi({
		["menu"] = "Text Tool (w)",
		["callback"] = "textTool",
		["accelerator"] = "w",
	})

	app.registerUi({
		["menu"] = "Hand Tool(r)",
		["callback"] = "handTool",
		["accelerator"] = "r",
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
	for i = 1, 9 do
		app.registerUi({ ["menu"] = "Color " .. i, ["callback"] = "color" .. i, ["accelerator"] = tostring(i) })
	end
	app.registerUi({ ["menu"] = "Color 10", ["callback"] = "color10", ["accelerator"] = "0" })
end

function nextPage()
	app.scrollToPage(1, true)
end

function previousPage()
	app.scrollToPage(-1, true)
end

function textTool()
	app.changeActionState("select-tool", app.C.Tool_text)
end

function handTool()
	app.changeActionState("select-tool", app.C.Tool_hand)
end

function highlighterTool()
	app.changeActionState("select-tool", app.C.Tool_highlighter)
end

function pdfTextTool()
	app.changeActionState("select-tool", app.C.Tool_selectPdfTextLinear)
end

function penTool()
	app.changeActionState("select-tool", app.C.Tool_pen)
end

function selectObject()
	app.changeActionState("select-tool", app.C.Tool_selectObject)
end

function gotoPage()
	app.activateAction("goto-page")
end
