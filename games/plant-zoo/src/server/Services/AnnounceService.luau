--!strict
-- Server-wide toasts ("PLAYER grew a RAINBOW Moonpetal Unicorn!") + cross-server for Secrets.
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local AnnounceService = {}

local TOPIC = "SproutZooAnnounce"
local myJobId = game.JobId

-- rarity: rarity name (UI colours the toast) or nil
function AnnounceService.Send(text: string, rarity: string?, crossServer: boolean?)
	Remotes.Event("Announce"):FireAllClients(text, rarity)
	if crossServer then
		task.spawn(function()
			local ok, err = pcall(function()
				MessagingService:PublishAsync(TOPIC, { text = text, rarity = rarity, job = myJobId })
			end)
			if not ok then
				warn("[AnnounceService] publish failed:", err)
			end
		end)
	end
end

function AnnounceService.Start()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(msg)
			local d = msg.Data
			if type(d) == "table" and d.job ~= myJobId and type(d.text) == "string" then
				Remotes.Event("Announce"):FireAllClients("[Global] " .. d.text, d.rarity)
			end
		end)
	end)
	if not ok then
		warn("[AnnounceService] subscribe failed (normal in Studio):", err)
	end
end

return AnnounceService
