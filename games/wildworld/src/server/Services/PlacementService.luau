--!strict
-- Park building: PlaceItem / RotateItem / MoveItem / RemoveItem. Client sends intents only
-- ({itemId, cellX, cellZ, rot}); server checks owner, unlock, cost, bounds, occupancy, 300 cap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local PlotGrid = require(script.Parent:WaitForChild("PlotGrid"))
local Models = require(script.Parent:WaitForChild("Models"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local PlacementService = {}

local grids: { [Player]: any } = {}
local models: { [Player]: { [number]: Model } } = {}

local function itemCFrame(plot: number, item: any, def: any): CFrame
	local w, d = Items.Footprint(def, item.r)
	local lx, lz = Formulas.CellCentre(item.x, item.z, w, d)
	return PlotService.ToWorld(plot, lx, lz, 0, item.r)
end

local function spawnModel(player: Player, plot: number, item: any)
	local def = Items.Get(item.id)
	if not def then
		return
	end
	local m = Models.Item(def, item.u)
	m.Name = def.Id .. "_" .. item.u
	m:PivotTo(itemCFrame(plot, item, def))
	m:SetAttribute("ItemUid", item.u)
	m:SetAttribute("ItemId", def.Id)
	m:SetAttribute("Kind", def.Kind)
	m:SetAttribute("OwnerId", player.UserId)
	m:SetAttribute("PlotIndex", plot)
	if def.Kind == "pad" then
		m:SetAttribute("PadSize", def.PadSize)
		m:SetAttribute("Capacity", def.PadCapacity)
		CollectionService:AddTag(m, "HabitatPad")
	end
	CollectionService:AddTag(m, "ParkItem")
	m.Parent = PlotService.Folder(plot)
	models[player][item.u] = m
end

local function despawn(player: Player, u: number)
	local m = models[player] and models[player][u]
	if m then
		m:Destroy()
		models[player][u] = nil
	end
end

local function findItem(data: any, u: any): (any, number?)
	if type(u) ~= "number" then
		return nil, nil
	end
	for i, it in data.plot.items do
		if it.u == u then
			return it, i
		end
	end
	return nil, nil
end

local function validRot(def: any, rot: any): boolean
	if not Guard.IsInt(rot, 0, 345) then
		return false
	end
	return rot % (if def.Fine then 15 else 90) == 0
end

-- Unlock + cost check. Returns (reason?, payKind, amount)
local function priceCheck(player: Player, data: any, def: any): (string?, string, number)
	if data.level < def.Level then
		return "Unlocks at Park Level " .. def.Level, "", 0
	end
	if def.Pass then
		if not MonetizationService.HasPass(player, def.Pass) then
			return "Needs the " .. ((Config.GamePasses :: any)[def.Pass].Name) .. " pass", "", 0
		end
		return nil, "free", 0
	end
	if def.Starter then
		return if data.flags.starterPack then nil else "Part of the Starter Pack", "free", 0
	end
	if def.ShopRare then
		return if (data.decorInv[def.Id] or 0) > 0 then nil else "Buy this in the shop first", "inv", 1
	end
	if def.RP then
		return if data.rp >= def.RP then nil else "Needs " .. def.RP .. " RP", "rp", def.RP
	end
	return if data.coins >= def.Cost then nil else "Not enough coins", "coins", def.Cost
end

local function place(player: Player, data: any, itemId: any, x: any, z: any, rot: any)
	local plot = PlotService.GetPlot(player)
	local grid = grids[player]
	local def = Items.Get(itemId)
	if not plot or not grid then
		return Guard.Fail(player, "Your park isn't ready yet")
	end
	if not def or not Guard.IsInt(x, 0, 255) or not Guard.IsInt(z, 0, 255) or not validRot(def, rot) then
		return false, "Bad request"
	end
	if grid:Count() >= Config.Grid.MaxObjects then
		return Guard.Fail(player, "Your park is full (" .. Config.Grid.MaxObjects .. " objects)")
	end
	if def.Max and grid:CountId(def.Id) >= def.Max then
		return Guard.Fail(player, "Max " .. def.Max .. " " .. def.Name .. "s")
	end
	local rect = PlotGrid.RectFor(def, x, z, rot)
	local bad = grid:Check(def, rect, data.upgrades.Land, nil)
	if bad then
		return Guard.Fail(player, bad)
	end
	local reason, payKind, amount = priceCheck(player, data, def)
	if reason then
		return Guard.Fail(player, reason)
	end
	if payKind == "coins" and not DataService.TrySpend(player, amount) then
		return Guard.Fail(player, "Not enough coins")
	elseif payKind == "rp" and not DataService.TrySpendRP(player, amount) then
		return Guard.Fail(player, "Not enough RP")
	end
	local item = { id = def.Id, x = x, z = z, r = rot, u = DataService.NewId(player) }
	DataService.Update(player, function(d)
		if payKind == "inv" then
			d.decorInv[def.Id] = (d.decorInv[def.Id] or 0) - 1
			if d.decorInv[def.Id] <= 0 then
				d.decorInv[def.Id] = nil
			end
		end
		table.insert(d.plot.items, item)
	end)
	grid:Add(item)
	spawnModel(player, plot, item)
	Guard.Sound(player, "Place", { kind = def.Kind, position = itemCFrame(plot, item, def).Position })
	Signals.Fire("Place", player, def.Id, def.Kind)
	Signals.Fire("PlotChanged", player)
	return true, item.u
end

local function move(player: Player, data: any, u: any, x: any, z: any, rot: any)
	local plot = PlotService.GetPlot(player)
	local grid = grids[player]
	local item = findItem(data, u)
	local def = item and Items.Get(item.id)
	if not plot or not grid or not item or not def then
		return false, "Bad request"
	end
	if not Guard.IsInt(x, 0, 255) or not Guard.IsInt(z, 0, 255) or not validRot(def, rot) then
		return false, "Bad request"
	end
	if def.Kind == "pad" and (x ~= item.x or z ~= item.z) and #grid:ItemsInPad(u) > 0 then
		return Guard.Fail(player, "Empty the habitat before moving it")
	end
	local rect = PlotGrid.RectFor(def, x, z, rot)
	local bad = grid:Check(def, rect, data.upgrades.Land, u)
	if bad then
		return Guard.Fail(player, bad)
	end
	grid:Remove(u)
	DataService.Update(player, function()
		item.x, item.z, item.r = x, z, rot
	end)
	grid:Add(item)
	local m = models[player][u]
	if m then
		m:PivotTo(itemCFrame(plot, item, def))
	end
	Guard.Sound(player, "Rotate")
	Signals.Fire("PlotChanged", player)
	return true, u
end

local function remove(player: Player, data: any, u: any)
	local grid = grids[player]
	local item, index = findItem(data, u)
	local def = item and Items.Get(item.id)
	if not grid or not item or not index or not def then
		return false, "Bad request"
	end
	if def.Kind == "pad" and #grid:ItemsInPad(u) > 0 then
		return Guard.Fail(player, "Remove the items inside the habitat first")
	end
	DataService.Update(player, function(d)
		table.remove(d.plot.items, index)
		if def.ShopRare then
			d.decorInv[def.Id] = (d.decorInv[def.Id] or 0) + 1
		elseif def.RP then
			d.rp += math.floor(def.RP / 2)
		elseif not def.Pass and not def.Starter then
			d.coins += math.floor(def.Cost / 2)
		end
	end)
	grid:Remove(u)
	despawn(player, u)
	Guard.Sound(player, "Remove")
	if def.Kind == "pad" then
		Signals.Fire("PadRemoved", player, u)
	end
	Signals.Fire("PlotChanged", player)
	return true, u
end

-- Queries for other services ---------------------------------------------------------------

function PlacementService.Grid(player: Player): any
	return grids[player]
end

function PlacementService.Model(player: Player, u: number): Model?
	return models[player] and models[player][u]
end

-- Pads: { {u, def, item, model, cf (centre, ground), half (studs)} }
function PlacementService.GetPads(player: Player): { any }
	local out = {}
	local grid, plot = grids[player], PlotService.GetPlot(player)
	if not grid or not plot then
		return out
	end
	for u, it in grid.items do
		local def = Items.Get(it.id)
		if def and def.Kind == "pad" then
			table.insert(out, {
				u = u,
				def = def,
				item = it,
				model = models[player][u],
				cf = itemCFrame(plot, it, def),
				half = (def.PadSize or 24) / 2,
			})
		end
	end
	table.sort(out, function(a, b)
		return a.u < b.u
	end)
	return out
end

-- Items (records) inside pad u, and their world positions.
function PlacementService.ItemsInPad(player: Player, padU: number): { any }
	local grid, plot = grids[player], PlotService.GetPlot(player)
	if not grid or not plot then
		return {}
	end
	local out = {}
	for _, it in grid:ItemsInPad(padU) do
		local def = Items.Get(it.id)
		table.insert(out, { item = it, def = def, pos = itemCFrame(plot, it, def).Position })
	end
	return out
end

function PlacementService.CountKind(player: Player, kind: string): number
	local grid = grids[player]
	local n = 0
	if grid then
		for _, it in grid.items do
			local def = Items.Get(it.id)
			if def and def.Kind == kind then
				n += 1
			end
		end
	end
	return n
end

function PlacementService.Init()
	PlotService.OnAssigned(function(player, plot, data)
		local grid = PlotGrid.new()
		grids[player] = grid
		models[player] = {}
		for _, it in data.plot.items do
			grid:Add(it)
			spawnModel(player, plot, it)
		end
	end, 20)
	Players.PlayerRemoving:Connect(function(p)
		grids[p] = nil
		models[p] = nil -- PlotService clears the folder
	end)
	Guard.Bind("PlaceItem", place)
	Guard.Bind("RotateItem", function(player, data, u, rot)
		local item = findItem(data, u)
		if not item then
			return false, "Bad request"
		end
		return move(player, data, u, item.x, item.z, rot)
	end)
	Guard.Bind("MoveItem", move)
	Guard.Bind("RemoveItem", remove)
end

return PlacementService
