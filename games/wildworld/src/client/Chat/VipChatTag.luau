--!strict
-- Gold [VIP] chat prefix for players with the server-set "VIP" attribute.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local VipChatTag = {}

function VipChatTag.Start()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
		local source = message.TextSource
		if not source then
			return nil
		end
		local p = Players:GetPlayerByUserId(source.UserId)
		if not (p and p:GetAttribute("VIP")) then
			return nil
		end
		local props = Instance.new("TextChatMessageProperties")
		props.PrefixText = '<font color="#FFCD32"><b>[VIP]</b></font> ' .. message.PrefixText
		return props
	end
end

return VipChatTag
