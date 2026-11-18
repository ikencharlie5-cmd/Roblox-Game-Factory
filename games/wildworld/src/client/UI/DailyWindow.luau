--!strict
-- Daily reward: 7-day strip (today highlighted, claimed days ticked, day 7 = Mutation Egg),
-- a big Claim button and the next-claim timer. ClaimDaily only; the server pays.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local DailyWindow = {}

local FALLBACK = {
	"100 Coins",
	"200 Coins",
	"3 Honey Bait",
	"500 Coins + 20 RP",
	"Starfruit Bait",
	"1,500 Coins",
	"Mutation Egg!",
}

local win: any
local strip: Frame
local claimBtn: TextButton
local timer: TextLabel
local badgeFn: ((boolean) -> ())? = nil

function DailyWindow.SetBadge(fn: (boolean) -> ())
	badgeFn = fn
end

local function rewards(): { string }
	local d = Derived.Cfg("Daily") or {}
	local r = Derived.Field(d, "Rewards", "rewards")
	if type(r) == "table" and #r >= 7 then
		local out = {}
		for i, v in r do
			out[i] = if type(v) == "table" then tostring(v.text or v.Text or v.label or ("Day " .. i)) else tostring(v)
		end
		return out
	end
	return FALLBACK
end

-- (streak so far, can claim now, seconds until next)
function DailyWindow.Next(): (number, boolean, number)
	local daily = State.Tbl("daily")
	local streak = tonumber(daily.streak) or 0
	local last = tonumber(daily.last) or 0
	local cd = tonumber(Derived.Field(Derived.Cfg("Daily") or {}, "CooldownSeconds")) or 20 * 3600
	local left = last + cd - State.Now()
	if daily.canClaim ~= nil then
		return streak, daily.canClaim == true, math.max(0, left)
	end
	return streak, left <= 0, math.max(0, left)
end

local function render()
	local streak, can, left = DailyWindow.Next()
	if badgeFn then
		(badgeFn :: (boolean) -> ())(can)
	end
	if not Windows.IsOpen("Daily") then
		return
	end
	Kit.Clear(strip)
	local today = (streak % 7) + 1
	for i, text in rewards() do
		local done = i < today or (i == today and not can)
		local isToday = i == today and can
		local pal = if isToday then Style.Pal.Sun elseif done then Style.Pal.Leaf elseif i == 7 then Style.Pal.Purple else Style.Pal.Card
		local f = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1 / 7, -8, 1, 0), LayoutOrder = i }, strip)
		local face = Kit.Slab(f, pal, 16, 5)
		Kit.Title(face, "Day " .. i, pal.Dark, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 6), TextSize = 22, ZIndex = 4 })
		Kit.Label(face, if done then "Claimed" else text, {
			Position = UDim2.fromOffset(6, 40),
			Size = UDim2.new(1, -12, 1, -48),
			TextSize = 18,
			TextColor3 = if pal == Style.Pal.Card then Style.Color.Ink else Style.Color.White,
			ZIndex = 4,
		})
		if isToday then
			Kit.Pulse(f, 1.05)
		end
	end
	Kit.SetButtonColor(claimBtn, if can then "Leaf" else "Stone")
	claimBtn.Text = if can then "CLAIM!" else "Come back soon"
	timer.Text = if can then "Miss a day and the streak resets!" else "Next reward in " .. Format.Time(left)
end

function DailyWindow.Mount()
	win = Windows.Create("Daily", "Daily Reward", "Sun", "Daily", Vector2.new(900, 460))
	strip = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 190) }, win.Body)
	Kit.List(strip, true, 8)
	claimBtn = Kit.Button(win.Body, "CLAIM!", "Leaf", function()
		local _, can = DailyWindow.Next()
		if not can then
			Kit.Sound("Error")
			return
		end
		if Net.Do("ClaimDaily", nil) then
			Kit.Sound("DailyClaim")
		end
	end, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 212),
		Size = UDim2.fromOffset(320, 76),
		TextSize = 36,
		Shine = true,
	})
	timer = Kit.Body(win.Body, "", { Position = UDim2.fromOffset(0, 300), Size = UDim2.new(1, 0, 0, 30), TextSize = 20 })
	win.OnOpen = render
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if Windows.IsOpen("Daily") then
				local _, can, left = DailyWindow.Next()
				if not can then
					timer.Text = "Next reward in " .. Format.Time(left)
				end
			end
		end
	end)
end

return DailyWindow
