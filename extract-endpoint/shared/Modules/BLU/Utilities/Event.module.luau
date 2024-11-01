-- Module
local Event = {}

-- Instantiating
function Event.new()
	
	-- Creating New
	local self = setmetatable({}, {__index = Event})
	self.ConnectedFunctions = {}
	
	-- Returning
	return self
	
end

-- Firing
function Event:Fire(...)
	for i, func in pairs(self.ConnectedFunctions) do
		task.spawn(func, ...)
	end
end

-- Connecting
function Event:Connect(func)
	table.insert(self.ConnectedFunctions, func)
	return function()
		self:Disconnect(func)
	end
end

-- Waiting
function Event:Wait()
	local params = nil
	local function func(...)
		params = {...}
		self:Disconnect(func)
	end
	self:Connect(func)
	
	repeat task.wait() until params
	return table.unpack(params)
end

-- Disconnecting
function Event:Disconnect(func)
	table.remove(self.ConnectedFunctions, table.find(self.ConnectedFunctions, func))
end

-- Destroying
function Event:Destroy()
	for i, func in pairs(self.ConnectedFunctions) do
		self:Disconnect(func)
	end
end

-- Returning
return Event