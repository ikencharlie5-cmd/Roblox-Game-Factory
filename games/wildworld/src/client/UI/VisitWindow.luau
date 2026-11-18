--!strict
-- Visit list: everyone in the server with their park rating/likes (player attributes
-- ParkRating / Likes if the server sets them), Visit + Like buttons, and Return Home.
local Players = game:GetService("Players")

local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local VisitWindow = {}

local win: any
local list: ScrollingFrame
local me = Players.LocalPlayer :: Player
local liked: { [number]: boolean } = {}

local function render()
	if not Windows.IsOpen("Visit") then
		return
	end
	Kit.Clear(list)
	local others = Players:GetPlayers()
	table.sort(others, function(a, b)
		return (tonumber(a:GetAttribute("ParkRating")) or 0) > (tonumber(b:GetAttribute("ParkRating")) or 0)
	end)
	local order = 0
	for _, p in others do
		if p ~= me then
			order += 1
			local card = Kit.Panel(list, nil, { Size = UDim2.new(1, -12, 0, 84), LayoutOrder = order })
			local thumb = Kit.Make("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 6),
				Size = UDim2.fromOffset(70, 70),
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150",
				ZIndex = 3,
			}, card)
			Kit.Corner(thumb, 99)
			Kit.Label(card, p.DisplayName .. "'s park", {
				Position = UDim2.fromOffset(92, 6),
				Size = UDim2.new(1, -440, 0, 36),
				TextSize = 26,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			})
			Kit.Body(card, string.format("Rating %d  ·  %d likes", tonumber(p:GetAttribute("ParkRating")) or 0, tonumber(p:GetAttribute("Likes")) or 0), {
				Position = UDim2.fromOffset(92, 44),
				Size = UDim2.new(1, -440, 0, 28),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			})
			local uid = p.UserId
			Kit.Button(card, if liked[uid] then "Liked" else "Like", if liked[uid] then "Stone" else "Coral", function()
				if liked[uid] then
					return
				end
				if Net.Do("LikePark", "Liked!", uid) then
					liked[uid] = true
					Kit.Sound("Like")
					render()
				end
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -184, 0.5, 0), Size = UDim2.fromOffset(140, 60), ZIndex = 4 })
			Kit.Button(card, "Visit", "Teal", function()
				if Net.Do("VisitPlot", nil, uid) then
					Windows.Close()
				end
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(160, 60), ZIndex = 4 })
		end
	end
	if order == 0 then
		Kit.Body(list, "Nobody else is here yet - invite a friend to show off your park!", {
			Size = UDim2.new(1, 0, 0, 60),
			TextSize = 22,
		})
	end
end

function VisitWindow.Mount()
	win = Windows.Create("Visit", "Visit Parks", "Teal", "Visit", Vector2.new(820, 600))
	Kit.Button(win.Body, "Return to my park", "Leaf", function()
		if Net.Do("ReturnHome", nil) then
			Windows.Close()
		end
	end, { Size = UDim2.fromOffset(300, 60), TextSize = 24 })
	list = Kit.Scroll(win.Body, { Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 1, -74) })
	Kit.List(list, false, 10)
	Kit.Padding(list, 4)
	win.OnOpen = render
	Players.PlayerAdded:Connect(render)
	Players.PlayerRemoving:Connect(function()
		task.defer(render)
	end)
end

return VisitWindow
