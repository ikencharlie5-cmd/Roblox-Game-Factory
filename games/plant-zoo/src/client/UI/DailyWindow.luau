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

local function rewardText(r: any): string
	if r.Kind == "Income" then
		return string.format("💵\n%d min of income", r.Minutes)
	elseif r.Kind == "Hope" then
		return "🌟\n" .. r.Amount .. " Hope"
	elseif r.Kind == "LuckPotion" then
		return "🧪\nLuck Potion"
	elseif r.Kind == "GrowTonic" then
		return "💧\n" .. r.Amount .. " Grow Tonics"
	elseif r.Kind == "Seed" then
		return "🌱\nFree " .. tostring(r.Rarity) .. " seed!"
	end
	return "🎁"
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
		local color = if isToday then Style.Color.Sun elseif done then Style.Color.Leaf else Style.Color.Card
		local c = Kit.Panel(strip, color, { LayoutOrder = i, Size = UDim2.new(1 / 7, -6, 1, 0) })
		Kit.Label(c, "Day " .. i, { Size = UDim2.new(1, -4, 0.2, 0), Position = UDim2.new(0, 2, 0.02, 0) })
		Kit.Label(c, rewardText(r), {
			Size = UDim2.new(1, -6, 0.58, 0),
			Position = UDim2.new(0, 3, 0.22, 0),
			Font = Style.FontBody,
		})
		Kit.Label(c, if done then "✅" elseif isToday then "TODAY" else "", {
			Size = UDim2.new(1, -4, 0.18, 0),
			Position = UDim2.new(0, 2, 0.8, 0),
		})
		if isToday then
			local s = Kit.Make("UIScale", { Scale = 1 }, c)
			task.spawn(function()
				while s.Parent do
					Kit.Tween(s, 0.5, { Scale = 1.06 })
					task.wait(0.5)
					Kit.Tween(s, 0.5, { Scale = 1 })
					task.wait(0.5)
				end
			end)
		end
	end
	Kit.SetButtonColor(claimBtn, if can then Style.Color.Leaf else Style.Color.Grey)
	claimBtn.Text = if can then "🎁 Claim Day " .. day else "Come back tomorrow!"
end

function DailyWindow.Mount()
	local win = Windows.Create("Daily", "🎁 Daily Reward", Style.Color.Pink)
	infoLabel = Kit.Label(win.Body, "Log in every day! Miss a day and the streak restarts.", {
		Size = UDim2.fromScale(1, 0.1),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	strip = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.13),
		Size = UDim2.fromScale(1, 0.6),
	}, win.Body)
	Kit.List(strip, true, 6, true)
	claimBtn = Kit.Button(win.Body, "Claim", Style.Color.Leaf, function()
		local _, can = DailyWindow.Next()
		if not can then
			Kit.Sound("Error")
			return
		end
		local ok, res = Net.Do("ClaimDaily", nil)
		if ok then
			if type(res) == "table" and type(res.text) == "string" then
				infoLabel.Text = "🎉 " .. res.text
			end
			lastSig = ""
			DailyWindow.Render()
		end
	end, { Size = UDim2.fromScale(0.5, 0.18), Position = UDim2.fromScale(0.25, 0.79) })
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
