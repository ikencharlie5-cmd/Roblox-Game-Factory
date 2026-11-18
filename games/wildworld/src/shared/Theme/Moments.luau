--!strict
-- Big-moment VFX (ART_STYLE_GUIDE §6). Each call spawns temporary parts in workspace.WorldFX, tweens
-- them and cleans up. Works on the server (everyone sees it) or the client (local-only, smoother).
-- Camera effects (FOV punch, screen flash) are UI/Animation's job; these are the in-world pieces.
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Effects = require(script.Parent.Effects)

local Moments = {}

local function fxFolder(): Folder
	return Kit.Folder(Workspace, "WorldFX")
end

local function tween(i: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	TweenService:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function burstAt(pos: Vector3, e: ParticleEmitter, count: number, life: number)
	local holder = Kit.Block(fxFolder(), Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), P.Cream)
	holder.Transparency = 1
	e.Parent = holder
	e:Emit(count)
	Debris:AddItem(holder, life)
end

-- Egg hatch: two shell halves fly apart + puff in the mutation colour (nil = cream).
function Moments.Hatch(pos: Vector3, shellColor: Color3, flashColor: Color3?)
	local folder = fxFolder()
	for _, side in { -1, 1 } do
		local half = Kit.Blob(folder, Vector3.new(1.4, 1.8, 2.8), CFrame.new(pos + Vector3.new(side * 0.7, 1, 0)), shellColor)
		tween(half, 0.6, {
			CFrame = CFrame.new(pos + Vector3.new(side * 3, 0.4, 0)) * CFrame.Angles(0, 0, side * 1.6),
			Transparency = 1,
		})
		Debris:AddItem(half, 0.7)
	end
	burstAt(pos + Vector3.new(0, 1, 0), Effects.Puff(flashColor or P.Cream), 14, 1)
	if flashColor then
		burstAt(pos + Vector3.new(0, 1, 0), Effects.Sparkle(flashColor, 0), 25, 1.5)
	end
end

-- Capture bubble around a creature. Returns a handle: :Success() pops it, :Fail() bursts it.
function Moments.CaptureBubble(pos: Vector3, size: number)
	local folder = fxFolder()
	local b = Kit.Ball(folder, size * 2.2, CFrame.new(pos), P.Mutation.Crystal, Enum.Material.ForceField)
	b.Name = "CaptureBubble"
	tween(b, 0.5, { Size = Vector3.one * size * 1.3 }, Enum.EasingStyle.Back)
	local handle = {}
	function handle.Success()
		tween(b, 0.15, { Size = Vector3.one * size * 0.2, Transparency = 1 })
		burstAt(pos, Effects.Sparkle(P.Discovery, 0), 30, 1.5)
		Debris:AddItem(b, 0.2)
	end
	function handle.Fail()
		tween(b, 0.12, { Size = Vector3.one * size * 2.6, Transparency = 1 })
		burstAt(pos, Effects.Puff(Color3.fromHex("#BFEFFF")), 12, 1)
		Debris:AddItem(b, 0.2)
	end
	Debris:AddItem(b, 15)
	return handle
end

-- First discovery: a rarity-coloured beam column rising and fading + confetti.
function Moments.DiscoveryBeam(pos: Vector3, color: Color3)
	local folder = fxFolder()
	local col = Kit.Cyl(folder, 2, 5, CFrame.new(pos + Vector3.new(0, 1, 0)), color, Enum.Material.Neon)
	col.Transparency = 0.4
	tween(col, 1.4, {
		Size = Vector3.new(80, 4, 4),
		CFrame = CFrame.new(pos + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
	})
	Debris:AddItem(col, 1.5)
	burstAt(pos + Vector3.new(0, 2, 0), Effects.Confetti(), 40, 2)
end

-- Rating-up sparkle ring across a habitat pad (pad centre + pad size in studs).
function Moments.RatingUp(center: Vector3, padSize: number)
	local folder = fxFolder()
	local ring = Kit.Cyl(folder, 0.2, 4, CFrame.new(center + Vector3.new(0, 0.6, 0)), P.Discovery, Enum.Material.Neon)
	ring.Transparency = 0.3
	tween(ring, 0.8, { Size = Vector3.new(0.2, padSize, padSize), Transparency = 1 })
	Debris:AddItem(ring, 0.9)
	burstAt(center + Vector3.new(0, 2, 0), Effects.Sparkle(P.Discovery, 0), 20, 1.5)
end

-- Coin fountain above a visitor or creature.
function Moments.Coins(pos: Vector3, amount: number?)
	burstAt(pos, Effects.CoinBurst(), math.clamp(amount or 10, 4, 30), 1.5)
end

-- One-shot hearts above a creature (pet / fed).
function Moments.Hearts(pos: Vector3)
	burstAt(pos, Effects.Hearts(), 3, 1.5)
end

return Moments
