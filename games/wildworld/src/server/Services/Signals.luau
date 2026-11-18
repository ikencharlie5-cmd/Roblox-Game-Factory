--!strict
-- Helper (not a service): tiny server-side event bus so services don't require each other in circles.
-- Events (args after player): Hatch(rec), Catch(rec), Breed(egg), Feed(uid), Pet(uid), Place(itemId),
-- Bait(baitId), Visit(ownerUserId), Earn(amount), PlotChanged(), CreaturesChanged(), LevelUp(level).
local Signals = {}

local handlers: { [string]: { (Player, ...any) -> () } } = {}

function Signals.On(name: string, fn: (Player, ...any) -> ())
	local list = handlers[name]
	if not list then
		list = {}
		handlers[name] = list
	end
	table.insert(list, fn)
end

-- Runs handlers synchronously (each pcall'd). Handlers must not yield.
function Signals.Fire(name: string, player: Player, ...: any)
	local list = handlers[name]
	if not list then
		return
	end
	for _, fn in list do
		local ok, err = pcall(fn, player, ...)
		if not ok then
			warn("[Signals]", name, "handler failed:", err)
		end
	end
end

return Signals
