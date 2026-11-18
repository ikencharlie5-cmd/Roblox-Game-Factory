--!strict
-- Cheap world life: tree sway, night lantern flicker, and the placement "thud" when a build item
-- appears in your own plot. Sway models: tag "Sway" (optional number attribute Sway = amplitude in rad),
-- and canopies found around every part named "Trunk" (scanned 6 / 30 / 90 s after join).
-- Trunk/Stem/Pot/Base parts and Wood stay put.
-- Lanterns: tag "Lantern" or "NightLight" (not on creatures); their Lights flicker at night.
-- Placed items: Models with attribute ItemId or tag "PlacedItem" drop in with dust when new.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Batch = require(script.Parent.Batch)
local Fx = require(script.Parent.Fx)
local Tuning = require(script.Parent.Tuning)

local Scenery = {}

type Sway = { parts: { BasePart }, rest: { CFrame }, base: CFrame, amp: number, phase: number, on: boolean }
type Drop = { parts: { BasePart }, rest: { CFrame }, base: CFrame, t0: number, dusted: boolean }

local sways: { [Instance]: Sway } = {}
local active: { Sway } = {}
local lights: { [Light]: number } = {}
local drops: { Drop } = {}
local startedAt = os.clock()
local lastCull, lastSway = 0, 0
local STILL = { "trunk", "stem", "pot", "base", "root" }

local function still(p: BasePart): boolean
	if p.Material == Enum.Material.Wood or p.Material == Enum.Material.WoodPlanks then
		return true
	end
	local n = string.lower(p.Name)
	for _, w in STILL do
		if string.find(n, w) then
			return true
		end
	end
	return false
end

local function addSway(inst: Instance)
	if sways[inst] or not inst:IsA("Model") then
		return
	end
	local m = inst :: Model
	local cf, size = m:GetBoundingBox()
	local base = CFrame.new(cf.Position - Vector3.new(0, size.Y * 0.5, 0))
	local parts, rest = {}, {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and not still(d) then
			table.insert(parts, d)
			table.insert(rest, base:ToObjectSpace(d.CFrame))
		end
	end
	if #parts == 0 then
		return
	end
	local a = m:GetAttribute("Sway")
	local tree = string.find(string.lower(m.Name), "tree") ~= nil or size.Y > 8
	sways[m] = {
		parts = parts,
		rest = rest,
		base = base,
		amp = if typeof(a) == "number" then a elseif tree then Tuning.TreeSway else Tuning.FlowerSway,
		phase = (base.Position.X + base.Position.Z) * 0.05,
		on = false,
	}
end

local claimed: { [BasePart]: boolean } = {}

local function halfY(p: BasePart): number
	local cf, sz = p.CFrame, p.Size
	return 0.5 * (math.abs(cf.XVector.Y) * sz.X + math.abs(cf.YVector.Y) * sz.Y + math.abs(cf.ZVector.Y) * sz.Z)
end

-- Graphics builds trees straight into cluster models, so group canopy parts around each "Trunk":
-- non-wood siblings within reach above the trunk base sway about that base.
local function scanTrunks()
	for _, inst in workspace:GetDescendants() do
		if inst.Name ~= "Trunk" or not inst:IsA("BasePart") then
			continue
		end
		local d = inst :: BasePart
		if claimed[d] then
			continue
		end
		claimed[d] = true
		local parent = d.Parent
		if not parent then
			continue
		end
		local hy = halfY(d)
		local base = d.Position - Vector3.new(0, hy, 0)
		local reach = math.max(6, hy * 2 * 1.6)
		local parts, rest = {}, {}
		local baseCf = CFrame.new(base)
		for _, s in parent:GetChildren() do
			if s:IsA("BasePart") and not claimed[s] and not still(s) then
				local off = s.Position - base
				if off.Y > hy and Vector3.new(off.X, 0, off.Z).Magnitude < reach and off.Y < reach * 2 then
					claimed[s] = true
					table.insert(parts, s)
					table.insert(rest, baseCf:ToObjectSpace(s.CFrame))
				end
			end
		end
		if #parts > 0 then
			sways[d] = {
				parts = parts,
				rest = rest,
				base = baseCf,
				amp = Tuning.TreeSway,
				phase = (base.X + base.Z) * 0.05,
				on = false,
			}
		end
	end
end

local function addLantern(inst: Instance)
	local owner = inst:FindFirstAncestorOfClass("Model")
	if owner and owner:GetAttribute("Species") ~= nil then
		return -- creature glow lights belong to the creature animator
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("Light") and not lights[d] then
			lights[d] = d.Brightness
		end
	end
end

-- Only items in the local player's own plot drop in (other plots stream in and must not "drop").
local function inMyPlot(inst: Instance): boolean
	local me = Players.LocalPlayer
	local a: Instance? = inst
	while a and a ~= workspace do
		local o = a:GetAttribute("OwnerId") or a:GetAttribute("Owner")
		if o ~= nil then
			return o == me.UserId or o == me.Name or o == tostring(me.UserId)
		end
		a = a.Parent
	end
	return false
end

local function addDrop(inst: Instance)
	if not inst:IsA("Model") or os.clock() - startedAt < Tuning.ArmDelay or not inMyPlot(inst) then
		return
	end
	if inst:GetAttribute("Species") ~= nil or CollectionService:HasTag(inst, "Creature") then
		return
	end
	local cam = workspace.CurrentCamera
	local pivot = (inst :: Model):GetPivot()
	if not cam or (pivot.Position - cam.CFrame.Position).Magnitude > 120 then
		return
	end
	local parts, rest = {}, {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(rest, pivot:ToObjectSpace(d.CFrame))
		end
	end
	if #parts > 0 and #parts <= 120 then
		table.insert(drops, { parts = parts, rest = rest, base = pivot, t0 = os.clock(), dusted = false })
	end
end

function Scenery.Start()
	for _, m in CollectionService:GetTagged("Sway") do
		addSway(m)
	end
	CollectionService:GetInstanceAddedSignal("Sway"):Connect(addSway)
	for _, tag in { "Lantern", "NightLight" } do
		for _, m in CollectionService:GetTagged(tag) do
			addLantern(m)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(addLantern)
	end
	CollectionService:GetInstanceAddedSignal("PlacedItem"):Connect(addDrop)
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Model") and d:GetAttribute("ItemId") ~= nil and not CollectionService:HasTag(d, "PlacedItem") then
			task.defer(addDrop, d) -- deferred so the model's parts are parented first
		end
	end)
	for _, t in { 6, 30, 90 } do
		task.delay(t, scanTrunks)
	end
end

local function stepDrops(now: number)
	for i = #drops, 1, -1 do
		local d = drops[i]
		local p = (now - d.t0) / 0.45
		local dy, s = 0, 0
		if p >= 1 then
			table.remove(drops, i)
		elseif p < 0.6 then
			local q = p / 0.6
			dy = Tuning.ThudDrop * (1 - q * q)
		else
			local q = (p - 0.6) / 0.4
			s = math.sin(math.pi * q) * (1 - q)
			if not d.dusted then
				d.dusted = true
				Fx.Burst("Dust", d.base.Position, 10)
				Fx.Ring(d.base.Position, Color3.fromRGB(240, 225, 190), 3)
			end
		end
		local f = d.base * CFrame.new(0, dy - 0.15 * s, 0)
		for j, part in d.parts do
			if part.Parent then
				Batch.Add(part, f * d.rest[j])
			end
		end
	end
end

function Scenery.Step(now: number, camPos: Vector3, night: boolean)
	stepDrops(now)
	if now - lastCull > 0.5 then
		lastCull = now
		local near: { { s: Sway, d: number } } = {}
		for _, s in sways do
			local d = (s.base.Position - camPos).Magnitude
			if d <= Tuning.SwayRadius then
				table.insert(near, { s = s, d = d })
			end
		end
		table.sort(near, function(a, b)
			return a.d < b.d
		end)
		for _, s in active do
			s.on = false
		end
		local prev = active
		active = {}
		local budget = Tuning.SwayMaxParts
		for _, e in near do
			if #e.s.parts > budget then
				break
			end
			budget -= #e.s.parts
			e.s.on = true
			table.insert(active, e.s)
		end
		for _, s in prev do
			if not s.on then
				for i, p in s.parts do
					Batch.Add(p, s.base * s.rest[i]) -- snap back when leaving range
				end
			end
		end
		-- lantern flicker (only at night, near the camera)
		for l in lights do
			if not l.Parent then
				lights[l] = nil
			end
		end
	end
	if now - lastSway >= Tuning.SwayRate then
		lastSway = now
		for _, s in active do
			if not s.parts[1].Parent then
				continue
			end
			local a = s.amp * (math.sin(now * 1.3 + s.phase) + 0.4 * math.sin(now * 2.7 + s.phase * 1.7))
			local r = s.base * CFrame.Angles(a * 0.6, 0, a)
			for i, p in s.parts do
				Batch.Add(p, r * s.rest[i])
			end
		end
		for l, b in lights do
			local parent = l.Parent
			if night and parent and parent:IsA("BasePart") and (parent.Position - camPos).Magnitude < Tuning.FlickerRadius then
				l.Brightness = b * (1 + 0.12 * math.noise(now * 4, b * 10))
			end
		end
	end
end

return Scenery
