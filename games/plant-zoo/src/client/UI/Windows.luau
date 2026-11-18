--!strict
-- Window manager: one menu open at a time, Back-Out pop-in, blur + dim behind, Quad-In close,
-- staggered card entrances, and a Confirm dialog. Chrome comes from Kit.Window.
local Lighting = game:GetService("Lighting")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local Windows = {}

export type Win = {
	Name: string,
	Frame: Frame,
	Body: Frame,
	Title: TextLabel,
	OnOpen: ((any) -> ())?,
	OnClose: (() -> ())?,
}

local gui: ScreenGui
local root: Frame
local dim: Frame
local blur: BlurEffect
local registry: { [string]: Win } = {}
local sizes: { [string]: Vector2 } = {}
local current: Win? = nil
local openedSignal = Instance.new("BindableEvent")
Windows.Opened = openedSignal.Event -- (name: string?)

-- Fit a window into the safe screen: max its design size, at most 92% wide / screen height - 70.
local function fit(win: Win)
	local want = sizes[win.Name] or Vector2.new(820, 560)
	local v = Kit.Virtual(gui)
	win.Frame.Size = UDim2.fromOffset(math.min(want.X, v.X * 0.92), math.min(want.Y, v.Y - 70))
end

function Windows.Init(screenGui: ScreenGui)
	gui = screenGui
	root = Kit.Root(gui)
	dim = Kit.Make("Frame", {
		Name = "Dim",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 0,
	}, root)
	blur = Kit.Make("BlurEffect", { Name = "SproutUIBlur", Size = 0, Enabled = false }, Lighting)
	Kit.Resized:Connect(function()
		for _, w in registry do
			fit(w)
		end
	end)
end

local function setBackdrop(on: boolean)
	if on then
		dim.Visible = true
		blur.Enabled = true
		Kit.Tween(dim, 0.2, { BackgroundTransparency = 0.6 })
		Kit.Tween(blur, 0.2, { Size = 10 })
	else
		Kit.Tween(dim, 0.18, { BackgroundTransparency = 1 })
		Kit.Tween(blur, 0.18, { Size = 0 })
		task.delay(0.2, function()
			if current == nil then
				dim.Visible = false
				blur.Enabled = false
			end
		end)
	end
end

-- accent = header colour (palette, name or Color3); icon = Style.Icons name; size = design px.
function Windows.Create(name: string, title: string, accent: any?, icon: string?, size: Vector2?): Win
	local parts = Kit.Window(root, title, accent or "Leaf", icon, size, function()
		Windows.Close()
	end)
	parts.Frame.Name = name
	parts.Frame.Visible = false
	sizes[name] = size or Vector2.new(820, 560)
	local win: Win = { Name = name, Frame = parts.Frame, Body = parts.Body, Title = parts.Title }
	registry[name] = win
	fit(win)
	return win
end

function Windows.SetSize(name: string, size: Vector2)
	sizes[name] = size
	local w = registry[name]
	if w then
		fit(w)
	end
end

function Windows.Get(name: string): Win?
	return registry[name]
end

function Windows.IsOpen(name: string): boolean
	return current ~= nil and (current :: Win).Name == name
end

function Windows.Close()
	local win = current
	if not win then
		return
	end
	current = nil
	Kit.Sound("Close")
	local scale = win.Frame:FindFirstChild("Open") :: UIScale
	Kit.Tween(scale, 0.18, { Scale = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.18, function()
		if current ~= win then
			win.Frame.Visible = false
		end
	end)
	setBackdrop(false)
	if win.OnClose then
		task.spawn(win.OnClose :: () -> ())
	end
	openedSignal:Fire(nil)
end

function Windows.Open(name: string, arg: any?)
	local win = registry[name]
	if not win then
		warn("[UI] unknown window", name)
		return
	end
	if current and current ~= win then
		local old = current :: Win
		current = nil
		old.Frame.Visible = false
		if old.OnClose then
			task.spawn(old.OnClose :: () -> ())
		end
	end
	local wasOpen = current == win
	current = win
	if not wasOpen then
		Kit.Sound("Open")
		fit(win)
		local scale = win.Frame:FindFirstChild("Open") :: UIScale
		scale.Scale = 0.6
		win.Frame.Visible = true
		Kit.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		setBackdrop(true)
	end
	Kit.BeginStagger(0.5)
	if win.OnOpen then
		task.spawn(win.OnOpen :: (any) -> (), arg)
	end
	openedSignal:Fire(name)
end

function Windows.Toggle(name: string, arg: any?)
	if Windows.IsOpen(name) then
		Windows.Close()
	else
		Windows.Open(name, arg)
	end
end

-- Yes/No popup above everything. onYes runs only on Yes.
function Windows.Confirm(title: string, text: string, yesText: string, onYes: () -> ())
	local shade = Kit.Make("TextButton", {
		Name = "ConfirmShade",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	}, root)
	Kit.Tween(shade, 0.2, { BackgroundTransparency = 0.5 })
	local function close()
		Kit.Sound("Close")
		shade:Destroy()
	end
	local parts = Kit.Window(shade, title, "Red", nil, Vector2.new(560, 330), close)
	local box = parts.Frame
	box.ZIndex = 51
	Kit.Body(parts.Body, text, {
		Size = UDim2.new(1, 0, 1, -84),
		TextSize = 24,
		TextColor3 = Style.Color.Ink,
	})
	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 68),
	}, parts.Body)
	Kit.List(row, true, 16, true)
	Kit.Button(row, "Cancel", "Stone", close, { Size = UDim2.fromOffset(200, 66), LayoutOrder = 1 })
	Kit.Button(row, yesText, "Red", function()
		shade:Destroy()
		onYes()
	end, { Size = UDim2.fromOffset(200, 66), LayoutOrder = 2 })
	Kit.Sound("Open")
	parts.Scale.Scale = 0.6
	Kit.Tween(parts.Scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

return Windows
