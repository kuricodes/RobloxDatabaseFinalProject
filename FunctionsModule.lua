--this file belongs in ReplicatedStorage as a ModuleScript

local module = {}

module.EB = function(_DateRequested, _DateCompleted, _Technician, _Description, _Notes)
	return {
		DateRequested = _DateRequested,
		DateCompleted = _DateCompleted,
		Technician = _Technician,
		Description = _Description,
		Notes = _Notes,
	}
end

--EB stands for Entry Builder.
--modulescripts allow for things like data and functions to be used
--by multiple scripts, even by both client and server scripts.
--since i use the entrybuilder function a lot to keep my code cleaner
--and save myself some time writing, i have put it into a modulescript
--so that i can easily access it anywhere i want.

module.DateValidator = function(dateString)
	local discountRegex = "%d%d/%d%d/%d%d%d%d"
	local validated = string.find(dateString, discountRegex) --searches the provided string for a date
	if validated == nil then
		return false --if there is no proper date in the string
	elseif #dateString >= 11 then
		return false --dates should be ten characters, if there are more then that means something doesn't belong
	else
		return true
	end
end

return module