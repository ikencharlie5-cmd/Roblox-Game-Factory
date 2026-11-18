--!strict
-- Client-side mirror of what the server sends (DataChanged / StockChanged / WeatherChanged).
-- Display only: the client never decides outcomes.
local State = {}

State.data = {} :: { [string]: any }
State.stock = nil :: any
State.weather = nil :: any
State.loaded = false

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event -- (what: "data" | "stock" | "weather")

function State.Fire(what: string)
	changed:Fire(what)
end

-- Reads a field, accepting camelCase or PascalCase from the server.
function State.Get(key: string, t: { [string]: any }?): any
	local d = t or State.data
	local v = d[key]
	if v == nil then
		v = d[string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)]
	end
	if v == nil then
		v = d[string.lower(string.sub(key, 1, 1)) .. string.sub(key, 2)]
	end
	return v
end

function State.Num(key: string, t: { [string]: any }?): number
	local v = State.Get(key, t)
	return if type(v) == "number" then v else 0
end

function State.Tbl(key: string, t: { [string]: any }?): { [any]: any }
	local v = State.Get(key, t)
	return if type(v) == "table" then v else {}
end

function State.Now(): number
	return workspace:GetServerTimeNow()
end

function State.SetData(data: any)
	if type(data) ~= "table" then
		return
	end
	State.data = data
	State.loaded = true
	changed:Fire("data")
end

function State.OnChange(fn: (string) -> ()): RBXScriptConnection
	return changed.Event:Connect(fn)
end

return State
