--!strict
-- Static pieces: 3D slab (lip + face), panels, rarity cards, progress bars, icons with
-- code-drawn fallbacks and red notification badges. Wildworld extras live in Extras.luau.
local TweenService = game:GetService("TweenService")

return function(Kit: any, Style: any)
	-- Shadow + dark lip + white gradient face with a thick same-hue stroke and gloss.
	-- Returns the face (put content in it), the lip and the shadow.
	function Kit.Slab(
		root: GuiObject,
		pal: any,
		radius: number?,
		lip: number?,
		stroke: number?,
		shadow: boolean?
	): (Frame, Frame, Frame?)
		local r = radius or 14
		local l = lip or 6
		local sh: Frame? = nil
		if shadow ~= false then
			sh = Kit.Make("Frame", {
				Name = "Shadow",
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, l + 4),
				Size = UDim2.new(1, 0, 1, -l),
				ZIndex = 1,
			}, root)
			Kit.Corner(sh :: Frame, r)
		end
		local base = Kit.Make("Frame", {
			Name = "Lip",
			BackgroundColor3 = pal.Dark,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, l),
			Size = UDim2.new(1, 0, 1, -l),
			ZIndex = 2,
		}, root)
		Kit.Corner(base, r)
		local face = Kit.Make("Frame", {
			Name = "Face",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, -l),
			ZIndex = 3,
		}, root)
		Kit.Corner(face, r)
		Kit.Gradient(face, pal)
		Kit.Stroke(face, pal.Dark, stroke or 3.5)
		Kit.Highlight(face, r, 1)
		return face, base, sh
	end

	-- Inset panel on cream windows (white card look). A dark colour gives a translucent dark chip.
	function Kit.Panel(parent: Instance?, color: Color3?, props: { [string]: any }?): Frame
		local f = Kit.Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 })
		Kit.Corner(f, 14)
		if color and (color == Style.Color.Dark or color == Style.Color.Chip) then
			f.BackgroundColor3 = Style.Color.Chip
			f.BackgroundTransparency = 0.35
			Kit.Stroke(f, Style.Color.Chip, 3)
		else
			local pal = if color == nil
					or color == Style.Color.Panel
					or color == Style.Color.Cream
				then Style.Pal.Card
				else Style.PaletteFor(color)
			if pal == Style.Pal.Card or pal == Style.Pal.Body then
				Kit.Gradient(f, Style.Pal.Card)
				Kit.Stroke(f, Style.Pal.Body.Dark, 3)
			else
				Kit.Gradient(f, { Top = Color3.new(1, 1, 1), Bottom = pal.Top, Dark = pal.Dark })
				Kit.Stroke(f, pal.Dark, 3)
			end
		end
		Kit.Apply(f, props)
		f.Parent = parent
		return f
	end

	-- Item card: white, rarity-dark stroke (animated for Legendary+), rarity band + word at the bottom.
	function Kit.Card(parent: Instance?, rarity: string?, props: { [string]: any }?): Frame
		local p = props or {}
		local c = Kit.Make("Frame", { Name = "Card", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 })
		Kit.Corner(c, 14)
		Kit.Gradient(c, Style.Pal.Card)
		local stroke = Kit.Stroke(c, Style.Pal.Body.Dark, 3)
		if rarity then
			Kit.RarityFx(stroke, rarity)
			if p.Band ~= false then
				local r = Style.NormRarity(rarity)
				local band = Kit.Make("Frame", {
					Name = "Band",
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 28),
					ZIndex = 2,
				}, c)
				Kit.Corner(band, 12)
				Kit.Gradient(band, Style.RarityPalette(r))
				Kit.Title(band, string.upper(r), Style.RarityDark[r], {
					Size = UDim2.new(1, -8, 1, -4),
					Position = UDim2.fromOffset(4, 2),
					TextSize = 17,
					StrokeThickness = 2,
					ZIndex = 3,
				})
			end
		end
		Kit.Apply(c, p, { Band = true })
		Kit.Stagger(c)
		c.Parent = parent
		return c
	end

	-- Progress bar: dark inset track + glossy gradient fill. Returns (track, setAlpha).
	function Kit.Progress(parent: Instance?, color: any, props: { [string]: any }?): (Frame, (number) -> ())
		local pal = Style.PaletteFor(color)
		local back = Kit.Make("Frame", {
			Name = "Progress",
			BackgroundColor3 = Style.Color.Chip,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		})
		Kit.Corner(back, 99)
		Kit.Stroke(back, Style.Color.Chip, 2.5)
		local fill = Kit.Make("Frame", {
			Name = "Fill",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0, 1),
		}, back)
		Kit.Corner(fill, 99)
		Kit.Gradient(fill, pal)
		Kit.Highlight(fill, 8, 2).Position = UDim2.fromOffset(4, 2)
		Kit.Apply(back, props)
		back.Parent = parent
		return back,
			function(alpha: number)
				local a = math.clamp(alpha ~= alpha and 0 or alpha, 0, 1)
				fill.Visible = a > 0.005
				Kit.Tween(fill, 0.3, { Size = UDim2.fromScale(a, 1) })
			end
	end

	-- Round badge with a white glyph (placeholder icon, biome/weather chips).
	function Kit.CodeBadge(parent: Instance?, glyph: string, pal: any, props: { [string]: any }?): Frame
		local f = Kit.Make("Frame", {
			Name = "Badge",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(44, 44),
		})
		Kit.Make("UIAspectRatioConstraint", { AspectRatio = 1 }, f)
		Kit.Corner(f, 99)
		Kit.Gradient(f, pal)
		Kit.Stroke(f, pal.Dark, 2.5)
		Kit.Highlight(f, 99, 1).Size = UDim2.new(1, -12, 0.4, 0)
		Kit.Title(f, glyph, pal.Dark, {
			Size = UDim2.fromScale(0.82, 0.7),
			Position = UDim2.fromScale(0.09, 0.15),
			TextSize = 60,
			StrokeThickness = 2.5,
			ZIndex = 3,
		})
		Kit.Apply(f, props)
		f.Parent = parent
		return f
	end

	local ICON_SKIP = { Depth = true, DepthColor = true }

	-- Icon by name (Style.Icons), raw "rbxassetid://" id, or a code-drawn badge when not uploaded yet.
	-- Props extras: Depth = true adds the darker duplicate 3 px below (images only), DepthColor.
	function Kit.Icon(parent: Instance?, icon: string, props: { [string]: any }?): GuiObject
		local p = props or {}
		local id = if string.sub(icon, 1, 13) == "rbxassetid://" then icon else Style.Icons[icon]
		if id then
			local holder = Kit.Make("Frame", { Name = "Icon", BackgroundTransparency = 1 })
			if p.Depth then
				Kit.Make("ImageLabel", {
					Name = "Depth",
					BackgroundTransparency = 1,
					Image = id,
					ImageColor3 = p.DepthColor or Style.Color.Dark,
					ImageTransparency = 0.4,
					ScaleType = Enum.ScaleType.Fit,
					Position = UDim2.fromOffset(0, 3),
					Size = UDim2.fromScale(1, 1),
				}, holder)
			end
			Kit.Make("ImageLabel", {
				Name = "Image",
				BackgroundTransparency = 1,
				Image = id,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, holder)
			Kit.Apply(holder, p, ICON_SKIP)
			holder.Parent = parent
			return holder
		end
		local fb = Style.IconFallback[icon]
		local glyph = if fb then fb.Glyph else string.upper(string.sub(string.gsub(icon, "[^%w]", ""), 1, 1))
		local pal = Style.Pal[if fb then fb.Pal else "Stone"]
		local holder = Kit.Make("Frame", { Name = "Icon", BackgroundTransparency = 1 })
		Kit.Apply(holder, p, ICON_SKIP)
		Kit.CodeBadge(holder, if glyph == "" then "?" else glyph, pal, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.86, 0.86),
		})
		holder.Parent = parent
		return holder
	end

	-- Red "!" (or number) badge at the top-right corner of a button. Bobs while visible.
	function Kit.Badge(parent: Instance, text: string?): Frame
		local pal = Style.Pal.Red
		local b = Kit.Make("Frame", {
			Name = "NotifyBadge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 30,
		}, parent)
		Kit.Corner(b, 99)
		Kit.Gradient(b, pal)
		Kit.Stroke(b, pal.Dark, 2.5)
		Kit.Title(b, text or "!", pal.Dark, { TextSize = 20, StrokeThickness = 2, ZIndex = 31 })
		local s = Kit.Make("UIScale", { Scale = 1 }, b)
		local info = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(s, info, { Scale = 1.15 }):Play()
		return b
	end
end
