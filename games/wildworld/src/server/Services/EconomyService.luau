--!strict
-- EconomyService: coins from visitors (income paid as tips every 10 s), offline earnings (50%, cap 2 h),
-- BuyUpgrade, UnlockZone (v1: only Meadow exists; disabled zones answer "future update"), and the
-- hub shop stall (Shop helper: GetShop / BuyShop / restocks). Park Level XP lives in RewardService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Shop = require(script.Parent:WaitForChild("Shop"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local EconomyService = {}

local carry: { [Player]: number } = {}

-- Coin fountain at one of the player's occupied habitats (or plot centre).
function EconomyService.VisitorTip(player: Player, amount: number)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	DataService.AddCoins(player, amount, true)
	local pos: Vector3? = nil
	local data = DataService.Get(player)
	if data then
		local pads = {}
		for _, pad in PlotService.GetPads(player) do
			if #PlotService.CreaturesOnPad(data, pad.u) > 0 then
				table.insert(pads, pad)
			end
		end
		if #pads > 0 then
			pos = pads[math.random(1, #pads)].cf.Position
		end
	end
	local plot = PlotService.GetPlot(player)
	if not pos and plot then
		pos = PlotService.ToWorld(plot, 0, 0).Position
	end
	local plotInst = if plot then PlotService.PlotPart(plot) else nil
	if plotInst then -- client Visitors coin fountain: TipAmount first, then bump Tips
		plotInst:SetAttribute("TipAmount", amount)
		plotInst:SetAttribute("Tips", ((plotInst:GetAttribute("Tips") :: number?) or 0) + 1)
	end
	Remotes.Event("VisitorTip"):FireClient(player, amount, pos)
	Signals.Fire("Earn", player, amount)
end

local function offline(player: Player, data: any)
	player:SetAttribute("Level", data.level)
	if (data.lastSeen or 0) <= 0 then
		return
	end
	local away = os.time() - data.lastSeen
	if away < Config.Economy.OfflineMinSeconds then
		return
	end
	local secs = math.min(away, Config.Economy.OfflineCapSeconds)
	local coins = math.floor(PlotService.IncomePerMin(player) * secs / 60 * Config.Economy.OfflineRate)
	local readyEggs = 0
	for _, e in data.eggs do
		if e.readyAt <= os.time() and e.source ~= "starter" then
			readyEggs += 1
		end
	end
	if coins > 0 then
		DataService.AddCoins(player, coins, true)
	end
	if coins > 0 or readyEggs > 0 then
		Guard.Reveal(player, "Offline", { coins = coins, seconds = away, cappedSeconds = secs, eggsReady = readyEggs })
	end
end

local function buyUpgrade(player: Player, data: any, key: any)
	if type(key) ~= "string" or not (Config.Upgrades :: any)[key] then
		return false, "Bad request"
	end
	local level = data.upgrades[key] or 0
	local cost = Formulas.UpgradeCost(key, level)
	if not cost then
		return Guard.Fail(player, "Already maxed")
	end
	if not DataService.TrySpend(player, cost) then
		return Guard.Fail(player, "Not enough coins")
	end
	DataService.Update(player, function(d)
		d.upgrades[key] = level + 1
	end)
	if key == "Land" then
		PlotService.RefreshLand(player)
	end
	Guard.Sound(player, "Purchase")
	Guard.Toast(player, (Config.Upgrades :: any)[key].Name .. " upgraded!", "success")
	Signals.Fire("CreaturesChanged", player)
	return true, level + 1
end

local function unlockZone(player: Player, data: any, zoneId: any)
	local zone: any = nil
	for _, z in Config.Zones do
		if z.Id == zoneId then
			zone = z
		end
	end
	if not zone then
		return false, "Bad request"
	end
	if not zone.Enabled then
		return Guard.Fail(player, zone.Name .. " opens in a future update!")
	end
	if data.zones[zone.Id] then
		return true, zone.Id
	end
	if data.level < zone.Level then
		return Guard.Fail(player, zone.Name .. " unlocks at Park Level " .. zone.Level)
	end
	if not DataService.TrySpend(player, zone.Cost) then
		return Guard.Fail(player, "Needs " .. zone.Cost .. " coins")
	end
	DataService.Update(player, function(d)
		d.zones[zone.Id] = true
	end)
	Guard.Sound(player, "Unlock")
	Guard.Reveal(player, "ZoneUnlocked", { zone = zone.Id, name = zone.Name })
	return true, zone.Id
end

function EconomyService.Init()
	PlotService.OnAssigned(function(player, _plot, data)
		offline(player, data)
	end, 60)
	Players.PlayerRemoving:Connect(function(p)
		carry[p] = nil
	end)
	Guard.Bind("BuyUpgrade", buyUpgrade)
	Guard.Bind("UnlockZone", unlockZone)
	Shop.Bind()
end

function EconomyService.Start()
	task.spawn(Shop.Loop)
	local interval = Config.Economy.TipInterval
	while true do
		task.wait(interval)
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) then
				local amount = PlotService.IncomePerMin(p) * interval / 60 + (carry[p] or 0)
				local whole = math.floor(amount)
				carry[p] = amount - whole
				if whole >= 1 then
					EconomyService.VisitorTip(p, whole)
				end
			end
		end
	end
end

return EconomyService
