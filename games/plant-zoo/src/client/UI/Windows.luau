--!strict
-- Window frames + manager: only one menu open at a time, pop-in tween, close button, confirm dialog.
local Theme = require(script.Parent:WaitForChild("Theme"))
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
local registry: { [string]: Win } = {}
local current: Win? = nil
local openedSignal = Instance.new("BindableEvent")
Windows.Opened = openedSignal.Event -- (name: string?)

function Windows.Init(screenGui: ScreenGui)
	gui = screenGui
end

function Windows.Create(name: string, title: string, accent: Color3?): Win
	local color = accent or Theme.Color.Leaf
	local frame = Kit.Panel(gui, Theme.Color.Cream, {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.64, 0.76),
		Visible = false,
		ZIndex = 5,
	})
	Kit.Make("UISizeConstraint", { MaxSize = Vector2.new(860, 620), MinSize = Vector2.new(300, 230) }, frame)
	Kit.Make("UIScale", { Scale = 1 }, frame)

	local bar = Kit.Make("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 46),
	}, frame)
	Kit.Corner(bar, 12)
	local titleLabel = Kit.Label(bar, title, {
		Size = UDim2.new(1, -110, 1, -8),
		Position = UDim2.new(0, 14, 0, 4),
		TextColor3 = Theme.Color.White,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Kit.Make("UIStroke", { Thickness = 2, Color = Kit.Darker(color, 0.5) }, titleLabel)

	local body = Kit.Make("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 54),
		Size = UDim2.new(1, -20, 1, -62),
	}, frame)

	local win: Win = { Name = name, Frame = frame, Body = body, Title = titleLabel }
	Kit.Button(bar, "X", Theme.Color.Red, function()
		Windows.Close()
	end, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 44),
	})
	registry[name] = win
	return win
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
	local scale = win.Frame:FindFirstChildOfClass("UIScale") :: UIScale
	Kit.Tween(scale, 0.12, { Scale = 0.85 })
	task.delay(0.12, function()
		if current ~= win then
			win.Frame.Visible = false
		end
	end)
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
	current = win
	Kit.Sound("Open")
	local scale = win.Frame:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0.7
	win.Frame.Visible = true
	Kit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
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
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	}, gui)
	local box = Kit.Panel(shade, Theme.Color.Cream, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.42, 0.42),
		ZIndex = 51,
	})
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(280, 190), MaxSize = Vector2.new(520, 320) }, box)
	Kit.Label(box, title, { Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.05), ZIndex = 52 })
	Kit.Label(box, text, {
		Size = UDim2.fromScale(0.9, 0.36),
		Position = UDim2.fromScale(0.05, 0.27),
		Font = Theme.FontBody,
		TextColor3 = Theme.Color.InkSoft,
		ZIndex = 52,
	})
	local function close()
		shade:Destroy()
	end
	Kit.Button(box, "Cancel", Theme.Color.Grey, close, {
		Size = UDim2.fromScale(0.42, 0.24),
		Position = UDim2.fromScale(0.05, 0.7),
		ZIndex = 52,
	})
	Kit.Button(box, yesText, Theme.Color.Red, function()
		close()
		onYes()
	end, { Size = UDim2.fromScale(0.42, 0.24), Position = UDim2.fromScale(0.53, 0.7), ZIndex = 52 })
	local scale = Kit.Make("UIScale", { Scale = 0.7 }, box)
	Kit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

return Windows
