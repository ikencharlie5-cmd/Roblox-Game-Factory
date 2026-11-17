--!strict
-- Quests: tutorial chain progress (auto-rewarded) + 3 daily quests with progress bars and Claim.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local QuestsWindow = {}

local list: ScrollingFrame
local lastSig = ""
local badge: ((boolean) -> ())? = nil

function QuestsWindow.SetBadge(fn: (boolean) -> ())
	badge = fn
end

function QuestsWindow.DailyList(): { any }
	local q = State.Tbl("quests")
	return if type(q.list) == "table" then q.list else {}
end

-- Returns tutorial step def + index while the tutorial runs, else nil.
function QuestsWindow.TutorialStep(): (any, number)
	local step = State.Num("tutorialStep")
	local def = Derived.Config.Tutorial[step]
	return def, step
end

local function row(order: number, title: string, progress: number, goal: number, claimable: boolean, claimed: boolean, onClaim: (() -> ())?)
	local r = Kit.Panel(list, if claimable then Style.Color.Cream else Style.Color.Panel, {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 64),
	})
	Kit.Label(r, title, {
		Size = UDim2.new(0.7, -8, 0.5, -2),
		Position = UDim2.new(0, 8, 0, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _, set = Kit.Progress(r, Style.Color.Leaf, {
		Size = UDim2.new(0.7, -8, 0.26, 0),
		Position = UDim2.new(0, 8, 0.6, 0),
	})
	set(if goal > 0 then progress / goal else 0)
	Kit.Label(r, string.format("%d/%d", math.min(progress, goal), goal), {
		Size = UDim2.new(0.7, -8, 0.26, 0),
		Position = UDim2.new(0, 8, 0.6, 0),
		TextColor3 = Style.Color.White,
		ZIndex = 3,
	})
	if claimed then
		Kit.Label(r, "✅ Done", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0.26, 0, 0.6, 0),
			TextColor3 = Style.Color.LeafDark,
		})
	elseif onClaim then
		Kit.Button(r, if claimable then "Claim!" else "...", if claimable then Style.Color.Sun else Style.Color.Grey, onClaim, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0.26, 0, 0, 48),
		})
	end
end

function QuestsWindow.Render(force: boolean?)
	local quests = QuestsWindow.DailyList()
	local anyClaim = false
	for _, q in quests do
		if not q.claimed and (q.progress or 0) >= (q.goal or 1) then
			anyClaim = true
		end
	end
	if badge then
		(badge :: (boolean) -> ())(anyClaim)
	end
	if not Windows.IsOpen("Quests") then
		return
	end
	local sig = Kit.Sig({ quests, State.Get("tutorialStep"), State.Get("tutorialProgress") })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	local def, step = QuestsWindow.TutorialStep()
	if def then
		Kit.Label(list, string.format("🌱 Getting started (%d/%d)", step, #Derived.Config.Tutorial), {
			LayoutOrder = 1,
			Size = UDim2.new(1, -8, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		row(2, def.Text, State.Num("tutorialProgress"), def.Goal, false, false, nil)
	end
	Kit.Label(list, "📅 Daily quests (+10 🌟 each)", {
		LayoutOrder = 10,
		Size = UDim2.new(1, -8, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	for i, q in quests do
		local progress, goal = q.progress or 0, q.goal or 1
		local claimable = not q.claimed and progress >= goal
		row(10 + i, tostring(q.text or q.kind), progress, goal, claimable, q.claimed == true, function()
			if not claimable then
				Kit.Sound("Error")
				return
			end
			if Net.Do("ClaimQuest", nil, i) then
				Kit.Sound("QuestComplete")
			end
		end)
	end
	if #quests == 0 then
		Kit.Label(list, "New quests arrive every day!", { LayoutOrder = 20, Size = UDim2.new(1, -8, 0, 30) })
	end
end

function QuestsWindow.Mount()
	local win = Windows.Create("Quests", "📜 Quests", Style.Color.Wood)
	list = Kit.Scroll(win.Body)
	Kit.List(list, false, 6)
	Kit.Padding(list, 4)
	win.OnOpen = function()
		QuestsWindow.Render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			QuestsWindow.Render()
		end
	end)
end

return QuestsWindow
