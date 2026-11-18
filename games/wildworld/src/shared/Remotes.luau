--!strict
-- Declare every remote here. Server creates them; client waits for them.
-- Client -> server remotes are RemoteFunctions returning (ok: boolean, result).
-- On failure `result` is an error string and the server already sent Toast + PlaySound("Error").
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- server -> client
local EVENTS = {
	"DataChanged", -- (data) full save table, batched
	"Toast", -- (text, kind) kind: "info" | "success" | "error" | "reward" | "weather"
	"Notify", -- alias of Toast (template UI)
	"Reveal", -- (kind, data) see notes/gameplay.md
	"PlaySound", -- (name, opts?) opts = {position=Vector3?, pitch=number?, species=string?}
	"VisitorTip", -- (amount, position) coin fountain at the habitat
	"HabitatChanged", -- (padUid, result) rating + checklist for one of YOUR pads
	"ShopChanged", -- (shop)
	"CaptureState", -- (wildId, state) state: {trust, claimedBy, attemptsLeft} or nil
}

-- client -> server (RemoteFunction, all validated + rate-limited)
local FUNCTIONS = {
	"PlaceItem", -- (itemId, cellX, cellZ, rot)
	"RotateItem", -- (itemUid, rot)
	"MoveItem", -- (itemUid, cellX, cellZ, rot)
	"RemoveItem", -- (itemUid)
	"RefillStation", -- (itemUid) food bowl
	"GetHabitat", -- (padUid) -> rating + checklist
	"AssignCreature", -- (uid, padUid | nil)
	"FeedCreature", -- (uid)
	"PetCreature", -- (uid)
	"RenameCreature", -- (uid, name)
	"SellCreature", -- (uid)
	"ThrowBait", -- (position, baitId?)
	"CaptureStart", -- (wildId) -> window
	"CaptureRelease", -- (wildId) -> result
	"Breed", -- (uidA, uidB) -> eggId
	"HatchEgg", -- (eggId) -> creature uid
	"ScanGenes", -- (uid)
	"BuyUpgrade", -- (key)
	"UnlockZone", -- (zoneId)
	"BuyShop", -- (slotIndex)
	"GetShop", -- () -> shop
	"ClaimDaily", -- ()
	"ClaimQuest", -- (index)
	"RerollQuest", -- (index)
	"VisitPlot", -- (userId)
	"LikePark", -- (userId)
	"ReturnHome", -- ()
	"RequestInstantHatch", -- (eggId) -> prompts the right product
	"PromptPurchase", -- (kind "pass"|"product", key)
	"GetTopParks", -- () -> list
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
