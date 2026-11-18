--!strict
-- UI building blocks (see research/UI_STYLE_GUIDE.md). Core helpers live here; the premium
-- pieces are installed from the child modules: Button, Window, Parts, Fx, View.
-- Everything is designed in px at a 1920x1080 reference: Kit.Gui adds a "Root" frame with one
-- UIScale (viewport height / 1080), so strokes, corners and text scale together.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Style = require(script.Parent:WaitForChild("Style"))

local Kit: any = {}
Kit.Style = Style

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

-- Props: normal Instance properties. Unknown keys are ignored (with pcall) so helpers can share tables.
function Kit.Apply(inst: Instance, props: { [string]: any }?, skip: { [string]: boolean }?)
	for k, v in props or {} do
		if not (skip and skip[k]) then
			local ok = pcall(function()
				(inst :: any)[k] = v
			end)
			if not ok then
				warn("[UI] bad prop", k, "on", inst.ClassName)
			end
		end
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

-- Reference scale: viewport height / 1080, clamped so phones stay tappable and 4K stays sane.
function Kit.Scale(): number
	local cam = workspace.CurrentCamera
	local h = if cam then cam.ViewportSize.Y else 1080
	return math.clamp(h / 1080, 0.55, 1.25)
end

local resized = Instance.new("BindableEvent")
Kit.Resized = resized.Event

function Kit.Gui(name: string, order: number): ScreenGui
	local player = Players.LocalPlayer :: Player
	local gui = Kit.Make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		IgnoreGuiInset = false,
	})
	local root = Kit.Make("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, gui)
	local scale = Kit.Make("UIScale", { Scale = 1 }, root)
	local function fit()
		local s = Kit.Scale()
		scale.Scale = s
		root.Size = UDim2.fromScale(1 / s, 1 / s)
		resized:Fire()
	end
	local camConn: RBXScriptConnection? = nil
	local function hookCamera()
		if camConn then
			camConn:Disconnect()
		end
		local cam = workspace.CurrentCamera
		if cam then
			camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		end
		fit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		resized:Fire()
	end)
	hookCamera()
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

-- The scaled root frame of a Kit.Gui. Parent HUD/windows here, sized in 1080p px.
function Kit.Root(gui: ScreenGui): Frame
	return (gui:FindFirstChild("Root") or gui) :: any
end

-- Size of the usable (safe-inset) screen in reference px.
function Kit.Virtual(gui: ScreenGui): Vector2
	return gui.AbsoluteSize / Kit.Scale()
end

-- Screen (absolute) position -> reference px inside Kit.Root(gui).
function Kit.ToRoot(gui: ScreenGui, abs: Vector2): Vector2
	return (abs - gui.AbsolutePosition) / Kit.Scale()
end

function Kit.IsTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Kit.Darker(c: Color3, f: number?): Color3
	local k = 1 - (f or 0.25)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

function Kit.Corner(parent: Instance, px: number?): UICorner
	return Kit.Make("UICorner", { CornerRadius = if px and px >= 99 then UDim.new(1, 0) else UDim.new(0, px or 14) }, parent)
end

-- Border stroke (panels/buttons). Thinnest allowed is 2.5.
function Kit.Stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	return Kit.Make("UIStroke", {
		Color = color,
		Thickness = math.max(2.5, thickness or 3),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, parent)
end

-- Text outline (Contextual UIStroke, never the legacy TextStroke).
function Kit.TextStroke(label: Instance, color: Color3, thickness: number?): UIStroke
	return Kit.Make("UIStroke", {
		Color = color,
		Thickness = thickness or 2.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, label)
end

function Kit.Padding(parent: Instance, px: number, top: number?)
	local u = UDim.new(0, px)
	Kit.Make(
		"UIPadding",
		{ PaddingTop = UDim.new(0, top or px), PaddingBottom = u, PaddingLeft = u, PaddingRight = u },
		parent
	)
end

function Kit.List(parent: Instance, horizontal: boolean, gap: number?, center: boolean?): UIListLayout
	return Kit.Make("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = if center then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
		VerticalAlignment = if center then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	}, parent)
end

function Kit.Grid(parent: Instance, cell: UDim2, gap: number?): UIGridLayout
	return Kit.Make("UIGridLayout", {
		CellSize = cell,
		CellPadding = UDim2.new(0, gap or 12, 0, gap or 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, parent)
end

-- No Linear easing for UI: default Quad Out.
function Kit.Tween(
	inst: Instance,
	time: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local LABEL_SKIP = { Stroke = true, StrokeThickness = true, TextSize = true, MinTextSize = true }

-- Label: FredokaOne, ink on cards. Props extras: TextSize (max px at 1080p), Stroke (Color3 -> outline),
-- StrokeThickness. Text shrinks to fit (TextScaled + UITextSizeConstraint) but never grows past TextSize.
function Kit.Label(parent: Instance?, text: string, props: { [string]: any }?): TextLabel
	local p = props or {}
	local l = Kit.Make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextScaled = true,
		TextWrapped = true,
		Font = Style.Font,
		TextColor3 = Style.Color.Ink,
		RichText = true,
	})
	Kit.Make("UITextSizeConstraint", { MaxTextSize = p.TextSize or 28, MinTextSize = p.MinTextSize or 9 }, l)
	Kit.Apply(l, p, LABEL_SKIP)
	if p.Stroke then
		Kit.TextStroke(l, p.Stroke, p.StrokeThickness)
	end
	l.Parent = parent
	return l
end

-- White FredokaOne with a dark outline (HUD numbers, text on colour).
function Kit.Title(parent: Instance?, text: string, dark: Color3, props: { [string]: any }?): TextLabel
	local p = table.clone(props or {})
	p.TextColor3 = p.TextColor3 or Style.Color.White
	p.Stroke = p.Stroke or dark
	p.StrokeThickness = p.StrokeThickness or 3
	return Kit.Label(parent, text, p)
end

-- Body text (BuilderSansExtraBold, ink, no stroke).
function Kit.Body(parent: Instance?, text: string, props: { [string]: any }?): TextLabel
	local p = table.clone(props or {})
	p.Font = Style.FontBody
	p.TextColor3 = p.TextColor3 or Style.Color.InkSoft
	p.TextSize = p.TextSize or 20
	return Kit.Label(parent, text, p)
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
		ScrollBarImageColor3 = Style.Pal.Body.Dark,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	})
	Kit.Apply(s, props)
	s.Parent = parent
	return s
end

-- Cheap change signature for "re-render only if this changed" checks.
function Kit.Sig(value: any): string
	local ok, s = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	return if ok then s else tostring(os.clock())
end

-- Strip emoji / pictographs from server text (they render per-device and look cheap).
function Kit.StripEmoji(text: string): string
	local out = string.gsub(text, "[\240-\244][\128-\191][\128-\191][\128-\191]", "")
	out = string.gsub(out, "\226[\152-\158][\128-\191]", "") -- U+2600-27BF symbols/dingbats
	out = string.gsub(out, "\226\173[\144-\149]", "") -- stars/circles U+2B50-2B55
	out = string.gsub(out, "\239\184\143", "") -- variation selector 16
	out = string.gsub(out, "\226\128\141", "") -- zero-width joiner
	out = string.gsub(out, "^%s+", "")
	out = string.gsub(out, "%s%s+", " ")
	return out
end

-- Child modules add the premium pieces (order matters: Fx before Parts/Button).
for _, name in { "Fx", "Parts", "Button", "Window", "View" } do
	local install = require(script:WaitForChild(name)) :: any
	install(Kit, Style)
end

return Kit
