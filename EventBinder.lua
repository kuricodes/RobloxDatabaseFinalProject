--this is a localscript stored inside the initial blank DataElementFrame's delete button

local button = script.Parent
local event = button.Parent.Parent.Parent:WaitForChild("DeleteEntry")
--fetches the delete button and the bindableFunction

local debounce = false
--to prevent unexpected behavior from clicking many times quickly

local function onClick()
	if debounce then
		return
	end
	--breaks the function early if the debounce is active
	
	debounce = true
	--activates the debounce
	
	event:Invoke(button.Parent.ID.Text, script.Parent.Parent)
	--invokes the main script's delete function.
	--i dont declare it for the return value because
	--i will not need it. the only reason it is a
	--function rather than an event is to allow for
	--a debounce
	
	debounce = false
	--this is just a safety mechanism
	--if the function bound to the prior event succeeds, the delete button and subsequently
	--this script will be deleted and terminated before it gets to this point. however if
	--it fails i need to make sure that the button doesn't just completely break forever

end

button.Activated:Connect(onClick)
--when the button is clicked, this activates

--[[
this script is placed inside the delete button of the base data entry object.
whenever a new data entry gui object is created by the main script, this subscript
will automatically run, linking the delete button to the main script.

I have chosen to do it like this for the sake of my own convenience- I technically
could have the main script automatically create and remove events bound to each
entry gui's delete button, but every time they are deleted I would have to also
manually root through prior code to get the event and unbind it.
If i failed at this, it would cause a memory leak.

This solution, however, is easier for me and has no negative effects in my code.
]]--