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

local function row(
	order: number,
	title: string,
	progress: number,
	goal: number,
	claimable: boolean,
	claimed: boolean,
	onClaim: (() -> ())?
)
	local r = Kit.Panel(list, if claimable then Style.Color.Sun else Style.Color.Panel, {
		LayoutOrder = order,
		Size = UDim2.new(1, -12, 0, 84),
	})
	Kit.Stagger(r)
	Kit.Label(r, Kit.StripEmoji(title), {
		Size = UDim2.new(0.7, -16, 0, 34),
		Position = UDim2.fromOffset(14, 8),
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _, set = Kit.Progress(r, "Leaf", {
		Size = UDim2.new(0.7, -16, 0, 26),
		Position = UDim2.fromOffset(14, 48),
	})
	set(if goal > 0 then progress / goal else 0)
	Kit.Title(r, string.format("%d/%d", math.min(progress, goal), goal), Style.Color.Dark, {
		Size = UDim2.new(0.7, -16, 0, 26),
		Position = UDim2.fromOffset(14, 48),
		TextSize = 20,
		StrokeThickness = 2,
		ZIndex = 3,
	})
	if claimed then
		Kit.Title(r, "Done!", Style.Pal.Leaf.Dark, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(0.26, 0, 0, 44),
			TextSize = 32,
			TextColor3 = Style.Pal.Leaf.Top,
		})
	elseif onClaim then
		Kit.Button(r, if claimable then "Claim!" else "...", if claimable then "Sun" else Style.Color.Grey, onClaim, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(0.26, 0, 0, 60),
			Shine = claimable,
		})
	end
end

local function heading(order: number, text: string)
	Kit.Label(list, text, {
		LayoutOrder = order,
		Size = UDim2.new(1, -12, 0, 36),
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
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
		heading(1, string.format("Getting started (%d/%d)", step, #Derived.Config.Tutorial))
		row(2, def.Text, State.Num("tutorialProgress"), def.Goal, false, false, nil)
	end
	heading(10, "Daily quests (+10 Hope each)")
	for i, q in quests do
		local progress, goal = q.progress or 0, q.goal or 1
		local claimable = not q.claimed and progress >= goal
		row(10 + i, tostring(q.text or q.kind), progress, goal, claimable, q.claimed == true, function()
			if not claimable then
				Kit.Sound("Error")
				return
			end
			Net.Do("ClaimQuest", nil, i)
		end)
	end
	if #quests == 0 then
		Kit.Body(list, "New quests arrive every day!", { LayoutOrder = 20, Size = UDim2.new(1, -12, 0, 30) })
	end
end

function QuestsWindow.Mount()
	local win = Windows.Create("Quests", "Quests", "Pink", "Quests")
	list = Kit.Scroll(win.Body)
	Kit.List(list, false, 10)
	Kit.Padding(list, 6)
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
