--!strict
-- Helper for CreatureService: needs loop (hunger, growth, happiness), offline catch-up and the
-- care remotes FeedCreature / PetCreature / RenameCreature / SellCreature / RefillStation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ParkService = require(script.Parent:WaitForChild("ParkService"))
local PlacementService = require(script.Parent:WaitForChild("PlacementService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local CreatureCare = {}

local CS: any = nil -- CreatureService (set in Setup, avoids a require cycle)
local live: { [Player]: { [string]: Model } } = {}
local lastFed: { [Player]: { [string]: number } } = {}
local lastPet: { [Player]: { [string]: number } } = {}
local petUntil: { [Player]: { [string]: number } } = {}
local servings: { [Player]: { [number]: number } } = {}

function CreatureCare.Setup(creatureService: any, liveTable: any)
	CS = creatureService
	live = liveTable
end

local function per<T>(t: { [Player]: T }, p: Player, default: T): T
	local v = t[p]
	if not v then
		t[p] = default
		return default
	end
	return v
end

-- Happiness = Hunger 30% + Habitat 40% + Social 15% + Enrichment 15% (+ pet bonus).
function CreatureCare.Happiness(player: Player, r: any): number
	if not r.padId then
		return r.happy
	end
	local w = Config.Needs.Weights
	local res = ParkService.PadResult(player, r.padId)
	local rating = if res then res.rating else 0
	local social = if res then res.social else 0
	local enrich = if res then res.enrichment else 0
	local h = w.Hunger * r.hunger + w.Habitat * rating + w.Social * social + w.Enrichment * enrich
	local pu = petUntil[player] and petUntil[player][r.uid]
	if pu and os.clock() < pu then
		h += Config.Needs.PetBonus
	end
	return math.clamp(h, 0, 100)
end

local function refreshModel(player: Player, r: any)
	local m = live[player] and live[player][r.uid]
	if m then
		m:SetAttribute("Hunger", math.floor(r.hunger))
		m:SetAttribute("Happy", math.floor(r.happy))
		m:SetAttribute("Stage", r.stage)
		m:SetAttribute("Nickname", r.nickname or "")
	end
end

local function growUp(player: Player, r: any)
	r.stage = "Adult"
	CS.Respawn(player, r.uid)
	Guard.Toast(player, (r.nickname or r.species) .. " grew up!", "success")
	Guard.Sound(player, "GrowUp", { species = r.species })
	Signals.Fire("GrowUp", player, r)
end

-- Offline: hunger drops at the normal rate but never below the floor (no death, no running away).
function CreatureCare.OfflineCatchUp(_player: Player, data: any)
	if (data.lastSeen or 0) <= 0 then
		return
	end
	local elapsed = math.max(0, os.time() - data.lastSeen)
	local drop = elapsed / Config.Needs.HungerTick
	for _, r in data.creatures do
		if r.hunger > Config.Needs.OfflineFloor then
			r.hunger = math.max(Config.Needs.OfflineFloor, r.hunger - drop)
		end
	end
end

-- AI finished a state (eat at bowl, drink...).
function CreatureCare.StateDone(player: Player, r: any, state: string, ctx: any)
	if state == "Eat" and ctx.foodU then
		local s = per(servings, player, {})
		local left = s[ctx.foodU] or Config.Needs.StationServings
		local auto = MonetizationService.HasPass(player, "AutoFeeder")
		if left > 0 or auto then
			r.hunger = math.min(100, r.hunger + Config.Needs.StationFeed)
			s[ctx.foodU] = if auto then Config.Needs.StationServings else left - 1
		end
	elseif state == "Drink" then
		r.hunger = math.min(100, r.hunger + Config.Needs.DrinkBonus)
	end
end

local function near(player: Player, uid: string): boolean
	local pos = CS.Position(player, uid)
	local root = Guard.RootPos(player)
	return pos ~= nil and root ~= nil and (pos - root).Magnitude <= Config.Needs.InteractRange
end

local function feed(player: Player, data: any, uid: any)
	local r = type(uid) == "string" and data.creatures[uid] or nil
	if not r then
		return false, "Bad request"
	end
	if not r.padId or not near(player, uid) then
		return Guard.Fail(player, "Get closer to feed it")
	end
	local lf = per(lastFed, player, {})
	if os.clock() - (lf[uid] or 0) < Config.Needs.FeedCooldown then
		return Guard.Fail(player, "Still munching...")
	end
	lf[uid] = os.clock()
	local grew = false
	DataService.Update(player, function(d)
		r.hunger = math.min(100, r.hunger + Config.Needs.FeedAmount)
		r.feeds += 1
		d.stats.fed += 1
		if r.stage == "Baby" and r.feeds >= Config.Growth.FeedingsToAdult then
			grew = true
		end
		r.happy = CreatureCare.Happiness(player, r)
	end)
	local m = live[player] and live[player][uid]
	if m then
		m:SetAttribute("LastFed", workspace:GetServerTimeNow())
	end
	refreshModel(player, r)
	Guard.Sound(player, "Munch", { species = r.species, position = CS.Position(player, uid) })
	Signals.Fire("Feed", player, uid)
	if grew then
		growUp(player, r)
	end
	return true, r.hunger
end

local function pet(player: Player, data: any, uid: any)
	local r = type(uid) == "string" and data.creatures[uid] or nil
	if not r then
		return false, "Bad request"
	end
	if not r.padId or not near(player, uid) then
		return Guard.Fail(player, "Get closer to pet it")
	end
	local lp = per(lastPet, player, {})
	if os.clock() - (lp[uid] or 0) < Config.Needs.PetCooldown then
		return false, "Too soon"
	end
	lp[uid] = os.clock()
	per(petUntil, player, {})[uid] = os.clock() + Config.Needs.PetBonusSeconds
	DataService.Update(player, function()
		r.happy = CreatureCare.Happiness(player, r)
	end)
	local m = live[player] and live[player][uid]
	if m then
		m:SetAttribute("LastPet", workspace:GetServerTimeNow())
	end
	refreshModel(player, r)
	Guard.Sound(player, "Pet", { species = r.species, position = CS.Position(player, uid) })
	Signals.Fire("Pet", player, uid)
	return true, r.happy
end

local function rename(player: Player, data: any, uid: any, name: any)
	local r = type(uid) == "string" and data.creatures[uid] or nil
	if not r or type(name) ~= "string" or #name > 20 then
		return false, "Bad request"
	end
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if #name == 0 then
		DataService.Update(player, function()
			r.nickname = nil
		end)
		refreshModel(player, r)
		return true, ""
	end
	local ok, filtered = pcall(function()
		return TextService:FilterStringAsync(name, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok or type(filtered) ~= "string" then
		return Guard.Fail(player, "Couldn't check that name, try again")
	end
	DataService.Update(player, function()
		r.nickname = filtered
	end)
	refreshModel(player, r)
	return true, filtered
end

local function sell(player: Player, data: any, uid: any)
	local r = type(uid) == "string" and data.creatures[uid] or nil
	if not r then
		return false, "Bad request"
	end
	local _, _, total = CS.Counts(data)
	if total <= 1 then
		return Guard.Fail(player, "You can't sell your last creature")
	end
	local value = Formulas.SellValue(r)
	CS.Remove(player, uid)
	DataService.AddCoins(player, value, true)
	Guard.Sound(player, "Sell")
	Guard.Toast(player, "Sold for " .. value .. " coins", "success")
	return true, value
end

local function refill(player: Player, data: any, itemU: any)
	if type(itemU) ~= "number" then
		return false, "Bad request"
	end
	for _, it in data.plot.items do
		local def = Items.Get(it.id)
		if it.u == itemU and def and def.Kind == "food" then
			per(servings, player, {})[itemU] = Config.Needs.StationServings
			Guard.Sound(player, "Refill")
			return true, Config.Needs.StationServings
		end
	end
	return false, "Bad request"
end

-- Servings left in a food bowl (UI can show it via GetHabitat or this attribute later).
function CreatureCare.Servings(player: Player, itemU: number): number
	local s = servings[player]
	return s and s[itemU] or Config.Needs.StationServings
end

-- AssignCreature(uid, padUid | nil): move between habitats / storage.
local function assign(player: Player, data: any, uid: any, padU: any)
	local r = if type(uid) == "string" then data.creatures[uid] else nil
	if not r then
		return false, "Bad request"
	end
	if padU == nil or padU == 0 then
		local _, storage = CS.Counts(data)
		if r.padId and storage >= Config.StorageSlots then
			return Guard.Fail(player, "Storage is full")
		end
		CS.Despawn(player, uid)
		DataService.Update(player, function()
			r.padId = nil
		end)
	else
		if type(padU) ~= "number" then
			return false, "Bad request"
		end
		local pad: any = nil
		for _, p in PlacementService.GetPads(player) do
			if p.u == padU then
				pad = p
			end
		end
		if not pad then
			return Guard.Fail(player, "That habitat doesn't exist")
		end
		if r.padId == padU then
			return true, padU
		end
		if #ParkService.CreaturesOnPad(data, padU) >= (pad.def.PadCapacity or 4) then
			return Guard.Fail(player, "That habitat is full - upgrade to a bigger pad")
		end
		local park = CS.Counts(data)
		if not r.padId and park >= Formulas.ParkSlots(data.upgrades.Capacity) then
			return Guard.Fail(player, "No park slots left - upgrade Creature Capacity")
		end
		DataService.Update(player, function()
			r.padId = padU
		end)
		CS.Respawn(player, r.uid)
	end
	Guard.Sound(player, "Assign")
	Signals.Fire("CreaturesChanged", player)
	return true, padU
end

function CreatureCare.Bind()
	Guard.Bind("AssignCreature", assign)
	Guard.Bind("FeedCreature", feed)
	Guard.Bind("PetCreature", pet)
	Guard.Bind("RenameCreature", rename)
	Guard.Bind("SellCreature", sell)
	Guard.Bind("RefillStation", refill)
	Players.PlayerRemoving:Connect(function(p)
		lastFed[p] = nil
		lastPet[p] = nil
		petUntil[p] = nil
		servings[p] = nil
	end)
end

-- Needs tick: hunger -1 / 30 s, babies grow (online), happiness refresh.
function CreatureCare.Loop()
	while true do
		task.wait(Config.Needs.HungerTick)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data and live[player] then
				local grown = {}
				DataService.Update(player, function()
					for _, r in data.creatures do
						r.hunger = math.max(0, r.hunger - 1)
						if r.stage == "Baby" then
							r.grow += Config.Needs.HungerTick
							if r.grow >= Config.Growth.BabySeconds then
								table.insert(grown, r)
							end
						end
						r.happy = CreatureCare.Happiness(player, r)
					end
				end)
				for _, r in data.creatures do
					refreshModel(player, r)
				end
				for _, r in grown do
					growUp(player, r)
				end
			end
		end
	end
end

return CreatureCare
