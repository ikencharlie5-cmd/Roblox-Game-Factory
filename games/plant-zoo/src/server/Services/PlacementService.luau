--!strict
-- Grid placement on exhibit pads: PlaceItem / MoveItem / RemoveItem / BuyDecor.
-- 5x5 cells per pad, 1 item per cell, rot in {0,90,180,270}. Positions saved as pad+cell.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local PlacementService = {}

local CELLS = Config.Grid.CellsPerSide * Config.Grid.CellsPerSide
local VALID_ROT = { [0] = true, [90] = true, [180] = true, [270] = true }

local function cellTaken(data: any, pad: number, cell: number, exceptId: number?): boolean
	for _, p in data.placed do
		if p.pad == pad and p.cell == cell and p.id ~= exceptId then
			return true
		end
	end
	for _, d in data.decor do
		if d.pad == pad and d.cell == cell and d.id ~= exceptId then
			return true
		end
	end
	return false
end

-- Returns an error string or nil if (pad, cell, rot) is a valid free spot.
function PlacementService.CheckSpot(data: any, pad: any, cell: any, rot: any, exceptId: number?): string?
	if not Guard.IsInt(pad, 1, #Config.PadCosts) or pad > data.padsOwned then
		return "That pad is locked"
	end
	if not Guard.IsInt(cell, 1, CELLS) then
		return "Invalid cell"
	end
	if type(rot) ~= "number" or not VALID_ROT[rot] then
		return "Invalid rotation"
	end
	if cellTaken(data, pad, cell, exceptId) then
		return "That cell is taken"
	end
	return nil
end

local function findIndex(list: { any }, id: number): number?
	for i, v in list do
		if v.id == id then
			return i
		end
	end
	return nil
end

function PlacementService.PlaceDecor(player: Player, kind: string, pad: number, cell: number, rot: number): number
	local id = DataService.NewId(player)
	local item = { id = id, kind = kind, pad = pad, cell = cell, rot = rot }
	DataService.Update(player, function(d)
		table.insert(d.decor, item)
	end)
	ItemService.Upsert(player, item, "decor")
	ItemService.RefreshPad(player, pad)
	Guard.Sound(player, "Place")
	QuestService.Progress(player, "PlaceDecor", 1)
	return id
end

-- PlaceItem(kind: "seed"|"creature"|"decor", ref, pad, cell, rot) -> (ok, itemId)
--   seed: ref = species name; creature: ref = inventory creature id; decor: ref = decor kind
local function placeItem(player: Player, data: any, kind: any, ref: any, pad: any, cell: any, rot: any): (boolean, any)
	local err = PlacementService.CheckSpot(data, pad, cell, rot)
	if err then
		return Guard.Fail(player, err)
	end
	if kind == "seed" then
		if not Guard.IsString(ref) or not Config.Species.ByName[ref] or (data.inventory.seeds[ref] or 0) < 1 then
			return Guard.Fail(player, "You don't have that seed")
		end
		local id = DataService.NewId(player)
		local item = {
			id = id,
			species = ref,
			pad = pad,
			cell = cell,
			rot = rot,
			plantedAt = os.time(),
			growTotal = Formulas.GrowTime(ref, data.upgrades.Fertilizer or 0),
			color = "None",
			weather = "None",
		}
		DataService.Update(player, function(d)
			d.inventory.seeds[ref] -= 1
			if d.inventory.seeds[ref] <= 0 then
				d.inventory.seeds[ref] = nil
			end
			table.insert(d.placed, item)
		end)
		ItemService.Upsert(player, item, "plant")
		ItemService.RefreshPad(player, pad)
		Guard.Sound(player, "Plant")
		QuestService.Progress(player, "PlantSeed", 1)
		return true, id
	elseif kind == "creature" then
		local idx = if type(ref) == "number" then findIndex(data.inventory.creatures, ref) else nil
		if not idx then
			return Guard.Fail(player, "Creature not found")
		end
		local c = data.inventory.creatures[idx]
		local item = {
			id = c.id,
			species = c.species,
			pad = pad,
			cell = cell,
			rot = rot,
			plantedAt = 0,
			growTotal = 0,
			color = c.color or "None",
			weather = c.weather or "None",
		}
		DataService.Update(player, function(d)
			table.remove(d.inventory.creatures, idx)
			table.insert(d.placed, item)
		end)
		ItemService.Upsert(player, item, "plant")
		ItemService.RefreshPad(player, pad)
		Guard.Sound(player, "Place")
		return true, item.id
	elseif kind == "decor" then
		if not Guard.IsString(ref) or (data.inventory.decor[ref] or 0) < 1 then
			return Guard.Fail(player, "You don't have that decor")
		end
		DataService.Update(player, function(d)
			d.inventory.decor[ref] -= 1
			if d.inventory.decor[ref] <= 0 then
				d.inventory.decor[ref] = nil
			end
		end)
		return true, PlacementService.PlaceDecor(player, ref, pad, cell, rot)
	end
	return Guard.Fail(player, "Invalid item")
end

-- Takes item `id` off the grid (creature -> inventory, growing plant -> seed back, decor -> inventory).
function PlacementService.Unplace(player: Player, id: number): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local pi = findIndex(data.placed, id)
	local di = findIndex(data.decor, id)
	if not pi and not di then
		return false
	end
	local pad = if pi then data.placed[pi].pad else data.decor[di :: number].pad
	DataService.Update(player, function(d)
		if pi then
			local p = table.remove(d.placed, pi)
			if Formulas.Progress(p, os.time()) >= 1 then
				table.insert(
					d.inventory.creatures,
					{ id = p.id, species = p.species, color = p.color, weather = p.weather }
				)
			else
				d.inventory.seeds[p.species] = (d.inventory.seeds[p.species] or 0) + 1
			end
		else
			local dec = table.remove(d.decor, di :: number)
			d.inventory.decor[dec.kind] = (d.inventory.decor[dec.kind] or 0) + 1
		end
	end)
	ItemService.Remove(player, id)
	ItemService.RefreshPad(player, pad)
	return true
end

function PlacementService.Init()
	Guard.Bind("PlaceItem", placeItem)

	-- MoveItem(itemId, pad, cell, rot) -> (ok, itemId)
	Guard.Bind("MoveItem", function(player, data, id, pad, cell, rot)
		if type(id) ~= "number" then
			return Guard.Fail(player, "Invalid item")
		end
		local pi = findIndex(data.placed, id)
		local di = findIndex(data.decor, id)
		local item = if pi then data.placed[pi] elseif di then data.decor[di] else nil
		if not item then
			return Guard.Fail(player, "Item not found")
		end
		local err = PlacementService.CheckSpot(data, pad, cell, rot, id)
		if err then
			return Guard.Fail(player, err)
		end
		local oldPad = item.pad
		DataService.Update(player, function()
			item.pad, item.cell, item.rot = pad, cell, rot
		end)
		ItemService.Upsert(player, item, if pi then "plant" else "decor")
		ItemService.RefreshPad(player, oldPad)
		if oldPad ~= pad then
			ItemService.RefreshPad(player, pad)
		end
		Guard.Sound(player, "Place")
		return true, id
	end)

	-- RemoveItem(itemId) -> (ok)
	Guard.Bind("RemoveItem", function(player, _data, id)
		if type(id) ~= "number" or not PlacementService.Unplace(player, id) then
			return Guard.Fail(player, "Item not found")
		end
		return true, id
	end)

	-- BuyDecor(kind, pad?, cell?, rot?) -> (ok, itemId or "inventory")
	Guard.Bind("BuyDecor", function(player, data, kind, pad, cell, rot)
		local def = if Guard.IsString(kind) then (Config.Decor :: any)[kind] else nil
		if not def then
			return Guard.Fail(player, "Unknown decor")
		end
		if def.Biome and not data.biomes[def.Biome] then
			return Guard.Fail(player, "Unlock the " .. def.Biome .. " biome first")
		end
		local placeNow = pad ~= nil
		if placeNow then
			local err = PlacementService.CheckSpot(data, pad, cell, rot or 0)
			if err then
				return Guard.Fail(player, err)
			end
		end
		if not DataService.TrySpend(player, def.Cost) then
			return Guard.Fail(player, "Not enough cash")
		end
		if placeNow then
			return true, PlacementService.PlaceDecor(player, kind, pad, cell, rot or 0)
		end
		DataService.Update(player, function(d)
			d.inventory.decor[kind] = (d.inventory.decor[kind] or 0) + 1
		end)
		Guard.Sound(player, "Purchase")
		return true, "inventory"
	end)
end

return PlacementService
