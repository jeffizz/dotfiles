local actions = require("actions")

function initUi()
	app.registerUi({
		menu = "AI: Setup Toolbar Icons",
		callback = "setupIcons",
	})

	app.registerUi({
		menu = "AI: Set Dictionary App",
		callback = "selectDictApp",
	})

	app.registerUi({
		menu = "AI: Smart Translate",
		callback = "smartTranslateClipboard",
		toolbarId = "ai_smart_translate",
		iconName = "ai_smart",
		accelerator = "<Alt>d",
	})

	app.registerUi({
		menu = "AI: Translate Only",
		callback = "translateOnly",
		toolbarId = "ai_translate_only",
		iconName = "ai_tran",
	})

	app.registerUi({
		menu = "AI: Translate & Explain",
		callback = "translateAndExplain",
		toolbarId = "ai_trans_and_explain",
		iconName = "ai_te",
	})

	app.registerUi({
		menu = "AI: Tech Summary",
		callback = "summarize",
		toolbarId = "ai_summary",
		iconName = "ai_sum",
	})
end

function translateOnly()
	actions.translateOnly()
end
function translateAndExplain()
	actions.translateAndExplain()
end
function summarize()
	actions.summarize()
end
function setupIcons()
	actions.setupIcons()
end

function smartTranslateClipboard()
	actions.smartTranslateClipboard()
end
function selectDictApp()
	actions.selectDictApp()
end
function onDictDialogResult(idx)
	actions.onDictDialogResult(idx)
end
