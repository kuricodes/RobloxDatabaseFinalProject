--this is a modulescript inside the StatusLabel textlabel that appears above the main gui

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(
	1.5, -- how long it takes
	Enum.EasingStyle.Linear, -- easing curve
	Enum.EasingDirection.Out, -- easing direction
	0, -- how many times it will repeat
	false, -- whether it reverses
	0.5 -- delay until it starts
)

--this script controls the little alert box above the status bar
--it uses tweens to smoothly go from visible to transparent

local module = {}

module.Colors = {
	Bad = Color3.new(1, 0, 0.0156863),
	Neutral = Color3.new(1, 1, 1),
	Good = Color3.new(0.101961, 1, 0),
} --some pre-defined colors

module.Alert = function(message, color)
	script.Parent.TextColor3 = color
	script.Parent.Text = message
	script.Parent.TextTransparency = 0
	TweenService:Create(script.Parent, tweenInfo, {TextTransparency = 1}):Play()
end --makes the alert pop up with the desired message and then slowly disappear

return module