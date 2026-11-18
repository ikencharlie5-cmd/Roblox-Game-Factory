--!strict
-- Builds the 6 player plots (80x80) on a ring around the hub. Each plot = 3x3 ExhibitPads.
-- Border, arch gate + owner sign and floor colour live in PlotDressing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Biomes = require(script.Parent.Biomes)
local PlotDressing = require(script.Parent.PlotDressing)

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
		Build.Part(f, {
			Size = V(sx, 0.2, sz),
			CFrame = cf * C(x, y, z),
			Color = Theme.Colors.Path,
			Material = M.SmoothPlastic,
			Name = "Path",
		})
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

function Plots.Build(parent: Instance, onPad: (Plot, Pad) -> ()): { Plot }
	local out: { Plot } = {}
	for i = 1, Plots.Count do
		local cf = Plots.CFrameFor(i)
		local model = Build.Model(parent, "Plot" .. i)
		local floor = Build.Part(model, {
			Size = V(Plots.Size, 1, Plots.Size),
			CFrame = cf * C(0, -0.5, 0),
			Color = Theme.Colors.PlotFloorFree,
			Material = M.SmoothPlastic,
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
		PlotDressing.BindFloor(model, floor)
		PlotDressing.Border(Build.Folder(model, "Border"), cf, Random.new(1000 + i))
		PlotDressing.Gate(model, i, cf)
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
