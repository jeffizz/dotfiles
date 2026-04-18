local utils = {}

function utils.urlEncode(str)
	if str then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w %-%_%.%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = str:gsub(" ", "%%20")
	end
	return str
end

function utils.getClipboardText()
	local os_type = "unknown"
	if package.config:sub(1, 1) == "\\" then
		os_type = "Windows"
	else
		local handle = io.popen("uname -s")
		if handle then
			local result = handle:read("*l")
			handle:close()
			os_type = (result == "Darwin") and "macOS" or "Linux"
		end
	end

	local cmd = (os_type == "macOS") and "pbpaste"
		or (os_type == "Windows") and 'powershell -command "Get-Clipboard"'
		or "wl-paste 2>/dev/null || xclip -selection clipboard -o 2>/dev/null"

	local handle = io.popen(cmd)
	if not handle then
		return ""
	end

	local result = handle:read("*a")
	handle:close()
	return (result:gsub("^%s*(.-)%s*$", "%1"))
end

utils.icons = {
	tran = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#3498DB"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">Tran</text></svg>]],
	te = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#9B59B6"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">T&amp;E</text></svg>]],
	sum = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#27AE60"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">Sum</text></svg>]],
	smart = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#E67E22"/><text x="12" y="16" font-family="Arial" font-size="7" font-weight="bold" fill="white" text-anchor="middle">Smart</text></svg>]],
}

return utils
