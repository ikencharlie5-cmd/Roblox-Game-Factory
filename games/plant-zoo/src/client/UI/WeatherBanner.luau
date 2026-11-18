--!strict
-- Top-centre weather banner: weather-coloured pill + 2-letter code badge, effect text and timer.
-- Clear skies show a grey "Next weather in" teaser.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))

local WeatherBanner = {}

local weatherBanner: Frame
local weatherFace: Frame
local weatherBadge: Frame
local weatherLabel: TextLabel
local lastWeatherKey = ""

local function pop(obj: Instance)
	local s = obj:FindFirstChild("Pop") :: UIScale?
	if s then
		s.Scale = 1.12
		Kit.Tween(s, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

function WeatherBanner.Mount(root: Instance)
	-- Weather banner (top-centre)
	weatherBanner = Kit.Make("Frame", {
		Name = "Weather",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(420, 58),
		Visible = false,
		ZIndex = 2,
	}, root)
	Kit.Make("UIScale", { Name = "Pop", Scale = 1 }, weatherBanner)
	weatherFace = Kit.Slab(weatherBanner, Style.Pal.Sky, 99, 4, 3.5, true)
	weatherBadge = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -6, 0.5, 0),
		Size = UDim2.fromOffset(62, 62),
		ZIndex = 4,
	}, weatherFace)
	weatherLabel = Kit.Title(weatherFace, "", Style.Pal.Sky.Dark, {
		Position = UDim2.fromOffset(62, 4),
		Size = UDim2.new(1, -76, 1, -8),
		TextSize = 24,
		ZIndex = 4,
	})
end

function WeatherBanner.Tick(now: number)
	-- Weather
	local w = State.weather
	local name = if type(w) == "table" then (w.name or w.Name) else nil
	local endsAt = if type(w) == "table" then (w.endsAt or w.EndsAt or 0) else 0
	local nextAt = if type(w) == "table" then (w.nextAt or w.NextAt or 0) else 0
	local key, text, pal, code
	if type(name) == "string" and name ~= "" and name ~= "Clear" and (endsAt == 0 or endsAt > now) then
		local info = Style.WeatherInfo(name)
		key, code, pal = "w" .. name, info.Code, Style.PaletteFor(info.Color)
		local timer = if endsAt > 0 then "  " .. Format.Time(endsAt - now) else ""
		text = string.format("%s! %s%s", name, info.Text, timer)
	elseif nextAt > now then
		-- Clear skies: small teaser so players stick around for the next event.
		key, code, pal = "next", "Wx", Style.Pal.Stone
		text = "Next weather in " .. Format.Time(nextAt - now)
	end
	if key then
		weatherLabel.Text = text
		if key ~= lastWeatherKey then
			lastWeatherKey = key
			Kit.SetGradient(weatherFace:FindFirstChildOfClass("UIGradient") :: UIGradient, pal)
			local stroke = weatherFace:FindFirstChildOfClass("UIStroke") :: UIStroke
			stroke.Color = pal.Dark
			local lip = weatherBanner:FindFirstChild("Lip") :: Frame
			lip.BackgroundColor3 = pal.Dark
			local textStroke = weatherLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
			textStroke.Color = pal.Dark
			Kit.Clear(weatherBadge)
			Kit.CodeBadge(weatherBadge, code, pal, { Size = UDim2.fromScale(1, 1) })
			weatherBanner.Visible = true
			pop(weatherBanner)
		end
	else
		weatherBanner.Visible = false
		lastWeatherKey = ""
	end
end

return WeatherBanner
