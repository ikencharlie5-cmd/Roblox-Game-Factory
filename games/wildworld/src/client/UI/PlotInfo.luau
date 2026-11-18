--!strict
-- Where is my plot, and the 4-stud cell math for build previews (same math as the server:
-- Shared/Formulas + Shared/Items). Display only: the server re-checks every placement.
-- Plot = the Graphics "Plot" tagged part whose OwnerId is me (or workspace.Plots child).
-- Cells are 0-based over the full plot (0..31), min corner of the footprint; the buildable
-- range comes from Formulas.BuildRange(upgrades.Land). Floor (pads, paths) and object layers
-- have separate occupancy, so trees can stand on pads.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(script.Parent:WaitForChild("State"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config: any = require(Shared:WaitForChild("Config"))
local Items: any = require(Shared:WaitForChild("Items"))
local Formulas: any = require(Shared:WaitForChild("Formulas"))

local PlotInfo = {}

local player = Players.LocalPlayer :: Player
PlotInfo.Cell = Config.Grid.Cell

local function owned(inst: Instance): boolean
	local o = inst:GetAttribute("OwnerId") or inst:GetAttribute("Owner")
	return o == player.UserId or o == player.Name
end

function PlotInfo.Model(): Instance?
	for _, inst in CollectionService:GetTagged("Plot") do
		if owned(inst) then
			return inst
		end
	end
	local folder = workspace:FindFirstChild("Plots")
	if folder then
		for _, inst in folder:GetChildren() do
			if owned(inst) then
				return inst
			end
		end
	end
	return nil
end

-- Plot centre (Y = ground top), or nil while the plot isn't known yet.
function PlotInfo.Center(): Vector3?
	local m = PlotInfo.Model()
	if not m then
		return nil
	end
	if m:IsA("BasePart") then
		return m.Position + Vector3.new(0, m.Size.Y / 2, 0)
	elseif m:IsA("Model") then
		local cf, size = m:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2, 0)
	end
	return nil
end

-- Levelled plot CFrame at ground top (same as server PlotService.PlotCFrame).
function PlotInfo.CFrame(): CFrame?
	local m = PlotInfo.Model()
	local cf: CFrame
	if m and m:IsA("BasePart") then
		cf = m.CFrame * CFrame.new(0, m.Size.Y / 2, 0)
	elseif m and m:IsA("Model") then
		local mcf, size = m:GetBoundingBox()
		cf = mcf * CFrame.new(0, size.Y / 2, 0)
	else
		return nil
	end
	local look = cf.LookVector
	return CFrame.lookAt(cf.Position, cf.Position + Vector3.new(look.X, 0, look.Z))
end

local function landLevel(): number
	return tonumber(State.Tbl("upgrades").Land) or 0
end

-- (centre, buildable size in studs) for the grid overlay.
function PlotInfo.Bounds(): (Vector3?, number)
	return PlotInfo.Center(), Formulas.LandSize(landLevel())
end

-- World position -> 0-based plot cell.
function PlotInfo.ToCell(pos: Vector3): (number, number)
	local l = (PlotInfo.CFrame() or CFrame.new()):PointToObjectSpace(pos)
	local half = Formulas.PlotCells() / 2
	return math.floor(l.X / PlotInfo.Cell + half), math.floor(l.Z / PlotInfo.Cell + half)
end

function PlotInfo.CellCFrame(cx: number, cz: number, w: number, d: number, rotDeg: number): CFrame
	local x, z = Formulas.CellCentre(cx, cz, w, d)
	return (PlotInfo.CFrame() or CFrame.new()) * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rotDeg), 0)
end

function PlotInfo.InBounds(cx: number, cz: number, w: number, d: number): boolean
	local lo, hi = Formulas.BuildRange(landLevel())
	return cx >= lo and cz >= lo and cx + w - 1 <= hi and cz + d - 1 <= hi
end

local occFor: any = nil
local occCache: { [string]: { [string]: number } } = {}

-- layer -> "x,z" -> item uid, from data.plot.items {id, x, z, r, u}.
function PlotInfo.Occupied(): { [string]: { [string]: number } }
	if occFor == State.data then
		return occCache
	end
	local used: { [string]: { [string]: number } } = { floor = {}, object = {} }
	for _, it in State.Tbl("plot").items or {} do
		local def = if type(it) == "table" then Items.Get(it.id) else nil
		if def then
			local w, d = Items.Footprint(def, tonumber(it.r) or 0)
			local layer = used[def.Layer] or used.object
			for dx = 0, w - 1 do
				for dz = 0, d - 1 do
					layer[((tonumber(it.x) or 0) + dx) .. "," .. ((tonumber(it.z) or 0) + dz)] = it.u
				end
			end
		end
	end
	occFor, occCache = State.data, used
	return used
end

-- Item uid at a cell (objects first, then floor) for Remove.
function PlotInfo.ItemAt(cx: number, cz: number): number?
	local occ = PlotInfo.Occupied()
	local key = cx .. "," .. cz
	return occ.object[key] or occ.floor[key]
end

function PlotInfo.Items(): { { [string]: any } }
	return Items.List()
end

function PlotInfo.Item(id: string): { [string]: any }
	return Items.Get(id) or { Id = id, Name = id, Kind = "decor", W = 1, D = 1, Cost = 0, Level = 0, Layer = "object" }
end

function PlotInfo.Footprint(def: { [string]: any }, rot: number): (number, number)
	return Items.Footprint(def, rot)
end

-- Tray categories from item Kind.
local CATEGORY: { [string]: string } = {
	pad = "Habitats",
	path = "Paths",
	fence = "Fences",
	tree = "Plants",
	bush = "Plants",
	flower = "Plants",
	rock = "Rocks",
	log = "Rocks",
	burrow = "Rocks",
	sand = "Rocks",
	sunspot = "Rocks",
	water = "Water",
	food = "Food",
	drink = "Food",
	shelter = "Shelter",
	toy = "Decor",
	light = "Decor",
	stand = "Decor",
	decor = "Decor",
}
local ORDER = { "Habitats", "Plants", "Rocks", "Water", "Food", "Shelter", "Paths", "Fences", "Decor" }

function PlotInfo.Category(def: { [string]: any }): string
	return CATEGORY[tostring(def.Kind)] or "Decor"
end

function PlotInfo.Categories(): { string }
	local seen: { [string]: boolean } = {}
	for _, def in Items.List() do
		seen[PlotInfo.Category(def)] = true
	end
	local out = {}
	for _, c in ORDER do
		if seen[c] then
			table.insert(out, c)
		end
	end
	return out
end

return PlotInfo
