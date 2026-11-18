--!strict
-- Finds creatures and eggs in the world for the context bar, nameplates and tutorial arrows.
-- Expected server markup (see notes/ui.md):
--   creatures: tag "Creature" (or children of workspace.Creatures / workspace.Wild), attributes
--     Uid (owned) or WildId (wild), OwnerId (number, owned only), Species, Nickname?, Happy?, Mutations?
--   eggs: tag "Egg", attributes EggId, OwnerId, ReadyAt (server time)
--   tutorial targets: tag "FoodBowl", "ForestGate" (or parts with those names)
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
	return gather("Creature", { "Creatures", "Wild", "WildCreatures" })
end

function WorldQuery.Eggs(): { Instance }
	return gather("Egg", { "Eggs" })
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
