--!strict
-- Collects every part CFrame written this frame and applies them in ONE workspace:BulkMoveTo.
local Batch = {}

local parts: { BasePart } = {}
local cfs: { CFrame } = {}
local n = 0

function Batch.Add(part: BasePart, cf: CFrame)
	n += 1
	parts[n] = part
	cfs[n] = cf
end

function Batch.Count(): number
	return n
end

function Batch.Flush()
	if n == 0 then
		return
	end
	if #parts > n then
		-- arrays must match exactly; trim leftovers from a bigger earlier frame
		for i = #parts, n + 1, -1 do
			parts[i] = nil
			cfs[i] = nil
		end
	end
	local ok = pcall(function()
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		-- a part was destroyed mid-frame: fall back to per-part writes for this frame
		for i = 1, n do
			local p = parts[i]
			if p.Parent then
				p.CFrame = cfs[i]
			end
		end
	end
	n = 0
end

return Batch
