function initUi()
	app.registerUi({
		["menu"] = "Add My Ruled Paper Template",
		["callback"] = "addPageTemplate",
		["accelerator"] = "",
	})
	app.registerUi({
		["menu"] = "Open New Window",
		["callback"] = "openNewWindow",
		["accelerator"] = "<Alt>n",
	})
end

-- Get the path to pagetemplates.ini based on OS
function getPageTemplatesPath()
	local home = os.getenv("HOME")
	local userprofile = os.getenv("USERPROFILE")

	if userprofile then
		-- Windows
		local programFiles = os.getenv("ProgramFiles")
		if programFiles then
			return programFiles .. "\\Xournal++\\share\\xournalpp\\ui\\pagetemplates.ini"
		end
		return "C:\\Program Files\\Xournal++\\share\\xournalpp\\ui\\pagetemplates.ini"
	elseif home then
		-- macOS or Linux
		local macPath = "/Applications/xournal++.app/Contents/Resources/ui/pagetemplates.ini"
		local file = io.open(macPath, "r")
		if file then
			file:close()
			return macPath
		end
		return "/usr/share/xournalpp/ui/pagetemplates.ini"
	end

	return nil
end

-- Check if a template section already exists in the file
function templateExists(filePath, templateName)
	local file = io.open(filePath, "r")
	if not file then
		return false
	end

	local content = file:read("*a")
	file:close()

	local pattern = "%[" .. templateName .. "%]"
	return string.find(content, pattern) ~= nil
end

-- Read file content
function readFile(filePath)
	local file = io.open(filePath, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()
	return content
end

-- Append content to file
function appendFile(filePath, content)
	local file = io.open(filePath, "a")
	if not file then
		return false
	end

	file:write(content)
	file:close()
	return true
end

-- Callback for dialog result - quit application
function onDialogResult(button)
	if button == 1 then
		-- User clicked OK, quit the application
		app.activateAction("quit")
	end
end

-- Main function to add page template
function addPageTemplate()
	local templatePath = getPageTemplatesPath()

	if not templatePath then
		app.openDialog("Error: Could not determine pagetemplates.ini path", { "OK" }, "", true)
		return
	end

	-- Check if pagetemplates.ini exists
	local file = io.open(templatePath, "r")
	if not file then
		app.openDialog("Error: pagetemplates.ini not found at:\n" .. templatePath, { "OK" }, "", true)
		return
	end
	file:close()

	-- Template configuration
	local templateName = "myRuledPaper"
	local templateConfig = [[

[myRuledPaper]
name=My-Ruled-Paper
format=ruled
config=r1=20,f1=0xD6D8D6]]

	-- Check if template already exists
	if templateExists(templatePath, templateName) then
		app.openDialog("Template '" .. templateName .. "' already exists.\nNo changes made.", { "OK" })
		return
	end

	-- Append the new template to pagetemplates.ini
	if not appendFile(templatePath, templateConfig) then
		app.openDialog("Error: Failed to write to pagetemplates.ini at:\n" .. templatePath, { "OK" }, "", true)
		return
	end

	-- Success message
	app.openDialog(
		"Page template added successfully!\n\n✓ Template name: My Ruled Paper\n✓ Format: Ruled\n✓ Line spacing: 20\n✓ Line color: #D6D8D6\n\nYou can select this template after restart.",
		{ "Restart Required!" },
		"onDialogResult"
	)
end

function openNewWindow()
	local cmd = "open -n -a Xournal++ &"
	os.execute(cmd)
end
