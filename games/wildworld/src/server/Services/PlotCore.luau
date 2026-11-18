--!strict
-- Helper for PlotService (not a service): plot claim. Assigns 1 of 8 plots on join (frees on leave),
-- spawns players at home, plot <-> world transforms.
-- Finds plots by CollectionService tag "Plot" (attribute PlotIndex) from Graphics' World builder; top surface = ground.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local PlotCore = {}

local owners: { [number]: Player } = {}
local plotOf: { [Player]: number } = {}
local cfCache: { [number]: CFrame } = {}
local folders: { [number]: Folder } = {}
local assignedCbs: { { fn: (Player, number, any) -> (), p: number } } = {}
local freedCbs: { (Player, number) -> () } = {}

local function findPlotPart(plot: number): Instance?
	for _, inst in CollectionService:GetTagged("Plot") do
		if inst:GetAttribute("PlotIndex") == plot then
			return inst
		end
	end
	return nil
end

-- Fallback ground if the World builder didn't build plots (keeps the game playable from rojo build).
local function fallbackPlot(plot: number): BasePart
	local a = math.rad((plot - 1) * 360 / Config.Grid.PlotCount)
	local pos = Vector3.new(math.cos(a), 0, math.sin(a)) * Config.Grid.PlotRadius
	local p = Instance.new("Part")
	p.Name = "FallbackPlot" .. plot
	p.Anchored = true
	p.Size = Vector3.new(Config.Grid.PlotSize, 2, Config.Grid.PlotSize)
	p.CFrame = CFrame.lookAt(pos - Vector3.new(0, 1, 0), Vector3.new(0, -1, 0))
	p.Color = Color3.fromRGB(108, 198, 68)
	p.Material = Enum.Material.Grass
	p:SetAttribute("PlotIndex", plot)
	p.Parent = workspace
	CollectionService:AddTag(p, "Plot")
	return p
end

-- Plot centre at ground level; -Z faces the hub.
function PlotCore.PlotCFrame(plot: number): CFrame
	local cached = cfCache[plot]
	if cached then
		return cached
	end
	local inst = findPlotPart(plot) or fallbackPlot(plot)
	local cf: CFrame
	if inst:IsA("BasePart") then
		cf = inst.CFrame * CFrame.new(0, inst.Size.Y / 2, 0)
	elseif inst:IsA("Model") then
		local mcf, size = inst:GetBoundingBox()
		cf = mcf * CFrame.new(0, size.Y / 2, 0)
	else
		cf = CFrame.new()
	end
	-- keep it level
	local look = cf.LookVector
	cf = CFrame.lookAt(cf.Position, cf.Position + Vector3.new(look.X, 0, look.Z))
	cfCache[plot] = cf
	return cf
end

function PlotCore.PlotPart(plot: number): Instance?
	return findPlotPart(plot)
end

-- World CFrame of plot-local (lx, lz) studs at ground + y, rotated rotDeg around Y.
function PlotCore.ToWorld(plot: number, lx: number, lz: number, y: number?, rotDeg: number?): CFrame
	return PlotCore.PlotCFrame(plot) * CFrame.new(lx, y or 0, lz) * CFrame.Angles(0, math.rad(rotDeg or 0), 0)
end

function PlotCore.ToLocal(plot: number, pos: Vector3): Vector3
	return PlotCore.PlotCFrame(plot):PointToObjectSpace(pos)
end

-- Is a world position over this plot's 128x128 square (any height within 60 studs)?
function PlotCore.IsOnPlot(plot: number, pos: Vector3): boolean
	local l = PlotCore.ToLocal(plot, pos)
	local half = Config.Grid.PlotSize / 2
	return math.abs(l.X) <= half and math.abs(l.Z) <= half and math.abs(l.Y) < 60
end

function PlotCore.GetPlot(player: Player): number?
	return plotOf[player]
end

function PlotCore.GetOwner(plot: number): Player?
	return owners[plot]
end

-- Folder for this plot's placed items (workspace.ParkObjects.Plot_<i>).
function PlotCore.Folder(plot: number): Folder
	local f = folders[plot]
	if f and f.Parent then
		return f
	end
	local root = workspace:FindFirstChild("ParkObjects") :: Folder?
	if not root then
		local nr = Instance.new("Folder")
		nr.Name = "ParkObjects"
		nr.Parent = workspace
		root = nr
	end
	local nf = Instance.new("Folder")
	nf.Name = "Plot_" .. plot
	nf:SetAttribute("PlotIndex", plot)
	nf.Parent = root
	folders[plot] = nf
	return nf
end

-- (player, plot, data) in priority order after a plot is assigned on load.
function PlotCore.OnAssigned(fn: (Player, number, any) -> (), priority: number?)
	table.insert(assignedCbs, { fn = fn, p = priority or 100 })
	table.sort(assignedCbs, function(a, b)
		return a.p < b.p
	end)
end

function PlotCore.OnFreed(fn: (Player, number) -> ())
	table.insert(freedCbs, fn)
end

function PlotCore.SpawnCFrame(plot: number): CFrame
	for _, inst in CollectionService:GetTagged("PlotSpawn") do
		if inst:GetAttribute("PlotIndex") == plot and inst:IsA("BasePart") then
			return inst.CFrame + Vector3.new(0, 4, 0)
		end
	end
	local pos = PlotCore.ToWorld(plot, 0, -20, 4).Position
	local centre = PlotCore.ToWorld(plot, 0, 0, 4).Position
	return CFrame.lookAt(pos, centre)
end

function PlotCore.TeleportTo(player: Player, plot: number)
	local char = player.Character
	if char then
		char:PivotTo(PlotCore.SpawnCFrame(plot))
	end
end

local function setPlotAttrs(plot: number, player: Player?, data: any?)
	local part = findPlotPart(plot)
	if part then
		part:SetAttribute("OwnerId", if player then player.UserId else 0)
		part:SetAttribute("OwnerName", if player then player.DisplayName else "")
		part:SetAttribute("LandSize", Formulas.LandSize(if data then data.upgrades.Land else 0))
	end
end

function PlotCore.RefreshLand(player: Player)
	local plot = plotOf[player]
	if plot then
		setPlotAttrs(plot, player, DataService.Get(player))
	end
end

local function onLoaded(player: Player, data: any)
	local plot: number? = nil
	for i = 1, Config.Grid.PlotCount do
		if not owners[i] then
			plot = i
			break
		end
	end
	if not plot then
		player:Kick("This server is full of parks. Please join another server!")
		return
	end
	owners[plot] = player
	plotOf[player] = plot
	player:SetAttribute("PlotIndex", plot)
	setPlotAttrs(plot, player, data)
	for _, cb in assignedCbs do
		local ok, err = pcall(cb.fn, player, plot, data)
		if not ok then
			warn("[PlotCore] OnAssigned callback failed:", err)
		end
	end
	if player.Character then
		PlotCore.TeleportTo(player, plot)
	end
end

-- Called from PlotService.Init.
function PlotCore.Bind()
	DataService.OnLoaded(onLoaded, 10)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			local plot = plotOf[player]
			if plot then
				task.defer(function()
					char:PivotTo(PlotCore.SpawnCFrame(plot))
				end)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local plot = plotOf[player]
		if not plot then
			return
		end
		for _, fn in freedCbs do
			pcall(fn, player, plot)
		end
		local f = folders[plot]
		if f then
			f:ClearAllChildren()
		end
		owners[plot] = nil
		plotOf[player] = nil
		setPlotAttrs(plot, nil, nil)
	end)
end

return PlotCore
