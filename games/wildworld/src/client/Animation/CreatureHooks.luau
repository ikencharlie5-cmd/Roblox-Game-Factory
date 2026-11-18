--!strict
-- Turns replicated creature attributes + the server's Reveal remote into animation moments.
-- Per creature (Connect):
--   State -> state pose; entering ReactToPlayer plays Happy
--   Moment = "Name" or "Name:<n>" -> plays that moment (any Poses.Duration name)
--   LastFed -> Feed, LastPet -> Pet, Trust up -> Sniff (or Happy when it jumps by 30+)
--   Mutations / Mutation / Pulse / Stage -> re-read look flags
-- Remote Reveal(kind, data): "Hatch" {uid} -> Hatch on the creature with that Uid; "Discovery"
-- {species} -> Discover on the nearest creature of that species.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreatureMoments = require(script.Parent.CreatureMoments)
local CreatureState = require(script.Parent.CreatureState)
local Fx = require(script.Parent.Fx)

type Creature = CreatureState.Creature

local CreatureHooks = {}

local pendingHatch: { [any]: number } = {}

local function play(c: Creature, name: string)
	CreatureMoments.Play(c, name, os.clock())
end

function CreatureHooks.Connect(c: Creature)
	local model = c.model
	local st = model:GetAttribute("State")
	c.state = if typeof(st) == "string" then st else "Idle"
	model:GetAttributeChangedSignal("State"):Connect(function()
		local s = model:GetAttribute("State")
		local prev = c.state
		c.state = if typeof(s) == "string" then s else "Idle"
		if c.state == "ReactToPlayer" and prev ~= "ReactToPlayer" and not c.moment then
			play(c, "Happy")
		end
	end)
	model:GetAttributeChangedSignal("Moment"):Connect(function()
		local name = CreatureMoments.Parse(model:GetAttribute("Moment"))
		if name then
			play(c, name)
		end
	end)
	model:GetAttributeChangedSignal("LastFed"):Connect(function()
		play(c, "Feed")
	end)
	model:GetAttributeChangedSignal("LastPet"):Connect(function()
		play(c, "Pet")
	end)
	local trust = model:GetAttribute("Trust")
	local lastTrust = if typeof(trust) == "number" then trust else 0
	model:GetAttributeChangedSignal("Trust"):Connect(function()
		local t = model:GetAttribute("Trust")
		local n = if typeof(t) == "number" then t else 0
		if n > lastTrust and not c.moment then
			play(c, if n - lastTrust >= 30 then "Happy" else "Sniff")
		end
		lastTrust = n
	end)
	for _, a in { "Mutations", "Mutation", "Pulse", "Stage" } do
		model:GetAttributeChangedSignal(a):Connect(function()
			CreatureState.ReadMutation(c)
		end)
	end
	model.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") or d:IsA("Light") or d:IsA("ParticleEmitter") then
			c.dirty = true
		end
	end)
	model.DescendantRemoving:Connect(function(d)
		if d:IsA("BasePart") then
			c.dirty = true
		end
	end)
	-- a Reveal("Hatch") that arrived before the model did
	local uid = model:GetAttribute("Uid")
	if uid ~= nil and pendingHatch[uid] then
		if os.clock() - pendingHatch[uid] < 5 then
			play(c, "Hatch")
		end
		pendingHatch[uid] = nil
	end
end

-- A wild creature we were catching vanished: it was captured -> bubble + sparkles where it stood.
function CreatureHooks.OnRemoved(c: Creature)
	local me = Players.LocalPlayer
	if c.model:GetAttribute("Wild") == true and c.model:GetAttribute("ClaimedBy") == me.UserId and c.dist < 150 then
		local center = c.pos + Vector3.new(0, (c.rig.top + c.rig.groundY) * 0.5, 0)
		local r = math.max(1, (c.rig.top - c.rig.groundY) * 0.7)
		Fx.Bubble(center, r * 1.2, r * 0.2, 0.6)
		Fx.Burst("Sparkle", center, 24)
	end
end

function CreatureHooks.Start(list: { Creature })
	task.spawn(function()
		local shared = ReplicatedStorage:WaitForChild("Shared")
		local ok, Remotes = pcall(require, shared:WaitForChild("Remotes") :: ModuleScript)
		if not ok then
			return
		end
		local ev = (Remotes :: any).Event("Reveal") :: RemoteEvent
		ev.OnClientEvent:Connect(function(kind: any, data: any)
			if type(data) ~= "table" then
				return
			end
			if kind == "Hatch" and data.uid ~= nil then
				for _, c in list do
					if c.model:GetAttribute("Uid") == data.uid then
						if c.moment ~= "Hatch" then
							play(c, "Hatch")
						end
						return
					end
				end
				pendingHatch[data.uid] = os.clock()
			elseif kind == "Discovery" and type(data.species) == "string" then
				local char = Players.LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if not (hrp and hrp:IsA("BasePart")) then
					return
				end
				local best: Creature? = nil
				local bestD = 60
				for _, c in list do
					local d = (c.pos - hrp.Position).Magnitude
					if c.model:GetAttribute("Species") == data.species and d < bestD then
						best, bestD = c, d
					end
				end
				if best then
					play(best, "Discover")
				end
			end
		end)
	end)
end

return CreatureHooks
