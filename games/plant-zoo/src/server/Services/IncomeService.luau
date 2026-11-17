--!strict
-- Visitor income: every second each pad's $/s goes into its Tip Jar (data.jars[pad]).
-- Walking over a TipJar (server Touched) collects it. Offline earnings on join.
-- Auto Gardener pass auto-collects. Cash Boost Dev Product.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local IncomeService = {}

local debounce: { [Player]: number } = {}
local hooked: { [Instance]: boolean } = {}
local fallbackJars: { [string]: BasePart } = {}

function IncomeService.PerSecond(player: Player): number
	local _, total = ItemService.Income(player)
	return total
end

local function jarInstance(plot: number, pad: number): Instance?
	return PlotService.FindJar(plot, pad) or fallbackJars[plot .. "_" .. pad]
end

local function showJar(player: Player, pad: number, amount: number)
	local plot = PlotService.GetPlotIndex(player)
	if not plot then
		return
	end
	local jar = jarInstance(plot, pad)
	if jar then
		jar:SetAttribute("Amount", amount)
	end
end

-- Collect one pad's jar (or all pads if pad == nil). Returns amount collected.
function IncomeService.Collect(player: Player, pad: number?): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local total = 0
	for i, v in data.jars do
		if (pad == nil or pad == i) and v > 0 then
			total += v
		end
	end
	total = math.floor(total)
	if total <= 0 then
		return 0
	end
	DataService.Update(player, function(d)
		for i in d.jars do
			if pad == nil or pad == i then
				d.jars[i] = 0
			end
		end
		d.cash += total
		d.totalEarned += total
	end)
	for i in data.jars do
		if pad == nil or pad == i then
			showJar(player, i, 0)
		end
	end
	Guard.Sound(player, "Cash")
	QuestService.Progress(player, "CollectJar", 1)
	QuestService.Progress(player, "CollectCash", total)
	return total
end

local function onJarTouched(jar: Instance, hit: BasePart)
	local char = hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then
		return
	end
	if jar:GetAttribute("PlotIndex") ~= PlotService.GetPlotIndex(player) then
		return
	end
	local now = os.clock()
	if now - (debounce[player] or 0) < 0.5 then
		return
	end
	debounce[player] = now
	local pad = jar:GetAttribute("PadIndex")
	if type(pad) == "number" then
		IncomeService.Collect(player, pad)
	end
end

local function hookJar(jar: Instance)
	if hooked[jar] then
		return
	end
	local part: BasePart? = if jar:IsA("BasePart") then jar else jar:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		warn("[IncomeService] TipJar has no BasePart:", jar:GetFullName())
		return
	end
	hooked[jar] = true
	part.CanTouch = true
	part.Touched:Connect(function(hit)
		onJarTouched(jar, hit)
	end)
end

-- If Graphics didn't tag a TipJar for a pad, make a simple one at the pad's front edge.
local function ensureJars(plot: number)
	for pad = 1, #Config.PadCosts do
		local key = plot .. "_" .. pad
		if not PlotService.FindJar(plot, pad) and not fallbackJars[key] then
			warn("[IncomeService] no TipJar for plot", plot, "pad", pad, "- creating fallback")
			local p = Instance.new("Part")
			p.Name = "FallbackTipJar"
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(3, 3, 3)
			p.Color = Color3.fromHex("FFC83D")
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored = true
			p.CanCollide = false
			p.CFrame = PlotService.PadCFrame(plot, pad)
				* CFrame.new(Config.Grid.PadSize / 2 + 1, 1.5, -Config.Grid.PadSize / 2 - 1)
				* CFrame.Angles(0, 0, math.rad(90))
			p:SetAttribute("PlotIndex", plot)
			p:SetAttribute("PadIndex", pad)
			p.Parent = workspace
			fallbackJars[key] = p
			hookJar(p)
		end
	end
end

local function grantOffline(player: Player, plot: number)
	local data = DataService.Get(player)
	if not data or (data.lastOnline or 0) <= 0 then
		return
	end
	local away = os.time() - data.lastOnline
	if away < Config.Income.OfflineMinSeconds then
		return
	end
	-- give passes a moment to load so VIP rate applies
	for _ = 1, 50 do
		if player:GetAttribute("Pass_VIP") ~= nil and player:GetAttribute("IncomePerSec") ~= nil then
			break
		end
		task.wait(0.1)
	end
	ItemService.RefreshAll(player)
	local rate = IncomeService.PerSecond(player)
	local vip = MonetizationService.HasPass(player, "VIP")
	local secs = math.min(away, Formulas.OfflineCapSeconds(data))
	local amount = math.floor(rate * secs * (if vip then Config.Income.OfflineRateVIP else Config.Income.OfflineRate))
	if amount > 0 then
		DataService.AddCash(player, amount, true)
		Remotes.Event("OfflineEarnings"):FireClient(player, amount, secs)
	end
	ensureJars(plot)
end

function IncomeService.Init()
	PlotService.OnAssigned(function(player, plot)
		ensureJars(plot)
		local data = DataService.Get(player)
		if data then
			for i, v in data.jars do
				showJar(player, i, v)
			end
		end
		grantOffline(player, plot)
	end)
	Players.PlayerRemoving:Connect(function(p)
		debounce[p] = nil
	end)
	MonetizationService.RegisterProduct("CashBoost", function(player)
		local def = Config.DevProducts.CashBoost
		local amount = math.max(def.Min, math.floor(IncomeService.PerSecond(player) * 60 * def.Minutes))
		DataService.AddCash(player, amount, true)
		Guard.Notify(player, "Cash Boost: +$" .. Format.Number(amount), "success")
		return true
	end)
end

function IncomeService.Start()
	for _, jar in CollectionService:GetTagged("TipJar") do
		hookJar(jar)
	end
	CollectionService:GetInstanceAddedSignal("TipJar"):Connect(hookJar)

	local lastAuto = os.clock()
	while true do
		task.wait(1)
		local doAuto = os.clock() - lastAuto >= Config.AutoGardenerSeconds
		if doAuto then
			lastAuto = os.clock()
		end
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data and PlotService.GetPlotIndex(player) then
				local perPad = ItemService.Income(player)
				for pad, v in perPad do
					if v > 0 and data.jars[pad] then
						DataService.UpdateQuiet(player, function(d)
							d.jars[pad] += v
						end)
						showJar(player, pad, data.jars[pad])
					end
				end
				if doAuto and MonetizationService.HasPass(player, "AutoGardener") then
					IncomeService.Collect(player, nil)
				end
			end
		end
	end
end

return IncomeService
