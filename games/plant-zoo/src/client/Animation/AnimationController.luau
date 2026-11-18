--!strict
-- Client world animation: one RenderStepped loop drives creatures, item moments, visitors, scenery
-- sway/flicker and reward FX. Everything is local (no network, server Hitboxes never move).
-- Start from Main.client.luau. Other client code can trigger a moment on any item/creature:
--   AnimationController.Play(itemOrVisualModel, "Celebrate")  -- Pop|Bounce|Celebrate|Hop|HappyHops|Spin|Wiggle|Look|Thud
-- Server code can do the same by setting the item Model attribute "Moment" (see notes/animation.md).
local RunService = game:GetService("RunService")
local Creatures = require(script.Parent.Creatures)
local Items = require(script.Parent.Items)
local Visitors = require(script.Parent.Visitors)
local Scenery = require(script.Parent.Scenery)
local Rewards = require(script.Parent.Rewards)
local Moments = require(script.Parent.Moments)

local AnimationController = {}

local started = false
local lastWarn = 0

function AnimationController.Play(model: Model, moment: string)
	local visual = model:FindFirstChild("Visual")
	local target = if visual and visual:IsA("Model") then visual else model
	local c = Creatures.Get(target)
	if c then
		Creatures.Play(c, moment)
	end
end

AnimationController.Burst = Moments.Burst

function AnimationController.Start()
	if started then
		return
	end
	started = true
	Items.Start()
	Visitors.Start()
	Scenery.Start()
	Rewards.Start()
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
		local ok, err = pcall(function()
			Creatures.Step(now, dt, camPos)
			Items.Step(now)
			Visitors.Step(now, dt, camPos)
			Scenery.Step(now, camPos)
			Rewards.Step(now)
		end)
		if not ok and now - lastWarn > 5 then
			lastWarn = now
			warn("[Animation] " .. tostring(err))
		end
	end)
end

return AnimationController
