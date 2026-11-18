--!strict
-- Handed over to the Animation branch: all creature/visitor motion now runs on the CLIENT
-- (src/client/Animation). This module keeps its old API so World callers don't change:
--   Creature / Pop -> no-ops (clients bob, wander, pop and celebrate from the replicated Visual + attributes)
--   SetVisitors    -> only publishes Count + Origin attributes on the plot's Visitors folder;
--                     each client spawns and walks its own visitors (Animation/Visitors.luau).
local Motion = {}

function Motion.Creature(_model: Model, _padTop: CFrame, _home: CFrame, _half: number?) end

function Motion.Pop(_model: Model) end

function Motion.SetVisitors(folder: Folder, _plotModel: Model, plotCf: CFrame, n: number)
	for _, c in folder:GetChildren() do
		c:Destroy() -- old server-side visitors (none are created any more)
	end
	folder:SetAttribute("Origin", plotCf)
	folder:SetAttribute("Count", n)
end

return Motion
