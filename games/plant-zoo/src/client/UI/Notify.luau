--!strict
-- Toasts (stacked, top-center), rare-discovery announcements, big center splashes, offline popup.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local Notify = {}

local gui: ScreenGui
local stack: Frame
local announceHolder: Frame
local order = 0

local KIND_COLORS: { [string]: Color3 } = {
	error = Style.Color.Red,
	success = Style.Color.Leaf,
	cash = Style.Color.Cash,
	hope = Style.Color.Sun,
	info = Style.Color.Dark,
	weather = Style.Color.Sky,
}

function Notify.Init()
	gui = Kit.Gui("SproutNotify", 20)
	stack = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.22),
		Size = UDim2.fromScale(0.42, 0.4),
	}, gui)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(260, 0) }, stack)
	Kit.List(stack, false, 6, true)
	announceHolder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.135),
		Size = UDim2.fromScale(0.6, 0.075),
	}, gui)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(300, 36) }, announceHolder)
end

-- Defensive: never show a "None" mutation word (e.g. "NONE NONE Sproutling") in server text.
local function clean(text: string): string
	local out = string.gsub(text, "%f[%w]None None ", "")
	return (string.gsub(out, "%f[%w]NONE ", ""))
end

function Notify.Toast(text: string, kind: string?)
	if not stack then
		return
	end
	text = clean(text)
	local k = kind or "info"
	-- Errors: the server (or Net.Do) already plays "Error", so no second sound here.
	if k ~= "error" and k ~= "cash" then
		Kit.Sound("Notify")
	end
	order += 1
	local color = KIND_COLORS[k] or Style.Color.Dark
	local holder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.16, 0),
		LayoutOrder = order,
	}, stack)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(0, 32) }, holder)
	local pill = Kit.Panel(holder, color, {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, -1.5),
		BackgroundTransparency = 0.05,
	})
	local label = Kit.Label(pill, text, {
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.new(0, 8, 0, 3),
		TextColor3 = Style.Color.White,
	})
	Kit.Make("UIStroke", { Thickness = 1.5, Color = Kit.Darker(color, 0.5) }, label)
	Kit.Tween(pill, 0.3, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Back)
	if #stack:GetChildren() > 6 then
		local oldest: Instance? = nil
		local best = math.huge
		for _, c in stack:GetChildren() do
			if c:IsA("Frame") and c.LayoutOrder < best then
				best = c.LayoutOrder
				oldest = c
			end
		end
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(3, function()
		if pill.Parent then
			Kit.Tween(pill, 0.3, { BackgroundTransparency = 1 })
			Kit.Tween(label, 0.3, { TextTransparency = 1 })
			task.wait(0.3)
			holder:Destroy()
		end
	end)
end

-- Server-wide rare discovery. rarity colors the banner; Secret gets a rainbow outline.
function Notify.Announce(text: string, rarity: string?)
	if not announceHolder then
		return
	end
	text = clean(text)
	Kit.Sound("Announce")
	Kit.Clear(announceHolder)
	local r = Style.NormRarity(rarity or "Legendary")
	local color = Style.RarityColor(r)
	local banner = Kit.Panel(announceHolder, color, {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, -2),
	})
	local label = Kit.Label(banner, "📣 " .. text, {
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.new(0, 8, 0, 3),
		TextColor3 = Style.Color.White,
	})
	Kit.Make("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.3 }, label)
	local outline = banner:FindFirstChildOfClass("UIStroke") :: UIStroke
	outline.Thickness = 4
	Kit.Tween(banner, 0.4, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Back)
	local alive = true
	if r == "Secret" or r == "Mythical" then
		task.spawn(function()
			local h = 0
			while alive and outline.Parent do
				h = (h + 0.02) % 1
				outline.Color = Color3.fromHSV(h, 0.8, 1)
				task.wait(0.03)
			end
		end)
	end
	task.delay(6, function()
		alive = false
		if banner.Parent then
			Kit.Tween(banner, 0.3, { Position = UDim2.fromScale(0, -2) })
			task.wait(0.3)
			banner:Destroy()
		end
	end)
end

-- Big center text that pops and fades ("Thriving!", "Released!").
function Notify.Splash(text: string, color: Color3?, seconds: number?)
	if not gui then
		return
	end
	local label = Kit.Label(gui, text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.6, 0.14),
		TextColor3 = color or Style.Color.Sun,
	})
	local ts = label:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint
	ts.MaxTextSize = 72
	Kit.Make("UIStroke", { Thickness = 3, Color = Kit.Darker(color or Style.Color.Sun, 0.6) }, label)
	local scale = Kit.Make("UIScale", { Scale = 0.3 }, label)
	Kit.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(seconds or 1.6, function()
		Kit.Tween(label, 0.4, { TextTransparency = 1 })
		Kit.Tween(scale, 0.4, { Scale = 1.3 })
		task.wait(0.4)
		label:Destroy()
	end)
end

-- "While you were away" popup. Server already paid; this just shows it.
function Notify.Offline(amount: number, seconds: number, isVip: boolean)
	if not gui then
		return
	end
	Kit.Sound("OfflineEarnings")
	local shade = Kit.Make("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Active = true,
	}, gui)
	local box = Kit.Panel(shade, Style.Color.Cream, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.5),
	})
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(280, 220), MaxSize = Vector2.new(480, 360) }, box)
	Kit.Label(
		box,
		"🌙 While you were away...",
		{ Size = UDim2.fromScale(0.9, 0.18), Position = UDim2.fromScale(0.05, 0.05) }
	)
	Kit.Label(box, "+$" .. Format.Number(amount), {
		Size = UDim2.fromScale(0.9, 0.24),
		Position = UDim2.fromScale(0.05, 0.25),
		TextColor3 = Style.Color.LeafDark,
	})
	local sub = "Your zoo earned for " .. Format.Time(seconds)
	if not isVip then
		sub ..= "\nVIP keeps 100% (you got 50%)"
	end
	Kit.Label(box, sub, {
		Size = UDim2.fromScale(0.9, 0.2),
		Position = UDim2.fromScale(0.05, 0.5),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	Kit.Button(box, "Collect!", Style.Color.Leaf, function()
		Kit.Sound("Cash")
		shade:Destroy()
	end, { Size = UDim2.fromScale(0.6, 0.2), Position = UDim2.fromScale(0.2, 0.75) })
	local scale = Kit.Make("UIScale", { Scale = 0.6 }, box)
	Kit.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

return Notify
