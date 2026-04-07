-- Register all Toolbar actions and initialize all UI stuff
function initUi()
	app.registerUi({ ["menu"] = "Cycle through color list", ["callback"] = "cycle", ["accelerator"] = "<Alt>c" })
	-- if you want to have multiple color lists you must use the app.registerUi function multiple times
	-- with different callback functions and accelerators
end

-- Predefined colors copied from LoadHandlerHelper.cpp
-- modify to your needs
local colorList = {
	{ "yellow", 0xffe16b },
	{ "orange", 0xffa154 },
	{ "purple", 0xcd9ef7 },
	{ "lightgreen", 0x9bdb4d },
	{ "lightblue", 0x64baff },
	{ "gray", 0x808080 },
	{ "darkgreen", 0x3a9104 },
	{ "red", 0xed5353 },
	{ "darkblue", 0x002e99 },
	{ "black", 0x000000 },
	{ "white", 0xffffff },
}

-- start with first color
local currentColor = 0

function cycle()
	if currentColor < #colorList then
		currentColor = currentColor + 1
	else
		currentColor = 1
	end
	-- apply color to currently used tool and allow coloring of elements from selections
	app.changeToolColor({ ["color"] = colorList[currentColor][2], ["selection"] = true })
	-- use app.changeToolColor({["color"] = colorList[currentColor][2], ["tool"] = "pen"})
	-- instead if you only want to change pen color
	-- similarly if you want to change highlighter color or the color from another tool with color capabilities.
end
