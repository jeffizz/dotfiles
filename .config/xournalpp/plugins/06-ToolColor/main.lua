local config = require("config")

local configLoaded = false
local toolColors = {}
local pdfSlots = {}
local hlSlots = {}

local DEFAULT_SLOTS = { 0xed5353, 0x9bdb4d, 0x64baff, 0xcd9ef7, 0xffa154 }

local CYCLE_COLORS_SOLID = { 0xED5353, 0x3A9104, 0x002E99, 0x9141AC, 0xFF7800 }
local CYCLE_COLORS_TRANSPARENT = { 0xED5353, 0x9BDB4D, 0x64BAFF, 0xCD9EF7, 0xFFA154 }

local PALETTE = {
	{ color = 0xED5353, emoji = "🔴", name = "Red (Soft)" },
	{ color = 0xFF0000, emoji = "🔴", name = "Red (Bright)" },
	{ color = 0xFF00FF, emoji = "🌺", name = "Magenta" },
	{ color = 0xCD9EF7, emoji = "🟣", name = "Purple" },
	{ color = 0xFFA154, emoji = "🟠", name = "Orange (Soft)" },
	{ color = 0xFF8000, emoji = "🟠", name = "Orange (Bright)" },
	{ color = 0xFFE16B, emoji = "🟡", name = "Yellow (Soft)" },
	{ color = 0xFFFF00, emoji = "🟡", name = "Yellow (Bright)" },
	{ color = 0x9BDB4D, emoji = "🎾", name = "Light Green (Soft)" },
	{ color = 0x00FF00, emoji = "🎾", name = "Light Green (Bright)" },
	{ color = 0x008000, emoji = "🟢", name = "Green" },
	{ color = 0x3A9104, emoji = "🌲", name = "Dark Green" },
	{ color = 0x64BAFF, emoji = "🩵", name = "Light Blue (Soft)" },
	{ color = 0x00C0FF, emoji = "🩵", name = "Light Blue (Bright)" },
	{ color = 0x3333CC, emoji = "🔵", name = "Blue" },
	{ color = 0x002E99, emoji = "🌌", name = "Dark Blue" },
	{ color = 0x808080, emoji = "🔘", name = "Gray" },
	{ color = 0x000000, emoji = "⚫", name = "Black" },
	{ color = 0xFFFFFF, emoji = "⚪", name = "White" },
}

local TOOL_KEYS = {
	[app.C.Tool_pen] = "pen",
	[app.C.Tool_highlighter] = "highlighter",
	[app.C.Tool_text] = "text",
}
local TOOL_API_NAMES = {
	[app.C.Tool_pen] = "PEN",
	[app.C.Tool_highlighter] = "HIGHLIGHTER",
	[app.C.Tool_text] = "TEXT",
}

local pendingTool = nil
local currentPalette = nil

local function getEmojiForColorName(name)
	local lowerName = string.lower(name or "")
	local matchers = {
		{ "dark blue", "🌌" },
		{ "light blue", "🩵" },
		{ "blue", "🔵" },
		{ "dark green", "🌲" },
		{ "light green", "🎾" },
		{ "green", "🟢" },
		{ "red", "🔴" },
		{ "orange", "🟠" },
		{ "yellow", "🟡" },
		{ "purple", "🟣" },
		{ "magenta", "🌺" },
		{ "black", "⚫" },
		{ "white", "⚪" },
		{ "gray", "🔘" },
	}
	for _, m in ipairs(matchers) do
		if string.find(lowerName, m[1]) then
			return m[2]
		end
	end
	return name
end

local function getEmojiForHex(hex)
	for _, p in ipairs(PALETTE) do
		if p.color == hex then
			return p.emoji
		end
	end
	return "🎨"
end

local function toHexString(num)
	local hexStr = string.format("%08X", tonumber(num) or 0)
	return "0x" .. string.sub(hexStr, -6)
end

local function loadColorsConfig()
	if configLoaded then
		return
	end
	local db = config.read()
	local needWrite = false
	db["toolColor"] = db["toolColor"] or {}

	local baseDefaults = { pen = 0xed5353, highlighter = 0x9bdb4d, text = 0xed5353, pdf_linear = 0x9bdb4d }
	for key, defaultColor in pairs(baseDefaults) do
		if db["toolColor"][key] and tonumber(db["toolColor"][key]) then
			toolColors[key] = tonumber(db["toolColor"][key])
		else
			toolColors[key] = defaultColor
			db["toolColor"][key] = toHexString(defaultColor)
			needWrite = true
		end
	end

	for i = 1, 5 do
		local pKey, hKey = "pdf_slot_" .. i, "hl_slot_" .. i
		if db["toolColor"][pKey] and tonumber(db["toolColor"][pKey]) then
			pdfSlots[i] = tonumber(db["toolColor"][pKey])
		else
			pdfSlots[i] = DEFAULT_SLOTS[i]
			db["toolColor"][pKey] = toHexString(DEFAULT_SLOTS[i])
			needWrite = true
		end
		if db["toolColor"][hKey] and tonumber(db["toolColor"][hKey]) then
			hlSlots[i] = tonumber(db["toolColor"][hKey])
		else
			hlSlots[i] = DEFAULT_SLOTS[i]
			db["toolColor"][hKey] = toHexString(DEFAULT_SLOTS[i])
			needWrite = true
		end
	end

	if needWrite then
		config.write(db)
	end
	configLoaded = true
end

local function saveColorsConfig()
	local db = config.read()
	db["toolColor"] = db["toolColor"] or {}
	for i = 1, 5 do
		db["toolColor"]["pdf_slot_" .. i] = toHexString(pdfSlots[i])
		db["toolColor"]["hl_slot_" .. i] = toHexString(hlSlots[i])
	end
	for key, color in pairs(toolColors) do
		db["toolColor"][key] = toHexString(color)
	end
	config.write(db)
end

function setupShortcutIcons()
	loadColorsConfig()
	local isWindows = package.config:sub(1, 1) == "\\"
	local iconDir = isWindows and (os.getenv("LOCALAPPDATA") .. "\\icons\\")
		or (os.getenv("HOME") .. "/.local/share/icons/")
	os.execute(
		isWindows and ('if not exist "' .. iconDir .. '" mkdir "' .. iconDir .. '"') or ('mkdir -p "' .. iconDir .. '"')
	)

	local svgPdfTemplate =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><path d="M22,10 H62 V40 H38 V54 H2 V26 H22 V10 Z" fill="%s" stroke="#757575" stroke-width="3" stroke-linejoin="round"/><text x="25" y="28" font-family="-apple-system, Arial, sans-serif" font-size="16" fill="#666666">Word</text><rect x="6" y="32" width="6" height="8" fill="#666666"/><rect x="14" y="32" width="6" height="8" fill="#666666"/><rect x="22" y="32" width="6" height="8" fill="#666666"/><rect x="30" y="32" width="6" height="8" fill="#666666"/><text x="5" y="50" font-family="-apple-system, Arial, sans-serif" font-size="11" fill="#666666">1234</text></svg>'
	local svgHlTemplate =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><g transform="rotate(25 32 32)"><path d="M 20,12 Q 32,8 44,12 L 38,38 L 26,38 Z" fill="%s" stroke="#333333" stroke-width="2" stroke-linejoin="round"/><path d="M 22,13 Q 27,11 28,13 L 28,36 L 26,36 Z" fill="#ffffff" opacity="0.4"/><polygon points="24,38 40,38 38,46 26,46" fill="#2c3e50" stroke="#333333" stroke-width="2" stroke-linejoin="round"/><polygon points="28,46 36,46 36,54 26,58" fill="%s" stroke="#333333" stroke-width="2" stroke-linejoin="round"/></g></svg>'

	local svgConfigPdf =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><path d="M22,10 H62 V40 H38 V54 H2 V26 H22 V10 Z" fill="#feda49" stroke="#757575" stroke-width="3" stroke-linejoin="round"/><text x="25" y="28" font-family="-apple-system, Arial, sans-serif" font-size="16" fill="#666666">Word</text><rect x="6" y="32" width="6" height="8" fill="#666666"/><rect x="14" y="32" width="6" height="8" fill="#666666"/><rect x="22" y="32" width="6" height="8" fill="#666666"/><rect x="30" y="32" width="6" height="8" fill="#666666"/><text x="5" y="50" font-family="-apple-system, Arial, sans-serif" font-size="11" fill="#666666">1234</text><g transform="translate(16, 16)"><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50"/><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50" transform="rotate(45 32 32)"/><circle cx="32" cy="32" r="12" fill="#2C3E50"/><circle cx="32" cy="32" r="5" fill="#FFFFFF"/></g></svg>'
	local svgConfigHl =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><g transform="rotate(25 32 32)"><path d="M 20,12 Q 32,8 44,12 L 38,38 L 26,38 Z" fill="#ffe16b" stroke="#333333" stroke-width="2" stroke-linejoin="round"/><path d="M 22,13 Q 27,11 28,13 L 28,36 L 26,36 Z" fill="#ffffff" opacity="0.4"/><polygon points="24,38 40,38 38,46 26,46" fill="#2c3e50" stroke="#333333" stroke-width="2" stroke-linejoin="round"/><polygon points="28,46 36,46 36,54 26,58" fill="#ffe16b" stroke="#333333" stroke-width="2" stroke-linejoin="round"/></g><g transform="translate(16, 16)"><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50"/><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50" transform="rotate(45 32 32)"/><circle cx="32" cy="32" r="12" fill="#2C3E50"/><circle cx="32" cy="32" r="5" fill="#FFFFFF"/></g></svg>'
	local svgConfigBase =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><rect x="8" y="6" width="20" height="40" rx="4" fill="#3498DB" stroke="#FFFFFF" stroke-width="2" transform="rotate(50 18 42)"/><rect x="8" y="6" width="20" height="40" rx="4" fill="#2ECC71" stroke="#FFFFFF" stroke-width="2" transform="rotate(25 18 42)"/><rect x="8" y="6" width="20" height="40" rx="4" fill="#E74C3C" stroke="#FFFFFF" stroke-width="2" transform="rotate(0 18 42)"/><circle cx="18" cy="40" r="3.5" fill="#FFFFFF"/><circle cx="18" cy="40" r="1.5" fill="#BDC3C7"/><g transform="translate(16, 16)"><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50"/><path d="M30 16 h4 v32 h-4 Z M16 30 h32 v4 h-32 Z" fill="#2C3E50" transform="rotate(45 32 32)"/><circle cx="32" cy="32" r="12" fill="#2C3E50"/><circle cx="32" cy="32" r="5" fill="#FFFFFF"/></g></svg>'
	local svgToolPen =
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><g transform="translate(32 32) rotate(45) scale(1.15) translate(-32 -32)"><path d="M 24,15 L 24,11 A 8 6 0 0 1 40 11 L 40,15 Z" fill="#F28B82"/><rect x="24" y="15" width="16" height="8" fill="#A0B0C0"/><rect x="24" y="23" width="16" height="24" fill="#FFCA28"/><polygon points="24,47 40,47 32,59" fill="#FF0000"/></g></svg>'

	local function hx(num)
		return string.format("#%06x", num)
	end

	local files = {
		["sc_pdf_slot1.svg"] = string.format(svgPdfTemplate, hx(pdfSlots[1])),
		["sc_pdf_slot2.svg"] = string.format(svgPdfTemplate, hx(pdfSlots[2])),
		["sc_pdf_slot3.svg"] = string.format(svgPdfTemplate, hx(pdfSlots[3])),
		["sc_pdf_slot4.svg"] = string.format(svgPdfTemplate, hx(pdfSlots[4])),
		["sc_pdf_slot5.svg"] = string.format(svgPdfTemplate, hx(pdfSlots[5])),
		["sc_hl_slot1.svg"] = string.format(svgHlTemplate, hx(hlSlots[1]), hx(hlSlots[1])),
		["sc_hl_slot2.svg"] = string.format(svgHlTemplate, hx(hlSlots[2]), hx(hlSlots[2])),
		["sc_hl_slot3.svg"] = string.format(svgHlTemplate, hx(hlSlots[3]), hx(hlSlots[3])),
		["sc_hl_slot4.svg"] = string.format(svgHlTemplate, hx(hlSlots[4]), hx(hlSlots[4])),
		["sc_hl_slot5.svg"] = string.format(svgHlTemplate, hx(hlSlots[5]), hx(hlSlots[5])),
		["sc_config_pdf.svg"] = svgConfigPdf,
		["sc_config_hl.svg"] = svgConfigHl,
		["sc_set_color.svg"] = svgConfigBase,
		["sc_tool_pen.svg"] = svgToolPen,
	}

	for name, content in pairs(files) do
		local f = io.open(iconDir .. name, "wb")
		if f then
			f:write(content)
			f:close()
		end
	end
	if not _G.isSilentSetup then
		app.openDialog("✅ Icons successfully written!", { "OK" })
	end
end

function setCurrentToolColor()
	pendingTool = app.getActionState("select-tool")
	if not TOOL_KEYS[pendingTool] then
		app.openDialog("⚠️ Select Pen, Text, or Highlighter tool first.", { "OK" })
		return
	end

	currentPalette = app.getColorPalette()
	local opts = {}
	for _, colorInfo in ipairs(currentPalette) do
		table.insert(opts, getEmojiForColorName(colorInfo.name))
	end
	table.insert(opts, "❌ Cancel")
	app.openDialog(
		"Set default shortcut color for " .. TOOL_API_NAMES[pendingTool] .. ":",
		opts,
		"onBaseColorDialogResult"
	)
end

function onBaseColorDialogResult(idx)
	if not idx or idx > #currentPalette then
		return
	end
	local selectedColor = currentPalette[idx].color

	loadColorsConfig()
	toolColors[TOOL_KEYS[pendingTool]] = selectedColor
	saveColorsConfig()

	app.changeToolColor({ ["color"] = selectedColor, ["tool"] = TOOL_API_NAMES[pendingTool] })
	if app.getActionState("select-tool") == pendingTool then
		app.changeActionState("tool-color", selectedColor)
	end
	app.openDialog("✅ Default color updated!", { "OK" })
	pendingTool, currentPalette = nil, nil
end

local configStateTarget = nil
local configStateSlotIdx = nil

local function startConfig(target)
	loadColorsConfig()
	configStateTarget = target
	local opts = {}
	local currentSlots = (target == "pdf") and pdfSlots or hlSlots
	for i = 1, 5 do
		table.insert(opts, "Slot " .. i .. "  " .. getEmojiForHex(currentSlots[i]))
	end
	table.insert(opts, "❌ Cancel")
	app.openDialog("Which " .. string.upper(target) .. " slot do you want to change?", opts, "onSlotSelectResult")
end

function configPdfSlots()
	startConfig("pdf")
end
function configHlSlots()
	startConfig("hl")
end

function onSlotSelectResult(idx)
	if not idx or idx > 5 then
		return
	end
	configStateSlotIdx = idx
	currentPalette = app.getColorPalette()
	local opts = {}
	for _, colorInfo in ipairs(currentPalette) do
		table.insert(opts, getEmojiForColorName(colorInfo.name))
	end

	table.insert(opts, "❌ Cancel")
	app.openDialog("Choose a new color for Slot " .. idx .. ":", opts, "onColorSelectResult")
end

function onColorSelectResult(idx)
	if not idx or idx > #currentPalette then
		return
	end
	local newColor = currentPalette[idx].color

	if configStateTarget == "pdf" then
		pdfSlots[configStateSlotIdx] = newColor
	else
		hlSlots[configStateSlotIdx] = newColor
	end
	saveColorsConfig()

	_G.isSilentSetup = true
	setupShortcutIcons()
	_G.isSilentSetup = false

	app.openDialog("✅ Slot " .. configStateSlotIdx .. " updated!", { "Got it" })
end

local function applyColor(toolType, slotIdx)
	loadColorsConfig()
	local colorHex = (toolType == "pdf") and pdfSlots[slotIdx] or hlSlots[slotIdx]
	local xoppTool = (toolType == "pdf") and app.C.Tool_selectPdfTextLinear or app.C.Tool_highlighter

	app.changeActionState("select-tool", xoppTool)
	app.changeActionState("tool-color", colorHex)
end

function pdfSlot1()
	applyColor("pdf", 1)
end
function pdfSlot2()
	applyColor("pdf", 2)
end
function pdfSlot3()
	applyColor("pdf", 3)
end
function pdfSlot4()
	applyColor("pdf", 4)
end
function pdfSlot5()
	applyColor("pdf", 5)
end

function hlSlot1()
	applyColor("hl", 1)
end
function hlSlot2()
	applyColor("hl", 2)
end
function hlSlot3()
	applyColor("hl", 3)
end
function hlSlot4()
	applyColor("hl", 4)
end
function hlSlot5()
	applyColor("hl", 5)
end

function textTool()
	loadColorsConfig()
	app.changeActionState("select-tool", app.C.Tool_text)
	app.changeActionState("tool-color", toolColors["text"])
end
function penTool()
	loadColorsConfig()
	app.changeActionState("select-tool", app.C.Tool_pen)
	app.changeActionState("tool-color", toolColors["pen"])
end
function highlighterTool()
	loadColorsConfig()
	app.changeActionState("select-tool", app.C.Tool_highlighter)
	app.changeActionState("tool-color", toolColors["highlighter"])
end
function pdfTextTool()
	loadColorsConfig()
	app.changeActionState("select-tool", app.C.Tool_selectPdfTextLinear)
	app.changeActionState("tool-color", toolColors["pdf_linear"])
end

function toggleShortcuts()
	local db = config.read()
	db["toolColor"] = db["toolColor"] or {}

	local currentState = true
	if db["toolColor"]["enable_shortcuts"] ~= nil then
		currentState = (db["toolColor"]["enable_shortcuts"] == "true")
	end

	local newState = not currentState
	db["toolColor"]["enable_shortcuts"] = tostring(newState)
	config.write(db)

	local stateMsg = newState and "🟢 ENABLED\n(Keys w, a, s, d will switch tools WITH your colors)"
		or "🔴 DISABLED\n(Keys w, a, s, d are released."

	app.openDialog(
		"ToolColor Shortcuts are now "
			.. stateMsg
			.. ".\n\n⚠️ IMPORTANT: To apply this change, please restart Xournal++.",
		{ "Got it" }
	)
end

function cycleToolColor()
	local currentTool = app.getActionState("select-tool")
	local currentColor = app.getActionState("tool-color")

	local targetArray = CYCLE_COLORS_SOLID

	if currentTool == app.C.Tool_highlighter or currentTool == app.C.Tool_selectPdfTextLinear then
		targetArray = CYCLE_COLORS_TRANSPARENT
	elseif currentTool == app.C.Tool_pen or currentTool == app.C.Tool_text then
		targetArray = CYCLE_COLORS_SOLID
	else
		local curHex = string.lower(toHexString(currentColor))
		for _, c in ipairs(CYCLE_COLORS_TRANSPARENT) do
			if string.lower(toHexString(c)) == curHex then
				targetArray = CYCLE_COLORS_TRANSPARENT
				break
			end
		end
	end

	local nextColor = targetArray[1]
	local curHex = string.lower(toHexString(currentColor))

	for i, color in ipairs(targetArray) do
		if string.lower(toHexString(color)) == curHex then
			local nextIdx = (i % #targetArray) + 1
			nextColor = targetArray[nextIdx]
			break
		end
	end

	app.changeToolColor({ ["color"] = nextColor, ["selection"] = true })
	app.changeActionState("tool-color", nextColor)

	if TOOL_KEYS[currentTool] then
		loadColorsConfig()
		toolColors[TOOL_KEYS[currentTool]] = nextColor
		saveColorsConfig()
	end
end

function initUi()
	local db = config.read()
	local enableShortcuts = true
	if db["toolColor"] and db["toolColor"]["enable_shortcuts"] ~= nil then
		enableShortcuts = (db["toolColor"]["enable_shortcuts"] == "true")
	end

	if enableShortcuts then
		app.registerUi({ ["menu"] = "Text Tool (w)", ["callback"] = "textTool", ["accelerator"] = "w" })
		app.registerUi({
			["menu"] = "Pen Tool (a)",
			["callback"] = "penTool",
			["accelerator"] = "a",
			toolbarId = "sc_tool_pen",
			iconName = "sc_tool_pen",
		})
		app.registerUi({ ["menu"] = "Select PDF Text (s)", ["callback"] = "pdfTextTool", ["accelerator"] = "s" })
		app.registerUi({ ["menu"] = "Highlighter Tool (d)", ["callback"] = "highlighterTool", ["accelerator"] = "d" })
	end

	app.registerUi({
		["menu"] = "ToolColor: Cycle Tool Color (c)",
		["callback"] = "cycleToolColor",
		["accelerator"] = "c",
	})
	app.registerUi({ menu = "ToolColor: Setup Icons", callback = "setupShortcutIcons" })
	app.registerUi({ menu = "ToolColor: Toggle Shortcuts (On/Off)", callback = "toggleShortcuts" })

	app.registerUi({
		menu = "ToolColor: Config Base Tool",
		callback = "setCurrentToolColor",
		toolbarId = "sc_set_color",
		iconName = "sc_set_color",
	})
	app.registerUi({
		menu = "ToolColor: Config PDF Colors",
		callback = "configPdfSlots",
		toolbarId = "sc_config_pdf",
		iconName = "sc_config_pdf",
	})
	app.registerUi({
		menu = "ToolColor: Config HL Colors",
		callback = "configHlSlots",
		toolbarId = "sc_config_hl",
		iconName = "sc_config_hl",
	})

	for i = 1, 5 do
		app.registerUi({
			menu = "PDF Color: Slot " .. i,
			callback = "pdfSlot" .. i,
			toolbarId = "sc_pdf_slot" .. i,
			iconName = "sc_pdf_slot" .. i,
		})
	end
	for i = 1, 5 do
		app.registerUi({
			menu = "HL Color: Slot " .. i,
			callback = "hlSlot" .. i,
			toolbarId = "sc_hl_slot" .. i,
			iconName = "sc_hl_slot" .. i,
		})
	end
end
