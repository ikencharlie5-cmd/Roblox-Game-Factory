--!strict
-- Capture: ThrowBait -> trust meter -> CaptureStart opens a server-timed ring window ->
-- CaptureRelease is judged on the SERVER clock (±150 ms, ping-compensated). Miss = flee 15 studs,
-- 2 retries per encounter. Pity: guaranteed after 4 fails on one species. Baiting claims the wild.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Genetics = require(Shared:WaitForChild("Genetics"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local WildService = require(script.Parent:WaitForChild("WildService"))
local CreatureAI = require(script.Parent:WaitForChild("CreatureAI"))
local Journal = require(script.Parent:WaitForChild("Journal"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local CaptureService = {}

local rng = Random.new()
local C = Config.Capture

local function claimedByOther(w: any, player: Player): boolean
	return w.claimedBy ~= nil and w.claimedBy ~= player and os.clock() < w.claimUntil and w.claimedBy.Parent ~= nil
end

local function sendState(player: Player, w: any)
	Remotes.Event("CaptureState"):FireClient(player, w.id, {
		trust = math.floor(w.trust),
		attemptsLeft = w.attempts,
		claimedBy = if w.claimedBy then w.claimedBy.UserId else 0,
		needed = C.TrustNeeded,
	})
end

local function setClaim(w: any, player: Player?)
	w.claimedBy = player
	w.claimUntil = if player then os.clock() + C.ClaimSeconds else 0
	w.model:SetAttribute("ClaimedBy", if player then player.UserId else 0)
	w.model:SetAttribute("Trust", math.floor(w.trust))
end

local function throwBait(player: Player, data: any, pos: any, baitId: any)
	baitId = if baitId == nil then "Berry" else baitId
	local bait = type(baitId) == "string" and (C.Bait :: any)[baitId] or nil
	if not bait or not Guard.IsVector(pos) then
		return false, "Bad request"
	end
	local root = Guard.RootPos(player)
	if not root or (root - pos).Magnitude > C.ThrowRange then
		return Guard.Fail(player, "Too far to throw")
	end
	if (data.bait[baitId] or 0) <= 0 then
		return Guard.Fail(player, "No " .. baitId .. " bait left - buy more at the shop")
	end
	DataService.Update(player, function(d)
		d.bait[baitId] -= 1
		if baitId == "Starfruit" then
			d.boosts.starfruit = os.time() + (bait.BoostSeconds or 180)
		end
	end)
	Guard.Sound(player, "BaitThrow", { position = pos })
	Signals.Fire("Bait", player, baitId)
	-- nearest unclaimed wild in an unlocked zone
	local best, bestD = nil, C.BaitAttract
	for _, w in WildService.All() do
		local d = (WildService.Position(w) - pos).Magnitude
		if d <= bestD and not claimedByOther(w, player) and WildService.ZoneUnlocked(data, w.zone) and not w.window then
			best, bestD = w, d
		end
	end
	if not best then
		return true, nil
	end
	local w: any = best
	w.trust = math.min(100, w.trust + bait.Trust)
	setClaim(w, player)
	CreatureAI.Force(w.agent, "Eat", pos, 6)
	sendState(player, w)
	return true, w.id
end

local function greenWidth(data: any, w: any): number
	local rarity = Genetics.DisplayRarity(w.species, w.mutations)
	local g = (C.Green :: any)[rarity] or C.Green.Common
	g += Formulas.CalmNetBonus(data.upgrades.CalmNet)
	g += C.TrustBonusMax * math.clamp((w.trust - C.TrustNeeded) / (100 - C.TrustNeeded), 0, 1)
	return math.clamp(g, 0.05, 1)
end

local function miss(player: Player, w: any)
	w.window = nil
	w.attempts -= 1
	w.agent.paused = false
	DataService.Update(player, function(d)
		d.pity[w.species] = (d.pity[w.species] or 0) + 1
	end)
	local root = Guard.RootPos(player)
	local pos = WildService.Position(w)
	local dir = if root then Vector3.new(pos.X - root.X, 0, pos.Z - root.Z) else Vector3.new(1, 0, 0)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(1, 0, 0)
	CreatureAI.Force(w.agent, "Flee", pos + dir * C.FleeDistance, 3, 2.5)
	if w.attempts <= 0 then
		w.trust = 0
		w.attempts = C.Attempts
		setClaim(w, nil)
		Guard.Toast(player, "It got away... try more bait!", "error")
	else
		Guard.Toast(player, "Missed! " .. w.attempts .. " tries left", "error")
	end
	Guard.Sound(player, "CaptureFail", { position = pos })
	sendState(player, w)
end

local function captureStart(player: Player, data: any, wildId: any)
	local w: any = WildService.Get(wildId)
	if not w then
		return false, "Bad request"
	end
	if w.claimedBy ~= player then
		return Guard.Fail(player, "Throw bait first")
	end
	if w.window then
		if os.clock() - w.window.start > w.window.duration + 0.5 then
			miss(player, w) -- never released: counts as a miss
			if not WildService.Get(wildId) or w.claimedBy ~= player then
				return false, "It got away"
			end
		else
			return false, "Already capturing"
		end
	end
	local root = Guard.RootPos(player)
	if not root or (root - WildService.Position(w)).Magnitude > C.CaptureRange then
		return Guard.Fail(player, "Get closer")
	end
	if w.trust < C.TrustNeeded then
		return Guard.Fail(player, "It doesn't trust you yet - more bait!")
	end
	local ok, reason = CreatureService.CanAdd(player)
	if not ok then
		return Guard.Fail(player, reason or "No room")
	end
	local guaranteed = (data.pity[w.species] or 0) >= C.PityFails
	local g = if guaranteed then 1 else greenWidth(data, w)
	local centre = rng:NextNumber(C.GreenCentreMin, C.GreenCentreMax)
	local from = math.clamp(centre - g / 2, 0, 1)
	local to = math.clamp(centre + g / 2, 0, 1)
	w.window = { start = os.clock(), duration = C.RingSeconds, from = from, to = to }
	w.claimUntil = os.clock() + C.ClaimSeconds
	w.agent.paused = true
	CreatureAI.Go(w.agent, "Calm", WildService.Position(w))
	Guard.Sound(player, "NetCharge")
	return true,
		{
			wildId = w.id,
			serverStart = workspace:GetServerTimeNow(),
			duration = C.RingSeconds,
			greenFrom = from,
			greenTo = to,
			guaranteed = guaranteed,
		}
end

local function captureRelease(player: Player, data: any, wildId: any)
	local w: any = WildService.Get(wildId)
	if not w or w.claimedBy ~= player or not w.window then
		return false, "Bad request"
	end
	local win = w.window
	local ping = math.clamp(player:GetNetworkPing(), 0, 0.5)
	local elapsed = os.clock() - win.start - ping
	local tol = C.Tolerance
	local hitStart, hitEnd = win.from * win.duration - tol, win.to * win.duration + tol
	if elapsed < hitStart or elapsed > hitEnd then
		miss(player, w)
		return true, { success = false, attemptsLeft = w.attempts }
	end
	-- success
	w.window = nil
	local r = CreatureService.NewRecord(player, {
		species = w.species,
		genes = w.genes,
		mutations = w.mutations,
		stage = "Adult",
		source = "wild",
		seed = w.seed,
	})
	WildService.Despawn(w.id)
	DataService.Update(player, function(d)
		d.pity[w.species] = 0
		d.stats.caught += 1
		if #r.mutations > 0 then
			d.stats.mutations += 1
			d.rp += Config.RP.Mutation
		end
	end)
	local isNew = (data.journal[r.species] or 0) == 0
	local uid = CreatureService.Add(player, r)
	Guard.Reveal(player, "Capture", {
		uid = uid,
		species = r.species,
		mutations = r.mutations,
		label = Genetics.MutationLabel(r.mutations),
		rarity = Genetics.DisplayRarity(r.species, r.mutations),
		firstDiscovery = isNew,
		padId = r.padId,
	})
	Guard.Sound(player, "CaptureSuccess", { species = r.species })
	Journal.Update(player, r.species, if #r.mutations > 0 then "mutated" else nil)
	Signals.Fire("Catch", player, r)
	return true, { success = true, uid = uid, species = r.species }
end

function CaptureService.Init()
	Guard.Bind("ThrowBait", throwBait)
	Guard.Bind("CaptureStart", captureStart)
	Guard.Bind("CaptureRelease", captureRelease)
end

function CaptureService.Start()
	-- trust slowly decays; claims expire; abandoned windows count as misses
	while true do
		task.wait(1)
		for _, w in WildService.All() do
			local wa: any = w
			if wa.window and os.clock() - wa.window.start > wa.window.duration + 3 then
				local p = wa.claimedBy
				if p and DataService.Get(p) then
					miss(p, wa)
				else
					wa.window = nil
					wa.agent.paused = false
				end
			end
			if wa.trust > 0 and not wa.window then
				wa.trust = math.max(0, wa.trust - C.TrustDecayPerSecond)
			end
			if wa.claimedBy and (os.clock() > wa.claimUntil or not wa.claimedBy.Parent) and not wa.window then
				wa.trust = 0
				wa.attempts = C.Attempts
				setClaim(wa, nil)
			end
		end
	end
end


return CaptureService
