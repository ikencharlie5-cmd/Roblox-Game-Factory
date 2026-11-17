--!strict
-- Safe remote calls. Works whether Gameplay made a remote a RemoteFunction or a RemoteEvent,
-- never hangs forever on a missing remote, and shows an error toast when the server says no.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent:WaitForChild("Kit"))

local Net = {}

local folder: Instance? = nil
local function getFolder(): Instance?
	if not folder then
		folder = ReplicatedStorage:WaitForChild("Remotes", 30)
	end
	return folder
end

function Net.Find(name: string, wait: number?): Instance?
	local f = getFolder()
	if not f then
		return nil
	end
	return f:FindFirstChild(name) or f:WaitForChild(name, wait or 5)
end

local notifyFn: ((string, string?) -> ())? = nil
function Net.SetNotifier(fn: (string, string?) -> ())
	notifyFn = fn
end

-- Interprets common server return shapes: (false, "msg"), {ok=false, msg=...}, nil.
local function interpret(a: any, b: any): (boolean, any)
	if a == false then
		return false, b
	end
	if type(a) == "table" and (a.ok == false or a.Ok == false or a.success == false) then
		return false, a.msg or a.message or a.error or a.reason
	end
	return true, if a == true and b ~= nil then b else a
end

-- Calls a client->server remote. Returns (ok, result-or-message, failedOnClient).
-- Server-side failures already Notify + play Error (Guard.Fail), so only client-side ones toast here.
function Net.Call(name: string, ...: any): (boolean, any, boolean?)
	local r = Net.Find(name)
	if not r then
		warn("[UI] missing remote", name)
		return false, "Not ready yet - try again!", true
	end
	if r:IsA("RemoteFunction") then
		local args = table.pack(...)
		local ok, a, b = pcall(function()
			return (r :: RemoteFunction):InvokeServer(table.unpack(args, 1, args.n))
		end)
		if not ok then
			warn("[UI]", name, "failed:", a)
			return false, "Something went wrong", true
		end
		return interpret(a, b)
	elseif r:IsA("RemoteEvent") then
		(r :: RemoteEvent):FireServer(...)
		return true, nil
	end
	return false, "Bad remote", true
end

-- Call + feedback: error toast/sound on client-side failure, optional success toast/sound.
function Net.Do(name: string, successText: string?, ...: any): (boolean, any)
	local ok, res, clientSide = Net.Call(name, ...)
	if not ok and clientSide then
		Kit.Sound("Error")
		if notifyFn then
			(notifyFn :: (string, string?) -> ())(if type(res) == "string" then res else "Can't do that yet", "error")
		end
	elseif ok and successText then
		Kit.Sound("Purchase")
		if notifyFn then
			(notifyFn :: (string, string?) -> ())(successText, "success")
		end
	end
	return ok, res
end

-- Connects to a server->client event once it exists.
function Net.On(name: string, fn: (...any) -> ())
	task.spawn(function()
		local r = Net.Find(name, 60)
		if r and r:IsA("RemoteEvent") then
			r.OnClientEvent:Connect(fn)
		elseif not r then
			warn("[UI] server event never appeared:", name)
		end
	end)
end

return Net
