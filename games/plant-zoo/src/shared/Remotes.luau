--!strict
-- Declare every remote here. Server creates them; client waits for them.
-- Args + return values are documented in notes/gameplay.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- RemoteEvents (server -> client unless noted)
local EVENTS = {
	"DataChanged", -- (data)
	"StockChanged", -- (stock)
	"WeatherChanged", -- (info)
	"Announce", -- (text, rarity?)
	"Notify", -- (text, kind?)
	"OfflineEarnings", -- (amount, seconds)
	"PlaySound", -- (soundName, extra?)
	"OpenScreen", -- (screenName)
}

-- RemoteFunctions (client -> server). All return (ok: boolean, resultOrError: any)
local FUNCTIONS: { string } = {
	"GetStock",
	"BuySeed",
	"PlaceItem",
	"MoveItem",
	"RemoveItem",
	"SellCreature",
	"Water",
	"BuyPad",
	"SetPadBiome",
	"UnlockBiome",
	"BuyDecor",
	"BuyUpgrade",
	"Release",
	"ClaimDaily",
	"ClaimQuest",
	"UseHopeItem",
	"BuyHopeItem",
	"VisitPlot",
	"LikeZoo",
	"GoHome",
}

local Remotes = {}

local folder: Folder
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	for _, name in FUNCTIONS do
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Remotes.Event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.Function(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
