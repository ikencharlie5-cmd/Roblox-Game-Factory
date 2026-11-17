--!strict
-- Always-on HUD: cash + $/s, Hope, luck, weather banner, restock timer, settings gear, goal card.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local Hud = {}
local _skip: any = nil -- sink for unused multiple-return values

local cashLabel: TextLabel
local rateLabel: TextLabel
local hopeLabel: TextLabel
local luckLabel: TextLabel
local weatherBanner: Frame
local weatherLabel: TextLabel
local restockLabel: TextLabel
local padLabel: TextLabel
local setPad: (number) -> ()
local releaseLabel: TextLabel
local setRelease: (number) -> ()
local goalCard: Frame
local shownCash = 0
local lastRestockId = -1

local function pill(parent: Instance, icon: string, color: Color3, width: number, order: number): (Frame, TextLabel)
	local p = Kit.Panel(parent, Style.Color.Dark, {
		Size = UDim2.new(width, -6, 1, 0),
		BackgroundTransparency = 0.15,
		LayoutOrder = order,
	})
	Kit.Label(p, icon, { Size = UDim2.new(0.22, 0, 0.9, 0), Position = UDim2.fromScale(0.02, 0.05) })
	local l = Kit.Label(p, "0", {
		Size = UDim2.new(0.74, 0, 0.8, 0),
		Position = UDim2.fromScale(0.24, 0.1),
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return p, l
end

function Hud.Mount(gui: ScreenGui)
	-- Top center: currencies
	local top = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.fromScale(0.46, 0.075),
	}, gui)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(300, 36), MaxSize = Vector2.new(640, 56) }, top)
	Kit.List(top, true, 6, true)
	local cashPill
	cashPill, cashLabel = pill(top, "💵", Style.Color.Cash, 0.46, 1)
	cashLabel.Size = UDim2.new(0.74, 0, 0.58, 0)
	rateLabel = Kit.Label(cashPill, "+$0/s", {
		Size = UDim2.new(0.74, 0, 0.34, 0),
		Position = UDim2.fromScale(0.24, 0.62),
		TextColor3 = Style.Color.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Style.FontBody,
	})
	_skip, hopeLabel = pill(top, "🌟", Style.Color.Hope, 0.28, 2)
	_skip, luckLabel = pill(top, "🍀", Style.Color.Luck, 0.26, 3)

	-- Weather banner under the currencies
	weatherBanner = Kit.Panel(gui, Style.Color.Sky, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.085, 6),
		Size = UDim2.fromScale(0.4, 0.05),
		Visible = false,
	})
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(260, 26) }, weatherBanner)
	weatherLabel = Kit.Label(weatherBanner, "", {
		Size = UDim2.new(1, -12, 1, -4),
		Position = UDim2.new(0, 6, 0, 2),
		TextColor3 = Style.Color.White,
	})
	Kit.Make("UIStroke", { Thickness = 1.5, Color = Style.Color.Dark }, weatherLabel)

	-- Top right: restock timer (tap = open shop) + settings gear
	local right = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 4),
		Size = UDim2.fromScale(0.22, 0.075),
	}, gui)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(170, 44), MaxSize = Vector2.new(300, 56) }, right)
	local restockBtn = Kit.Button(right, "", Style.Color.Wood, function()
		Windows.Open("Shop")
	end, { Size = UDim2.new(1, -50, 1, 0) })
	restockLabel = Kit.Label(restockBtn, "🛒 Restock 5:00", { TextColor3 = Style.Color.White })
	Kit.Button(right, "⚙️", Style.Color.Grey, function()
		Windows.Toggle("Settings")
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 44, 1, 0) })

	-- Goal card (top-left): next pad + Release progress
	goalCard = Kit.Panel(gui, Style.Color.Cream, {
		Position = UDim2.new(0, 6, 0, 4),
		Size = UDim2.fromScale(0.2, 0.14),
		BackgroundTransparency = 0.05,
	})
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(150, 58), MaxSize = Vector2.new(280, 110) }, goalCard)
	local padBtn = Kit.Make("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 0.5),
	}, goalCard)
	padLabel = Kit.Label(padBtn, "Next: Pad 2 - $500", {
		Size = UDim2.new(1, -10, 0.55, 0),
		Position = UDim2.new(0, 5, 0, 2),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	_skip, setPad = Kit.Progress(padBtn, Style.Color.Leaf, {
		Size = UDim2.new(1, -10, 0.3, 0),
		Position = UDim2.new(0, 5, 0.62, 0),
	})
	padBtn.Activated:Connect(function()
		Kit.Sound("Click")
		Windows.Open("Build", { tab = "Exhibits" })
	end)
	local relBtn = Kit.Make("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	}, goalCard)
	releaseLabel = Kit.Label(relBtn, "🕊️ Release: $1M", {
		Size = UDim2.new(1, -10, 0.55, 0),
		Position = UDim2.new(0, 5, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	_skip, setRelease = Kit.Progress(relBtn, Style.Color.Purple, {
		Size = UDim2.new(1, -10, 0.3, 0),
		Position = UDim2.new(0, 5, 0.58, 0),
	})
	relBtn.Activated:Connect(function()
		Kit.Sound("Click")
		Windows.Open("Release")
	end)

	State.OnChange(function(what)
		if what == "data" then
			Hud.Refresh()
		end
	end)
	task.spawn(function()
		while true do
			Hud.Tick()
			task.wait(0.25)
		end
	end)
end

function Hud.Refresh()
	local cash = State.Num("cash")
	if cash ~= shownCash then
		local grew = cash > shownCash
		local from = shownCash
		shownCash = cash
		local nv = Instance.new("NumberValue")
		nv.Value = from
		nv.Changed:Connect(function(v)
			cashLabel.Text = "$" .. Format.Number(v)
		end)
		Kit.Tween(nv, 0.4, { Value = cash })
		task.delay(0.5, function()
			nv:Destroy()
			cashLabel.Text = "$" .. Format.Number(State.Num("cash"))
		end)
		if grew then
			cashLabel.TextColor3 = Style.Color.White
			Kit.Tween(cashLabel, 0.4, { TextColor3 = Style.Color.Cash })
		end
	end
	hopeLabel.Text = Format.Number(State.Num("hope"))

	local nextIdx, price = Derived.NextPad()
	if nextIdx and price then
		padLabel.Text = string.format("🌱 Next: Pad %d - $%s", nextIdx, Format.Number(price))
		setPad(cash / price)
	else
		padLabel.Text = "🌱 All pads owned!"
		setPad(1)
	end
	local n, need, rarity = Derived.ReleaseInfo()
	releaseLabel.Text = string.format("🕊️ Release #%d: $%s + %s", n, Format.Number(need), rarity)
	setRelease(cash / need)
end

function Hud.Tick()
	local now = State.Now()
	rateLabel.Text = "+$" .. Format.Number(Derived.Income()) .. "/s"

	local luck = Derived.Luck()
	local potion = Derived.LuckPotionLeft()
	luckLabel.Text = string.format("x%.1f", luck) .. (if potion > 0 then " ⏱" .. Format.Time(potion) else "")

	-- Restock countdown is global and deterministic: every RestockSeconds of server time.
	local period = Derived.Config.Shop.RestockSeconds
	local restockId = math.floor(now / period)
	local left = (restockId + 1) * period - now
	restockLabel.Text = "🛒 Restock " .. Format.Time(left)
	if lastRestockId ~= -1 and restockId ~= lastRestockId then
		restockLabel.TextColor3 = Style.Color.Sun
		Kit.Tween(restockLabel, 1, { TextColor3 = Style.Color.White })
	end
	lastRestockId = restockId

	-- Weather
	local w = State.weather
	local name = if type(w) == "table" then (w.name or w.Name) else nil
	local endsAt = if type(w) == "table" then (w.endsAt or w.EndsAt or 0) else 0
	if type(name) == "string" and name ~= "" and name ~= "Clear" and (endsAt == 0 or endsAt > now) then
		local info = Style.WeatherInfo(name)
		weatherBanner.BackgroundColor3 = info.Color
		local timer = if endsAt > 0 then "  " .. Format.Time(endsAt - now) else ""
		weatherLabel.Text = string.format("%s %s! %s%s", info.Icon, name, info.Text, timer)
		if not weatherBanner.Visible then
			weatherBanner.Visible = true
			weatherBanner.Size = UDim2.fromScale(0.1, 0.05)
			Kit.Tween(weatherBanner, 0.35, { Size = UDim2.fromScale(0.4, 0.05) }, Enum.EasingStyle.Back)
		end
	else
		-- Clear skies: small teaser so players stick around for the next event.
		local nextAt = if type(w) == "table" then (w.nextAt or w.NextAt or 0) else 0
		if nextAt > now then
			weatherBanner.Visible = true
			weatherBanner.BackgroundColor3 = Style.Color.Grey
			weatherLabel.Text = "🌤️ Next weather in " .. Format.Time(nextAt - now)
		else
			weatherBanner.Visible = false
		end
	end
end

-- Used by the tutorial to point at things.
function Hud.GoalCard(): Frame
	return goalCard
end

return Hud
