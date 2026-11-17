--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Hud = require(script.Parent:WaitForChild("UI"):WaitForChild("Hud"))

Hud.Mount()

Remotes.Event("DataChanged").OnClientEvent:Connect(function(data)
	Hud.SetData(data)
end)

Remotes.Event("Notify").OnClientEvent:Connect(function(text: string)
	Hud.Notify(text)
end)
