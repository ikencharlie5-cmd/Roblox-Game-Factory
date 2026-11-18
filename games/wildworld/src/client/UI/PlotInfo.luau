--!strict
-- Where is my plot, and the 4-stud cell math for build previews. Display only: the server
-- re-checks every placement. Plot lookup order:
--   1) player attributes PlotCenter (Vector3) + PlotSize (number, buildable studs)
--   2) a workspace instance tagged "Plot" (or under workspace.Plots) with attribute
--      OwnerId/Owner == my UserId; its pivot = centre, attribute BuildSize or part size = size.
-- Also the build catalog (Config.Items / BuildItems / Placeables, fallback = SPEC props).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))

local PlotInfo = {}

local player = Players.LocalPlayer :: Player
PlotInfo.Cell = tonumber(Derived.Field(Derived.Config, "CellSize", "GridSize")) or 4

local function owned(inst: Instance): boolean
	local o = inst:GetAttribute("OwnerId") or inst:GetAttribute("Owner") or inst:GetAttribute("UserId")
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

-- Buildable area from the Park Land upgrade (64 -> 128 studs).
local function landSize(): number
	local sizes = { 64, 80, 96, 112, 128 }
	local up = State.Tbl("upgrades")
	local lvl = tonumber(up.ParkLand or up.Land or up.parkLand) or 0
	return sizes[math.clamp(lvl + 1, 1, #sizes)]
end

-- Returns centre (Y = ground top) and buildable size, or nil if the plot isn't known yet.
function PlotInfo.Bounds(): (Vector3?, number)
	local c = player:GetAttribute("PlotCenter")
	local s = player:GetAttribute("PlotSize")
	if typeof(c) == "Vector3" then
		return c, if type(s) == "number" then s else landSize()
	end
	local m = PlotInfo.Model()
	if not m then
		return nil, landSize()
	end
	local cf: CFrame
	local size: Vector3
	if m:IsA("BasePart") then
		cf, size = m.CFrame, m.Size
		cf = cf * CFrame.new(0, size.Y / 2, 0)
	elseif m:IsA("Model") then
		cf = m:GetPivot()
		size = m:GetExtentsSize()
	else
		return nil, landSize()
	end
	local bs = m:GetAttribute("BuildSize")
	return cf.Position, if type(bs) == "number" then bs else math.min(size.X, landSize())
end

-- World position -> 0-based cell (x, z) relative to the plot's min corner.
function PlotInfo.ToCell(pos: Vector3): (number, number)
	local center, size = PlotInfo.Bounds()
	local c = center or Vector3.zero
	local minX, minZ = c.X - size / 2, c.Z - size / 2
	return math.floor((pos.X - minX) / PlotInfo.Cell), math.floor((pos.Z - minZ) / PlotInfo.Cell)
end

-- Cell (+ footprint w x d cells) -> world CFrame at ground level, centred on the footprint.
function PlotInfo.CellCFrame(cx: number, cz: number, w: number, d: number, rotDeg: number): CFrame
	local center, size = PlotInfo.Bounds()
	local c = center or Vector3.zero
	local minX, minZ = c.X - size / 2, c.Z - size / 2
	local x = minX + (cx + w / 2) * PlotInfo.Cell
	local z = minZ + (cz + d / 2) * PlotInfo.Cell
	return CFrame.new(x, c.Y, z) * CFrame.Angles(0, math.rad(rotDeg), 0)
end

function PlotInfo.InBounds(cx: number, cz: number, w: number, d: number): boolean
	local _, size = PlotInfo.Bounds()
	local n = math.floor(size / PlotInfo.Cell)
	return cx >= 0 and cz >= 0 and cx + w <= n and cz + d <= n
end

-- Cells used by placed items (from data.plot.items {id,x,z,r}). Display only.
local occFor: any = nil
local occCache: { [string]: boolean } = {}

function PlotInfo.Occupied(): { [string]: boolean }
	if occFor == State.data then
		return occCache
	end
	local used: { [string]: boolean } = {}
	local items = State.Tbl("plot").items or {}
	for _, it in items do
		if type(it) == "table" then
			local def = PlotInfo.Item(tostring(it.id))
			local w, d = PlotInfo.Footprint(def, tonumber(it.r) or 0)
			for dx = 0, w - 1 do
				for dz = 0, d - 1 do
					used[((tonumber(it.x) or 0) + dx) .. "," .. ((tonumber(it.z) or 0) + dz)] = true
				end
			end
		end
	end
	occFor, occCache = State.data, used
	return used
end

local FALLBACK_ITEMS = {
	{ id = "PadSmall", name = "Small Habitat", category = "Habitats", price = 100, cells = { 6, 6 } },
	{ id = "PadMedium", name = "Medium Habitat", category = "Habitats", price = 600, cells = { 9, 9 } },
	{ id = "PadLarge", name = "Large Habitat", category = "Habitats", price = 2500, cells = { 12, 12 } },
	{ id = "Tree", name = "Tree", category = "Plants", price = 25, tags = { "tree" } },
	{ id = "Bush", name = "Bush", category = "Plants", price = 15, tags = { "bush" } },
	{ id = "Flowers", name = "Flowers", category = "Plants", price = 10, tags = { "flower" } },
	{ id = "Rock", name = "Rock", category = "Rocks", price = 20, tags = { "rock" } },
	{ id = "Log", name = "Log", category = "Rocks", price = 20, tags = { "log" } },
	{ id = "Pond", name = "Pond", category = "Water", price = 80, cells = { 2, 2 }, tags = { "water" } },
	{ id = "FoodBowl", name = "Food Bowl", category = "Food", price = 30, tags = { "food" } },
	{ id = "WaterTrough", name = "Water Trough", category = "Food", price = 30, tags = { "water" } },
	{ id = "Shelter", name = "Shelter Hut", category = "Shelter", price = 120, cells = { 2, 2 } },
	{ id = "Burrow", name = "Burrow", category = "Shelter", price = 60, tags = { "burrow" } },
	{ id = "Path", name = "Path", category = "Paths", price = 5 },
	{ id = "Fence", name = "Fence", category = "Fences", price = 8 },
	{ id = "Lantern", name = "Lantern", category = "Decor", price = 40 },
	{ id = "Bench", name = "Bench", category = "Decor", price = 35 },
	{ id = "SnackStand", name = "Snack Stand", category = "Decor", price = 750, cells = { 2, 2 } },
}

local itemsCache: { { [string]: any } }? = nil

function PlotInfo.Items(): { { [string]: any } }
	if itemsCache then
		return itemsCache
	end
	local list = Derived.List(Derived.Cfg("Items", "BuildItems", "Placeables", "Props"))
	if #list == 0 then
		list = FALLBACK_ITEMS
	end
	for _, e in list do
		e.id = Derived.Field(e, "id", "Id") or e.name
		e.price = Derived.Field(e, "price", "Price", "cost", "Cost") or 0
	end
	itemsCache = list
	return list
end

function PlotInfo.Item(id: string): { [string]: any }
	for _, e in PlotInfo.Items() do
		if e.id == id or e.name == id then
			return e
		end
	end
	return { id = id, name = id, category = "Decor", price = 0 }
end

function PlotInfo.Footprint(def: { [string]: any }, rot: number): (number, number)
	local cells = Derived.Field(def, "cells", "Cells", "footprint", "Footprint")
	local w, d = 1, 1
	if type(cells) == "table" then
		w, d = tonumber(cells[1] or cells.x or cells.X) or 1, tonumber(cells[2] or cells.z or cells.Z) or 1
	elseif type(cells) == "number" then
		w, d = cells, cells
	end
	if math.floor(rot / 90 + 0.5) % 2 == 1 then
		w, d = d, w
	end
	return w, d
end

function PlotInfo.Categories(): { string }
	local seen: { [string]: boolean } = {}
	local out = {}
	for _, e in PlotInfo.Items() do
		local c = tostring(Derived.Field(e, "category", "Category") or "Decor")
		if not seen[c] then
			seen[c] = true
			table.insert(out, c)
		end
	end
	return out
end

return PlotInfo
