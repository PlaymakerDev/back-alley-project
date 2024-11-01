-- Module
local TableUtil = {}

-- Functions
function TableUtil.DeepCopy(original)
	
	-- Creating a deep copy
	local visited = {}
	local function deepCopy(t)
		
		-- Creating copy
		local copy = {}
		
		-- Looping table
		for k, v in pairs(t) do
			if typeof(v) == "table" then
				
				-- Checking if already looped
				if visited[v] then
					warn("Attempted to clone cyclic table: cutting deep copy short on this branch at " .. k .. " in", t)
					continue
				end
				
				-- Copying
				visited[v] = true
				copy[k] = deepCopy(v)
				visited[v] = nil
				
			else
				copy[k] = v
			end
		end
		
		-- Returning
		return copy
		
	end
	
	-- Returning
	return deepCopy(original)
	
end

-- Multi layer shallow
function TableUtil.MultiLayerShallowCopy(original: table, layers: number, currentLayer: number?, visited: table?)
	currentLayer = currentLayer or 0
	visited = visited or {}
	
	-- Creating copy
	local copy = {}
	for k, v in pairs(original) do
		if typeof(v) == "table" and currentLayer < layers then
			if not visited[v] then
				visited[v] = true
				copy[k] = TableUtil.MultiLayerShallowCopy(v, layers, currentLayer + 1, visited)
				visited[v] = false
			else
				continue
			end
		elseif typeof(v) ~= "table" then
			copy[k] = v
		end
	end
	
	-- Returning
	return copy
	
end

-- Loading one table onto another
function TableUtil.LoadTableOntoTable(loadFrom, loadTo)
	for k, v in loadFrom do
		if loadTo[k] == nil then continue end
		if typeof(v) == "table" then
			TableUtil.LoadTableOntoTable(v, loadTo[k])
		else
			loadTo[k] = v
		end
	end
end

-- Returning
return TableUtil