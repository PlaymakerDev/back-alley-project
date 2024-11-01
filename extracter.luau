local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
 
-- Read the place file called myPlaceFile.rbxl into a DataModel variable called "game"
-- This works exactly the same as in Roblox, except "game" does not exist by default.
-- To access "game" you have to load it from a file!
local file = fs.readFile("extract.rbxl")
local game = roblox.deserializePlace(file)
local server = game:GetService("ServerScriptService")
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

fs.writeDir("server")
fs.writeDir("shared")
fs.writeDir("client")

local path = ""

function recursion(n1: Instance, avoidParentName: string)
	if n1.Parent ~= nil and n1.Parent.Name ~= avoidParentName then
		print(n1.Parent.Name)
		local newPath = n1.Parent.Name
		newPath = recursion(n1.Parent, avoidParentName) .. "/" .. newPath
		path = newPath
	end

	return path
end

for _, descendant in server:GetDescendants() do
	path = ""

	if descendant:IsA("Script") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".luau", descendant.Source)
		end
	end

	if descendant:IsA("ModuleScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".module.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".module.luau", descendant.Source)
		end
	end

	if descendant:IsA("LocalScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".local.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".local.luau", descendant.Source)
		end
	end
end

for _, descendant in server:GetDescendants() do
	path = ""

	if descendant:IsA("Script") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".luau", descendant.Source)
		end
	end

	if descendant:IsA("ModuleScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".module.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".module.luau", descendant.Source)
		end
	end

	if descendant:IsA("LocalScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".local.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".local.luau", descendant.Source)
		end
	end
end

for _, descendant in server:GetDescendants() do
	path = ""

	if descendant:IsA("Script") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".luau", descendant.Source)
		end
	end

	if descendant:IsA("ModuleScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".module.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".module.luau", descendant.Source)
		end
	end

	if descendant:IsA("LocalScript") then
		if descendant.Parent.Name ~= "ServerScriptService" then
			path = recursion(descendant, "ServerScriptService")
			fs.writeDir("server/" .. path)
			fs.writeFile("server/" .. path .. "/" .. descendant.Name .. ".local.luau", descendant.Source)
		else
			fs.writeFile("server/" .. descendant.Name .. ".local.luau", descendant.Source)
		end
	end
end

for _, descendant in shared:GetDescendants() do
	path = ""

	if descendant:IsA("Script") then
		if descendant.Parent.Name ~= "ReplicatedStorage" then
			path = recursion(descendant, "ReplicatedStorage")
			fs.writeDir("shared/" .. path)
			fs.writeFile("shared/" .. path .. "/" .. descendant.Name .. ".luau", descendant.Source)
		else
			fs.writeFile("shared/" .. descendant.Name .. ".luau", descendant.Source)
		end
	end

	if descendant:IsA("ModuleScript") then
		if descendant.Parent.Name ~= "ReplicatedStorage" then
			path = recursion(descendant, "ReplicatedStorage")
			fs.writeDir("shared/" .. path)
			fs.writeFile("shared/" .. path .. "/" .. descendant.Name .. ".module.luau", descendant.Source)
		else
			fs.writeFile("shared/" .. descendant.Name .. ".module.luau", descendant.Source)
		end
	end

	if descendant:IsA("LocalScript") then
		if descendant.Parent.Name ~= "ReplicatedStorage" then
			path = recursion(descendant, "ReplicatedStorage")
			fs.writeDir("shared/" .. path)
			fs.writeFile("shared/" .. path .. "/" .. descendant.Name .. ".local.luau", descendant.Source)
		else
			fs.writeFile("shared/" .. descendant.Name .. ".local.luau", descendant.Source)
		end
	end
end

for _, descendant in client:GetDescendants() do
	path = ""

	if descendant:IsA("Script") then
		if descendant.Parent.Name ~= "StarterPlayer" then
			path = recursion(descendant, "StarterPlayer")
			fs.writeDir("client/" .. path)
			fs.writeFile("client/" .. path .. "/" .. descendant.Name .. ".luau", descendant.Source)
		else
			fs.writeFile("client/" .. descendant.Name .. ".luau", descendant.Source)
		end
	end

	if descendant:IsA("ModuleScript") then
		if descendant.Parent.Name ~= "StarterPlayer" then
			path = recursion(descendant, "StarterPlayer")
			fs.writeDir("client/" .. path)
			fs.writeFile("client/" .. path .. "/" .. descendant.Name .. ".module.luau", descendant.Source)
		else
			fs.writeFile("client/" .. descendant.Name .. ".module.luau", descendant.Source)
		end
	end

	if descendant:IsA("LocalScript") then
		if descendant.Parent.Name ~= "StarterPlayer" then
			path = recursion(descendant, "StarterPlayer")
			fs.writeDir("client/" .. path)
			fs.writeFile("client/" .. path .. "/" .. descendant.Name .. ".local.luau", descendant.Source)
		else
			fs.writeFile("client/" .. descendant.Name .. ".local.luau", descendant.Source)
		end
	end
end

 
-- Save the DataModel (game) back to the file that we read it from
-- file = roblox.serializePlace(game)
-- fs.writeFile("myPlaceFile.rbxl", file)