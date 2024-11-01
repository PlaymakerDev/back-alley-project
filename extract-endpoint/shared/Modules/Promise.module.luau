-- Basic Promise module implementation
local Promise = {}
Promise.__index = Promise

function Promise.new(executor)
	local self = setmetatable({}, Promise)
	self._fulfilledCallbacks = {}
	self._rejectedCallbacks = {}
	self._status = "pending"
	self._value = nil

	local function resolve(value)
		if self._status == "pending" then
			self._status = "fulfilled"
			self._value = value
			for _, callback in ipairs(self._fulfilledCallbacks) do
				callback(value)
			end
		end
	end

	local function reject(reason)
		if self._status == "pending" then
			self._status = "rejected"
			self._value = reason
			for _, callback in ipairs(self._rejectedCallbacks) do
				callback(reason)
			end
		end
	end

	local success, err = pcall(function()
		executor(resolve, reject)
	end)

	if not success then
		reject(err)
	end

	return self
end

function Promise:andThen(onFulfilled, onRejected)
	return Promise.new(function(resolve, reject)
		local function handleFulfill(value)
			if type(onFulfilled) == "function" then
				local success, result = pcall(onFulfilled, value)
				if success then
					resolve(result)
				else
					reject(result)
				end
			else
				resolve(value)
			end
		end

		local function handleReject(reason)
			if type(onRejected) == "function" then
				local success, result = pcall(onRejected, reason)
				if success then
					resolve(result)
				else
					reject(result)
				end
			else
				reject(reason)
			end
		end

		if self._status == "fulfilled" then
			handleFulfill(self._value)
		elseif self._status == "rejected" then
			handleReject(self._value)
		else
			table.insert(self._fulfilledCallbacks, handleFulfill)
			table.insert(self._rejectedCallbacks, handleReject)
		end
	end)
end

function Promise:catch(onRejected)
	return self:andThen(nil, onRejected)
end

return Promise
