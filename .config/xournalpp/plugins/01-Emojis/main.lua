local emojis = {
	{ emoji = "🎯", desc = ":dart: \t\t(定义|结论总结)" },
	{ emoji = "⭐", desc = ":star: \t\t(黄金法则|金句)" },
	{ emoji = "💎", desc = ":gem: \t\t(精华|见解)" },
	{ emoji = "📌", desc = ":pushpin: \t\t(重点|复习停留)" },
	{ emoji = "🔥", desc = ":fire: \t\t\t(强烈推荐|亮点)" },
	{ emoji = "🔑", desc = ":key: \t\t\t(关键|定义|概念)" },

	{ emoji = "⚠️", desc = ":warning: \t\t(易错/混淆|有条件)" },
	{ emoji = "🔴", desc = ":red_circle: \t(错误示范|反模式)" },
	{ emoji = "❌", desc = ":cross_mark: \t(避坑|陷阱)" },
	{ emoji = "🔔", desc = ":bell: \t\t\t(注意事项)" },

	{ emoji = "🤔", desc = ":thinking: \t\t(感悟|存疑)" },
	{ emoji = "🔍", desc = ":mag: \t\t(查阅|扩展)" },
	{ emoji = "💡", desc = ":bulb: \t\t(豁开|巧妙)" },
	{ emoji = "❓", desc = ":question: \t(没懂|疑问)" },

	{ emoji = "🛠️", desc = ":hammer: \t\t(实践练习)" },
	{ emoji = "📅", desc = ":scroll: \t\t(背景|历史)" },

	{ emoji = "💬", desc = ":speech: \t\t(摘抄|引用)" },
	{ emoji = "🔗", desc = ":link: \t\t\t(跳转|关联)" },
}

function initUi()
	for i, item in ipairs(emojis) do
		local menuName = item.emoji .. " " .. item.desc
		local callbackName = "insert_emoji_" .. i

		_G[callbackName] = function()
			insertEmoji(item.emoji)
		end

		app.registerUi({
			["menu"] = menuName,
			["callback"] = callbackName,
		})
	end
end

function insertEmoji(emoji)
	local success = false

	local home = os.getenv("HOME")

	if home then
		local tempFile = home .. "/.xournalpp_emoji_temp.txt"

		local file = io.open(tempFile, "w")
		if file then
			file:write(emoji)
			file:close()

			local cmd = "pbcopy < " .. tempFile .. " 2>/dev/null"
			local result = os.execute(cmd)

			if result == 0 or result == true then
				success = true
			else
				cmd = "cat " .. tempFile .. " | xclip -selection clipboard 2>/dev/null"
				result = os.execute(cmd)

				if result == 0 or result == true then
					success = true
				else
					cmd = "cat " .. tempFile .. " | xsel -b 2>/dev/null"
					result = os.execute(cmd)

					if result == 0 or result == true then
						success = true
					end
				end
			end

			os.remove(tempFile)
		end
	else
		local tempFile = os.getenv("TEMP") .. "\\xournalpp_emoji_temp.txt"

		local file = io.open(tempFile, "w")
		if file then
			file:write(emoji)
			file:close()

			local cmd = "clip < " .. tempFile .. " 2>nul"
			local result = os.execute(cmd)

			if result == 0 or result == true then
				success = true
			end

			os.remove(tempFile)
		end
	end

	if success then
		app.uiAction({ ["action"] = "ACTION_PASTE" })
	end
end
