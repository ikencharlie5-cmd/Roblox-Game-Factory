--!strict
-- Breeding, eggs, incubators, hatching, Gene Scanner, starter egg.
-- Mendelian genes + mutation roll (Heirloom, habitat >= 80, Rainbow Shower). First bred egg = Golden.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local Genetics = require(Shared:WaitForChild("Genetics"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlacementService = require(script.Parent:WaitForChild("PlacementService"))
local ParkService = require(script.Parent:WaitForChild("ParkService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local Models = require(script.Parent:WaitForChild("Models"))
local Journal = require(script.Parent:WaitForChild("Journal"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local GeneticsService = {}

local rng = Random.new()
local worldEggs: { [Player]: Model } = {}

function GeneticsService.Incubators(player: Player, data: any): number
	return Formulas.Incubators(data.upgrades.Incubators, MonetizationService.HasPass(player, "ExtraIncubator"))
end

-- Builds + stores an egg. fields: species, genes, mutations, parents, gen, seconds, source.
function GeneticsService.MakeEgg(player: Player, fields: any): any
	local def = Species[fields.species]
	local now = os.time()
	local egg = {
		id = DataService.NewId(player, "e"),
		species = fields.species,
		genes = fields.genes or Genetics.Random(rng, Config.Capture.RecessiveAlleleChance),
		mutations = fields.mutations or {},
		parents = fields.parents or {},
		gen = fields.gen or 1,
		laidAt = now,
		readyAt = now + (fields.seconds or def.EggSeconds),
		source = fields.source or "breed",
	}
	DataService.Update(player, function(d)
		table.insert(d.eggs, egg)
	end)
	return egg
end

local function findEgg(data: any, eggId: any): (any, number?)
	if type(eggId) ~= "string" then
		return nil, nil
	end
	for i, e in data.eggs do
		if e.id == eggId then
			return e, i
		end
	end
	return nil, nil
end

local function breed(player: Player, data: any, uidA: any, uidB: any)
	if type(uidA) ~= "string" or type(uidB) ~= "string" or uidA == uidB then
		return false, "Bad request"
	end
	local a, b = data.creatures[uidA], data.creatures[uidB]
	if not a or not b then
		return false, "Bad request"
	end
	if a.species ~= b.species then
		return Guard.Fail(player, "Only the same species can breed (for now!)")
	end
	if a.stage ~= "Adult" or b.stage ~= "Adult" then
		return Guard.Fail(player, "Both parents must be adults")
	end
	if a.happy < Config.Breeding.MinHappy or b.happy < Config.Breeding.MinHappy then
		return Guard.Fail(player, "Both parents need happiness " .. Config.Breeding.MinHappy .. "+")
	end
	local now = os.time()
	if (a.breedReadyAt or 0) > now or (b.breedReadyAt or 0) > now then
		return Guard.Fail(player, "Parents are resting")
	end
	if #data.eggs >= GeneticsService.Incubators(player, data) then
		return Guard.Fail(player, "All incubators are busy")
	end
	local cost = Formulas.BreedCost(a.species)
	if not DataService.TrySpend(player, cost) then
		return Guard.Fail(player, "Breeding costs " .. cost .. " coins")
	end
	local padA = a.padId and ParkService.PadResult(player, a.padId)
	local mods = {
		habitat80 = padA ~= nil and padA.rating >= Config.MutationRules.HabitatBonusRating,
		rainbow = Guard.State():GetAttribute("Weather") == "Rainbow Shower",
	}
	local force = if not data.flags.goldenGiven then "Golden" else nil
	local muts = Genetics.RollMutations(rng, a.mutations, b.mutations, mods, force)
	local egg = GeneticsService.MakeEgg(player, {
		species = a.species,
		genes = Genetics.Cross(rng, a.genes, b.genes),
		mutations = muts,
		parents = { uidA, uidB },
		gen = math.max(a.gen, b.gen) + 1,
		source = "breed",
	})
	DataService.Update(player, function(d)
		d.flags.goldenGiven = true
		a.bred = (a.bred or 0) + 1
		b.bred = (b.bred or 0) + 1
		a.breedReadyAt = now + Config.Breeding.ParentCooldown
		b.breedReadyAt = now + Config.Breeding.ParentCooldown
		d.rp += Config.RP.Breed
		d.stats.bred += 1
	end)
	Journal.Update(player, a.species, "bred")
	Guard.Sound(player, "EggLaid")
	Guard.Toast(player, "A new egg! It hatches in " .. math.floor((egg.readyAt - now) / 60) .. " min", "success")
	Signals.Fire("Breed", player, egg)
	return true, egg.id
end

local function removeWorldEgg(player: Player)
	local m = worldEggs[player]
	if m then
		m:Destroy()
		worldEggs[player] = nil
	end
end

function GeneticsService.Hatch(player: Player, eggId: any): (boolean, any)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading..."
	end
	local egg, i = findEgg(data, eggId)
	if not egg or not i then
		return false, "Bad request"
	end
	if os.time() < egg.readyAt then
		return Guard.Fail(player, "Not ready yet")
	end
	local ok, reason = CreatureService.CanAdd(player)
	if not ok then
		return Guard.Fail(player, reason or "No room")
	end
	local starter = egg.source == "starter"
	local r = CreatureService.NewRecord(player, {
		species = egg.species,
		genes = egg.genes,
		mutations = egg.mutations,
		parents = egg.parents,
		gen = egg.gen,
		stage = if starter and Config.StarterHatchesAdult then "Adult" else "Baby",
		source = egg.source,
	})
	DataService.Update(player, function(d)
		table.remove(d.eggs, i)
		d.stats.hatched += 1
		if #r.mutations > 0 then
			d.stats.mutations += 1
			d.rp += Config.RP.Mutation
		end
	end)
	if starter then
		removeWorldEgg(player)
	end
	local uid = CreatureService.Add(player, r)
	local isNew = (data.journal[r.species] or 0) == 0
	Guard.Reveal(player, "Hatch", {
		uid = uid,
		species = r.species,
		mutations = r.mutations,
		label = Genetics.MutationLabel(r.mutations),
		rarity = Genetics.DisplayRarity(r.species, r.mutations),
		firstDiscovery = isNew,
		starter = starter,
		padId = r.padId,
	})
	Guard.Sound(player, "EggCrack", { species = r.species })
	Journal.Update(player, r.species, if #r.mutations > 0 then "mutated" else nil)
	Signals.Fire("Hatch", player, r)
	return true, uid
end

local function scan(player: Player, data: any, uid: any)
	local r = type(uid) == "string" and data.creatures[uid] or nil
	if not r then
		return false, "Bad request"
	end
	if r.scanned or (r.bred or 0) > 0 then
		return true, r.genes
	end
	if not DataService.TrySpendRP(player, Config.GeneScanRP) then
		return Guard.Fail(player, "Gene Scanner needs " .. Config.GeneScanRP .. " RP")
	end
	DataService.Update(player, function()
		r.scanned = true
	end)
	Guard.Sound(player, "Scan")
	return true, r.genes
end

-- Starter egg: created once, shown in the world on the starter pad with a "Hatch!" prompt.
local function setupStarter(player: Player, plot: number, data: any)
	if not data.flags.starterEgg then
		local species = Config.StarterSpecies[rng:NextInteger(1, #Config.StarterSpecies)]
		GeneticsService.MakeEgg(player, { species = species, seconds = 0, source = "starter" })
		DataService.Update(player, function(d)
			d.flags.starterEgg = true
		end)
	end
	local egg: any = nil
	for _, e in data.eggs do
		if e.source == "starter" then
			egg = e
		end
	end
	if not egg then
		return
	end
	local pads = PlacementService.GetPads(player)
	local cf = if pads[1] then pads[1].cf else PlotService.ToWorld(plot, 0, 0)
	local m = Models.Egg(egg.species, egg.mutations, Models.Seed(egg.id))
	m:SetAttribute("EggId", egg.id)
	m:SetAttribute("OwnerId", player.UserId)
	m:SetAttribute("Starter", true)
	m:PivotTo(cf * CFrame.new(-4, 0, -4))
	m.Parent = PlotService.Folder(plot)
	worldEggs[player] = m
	local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		(prompt :: ProximityPrompt).Triggered:Connect(function(who)
			if who == player then
				GeneticsService.Hatch(player, egg.id)
			end
		end)
	end
end

function GeneticsService.Init()
	PlotService.OnAssigned(setupStarter, 50)
	PlotService.OnFreed(function(player)
		worldEggs[player] = nil -- folder is cleared by PlotService
	end)
	Players.PlayerRemoving:Connect(function(p)
		worldEggs[p] = nil
	end)
	Guard.Bind("Breed", breed)
	Guard.Bind("HatchEgg", function(player, _data, eggId)
		return GeneticsService.Hatch(player, eggId)
	end)
	Guard.Bind("ScanGenes", scan)
end

return GeneticsService
