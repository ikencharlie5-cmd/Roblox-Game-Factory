--!strict
-- Left button bar (2 columns so it fits a phone in landscape). Red dots = something to claim.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SideBar = {}

local BUTTONS = {
	{ Name = "Shop", Icon = "🛒", Color = Style.Color.Leaf },
	{ Name = "Inventory", Label = "Bag", Icon = "🎒", Color = Style.Color.Wood },
	{ Name = "Build", Icon = "🔨", Color = Style.Color.Sun },
	{ Name = "Index", Icon = "📖", Color = Style.Color.Sky },
	{ Name = "Upgrades", Label = "Upgrade", Icon = "⬆️", Color = Style.Color.LeafDark },
	{ Name = "Release", Icon = "🕊️", Color = Style.Color.Purple },
	{ Name = "Quests", Icon = "📜", Color = Style.Color.Wood },
	{ Name = "Daily", Icon = "🎁", Color = Style.Color.Pink },
	{ Name = "Visit", Icon = "🏡", Color = Style.Color.Sky },
	{ Name = "Store", Icon = "💎", Color = Style.Color.Robux },
}

local buttons: { [string]: TextButton } = {}
local badges: { [string]: TextLabel } = {}

function SideBar.Mount(gui: ScreenGui)
	local bar = Kit.Make("Frame", {
		Name = "SideBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.58, 0),
		Size = UDim2.fromScale(0.13, 0.62),
	}, gui)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(100, 250), MaxSize = Vector2.new(180, 460) }, bar)
	Kit.Make("UIAspectRatioConstraint", { AspectRatio = 0.4 }, bar)
	Kit.Grid(bar, UDim2.new(0.5, -3, 0.2, -5), 5)

	for i, def in BUTTONS do
		local b = Kit.Button(bar, "", def.Color, function()
			Windows.Toggle(def.Name)
		end, { LayoutOrder = i, Name = def.Name })
		-- Grid cells can't use the 44px constraint; the bar's MinSize keeps cells >= ~47px.
		local c = b:FindFirstChildOfClass("UISizeConstraint")
		if c then
			c:Destroy()
		end
		Kit.Icon(b, Style.Icons[def.Name] or def.Icon, {
			Size = UDim2.fromScale(0.9, 0.58),
			Position = UDim2.fromScale(0.05, 0.04),
		})
		local text = Kit.Label(b, def.Label or def.Name, {
			Size = UDim2.fromScale(1, 0.36),
			Position = UDim2.fromScale(0, 0.64),
			TextColor3 = Style.Color.White,
		})
		Kit.Make("UIStroke", { Thickness = 1.5, Color = Kit.Darker(def.Color, 0.5) }, text)
		local dot = Kit.Label(b, "!", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.92, 0.08),
			Size = UDim2.fromScale(0.34, 0.34),
			BackgroundTransparency = 0,
			BackgroundColor3 = Style.Color.Red,
			TextColor3 = Style.Color.White,
			Visible = false,
			ZIndex = 3,
		})
		Kit.Make("UIAspectRatioConstraint", { AspectRatio = 1 }, dot)
		Kit.Corner(dot, 99)
		buttons[def.Name] = b
		badges[def.Name] = dot
	end

	-- Bounce badges so they are noticed.
	task.spawn(function()
		local up = false
		while true do
			up = not up
			for _, dot in badges do
				if dot.Visible then
					Kit.Tween(dot, 0.4, { Size = UDim2.fromScale(if up then 0.4 else 0.32, if up then 0.4 else 0.32) })
				end
			end
			task.wait(0.45)
		end
	end)
end

function SideBar.Badge(name: string, on: boolean)
	local dot = badges[name]
	if dot then
		dot.Visible = on
	end
end

function SideBar.Button(name: string): TextButton?
	return buttons[name]
end

return SideBar
