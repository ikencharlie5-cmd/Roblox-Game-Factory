--!strict
-- Coins from visitors (income paid as tips every 10 s), offline earnings (50%, cap 2 h),
-- Park Level XP, BuyUpgrade, UnlockZone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlacementService = require(script.Parent:WaitForChild("PlacementService"))
local ParkService = require(script.Parent:WaitForChild("ParkService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
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
		for _, pad in PlacementService.GetPads(player) do
			if #ParkService.CreaturesOnPad(data, pad.u) > 0 then
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

function EconomyService.AddXP(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	local gained: { number } = {}
	DataService.Update(player, function(d)
		d.xp += amount
		while d.xp >= Formulas.LevelXP(d.level) do
			d.xp -= Formulas.LevelXP(d.level)
			d.level += 1
			table.insert(gained, d.level)
		end
	end)
	for _, lvl in gained do
		local unlocks = {}
		for _, def in Items.List() do
			if def.Level == lvl and not def.Pass and not def.Starter and not def.ShopRare then
				table.insert(unlocks, def.Name)
			end
		end
		for _, z in Config.Zones do
			if z.Level == lvl then
				table.insert(unlocks, z.Name .. " (forest area)")
			end
		end
		Guard.Reveal(player, "LevelUp", { level = lvl, unlocks = unlocks })
		Guard.Sound(player, "LevelUp")
		Signals.Fire("LevelUp", player, lvl)
	end
	player:SetAttribute("Level", data.level)
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
	local coins = math.floor(ParkService.IncomePerMin(player) * secs / 60 * Config.Economy.OfflineRate)
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
	Signals.On("Hatch", function(p)
		task.defer(EconomyService.AddXP, p, Config.XP.Hatch)
	end)
	Signals.On("Catch", function(p)
		task.defer(EconomyService.AddXP, p, Config.XP.Catch)
	end)
	Signals.On("Breed", function(p)
		task.defer(EconomyService.AddXP, p, Config.XP.Breed)
	end)
	Signals.On("Place", function(p)
		task.defer(EconomyService.AddXP, p, Config.XP.Place)
	end)
	Signals.On("QuestDone", function(p)
		task.defer(EconomyService.AddXP, p, Config.XP.Quest)
	end)
	Players.PlayerRemoving:Connect(function(p)
		carry[p] = nil
	end)
	Guard.Bind("BuyUpgrade", buyUpgrade)
	Guard.Bind("UnlockZone", unlockZone)
end

function EconomyService.Start()
	local interval = Config.Economy.TipInterval
	while true do
		task.wait(interval)
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) then
				local amount = ParkService.IncomePerMin(p) * interval / 60 + (carry[p] or 0)
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
