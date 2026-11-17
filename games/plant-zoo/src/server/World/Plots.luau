--!strict
-- Builds the 6 player plots (80x80) on a ring around the hub. Each plot = 3x3 ExhibitPads.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Biomes = require(script.Parent.Biomes)

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex
local M = Enum.Material

local Plots = {}

Plots.Count = 6
Plots.Radius = 170
Plots.Size = 80
Plots.FloorTop = 0.5
Plots.PadHeight = 0.8

export type Pad = {
	index: number,
	model: Model,
	base: Part,
	dressing: Folder,
	lock: Folder,
	items: Folder,
	jar: Part,
	jarVisual: Model,
	jarFill: Part,
	jarLabel: TextLabel,
}
export type Plot = {
	index: number,
	model: Model,
	cf: CFrame, -- ground-top center, LookVector -> hub
	pads: { Pad },
	spawn: Part,
	visitors: Folder,
}

-- Plot i at angle (i-1)*60 deg, matching gameplay's fallback.
function Plots.CFrameFor(i: number): CFrame
	local a = math.rad((i - 1) * 60)
	local pos = V(math.cos(a) * Plots.Radius, Plots.FloorTop, math.sin(a) * Plots.Radius)
	return CFrame.lookAt(pos, V(0, Plots.FloorTop, 0))
end

-- Pad local offset (row 1 = entrance side, which is local -Z / toward the hub).
function Plots.PadOffset(padIndex: number): CFrame
	local row = (padIndex - 1) // 3 + 1
	local col = (padIndex - 1) % 3 + 1
	return C((col - 2) * Theme.Grid.PadSpacing, 0, (row - 2) * Theme.Grid.PadSpacing)
end

local function buildJar(pad: Pad, plotIndex: number, cf: CFrame)
	local m = Build.Model(pad.model, "TipJarVisual")
	Build.Cyl(m, 0.4, 2.4, cf * C(0, 0.2, 0), Theme.Colors.WoodDark, M.Wood, false)
	local glass = Build.Cyl(m, 2.2, 1.8, cf * C(0, 1.5, 0), hex("#CFF3FF"), M.Glass, false)
	glass.Transparency = 0.55
	local fill = Build.Cyl(m, 0.2, 1.5, cf * C(0, 0.5, 0), Theme.Colors.Gold, M.Metal, false)
	fill.Name = "Fill"
	Build.Cyl(m, 0.3, 1.9, cf * C(0, 2.75, 0), Theme.Colors.Wood, M.Wood, false)
	Build.Ball(m, 0.6, cf * C(0, 3.1, 0), Theme.Colors.Gold, M.Neon)
	local trigger = Build.Part(pad.model, {
		Size = V(4, 3, 4),
		CFrame = cf * C(0, 1.5, 0),
		Transparency = 1,
		CanCollide = false,
		Name = "TipJar",
	})
	trigger.CanTouch = true
	trigger.CanQuery = false
	Build.Tag(trigger, "TipJar", { PlotIndex = plotIndex, PadIndex = pad.index, Amount = 0, Active = false })
	local label = Build.Billboard(trigger, "$0", Theme.Colors.Gold, 3.2, 5)
	local bb = label.Parent :: BillboardGui
	bb.Enabled = false
	pad.jar = trigger
	pad.jarVisual = m
	pad.jarFill = fill
	pad.jarLabel = label
end

local function buildPad(plot: Plot, padIndex: number): Pad
	local model = Build.Model(plot.model, "Pad" .. padIndex)
	local cf = plot.cf * Plots.PadOffset(padIndex)
	local base = Build.Part(model, {
		Size = V(Theme.Grid.PadSize, Plots.PadHeight, Theme.Grid.PadSize),
		CFrame = cf * C(0, Plots.PadHeight / 2, 0),
		Color = Theme.Colors.Grass,
		Material = M.Grass,
		Name = "Base",
	})
	Build.Tag(base, "ExhibitPad", {
		PlotIndex = plot.index,
		PadIndex = padIndex,
		Unlocked = false,
		Biome = "Meadow",
		CellSize = Theme.Grid.CellSize,
		GridCells = Theme.Grid.Cells,
	})
	local pad: Pad = {
		index = padIndex,
		model = model,
		base = base,
		dressing = Build.Folder(model, "Dressing"),
		lock = Build.Folder(model, "Lock"),
		items = Build.Folder(model, "Items"),
	} :: any
	buildJar(pad, plot.index, cf * C(0, 0, -12))
	return pad
end

local function paths(f: Instance, cf: CFrame)
	local h = Plots.Size / 2
	local y = 0.05
	local function strip(x: number, z: number, sx: number, sz: number)
		Build.Part(
			f,
			{
				Size = V(sx, 0.2, sz),
				CFrame = cf * C(x, y, z),
				Color = Theme.Colors.Path,
				Material = M.Sand,
				Name = "Path",
			}
		)
	end
	for _, k in { -12, 12 } do
		strip(k, 0, 4, 68)
		strip(0, k, 68, 4)
	end
	strip(0, -(h - 3), 80, 6)
	strip(0, h - 3, 80, 6)
	strip(-(h - 3), 0, 6, 68)
	strip(h - 3, 0, 6, 68)
end

local function border(f: Instance, cf: CFrame)
	local h = Plots.Size / 2
	local hedge = Theme.Colors.Hedge
	local function wall(x: number, z: number, sx: number, sz: number)
		Build.Part(
			f,
			{ Size = V(sx, 2, sz), CFrame = cf * C(x, 0.5, z), Color = hedge, Material = M.Grass, Name = "Hedge" }
		)
	end
	wall(0, h + 0.75, 81.5, 1.5)
	wall(-(h + 0.75), 0, 1.5, 81.5)
	wall(h + 0.75, 0, 1.5, 81.5)
	wall(-(h + 0.75) / 2 - 4.6, -(h + 0.75), h - 8, 1.5)
	wall((h + 0.75) / 2 + 4.6, -(h + 0.75), h - 8, 1.5)
	for _, x in { -h, h } do
		for _, z in { -h, h } do
			Build.Tree(f, (cf * C(x * 1.12, -0.5, z * 1.12)).Position, 1.2, hex("#5FB23A"))
		end
	end
end

local function sign(plot: Plot)
	local f = Build.Model(plot.model, "Sign")
	local cf = plot.cf * C(0, 0, -(Plots.Size / 2 + 1))
	for _, x in { -6, 6 } do
		Build.Cyl(f, 9, 1, cf * C(x, 4, 0), Theme.Colors.Wood, M.Wood, true)
		Build.Ball(f, 1.6, cf * C(x, 9, 0), Theme.Colors.Leaf, M.Grass)
	end
	local board = Build.Part(
		f,
		{ Size = V(13, 3.2, 0.6), CFrame = cf * C(0, 7.4, 0), Color = Theme.Colors.Cream, Name = "Board" }
	)
	board.CanCollide = false
	Build.Tag(board, "PlotSign", { PlotIndex = plot.index })
	local front = Build.Label(board, Enum.NormalId.Front, "Free Plot", Theme.Colors.Text)
	local back = Build.Label(board, Enum.NormalId.Back, "Free Plot", Theme.Colors.Text)
	Build.Deco(f, { Size = V(13.6, 0.5, 1), CFrame = cf * C(0, 9.2, 0), Color = Theme.Colors.Leaf, Material = M.Grass })
	for i = 0, 4 do
		Build.Ball(f, 0.7, cf * C(-5 + i * 2.5, 9.6, -0.2), if i % 2 == 0 then hex("#FFD54F") else hex("#FF8FB8"))
	end
	local function refresh()
		local name = plot.model:GetAttribute("OwnerName")
		local likes = plot.model:GetAttribute("Likes") or 0
		local text = if typeof(name) == "string" and name ~= ""
			then string.format("%s's Zoo  ❤ %d", name, likes)
			else "Free Plot"
		front.Text = text
		back.Text = text
	end
	plot.model:GetAttributeChangedSignal("OwnerName"):Connect(refresh)
	plot.model:GetAttributeChangedSignal("Likes"):Connect(refresh)
end

function Plots.Build(parent: Instance, onPad: (Plot, Pad) -> ()): { Plot }
	local out: { Plot } = {}
	for i = 1, Plots.Count do
		local cf = Plots.CFrameFor(i)
		local model = Build.Model(parent, "Plot" .. i)
		local floor = Build.Part(model, {
			Size = V(Plots.Size, 1, Plots.Size),
			CFrame = cf * C(0, -0.5, 0),
			Color = Theme.Colors.GrassDark,
			Material = M.Grass,
			Name = "Floor",
		})
		floor.PivotOffset = C(0, 0.5, 0)
		model.PrimaryPart = floor
		Build.Tag(model, "Plot", { PlotIndex = i, OwnerUserId = 0, OwnerName = "", Likes = 0 })
		local spawn = Build.Part(model, {
			Size = V(4, 1, 4),
			CFrame = cf * C(0, 0.5, -(Plots.Size / 2 - 3)) * CFrame.Angles(0, math.pi, 0),
			Transparency = 1,
			CanCollide = false,
			Name = "PlotSpawn",
		})
		spawn.CanTouch = false
		spawn.CanQuery = false
		Build.Tag(spawn, "PlotSpawn", { PlotIndex = i })
		local plot: Plot =
			{ index = i, model = model, cf = cf, pads = {}, spawn = spawn, visitors = Build.Folder(model, "Visitors") }
		paths(Build.Folder(model, "Paths"), cf)
		border(Build.Folder(model, "Border"), cf)
		sign(plot)
		for p = 1, 9 do
			local pad = buildPad(plot, p)
			plot.pads[p] = pad
			onPad(plot, pad)
		end
		table.insert(out, plot)
		task.wait()
	end
	return out
end

-- Pad top-center CFrame (planting surface).
function Plots.PadTop(pad: Pad): CFrame
	return Biomes.TopCFrame(pad.base)
end

return Plots
