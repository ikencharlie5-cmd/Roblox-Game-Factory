--!strict
-- WorldService: builds the whole map in code and exposes a visual API for Gameplay.
-- All functions are server-side and purely visual; Gameplay stays the source of truth.
-- Full API + tags: games/plant-zoo/notes/graphics.md
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local World = script.Parent.Parent:WaitForChild("World")
local Build = require(World:WaitForChild("Build"))
local Biomes = require(World:WaitForChild("Biomes"))
local Plots = require(World:WaitForChild("Plots"))
local Hub = require(World:WaitForChild("Hub"))
local Scenery = require(World:WaitForChild("Scenery"))
local Sky = require(World:WaitForChild("Sky"))
local Items = require(World:WaitForChild("Items"))
local Motion = require(World:WaitForChild("Motion"))
local Reserve = require(World:WaitForChild("Reserve"))

local WorldService = {}
WorldService.Ready = false

local DEFAULT_PAD_PRICES = { 0, 500, 5000, 40000, 250000, 1500000, 10000000, 60000000, 400000000 }

local plots: { Plots.Plot } = {}
local hub: Hub.HubRefs
local visitorOverride: { [number]: number } = {}

local function padPrice(i: number): number
	local list = (Config :: any).PadPrices
	return if typeof(list) == "table" and list[i] then list[i] else DEFAULT_PAD_PRICES[i] or 0
end

local function getPad(plotIndex: number, padIndex: number): (Plots.Plot?, Plots.Pad?)
	local plot = plots[plotIndex]
	if not plot then
		warn("[WorldService] bad plot index", plotIndex)
		return nil, nil
	end
	return plot, plot.pads[padIndex]
end

local function refreshVisitors(plotIndex: number)
	local plot = plots[plotIndex]
	if not plot then
		return
	end
	local grown, thriving = Items.Counts(plotIndex)
	plot.model:SetAttribute("ThrivingCount", thriving)
	plot.model:SetAttribute("GrownCount", grown)
	local owned = (plot.model:GetAttribute("OwnerUserId") or 0) ~= 0
	local n = visitorOverride[plotIndex] or (if owned and grown > 0 then math.clamp(2 + grown // 2, 2, 6) else 0)
	Motion.SetVisitors(plot.visitors, plot.model, plot.cf, n)
end

-- Pads -------------------------------------------------------------------------------------------
function WorldService.SetPadUnlocked(plotIndex: number, padIndex: number, unlocked: boolean, price: number?)
	local _, pad = getPad(plotIndex, padIndex)
	if not pad then
		return
	end
	pad.base:SetAttribute("Unlocked", unlocked)
	pad.lock:ClearAllChildren()
	pad.dressing:ClearAllChildren()
	if unlocked then
		Biomes.Apply(pad.base, pad.dressing, pad.base:GetAttribute("Biome") :: string?)
	else
		Biomes.Lock(pad.base, pad.lock, "$" .. Format.Number(price or padPrice(padIndex)), padIndex)
	end
	pad.jar:SetAttribute("Active", unlocked)
	pad.jarVisual.Parent = if unlocked then pad.model else nil
	pad.jar.CanTouch = unlocked
end

function WorldService.SetPadBiome(plotIndex: number, padIndex: number, biome: string)
	local _, pad = getPad(plotIndex, padIndex)
	if not pad then
		return
	end
	pad.base:SetAttribute("Biome", Theme.BiomeKey(biome) or "Meadow")
	if pad.base:GetAttribute("Unlocked") then
		Biomes.Apply(pad.base, pad.dressing, biome)
	end
end

function WorldService.SetTipJar(plotIndex: number, padIndex: number, amount: number)
	local _, pad = getPad(plotIndex, padIndex)
	if not pad then
		return
	end
	pad.jar:SetAttribute("Amount", amount)
	pad.jarLabel.Text = "$" .. Format.Number(amount)
	local bb = pad.jarLabel.Parent :: BillboardGui
	bb.Enabled = amount > 0
	-- Fill height grows with log10 of the amount (0.2 .. 1.8 studs).
	local h = if amount <= 0 then 0.2 else math.clamp(0.2 + math.log10(amount + 1) * 0.3, 0.2, 1.8)
	local bottom = (pad.jar.CFrame * CFrame.new(0, -1.5 + 0.4, 0))
	pad.jarFill.Size = Vector3.new(h, pad.jarFill.Size.Y, pad.jarFill.Size.Z)
	pad.jarFill.CFrame = bottom * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
end

function WorldService.PlayCoinBurst(plotIndex: number, padIndex: number, count: number?)
	local _, pad = getPad(plotIndex, padIndex)
	if not pad then
		return
	end
	local e = pad.jar:FindFirstChild("CoinBurst") :: ParticleEmitter?
	if not e then
		local made = Theme.Effects.CoinBurst()
		made.Name = "CoinBurst"
		made.Parent = pad.jar
		e = made
	end
	if e then
		e:Emit(count or 25)
	end
end

-- Plots ------------------------------------------------------------------------------------------
function WorldService.GetPlot(i: number): Model?
	local p = plots[i]
	return if p then p.model else nil
end

function WorldService.GetPlotCFrame(i: number): CFrame
	local p = plots[i]
	return if p then p.cf else Plots.CFrameFor(i)
end

function WorldService.GetSpawnCFrame(i: number): CFrame
	local p = plots[i]
	local cf = if p then p.spawn.CFrame else Plots.CFrameFor(i)
	return cf + Vector3.new(0, 3, 0)
end

function WorldService.GetPad(plotIndex: number, padIndex: number): BasePart?
	local _, pad = getPad(plotIndex, padIndex)
	return if pad then pad.base else nil
end

-- World CFrame of a grid cell (1..25) on a pad's top surface; rot 0..3.
function WorldService.GetCellCFrame(plotIndex: number, padIndex: number, cell: number, rot: number?): CFrame?
	local _, pad = getPad(plotIndex, padIndex)
	return if pad then Items.CellCFrame(pad, cell, rot or 0) else nil
end

function WorldService.SetPlotOwner(plotIndex: number, player: Player?)
	local plot = plots[plotIndex]
	if not plot then
		return
	end
	if not player then
		WorldService.ResetPlot(plotIndex)
	end
	plot.model:SetAttribute("OwnerUserId", if player then player.UserId else 0)
	plot.model:SetAttribute("OwnerName", if player then player.DisplayName else "")
	if not player then
		plot.model:SetAttribute("Likes", 0)
	end
	refreshVisitors(plotIndex)
end

function WorldService.SetPlotLikes(plotIndex: number, likes: number)
	local plot = plots[plotIndex]
	if plot then
		plot.model:SetAttribute("Likes", likes)
	end
end

-- Back to a fresh plot: items cleared, pad 1 unlocked (Meadow), others locked, jars empty.
function WorldService.ResetPlot(plotIndex: number)
	local plot = plots[plotIndex]
	if not plot then
		return
	end
	Items.ClearPlot(plotIndex)
	for i, pad in plot.pads do
		pad.base:SetAttribute("Biome", "Meadow")
		WorldService.SetPadUnlocked(plotIndex, i, i == 1)
		WorldService.SetTipJar(plotIndex, i, 0)
	end
end

-- nil = automatic (2..6 by grown creatures while the plot is owned).
function WorldService.SetVisitorCount(plotIndex: number, n: number?)
	visitorOverride[plotIndex] = n
	refreshVisitors(plotIndex)
end

-- Creatures + decor ------------------------------------------------------------------------------
-- stage: "Seed"|"Sprout"|"Bud"|"Grown" or 1..4. look: { Color="Gold"|"Diamond"|"Rainbow", Weather="Dewy"|..., Thriving=bool }
function WorldService.SpawnCreature(
	id: any,
	plotIndex: number,
	padIndex: number,
	cell: number,
	rot: number?,
	species: string,
	stage: any,
	look: Items.Look?
): Model?
	local plot, pad = getPad(plotIndex, padIndex)
	if not plot or not pad then
		return nil
	end
	return Items.SpawnCreature(tostring(id), plot, pad, cell, rot or 0, species, stage, look)
end

function WorldService.SetCreatureStage(id: any, stage: any): Model?
	return Items.SetStage(tostring(id), stage)
end

function WorldService.SetCreatureLook(id: any, look: Items.Look)
	Items.SetLook(tostring(id), look)
end

function WorldService.SpawnDecor(
	id: any,
	plotIndex: number,
	padIndex: number,
	cell: number,
	rot: number?,
	kind: string
): Model?
	local plot, pad = getPad(plotIndex, padIndex)
	if not plot or not pad then
		return nil
	end
	return Items.SpawnDecor(tostring(id), plot, pad, cell, rot or 0, kind)
end

function WorldService.MoveItem(id: any, plotIndex: number, padIndex: number, cell: number, rot: number?)
	local plot, pad = getPad(plotIndex, padIndex)
	if plot and pad then
		Items.Move(tostring(id), plot, pad, cell, rot or 0)
	end
end

function WorldService.RemoveItem(id: any)
	Items.Remove(tostring(id))
end

function WorldService.GetItemModel(id: any): Model?
	return Items.Get(tostring(id))
end

-- Hub ----------------------------------------------------------------------------------------------
-- entries: { { Name = string, Value = number } } sorted best-first (max 10).
function WorldService.SetLeaderboard(entries: { { Name: string, Value: number } })
	for i, row in hub.boardRows do
		local e = entries[i]
		row.Text = if e
			then string.format("%d. %s  $%s", i, e.Name, Format.Number(e.Value))
			else string.format("%d. ---", i)
	end
end

function WorldService.AddReserveCreature(species: string, color: string?, ownerName: string)
	Reserve.Add(species, color, ownerName)
end

-- Tall green beam + puff where a creature is released (e.g. its old position).
function WorldService.PlayReleaseBeam(position: Vector3)
	Reserve.Beam(position)
end

-- Weather / time -----------------------------------------------------------------------------------
function WorldService.SetWeather(name: string?)
	Sky.SetWeather(name)
end

function WorldService.IsNight(): boolean
	return Sky.IsNight()
end

function WorldService.WaitReady()
	while not WorldService.Ready do
		task.wait()
	end
end

-- Lifecycle ----------------------------------------------------------------------------------------
function WorldService.Init()
	local root = Build.Folder(Workspace, "World")
	local areas = { Vector3.zero }
	for i = 1, Plots.Count do
		table.insert(areas, Plots.CFrameFor(i).Position)
	end
	Sky.Setup(areas)
	hub = Hub.Build(root)
	Reserve.Init(Build.Folder(root, "ReserveCreatures"), hub.reserveZones)
	plots = Plots.Build(Build.Folder(root, "Plots"), function(_, pad)
		pad.base:SetAttribute("Biome", "Meadow")
		if pad.index == 1 then
			Biomes.Apply(pad.base, pad.dressing, "Meadow")
			pad.base:SetAttribute("Unlocked", true)
			pad.jar:SetAttribute("Active", true)
		else
			Biomes.Lock(pad.base, pad.lock, "$" .. Format.Number(padPrice(pad.index)), pad.index)
			pad.jarVisual.Parent = nil
			pad.jar.CanTouch = false
		end
	end)
	Items.OnChanged(function(plotIndex)
		task.defer(refreshVisitors, plotIndex)
	end)
	task.spawn(Scenery.Build, root, Plots.Count, Plots.Radius)
	WorldService.Ready = true
	Workspace:SetAttribute("WorldReady", true)
end

function WorldService.Start()
	Sky.StartCycle()
	Items.StartRainbow()
	local period = ((Config :: any).RestockSeconds :: number?) or 300
	Players.PlayerRemoving:Connect(function(player)
		for i, plot in plots do
			if plot.model:GetAttribute("OwnerUserId") == player.UserId then
				WorldService.SetPlotOwner(i, nil)
			end
		end
	end)
	while true do
		local left = period - os.time() % period
		hub.restockLabel.Text = string.format("Restock %d:%02d", left // 60, left % 60)
		task.wait(1)
	end
end

return WorldService
