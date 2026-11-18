--!strict
-- Quest tracker card (guide §3): right side, 300 x ~120, collapsible to a 56 px chip.
-- Shows the tutorial goal while the tutorial runs, then the next unclaimed daily quest with a
-- Claim button (ClaimQuest). Hidden until the tutorial reaches the quest step.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))

local QuestCard = {}

local holder: Frame
local card: Frame
local chip: TextButton
local titleLabel: TextLabel
local textLabel: TextLabel
local setBar: (number) -> ()
local claimBtn: TextButton
local collapsed = false
local override: { title: string, text: string, progress: number }? = nil
local claimId: any = nil
local enabled = false
local hidden = false

local function daily(): { [string]: any }?
	local qs = State.Tbl("quests")
	local list = qs.daily or qs.list or qs
	if type(list) ~= "table" then
		return nil
	end
	for k, q in list do
		if type(q) == "table" and not q.claimed then
			local e = table.clone(q)
			e.id = q.id or k
			return e
		end
	end
	return nil
end

local function render()
	if not enabled or hidden then
		holder.Visible = false
		return
	end
	holder.Visible = true
	card.Visible = not collapsed
	chip.Visible = collapsed
	claimBtn.Visible = false
	claimId = nil
	local o = override
	if o then
		titleLabel.Text = o.title
		textLabel.Text = o.text
		setBar(o.progress)
		return
	end
	local q = daily()
	if not q then
		titleLabel.Text = "Daily quests"
		textLabel.Text = "All done! New quests tomorrow."
		setBar(1)
		return
	end
	local goal = math.max(1, tonumber(q.goal or q.target) or 1)
	local prog = math.min(goal, tonumber(q.progress) or 0)
	titleLabel.Text = "Daily quest"
	textLabel.Text = Kit.StripEmoji(tostring(q.text or q.name or q.kind or "Quest")) .. string.format("  %d/%d", prog, goal)
	setBar(prog / goal)
	if prog >= goal then
		claimBtn.Visible = true
		claimId = q.id
	end
end

function QuestCard.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	holder = Kit.Make("Frame", {
		Name = "QuestCard",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 180),
		Size = UDim2.fromOffset(300, 132),
		Visible = false,
	}, root)
	card = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, holder)
	local face = Kit.Slab(card, Style.Pal.Body, 18, 5, 3.5)
	Kit.CodeBadge(face, "!", Style.Pal.Coral, { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(32, 32), ZIndex = 4 })
	titleLabel = Kit.Label(face, "Quest", {
		Position = UDim2.fromOffset(46, 6),
		Size = UDim2.new(1, -100, 0, 30),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})
	textLabel = Kit.Body(face, "", {
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 0, 44),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.Color.Ink,
		ZIndex = 4,
	})
	local _, set = Kit.Progress(face, "Leaf", { Position = UDim2.fromOffset(12, 92), Size = UDim2.new(1, -24, 0, 14), ZIndex = 4 })
	setBar = set
	Kit.Button(card, "-", "Stone", function()
		collapsed = true
		render()
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 2), Size = UDim2.fromOffset(44, 44), TextSize = 28, ZIndex = 6 })
	claimBtn = Kit.Button(card, "Claim!", "Sun", function()
		if claimId ~= nil and Net.Do("ClaimQuest", nil, claimId) then
			Kit.Sound("QuestComplete")
		end
	end, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(160, 50),
		Visible = false,
		Pulse = true,
		ZIndex = 6,
	})
	chip = Kit.IconButton(holder, "Quest", "Quest", "Coral", function()
		collapsed = false
		render()
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(56, 56), Visible = false })
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
end

function QuestCard.Enable(on: boolean)
	enabled = on
	render()
end

-- Tutorial goal text (nil = back to daily quests).
function QuestCard.SetGoal(title: string?, text: string?, progress: number?)
	if title then
		override = { title = title, text = text or "", progress = progress or 0 }
		collapsed = false
	else
		override = nil
	end
	render()
end

-- Build mode slides the card away (guide §7).
function QuestCard.SetHidden(on: boolean)
	hidden = on
	render()
end

return QuestCard
