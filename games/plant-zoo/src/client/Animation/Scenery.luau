--!strict
-- Cheap scenery life: tree canopies + flowers sway in a wind wave, night lanterns flicker.
-- One scan of workspace.World (after WorldReady, again later because Scenery fills in async), grouped
-- into a 40-stud grid. Every Tuning.SwayRate seconds only groups within Tuning.SwayRadius of the camera
-- move (capped at Tuning.SwayMaxParts parts, one BulkMoveTo); groups leaving range snap back.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Tuning = require(script.Parent.Tuning)

local Scenery = {}

type Group = { parts: { BasePart }, orig: { CFrame }, pivot: Vector3, amp: number, phase: number, freq: number }

local CELL = 40
local grid: { [Vector3]: { Group } } = {}
local seen: { [BasePart]: boolean } = {}
local live: { [Group]: boolean } = {}
local nextLive: { [Group]: boolean } = {}
local movParts: { BasePart } = {}
local movCF: { CFrame } = {}
local lastSway = 0

local function addGroup(parts: { BasePart }, pivot: Vector3, amp: number)
	local orig = table.create(#parts)
	for i, p in parts do
		orig[i] = p.CFrame
		seen[p] = true
	end
	local g: Group = {
		parts = parts,
		orig = orig,
		pivot = pivot,
		amp = amp,
		phase = pivot.X * 0.045 + pivot.Z * 0.03, -- travelling wind wave
		freq = 1.3 + (pivot.X * 7.3 % 1) * 0.5,
	}
	local key = Vector3.new(math.floor(pivot.X / CELL), 0, math.floor(pivot.Z / CELL))
	local cell = grid[key]
	if not cell then
		cell = {}
		grid[key] = cell
	end
	table.insert(cell, g)
end

local function scanFolder(folder: Instance)
	local trunks: { BasePart } = {}
	local balls: { BasePart } = {}
	local stems: { BasePart } = {}
	local small: { [string]: { BasePart } } = {}
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") and not seen[d] and d.Anchored then
			local s = d.Size
			if d.Name == "Trunk" then
				table.insert(trunks, d)
			elseif d:IsA("Part") and d.Shape == Enum.PartType.Ball and s.X > 3 then
				table.insert(balls, d)
			elseif math.abs(s.X - 0.2) < 0.01 and math.abs(s.Y - 1.2) < 0.01 then
				table.insert(stems, d)
			elseif s.Magnitude < 1.6 then
				local key = string.format("%.2f,%.2f", d.Position.X, d.Position.Z)
				small[key] = small[key] or {}
				table.insert(small[key], d)
			end
		elseif d:IsA("Model") then
			local n = string.lower(d.Name)
			if string.sub(n, 1, 4) == "tree" or string.sub(n, 1, 6) == "flower" then
				local parts = {}
				for _, p in d:GetDescendants() do
					if p:IsA("BasePart") and not seen[p] then
						table.insert(parts, p)
					end
				end
				if #parts > 0 and #parts <= 12 then
					local cf, size = d:GetBoundingBox()
					local amp = if string.sub(n, 1, 4) == "tree" then Tuning.TreeSway else Tuning.FlowerSway
					addGroup(parts, cf.Position - Vector3.new(0, size.Y / 2, 0), amp)
				end
			end
		end
	end
	-- primitive trees: leaf balls above + near each trunk
	for _, t in trunks do
		local h = math.max(t.Size.X, t.Size.Y)
		local base = t.Position - Vector3.new(0, h / 2, 0)
		local leaves = {}
		for _, b in balls do
			local off = b.Position - t.Position
			if not seen[b] and off.Y > 0 and Vector3.new(off.X, 0, off.Z).Magnitude < h * 0.6 then
				table.insert(leaves, b)
			end
		end
		if #leaves > 0 then
			addGroup(leaves, base, Tuning.TreeSway)
		end
	end
	-- primitive flowers: stem + bloom + centre share x/z
	for _, st in stems do
		local key = string.format("%.2f,%.2f", st.Position.X, st.Position.Z)
		local parts = { st }
		for _, p in small[key] or {} do
			table.insert(parts, p)
		end
		addGroup(parts, st.Position - Vector3.new(0, 0.6, 0), Tuning.FlowerSway)
	end
	for _, d in folder:GetChildren() do
		if (d:IsA("Folder") or d:IsA("Model")) and not string.match(string.lower(d.Name), "^tree") then
			scanFolder(d)
		end
	end
end

local function scan()
	local world = workspace:FindFirstChild("World")
	if world then
		scanFolder(world)
	end
end

local function sway(now: number, camPos: Vector3)
	table.clear(movParts)
	table.clear(movCF)
	table.clear(nextLive)
	local r = Tuning.SwayRadius
	local cx, cz = math.floor(camPos.X / CELL), math.floor(camPos.Z / CELL)
	local span = math.ceil(r / CELL)
	local budget = Tuning.SwayMaxParts
	for x = cx - span, cx + span do
		for z = cz - span, cz + span do
			local cell = grid[Vector3.new(x, 0, z)]
			if cell and budget > 0 then
				for _, g in cell do
					if budget <= 0 then
						break
					end
					if g.parts[1].Parent and (g.pivot - camPos).Magnitude <= r then
						local a = g.amp * math.sin(now * g.freq + g.phase)
						local b = g.amp * 0.6 * math.sin(now * g.freq * 0.73 + g.phase * 1.3)
						local rot = CFrame.new(g.pivot) * CFrame.Angles(a, 0, b) * CFrame.new(-g.pivot)
						for i, p in g.parts do
							table.insert(movParts, p)
							table.insert(movCF, rot * g.orig[i])
						end
						budget -= #g.parts
						nextLive[g] = true
					end
				end
			end
		end
	end
	for g in live do
		if not nextLive[g] then
			for i, p in g.parts do
				table.insert(movParts, p)
				table.insert(movCF, g.orig[i])
			end
		end
	end
	live, nextLive = nextLive, live
	if #movParts > 0 then
		workspace:BulkMoveTo(movParts, movCF, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Lantern flicker -----------------------------------------------------------------------------------
local lights: { [PointLight]: number } = {}

local function flicker(now: number, camPos: Vector3)
	if Lighting:GetAttribute("IsNight") ~= true then
		return
	end
	for _, p in CollectionService:GetTagged("NightLight") do
		if p:IsA("BasePart") and (p.Position - camPos).Magnitude <= Tuning.FlickerRadius then
			local l = p:FindFirstChildOfClass("PointLight")
			if l and l.Enabled then
				local base = lights[l]
				if not base then
					base = l.Brightness
					lights[l] = base
				end
				local k = p.Position.X * 1.7 + p.Position.Z
				l.Brightness = base * (0.88 + 0.08 * math.sin(now * 7 + k) + 0.04 * math.sin(now * 17.3 + k * 2))
			end
		end
	end
end

function Scenery.Step(now: number, camPos: Vector3)
	if now - lastSway < Tuning.SwayRate then
		return
	end
	lastSway = now
	sway(now, camPos)
	flicker(now, camPos)
end

function Scenery.Start()
	task.spawn(function()
		if not workspace:GetAttribute("WorldReady") then
			workspace:GetAttributeChangedSignal("WorldReady"):Wait()
		end
		for _, delay in { 6, 25 } do
			task.wait(delay)
			scan()
		end
	end)
end

return Scenery
