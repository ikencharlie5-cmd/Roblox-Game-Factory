--!strict
-- Shows the server-set player Attribute "ChatTag" (e.g. "[VIP]") in front of chat names.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatTags = {}

function ChatTags.Start()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		if source then
			local p = Players:GetPlayerByUserId(source.UserId)
			local tag = if p then p:GetAttribute("ChatTag") else nil
			if type(tag) == "string" and tag ~= "" then
				props.PrefixText = string.format('<font color="#FFB300">%s</font> %s', tag, message.PrefixText)
			end
		end
		return props
	end
end

return ChatTags
