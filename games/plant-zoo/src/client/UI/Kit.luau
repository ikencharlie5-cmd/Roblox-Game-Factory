--!strict
-- UI building blocks. Every button gets a sound, a press tween and a 44px minimum touch size.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Style = require(script.Parent:WaitForChild("Style"))

local Kit = {}

local soundController: any = nil
function Kit.Sound(name: string)
	if soundController == nil then
		local ok, mod = pcall(function()
			return require(script.Parent.Parent:WaitForChild("Audio"):WaitForChild("SoundController")) :: any
		end)
		soundController = if ok and type(mod) == "table" then mod else false
	end
	if soundController and soundController.Play then
		pcall(soundController.Play, name)
	end
end

function Kit.Make(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Kit.Gui(name: string, order: number): ScreenGui
	local player = Players.LocalPlayer :: Player
	local gui = Kit.Make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	})
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

function Kit.Darker(c: Color3, f: number?): Color3
	local k = 1 - (f or 0.25)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

function Kit.Corner(parent: Instance, px: number?)
	Kit.Make("UICorner", { CornerRadius = UDim.new(0, px or 12) }, parent)
end

function Kit.Stroke(parent: Instance, color: Color3, thickness: number?)
	Kit.Make("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function Kit.Padding(parent: Instance, px: number)
	local u = UDim.new(0, px)
	Kit.Make("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u }, parent)
end

function Kit.List(parent: Instance, horizontal: boolean, gap: number?, center: boolean?): UIListLayout
	return Kit.Make("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = if center then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
		VerticalAlignment = if center then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	}, parent)
end

function Kit.Grid(parent: Instance, cell: UDim2, gap: number?): UIGridLayout
	return Kit.Make("UIGridLayout", {
		CellSize = cell,
		CellPadding = UDim2.new(0, gap or 8, 0, gap or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent)
end

function Kit.Tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?): Tween
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

function Kit.Label(parent: Instance?, text: string, props: { [string]: any }?): TextLabel
	local l = Kit.Make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextScaled = true,
		Font = Style.Font,
		TextColor3 = Style.Color.Ink,
		RichText = true,
	})
	Kit.Make("UITextSizeConstraint", { MaxTextSize = 30, MinTextSize = 8 }, l)
	for k, v in props or {} do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

-- Panel = rounded frame with a soft outline.
function Kit.Panel(parent: Instance?, color: Color3?, props: { [string]: any }?): Frame
	local f = Kit.Make("Frame", { BackgroundColor3 = color or Style.Color.Panel, BorderSizePixel = 0 })
	Kit.Corner(f, 12)
	Kit.Stroke(f, Kit.Darker(color or Style.Color.Panel, 0.2), 2)
	for k, v in props or {} do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

function Kit.Button(
	parent: Instance?,
	text: string,
	color: Color3?,
	onClick: (() -> ())?,
	props: { [string]: any }?
): TextButton
	local base = color or Style.Color.Leaf
	local b = Kit.Make("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = base,
		BorderSizePixel = 0,
		Text = text,
		TextScaled = true,
		RichText = true,
		Font = Style.Font,
		TextColor3 = Style.Color.White,
		Size = UDim2.fromScale(1, 1),
	})
	Kit.Corner(b, 12)
	Kit.Stroke(b, Kit.Darker(base, 0.3), 2)
	Kit.Make("UITextSizeConstraint", { MaxTextSize = 26, MinTextSize = 8 }, b)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(44, 44) }, b)
	Kit.Make("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 3),
	}, b)
	local textStroke = Kit.Make("UIStroke", { Thickness = 1.5, Color = Kit.Darker(base, 0.5) }, b)
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	local scale = Kit.Make("UIScale", { Scale = 1 }, b)
	for k, v in props or {} do
		(b :: any)[k] = v
	end

	b.MouseEnter:Connect(function()
		Kit.Tween(scale, 0.12, { Scale = 1.05 })
	end)
	b.MouseLeave:Connect(function()
		Kit.Tween(scale, 0.12, { Scale = 1 })
	end)
	local busy = false
	b.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		Kit.Sound("Click")
		scale.Scale = 0.88
		Kit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		if onClick then
			local ok, err = pcall(onClick)
			if not ok then
				warn("[UI] button error:", err)
			end
		end
		busy = false
	end)
	b.Parent = parent
	return b
end

-- Recolor a Kit.Button (keeps its outline in sync).
function Kit.SetButtonColor(b: TextButton, color: Color3)
	b.BackgroundColor3 = color
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = Kit.Darker(color, 0.3)
	end
end

function Kit.Progress(parent: Instance?, color: Color3, props: { [string]: any }?): (Frame, (number) -> ())
	local back = Kit.Make("Frame", {
		BackgroundColor3 = Style.Color.Dark,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	})
	Kit.Corner(back, 8)
	local fill =
		Kit.Make("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, back)
	Kit.Corner(fill, 8)
	for k, v in props or {} do
		(back :: any)[k] = v
	end
	back.Parent = parent
	return back,
		function(alpha: number)
			Kit.Tween(fill, 0.3, { Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1) })
		end
end

-- Remove everything except layout/constraint objects.
function Kit.Clear(container: Instance)
	for _, c in container:GetChildren() do
		if not c:IsA("UIBase") then
			c:Destroy()
		end
	end
end

function Kit.Scroll(parent: Instance?, props: { [string]: any }?): ScrollingFrame
	local s = Kit.Make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Style.Color.LeafDark,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	for k, v in props or {} do
		(s :: any)[k] = v
	end
	s.Parent = parent
	return s
end

-- Tabs row: returns a function to select a tab by name.
function Kit.Tabs(parent: Instance, names: { string }, onSelect: (string) -> ()): (string) -> ()
	local row = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
	Kit.List(row, true, 6)
	local buttons: { [string]: TextButton } = {}
	local function choose(name: string)
		for n, b in buttons do
			Kit.SetButtonColor(b, if n == name then Style.Color.Sun else Style.Color.Grey)
		end
		onSelect(name)
	end
	for i, n in names do
		buttons[n] = Kit.Button(row, n, Style.Color.Grey, function()
			choose(n)
		end, { Size = UDim2.new(1 / #names, -6, 1, 0), LayoutOrder = i })
	end
	return choose
end

-- Cheap change signature for "re-render only if this changed" checks.
function Kit.Sig(value: any): string
	local ok, s = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	return if ok then s else tostring(os.clock())
end

return Kit
