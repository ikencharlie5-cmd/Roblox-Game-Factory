--!strict
-- Field-journal window chrome (guide §1): teal-ink lip + shadow, parchment gradient body with a
-- 4 px deep-teal stroke and a dashed "stitch" border 8 px inside, a category-colour header pill
-- sticking 24 px out of the top (icon + FredokaOne title), and a red tilted close button.
-- Open/close animation lives in Windows.luau.
export type WindowParts = {
	Frame: Frame,
	Body: Frame,
	Title: TextLabel,
	Header: Frame,
	Scale: UIScale,
	Close: TextButton?,
}

return function(Kit: any, Style: any)
	-- Dashed stitch: short segments along each edge (cheap, no image asset).
	local function stitch(parent: GuiObject)
		local holder = Kit.Make("Frame", {
			Name = "Stitch",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 1, -16),
			ZIndex = 3,
		}, parent)
		local function edge(horizontal: boolean, pos: UDim2, anchor: Vector2)
			local line = Kit.Make("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = anchor,
				Position = pos,
				Size = if horizontal then UDim2.new(1, -24, 0, 2) else UDim2.new(0, 2, 1, -24),
				ZIndex = 3,
			}, holder)
			local list = Kit.List(line, horizontal, 7)
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.VerticalAlignment = Enum.VerticalAlignment.Center
			for i = 1, 60 do
				Kit.Make("Frame", {
					BackgroundColor3 = Style.Color.Stitch,
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Size = if horizontal then UDim2.fromOffset(9, 2) else UDim2.fromOffset(2, 9),
					LayoutOrder = i,
					ZIndex = 3,
				}, line)
			end
			line.ClipsDescendants = true
		end
		edge(true, UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5, 0))
		edge(true, UDim2.new(0.5, 0, 1, 0), Vector2.new(0.5, 1))
		edge(false, UDim2.new(0, 0, 0.5, 0), Vector2.new(0, 0.5))
		edge(false, UDim2.new(1, 0, 0.5, 0), Vector2.new(1, 0.5))
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
		Kit.Corner(shadow, 22)
		local lip = Kit.Make("Frame", {
			Name = "Lip",
			BackgroundColor3 = body.Dark,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 1, -8),
			ZIndex = 2,
		}, frame)
		Kit.Corner(lip, 22)
		local bodyBg = Kit.Make("Frame", {
			Name = "BodyBg",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, -8),
			ZIndex = 3,
		}, frame)
		Kit.Corner(bodyBg, 22)
		Kit.Gradient(bodyBg, body)
		Kit.Stroke(bodyBg, body.Dark, 4)
		stitch(bodyBg)
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
