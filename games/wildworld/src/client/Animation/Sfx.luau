--!strict
-- Optional sound cues for animation moments, through Audio's SoundController.PlayAt (Shared/Sounds names).
-- Safe if Audio is missing; throttled per name; only near the camera.
local Sfx = {}

local controller: any = nil
local looked = false
local last: { [string]: number } = {}
local MAX_DIST = 50

local function get(): any
	if not looked then
		looked = true
		pcall(function()
			local audio = script.Parent.Parent:FindFirstChild("Audio")
			local mod = audio and audio:FindFirstChild("SoundController")
			if mod and mod:IsA("ModuleScript") then
				controller = require(mod) :: any
			end
		end)
	end
	return controller
end

function Sfx.At(name: string, pos: Vector3, minGap: number?)
	local now = os.clock()
	if now - (last[name] or 0) < (minGap or 0.15) then
		return
	end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - pos).Magnitude > MAX_DIST then
		return
	end
	local sc = get()
	if sc and type(sc.PlayAt) == "function" then
		last[name] = now
		pcall(sc.PlayAt, name, pos)
	end
end

return Sfx
