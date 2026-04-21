function initUi()
	app.registerUi({ ["menu"] = "Next Page (v)", ["callback"] = "nextPage", ["accelerator"] = "v" })
	app.registerUi({ ["menu"] = "Previous Page (q)", ["callback"] = "previousPage", ["accelerator"] = "q" })
	app.registerUi({ ["menu"] = "Hand Tool(r)", ["callback"] = "handTool", ["accelerator"] = "r" })
	app.registerUi({ ["menu"] = "Select Object (f)", ["callback"] = "selectObject", ["accelerator"] = "f" })
	app.registerUi({ ["menu"] = "Go to Page (g)", ["callback"] = "gotoPage", ["accelerator"] = "g" })
end

function nextPage()
	app.scrollToPage(1, true)
end
function previousPage()
	app.scrollToPage(-1, true)
end
function handTool()
	app.changeActionState("select-tool", app.C.Tool_hand)
end
function selectObject()
	app.changeActionState("select-tool", app.C.Tool_selectObject)
end
function gotoPage()
	app.activateAction("goto-page")
end
