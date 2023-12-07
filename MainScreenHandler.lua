--this is a localscript stored within StarterPlayerScripts

------------
--SERVICES--
------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--to access my useful functions module
local TweenService = game:GetService("TweenService")
--for flashy animations tm



---------------------
--USEFUL REFERENCES--
---------------------
local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
local main = gui:WaitForChild("border"):WaitForChild("background")
local scroller = main:WaitForChild("scrollerbg"):WaitForChild("Scroller")
local basicFrame = scroller:WaitForChild("DataElementFrame")
local newElementFrame = main.scrollerbg:WaitForChild("NewElementFrame")
--in case this doesn't make sense, i'll explain it.
--roblox loads everything in an order that can't be predicted.
--the only solid thing you know is that if an object is loaded,
--its parent is also loaded. if you try to call an object that
--doesn't exist, roblox throws an error and the script stops.
--this also happens when you try to call something that hasn't
--loaded yet. the waitforchild command fixes this. it's
--basically identical to the normal "object.child" declaration
--scheme, but if the object being called doesn't exist yet, the
--script waits until it does.



----------
--EVENTS--
----------
local deleteEvent = main.scrollerbg:WaitForChild("DeleteEntry")
--the delete entry event that is activated by the delete buttons on all the entry gui instances
local loadEvent = game.Workspace:WaitForChild("LoadData")
local saveEvent = game.Workspace:WaitForChild("SaveData")
--the two remote functions used to load and save data in the server script



----------------------
--MODULESCRIPT STUFF--
----------------------
local MyFuncs = require(ReplicatedStorage:WaitForChild("FunctionsModule"))
local EB = MyFuncs.EB
local dateValidator = MyFuncs.DateValidator
--two useful functions
local popup = require(gui:WaitForChild("StatusLabel"):WaitForChild("labelfuncs"))
--this is a function set for the top of screen alert box,
--packaged into its own modulescript for code clarity



--------------------------
--INITIALIZATION & FLAGS--
--------------------------
local dataArray = {}
--this is where the clientside backend version of the data is stored
basicFrame.Parent = script
--this removes the empty data entry gui element and keeps it
--stored inside this script until needed.
local currentFilter = "All"
--this is a flag that stores the currently applied filter.
--possible values are "All" "Incomplete" "Complete"
local currentSort = "ID"
--this is a flag that stores the currently applied sorting method.
--possible values are "ID" and "Technician"
local isHelpWindowActive = false
--this is a flag to stop all button interactions when the help menu is visible
--functions activated upon button press will check this first before continuing



--------------------
--COMMON FUNCTIONS--
--------------------
local function scrollerLength()
	return (47*(#scroller:GetChildren()-1))-2
end
--automatically finds the length that the scrolling frame should be
local function isDictionaryMember (dictionary, search)
	local returnvalue = false
	--default case returns false
	for index, value in pairs(dictionary) do
		if index == search then
			returnvalue = true
			--if the specified index is in the dictionary, return true
		end
	end
	return returnvalue
end
--this function checks to see if a specified dictionary
--has an index matching the provided search string.
--i have to do it in a weird way to make sure i don't
--define a dictionary index that i'm trying to check.



-----------------------------
--PLAYER CHARACTER DISABLER--
-----------------------------
local LocalPlayer = game:GetService("Players").LocalPlayer
local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
Controls:Disable()
local StarterGui = game:GetService("StarterGui")
repeat 
	local success = pcall(function() 
		StarterGui:SetCore("ResetButtonCallback", false) 
	end)
	task.wait(1)
until success
--this disables the player character's controls and reset button
--so that they can't hurt themselves and break something



----------------------------
--GENERAL GUI MANIPULATION--
----------------------------
local function technicianSort()
	--this shits' loop structure is gonna be hard to follow, so get ready.
	local techDataArray = {}
	--defines an empty dictionary to store references to all the gui objects.
	local techniciansList = {}
	--defines an empty array to hold the technicians' names, for the sake of sorting them later.
	for index, value in pairs(scroller:GetChildren()) do
		if value.Name == "UIListLayout" then
			continue --just skip over the listlayout. this also avoids the triangle of doom
		end
		--so what we're doing here is looping through all the gui elements in the list
		local technician = value.Technician.Text
		if not isDictionaryMember(techDataArray, technician) then
			techDataArray[technician] = {}
			--the function is categorizing every entry by making each technician its own sub-array.
			--if a technician doesn't already have a sub-array, this creates one.
			--i have to do it like this because in pairs() does not iterate through any list
			--in a predictable order, the only way to do that is with an array using in ipairs().
			table.insert(techniciansList, technician)
			--also adds the technicians' name to the other list.
		end
		table.insert(techDataArray[technician], value.ID.Text)
		--now that we've made sure the sub-array exists, we
		--add the ID of the entry we are currently looking at.
	end
	--now that this is done, we should have the dictionary we need.
	--it's indexed by technician name, each technician having an array
	--with all the tickets they are associated with.
	table.sort(techniciansList, function(a,b)
		return string.lower(a) < string.lower(b)
	end)
	--this sorts the technician names list alphabetically. the greater
	--than operator simply checks the ascii values of the letters, so
	--i force it all into lowercase when comparing the strings- this
	--is because the uppercase alphabet comes before the lowercase
	--alphabet in ascii and that might mess with things.
	local layoutOrderIncrementor = 1
	--create an incrementing variable to define the elements' layout order
	for index, value in ipairs(techniciansList) do
		--iterate through the technicians list, now in alphabetical order
		table.sort(techDataArray[value], function(a,b)
			return tonumber(a) < tonumber(b)
		end)
		--sorts the technician's sub-array of tickets by number
		for index2, value2 in ipairs(techDataArray[value]) do
			--now we're iterating through the sorted list of tickets for
			--the technician we are currently looking at
			scroller[value2].LayoutOrder = layoutOrderIncrementor
			--grabs the gui element for the ticket in question and then
			--sets its layout order to the incrementor
			layoutOrderIncrementor += 1
			--increments up in this hoe
		end
	end
	--[[
	in summary, this function:
	1) finds every unique technician in the database and puts that into a list.
	2) assigns all a technician's tickets to the technician's sub-list object.
	3) iterates through the technician list alphabetically.
	4) iterates through the tickets of each technician's sub-list in order.
	5) in steps 3-4 the incrementor counts up for each ticket sorted and is used to assign its position.
	the end result is that all tickets are sorted first by the
	technicians' name alphabetically, then ascending by id.
	]]--
end

local function updateTable()
	--called whenever data needs to be manually synced with the server
	local position = scroller.CanvasPosition.Y
	--grab the distance scrolled in th table
	for index, value in pairs(scroller:GetChildren()) do
		if value.Name ~= "UIListLayout" then
			value:Destroy()
		end
	end
	--destroys any pre-existing ui elements
	print(dataArray)
	for index, value in ipairs(dataArray) do
		--iterate through all data
		if (currentFilter == "All") or
			(currentFilter == "Incomplete" and value.DateCompleted == "") or
			(currentFilter == "Complete" and value.DateCompleted ~= "") then
			--it iterates through everything but only shows the entries that correspond with the filter
			
			local newframe = basicFrame:Clone()
			--create copy of the blank gui element
			newframe.Name = index
			newframe.LayoutOrder = index
			--names the element and sets its position in the list
			newframe.ID.Text = index
			newframe.DateRequested.Text = value.DateRequested
			newframe.DateCompleted.Text = value.DateCompleted
			newframe.Technician.Text = value.Technician
			newframe.Description.Text = value.Description
			newframe.Notes.Text = value.Notes
			newframe.Parent = scroller
			--fills in the data boxes visible to the player
			newframe.Delete.EventBinder.Enabled = true
			--enables the delete button script
		end
	end
	if currentSort == "Technician" then
		technicianSort()
	end
	scroller.CanvasPosition = Vector2.new(0, position)
	--reset the scrolling frame's position to back where it was, for the sake of user friendliness
	scroller.CanvasSize = UDim2.new(0, 0, 0, scrollerLength())
	--automatically resizes the scrollingframe content size to accomodate all data entries
end



---------------------
--DATA SAVING STUFF--
---------------------
local function saveChangesClient()
	for _, frame in pairs(scroller:GetChildren()) do
		if frame.Name ~= "UIListLayout" then
			if not (dateValidator(frame.DateRequested.Text) and (dateValidator(frame.DateCompleted.Text)) or frame.DateCompleted.Text == "") then
				popup.Alert("One or more dates in Ticket "..frame.Name.." are invalid.", popup.Colors.Bad)
				return false
				--input validation. terminates the update before any changes are made if any dates are invalid.
				--the second one is allowed to be nothing so it checks for this as well.
			end
		end
	end
	local tempArray = {}
	for _, frame in pairs(scroller:GetChildren()) do
		if frame.Name ~= "UIListLayout" then
			tempArray[tonumber(frame.ID.Text)] = EB(
				frame.DateRequested.Text,
				frame.DateCompleted.Text,
				frame.Technician.Text,
				frame.Description.Text,
				frame.Notes.Text
			)
		end
	end
	dataArray = tempArray
	return true
end

local function createEntry()
	if isHelpWindowActive then
		return
	end
	if not (dateValidator(newElementFrame.DateRequested.Text) and
			(dateValidator(newElementFrame.DateCompleted.Text)) or
			newElementFrame.DateCompleted.Text == "") then
		popup.Alert("One or more dates in the new entry are invalid.", popup.Colors.Bad)
		return
		--input validation, terminates function early with a warning message if the new entry box has something wrong
	end
	saveChangesClient()
	--saves any entry changes made just in case
	--otherwise the changes would be lost on reload
	table.insert(dataArray, EB(
		newElementFrame.DateRequested.Text,
		newElementFrame.DateCompleted.Text,
		newElementFrame.Technician.Text,
		newElementFrame.Description.Text,
		newElementFrame.Notes.Text))
	--inserts the new entry to the client database copy
	--using the boxes at the bottom
	updateTable()
	newElementFrame.DateRequested.Text = ""
	newElementFrame.DateCompleted.Text = ""
	newElementFrame.Technician.Text = ""
	newElementFrame.Description.Text = ""
	newElementFrame.Notes.Text = ""
	--clears the bottom boxes
	popup.Alert("Entry Created", popup.Colors.Good)
end
newElementFrame.CreateNew.Activated:Connect(createEntry)

local saveDebounce = false
local function saveChangesServer()
	if isHelpWindowActive then
		return
	end
	local clientsuccess = saveChangesClient()
	if not clientsuccess then
		return
		--kills the function early if there are invalid dates
	end
	if saveDebounce then
		popup.Alert("Server on cooldown, saved only to client.", popup.Colors.Neutral)
		return
	end
	saveDebounce = true
	local serversuccess = saveEvent:InvokeServer(dataArray)
	if serversuccess[1] then
		popup.Alert("Saved to server.", popup.Colors.Good)
	else
		popup.Alert("Save Error: "..serversuccess[2], popup.Colors.Bad)
	end
	wait(5)
	saveDebounce = false
end
main.Save.Activated:Connect(saveChangesServer)
--simple function that combines the server saving with the
--client saving, invoked upon pressing the save button



-----------------
--ENTRY DELETER--
-----------------
local function deleteEntry(index, element)
	if isHelpWindowActive then
		return
	end
	if not saveChangesClient() then
		return
	end --if the save fails it has its own error message, so
	--i can just kill the function and now worry about it
	table.remove(dataArray, index)
	--removes the entry from the backend database
	element:Destroy()
	--removes the entry from the frontend gui
	updateTable()
	--updates the table to fix any leftover issues
	popup.Alert("Entry Deleted", popup.Colors.Good)
end
deleteEvent.OnInvoke = deleteEntry
--binds this function to the deleteentry event established in the "EventBinder"



--------------------------------
--STUFF FOR THE FILTER BUTTONS--
--------------------------------
local buttonActive = Color3.fromRGB(161, 247, 255)
local buttonInactive = Color3.fromRGB(123, 189, 195)
--colors for the filter buttons
main:WaitForChild("FilterAll").Activated:Connect(function()
	if isHelpWindowActive or currentFilter == "All" then
		return
	end
	currentFilter = "All"
	main.FilterAll.BackgroundColor3 = buttonActive
	main.FilterComplete.BackgroundColor3 = buttonInactive
	main.FilterIncomplete.BackgroundColor3 = buttonInactive
	updateTable()
	popup.Alert("Showing All Tickets", popup.Colors.Neutral)
end)
main:WaitForChild("FilterComplete").Activated:Connect(function()
	if isHelpWindowActive or currentFilter == "Complete" then
		return
	end
	currentFilter = "Complete"
	main.FilterAll.BackgroundColor3 = buttonInactive
	main.FilterComplete.BackgroundColor3 = buttonActive
	main.FilterIncomplete.BackgroundColor3 = buttonInactive
	updateTable()
	popup.Alert("Showing Only Complete Tickets", popup.Colors.Neutral)
end)
main:WaitForChild("FilterIncomplete").Activated:Connect(function()
	if isHelpWindowActive or currentFilter == "Incomplete" then
		return
	end
	currentFilter = "Incomplete"
	main.FilterAll.BackgroundColor3 = buttonInactive
	main.FilterComplete.BackgroundColor3 = buttonInactive
	main.FilterIncomplete.BackgroundColor3 = buttonActive
	updateTable()
	popup.Alert("Showing Only Incomplete Tickets", popup.Colors.Neutral)
end)
main:WaitForChild("ByID").Activated:Connect(function()
	if isHelpWindowActive or currentSort == "ID" then
		return
	end
	currentSort = "ID"
	main.ByID.BackgroundColor3 = buttonActive
	main.ByTechnician.BackgroundColor3 = buttonInactive
	updateTable()
	popup.Alert("Sorting By Ticket ID Only", popup.Colors.Neutral)
end)
main:WaitForChild("ByTechnician").Activated:Connect(function()
	if isHelpWindowActive or currentSort == "Technician" then
		return
	end
	currentSort = "Technician"
	main.ByID.BackgroundColor3 = buttonInactive
	main.ByTechnician.BackgroundColor3 = buttonActive
	updateTable()
	popup.Alert("Sorting By Technician, Then Ticket ID", popup.Colors.Neutral)
end)
--functions connected to the the filter buttons
--changes the button colors and filters the table



-----------------------------
--STUFF FOR THE HELP SCREEN--
-----------------------------
main:WaitForChild("Help").Activated:Connect(function()
	isHelpWindowActive = true
	gui:WaitForChild("HelpMenu"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
	--turns off other buttons, begins moving the help window into place
	wait(0.25)
	gui.HelpMenu:WaitForChild("ExitHelp").Active = true
	--halfway through the animation the back button becomes active
end)
gui.HelpMenu.ExitHelp.Activated:Connect(function()
	gui.HelpMenu.ExitHelp.Active = false
	--immediately re-disables the back button
	gui:WaitForChild("HelpMenu"):TweenPosition(UDim2.new(0.5, 0, 1.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true)
	--begins moving the help window into place
	wait(0.35)
	isHelpWindowActive = false
	--other buttons once again become active, though this time later in the animation
end)
--basically these two just move the help screen up and down.
--the only reason it's so long is because I wanted to make
--sure users couldn't accidentally input something they
--didn't intend to while the menu was up.
--also to make it look nice because whatever



-------------------
--DATASTORE STUFF--
-------------------
local function loadFromServer()
	local retVals = loadEvent:InvokeServer()
	if retVals[1] then --if the loading script succeeded
		dataArray = retVals[2]
	else --if the loading script failed
		popup.Alert("Load Error: "..retVals[3], popup.Colors.Bad)
		wait(3)
		loadFromServer()
		--recurses three seconds later.
		--typically this would be ill-advised, but in this case
		--manipulating the save data is literally the only
		--thing you do here so it can't be allowed to fail
	end
end
--[[
allow me to manually explain the general structure here.
there are three versions of the data at play at all times.
the first one is in the server within the datastore.
it can only be accessed and changed so many times so
quickly due to api limitations, so it needs to be accessed
sparingly.
the second one is in the client, stored as an array of values.
it is not visible to the user, however there is no limit as to
how often it can be altered.
the third one is in the gui- this is the data that the user sees.
it is stored within the gui elements themselves and so this
script has to go through it entry by entry to save alterations.
this isn't exactly ideal per se, but it is faster than manually
forcing an update every time any space in the gui is deselected.
also, it's easier for me, so that's what i'm going to do.
]]--



------------------------
--FINAL INITIALIZATION--
------------------------
loadFromServer()
updateTable()