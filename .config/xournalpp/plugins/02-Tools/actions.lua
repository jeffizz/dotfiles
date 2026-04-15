local utils = require("utils")
local actions = {}

-- Core invocation function
local function callRaycast(commandSlug)
	-- local text = utils.getClipboardText()
	-- if not text or text == "" then
	-- 	return
	-- end

	-- local encodedText = utils.urlEncode(text)
	local deeplink = "raycast://ai-commands/" .. commandSlug -- .. "?fallbackText=" .. encodedText
	os.execute("open '" .. deeplink .. "'")
end

function actions.translateOnly()
	callRaycast("tech-translate-only")
end
function actions.translateAndExplain()
	callRaycast("tech-translate-and-explain")
end
function actions.summarize()
	callRaycast("tech-translate-and-summary")
end

-- One-click icon setup function
function actions.setupIcons()
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

	local files = {
		["ai_tran.svg"] = utils.icons.tran,
		["ai_te.svg"] = utils.icons.te,
		["ai_sum.svg"] = utils.icons.sum,
	}

	for filename, content in pairs(files) do
		local f = io.open(iconDir .. filename, "w")
		if f then
			f:write(content)
			f:close()
		end
	end
	app.openDialog(
		"Icons successfully written to "
			.. iconDir
			.. "\nPlease search for 'AI' in Toolbar Configuration and add the buttons.",
		{ "OK" }
	)
end

return actions
