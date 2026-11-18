--!strict
-- Gradients, gloss, shine sweep, pulse, rarity stroke animation, staggered pop-ins, floating text.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

return function(Kit: any, Style: any)
	-- Light top -> dark bottom. Parent background must be WHITE (UIGradient multiplies).
	function Kit.Gradient(parent: Instance, pal: any, rotation: number?): UIGradient
		local mid = pal.Top:Lerp(pal.Bottom, 0.5)
		return Kit.Make("UIGradient", {
			Rotation = rotation or 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, pal.Top),
				ColorSequenceKeypoint.new(0.5, mid),
				ColorSequenceKeypoint.new(1, pal.Bottom),
			}),
		}, parent)
	end

	function Kit.SetGradient(g: UIGradient, pal: any)
		local mid = pal.Top:Lerp(pal.Bottom, 0.5)
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, pal.Top),
			ColorSequenceKeypoint.new(0.5, mid),
			ColorSequenceKeypoint.new(1, pal.Bottom),
		})
	end

	-- Glossy strip on the top 42% of a face.
	function Kit.Highlight(face: Instance, radius: number?, z: number?): Frame
		local hl = Kit.Make("Frame", {
			Name = "Highlight",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.new(1, -12, 0.42, 0),
			ZIndex = z or 2,
		}, face)
		Kit.Corner(hl, math.max(4, (radius or 14) - 4))
		Kit.Make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.2, 1) }, hl)
		return hl
	end

	-- Shine sweep for featured buttons (keep to 1-2 on screen). Stops when the face is destroyed.
	function Kit.Shine(face: GuiObject, radius: number?)
		local shine = Kit.Make("Frame", {
			Name = "Shine",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 8,
		}, face)
		Kit.Corner(shine, radius or 14)
		local g = Kit.Make("UIGradient", {
			Rotation = 20,
			Offset = Vector2.new(-1, 0),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 1),
				NumberSequenceKeypoint.new(0.5, 0.35),
				NumberSequenceKeypoint.new(0.55, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, shine)
		task.spawn(function()
			while shine.Parent do
				g.Offset = Vector2.new(-1, 0)
				Kit.Tween(g, 0.7, { Offset = Vector2.new(1, 0) })
				task.wait(3.2)
			end
		end)
	end

	-- Idle pulse 1 -> 1.06 -> 1 (1.2 s, Sine InOut, looping) on an own UIScale.
	function Kit.Pulse(obj: GuiObject, amount: number?): UIScale
		local s = Kit.Make("UIScale", { Name = "Pulse", Scale = 1 }, obj)
		local info = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(s, info, { Scale = amount or 1.06 }):Play()
		return s
	end

	-- Staggered pop-in for cards: active for a short time after a window opens / tab switches.
	Kit.StaggerUntil = 0
	local staggerIndex = 0
	function Kit.BeginStagger(seconds: number?)
		Kit.StaggerUntil = os.clock() + (seconds or 0.5)
		staggerIndex = 0
	end
	function Kit.Stagger(obj: GuiObject)
		if os.clock() > Kit.StaggerUntil then
			return
		end
		staggerIndex += 1
		local s = Kit.Make("UIScale", { Name = "Pop", Scale = 0.8 }, obj)
		task.delay(math.min(staggerIndex * 0.03, 0.4), function()
			Kit.Tween(s, 0.22, { Scale = 1 })
		end)
	end

	-- UIScale 0 -> 1 with Back Out (popups, reward cards).
	function Kit.PopIn(obj: GuiObject, from: number?, time: number?): UIScale
		local s = obj:FindFirstChild("PopIn") :: UIScale?
		if not s then
			s = Kit.Make("UIScale", { Name = "PopIn" }, obj)
		end
		local sc = s :: UIScale
		sc.Scale = from or 0.6
		Kit.Tween(sc, time or 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		return sc
	end

	-- "+1.2K" floating up 40 px and fading (0.6 s).
	function Kit.Float(parent: Instance, text: string, pos: UDim2, color: Color3?)
		local l = Kit.Title(parent, text, Style.Color.Dark, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos,
			Size = UDim2.fromOffset(200, 34),
			TextSize = 28,
			TextColor3 = color or Style.Color.Cash,
			ZIndex = 20,
		})
		local stroke = l:FindFirstChildOfClass("UIStroke") :: UIStroke
		Kit.Tween(l, 0.6, { Position = pos - UDim2.fromOffset(0, 40), TextTransparency = 1 })
		Kit.Tween(stroke, 0.6, { Transparency = 1 })
		task.delay(0.65, function()
			l:Destroy()
		end)
	end

	-- Rarity strokes: Legendary+ get an animated gradient on the UIStroke (one shared loop).
	local animated: { [UIGradient]: string } = setmetatable({}, { __mode = "k" }) :: any
	local function rainbow(): ColorSequence
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.85, 1)))
		end
		return ColorSequence.new(keys)
	end

	function Kit.RarityFx(stroke: UIStroke, rarity: any)
		local r = Style.NormRarity(rarity)
		local idx = Style.RarityIndex(r)
		stroke.Color = Color3.new(1, 1, 1)
		local seq: ColorSequence
		if r == "Secret" then
			seq = rainbow()
		elseif r == "Mythical" then
			seq = ColorSequence.new(Style.Rarity.Mythical, Style.Rarity.Epic)
		elseif r == "Legendary" then
			seq = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Style.RarityDark.Legendary),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFE36B")),
				ColorSequenceKeypoint.new(1, Style.RarityDark.Legendary),
			})
		elseif r == "Epic" then
			seq = ColorSequence.new(Style.Rarity.Epic, Style.RarityDark.Epic)
		else
			stroke.Color = Style.RarityDark[r]
			return
		end
		local g = Kit.Make("UIGradient", { Color = seq, Rotation = 45 }, stroke)
		if idx >= 5 then
			animated[g] = r
		end
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		local t = os.clock()
		for g, r in animated do
			if g.Parent then
				if r == "Mythical" then
					g.Offset = Vector2.new(math.sin(t * 1.5) * 0.5, 0)
				else
					g.Rotation = (t * 120) % 360 -- Legendary/Secret: spin once every 3 s
				end
			end
		end
	end)
end
