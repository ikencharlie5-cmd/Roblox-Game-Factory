--!strict
-- Daily reward: 7-day streak strip (missing a UTC day resets), Claim button, sidebar badge.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local DailyWindow = {}

local strip: Frame
local claimBtn: TextButton
local infoLabel: TextLabel
local lastSig = ""
local badge: ((boolean) -> ())? = nil

-- (icon, text) per reward kind. Icons are Style.Icons names (code-drawn badge until uploaded).
local function reward(r: any): (string, string)
	if r.Kind == "Income" then
		return "Cash", string.format("%d min of income", r.Minutes)
	elseif r.Kind == "Hope" then
		return "Hope", r.Amount .. " Hope"
	elseif r.Kind == "LuckPotion" then
		return "LuckPotion", "Luck Potion"
	elseif r.Kind == "GrowTonic" then
		return "GrowTonic", r.Amount .. " Grow Tonics"
	elseif r.Kind == "Seed" then
		return "Shop", "Free " .. tostring(r.Rarity) .. " seed!"
	end
	return "Daily", "Gift"
end

-- Mirrors DailyRewardService.Next for display: (dayToClaim, canClaim)
function DailyWindow.Next(): (number, boolean)
	local daily = State.Tbl("daily")
	local today = Derived.Day()
	local last = daily.last or 0
	local streak = daily.streak or 0
	local count = #Derived.Config.Daily.Rewards
	if last == today then
		return streak, false
	elseif last == today - 1 then
		return (streak % count) + 1, true
	end
	return 1, true
end

function DailyWindow.SetBadge(fn: (boolean) -> ())
	badge = fn
end

function DailyWindow.Render(force: boolean?)
	local day, can = DailyWindow.Next()
	if badge then
		(badge :: (boolean) -> ())(can)
	end
	if not Windows.IsOpen("Daily") then
		return
	end
	local sig = Kit.Sig({ day, can })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(strip)
	for i, r in Derived.Config.Daily.Rewards do
		local done = i < day or (i == day and not can)
		local isToday = i == day and can
		local pal = if isToday then Style.Pal.Sun elseif done then Style.Pal.Leaf else Style.Pal.Card
		local cell = Kit.Make("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Size = UDim2.new(1 / 7, -8, 1, 0),
		}, strip)
		local face = Kit.Slab(cell, pal, 16, 5, 3, true)
		if pal == Style.Pal.Card then
			(face:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Style.Pal.Body.Dark
			local lip = cell:FindFirstChild("Lip") :: Frame
			lip.BackgroundColor3 = Style.Pal.Body.Dark
		end
		local dark = if pal == Style.Pal.Card then Style.Pal.Body.Dark else pal.Dark
		Kit.Title(
			face,
			"Day " .. i,
			dark,
			{ Size = UDim2.new(1, -8, 0, 30), Position = UDim2.fromOffset(4, 6), TextSize = 24, ZIndex = 4 }
		)
		local icon, text = reward(r)
		Kit.Icon(face, icon, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 40),
			Size = UDim2.fromOffset(62, 62),
			Depth = true,
			ZIndex = 4,
		})
		Kit.Body(face, text, {
			Position = UDim2.fromOffset(4, 106),
			Size = UDim2.new(1, -8, 0, 56),
			TextSize = 18,
			TextColor3 = if pal == Style.Pal.Card then Style.Color.Ink else Style.Color.White,
			Stroke = if pal == Style.Pal.Card then nil else dark,
			StrokeThickness = 2,
			ZIndex = 4,
		})
		if done then
			Kit.CodeBadge(cell, "OK", Style.Pal.Leaf, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -8, 0, 8),
				Size = UDim2.fromOffset(34, 34),
				ZIndex = 6,
			})
		elseif isToday then
			Kit.Title(face, "TODAY", dark, {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 4, 1, -6),
				Size = UDim2.new(1, -8, 0, 26),
				TextSize = 22,
				ZIndex = 4,
			})
			Kit.Pulse(cell)
		end
	end
	Kit.SetButtonColor(claimBtn, if can then "Leaf" else Style.Color.Grey)
	claimBtn.Text = if can then "Claim Day " .. day else "Come back tomorrow!"
end

function DailyWindow.Mount()
	local win = Windows.Create("Daily", "Daily Reward", "Sun", "Daily", Vector2.new(900, 520))
	infoLabel = Kit.Body(win.Body, "Log in every day! Miss a day and the streak restarts.", {
		Size = UDim2.new(1, 0, 0, 34),
		TextSize = 22,
	})
	strip = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -146),
	}, win.Body)
	Kit.List(strip, true, 8, true)
	claimBtn = Kit.Button(win.Body, "Claim", "Leaf", function()
		local _, can = DailyWindow.Next()
		if not can then
			Kit.Sound("Error")
			return
		end
		local ok, res = Net.Do("ClaimDaily", nil)
		if ok then
			if type(res) == "table" and type(res.text) == "string" then
				infoLabel.Text = Kit.StripEmoji(res.text)
			end
			lastSig = ""
			DailyWindow.Render()
		end
	end, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(360, 76),
		TextSize = 30,
		Shine = true,
	})
	win.OnOpen = function()
		DailyWindow.Render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			DailyWindow.Render()
		end
	end)
	-- Re-check at UTC midnight without needing a data change.
	task.spawn(function()
		while true do
			task.wait(30)
			DailyWindow.Render()
		end
	end)
end

return DailyWindow
