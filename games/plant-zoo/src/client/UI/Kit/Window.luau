--!strict
-- Window chrome (guide section 4): wood lip + shadow, cream gradient body with a 4 px wood stroke,
-- a coloured header slab sticking 24 px out of the top (icon + FredokaOne title), and a red tilted
-- close button overlapping the top-right corner. Open/close animation lives in Windows.luau.
export type WindowParts = {
	Frame: Frame,
	Body: Frame,
	Title: TextLabel,
	Header: Frame,
	Scale: UIScale,
	Close: TextButton?,
}

return function(Kit: any, Style: any)
	function Kit.Window(
		parent: Instance?,
		title: string,
		color: any,
		icon: string?,
		size: Vector2?,
		onClose: (() -> ())?
	): WindowParts
		local pal = Style.PaletteFor(color or "Leaf")
		local wood = Style.Pal.Body
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
			BackgroundColor3 = wood.Dark,
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
		Kit.Gradient(bodyBg, wood)
		Kit.Stroke(bodyBg, wood.Dark, 4)
		local content = Kit.Make("Frame", {
			Name = "Body",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 58),
			Size = UDim2.new(1, -40, 1, -78),
			ZIndex = 4,
		}, bodyBg)

		local header = Kit.Make("Frame", {
			Name = "Header",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -24),
			Size = UDim2.new(1, -40, 0, 69),
			ZIndex = 6,
		}, frame)
		local hface = Kit.Slab(header, pal, 18, 5, 4, false)
		local row = Kit.Make("Frame", {
			Name = "Row",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -90, 1, 0),
			Position = UDim2.fromOffset(45, 0),
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
			TextSize = 38,
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
