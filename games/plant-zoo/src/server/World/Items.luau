--!strict
-- Registry of placed creatures + decor models on plots (keyed by gameplay's item id).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local CreatureModels = require(Shared:WaitForChild("CreatureModels"))
local Decor = require(script.Parent.Decor)
local Motion = require(script.Parent.Motion)
local Plots = require(script.Parent.Plots)

local Items = {}

export type Look = { Color: string?, Weather: string?, Thriving: boolean? }
type Item = {
	id: string,
	isCreature: boolean,
	model: Model,
	plot: Plots.Plot,
	pad: Plots.Pad,
	cell: number,
	rot: number,
	species: string?,
	stage: string?,
	look: { [string]: any },
}

local items: { [string]: Item } = {}
local rainbow: { [Model]: boolean } = {}
local onChanged: (plotIndex: number) -> () = function(_: number) end

function Items.OnChanged(fn: (number) -> ())
	onChanged = fn
end

local function cellCFrame(pad: Plots.Pad, cell: number, rot: number): CFrame
	return Plots.PadTop(pad) * Theme.CellOffset(cell, rot)
end
Items.CellCFrame = cellCFrame

local function tagModel(item: Item)
	local m = item.model
	m:SetAttribute("ItemId", item.id)
	m:SetAttribute("PlotIndex", item.plot.index)
	m:SetAttribute("PadIndex", item.pad.index)
	m:SetAttribute("Cell", item.cell)
	m:SetAttribute("Rot", item.rot)
	m:SetAttribute("OwnerUserId", item.plot.model:GetAttribute("OwnerUserId"))
	m:AddTag(if item.isCreature then "Creature" else "Decor")
end

local function place(item: Item, pop: boolean)
	local cf = cellCFrame(item.pad, item.cell, item.rot)
	item.model:PivotTo(cf)
	item.model.Parent = item.pad.items
	tagModel(item)
	if item.isCreature then
		rainbow[item.model] = if item.model:GetAttribute("Rainbow") then true else nil
		if pop then
			Motion.Pop(item.model)
		end
		if item.stage == "Grown" then
			local m = item.model
			task.delay(if pop then 0.3 else 0, function()
				if m.Parent then
					Motion.Creature(m, Plots.PadTop(item.pad), cf)
				end
			end)
		end
	end
end

local function buildCreature(item: Item)
	item.model = CreatureModels.Build(item.species or "Sproutling", item.stage, item.look :: any)
end

function Items.SpawnCreature(
	id: string,
	plot: Plots.Plot,
	pad: Plots.Pad,
	cell: number,
	rot: number,
	species: string,
	stage: any,
	look: Look?
): Model
	Items.Remove(id)
	local item: Item = {
		id = id,
		isCreature = true,
		model = nil :: any,
		plot = plot,
		pad = pad,
		cell = cell,
		rot = rot or 0,
		species = species,
		stage = CreatureModels.StageName(stage),
		look = (look or {}) :: any,
	}
	buildCreature(item)
	items[id] = item
	place(item, true)
	onChanged(plot.index)
	return item.model
end

function Items.SpawnDecor(id: string, plot: Plots.Plot, pad: Plots.Pad, cell: number, rot: number, kind: string): Model?
	Items.Remove(id)
	local m = Decor.Build(kind)
	if not m then
		warn("[WorldService] unknown decor kind", kind)
		return nil
	end
	local item: Item =
		{ id = id, isCreature = false, model = m, plot = plot, pad = pad, cell = cell, rot = rot or 0, look = {} }
	items[id] = item
	place(item, false)
	return m
end

function Items.SetStage(id: string, stage: any): Model?
	local item = items[id]
	if not item or not item.isCreature then
		return nil
	end
	local name = CreatureModels.StageName(stage)
	if name == item.stage then
		return item.model
	end
	item.stage = name
	rainbow[item.model] = nil
	item.model:Destroy()
	buildCreature(item)
	place(item, true)
	onChanged(item.plot.index)
	return item.model
end

function Items.SetLook(id: string, look: Look)
	local item = items[id]
	if not item or not item.isCreature then
		return
	end
	for k, v in look :: any do
		item.look[k] = v
	end
	CreatureModels.ApplyLook(item.model, look :: any)
	rainbow[item.model] = if item.model:GetAttribute("Rainbow") then true else nil
	onChanged(item.plot.index)
end

function Items.Move(id: string, plot: Plots.Plot, pad: Plots.Pad, cell: number, rot: number)
	local item = items[id]
	if not item then
		return
	end
	item.plot, item.pad, item.cell, item.rot = plot, pad, cell, rot or 0
	-- Rebuild so the wander "home" updates cleanly.
	local kindName = item.model.Name
	rainbow[item.model] = nil
	item.model:Destroy()
	if item.isCreature then
		buildCreature(item)
	else
		item.model = Decor.Build(kindName) or Instance.new("Model")
	end
	place(item, false)
	onChanged(plot.index)
end

function Items.Remove(id: string)
	local item = items[id]
	if not item then
		return
	end
	items[id] = nil
	rainbow[item.model] = nil
	item.model:Destroy()
	onChanged(item.plot.index)
end

function Items.Get(id: string): Model?
	local item = items[id]
	return if item then item.model else nil
end

function Items.ClearPlot(plotIndex: number)
	for id, item in items do
		if item.plot.index == plotIndex then
			items[id] = nil
			rainbow[item.model] = nil
			item.model:Destroy()
		end
	end
	onChanged(plotIndex)
end

-- (grown creatures, thriving creatures) on a plot.
function Items.Counts(plotIndex: number): (number, number)
	local grown, thriving = 0, 0
	for _, item in items do
		if item.isCreature and item.plot.index == plotIndex and item.stage == "Grown" then
			grown += 1
			if item.model:GetAttribute("Thriving") then
				thriving += 1
			end
		end
	end
	return grown, thriving
end

function Items.StartRainbow()
	task.spawn(function()
		local hue = 0
		while true do
			task.wait(0.25)
			hue = (hue + 0.03) % 1
			for m in rainbow do
				if m.Parent then
					CreatureModels.StepRainbow(m, hue)
				else
					rainbow[m] = nil
				end
			end
		end
	end)
end

return Items
