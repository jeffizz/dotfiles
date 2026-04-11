-- Custom Keyboard Shortcuts Plugin for Xournal++

function initUi()
	app.registerUi({
		["menu"] = "Open New Window",
		["callback"] = "openNewWindow",
		["accelerator"] = "<Alt>n",
	})
end

function openNewWindow()
	local cmd = "open -n -a Xournal++ &"
	os.execute(cmd)
end
