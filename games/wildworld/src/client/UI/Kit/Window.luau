--!strict
-- Toy-brick window chrome (STUDS_STYLE_GUIDE "For UI"): navy lip + shadow, white-plastic gradient
-- body (10 px corners) with a 4 px navy stroke, a category-colour header pill sticking 24 px out of
-- the top (icon + FredokaOne title) with a row of studs on its top edge, and a red tilted close button.
-- Also home of the shared stud helpers Kit.Stud / Kit.StudRow (used by Button + Card).
-- Open/close animation lives in Windows.luau.
export type WindowParts = {
	Frame: Frame,
	Body: Frame,
	Title: TextLabel,
	Header: Frame,
	Scale: UIScale,
	Close: TextButton?,
}

local BODY_RADIUS = 10

return function(Kit: any, Style: any)
	-- Toy-brick stud: circle in the palette's Top colour lightened 15 %, 2 px stroke in its Dark
	-- colour, plus a small white highlight dot (Style.Color.Stud). Centre-anchored.
	function Kit.Stud(parent: Instance?, pal: any, size: number, props: { [string]: any }?): Frame
		local p = Style.PaletteFor(pal)
		local stud = Kit.Make("Frame", {
			Name = "Stud",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = p.Top:Lerp(Color3.new(1, 1, 1), Style.StudLighten),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(size, size),
		})
		Kit.Corner(stud, 99)
		Kit.Make("UIStroke", {
			Color = p.Dark,
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, stud)
		local dot = Kit.Make("Frame", {
			Name = "Shine",
			BackgroundColor3 = Style.Color.Stud,
			BackgroundTransparency = Style.StudTransparency,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.2, 0.16),
			Size = UDim2.fromScale(0.36, 0.3),
		}, stud)
		Kit.Corner(dot, 99)
		Kit.Apply(stud, props)
		dot.ZIndex = stud.ZIndex
		stud.Parent = parent
		return stud
	end

	-- Centred row of `count` studs along the top edge of `parent`; y = centre offset from the top
	-- (0 = straddling the edge).
	function Kit.StudRow(
		parent: Instance,
		pal: any,
		count: number,
		size: number,
		gap: number,
		z: number?,
		y: number?
	): Frame
		local row = Kit.Make("Frame", {
			Name = "Studs",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, y or 0),
			Size = UDim2.fromOffset(count * size + math.max(0, count - 1) * gap + 4, size + 4),
			ZIndex = z or 5,
		}, parent)
		local list = Kit.List(row, true, gap)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		for i = 1, count do
			local st = Kit.Stud(row, pal, size, { LayoutOrder = i, ZIndex = z or 5 })
			st.AnchorPoint = Vector2.zero
		end
		return row
	end

	-- Toy-brick studs along the top edge of the header pill: as many 18 px studs (10 px gap) as fit
	-- on the straight part of the pill, max 10. Width is known up front (header = 70 % of the window,
	-- clamped 280..620), so no resize signal is needed.
	local function studRow(header: Frame, face: Frame, pal: any, windowWidth: number)
		local cfg = Style.Studs.Header
		local width = math.clamp(windowWidth * 0.7, 280, 620) - header.Size.Y.Offset
		local count = math.clamp(math.floor((width + cfg.Gap) / (cfg.Size + cfg.Gap)), 0, cfg.Max)
		if count > 0 then
			Kit.StudRow(face, pal, count, cfg.Size, cfg.Gap, 3) -- under the title row (Z 4)
		end
	end

	function Kit.Window(
		parent: Instance?,
		title: string,
		color: any,
		icon: string?,
		size: Vector2?,
		onClose: (() -> ())?
	): WindowParts
		local pal = Style.PaletteFor(color or "Teal")
		local body = Style.Pal.Body
		local sz = size or Vector2.new(820, 560)
		local frame = Kit.Make("Frame", {
			Name = "Window",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 14),
			Size = UDim2.fromOffset(sz.X, sz.Y),
			ZIndex = 5,
		})
		local scale = Kit.Make("UIScale", { Name = "Open", Scale = 1 }, frame)
		local shadow = Kit.Make("Frame", {
			Name = "Shadow",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 16),
			Size = UDim2.new(1, 0, 1, -8),
			ZIndex = 1,
		}, frame)
		Kit.Corner(shadow, BODY_RADIUS)
		local lip = Kit.Make("Frame", {
			Name = "Lip",
			BackgroundColor3 = body.Dark,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 1, -8),
			ZIndex = 2,
		}, frame)
		Kit.Corner(lip, BODY_RADIUS)
		local bodyBg = Kit.Make("Frame", {
			Name = "BodyBg",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, -8),
			ZIndex = 3,
		}, frame)
		Kit.Corner(bodyBg, BODY_RADIUS)
		Kit.Gradient(bodyBg, body)
		Kit.Stroke(bodyBg, body.Dark, 4)
		local content = Kit.Make("Frame", {
			Name = "Body",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 60),
			Size = UDim2.new(1, -44, 1, -80),
			ZIndex = 4,
		}, bodyBg)

		local header = Kit.Make("Frame", {
			Name = "Header",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -24),
			Size = UDim2.new(0.7, 0, 0, 69),
			ZIndex = 6,
		}, frame)
		Kit.Make("UISizeConstraint", { MinSize = Vector2.new(280, 0), MaxSize = Vector2.new(620, 69) }, header)
		local hface = Kit.Slab(header, pal, 99, 5, 4, false)
		studRow(header, hface, pal, sz.X)
		local row = Kit.Make("Frame", {
			Name = "Row",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 0),
			ZIndex = 4,
		}, hface)
		Kit.List(row, true, 10, true)
		if icon then
			Kit.Icon(row, icon, {
				Size = UDim2.fromOffset(44, 44),
				LayoutOrder = 1,
				Depth = true,
				DepthColor = pal.Dark,
				ZIndex = 4,
			})
		end
		local titleLabel = Kit.Title(row, title, pal.Dark, {
			Name = "Title",
			Size = UDim2.new(0, 0, 0, 50),
			AutomaticSize = Enum.AutomaticSize.X,
			TextScaled = false,
			TextSize = 36,
			TextWrapped = false,
			StrokeThickness = 3.5,
			LayoutOrder = 2,
			ZIndex = 4,
		})

		local close: TextButton? = nil
		if onClose then
			local cb = Kit.CloseButton(frame, onClose)
			cb.Position = UDim2.new(1, -10, 0, -14)
			close = cb
		end
		frame.Parent = parent
		return {
			Frame = frame,
			Body = content,
			Title = titleLabel,
			Header = header,
			Scale = scale,
			Close = close,
		}
	end
end
