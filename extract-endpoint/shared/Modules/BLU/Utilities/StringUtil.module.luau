-- Services
local Players				= game:GetService("Players")
local RunService			= game:GetService("RunService")

-- Player Variables
local player				= Players.LocalPlayer

-- Constants
local STRING_VARIABLES = {
	_Player = function()
		if RunService:IsClient() then
			return player
		end
	end,
	_Character = function()
		if RunService:IsClient() then
			return player.Character
		end
	end,
}

-- Module
local StringUtil = {}

-- Formatting times
function StringUtil.FormatTime(seconds)
	seconds = math.floor(seconds)
	
	-- Getting time
	local hours = math.floor(seconds / 3600); seconds -= hours * 3600
	local minutes = math.floor(seconds / 60); seconds -= minutes * 60
	
	-- Formatting time
	local timeString = ("%.2d:%.2d:%.2d"):format(hours, minutes, seconds)
	return timeString
	
end

-- Adjusting Big Numbers
function StringUtil.NumberString(num, sigFigs: number?)
	sigFigs = sigFigs or 3
	
	-- Abbreviations
	local abbreviations = {
		[1e33] = "De";
		[1e30] = "Nn";
		[1e27] = "Oc";
		[1e24] = "Sp";
		[1e21] = "Sx";
		[1e18] = "Qn";
		[1e15] = "Qd";
		[1e12] = "Tr";
		[1e9] = "Bi";
		[1e6] = "Mi";
		[1e3] = "K";
	}
	
	-- Getting abbreviation
	local chosenAmount, chosenAbbrev = 1, nil
	for amount, abbrev in abbreviations do
		if num >= amount and (chosenAmount == 1 or chosenAmount < amount) then
			chosenAmount, chosenAbbrev = amount, abbrev
		end
	end
	
	-- Calculating number with sigfigs
	local newNum = num / chosenAmount
	local decimalCount = sigFigs
	
	for i, char in tostring(newNum):split("") do
		if char == "." then break end
		decimalCount -= 1
	end
	local roundTo = 10 ^ decimalCount
	
	-- Converting to string
	local numString = math.floor(newNum * roundTo) / roundTo .. (chosenAbbrev or "")
	
	-- Returning
	return numString
	
end

-- Converting Values
function StringUtil.ConvertString(str: string)
	str = tostring(str)
	
	-- Finding Conversions
	local tableConversion = StringUtil.StringToTable(str)
	local v3 = StringUtil.ConvertVector3(str)
	local object = StringUtil.ObjectSearch(str)
	
	-- Returning Conversion
	if str == "true" then
		return true
	elseif str == "false" then
		return false
	elseif tonumber(str) then
		return tonumber(str)
	elseif tableConversion then
		return tableConversion
	elseif v3 then
		return v3
	elseif object then
		return object
	else
		return str
	end
	
end

-- String to table
function StringUtil.StringToTable(str: string)
	str = tostring(str)
	if str:sub(1, 1) == "{" and str:sub(-1, -1) == "}" then
		
		-- Creating Table
		local returnTable = {}
		str = str:sub(2, -1):sub(1, str:len() - 2)
		
		-- Finding key/value pairs
		local keyValuePairs = str:split(",")
		for i, pair in pairs(keyValuePairs) do
			
			-- Splitting pair
			local keyValues = pair:split("=")
			if #keyValues == 1 then
				
				-- Array insert
				table.insert(returnTable, pair)
				
			elseif #keyValues > 1 then
				
				-- Dictionary insert
				local key = keyValues[1]
				local value = keyValues[2]
				
				-- Converting key
				if key:sub(1, 1) == "[" and key:sub(-1, -1) == "]" then
					key = key:sub(2, -1):sub(1, key:len() - 2)
					if key:sub(1, 1) == "\"" and key:sub(-1, -1) == "\"" then
						key = key:sub(2, -1):sub(1, key:len() - 2)
					else
						key = StringUtil.ConvertString(key)
					end
				else
					key = StringUtil.ConvertString(key)
				end
				
				-- Converting value
				value = StringUtil.ConvertString(value)
				
				-- Inserting
				returnTable[key] = value
				
			end
			
		end
		
		-- Returning
		return returnTable
		
	end
end

-- Converting Vector3
function StringUtil.ConvertVector3(str: string)
	str = tostring(str)
	local matchStr = "Vector3.new("
	if str:sub(1, matchStr:len()) == matchStr and str:sub(str:len(), str:len()) == ")" then
		
		-- Getting Vector3.new() arguments
		local argsString = str:gsub(matchStr, ""):gsub("%)", "")
		local args = argsString:split(",")
		local numArgs = {}
		for i, arg in pairs(args) do
			table.insert(numArgs, tonumber(arg))
		end
		
		-- Creating Vector3
		local v3 = Vector3.new(numArgs[1], numArgs[2], numArgs[3])
		return v3
		
	end
	return false
end

-- Finding objects in game
function StringUtil.ObjectSearch(str: string)
	str = tostring(str)
	
	-- Finding starting object
	local startObj = game
	local varName = str:split(".")[1]
	if STRING_VARIABLES[varName] then
		startObj = STRING_VARIABLES[varName]()
	end
	
	-- Searching for match string
	local matchStr = if startObj == game then "game." else varName .. "."
	if str:sub(1, matchStr:len()) == matchStr then
		
		-- Finding object path
		local pathStr = str:gsub(matchStr, "", 1)
		local path = pathStr:split(".")
		
		-- Finding Object
		local object = startObj
		for i, childName in pairs(path) do
			object = object[childName]
		end
		
		-- Returning
		return object
		
	end
	
	-- If variable
	if startObj ~= game then
		return startObj
	end
	
end

-- Returning
return StringUtil