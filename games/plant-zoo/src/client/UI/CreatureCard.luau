--!strict
-- Tap a plant/creature: rarity, stage + timer, $/s, mutations, needs checklist with one-tap Fix,
-- Water, Grow Tonic, Move, Sell. Also owns the "tap something in the world" picker.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))
local Plots = require(script.Parent:WaitForChild("Plots"))

local CreatureCard = {}
local _skip: any = nil -- sink for unused multiple-return values

local win: Windows.Win
local header: TextLabel
local info: TextLabel
local stageLabel: TextLabel
local setStage: (number) -> ()
local needsBox: Frame
local thrivingLabel: TextLabel
local waterBtn: TextButton
local tonicBtn: TextButton
local currentId: any = nil
local lastSig = ""
local lastView = ""
local picture: Frame
local notify: ((string, string?) -> ())? = nil

function CreatureCard.SetNotifier(fn: (string, string?) -> ())
	notify = fn
end

local function needRow(order: number, ok: boolean, text: string, fix: (() -> ())?)
	local row = Kit.Panel(needsBox, Style.Color.Panel, { Size = UDim2.new(1, -8, 0, 54), LayoutOrder = order })
	Kit.CodeBadge(row, if ok then "OK" else "X", if ok then Style.Pal.Leaf else Style.Pal.Red, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
	})
	Kit.Body(row, text, {
		Size = UDim2.new(1, if ok then -64 else -200, 1, -8),
		Position = UDim2.fromOffset(56, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = if ok then Style.Pal.Leaf.Dark else Style.Color.Ink,
	})
	if not ok and fix then
		Kit.Button(row, "Fix", "Sun", fix, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(120, 46),
			TextSize = 24,
			Lip = 4,
		})
	end
end

local function renderNeeds(item: any, s: any)
	Kit.Clear(needsBox)
	local r = Derived.NeedsFor(item)
	if not s or not r then
		Kit.Body(needsBox, "Needs loading...", { Size = UDim2.new(1, 0, 0, 40) })
		return
	end
	local padBiome = State.Tbl("padBiome")[item.pad] or "?"
	needRow(
		1,
		r.biome == true,
		string.format("%s exhibit (pad is %s)", s.Biome, padBiome),
		function()
			Windows.Open("Build", { tab = "Exhibits", pad = item.pad, biome = s.Biome })
		end
	)
	needRow(2, r.decor == true, s.Decor .. " in this pad", function()
		Windows.Open("Build", { tab = "Decor", decor = s.Decor, pad = item.pad })
	end)
	if s.Buddy then
		needRow(3, r.buddy == true, "A " .. s.Buddy .. " buddy in this pad", function()
			if notify then
				(notify :: (string, string?) -> ())(
					"Place any " .. s.Buddy .. " creature in Pad " .. tostring(item.pad),
					"info"
				)
			end
			Windows.Open("Index", { role = s.Buddy })
		end)
	end
	local met = r.met or 0
	local total = r.total or 0
	if r.thriving then
		thrivingLabel.Text = "THRIVING! x1.5 income"
		thrivingLabel.TextColor3 = Style.Pal.Leaf.Dark
	else
		thrivingLabel.Text = string.format("Needs %d/%d - meet all for Thriving x1.5", met, total)
		thrivingLabel.TextColor3 = Style.Color.InkSoft
	end
end

function CreatureCard.Update()
	if not Windows.IsOpen("Creature") or currentId == nil then
		return
	end
	local item = Derived.FindPlaced(currentId)
	if not item then
		Windows.Close()
		return
	end
	local s = Derived.Species(item.species)
	local rarity = if s then s.Rarity else "Common"
	header.Text = Derived.DisplayName(item)
	header.TextColor3 = Style.RarityDarkColor(rarity)
	win.Title.Text = Style.NormRarity(rarity) .. (if s then " · " .. tostring(s.Biome) else "")
	local stage, progress, left = Derived.Stage(item)
	-- Picture: rebuild only when species/stage changes (cached models, cheap clone).
	local viewKey = tostring(item.species) .. "|" .. (if progress >= 1 then "Grown" else tostring(stage))
	if viewKey ~= lastView then
		lastView = viewKey
		Kit.Clear(picture)
		local card = Kit.Card(picture, rarity, { Size = UDim2.fromScale(1, 1) })
		Kit.CreatureView(card, tostring(item.species), if progress >= 1 then "Grown" else tostring(stage), {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 1, -44),
			ZIndex = 2,
		})
	end
	local muts = Derived.Mutations(item)
	info.Text = string.format(
		"+$%s/s · %s%s",
		Format.Number(Derived.CreatureIncome(item)),
		if s then s.Role else "",
		if muts ~= "" then " · " .. muts else ""
	)
	if progress >= 1 then
		stageLabel.Text = "Grown - earning!"
	else
		stageLabel.Text = string.format("%s - ready in %s", stage, Format.Time(left))
	end
	setStage(progress)
	waterBtn.Visible = progress < 1
	tonicBtn.Visible = progress < 1 and State.Num("tonics") > 0
	local sig = Kit.Sig({ State.data.padBiome, State.data.decor, #State.Tbl("placed"), progress >= 1, item.pad })
	if sig ~= lastSig then
		lastSig = sig
		renderNeeds(item, s)
	end
end

function CreatureCard.Open(id: any)
	currentId = id
	lastSig = ""
	lastView = ""
	Windows.Open("Creature", id)
end

function CreatureCard.Mount()
	win = Windows.Create("Creature", "Creature", "Sky", nil, Vector2.new(840, 580))
	local body = win.Body
	picture = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 250, 1, -86),
	}, body)
	local right = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(266, 0),
		Size = UDim2.new(1, -266, 1, -86),
	}, body)
	header = Kit.Label(right, "", { Size = UDim2.new(1, 0, 0, 44), TextSize = 38 })
	info = Kit.Body(right, "", { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 28), TextSize = 22 })
	stageLabel = Kit.Label(right, "", { Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 30), TextSize = 24 })
	_skip, setStage = Kit.Progress(right, "Leaf", { Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 0, 20) })
	thrivingLabel = Kit.Label(right, "", { Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 30), TextSize = 24 })
	needsBox = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 174),
		Size = UDim2.new(1, 0, 1, -174),
	}, right)
	Kit.List(needsBox, false, 8)

	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 72),
	}, body)
	Kit.List(row, true, 14, true)
	local function act(text: string, color: any, order: number, fn: () -> ()): TextButton
		return Kit.Button(row, text, color, fn, { Size = UDim2.fromOffset(176, 68), LayoutOrder = order })
	end
	waterBtn = act("Water", "Sky", 1, function()
		Net.Do("Water", nil, currentId)
	end)
	tonicBtn = act("Tonic", "Purple", 2, function()
		Net.Do("UseHopeItem", "Grown instantly!", "GrowTonic", currentId)
	end)
	act("Move", "Wood", 3, function()
		BuildMode.Start({ mode = "move", ref = currentId, label = "Pick a new cell" })
	end)
	act("Sell", "Sun", 4, function()
		local item = Derived.FindPlaced(currentId)
		if not item then
			return
		end
		local value = Derived.SellValue(item)
		Windows.Confirm(
			"Sell " .. tostring(item.species) .. "?",
			"You get $" .. Format.Number(value) .. ". It's gone for good!",
			"Sell",
			function()
				if Net.Do("SellCreature", nil, item.id) then
					Windows.Close()
				end
			end
		)
	end)

	win.OnOpen = function()
		CreatureCard.Update()
	end
	task.spawn(function()
		while true do
			CreatureCard.Update()
			task.wait(0.5)
		end
	end)

	-- Tap one of your plants/creatures in the world (not in build mode) to open its card.
	local function tap(pos: Vector2)
		if BuildMode.IsActive() then
			return
		end
		local res = Plots.Raycast(pos, false, {})
		local model, id = Plots.ItemFromHit(if res then res.Instance else nil)
		if model and id and Plots.IsMine(model) and model:GetAttribute("Kind") ~= "decor" then
			Kit.Sound("Click")
			CreatureCard.Open(id)
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			tap(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UserInputService.TouchTap:Connect(function(positions, processed)
		if not processed and positions[1] then
			tap(Vector2.new(positions[1].X, positions[1].Y))
		end
	end)
end

return CreatureCard
