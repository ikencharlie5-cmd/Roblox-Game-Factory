--!strict
-- Helper (not a service): server occupancy grid for one plot. Two layers:
-- "floor" (pads, paths) and "object" (everything else). Objects must be fully inside one pad
-- or fully outside all pads. No physics queries; pure tables.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items"))
local Formulas = require(Shared:WaitForChild("Formulas"))

local PlotGrid = {}
PlotGrid.__index = PlotGrid

export type Rect = { x0: number, z0: number, x1: number, z1: number }
export type Grid = typeof(setmetatable(
	{} :: { floor: { [number]: number }, object: { [number]: number }, rects: { [number]: Rect }, items: { [number]: any } },
	PlotGrid
))

local function k(x: number, z: number): number
	return x * 256 + z
end

function PlotGrid.new(): Grid
	return setmetatable({ floor = {}, object = {}, rects = {}, items = {} }, PlotGrid)
end

function PlotGrid.RectFor(def: any, x: number, z: number, rot: number): Rect
	local w, d = Items.Footprint(def, rot)
	return { x0 = x, z0 = z, x1 = x + w - 1, z1 = z + d - 1 }
end

local function inside(a: Rect, b: Rect): boolean
	return a.x0 >= b.x0 and a.x1 <= b.x1 and a.z0 >= b.z0 and a.z1 <= b.z1
end

local function overlaps(a: Rect, b: Rect): boolean
	return a.x0 <= b.x1 and b.x0 <= a.x1 and a.z0 <= b.z1 and b.z0 <= a.z1
end

-- Returns nil if ok, else a player-facing reason. ignoreU = item being moved/rotated.
function PlotGrid.Check(self: Grid, def: any, rect: Rect, landLevel: number, ignoreU: number?): string?
	local lo, hi = Formulas.BuildRange(landLevel)
	if rect.x0 < lo or rect.z0 < lo or rect.x1 > hi or rect.z1 > hi then
		return "Outside your park land (upgrade Park Land for more room)"
	end
	local layer = if def.Layer == "floor" then self.floor else self.object
	for x = rect.x0, rect.x1 do
		for z = rect.z0, rect.z1 do
			local u = layer[k(x, z)]
			if u and u ~= ignoreU then
				return "That spot is taken"
			end
		end
	end
	if def.Kind == "pad" then
		-- objects overlapping the new pad must be fully inside it
		for u, r in self.rects do
			local it = self.items[u]
			local idef = it and Items.Get(it.id)
			if u ~= ignoreU and idef and idef.Layer == "object" and overlaps(r, rect) and not inside(r, rect) then
				return "An item is sticking over the pad edge"
			end
		end
	elseif def.Layer == "object" then
		local pad = self:PadAt(rect.x0, rect.z0)
		for x = rect.x0, rect.x1 do
			for z = rect.z0, rect.z1 do
				if self:PadAt(x, z) ~= pad then
					return "Place it fully inside or fully outside a habitat"
				end
			end
		end
	end
	return nil
end

-- Pad uid covering a cell (nil if none).
function PlotGrid.PadAt(self: Grid, x: number, z: number): number?
	local u = self.floor[k(x, z)]
	if u then
		local it = self.items[u]
		if it and it.id and string.sub(it.id, 1, 3) == "Pad" then
			return u
		end
	end
	return nil
end

function PlotGrid.Add(self: Grid, item: any)
	local def = Items.Get(item.id)
	if not def then
		return
	end
	local rect = PlotGrid.RectFor(def, item.x, item.z, item.r)
	local layer = if def.Layer == "floor" then self.floor else self.object
	for x = rect.x0, rect.x1 do
		for z = rect.z0, rect.z1 do
			layer[k(x, z)] = item.u
		end
	end
	self.rects[item.u] = rect
	self.items[item.u] = item
end

function PlotGrid.Remove(self: Grid, u: number)
	local rect = self.rects[u]
	if not rect then
		return
	end
	for x = rect.x0, rect.x1 do
		for z = rect.z0, rect.z1 do
			local key = k(x, z)
			if self.floor[key] == u then
				self.floor[key] = nil
			end
			if self.object[key] == u then
				self.object[key] = nil
			end
		end
	end
	self.rects[u] = nil
	self.items[u] = nil
end

-- Item records whose footprint is fully inside pad u.
function PlotGrid.ItemsInPad(self: Grid, padU: number): { any }
	local out = {}
	local pr = self.rects[padU]
	if not pr then
		return out
	end
	for u, r in self.rects do
		local it = self.items[u]
		if u ~= padU and it and inside(r, pr) then
			local def = Items.Get(it.id)
			if def and def.Layer == "object" then
				table.insert(out, it)
			end
		end
	end
	return out
end

function PlotGrid.Count(self: Grid): number
	local n = 0
	for _ in self.items do
		n += 1
	end
	return n
end

function PlotGrid.CountId(self: Grid, id: string): number
	local n = 0
	for _, it in self.items do
		if it.id == id then
			n += 1
		end
	end
	return n
end

return PlotGrid
