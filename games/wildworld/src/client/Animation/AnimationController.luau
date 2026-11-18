--!strict
-- Client world animation. ONE RenderStepped loop drives creatures, eggs, visitors, scenery and FX,
-- then applies every part CFrame with a single workspace:BulkMoveTo (Batch). No network.
-- Start from Main.client.luau:  require(script.Animation.AnimationController).Start()
--
-- Hooks for other branches (see notes/animation.md):
--   Server: set creature Model attribute Moment = "Happy:<n>" (any change plays; suffix lets repeats fire).
--   Client: AnimationController.Play(creatureModel, "Celebrate")
--           AnimationController.CoinFountain(pos, count, target?)
--           AnimationController.Burst("Sparkle" | "Dust", pos, count?, color?)
--           AnimationController.Float(text, pos, color?, size?)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Batch = require(script.Parent.Batch)
local Creatures = require(script.Parent.Creatures)
local Eggs = require(script.Parent.Eggs)
local Fx = require(script.Parent.Fx)
local Scenery = require(script.Parent.Scenery)
local Visitors = require(script.Parent.Visitors)

local AnimationController = {}

local started = false
local lastWarn = 0

function AnimationController.Play(model: Model, moment: string): boolean
	return Creatures.Play(model, moment)
end

function AnimationController.CoinFountain(pos: Vector3, count: number?, target: Vector3?)
	Fx.Coins(pos, count or 8, target)
end

AnimationController.Burst = Fx.Burst
AnimationController.Float = Fx.Float
AnimationController.Tip = Visitors.Tip

local function isNight(): boolean
	local flag = Lighting:GetAttribute("IsNight")
	if typeof(flag) == "boolean" then
		return flag
	end
	local t = Lighting.ClockTime
	return t < 6 or t >= 18.5
end

function AnimationController.Start()
	if started then
		return
	end
	started = true
	Fx.Init()
	Creatures.Start()
	Eggs.Start()
	Visitors.Start()
	Scenery.Start()
	local last = os.clock()
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local camPos = cam.CFrame.Position
		local night = isNight()
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local playerPos = if hrp and hrp:IsA("BasePart") then hrp.Position else nil
		local ok, err = pcall(function()
			Creatures.Step(now, dt, cam, night)
			Eggs.Step(now, camPos)
			Visitors.Step(now, dt, camPos)
			Scenery.Step(now, camPos, night)
			Fx.Step(now, dt, playerPos)
		end)
		Batch.Flush()
		if not ok and now - lastWarn > 5 then
			lastWarn = now
			warn("[Animation] " .. tostring(err))
		end
	end)
end

return AnimationController
