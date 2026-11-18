--!strict
-- Finds creatures and eggs in the world for the context bar, nameplates and tutorial arrows.
-- Server markup (notes/gameplay.md "Attributes"):
--   park creatures: tag "Creature" / workspace.Creatures; Uid, OwnerId, Species, Nickname, Happy, Mutations
--   wild creatures: tag "WildCreature" / workspace.WildCreatures; WildId, Species, Trust, ClaimedBy
--   eggs: any instance with EggId + OwnerId (starter egg sits in the plot folder; ReadyAt optional)
--   placed items: tag "ParkItem"; ItemUid, ItemId, OwnerId. Forest arch: tag "ForestGate".
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local WorldQuery = {}

local player = Players.LocalPlayer :: Player

local function gather(tag: string, folders: { string }): { Instance }
	local out = CollectionService:GetTagged(tag)
	for _, name in folders do
		local f = workspace:FindFirstChild(name)
		if f then
			for _, c in f:GetChildren() do
				if not table.find(out, c) then
					table.insert(out, c)
				end
			end
		end
	end
	return out
end

function WorldQuery.Pos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	elseif inst:IsA("Attachment") then
		return inst.WorldPosition
	end
	return nil
end

function WorldQuery.IsMine(inst: Instance): boolean
	local o = inst:GetAttribute("OwnerId") or inst:GetAttribute("Owner")
	return o == player.UserId or o == player.Name
end

function WorldQuery.Creatures(): { Instance }
	local out = gather("Creature", { "Creatures" })
	for _, w in gather("WildCreature", { "WildCreatures" }) do
		table.insert(out, w)
	end
	return out
end

-- Eggs: tagged "Egg" plus anything under workspace.ParkObjects with an EggId attribute (cached 2 s).
local eggCache: { Instance } = {}
local eggAt = 0
function WorldQuery.Eggs(): { Instance }
	if os.clock() - eggAt < 2 then
		return eggCache
	end
	eggAt = os.clock()
	local out = CollectionService:GetTagged("Egg")
	local root = workspace:FindFirstChild("ParkObjects")
	if root then
		for _, d in root:GetDescendants() do
			if d:GetAttribute("EggId") ~= nil and not table.find(out, d) then
				table.insert(out, d)
			end
		end
	end
	eggCache = out
	return out
end

-- My placed item by ItemId (e.g. "FoodBowl").
function WorldQuery.MyItem(itemId: string): Instance?
	for _, inst in CollectionService:GetTagged("ParkItem") do
		if inst:GetAttribute("ItemId") == itemId and WorldQuery.IsMine(inst) then
			return inst
		end
	end
	return nil
end

function WorldQuery.MyPos(): Vector3?
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp.Position else nil
end

-- Nearest instance from `list` within `range` studs that passes `filter`.
function WorldQuery.Nearest(list: { Instance }, range: number, filter: ((Instance) -> boolean)?): (Instance?, number)
	local me = WorldQuery.MyPos()
	if not me then
		return nil, math.huge
	end
	local best, bestD = nil, range
	for _, inst in list do
		if inst.Parent and (not filter or filter(inst)) then
			local p = WorldQuery.Pos(inst)
			if p then
				local d = (p - me).Magnitude
				if d <= bestD then
					best, bestD = inst, d
				end
			end
		end
	end
	return best, bestD
end

-- A named landmark (tag first, then a descendant by name), e.g. "FoodBowl", "ForestGate".
function WorldQuery.Landmark(name: string, mineOnly: boolean?): Instance?
	local tagged = CollectionService:GetTagged(name)
	if mineOnly then
		for _, inst in tagged do
			if WorldQuery.IsMine(inst) then
				return inst
			end
		end
	end
	return tagged[1] or workspace:FindFirstChild(name, true)
end

function WorldQuery.MyEgg(): Instance?
	local mine = {}
	for _, e in WorldQuery.Eggs() do
		if WorldQuery.IsMine(e) then
			table.insert(mine, e)
		end
	end
	return mine[1]
end

function WorldQuery.MyCreature(uid: any?): Instance?
	for _, c in WorldQuery.Creatures() do
		if WorldQuery.IsMine(c) and (uid == nil or tostring(c:GetAttribute("Uid")) == tostring(uid)) then
			return c
		end
	end
	return nil
end

return WorldQuery
