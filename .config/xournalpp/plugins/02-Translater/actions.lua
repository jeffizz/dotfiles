local utils = require("utils")
local metadata = require("metadata")
local actions = {}

local pendingTranslateText = nil

local cachedDictApp = nil
local isDictConfigLoaded = false

local function getDictAppConfig()
	if isDictConfigLoaded then
		return cachedDictApp
	end

	local dbText = metadata.getMetadataText()
	if dbText ~= "" then
		local db = metadata.parseINI(dbText)
		if db["Common"] and db["Common"]["DictApp"] then
			cachedDictApp = string.lower(tostring(db["Common"]["DictApp"])):gsub("^%s*(.-)%s*$", "%1")
		end
	end

	isDictConfigLoaded = true
	return cachedDictApp
end

local function callRaycast(commandSlug, textToTranslate)
	local text = textToTranslate or utils.getClipboardText()
	if not text or text == "" then
		return
	end

	text = text:gsub("^%s*(.-)%s*$", "%1")
	local encodedText = utils.urlEncode(text)

	local deeplink = "raycast://ai-commands/" .. commandSlug .. "?fallbackText=" .. encodedText
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

function actions.selectDictApp()
	app.openDialog(
		"Please select your preferred dictionary app:",
		{ "Eudic", "Easydict", "Cancel" },
		"onDictDialogResult"
	)
end

function actions.onDictDialogResult(selectedIndex)
	if not selectedIndex then
		pendingTranslateText = nil
		return
	end

	local selection = nil
	if type(selectedIndex) == "number" then
		local opts = { "eudic", "easydict", "cancel" }
		selection = opts[selectedIndex] or opts[selectedIndex + 1]
	else
		selection = string.lower(tostring(selectedIndex))
	end

	if not selection or selection == "cancel" then
		pendingTranslateText = nil
		return
	end

	local dbText = metadata.getMetadataText()
	local db = {}
	if dbText ~= "" then
		db = metadata.parseINI(dbText)
	end

	db["Common"] = db["Common"] or {}
	db["Common"]["DictApp"] = selection
	metadata.writeMetadata(db)

	cachedDictApp = selection
	isDictConfigLoaded = true

	if pendingTranslateText then
		local textToProcess = pendingTranslateText
		pendingTranslateText = nil
		actions.doTranslate(textToProcess, selection)
	else
		app.openDialog("✅ Dictionary app updated to: " .. selection, { "OK" })
	end
end

function actions.doTranslate(text, dictApp)
	local length = #text

	if length > 80 then
		callRaycast("tech-translate-only", text)
		return
	end

	if dictApp == "eudic" then
		if string.match(text, "^[a-zA-Z%-]+$") then
			os.execute("open 'eudic://dict/" .. text .. "'")
		else
			callRaycast("tech-translate-only", text)
		end
	elseif dictApp == "easydict" then
		local encoded = utils.urlEncode(text)
		local cmd = "open 'raycast://extensions/isfeng/easydict/easydict?arguments=%7B%22queryText%22%3A%22"
			.. encoded
			.. "%22%7D'"
		os.execute(cmd)
	else
		callRaycast("tech-translate-only", text)
	end
end

function actions.smartTranslateClipboard()
	local text = utils.getClipboardText()
	if not text then
		return
	end
	text = text:gsub("^%s*(.-)%s*$", "%1")
	if text == "" then
		return
	end

	if #text > 80 then
		callRaycast("tech-translate-only", text)
		return
	end

	local dictApp = getDictAppConfig()

	if not dictApp or dictApp == "" then
		pendingTranslateText = text
		actions.selectDictApp()
	else
		actions.doTranslate(text, dictApp)
	end
end

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
		["ai_smart.svg"] = utils.icons.smart,
	}

	for filename, content in pairs(files) do
		local f = io.open(iconDir .. filename, "w")
		if f then
			f:write(content)
			f:close()
		end
	end
	app.openDialog("Icons successfully written to " .. iconDir, { "OK" })
end

return actions
