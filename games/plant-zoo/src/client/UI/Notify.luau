--!strict
-- Toasts (top-centre under the weather banner, max 3, slide + fade, 2.5 s), rare-discovery
-- announcements (rarity gradient + animated stroke), big centre splashes with a sunburst, and the
-- offline-earnings popup. Server text is emoji-stripped before display.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local Notify = {}

local gui: ScreenGui
local root: Frame
local stack: Frame
local announceHolder: Frame
local order = 0

local KIND_PAL: { [string]: string } = {
	error = "Red",
	success = "Leaf",
	cash = "Leaf",
	hope = "Sun",
	info = "Sky",
	weather = "Sky",
}

function Notify.Init()
	gui = Kit.Gui("SproutNotify", 20)
	root = Kit.Root(gui)
	announceHolder = Kit.Make("Frame", {
		Name = "Announce",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.fromOffset(640, 66),
	}, root)
	stack = Kit.Make("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 156),
		Size = UDim2.fromOffset(440, 220),
	}, root)
	Kit.List(stack, false, 10, true).VerticalAlignment = Enum.VerticalAlignment.Top
end

-- Defensive: never show a "None" mutation word (e.g. "NONE NONE Sproutling") or emoji.
local function clean(text: string): string
	local out = string.gsub(text, "%f[%w]None None ", "")
	out = string.gsub(out, "%f[%w]NONE ", "")
	return Kit.StripEmoji(out)
end

-- Fade every visual piece under obj (frames, text, strokes).
local function fadeOut(obj: Instance, t: number)
	for _, d in obj:GetDescendants() do
		if d:IsA("TextLabel") then
			Kit.Tween(d, t, { TextTransparency = 1 })
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
			Kit.Tween(d, t, { BackgroundTransparency = 1 })
		elseif d:IsA("UIStroke") then
			Kit.Tween(d, t, { Transparency = 1 })
		elseif d:IsA("ImageLabel") then
			Kit.Tween(d, t, { ImageTransparency = 1 })
		end
	end
end

function Notify.Toast(text: string, kind: string?)
	if not stack then
		return
	end
	text = clean(text)
	local k = kind or "info"
	-- Errors: the server (or Net.Do) already plays "Error", so no second sound here.
	if k ~= "error" and k ~= "cash" then
		Kit.Sound("Notify")
	end
	order += 1
	local pal = Style.Pal[KIND_PAL[k] or "Sky"]
	local holder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(440, 58),
		LayoutOrder = order,
	}, stack)
	local pill = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, -60),
	}, holder)
	local face = Kit.Slab(pill, pal, 99, 4, 3, true)
	Kit.Title(face, text, pal.Dark, {
		Size = UDim2.new(1, -36, 1, -8),
		Position = UDim2.fromOffset(18, 4),
		TextSize = 24,
		ZIndex = 4,
	})
	Kit.Tween(pill, 0.25, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	-- Max 3 visible: drop the oldest.
	local frames = {}
	for _, c in stack:GetChildren() do
		if c:IsA("Frame") then
			table.insert(frames, c)
		end
	end
	table.sort(frames, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #frames - 3 do
		frames[i]:Destroy()
	end
	task.delay(2.5, function()
		if holder.Parent then
			fadeOut(holder, 0.2)
			task.wait(0.22)
			holder:Destroy()
		end
	end)
end

-- Server-wide rare discovery. Rarity gradient banner; Legendary+ get an animated stroke.
function Notify.Announce(text: string, rarity: string?)
	if not announceHolder then
		return
	end
	text = clean(text)
	Kit.Sound("Announce")
	Kit.Clear(announceHolder)
	local r = Style.NormRarity(rarity or "Legendary")
	local pal = Style.RarityPalette(r)
	local banner = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, -120),
	}, announceHolder)
	local face = Kit.Slab(banner, pal, 20, 5, 4, true)
	Kit.RarityFx(face:FindFirstChildOfClass("UIStroke") :: UIStroke, r)
	Kit.Title(face, text, pal.Dark, {
		Size = UDim2.new(1, -40, 1, -8),
		Position = UDim2.fromOffset(20, 4),
		TextSize = 28,
		StrokeThickness = 3,
		ZIndex = 4,
	})
	Kit.Tween(banner, 0.4, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	task.delay(6, function()
		if banner.Parent then
			Kit.Tween(banner, 0.3, { Position = UDim2.fromOffset(0, -120) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.wait(0.3)
			banner:Destroy()
		end
	end)
end

-- Big centre text with a rotating sunburst ("Thriving!", "Released!").
function Notify.Splash(text: string, color: Color3?, seconds: number?)
	if not root then
		return
	end
	text = clean(text)
	local pal = Style.PaletteFor(color or Style.Color.Sun)
	local holder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(900, 150),
		ZIndex = 10,
	}, root)
	local burst = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		ZIndex = 1,
	}, holder)
	for i = 0, 11 do
		local ray = Kit.Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(46, 520),
			Rotation = i * 15,
			BackgroundColor3 = pal.Top,
			BackgroundTransparency = 0.55,
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
	Kit.Tween(burst, 6, { Rotation = 270 }, Enum.EasingStyle.Sine)
	local label = Kit.Title(holder, text, pal.Dark, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 72,
		TextColor3 = Style.Color.White,
		StrokeThickness = 4,
		ZIndex = 2,
	})
	Kit.Make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), pal.Top),
	}, label)
	local scale = Kit.PopIn(holder, 0, 0.35)
	task.delay(seconds or 1.6, function()
		fadeOut(holder, 0.4)
		Kit.Tween(scale, 0.4, { Scale = 1.2 })
		task.wait(0.45)
		holder:Destroy()
	end)
end

-- "While you were away" popup. Server already paid; this just shows it.
function Notify.Offline(amount: number, seconds: number, isVip: boolean)
	if not root then
		return
	end
	Kit.Sound("OfflineEarnings")
	local shade = Kit.Make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 30,
	}, root)
	Kit.Tween(shade, 0.2, { BackgroundTransparency = 0.5 })
	local function collect()
		Kit.Sound("Cash")
		shade:Destroy()
	end
	local parts = Kit.Window(shade, "While you were away", "Sun", "Cash", Vector2.new(560, 400), collect)
	local body = parts.Body
	Kit.Title(body, "+$" .. Format.Number(amount), Style.Pal.Leaf.Dark, {
		Size = UDim2.new(1, 0, 0, 84),
		TextSize = 72,
		TextColor3 = Style.Color.Cash,
		StrokeThickness = 4,
	})
	local sub = "Your zoo earned for " .. Format.Time(seconds)
	if not isVip then
		sub ..= "\nVIP keeps 100% (you got 50%)"
	end
	Kit.Body(body, sub, { Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 0, 64), TextSize = 22 })
	Kit.Button(body, "Collect!", "Leaf", collect, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(260, 70),
		TextSize = 30,
		Shine = true,
	})
	parts.Scale.Scale = 0.6
	Kit.Tween(parts.Scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

return Notify
