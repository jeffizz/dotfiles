-- PDF Folder Browser Plugin for Xournal++
-- Opens file dialog using system tools, then opens in xournalpp via API

local config = require("config")
local pdf_folder = config.PDF_FOLDER_PATH

-- Detect OS
local function getOS()
	local handle = io.popen("uname -s 2>/dev/null")
	if handle then
		local result = handle:read("*a"):lower():gsub("\n", "")
		handle:close()
		if result:find("darwin") then
			return "macos"
		elseif result:find("linux") then
			return "linux"
		end
	end
	return "windows"
end

local current_os = getOS()

-- Register UI
function initUi()
	app.registerUi({
		["menu"] = "Open PDF from Folder",
		["callback"] = "openPdfFromFolder",
		["accelerator"] = "<Control><Shift>o",
	})
end

-- Main callback function
function openPdfFromFolder()
	-- Expand ~ to home directory
	local expanded_path = pdf_folder:gsub("^~", os.getenv("HOME") or "")

	-- Check if folder exists
	local folder_exists = io.open(expanded_path, "r")
	if not folder_exists then
		return
	end
	folder_exists:close()

	-- Open file dialog using system tools
	openFileDialog(expanded_path)
end

-- Open file dialog using system tools
function openFileDialog(folder_path)
	local cmd
	local temp_file = os.getenv("HOME") .. "/.xournalpp_selected_file"

	if current_os == "macos" then
		cmd = string.format(
			"osascript << 'EOF'\n"
				.. "try\n"
				.. '  set selectedFile to choose file default location POSIX file "%s" of type {"com.adobe.pdf"}\n'
				.. "  set selectedPath to POSIX path of selectedFile\n"
				.. '  do shell script "echo " & quoted form of selectedPath & " > %s"\n'
				.. "end try\n"
				.. "EOF",
			folder_path,
			temp_file
		)
	elseif current_os == "linux" then
		cmd = string.format(
			'zenity --file-selection --filename="%s/" --file-filter="PDF files (*.pdf) | *.pdf" --file-filter="All files (*) | *" > "%s" 2>/dev/null',
			folder_path,
			temp_file
		)
	else
		return
	end

	os.execute(cmd)
	os.execute("sleep 0.5")

	local file = io.open(temp_file, "r")
	if file then
		local filepath = file:read("*a"):gsub("\n", ""):gsub("^'", ""):gsub("'$", "")
		file:close()
		os.remove(temp_file)

		if filepath and filepath ~= "" then
			-- Only open if file is a PDF
			if filepath:lower():match("%.pdf$") then
				app.openFile(filepath, true)
			end
		end
	end
end
