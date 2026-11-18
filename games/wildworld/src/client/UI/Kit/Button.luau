--!strict
-- Premium buttons (guide section 3): white face + UIGradient + 3.5 px same-hue dark stroke, dark lip
-- under it, soft shadow, gloss strip, white FredokaOne label with a dark outline, press squash
-- (face sinks onto the lip), hover grow, Back-Out release, click sound. Wide text buttons get 2
-- toy-brick studs on the top edge.
--   Kit.Button(parent, text, color, onClick, props) -> TextButton (the root; setting .Text updates the label)
--   props extras: Icon (name or id), IconSize, TextSize, Lip, Radius, Shine, Pulse
local TweenService = game:GetService("TweenService")

return function(Kit: any, Style: any)
	local SKIP = {
		Icon = true,
		IconSize = true,
		TextSize = true,
		Lip = true,
		Radius = true,
		Shine = true,
		Pulse = true,
	}

	local function quick(inst: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
		TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
			:Play()
	end

	-- Parts live in a centre-anchored "Holder" so the press/hover UIScale squashes around the centre
	-- whatever AnchorPoint the caller uses.
	local function holderOf(b: Instance): Instance
		return b:FindFirstChild("Holder", true) or b
	end
	Kit.ButtonHolder = holderOf

	function Kit.ButtonFace(b: Instance): Frame
		return (holderOf(b):FindFirstChild("Face") or b) :: any
	end

	function Kit.ButtonPress(b: Instance): UIScale
		return holderOf(b):FindFirstChild("Press") :: UIScale
	end

	function Kit.Button(
		parent: Instance?,
		text: string,
		color: any,
		onClick: (() -> ())?,
		props: { [string]: any }?
	): TextButton
		local p = props or {}
		local pal = Style.PaletteFor(color or "Leaf")
		local lip = p.Lip or 5
		local radius = p.Radius or 14
		local root = Kit.Make("TextButton", {
			Name = "Button",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text,
			TextTransparency = 1,
			TextSize = 1,
			Size = UDim2.fromScale(1, 1),
		})
		local function centred(name: string, parentObj: Instance): Frame
			return Kit.Make("Frame", {
				Name = name,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
			}, parentObj)
		end
		-- Optional idle pulse wraps the holder so it also scales around the centre.
		local holder = centred("Holder", if p.Pulse then centred("PulseWrap", root) else root)
		local scale = Kit.Make("UIScale", { Name = "Press", Scale = 1 }, holder)
		local face = Kit.Slab(holder, pal, radius, lip, 3.5, true)
		local label = Kit.Title(face, text, pal.Dark, {
			Name = "Label",
			Size = UDim2.new(1, -16, 1, -6),
			Position = UDim2.fromOffset(8, 3),
			TextSize = p.TextSize or 26,
			StrokeThickness = 2.5,
			ZIndex = 5,
		})
		local icon: GuiObject? = nil
		if p.Icon then
			icon = Kit.Icon(face, p.Icon, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(36, 36),
				ZIndex = 4,
				Depth = true,
				DepthColor = pal.Dark,
			})
		end
		-- Toy-brick studs: 2 small studs on the top edge of wide text buttons (never icon buttons).
		local studs: { Frame }? = nil
		local function setStuds(show: boolean)
			if show and not studs then
				local sz = Style.Studs.Button.Size
				-- Use the face's current colours (SetButtonColor may have recoloured it since).
				local cur = pal
				local g = face:FindFirstChildOfClass("UIGradient")
				local fs = face:FindFirstChildOfClass("UIStroke")
				if g and fs then
					cur = { Top = g.Color.Keypoints[1].Value, Bottom = pal.Bottom, Dark = fs.Color }
				end
				studs = {}
				for _, x in { 0.3, 0.7 } do
					table.insert(
						studs :: { Frame },
						Kit.Stud(face, cur, sz, { Position = UDim2.new(x, 0, 0, 0), ZIndex = 4 })
					)
				end
			end
			if studs then
				for _, st in studs do
					st.Visible = show
				end
			end
		end
		local function layout()
			local k = math.max(0.01, Kit.Scale() * scale.Scale)
			local h = face.AbsoluteSize.Y / k
			local hasText = root.Text ~= ""
			label.Visible = hasText
			setStuds(hasText and face.AbsoluteSize.X / k >= Style.Studs.Button.MinWidth)
			if icon then
				local size = math.clamp(h * 0.74, 16, p.IconSize or 44)
				local ic = icon :: GuiObject
				ic.Size = UDim2.fromOffset(size, size)
				if hasText then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 8, 0.5, 0)
					label.Position = UDim2.fromOffset(size + 12, 3)
					label.Size = UDim2.new(1, -(size + 20), 1, -6)
				else
					ic.AnchorPoint = Vector2.new(0.5, 0.5)
					ic.Position = UDim2.fromScale(0.5, 0.5)
				end
			end
		end
		root:GetPropertyChangedSignal("Text"):Connect(function()
			label.Text = root.Text
			layout()
		end)
		face:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
		Kit.Apply(root, p, SKIP)
		layout()

		local function rest(): number
			local r = root:GetAttribute("RestScale")
			return if type(r) == "number" then r else 1
		end
		local function up()
			quick(scale, 0.25, { Scale = rest() }, Enum.EasingStyle.Back)
			quick(face, 0.12, { Position = UDim2.fromOffset(0, 0) })
		end
		root.MouseEnter:Connect(function()
			quick(scale, 0.12, { Scale = rest() * 1.06 })
			if icon then
				quick(icon :: GuiObject, 0.12, { Rotation = 8 })
			end
		end)
		root.MouseLeave:Connect(function()
			quick(scale, 0.12, { Scale = rest() })
			quick(face, 0.08, { Position = UDim2.fromOffset(0, 0) })
			if icon then
				quick(icon :: GuiObject, 0.12, { Rotation = 0 })
			end
		end)
		root.MouseButton1Down:Connect(function()
			quick(scale, 0.07, { Scale = rest() * 0.92 })
			quick(face, 0.07, { Position = UDim2.fromOffset(0, lip) })
		end)
		root.MouseButton1Up:Connect(up)
		local busy = false
		root.Activated:Connect(function()
			up()
			if busy then
				return
			end
			busy = true
			Kit.Sound("Click")
			if onClick then
				local ok, err = pcall(onClick)
				if not ok then
					warn("[UI] button error:", err)
				end
			end
			busy = false
		end)
		if p.Shine then
			Kit.Shine(face, radius)
		end
		if p.Pulse then
			Kit.Pulse(holder.Parent :: GuiObject)
		end
		root.Parent = parent
		return root
	end

	-- Recolour a Kit.Button: palette, palette name or Color3. Style.Color.Grey = disabled look.
	-- A palette with a Text colour (e.g. white inactive tabs) switches the label to that ink.
	function Kit.SetButtonColor(b: Instance, color: any)
		local pal = Style.PaletteFor(color)
		local face = holderOf(b):FindFirstChild("Face")
		if not face then
			return
		end
		local g = face:FindFirstChildOfClass("UIGradient")
		if g then
			Kit.SetGradient(g, pal)
		end
		local s = face:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = pal.Dark
		end
		local lip = holderOf(b):FindFirstChild("Lip")
		if lip and lip:IsA("Frame") then
			lip.BackgroundColor3 = pal.Dark
		end
		for _, st in face:GetChildren() do
			if st.Name == "Stud" and st:IsA("Frame") then
				st.BackgroundColor3 = pal.Top:Lerp(Color3.new(1, 1, 1), Style.StudLighten)
				local ss = st:FindFirstChildOfClass("UIStroke")
				if ss then
					ss.Color = pal.Dark
				end
			end
		end
		local label = face:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.TextColor3 = pal.Text or Color3.new(1, 1, 1)
			local ts = label:FindFirstChildOfClass("UIStroke")
			if ts then
				ts.Color = if pal.Text then Color3.new(1, 1, 1) else pal.Dark
			end
		end
	end

	-- Square HUD button (84 px): icon does the talking, label straddles the bottom edge.
	function Kit.IconButton(
		parent: Instance?,
		icon: string,
		text: string,
		color: any,
		onClick: (() -> ())?,
		props: { [string]: any }?
	): TextButton
		local p = table.clone(props or {})
		p.Radius = p.Radius or 18
		p.Lip = p.Lip or 6
		p.Size = p.Size or UDim2.fromOffset(84, 84)
		local b = Kit.Button(parent, "", color, onClick, p)
		local pal = Style.PaletteFor(color)
		Kit.Icon(Kit.ButtonFace(b), icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.44),
			Size = UDim2.fromScale(0.72, 0.72),
			Depth = true,
			DepthColor = pal.Dark,
			ZIndex = 4,
		})
		if text ~= "" then
			Kit.Title(holderOf(b), text, Style.Color.Dark, {
				Name = "Caption",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(1, 16, 0, 22),
				TextSize = 19,
				StrokeThickness = 2.5,
				ZIndex = 10,
			})
		end
		return b
	end

	-- Red tilted close button overlapping a window's top-right corner.
	function Kit.CloseButton(parent: Instance, onClick: () -> ()): TextButton
		local b = Kit.Button(parent, "X", Style.Pal.Red, onClick, {
			Name = "Close",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(56, 58),
			Rotation = -6,
			TextSize = 34,
			ZIndex = 20,
		})
		local label = Kit.ButtonFace(b):FindFirstChild("Label") :: TextLabel
		label.Size = UDim2.fromScale(1, 1)
		label.Position = UDim2.fromOffset(0, 0)
		return b
	end

	-- Pill tabs: active = full colour, inactive = white with coloured ink and scale 0.92.
	-- Returns choose(name). Optional color picks the category palette (default Sun).
	function Kit.Tabs(parent: Instance, names: { string }, onSelect: (string) -> (), color: any?): (string) -> ()
		local pal = Style.PaletteFor(color or "Sun")
		local off = { Top = Color3.new(1, 1, 1), Bottom = Style.Pal.Body.Bottom, Dark = pal.Dark, Text = pal.Dark }
		local row =
			Kit.Make("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
		Kit.List(row, true, 8)
		local buttons: { [string]: TextButton } = {}
		local current: string? = nil
		local function choose(name: string)
			for n, b in buttons do
				local on = n == name
				Kit.SetButtonColor(b, if on then pal else off)
				b:SetAttribute("RestScale", if on then 1 else 0.92)
				Kit.Tween(Kit.ButtonPress(b), 0.15, { Scale = if on then 1 else 0.92 })
			end
			if current ~= name then
				Kit.BeginStagger(0.4)
			end
			current = name
			onSelect(name)
		end
		for i, n in names do
			buttons[n] = Kit.Button(row, n, off, function()
				choose(n)
			end, { Size = UDim2.new(1 / #names, -8, 1, 0), LayoutOrder = i, Radius = 99, TextSize = 24, Lip = 4 })
			Kit.SetButtonColor(buttons[n], off)
		end
		return choose
	end
end
