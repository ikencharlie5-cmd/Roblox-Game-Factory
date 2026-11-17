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
local notify: ((string, string?) -> ())? = nil

function CreatureCard.SetNotifier(fn: (string, string?) -> ())
	notify = fn
end

local function needRow(order: number, ok: boolean, text: string, fix: (() -> ())?)
	local row = Kit.Make(
		"Frame",
		{ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.3, -4), LayoutOrder = order },
		needsBox
	)
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(0, 34) }, row)
	Kit.Label(row, if ok then "✅" else "❌", { Size = UDim2.fromScale(0.12, 1) })
	Kit.Label(row, text, {
		Size = UDim2.fromScale(if ok then 0.86 else 0.6, 1),
		Position = UDim2.fromScale(0.13, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Style.FontBody,
		TextColor3 = if ok then Style.Color.LeafDark else Style.Color.Ink,
	})
	if not ok and fix then
		Kit.Button(
			row,
			"🔧 Fix",
			Style.Color.Sun,
			fix,
			{ Size = UDim2.fromScale(0.25, 1), Position = UDim2.fromScale(0.74, 0) }
		)
	end
end

local function renderNeeds(item: any, s: any)
	Kit.Clear(needsBox)
	local r = Derived.NeedsFor(item)
	if not s or not r then
		Kit.Label(needsBox, "Needs loading...", { Size = UDim2.new(1, 0, 0.3, 0) })
		return
	end
	local padBiome = State.Tbl("padBiome")[item.pad] or "?"
	needRow(
		1,
		r.biome == true,
		string.format("%s %s exhibit (pad is %s)", Style.BiomeInfo(s.Biome).Icon, s.Biome, padBiome),
		function()
			Windows.Open("Build", { tab = "Exhibits", pad = item.pad, biome = s.Biome })
		end
	)
	needRow(2, r.decor == true, "🪴 " .. s.Decor .. " in this pad", function()
		Windows.Open("Build", { tab = "Decor", decor = s.Decor, pad = item.pad })
	end)
	if s.Buddy then
		needRow(3, r.buddy == true, "🤝 A " .. s.Buddy .. " buddy in this pad", function()
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
		thrivingLabel.Text = "✨ THRIVING! x1.5 income ✨"
		thrivingLabel.TextColor3 = Style.Color.LeafDark
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
	header.TextColor3 = Style.RarityColor(rarity)
	win.Title.Text = string.format("%s %s", Style.BiomeInfo(s and s.Biome).Icon, rarity)
	local stage, progress, left = Derived.Stage(item)
	local muts = Derived.Mutations(item)
	info.Text = string.format(
		"+$%s/s · %s%s",
		Format.Number(Derived.CreatureIncome(item)),
		if s then s.Role else "",
		if muts ~= "" then " · 🌈 " .. muts else ""
	)
	if progress >= 1 then
		stageLabel.Text = "🌳 Grown - earning!"
	else
		stageLabel.Text = string.format("🌱 %s - ready in %s", stage, Format.Time(left))
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
	Windows.Open("Creature", id)
end

function CreatureCard.Mount()
	win = Windows.Create("Creature", "Creature", Style.Color.Sky)
	local body = win.Body
	header = Kit.Label(body, "", { Size = UDim2.new(1, 0, 0.12, 0) })
	Kit.Make("UIStroke", { Thickness = 1.5, Color = Style.Color.Dark }, header)
	info = Kit.Label(body, "", {
		Size = UDim2.new(1, 0, 0.08, 0),
		Position = UDim2.fromScale(0, 0.13),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	stageLabel = Kit.Label(body, "", { Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.fromScale(0, 0.22) })
	_skip, setStage =
		Kit.Progress(body, Style.Color.Leaf, { Size = UDim2.new(1, 0, 0.05, 0), Position = UDim2.fromScale(0, 0.31) })
	thrivingLabel = Kit.Label(body, "", { Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.fromScale(0, 0.38) })
	needsBox = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.36, 0),
		Position = UDim2.fromScale(0, 0.47),
	}, body)
	Kit.List(needsBox, false, 4)

	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.14, 0),
		Position = UDim2.fromScale(0, 0.86),
	}, body)
	Kit.List(row, true, 6, true)
	local function act(text: string, color: Color3, order: number, fn: () -> ()): TextButton
		return Kit.Button(row, text, color, fn, { Size = UDim2.new(0.24, -6, 1, 0), LayoutOrder = order })
	end
	waterBtn = act("💦 Water", Style.Color.Sky, 1, function()
		Net.Do("Water", nil, currentId)
	end)
	tonicBtn = act("💧 Tonic", Style.Color.Purple, 2, function()
		Net.Do("UseHopeItem", "Grown instantly! 🌳", "GrowTonic", currentId)
	end)
	act("✋ Move", Style.Color.Wood, 3, function()
		BuildMode.Start({ mode = "move", ref = currentId, label = "Pick a new cell" })
	end)
	act("💰 Sell", Style.Color.Sun, 4, function()
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
