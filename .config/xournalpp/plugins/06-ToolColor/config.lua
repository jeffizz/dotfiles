local config = {}

local function getPluginDir()
	local source = debug.getinfo(1, "S").source
	local scriptPath = source:sub(1, 1) == "@" and source:sub(2) or source
	return scriptPath:match("(.*[/\\])") or ""
end

local function getConfigPath()
	return getPluginDir() .. "plugin.ini"
end

function config.parse(text)
	local db = {}
	local currentSection = "Global"
	for line in text:gmatch("[^\r\n]+") do
		local cleanLine = line:match("^%s*(.-)%s*$")
		if cleanLine ~= "" and cleanLine:sub(1, 1) ~= "#" and cleanLine:sub(1, 1) ~= ";" then
			local section = cleanLine:match("^%[([^%]]+)%]$")
			if section then
				currentSection = section
				db[currentSection] = db[currentSection] or {}
			else
				local k, v = cleanLine:match("^([^=:]+)[=:]%s*(.+)$")
				if k and v then
					k = k:match("^%s*(.-)%s*$")
					v = v:match("^%s*(.-)%s*$")
					db[currentSection] = db[currentSection] or {}
					db[currentSection][k] = v
				end
			end
		end
	end
	return db
end

function config.stringify(db)
	local lines = {}
	local sections = {}
	for s in pairs(db) do
		table.insert(sections, s)
	end
	table.sort(sections, function(a, b)
		if a == "about" then
			return true
		end
		if b == "about" then
			return false
		end
		return a < b
	end)

	for _, section in ipairs(sections) do
		table.insert(lines, "[" .. section .. "]")
		for k, v in pairs(db[section]) do
			table.insert(lines, k .. "=" .. tostring(v))
		end
		table.insert(lines, "")
	end
	return table.concat(lines, "\n")
end

function config.read()
	local path = getConfigPath()
	local file = io.open(path, "r")
	if not file then
		return {}
	end
	local content = file:read("*a")
	file:close()
	return config.parse(content)
end

function config.write(db)
	local path = getConfigPath()
	local file = io.open(path, "w")
	if file then
		file:write(config.stringify(db))
		file:close()
		return true
	end

	app.openDialog("⚠️ Error: Cannot write config file. Please check folder permissions:\n" .. path, { "OK" })
	return false
end

return config
