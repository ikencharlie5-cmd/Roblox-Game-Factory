--!strict
-- 8 player plots (128x128) in a ring around the hub, brick style: smooth pale base (locked land) with a
-- studded green Land plate on top for the unlocked square. Model "Plot<i>": pivot = floor-top centre, -Z faces
-- the hub (entrance). Children: Base, Land (unlocked square), Border, Gate (arch + glowing name sign),
-- Spawn (tag PlotSpawn), Dressing, Items/, Creatures/.
-- The Base part carries tag "Plot" (its top surface = plot ground, LookVector -> hub) with attributes
-- PlotIndex, OwnerId (0 = free), OwnerName, LandSize (studs 64..128). Gameplay (PlotService) writes
-- OwnerId/OwnerName/LandSize; this module listens and updates the sign, floor colour and Land square.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)
local Scatter = require(script.Parent.Scatter)

local Kit, Nature, Structures, P = Theme.Kit, Theme.Nature, Theme.Structures, Theme.Colors
local V = Vector3.new
local Plots = {}

local SIZE = Layout.PlotSize
local HALF = SIZE / 2
local GATE_W = 14
local LAND_H = 0.4 -- studded land plate, top 0.02 above the plot floor (items sit on the floor top)

local plots: { Model } = {}

local function sign(m: Model, cf: CFrame): TextLabel
	local gate = Kit.Model(m, "Gate")
	for _, x in { -GATE_W / 2 - 1, GATE_W / 2 + 1 } do
		Kit.Brick(gate, V(2, 11, 2), cf * CFrame.new(x, 5.5, 0), P.WoodDark, "All", true)
		Kit.Brick(gate, V(3, 2.4, 3), cf * CFrame.new(x, 12.2, 0), P.Leaf2, "All")
		Kit.Brick(gate, V(2, 1.2, 2), cf * CFrame.new(x, 14, 0), P.Leaf3, "All")
	end
	Kit.Brick(gate, V(GATE_W + 6, 1.2, 2), cf * CFrame.new(0, 10.4, 0), P.Wood, "Top")
	local board = Kit.Brick(gate, V(GATE_W - 1, 2.8, 0.4), cf * CFrame.new(0, 8.4, -0.3), P.Teal, "Top")
	board.Name = "NameSign"
	local label = Kit.Label(board, Enum.NormalId.Front, "Free Plot", P.Discovery, true)
	local back = Kit.Label(board, Enum.NormalId.Back, "Free Plot", P.Discovery, true)
	back.Name = "BackText"
	-- Glowing trim + lanterns for the "glowing sign" look.
	local trim = Kit.Tile(gate, V(GATE_W - 1, 0.4, 0.6), cf * CFrame.new(0, 6.8, -0.3), P.Discovery)
	trim.Name = "Trim"
	Structures.Lantern(gate, cf * CFrame.new(-GATE_W / 2 - 3.5, 0, -1) * CFrame.Angles(0, math.rad(180), 0))
	Structures.Lantern(gate, cf * CFrame.new(GATE_W / 2 + 3.5, 0, -1))
	return label
end

local function border(m: Model, cf: CFrame)
	local b = Kit.Model(m, "Border")
	local h = 1.2
	-- Back and sides full length; front split around the gate. Studded wood bricks.
	Kit.Brick(b, V(SIZE + 2, h, 2), cf * CFrame.new(0, h / 2 - 0.2, HALF + 1), P.Wood, "Top", true)
	Kit.Brick(b, V(2, h, SIZE + 2), cf * CFrame.new(HALF + 1, h / 2 - 0.2, 0), P.Wood, "Top", true)
	Kit.Brick(b, V(2, h, SIZE + 2), cf * CFrame.new(-HALF - 1, h / 2 - 0.2, 0), P.Wood, "Top", true)
	local seg = (SIZE + 4 - GATE_W) / 2
	for _, side in { -1, 1 } do
		Kit.Brick(b, V(seg, h, 2), cf * CFrame.new(side * (GATE_W / 2 + seg / 2), h / 2 - 0.2, -HALF - 1), P.Wood, "Top", true)
	end
	-- Corner posts with leaf cubes.
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local pos = cf * CFrame.new(c[1] * (HALF + 1), 1.4, c[2] * (HALF + 1))
		Kit.Brick(b, V(3, 3.2, 3), pos, P.WoodDark, "All", true)
		Kit.Brick(b, V(2, 2, 2), pos * CFrame.new(0, 2.6, 0), P.Leaf2, "All")
	end
end

local function dressing(m: Model, cf: CFrame, rng: Random)
	local d = Kit.Model(m, "Dressing")
	-- Hedge bushes + flowers along the outside of the side and back borders.
	for _, side in { -1, 1 } do
		for z = -HALF + 10, HALF - 10, 16 do
			Nature.Bush(d, cf * CFrame.new(side * (HALF + 5), -0.5, z), 1.1, rng, rng:NextNumber() < 0.25)
		end
	end
	for x = -HALF + 10, HALF - 10, 16 do
		Nature.Bush(d, cf * CFrame.new(x, -0.5, HALF + 5), 1.1, rng, rng:NextNumber() < 0.25)
	end
	-- Flower strips flanking the front border.
	for _, side in { -1, 1 } do
		local a = (cf * CFrame.new(side * (GATE_W / 2 + 6), -0.5, -HALF - 3.5)).Position
		local b = (cf * CFrame.new(side * (HALF - 2), -0.5, -HALF - 3.5)).Position
		Scatter.FlowerLine(d, a, b, rng, 5)
	end
	-- One tree cluster behind each back corner.
	for _, side in { -1, 1 } do
		local p = (cf * CFrame.new(side * (HALF + 16), 0, HALF + 14)).Position
		Scatter.Cluster(d, p.X, p.Z, rng, "Mixed", 1)
	end
end

function Plots.Build(parent: Instance, rng: Random): { Model }
	local folder = Kit.Folder(parent, "Plots")
	for i = 1, Layout.PlotCount do
		local cf = Layout.PlotCFrame(i)
		local m = Kit.Model(folder, "Plot" .. i)
		local base = Kit.Brick(m, V(SIZE, 1, SIZE), cf * CFrame.new(0, -0.5, 0), P.PlotLocked, "None", true)
		base.Name = "Base"
		base.CastShadow = false
		base.CanQuery = true
		local land = Kit.Brick(m, V(64, LAND_H, 64), cf * CFrame.new(0, 0.02 - LAND_H / 2, 0), P.PlotLocked, "Top", true)
		land.Name = "Land"
		land.CastShadow = false
		border(m, cf)
		local label = sign(m, cf * CFrame.new(0, -0.5, -HALF - 1))
		label.Name = "Text"
		local spawnPad = Kit.Block(m, V(6, 1, 6), cf * CFrame.new(0, 0.5, -HALF + 10) * CFrame.Angles(0, math.rad(180), 0), P.Cream)
		spawnPad.Name = "Spawn"
		spawnPad.Transparency = 1
		spawnPad.CanQuery = false
		Kit.Tag(spawnPad, "PlotSpawn", { PlotIndex = i })
		dressing(m, cf, rng)
		Kit.Folder(m, "Items")
		Kit.Folder(m, "Creatures")
		base.PivotOffset = CFrame.new(0, 0.5, 0)
		m.PrimaryPart = base
		m:SetAttribute("PlotIndex", i)
		Kit.Tag(base, "Plot", { PlotIndex = i, OwnerId = 0, OwnerName = "", LandSize = 64 })
		plots[i] = m
		base:GetAttributeChangedSignal("OwnerId"):Connect(function()
			Plots.Refresh(i)
		end)
		base:GetAttributeChangedSignal("OwnerName"):Connect(function()
			Plots.Refresh(i)
		end)
		base:GetAttributeChangedSignal("LandSize"):Connect(function()
			Plots.Refresh(i)
		end)
		task.wait()
	end
	return plots
end

function Plots.Get(i: number): Model?
	return plots[i]
end

function Plots.All(): { Model }
	return plots
end

local function basePart(i: number): BasePart?
	local m = plots[i]
	return if m then m:FindFirstChild("Base") :: BasePart? else nil
end

-- Re-apply visuals from the Base attributes (owner sign, floor colour, unlocked square).
function Plots.Refresh(i: number)
	local m, base = plots[i], basePart(i)
	if not m or not base then
		return
	end
	local owner = (base:GetAttribute("OwnerId") :: number?) or 0
	local name = (base:GetAttribute("OwnerName") :: string?) or ""
	local studs = (base:GetAttribute("LandSize") :: number?) or 64
	local owned = owner ~= 0
	local text = if owned then name .. "'s Park" else "Free Plot"
	local gate = m:FindFirstChild("Gate")
	local board = gate and gate:FindFirstChild("NameSign")
	if board then
		for _, gui in board:GetChildren() do
			local l = gui:FindFirstChildOfClass("TextLabel")
			if l then
				l.Text = text
			end
		end
	end
	local land = m:FindFirstChild("Land") :: BasePart?
	if land then
		local s = math.clamp(if owned then studs else 64, 16, SIZE)
		land.Size = V(s, LAND_H, s)
		land.Color = if owned then P.PlotFloor else P.PlotLocked
		land.Material = Enum.Material.Plastic
	end
end

-- Direct setters (gameplay may instead just write the Base attributes).
function Plots.SetLand(i: number, studs: number)
	local base = basePart(i)
	if base then
		base:SetAttribute("LandSize", studs)
	end
end

function Plots.SetOwner(i: number, player: Player?)
	local base = basePart(i)
	if base then
		base:SetAttribute("OwnerId", if player then player.UserId else 0)
		base:SetAttribute("OwnerName", if player then player.DisplayName else "")
		if not player then
			base:SetAttribute("LandSize", 64)
		end
	end
end

return Plots
