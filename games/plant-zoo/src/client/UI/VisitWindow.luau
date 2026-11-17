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
	return Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 60) })
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
			Kit.Label(r, string.format("🏡 %s's Zoo%s", tostring(name), if plot == mine then " (you)" else ""), {
				Size = UDim2.new(0.5, -8, 0.55, 0),
				Position = UDim2.new(0, 8, 0, 2),
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Kit.Label(r, string.format("❤️ %s   🌿 %s pads", Format.Number(likes), tostring(pads)), {
				Size = UDim2.new(0.5, -8, 0.38, 0),
				Position = UDim2.new(0, 8, 0.58, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Style.FontBody,
				TextColor3 = Style.Color.InkSoft,
			})
			if plot ~= mine then
				Kit.Button(r, "🚶 Visit", Style.Color.Sky, function()
					if Net.Do("VisitPlot", nil, plot) then
						Windows.Close()
					end
				end, { Size = UDim2.new(0.22, 0, 0, 48), Position = UDim2.new(0.52, 0, 0.5, -24) })
				Kit.Button(r, "❤️ Like", Style.Color.Pink, function()
					if Net.Do("LikeZoo", "❤️ Liked " .. tostring(name) .. "'s zoo!", plot) then
						VisitWindow.Render()
					end
				end, { Size = UDim2.new(0.22, 0, 0, 48), Position = UDim2.new(0.76, 0, 0.5, -24) })
			end
		end
	end
	if count == 0 then
		Kit.Label(list, "No zoos yet...", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40) })
	end
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
		local medal = ({ "🥇", "🥈", "🥉" })[i] or ("#" .. i)
		Kit.Label(r, medal .. " " .. p.DisplayName, {
			Size = UDim2.new(0.5, -8, 0.8, 0),
			Position = UDim2.new(0, 8, 0.1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Kit.Label(r, string.format("🕊️ %d   💵 $%s", stat(p, "Releases"), Format.Number(stat(p, "Cash"))), {
			Size = UDim2.new(0.48, -8, 0.6, 0),
			Position = UDim2.new(0.5, 0, 0.2, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Style.Color.LeafDark,
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
	Kit.Label(list, "🏆 All-time Top 10 (total earned)", {
		LayoutOrder = 100,
		Size = UDim2.new(1, -8, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	if ok and type(rows) == "table" then
		for i, e in rows do
			local r = rowFrame(100 + i)
			Kit.Label(r, string.format("#%s %s", tostring(e.rank or i), tostring(e.name or "?")), {
				Size = UDim2.new(0.6, -8, 0.8, 0),
				Position = UDim2.new(0, 8, 0.1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Kit.Label(r, "$" .. Format.Number(tonumber(e.value) or 0), {
				Size = UDim2.new(0.38, -8, 0.6, 0),
				Position = UDim2.new(0.6, 0, 0.2, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Style.Color.LeafDark,
			})
		end
	else
		Kit.Label(list, "Loading board...", {
			LayoutOrder = 101,
			Size = UDim2.new(1, -8, 0, 30),
			Font = Style.FontBody,
			TextColor3 = Style.Color.InkSoft,
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
	local win = Windows.Create("Visit", "🏡 Visit Zoos", Style.Color.Sky)
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0) }, top)
	local choose = Kit.Tabs(tabHolder, { "Zoos", "Top" }, function(name)
		tab = name
		VisitWindow.Render()
	end)
	Kit.Button(top, "🏠 Go Home", Style.Color.Leaf, function()
		if Net.Do("GoHome", nil) then
			Windows.Close()
		end
	end, { Size = UDim2.new(0.36, 0, 1, 0), Position = UDim2.new(0.64, 0, 0, 0) })
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52) })
	Kit.List(list, false, 6)
	Kit.Padding(list, 4)
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
