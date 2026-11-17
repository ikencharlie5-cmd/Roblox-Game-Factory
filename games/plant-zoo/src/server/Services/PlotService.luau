--!strict
-- Assigns 1 of 6 plots on join, finds plot/pad/jar parts by CollectionService tags
-- (from WorldService), spawns players at home, Visit / GoHome, hub ProximityPrompts.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local PlotService = {}

local owners: { [number]: Player } = {}
local plotOf: { [Player]: number } = {}
local warned: { [string]: boolean } = {}
local assignedCbs: { (Player, number) -> () } = {}

local function warnOnce(key: string, msg: string)
	if not warned[key] then
		warned[key] = true
		warn("[PlotService] " .. msg)
	end
end

local function pivotOf(inst: Instance): CFrame
	if inst:IsA("BasePart") then
		return inst.CFrame
	elseif inst:IsA("Model") then
		return inst:GetPivot()
	end
	return CFrame.new()
end

local function findTagged(tag: string, plot: number, pad: number?): Instance?
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:GetAttribute("PlotIndex") == plot and (pad == nil or inst:GetAttribute("PadIndex") == pad) then
			return inst
		end
	end
	return nil
end

function PlotService.GetPlotIndex(player: Player): number?
	return plotOf[player]
end

function PlotService.GetOwner(plot: number): Player?
	return owners[plot]
end

-- Yields until WorldService has built the plots (workspace.WorldReady), up to Config.WorldReadyTimeout.
function PlotService.WaitWorldReady(): boolean
	local t0 = os.clock()
	while not workspace:GetAttribute("WorldReady") and os.clock() - t0 < Config.WorldReadyTimeout do
		task.wait(0.1)
	end
	return workspace:GetAttribute("WorldReady") == true
end

function PlotService.OnAssigned(fn: (Player, number) -> ())
	table.insert(assignedCbs, fn)
end

-- Plot centre (ground level), facing the hub.
function PlotService.PlotCFrame(plot: number): CFrame
	local inst = findTagged("Plot", plot)
	if inst then
		return pivotOf(inst)
	end
	warnOnce("plot" .. plot, "No part tagged 'Plot' with PlotIndex " .. plot .. "; using computed position")
	local a = math.rad((plot - 1) * 360 / Config.Grid.PlotCount)
	local pos = Vector3.new(math.cos(a), 0, math.sin(a)) * Config.Grid.PlotRadius
	return CFrame.lookAt(pos, Vector3.zero)
end

-- CFrame at the CENTRE of the pad's TOP surface (y = planting height).
function PlotService.PadCFrame(plot: number, pad: number): CFrame
	local inst = findTagged("ExhibitPad", plot, pad)
	if inst and inst:IsA("BasePart") then
		return inst.CFrame * CFrame.new(0, inst.Size.Y / 2, 0)
	elseif inst then
		return pivotOf(inst)
	end
	warnOnce(
		"pad" .. plot .. "_" .. pad,
		"No 'ExhibitPad' for plot " .. plot .. " pad " .. pad .. "; using computed position"
	)
	local row = (pad - 1) // 3
	local col = (pad - 1) % 3
	local sp = Config.Grid.PadSpacing
	return PlotService.PlotCFrame(plot) * CFrame.new((col - 1) * sp, 0.5, (row - 1) * sp)
end

-- World CFrame of a grid cell (1..25) on a pad, rotated by rot degrees.
function PlotService.CellCFrame(plot: number, pad: number, cell: number, rot: number): CFrame
	local n = Config.Grid.CellsPerSide
	local size = Config.Grid.CellSize
	local cx = (cell - 1) % n
	local cz = (cell - 1) // n
	local half = (n - 1) / 2
	return PlotService.PadCFrame(plot, pad)
		* CFrame.new((cx - half) * size, 0, (cz - half) * size)
		* CFrame.Angles(0, math.rad(rot), 0)
end

function PlotService.FindJar(plot: number, pad: number): Instance?
	return findTagged("TipJar", plot, pad)
end

function PlotService.SpawnCFrame(plot: number): CFrame
	local spawnPart = findTagged("PlotSpawn", plot)
	if spawnPart then
		return pivotOf(spawnPart) + Vector3.new(0, 4, 0)
	end
	-- entrance edge, toward the hub
	local cf = PlotService.PlotCFrame(plot)
	return cf * CFrame.new(0, 5, -(1.5 * Config.Grid.PadSpacing + 8)) * CFrame.Angles(0, math.pi, 0)
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if char and char.PrimaryPart then
		char:PivotTo(cf)
	end
end

local function setPlotAttrs(plot: number, player: Player?, data: any?)
	local inst = findTagged("Plot", plot)
	local targets: { Instance } = { Guard.State() }
	if inst then
		table.insert(targets, inst)
	end
	for _, t in targets do
		local prefix = if t == Guard.State() then "Plot" .. plot .. "_" else ""
		t:SetAttribute(prefix .. "OwnerUserId", if player then player.UserId else 0)
		t:SetAttribute(prefix .. "OwnerName", if player then player.DisplayName else "")
		t:SetAttribute(prefix .. "Likes", if data then data.likes else 0)
		t:SetAttribute(prefix .. "PadsOwned", if data then data.padsOwned else 0)
	end
	-- Per pad: Biome, Unlocked, Price (on the ExhibitPad part and mirrored in GameState).
	for pad = 1, #Config.PadCosts do
		local biome = if data then data.padBiome[pad] else "Meadow"
		local unlocked = if data then pad <= data.padsOwned else pad == 1
		local padInst = findTagged("ExhibitPad", plot, pad)
		if padInst then
			padInst:SetAttribute("Biome", biome)
			padInst:SetAttribute("Unlocked", unlocked)
			padInst:SetAttribute("Price", Config.PadCosts[pad])
			padInst:SetAttribute("OwnerUserId", if player then player.UserId else 0)
		end
		local key = "Plot" .. plot .. "_Pad" .. pad .. "_"
		Guard.State():SetAttribute(key .. "Biome", biome)
		Guard.State():SetAttribute(key .. "Unlocked", unlocked)
	end
end

function PlotService.RefreshPlotAttrs(player: Player)
	local plot = plotOf[player]
	local data = DataService.Get(player)
	if plot and data then
		setPlotAttrs(plot, player, data)
	end
end

local function assign(player: Player, data: any)
	if not PlotService.WaitWorldReady() then
		warnOnce("worldready", "workspace.WorldReady never set; assigning with fallback positions")
	end
	if not player.Parent or plotOf[player] then
		return
	end
	for i = 1, Config.Grid.PlotCount do
		if not owners[i] then
			owners[i] = player
			plotOf[player] = i
			player:SetAttribute("PlotIndex", i)
			setPlotAttrs(i, player, data)
			for _, fn in assignedCbs do
				task.spawn(fn, player, i)
			end
			local function onChar(char: Model)
				task.wait(0.2)
				if char.Parent then
					char:PivotTo(PlotService.SpawnCFrame(i))
				end
			end
			player.CharacterAdded:Connect(onChar)
			if player.Character then
				task.spawn(onChar, player.Character)
			end
			return
		end
	end
	warn("[PlotService] server full, no plot for", player.Name)
	Guard.Notify(player, "No free plot on this server", "error")
end

local PROMPTS = {
	ShopStand = { Screen = "SeedShop", Text = "Seed Shop" },
	HopeShop = { Screen = "HopeShop", Text = "Hope Shop" },
	UpgradeStand = { Screen = "Upgrades", Text = "Upgrades" },
	ReleaseAltar = { Screen = "Release", Text = "Release to the Wild" },
	DailyStand = { Screen = "Daily", Text = "Daily Reward" },
}

local function addPrompt(inst: Instance, info: { Screen: string, Text: string })
	if inst:FindFirstChild("OpenPrompt") then
		return
	end
	local parent = if inst:IsA("Model") then (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")) else inst
	if not parent then
		return
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = "OpenPrompt"
	p.ActionText = "Open"
	p.ObjectText = info.Text
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p.Parent = parent
	p.Triggered:Connect(function(plr)
		Remotes.Event("OpenScreen"):FireClient(plr, info.Screen)
	end)
end

function PlotService.Init()
	DataService.OnLoaded(assign)
	Players.PlayerRemoving:Connect(function(p)
		local i = plotOf[p]
		if i then
			owners[i] = nil
			setPlotAttrs(i, nil, nil)
		end
		plotOf[p] = nil
	end)

	Guard.Bind("VisitPlot", function(player, _data, plot)
		if not Guard.IsInt(plot, 1, Config.Grid.PlotCount) then
			return Guard.Fail(player, "Invalid plot")
		end
		if not owners[plot] then
			return Guard.Fail(player, "Nobody owns that plot")
		end
		teleport(player, PlotService.SpawnCFrame(plot))
		return true, plot
	end)
	Guard.Bind("GoHome", function(player)
		local i = plotOf[player]
		if not i then
			return Guard.Fail(player, "You don't have a plot")
		end
		teleport(player, PlotService.SpawnCFrame(i))
		return true, i
	end)
end

function PlotService.Start()
	for tag, info in PROMPTS do
		for _, inst in CollectionService:GetTagged(tag) do
			addPrompt(inst, info)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			addPrompt(inst, info)
		end)
	end
end

return PlotService
