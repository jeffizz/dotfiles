-- Configuration file for PDF Folder Browser plugin
-- Modify the PDF_FOLDER_PATH to your desired folder

return {
	-- Set your PDF folder path here
	-- Examples:
	-- Linux/Mac: "/home/user/Documents/PDFs" or "~/Documents/PDFs"
	-- Windows: "C:\\Users\\user\\Documents\\PDFs"
	PDF_FOLDER_PATH = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Books",
}
