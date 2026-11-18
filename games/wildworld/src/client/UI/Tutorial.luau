--!strict
-- First 60 seconds (spec "Core loop"): at first nothing but an arrow + a big "Hatch!" button.
-- Then Feed it -> Coins chip fades in -> Build button + "Place a tree" with the rating strip ->
-- quest card "Catch a wild friend" + arrow to the forest gate. One new HUD button per goal; the
-- full menu after 2 creatures. The step is derived from server data (display only).
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local SideBar = require(script.Parent:WaitForChild("SideBar"))
local QuestCard = require(script.Parent:WaitForChild("QuestCard"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))
local BuildTray = require(script.Parent:WaitForChild("BuildTray"))
local WorldQuery = require(script.Parent:WaitForChild("WorldQuery"))
local Arrows = require(script.Parent:WaitForChild("Arrows"))

local Tutorial = {}

local hint: Frame
local hintText: TextLabel
local bigBtn: TextButton
local bigAction: (() -> ())? = nil
local fedLocal = false
local step = 0

-- 1 Hatch · 2 Feed · 3 Place a tree · 4 Catch a wild friend · 5 done
local function computeStep(): number
	-- Server's TutorialStep attribute (1 Hatch, 2 Feed, 3 Tree, 4 Catch, 5 Breed, 6 done) wins.
	local attr = tonumber((game:GetService("Players").LocalPlayer :: Player):GetAttribute("TutorialStep"))
	if attr then
		return math.clamp(math.floor(attr), 1, 5)
	end
	local flags = State.Tbl("flags")
	if flags.tutorialDone == true or (tonumber(flags.tutorialStep) or 0) >= 5 then
		return 5
	end
	local creatures = Derived.Creatures()
	if #creatures >= 2 then
		return 5
	end
	if #creatures == 0 then
		return 1
	end
	local fed = fedLocal or flags.fed == true or (tonumber(flags.tutorialStep) or 0) >= 3
	if not fed then
		return 2
	end
	local placedDecor = flags.placedTree == true or (tonumber(flags.tutorialStep) or 0) >= 4
	if not placedDecor then
		for _, it in State.Tbl("plot").items or {} do
			if type(it) == "table" and not string.find(string.lower(tostring(it.id)), "pad", 1, true) then
				placedDecor = true
			end
		end
	end
	return if placedDecor then 4 else 3
end

local function unlockFor(s: number, quiet: boolean)
	if s >= 2 then
		SideBar.Unlock("Collection", quiet)
	end
	if s >= 3 then
		Hud.Show("Coins")
		SideBar.Unlock("Build", quiet)
	end
	if s >= 4 then
		SideBar.Unlock("Journal", quiet)
		QuestCard.Enable(true)
	end
	if s >= 5 then
		for _, n in { "Breed", "Inventory", "Park" } do
			SideBar.Unlock(n, quiet)
		end
		Hud.Show("Coins")
		Hud.Show("RP")
		Hud.Show("Level")
		Hud.Show("TopRow")
		QuestCard.Enable(true)
	end
end

local function setBig(text: string?, color: string?, fn: (() -> ())?)
	bigAction = fn
	if not text or BuildMode.IsActive() or Windows.AnyOpen() then
		bigBtn.Visible = false
		return
	end
	bigBtn.Text = text
	Kit.SetButtonColor(bigBtn, color or "Sun")
	bigBtn.Visible = true
end

local function update()
	if not State.loaded then
		return
	end
	local s = computeStep()
	if s ~= step then
		local first = step == 0
		step = s
		unlockFor(s, first)
		if not first and s > 1 then
			Kit.Sound("QuestComplete")
		end
	end
	local building = BuildMode.IsActive()
	local text: string? = nil
	if s == 1 then
		text = "Your egg is ready - tap Hatch!"
		local eggs = Derived.Eggs()
		local egg = WorldQuery.MyEgg()
		Arrows.World(egg)
		Arrows.Ui(nil)
		setBig("Hatch!", "Sun", function()
			local id = if eggs[1] then eggs[1].id elseif egg then egg:GetAttribute("EggId") else nil
			Net.Do("HatchEgg", nil, id)
		end)
	elseif s == 2 then
		local c = Derived.Creatures()[1]
		local model = WorldQuery.MyCreature(c and c.uid)
		local at: Vector3? = if model then WorldQuery.Pos(model) else nil
		local me = WorldQuery.MyPos()
		-- Server feed range (CreatureAI.Distance <= Needs.InteractRange); 2 studs margin for lag.
		local range = (tonumber(Derived.Config.Needs and Derived.Config.Needs.InteractRange) or 30) - 2
		local near = at ~= nil and me ~= nil and (at - me).Magnitude <= range
		Arrows.World(model)
		Arrows.Ui(nil)
		if near then
			text = "Your baby is hungry - feed it!"
			setBig("Feed it", "Leaf", function()
				if c and Net.Do("FeedCreature", nil, c.uid) then
					fedLocal = true
					Kit.Sound("Feed")
				end
			end)
		else
			text = "Walk to your baby - follow the arrow!"
			setBig("Walk closer", "Disabled", function()
				Kit.Sound("Error")
				Net.Toast("Walk to your creature first!", "error")
			end)
		end
	elseif s == 3 then
		setBig(nil)
		Arrows.World(nil)
		if building then
			text = "Pick the Tree and place it in your park - watch the rating jump!"
			BuildTray.HighlightItem("TreeOak")
			Arrows.Ui(nil)
		else
			text = "Visitors pay more for pretty parks. Tap Build!"
			Arrows.Ui(SideBar.Button("Build"))
		end
	elseif s == 4 then
		setBig(nil)
		BuildTray.HighlightItem(nil)
		Arrows.Ui(nil)
		Arrows.World(if building then nil else WorldQuery.Landmark("ForestGate"))
		QuestCard.SetGoal("Catch a wild friend", "Head through the gate into Greenleaf Forest and catch a creature.", 0)
		text = nil
	else
		setBig(nil)
		Arrows.World(nil)
		Arrows.Ui(nil)
		if not Derived.Flag("goldenGiven") and #Derived.Creatures() >= 2 and #Derived.Eggs() == 0 then
			local jp = 0
			for _, def in Derived.SpeciesList() do
				if Derived.JournalStep(def.name) >= 2 then
					jp += 1
				end
			end
			QuestCard.SetGoal(
				"Breed your first egg",
				string.format("Breed two of the same species - your first egg is GOLDEN! Journal %d/%d", jp, #Derived.SpeciesList()),
				0
			)
		else
			QuestCard.SetGoal(nil)
		end
	end
	hint.Visible = text ~= nil and not building and not Windows.AnyOpen()
	if text then
		hintText.Text = text
	end
end

function Tutorial.Step(): number
	return step
end

function Tutorial.MarkFed()
	fedLocal = true
end

function Tutorial.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	hint = Kit.Make("Frame", {
		Name = "TutorialHint",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(620, 64),
		Visible = false,
	}, root)
	local face = Kit.Slab(hint, Style.Pal.Body, 99, 5, 3.5)
	hintText = Kit.Label(face, "", { Size = UDim2.new(1, -40, 1, -8), Position = UDim2.fromOffset(20, 4), TextSize = 26, ZIndex = 4 })
	bigBtn = Kit.Button(root, "Hatch!", "Sun", function()
		local fn = bigAction
		if fn then
			fn()
		end
	end, {
		Name = "TutorialAction",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(300, 92),
		TextSize = 44,
		Pulse = true,
		Shine = true,
		Visible = false,
	})
	Arrows.Mount(gui)
	task.spawn(function()
		while true do
			local ok, err = pcall(update)
			if not ok then
				warn("[UI] tutorial:", err)
			end
			task.wait(0.25)
		end
	end)
end

return Tutorial
