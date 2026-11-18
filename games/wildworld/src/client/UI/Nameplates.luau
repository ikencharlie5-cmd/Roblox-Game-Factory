--!strict
-- Over-creature nameplates (guide §3) for your own creatures: name (FredokaOne 22, dark stroke),
-- up to 3 mutation dots and a heart chip that turns red under 30% happiness. MaxDistance 40,
-- not AlwaysOnTop, all hidden while a window is open. Reads creature attributes only.
local Players = game:GetService("Players")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local WorldQuery = require(script.Parent:WaitForChild("WorldQuery"))

local Nameplates = {}

local folder: Instance
local plates: { [Instance]: { gui: BillboardGui, sig: string } } = {}

local function info(model: Instance): (string, { string }, number)
	local uid = model:GetAttribute("Uid")
	local c = if uid ~= nil then Derived.Creature(uid) else nil
	if c then
		return Derived.Name(c), Derived.Muts(c), Derived.Happy(c)
	end
	local muts = {}
	local m = model:GetAttribute("Mutations")
	if type(m) == "string" and m ~= "" then
		for part in string.gmatch(m, "[^,]+") do
			table.insert(muts, part)
		end
	end
	local name = model:GetAttribute("Nickname") or model:GetAttribute("Species") or "Creature"
	return tostring(name), muts, tonumber(model:GetAttribute("Happy")) or 100
end

local function render(gui: BillboardGui, name: string, muts: { string }, happy: number)
	Kit.Clear(gui)
	Kit.Title(gui, name, Style.Color.Chip, {
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 22,
		StrokeThickness = 2.5,
	})
	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 20),
	}, gui)
	Kit.List(row, true, 4, true)
	for i, m in muts do
		if i > 3 then
			break
		end
		Kit.MutationBadge(row, m, 18, { LayoutOrder = i })
	end
	local pal = if happy < 30 then Style.Pal.Red else Style.Pal.Coral
	local heart = Kit.CodeBadge(row, "<3", pal, { Size = UDim2.fromOffset(20, 20), LayoutOrder = 10 })
	heart.Visible = happy < 30 or #muts == 0
end

local function refresh()
	local hidden = Windows.AnyOpen()
	local seen: { [Instance]: boolean } = {}
	for _, model in WorldQuery.Creatures() do
		if WorldQuery.IsMine(model) then
			seen[model] = true
			local adornee = if model:IsA("Model") then (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) else model
			local entry = plates[model]
			if not entry then
				local gui = Kit.Make("BillboardGui", {
					Name = "Plate",
					Size = UDim2.fromOffset(180, 50),
					StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
					MaxDistance = 40,
					AlwaysOnTop = false,
					LightInfluence = 0,
					ResetOnSpawn = false,
				}, folder)
				entry = { gui = gui, sig = "" }
				plates[model] = entry
			end
			local e = entry :: { gui: BillboardGui, sig: string }
			e.gui.Adornee = adornee :: any
			e.gui.Enabled = not hidden
			local name, muts, happy = info(model)
			local sig = name .. table.concat(muts, ",") .. (if happy < 30 then "!" else "")
			if sig ~= e.sig then
				e.sig = sig
				render(e.gui, name, muts, happy)
			end
		end
	end
	for model, e in plates do
		if not seen[model] or not model.Parent then
			e.gui:Destroy()
			plates[model] = nil
		end
	end
end

function Nameplates.Mount()
	local player = Players.LocalPlayer :: Player
	folder = player:WaitForChild("PlayerGui")
	task.spawn(function()
		while true do
			pcall(refresh)
			task.wait(0.5)
		end
	end)
end

return Nameplates
