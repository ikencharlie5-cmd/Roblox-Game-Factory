--!strict
-- Visit + Like other zoos on this server, Go Home, and a server leaderboard tab.
-- Reads ReplicatedStorage.GameState attributes Plot<n>_OwnerUserId / _OwnerName / _Likes / _PadsOwned.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Plots = require(script.Parent:WaitForChild("Plots"))

local VisitWindow = {}

local list: ScrollingFrame
local tab = "Zoos"

local function stateFolder(): Instance?
	return ReplicatedStorage:FindFirstChild("GameState")
end

local function rowFrame(order: number): Frame
	local r = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order, Size = UDim2.new(1, -12, 0, 76) })
	Kit.Stagger(r)
	return r
end

local function renderZoos()
	local st = stateFolder()
	local mine = Plots.MyPlot()
	local count = 0
	for plot = 1, Derived.Config.Grid.PlotCount do
		local owner = if st then st:GetAttribute("Plot" .. plot .. "_OwnerUserId") else nil
		if type(owner) == "number" and owner ~= 0 then
			count += 1
			local name = (st :: Instance):GetAttribute("Plot" .. plot .. "_OwnerName") or "?"
			local likes = (st :: Instance):GetAttribute("Plot" .. plot .. "_Likes") or 0
			local pads = (st :: Instance):GetAttribute("Plot" .. plot .. "_PadsOwned") or 1
			local r = rowFrame(plot)
			Kit.Icon(r, "Visit", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(54, 54),
			})
			Kit.Label(r, string.format("%s's Zoo%s", tostring(name), if plot == mine then " (you)" else ""), {
				Size = UDim2.new(0.5, -74, 0, 34),
				Position = UDim2.fromOffset(74, 6),
				TextSize = 26,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Kit.Body(r, string.format("%s likes · %s pads", Format.Number(likes), tostring(pads)), {
				Size = UDim2.new(0.5, -74, 0, 26),
				Position = UDim2.fromOffset(74, 42),
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			if plot ~= mine then
				Kit.Button(r, "Visit", "Sky", function()
					if Net.Do("VisitPlot", nil, plot) then
						Windows.Close()
					end
				end, {
					AnchorPoint = Vector2.new(1, 0.5),
					Size = UDim2.new(0.21, 0, 0, 58),
					Position = UDim2.new(0.76, -6, 0.5, 0),
					TextSize = 24,
				})
				Kit.Button(r, "Like", "Pink", function()
					if Net.Do("LikeZoo", "Liked " .. tostring(name) .. "'s zoo!", plot) then
						VisitWindow.Render()
					end
				end, {
					AnchorPoint = Vector2.new(1, 0.5),
					Size = UDim2.new(0.21, 0, 0, 58),
					Position = UDim2.new(1, -12, 0.5, 0),
					TextSize = 24,
				})
			end
		end
	end
	if count == 0 then
		Kit.Body(list, "No zoos yet...", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40) })
	end
end

-- Rank badge: gold / silver / bronze, then stone.
local function medal(r: Frame, rank: number)
	local pal = if rank == 1 then "Sun" elseif rank == 2 then "Stone" elseif rank == 3 then "Wood" else "Sky"
	Kit.CodeBadge(r, tostring(rank), Style.Pal[pal], {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(50, 50),
	})
end

local function stat(p: Player, key: string): number
	local ls = p:FindFirstChild("leaderstats")
	local v = if ls then ls:FindFirstChild(key) else nil
	return if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then v.Value else 0
end

local function renderTop()
	local players = Players:GetPlayers()
	table.sort(players, function(a, b)
		local ra, rb = stat(a, "Releases"), stat(b, "Releases")
		if ra ~= rb then
			return ra > rb
		end
		return stat(a, "Cash") > stat(b, "Cash")
	end)
	for i, p in players do
		local r = rowFrame(i)
		medal(r, i)
		Kit.Label(r, p.DisplayName, {
			Size = UDim2.new(0.5, -74, 0, 40),
			Position = UDim2.new(0, 74, 0.5, -20),
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Kit.Label(r, string.format("%d Releases · $%s", stat(p, "Releases"), Format.Number(stat(p, "Cash"))), {
			Size = UDim2.new(0.48, -16, 0, 36),
			Position = UDim2.new(0.5, 0, 0.5, -18),
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Style.Pal.Leaf.Dark,
		})
	end
	-- All-time Top 10 Total Earned (server JSON in GameState.TopEarned, refreshed every 60 s).
	local st = stateFolder()
	local top = if st then st:FindFirstChild("TopEarned") else nil
	local ok, rows = false, nil
	if top and top:IsA("StringValue") and top.Value ~= "" then
		ok, rows = pcall(function()
			return HttpService:JSONDecode(top.Value)
		end)
	end
	Kit.Label(list, "All-time Top 10 (total earned)", {
		LayoutOrder = 100,
		Size = UDim2.new(1, -12, 0, 36),
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	if ok and type(rows) == "table" then
		for i, e in rows do
			local r = rowFrame(100 + i)
			medal(r, tonumber(e.rank) or i)
			Kit.Label(r, tostring(e.name or "?"), {
				Size = UDim2.new(0.6, -74, 0, 40),
				Position = UDim2.new(0, 74, 0.5, -20),
				TextSize = 26,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Kit.Label(r, "$" .. Format.Number(tonumber(e.value) or 0), {
				Size = UDim2.new(0.38, -16, 0, 36),
				Position = UDim2.new(0.6, 0, 0.5, -18),
				TextSize = 26,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Style.Pal.Leaf.Dark,
			})
		end
	else
		Kit.Body(list, "Loading board...", {
			LayoutOrder = 101,
			Size = UDim2.new(1, -12, 0, 30),
		})
	end
end

function VisitWindow.Render()
	if not Windows.IsOpen("Visit") then
		return
	end
	Kit.Clear(list)
	if tab == "Zoos" then
		renderZoos()
	else
		renderTop()
	end
end

function VisitWindow.Mount()
	local win = Windows.Create("Visit", "Visit Zoos", "Sky", "Visit")
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0) }, top)
	local choose = Kit.Tabs(tabHolder, { "Zoos", "Top" }, function(name)
		tab = name
		VisitWindow.Render()
	end, "Sky")
	Kit.Button(top, "Go Home", "Leaf", function()
		if Net.Do("GoHome", nil) then
			Windows.Close()
		end
	end, { Size = UDim2.new(0.36, 0, 0, 56), Position = UDim2.new(0.64, 0, 0, 0), TextSize = 24, Lip = 4 })
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
	Kit.List(list, false, 10)
	Kit.Padding(list, 6)
	win.OnOpen = function()
		choose(tab)
	end
	task.spawn(function()
		local st = ReplicatedStorage:WaitForChild("GameState", 60)
		if st then
			st.AttributeChanged:Connect(function(attr)
				if string.sub(attr, 1, 4) == "Plot" then
					VisitWindow.Render()
				end
			end)
		end
	end)
end

return VisitWindow
