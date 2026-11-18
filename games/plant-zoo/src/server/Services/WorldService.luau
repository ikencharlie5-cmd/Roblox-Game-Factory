--!strict
-- WorldService: builds the whole map in code and keeps visuals in sync with Gameplay's state.
-- Mostly attribute-driven (Gameplay sets attributes, we render):
--   ExhibitPad Unlocked/Biome/Price -> hedge+price sign or biome kit;  TipJar Amount -> jar fill + coin burst;
--   Plot OwnerName/Likes -> sign;  workspace.ZooItems items -> creature/decor visuals (World/ItemVisuals);
--   GameState Weather/NextRestockAt/TopEarned/WorldReserve -> sky, restock clock, leaderboard, reserve.
-- Full API + tags: games/plant-zoo/notes/graphics.md
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local CreatureModels = require(Shared:WaitForChild("CreatureModels"))

local World = script.Parent.Parent:WaitForChild("World")
local Build = require(World:WaitForChild("Build"))
local Biomes = require(World:WaitForChild("Biomes"))
local Plots = require(World:WaitForChild("Plots"))
local Hub = require(World:WaitForChild("Hub"))
local Scenery = require(World:WaitForChild("Scenery"))
local Sky = require(World:WaitForChild("Sky"))
local Motion = require(World:WaitForChild("Motion"))
local Reserve = require(World:WaitForChild("Reserve"))
local ItemVisuals = require(World:WaitForChild("ItemVisuals"))
local StateSync = require(World:WaitForChild("StateSync"))

local WorldService = {}
WorldService.Ready = false

local plots: { Plots.Plot } = {}
local hub: Hub.HubRefs = nil :: any
local visitorOverride: { [number]: number } = {}

local function padPrice(i: number): number
	local list = (Config :: any).PadCosts
	return if typeof(list) == "table" and list[i] then list[i] else 0
end

local function getPad(plotIndex: number, padIndex: number): Plots.Pad?
	local plot = plots[plotIndex]
	return if plot then plot.pads[padIndex] else nil
end

local function refreshVisitors(plotIndex: number)
	local plot = plots[plotIndex]
	if not plot then
		return
	end
	local grown, thriving = ItemVisuals.Counts(plotIndex)
	plot.model:SetAttribute("ThrivingCount", thriving)
	plot.model:SetAttribute("GrownCount", grown)
	local owned = (plot.model:GetAttribute("OwnerUserId") or 0) ~= 0
	local n = visitorOverride[plotIndex] or (if owned and grown > 0 then math.clamp(2 + grown // 2, 2, 6) else 0)
	Motion.SetVisitors(plot.visitors, plot.model, plot.cf, n)
end

-- Pad rendering (reads the ExhibitPad's attributes) ----------------------------------------------
local function renderPad(pad: Plots.Pad)
	local base = pad.base
	local unlocked = base:GetAttribute("Unlocked") == true
	pad.lock:ClearAllChildren()
	pad.dressing:ClearAllChildren()
	if unlocked then
		Biomes.Apply(base, pad.dressing, base:GetAttribute("Biome") :: string?)
	else
		local price = (base:GetAttribute("Price") :: number?) or padPrice(pad.index)
		Biomes.Lock(base, pad.lock, "$" .. Format.Number(price), pad.index)
	end
	pad.jar:SetAttribute("Active", unlocked)
	pad.jarVisual.Parent = if unlocked then pad.model else nil
	pad.jar.CanTouch = unlocked
end

function WorldService.PlayCoinBurst(plotIndex: number, padIndex: number, count: number?)
	local plot = plots[plotIndex]
	local pad = if plot then plot.pads[padIndex] else nil
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

local function renderJar(plotIndex: number, pad: Plots.Pad, old: number)
	local amount = (pad.jar:GetAttribute("Amount") :: number?) or 0
	pad.jarLabel.Text = "$" .. Format.Number(amount)
	local bb = pad.jarLabel.Parent :: BillboardGui
	bb.Enabled = amount > 0
	local h = if amount <= 0 then 0.2 else math.clamp(0.2 + math.log10(amount + 1) * 0.3, 0.2, 1.8)
	local bottom = pad.jar.CFrame * CFrame.new(0, -1.5 + 0.4, 0)
	pad.jarFill.Size = Vector3.new(h, pad.jarFill.Size.Y, pad.jarFill.Size.Z)
	pad.jarFill.CFrame = bottom * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	if amount < old and old > 0 then
		WorldService.PlayCoinBurst(plotIndex, pad.index)
	end
end

local function bindPad(plotIndex: number, pad: Plots.Pad)
	local pending = false
	pad.base.AttributeChanged:Connect(function(name)
		if (name == "Unlocked" or name == "Biome" or name == "Price") and not pending then
			pending = true
			task.defer(function()
				pending = false
				renderPad(pad)
			end)
		end
	end)
	local last = 0
	pad.jar:GetAttributeChangedSignal("Amount"):Connect(function()
		renderJar(plotIndex, pad, last)
		last = (pad.jar:GetAttribute("Amount") :: number?) or 0
	end)
end

-- Public API ---------------------------------------------------------------------------------------
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
	return (if p then p.spawn.CFrame else Plots.CFrameFor(i)) + Vector3.new(0, 3, 0)
end

function WorldService.GetPad(plotIndex: number, padIndex: number): BasePart?
	local pad = getPad(plotIndex, padIndex)
	return if pad then pad.base else nil
end

-- Pad top-surface CFrame (planting surface), -Z toward the hub.
function WorldService.GetPadTop(plotIndex: number, padIndex: number): CFrame?
	local pad = getPad(plotIndex, padIndex)
	return if pad then Plots.PadTop(pad) else nil
end

-- World CFrame of grid cell 1..25 on a pad's top; rot in degrees (0/90/180/270).
function WorldService.GetCellCFrame(plotIndex: number, padIndex: number, cell: number, rot: number?): CFrame?
	local top = WorldService.GetPadTop(plotIndex, padIndex)
	return if top then top * Theme.CellOffset(cell, rot) else nil
end

-- Same as setting the ExhibitPad attributes yourself.
function WorldService.SetPadUnlocked(plotIndex: number, padIndex: number, unlocked: boolean, price: number?)
	local pad = getPad(plotIndex, padIndex)
	if pad then
		if price then
			pad.base:SetAttribute("Price", price)
		end
		pad.base:SetAttribute("Unlocked", unlocked)
	end
end

function WorldService.SetPadBiome(plotIndex: number, padIndex: number, biome: string)
	local pad = getPad(plotIndex, padIndex)
	if pad then
		pad.base:SetAttribute("Biome", Theme.BiomeKey(biome) or "Meadow")
	end
end

function WorldService.SetTipJar(plotIndex: number, padIndex: number, amount: number)
	local pad = getPad(plotIndex, padIndex)
	if pad then
		pad.jar:SetAttribute("Amount", amount)
	end
end

function WorldService.SetPlotOwner(plotIndex: number, player: Player?)
	local plot = plots[plotIndex]
	if plot then
		plot.model:SetAttribute("OwnerUserId", if player then player.UserId else 0)
		plot.model:SetAttribute("OwnerName", if player then player.DisplayName else "")
	end
end

function WorldService.SetPlotLikes(plotIndex: number, likes: number)
	local plot = plots[plotIndex]
	if plot then
		plot.model:SetAttribute("Likes", likes)
	end
end

-- nil = automatic (2..6 by grown creatures while the plot is owned).
function WorldService.SetVisitorCount(plotIndex: number, n: number?)
	visitorOverride[plotIndex] = n
	refreshVisitors(plotIndex)
end

-- Generic creature model (e.g. for cutscenes): CreatureModels.Build placed at cf.
function WorldService.SpawnCreatureModel(
	species: string,
	stage: any,
	look: { [string]: any }?,
	cf: CFrame,
	parent: Instance?
): Model
	local m = CreatureModels.Build(species, stage, look :: any)
	m:PivotTo(cf)
	m.Parent = parent or Workspace
	return m
end

-- entries: { {Name=, Value=} } or gameplay's { {rank, userId, name, value} }, best first.
function WorldService.SetLeaderboard(entries: { any })
	for i, row in hub.boardRows do
		local e = entries[i]
		local name = e and (e.Name or e.name)
		local value = e and (e.Value or e.value)
		row.Text = if name
			then string.format("%d. %s  $%s", i, tostring(name), Format.Number(tonumber(value) or 0))
			else string.format("%d. ---", i)
	end
end

function WorldService.AddReserveCreature(species: string, color: string?, ownerName: string)
	Reserve.Add(species, color, ownerName)
end

function WorldService.PlayReleaseBeam(position: Vector3)
	Reserve.Beam(position)
end

function WorldService.SetWeather(name: string?)
	Sky.SetWeather(name)
end

function WorldService.IsNight(): boolean
	return Sky.IsNight()
end

-- Lifecycle ------------------------------------------------------------------------------------------
function WorldService.Init()
	local root = Build.Folder(Workspace, "World")
	local areas = { Vector3.zero }
	local plotCFs = {}
	for i = 1, Plots.Count do
		table.insert(areas, Plots.CFrameFor(i).Position)
		table.insert(plotCFs, Plots.CFrameFor(i))
	end
	Sky.Setup(areas)
	-- Terrain grass + dirt under part-built areas (synchronous: players stand on it).
	Scenery.Ground(plotCFs, Hub.Radius)
	hub = Hub.Build(root)
	Reserve.Init(Build.Folder(root, "ReserveCreatures"), hub.reserveZones)
	plots = Plots.Build(Build.Folder(root, "Plots"), function(plot, pad)
		pad.base:SetAttribute("Biome", "Meadow")
		pad.base:SetAttribute("Price", padPrice(pad.index))
		pad.base:SetAttribute("Unlocked", pad.index == 1)
		renderPad(pad)
		bindPad(plot.index, pad)
	end)
	for _, plot in plots do
		plot.model:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			refreshVisitors(plot.index)
		end)
	end
	task.spawn(Scenery.Build, root, Plots.Count, Plots.Radius)
	WorldService.Ready = true
	Workspace:SetAttribute("WorldReady", true)
end

function WorldService.Start()
	Sky.StartCycle()
	ItemVisuals.Start(WorldService.GetPadTop, function(plotIndex)
		task.defer(refreshVisitors, plotIndex)
	end)
	StateSync.Start(WorldService.SetLeaderboard, Reserve.Sync, Sky.SetWeather, hub.restockLabel)
	Players.PlayerRemoving:Connect(function(player)
		for i, plot in plots do
			if plot.model:GetAttribute("OwnerUserId") == player.UserId then
				task.delay(1, refreshVisitors, i)
			end
		end
	end)
end

return WorldService
