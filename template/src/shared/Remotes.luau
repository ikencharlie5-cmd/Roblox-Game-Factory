--!strict
-- Declare every remote here. Server creates them; client waits for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"DataChanged", -- server -> client: (data)
	"Notify", -- server -> client: (text)
	"ClaimDaily", -- client -> server: ()
	"PlaySound", -- server -> client: (soundName)
}

local FUNCTIONS: { string } = {}

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
