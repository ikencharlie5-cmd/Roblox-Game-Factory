--!strict
-- Client-only creature voices: idle calls every 12-30 s per creature near the camera, plus
-- Call(model, kind) for Happy / Eat / Alert moments. Owned by Audio.
-- Contract: creature models tagged `Creature` with Attributes `Species` (string), optional
-- `Mutations` (comma string, e.g. "Golden,Crystal"), `Stage` ("Baby" | "Adult"), `State` (AI state).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local RANGE = 60
local MAX_VOICES = 6
local IDLE_MIN, IDLE_MAX = 12, 30

local CreatureVoices = {}

local SC: any = nil
local active = 0
local nextCall: { [Instance]: number } = {}

local CALL_PITCH = { Idle = 1, Happy = 1.12, Eat = 1, Alert = 1.2, Sleep = 0.85 }

local function anchorOf(model: Instance): BasePart?
	if model:IsA("Model") then
		return (model :: Model).PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	end
	return if model:IsA("BasePart") then model :: BasePart else nil
end

local function mutationsOf(model: Instance): { string }
	local list = {}
	local m = model:GetAttribute("Mutations")
	if type(m) == "string" then
		for word in string.gmatch(m, "[^,%s]+") do
			table.insert(list, word)
		end
	end
	return list
end

-- Play a call on a creature. kind: "Idle" | "Happy" | "Eat" | "Alert" | "Sleep".
function CreatureVoices.Call(model: Instance, kind: string?)
	if not SC or active >= MAX_VOICES then
		return
	end
	local part = anchorOf(model)
	local species = model:GetAttribute("Species")
	local voice = if type(species) == "string" then SoundsModule.Voices[species] else nil
	if not part or not voice then
		return
	end
	local k = kind or "Idle"
	local pitch = voice.Pitch * ((CALL_PITCH :: any)[k] or 1)
	if model:GetAttribute("Stage") == "Baby" then
		pitch *= 1.3
	end
	local bank = if k == "Eat" then "Voice_Munch" else voice.Bank
	local s = SC.PlayAt(bank, part, pitch)
	if s then
		active += 1
		s.Destroying:Once(function()
			active -= 1
		end)
	end
	for _, mut in mutationsOf(model) do
		local layer = SoundsModule.VoiceLayer[mut]
		if layer then
			SC.PlayAt(layer, part)
		end
	end
end

function CreatureVoices.Start(controller: any)
	SC = controller
	CollectionService:GetInstanceRemovedSignal("Creature"):Connect(function(inst)
		nextCall[inst] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local cam = workspace.CurrentCamera
			if cam then
				local camPos = cam.CFrame.Position
				local now = os.clock()
				for _, model in CollectionService:GetTagged("Creature") do
					local part = anchorOf(model)
					if part then
						local close = (part.Position - camPos).Magnitude <= RANGE
						local due = nextCall[model]
						if not due then
							nextCall[model] = now + math.random(IDLE_MIN, IDLE_MAX)
						elseif close and now >= due then
							nextCall[model] = now + math.random(IDLE_MIN, IDLE_MAX)
							local state = model:GetAttribute("State")
							CreatureVoices.Call(model, if state == "Sleep" then "Sleep" else "Idle")
						end
					end
				end
			end
		end
	end)
end

return CreatureVoices
