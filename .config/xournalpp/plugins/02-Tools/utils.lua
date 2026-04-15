local utils = {}

-- Simple URL encoding to ensure special characters in the clipboard (like &, %, #) don't break the Deeplink
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

-- Get clipboard text (for macOS)
function utils.getClipboardText()
	local handle = io.popen("pbpaste")
	local result = handle:read("*a")
	handle:close()
	return result
end

-- Icon data: Tran, T&E, Sum
utils.icons = {
	tran = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#3498DB"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">Tran</text></svg>]],
	te = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#9B59B6"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">T&amp;E</text></svg>]],
	sum = [[<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#27AE60"/><text x="12" y="16" font-family="Arial" font-size="9" font-weight="bold" fill="white" text-anchor="middle">Sum</text></svg>]],
}

return utils
