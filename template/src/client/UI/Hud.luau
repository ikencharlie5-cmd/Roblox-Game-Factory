--!strict
-- HUD built entirely in code. Scale-based so it works on phone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local SoundController = require(script.Parent.Parent:WaitForChild("Audio"):WaitForChild("SoundController"))

local Hud = {}

local gui: ScreenGui
local cashLabel: TextLabel
local toast: TextLabel

local function corner(parent: Instance, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

local function button(text: string, pos: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.14, 0, 0.07, 0)
	b.Position = pos
	b.BackgroundColor3 = color
	b.Text = text
	b.TextScaled = true
	b.Font = Enum.Font.FredokaOne
	b.TextColor3 = Color3.new(1, 1, 1)
	local min = Instance.new("UISizeConstraint")
	min.MinSize = Vector2.new(88, 44)
	min.Parent = b
	corner(b, 10)
	b.Parent = gui
	return b
end

function Hud.Mount()
	gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false

	cashLabel = Instance.new("TextLabel")
	cashLabel.Size = UDim2.new(0.22, 0, 0.08, 0)
	cashLabel.Position = UDim2.new(0.02, 0, 0.4, 0)
	cashLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	cashLabel.BackgroundTransparency = 0.2
	cashLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	cashLabel.Font = Enum.Font.FredokaOne
	cashLabel.TextScaled = true
	cashLabel.Text = "$0"
	corner(cashLabel, 12)
	cashLabel.Parent = gui

	local daily = button("Daily", UDim2.new(0.02, 0, 0.5, 0), Color3.fromRGB(255, 170, 40))
	daily.Activated:Connect(function()
		SoundController.Play("Click")
		Remotes.Event("ClaimDaily"):FireServer()
	end)

	toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(0.5, 0, 0.06, 0)
	toast.Position = UDim2.new(0.25, 0, -0.1, 0)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Font = Enum.Font.FredokaOne
	toast.TextScaled = true
	toast.Text = ""
	corner(toast, 10)
	toast.Parent = gui

	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
end

function Hud.SetData(data: { [string]: any })
	cashLabel.Text = "$" .. Format.Number(data.Cash)
	cashLabel.Size = UDim2.new(0.24, 0, 0.088, 0)
	TweenService:Create(cashLabel, TweenInfo.new(0.15), { Size = UDim2.new(0.22, 0, 0.08, 0) }):Play()
end

function Hud.Notify(text: string)
	toast.Text = text
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0.25, 0, 0.03, 0) })
		:Play()
	task.delay(2.5, function()
		if toast.Text == text then
			TweenService:Create(toast, TweenInfo.new(0.25), { Position = UDim2.new(0.25, 0, -0.1, 0) }):Play()
		end
	end)
end

return Hud
