--!strict
-- Hatch / capture / discovery reveal (guide §6): full-screen dim, egg shakes 3x, white flash,
-- creature pops in (0 -> 1.1 -> 1, Back Out) over a rarity-coloured sunburst, mutation badges
-- drop in one by one, "NEW DISCOVERY!" ribbon, then Name it / Inspect / Close. Reveals queue.
-- Fed by the server's Reveal(kind, data) event; shows exactly what the server rolled.
local RunService = game:GetService("RunService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Derived = require(script.Parent:WaitForChild("Derived"))

local Reveal = {}

local gui: ScreenGui
local root: Frame
local queue: { { any } } = {}
local busy = false
local inspectFn: ((any) -> ())? = nil
local closedSignal = Instance.new("BindableEvent")
Reveal.Closed = closedSignal.Event -- (kind)

local TITLES = {
	hatch = "It hatched!",
	capture = "Caught!",
	discovery = "New discovery!",
	golden = "GOLDEN!",
}

function Reveal.SetInspect(fn: (any) -> ())
	inspectFn = fn
end

function Reveal.Mount()
	gui = Kit.Gui("WildReveal", 30)
	gui.ScreenInsets = Enum.ScreenInsets.None
	root = Kit.Root(gui)
end

function Reveal.IsBusy(): boolean
	return busy
end

local function sunburst(parent: Instance, color: Color3): Frame
	local burst = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(10, 10),
	}, parent)
	for i = 0, 11 do
		local ray = Kit.Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(70, 900),
			Rotation = i * 15,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
		}, burst)
		Kit.Make("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, ray)
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		if not burst.Parent then
			conn:Disconnect()
			return
		end
		burst.Rotation += 45 * dt
	end)
	return burst
end

local function show(kind: string, data: { [string]: any })
	busy = true
	local species = tostring(data.species or "?")
	local muts = Derived.Muts(data)
	local rarity = Style.NormRarity(data.rarity or Derived.Rarity(species))
	local isGolden = table.find(muts, "Golden") ~= nil
	local pal = if isGolden then Style.Pal.Sun else Style.RarityPalette(rarity)
	local shade = Kit.Make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, root)
	Kit.Tween(shade, 0.25, { BackgroundTransparency = 0.35 })
	local stage = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, shade)

	-- 1) Egg shake (hatch only)
	if kind == "hatch" or kind == "golden" then
		Kit.Sound("Egg_Wobble")
		local egg = Kit.Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(150, 190),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, stage)
		Kit.Corner(egg, 99)
		Kit.Gradient(egg, pal)
		Kit.Stroke(egg, pal.Dark, 5)
		Kit.PopIn(egg, 0.3, 0.3)
		task.wait(0.35)
		for _ = 1, 3 do
			Kit.Tween(egg, 0.08, { Rotation = 8 })
			task.wait(0.08)
			Kit.Tween(egg, 0.08, { Rotation = -8 })
			task.wait(0.08)
		end
		task.wait(0.1)
		local flash = Kit.Make("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 50,
		}, stage)
		Kit.Sound("Egg_Crack")
		egg:Destroy()
		Kit.Tween(flash, 0.15, { BackgroundTransparency = 1 })
		task.delay(0.2, function()
			flash:Destroy()
		end)
	end

	-- 2) Creature pop over the sunburst + rarity stinger
	sunburst(stage, pal.Top)
	Kit.SoundFn("PlayReveal", rarity, muts)
	local view = Kit.CreatureView(stage, species, {
		Genes = data.genes,
		Mutations = muts,
		Stage = data.stage or "Baby",
		Rarity = rarity,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(340, 340),
		ZIndex = 5,
	})
	local s = Kit.Make("UIScale", { Scale = 0 }, view)
	Kit.Tween(s, 0.25, { Scale = 1.1 }, Enum.EasingStyle.Back)
	task.delay(0.25, function()
		Kit.Tween(s, 0.1, { Scale = 1 })
	end)
	local title = (TITLES :: any)[kind] or "Wow!"
	if isGolden then
		title = "GOLDEN " .. species .. "!"
	end
	Kit.Title(stage, title, pal.Dark, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromOffset(900, 90),
		TextSize = 72,
		StrokeThickness = 5,
		ZIndex = 6,
	})
	Kit.Title(stage, string.upper(rarity) .. "  " .. species, pal.Dark, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.66),
		Size = UDim2.fromOffset(700, 50),
		TextSize = 40,
		TextColor3 = pal.Top,
		ZIndex = 6,
	})

	-- 3) Mutation badges drop in with a stagger
	local mrow = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.73),
		Size = UDim2.fromOffset(600, 50),
		ZIndex = 6,
	}, stage)
	Kit.List(mrow, true, 12, true)
	for i, m in muts do
		task.wait(0.12)
		local b = Kit.MutationBadge(mrow, m, 48, { LayoutOrder = i, ZIndex = 7 })
		Kit.PopIn(b, 0, 0.3)
	end
	if data.firstDiscovery or data.isNew then
		local ribbon = Kit.Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.2),
			Size = UDim2.fromOffset(380, 54),
			Rotation = -4,
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 8,
		}, stage)
		Kit.Corner(ribbon, 12)
		Kit.Gradient(ribbon, Style.Pal.Coral)
		Kit.Stroke(ribbon, Style.Pal.Coral.Dark, 3.5)
		Kit.Title(ribbon, "NEW DISCOVERY!", Style.Pal.Coral.Dark, { TextSize = 32, ZIndex = 9 })
		Kit.PopIn(ribbon, 0, 0.35)
	end

	-- 4) Buttons
	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.85),
		Size = UDim2.fromOffset(640, 74),
		ZIndex = 6,
	}, stage)
	Kit.List(row, true, 16, true)
	local done = false
	local function close()
		if done then
			return
		end
		done = true
		Kit.Tween(shade, 0.2, { BackgroundTransparency = 1 })
		stage:Destroy()
		task.delay(0.2, function()
			shade:Destroy()
		end)
		closedSignal:Fire(kind)
		busy = false
		Reveal.Next()
	end
	if data.uid ~= nil and inspectFn then
		Kit.Button(row, "Inspect", "Teal", function()
			close()
			if inspectFn then
				(inspectFn :: (any) -> ())(data.uid)
			end
		end, { Size = UDim2.fromOffset(200, 70), LayoutOrder = 1 })
	end
	Kit.Button(row, "Awesome!", "Leaf", close, { Size = UDim2.fromOffset(240, 70), LayoutOrder = 2, Shine = true })
end

function Reveal.Next()
	if busy or #queue == 0 then
		return
	end
	local item = table.remove(queue, 1) :: { any }
	task.spawn(show, item[1], item[2])
end

function Reveal.Show(kind: string, data: any)
	if type(data) ~= "table" then
		return
	end
	table.insert(queue, { string.lower(kind), data })
	Reveal.Next()
end

return Reveal
