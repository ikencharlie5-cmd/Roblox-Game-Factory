--!strict
-- Wildworld-only pieces: mutation badges, rarity frames, happiness ring, star rating,
-- "SOON" ribbon, key-hint chip, min-44px hit areas.
local TweenService = game:GetService("TweenService")

return function(Kit: any, Style: any)
	-- Round mutation chip (24 px on cards, 36 px in Inspect). Coloured circle + 2-letter code.
	function Kit.MutationBadge(parent: Instance?, mutationId: string, size: number?, props: { [string]: any }?): Frame
		local info = Style.MutationInfo(mutationId)
		local px = size or 24
		local pal = {
			Top = info.Color:Lerp(Color3.new(1, 1, 1), 0.35),
			Bottom = info.Color,
			Dark = info.Dark,
		}
		local b = Kit.CodeBadge(parent, info.Code, pal, { Size = UDim2.fromOffset(px, px), Name = "Mut_" .. mutationId })
		if info.Shine then
			local g = b:FindFirstChildOfClass("UIGradient")
			if g then
				local tw = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				TweenService:Create(g, tw, { Rotation = 150 }):Play()
			end
		elseif info.Pulse then
			b.BackgroundTransparency = 0.2
			local tw = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			TweenService:Create(b, tw, { BackgroundTransparency = 0.5 }):Play()
		end
		Kit.Apply(b, props)
		return b
	end

	-- Re-skin an existing card frame with the rarity stroke (animated for Epic+).
	function Kit.RarityFrame(card: GuiObject, rarity: any)
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Kit.Stroke(card, Style.RarityDark[Style.NormRarity(rarity)], 3)
		end
		for _, c in (stroke :: UIStroke):GetChildren() do
			c:Destroy()
		end
		Kit.RarityFx(stroke, rarity)
	end

	-- 0-100 happiness -> palette (green > 60, amber 30-60, red < 30).
	function Kit.HappyPal(v: number): any
		if v > 60 then
			return Style.Pal.Leaf
		elseif v >= 30 then
			return Style.Pal.Sun
		end
		return Style.Pal.Red
	end

	-- Happiness ring: a round chip whose thick stroke is coloured by value, number inside.
	function Kit.HappyRing(parent: Instance?, value: number, size: number?, props: { [string]: any }?): Frame
		local px = size or 32
		local pal = Kit.HappyPal(value)
		local f = Kit.Make("Frame", {
			Name = "Happy",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(px, px),
		})
		Kit.Corner(f, 99)
		Kit.Stroke(f, pal.Bottom, math.max(3, px * 0.12))
		Kit.Title(f, tostring(math.floor(value)), pal.Dark, {
			Size = UDim2.fromScale(0.8, 0.6),
			Position = UDim2.fromScale(0.1, 0.2),
			TextSize = px * 0.5,
			StrokeThickness = 1.5,
			TextColor3 = pal.Bottom,
			ZIndex = 3,
		})
		Kit.Apply(f, props)
		f.Parent = parent
		return f
	end

	-- 0-5 star row from a 0-100 rating (20 = 1 star, half stars allowed). Code-drawn stars:
	-- rotated squares in gold; empty = stone. Returns the row and a setter.
	function Kit.Stars(parent: Instance?, props: { [string]: any }?): (Frame, (number) -> ())
		local row = Kit.Make("Frame", { Name = "Stars", BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 30) })
		local list = Kit.List(row, true, 6)
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		local fills: { Frame } = {}
		for i = 1, 5 do
			local slot = Kit.Make("Frame", {
				BackgroundColor3 = Style.Pal.Stone.Bottom,
				BorderSizePixel = 0,
				Rotation = 45,
				Size = UDim2.fromOffset(20, 20),
				LayoutOrder = i,
				ClipsDescendants = true,
			}, row)
			Kit.Corner(slot, 5)
			Kit.Stroke(slot, Style.Pal.Sun.Dark, 2.5)
			local fill = Kit.Make("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0, 1),
			}, slot)
			Kit.Gradient(fill, Style.Pal.Sun)
			fills[i] = fill
		end
		Kit.Apply(row, props)
		row.Parent = parent
		return row,
			function(rating: number)
				local stars = math.clamp(math.floor(rating / 10) / 2, 0, 5)
				for i, f in fills do
					local a = math.clamp(stars - (i - 1), 0, 1)
					Kit.Tween(f, 0.25, { Size = UDim2.fromScale(a, 1) })
				end
			end
	end

	-- Coral "SOON" ribbon across a button's top-left corner.
	function Kit.SoonRibbon(parent: Instance): Frame
		local pal = Style.Pal.Coral
		local r = Kit.Make("Frame", {
			Name = "Soon",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, 4),
			Size = UDim2.new(1, 8, 0, 22),
			Rotation = -8,
			ZIndex = 30,
		}, parent)
		Kit.Corner(r, 6)
		Kit.Gradient(r, pal)
		Kit.Stroke(r, pal.Dark, 2.5)
		Kit.Title(r, "SOON", pal.Dark, { TextSize = 16, StrokeThickness = 2, ZIndex = 31 })
		return r
	end

	-- Small dark key chip ("R") at a button's top-right. Hidden on touch devices.
	function Kit.KeyHint(parent: Instance, key: string): Frame
		local f = Kit.Make("Frame", {
			Name = "KeyHint",
			BackgroundColor3 = Style.Color.Chip,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -4),
			Size = UDim2.fromOffset(24, 22),
			Visible = not Kit.IsTouch(),
			ZIndex = 30,
		}, parent)
		Kit.Corner(f, 6)
		Kit.Label(f, key, { TextColor3 = Style.Color.White, TextSize = 16, ZIndex = 31 })
		return f
	end

	-- Make sure a tap target is at least 44x44 after scaling (guide §9).
	function Kit.MinHit(obj: GuiObject)
		local min = 44 / math.max(0.55, Kit.Scale())
		Kit.Make("UISizeConstraint", { MinSize = Vector2.new(min, min) }, obj)
	end

	-- Dark translucent chip with white text (timers, counts).
	function Kit.Chip(parent: Instance?, text: string, props: { [string]: any }?): TextLabel
		local f = Kit.Make("Frame", {
			Name = "Chip",
			BackgroundColor3 = Style.Color.Chip,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(120, 30),
		})
		Kit.Corner(f, 99)
		local l = Kit.Title(f, text, Style.Color.Chip, {
			Name = "Text",
			Size = UDim2.new(1, -12, 1, -4),
			Position = UDim2.fromOffset(6, 2),
			TextSize = 20,
			StrokeThickness = 1.5,
		})
		Kit.Apply(f, props)
		f.Parent = parent
		return l
	end
end
