--this script belongs in ServerScriptService as a Script object

local loadEvent = game.Workspace:WaitForChild("LoadData")
local saveEvent = game.Workspace:WaitForChild("SaveData")
local DataStoreService = game:GetService("DataStoreService")
local databaseStore = DataStoreService:GetDataStore("DatabaseStore")
--typical header stuff

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MyFuncs = require(ReplicatedStorage:WaitForChild("FunctionsModule"))
local EB = MyFuncs.EB
--this grabs the Entry Builder function from my modulescript

local baseArray = {
	EB("11/06/2023", "11/17/2023", "Mike Schmidt", "Damaged television screen", "Device had a large crack in the center. Screen replaced."),
	EB("11/07/2023", "11/15/2023", "James Lee", "Broken ribbon cable", "User's macbook screen had a disconnected ribbon cable. Re-soldered."),
	EB("11/09/2023", "11/18/2023", "Mike Schmidt", "Phone not working", "User unaware that device needed to be charged."),
	EB("11/10/2023", "11/19/2023", "Curt Thomas", "Example Desc 1", "Example Notes 1"),
	EB("11/11/2023", "", "James Lee", "Example Desc 2", "Example Notes 2"),
	EB("11/11/2023", "11/20/2023", "Curt Thomas", "Example Desc 3", "Example Notes 3"),
	EB("11/12/2023", "", "James Lee", "Example Desc 4", "Example Notes 4"),
	EB("11/13/2023", "", "Mike Schmidt", "Example Desc 5", "Example Notes 5"),
	EB("11/14/2023", "", "Curt Thomas", "Example Desc 6", "Example Notes 6"),
}

local function loadEventFunc(player)
	local data = {}
	--declare the return variable as an array
	local success, err = pcall(function() -- pcall is basically an error catcher
		data = databaseStore:GetAsync("user_"..player.UserId)
		--set the return array to the datastore value
	end)
	if not success then
		print(err)
	end
	--if the function inside pcall fails, instead of breaking the script,
	--it just stops and sets the success flag to false- i detect this and
	--print out the error it throws into the console
	if data == nil then
		data = baseArray
		--if the user does not already have a datastore entry, this sends
		--them the default table instead
		--this will only happen on the user's first join
	end
	return {success, data, err}
	--sends the data to the client
end
loadEvent.OnServerInvoke = loadEventFunc

local function saveEventFunc (player, data)
	local success, err = pcall(function()
		databaseStore:SetAsync("user_"..player.UserId, data)
		--while UpdateAsync is technically safer than SetAsync,
		--this is faster and there almost definitely will not
		--be any of the cross-server race conditions that
		--UpdateAsync is designed to solve.
	end)
	if not success then
		print(err)
	end
	return {success, err}
end
saveEvent.OnServerInvoke = saveEventFunc
