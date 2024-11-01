-- Services
local RunService = game:GetService("RunService")
local HS = game:GetService("HttpService")

-- Module
local Transverse = {}

-- Server Functionality
if RunService:IsServer() then
	
	-- Creating Service
	function Transverse.CreateService(name: string)
		if script.Services:FindFirstChild(name) then
			error("Cannot create duplicate service of name \"" .. name .. "\"")
		end
		
		-- Creating Service Object
		local service = Instance.new("Configuration")
		service.Name = name
		service:SetAttribute("Ready", false)
		
		local eventsF = Instance.new("Folder", service)
		eventsF.Name = "Events"
		
		local methodsF = Instance.new("Folder", service)
		methodsF.Name = "Methods"
		
		local propertiesF = Instance.new("Folder", service)
		propertiesF.Name = "Properties"
		
		service.Parent = script.Services
		
		-- Default Methods
		Transverse.CreateMethod(name, "CreateMethod", 1, function(self, methodName: string, serverClientIndex: number, methodCallback)
			Transverse.CreateMethod(self.Name, methodName, serverClientIndex, methodCallback)
		end)
		Transverse.CreateMethod(name, "CreateEvent", 1, function(self, eventName: string, serverClientIndex: number)
			Transverse.CreateEvent(self.Name, eventName, serverClientIndex)
		end)
		Transverse.CreateMethod(name, "CreateProperty", 1, function(self, propName: string, serverClientIndex: number, readOnlyIndex: number)
			Transverse.CreateProperty(self.Name, propName, serverClientIndex, readOnlyIndex)
		end)
		Transverse.CreateMethod(name, "Ready", 1, function(self)
			service:SetAttribute("Ready", true)
		end)
		
		-- Getting Service
		return Transverse.GetService(name, nil, false)
		
	end
	
	-- Creating Method
	function Transverse.CreateMethod(serviceName: string, methodName: string, serverClientIndex: number, methodCallback) -- SCI - 0:Client 1:Server 2:Both
		if not script.Services:FindFirstChild(serviceName) then
			error("Cannot create method of service \"" .. serviceName .. "\" because it does not exist")
		end
		
		-- Finding Methods folder
		local methodsF = script.Services[serviceName].Methods
		if methodsF:FindFirstChild(methodName) then
			error("Cannot create duplicate method of name \"" .. methodName .. "\" in service \"" .. serviceName .. "\"")
		end
		
		-- Checking Server Client Index
		local onServer = false
		local onClient = false
		
		if serverClientIndex == 0 then
			onClient = true
		elseif serverClientIndex == 1 then
			onServer = true
		elseif serverClientIndex == 2 then
			onServer = true
			onClient = true
		end
		
		-- Creating Remotes
		if onClient then
			
			-- Creating
			local methodRemote = Instance.new("RemoteFunction")
			methodRemote.Name = methodName .. "Remote"
			methodRemote.Parent = methodsF
			
			-- Connecting
			methodRemote.OnServerInvoke = function(player, ...)
				return methodCallback(player, ...)
			end
			
		end
		if onServer then
			
			-- Creating
			local methodBindable = Instance.new("BindableFunction")
			methodBindable.Name = methodName .. "Bindable"
			methodBindable.Parent = methodsF
			
			-- Connecting
			methodBindable.OnInvoke = methodCallback
			
		end
		
	end
	
	-- Creating Event
	function Transverse.CreateEvent(serviceName: string, eventName: string, serverClientIndex: number) -- SCI - 0:Client 1:Server 2:Both
		if not script.Services:FindFirstChild(serviceName) then
			error("Cannot create event of service \"" .. serviceName .. "\" because it does not exist")
		end
		
		-- Finding Events folder
		local eventsF = script.Services[serviceName].Events
		if eventsF:FindFirstChild(eventName) then
			error("Cannot create duplicate event of name \"" .. eventName .. "\" in service \"" .. serviceName .. "\"")
		end
		
		-- Checking Server Client Index
		local onServer = false
		local onClient = false
		
		if serverClientIndex == 0 then
			onClient = true
		elseif serverClientIndex == 1 then
			onServer = true
		elseif serverClientIndex == 2 then
			onServer = true
			onClient = true
		end
		
		-- Creating Remotes
		if onClient then
			
			-- Creating
			local eventRemote = Instance.new("RemoteEvent")
			eventRemote.Name = eventName .. "Remote"
			eventRemote.Parent = eventsF
			
		end
		if onServer then
			
			-- Creating
			local eventBindable = Instance.new("BindableEvent")
			eventBindable.Name = eventName .. "Bindable"
			eventBindable.Parent = eventsF
			
		end
		
	end
	
	-- Creating Property
	function Transverse.CreateProperty(serviceName: string, propName: string, serverClientIndex: number, initValue: any) -- SCI - 1:Server 2:Both
		if not script.Services:FindFirstChild(serviceName) then
			error("Cannot create property of service \"" .. serviceName .. "\" because it does not exist")
		end
		
		-- Finding Properties folder
		local propertiesF = script.Services[serviceName].Properties
		if propertiesF:FindFirstChild(propName) then
			error("Cannot create duplicate property of name \"" .. propName .. "\" in service \"" .. serviceName .. "\"")
		end
		
		-- Adjusting Tables
		local initValue = initValue
		if typeof(initValue) == "table" then
			initValue = HS:JSONEncode(initValue)
		end
		
		-- Adding Property
		local prop = Instance.new("IntValue")
		prop.Name = propName
		prop.Value = serverClientIndex
		prop:SetAttribute("Value", initValue)
		prop.Parent = propertiesF
		
	end
	
end

-- Both Functionality
function Transverse.GetService(name: string, timeout: number?, needsReady: boolean?)
	
	-- Finding Service
	local service = nil
	local startTime = os.clock()
	local timeout = timeout or 20
	
	-- Warning
	task.delay(timeout, function()
		if not service then
			_G.Warn("Inifinite yield warning: No service was found by the name \"" .. name .. "\" after the timeout time, " .. timeout .. "s")
		end
	end)
	
	-- Searching
	repeat wait()
		service = script.Services:FindFirstChild(name)
	until service
	
	local needsReady = if needsReady == nil then true else needsReady
	if needsReady then
		repeat wait() until service:GetAttribute("Ready")
	end
	
	-- Creating Table
	local serviceTable = {}
	serviceTable.Name = service.Name
	
	-- Adding Methods
	for i, fireable in pairs(service.Methods:GetChildren()) do
		if fireable.ClassName == "RemoteFunction" and RunService:IsClient() then
			local methodName = string.gsub(fireable.Name, "Remote", "")
			serviceTable[methodName] = function(self, ...)
				return fireable:InvokeServer(self, ...)
			end
		elseif fireable.ClassName == "BindableFunction" and RunService:IsServer() then
			local methodName = string.gsub(fireable.Name, "Bindable", "")
			serviceTable[methodName] = function(self, ...)
				return fireable:Invoke(self, ...)
			end
		end
	end
	
	-- Adding Events
	for i, fireable in pairs(service.Events:GetChildren()) do
		if fireable.ClassName == "RemoteEvent" and RunService:IsClient() then
			
			-- Getting Service Event
			local eventName = string.gsub(fireable.Name, "Remote", "")
			if not serviceTable[eventName] then
				serviceTable[eventName] = {}
			end
			
			-- Adding Methods
			local startTime = os.clock()
			serviceTable[eventName].Connect = function(self, callback)
				local connection = fireable.OnClientEvent:Connect(function(t, ...)
					if t < startTime then return end
					callback(...)
				end)
				return connection
			end
			serviceTable[eventName].Wait = function(self)
				return fireable.OnClientEvent:Wait()
			end
			
		elseif fireable.ClassName == "RemoteEvent" and RunService:IsServer() then
			
			-- Getting Service Event
			local eventName = string.gsub(fireable.Name, "Remote", "")
			if not serviceTable[eventName] then
				serviceTable[eventName] = {}
			end
			
			-- Adding Methods
			serviceTable[eventName].FireAllClients = function(self, ...)
				fireable:FireAllClients(os.clock(), ...)
			end
			serviceTable[eventName].FireClient = function(self, player, ...)
				fireable:FireClient(player, os.clock(), ...)
			end
			
		elseif fireable.ClassName == "BindableEvent" and RunService:IsServer() then
			
			-- Getting Service Event
			local eventName = string.gsub(fireable.Name, "Bindable", "")
			if not serviceTable[eventName] then
				serviceTable[eventName] = {}
			end
			
			-- Adding Methods
			local startTime = os.clock()
			serviceTable[eventName].FireServer = function(self, ...)
				fireable:Fire(os.clock(), ...)
			end
			serviceTable[eventName].FireAll = function(self, ...)
				fireable:Fire(os.clock(), ...)
				
				-- Firing Remote Event
				local remoteEvent = service.Events:FindFirstChild(eventName .. "Remote")
				if remoteEvent then
					remoteEvent:FireAllClients(os.clock(), ...)
				end
				
			end
			serviceTable[eventName].Connect = function(self, callback)
				local connection = fireable.Event:Connect(function(t, ...)
					if t < startTime then return end
					callback(...)
				end)
				return connection
			end
			serviceTable[eventName].Wait = function(self)
				return fireable.Event:Wait()
			end
			
		end
	end
	
	-- Adding Properties
	local meta = {
		__index = function(t, i) -- get
			
			-- Finding Value
			local propValue = service.Properties:FindFirstChild(i)
			if propValue then
				local v = propValue:GetAttribute("Value")
				pcall(function()
					v = HS:JSONDecode(v)
				end)
				return v
			end
			return nil
			
		end,
		__newindex = function(t, i, v) -- set
			
			-- Dictionaries / Tables
			local v = v
			if typeof(v) == "table" then
				v = HS:JSONEncode(v)
			end
			
			-- Finding value
			local propValue = service.Properties:FindFirstChild(i)
			if propValue then
				if (RunService:IsClient() and propValue.Value == 2) or RunService:IsServer() then
					propValue:SetAttribute("Value", v)
					return
				else
					error("You do not have permission to alter the " .. tostring(i) .. " property from the client")
				end
			end
			error("No property found by the name " .. tostring(i))
			
		end,
		
	}
	setmetatable(serviceTable, meta)
	
	-- Returning
	return serviceTable
	
end

-- Returning
return Transverse