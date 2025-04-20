--!strict

local MouseInputsManager = {}

local LeftClickHandlers = {}
local RightClickHandlers = {}
local Mouse = game.Players.LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = Color3.new()
SelectionBox.Parent = game.Players.LocalPlayer.PlayerGui

function MouseInputsManager.initialize()
	-- Mouse.Target must be the same part on down and up to register a click
	-- This allows for "safe" clicking (drag away to "cancel")
	local target1 = nil
	local target2 = nil
	UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			target1 = Mouse.Target
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			target2 = Mouse.Target
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if target1 == Mouse.Target then
				local handler = LeftClickHandlers[target1]
				if handler then
					return handler()
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if target2 == Mouse.Target then
				local handler = RightClickHandlers[target2]
				if handler then
					return handler()
				end
			end
		end
	end)
	Mouse.Move:Connect(MouseInputsManager.UpdateSelectionBox)
end

function MouseInputsManager.BindPartToClick(part: BasePart, leftClickCallback: () -> (), rightClickCallback: () -> ())
	LeftClickHandlers[part] = leftClickCallback
	RightClickHandlers[part] = rightClickCallback
	return MouseInputsManager.UpdateSelectionBox()
end
function MouseInputsManager.UnbindPartFromClick(part)
	LeftClickHandlers[part] = nil
	RightClickHandlers[part] = nil
	return MouseInputsManager.UpdateSelectionBox()
end
function MouseInputsManager.UpdateSelectionBox()
	if LeftClickHandlers[Mouse.Target] or RightClickHandlers[Mouse.Target] then
		SelectionBox.Adornee = Mouse.Target
	else
		SelectionBox.Adornee = nil
	end
end

return MouseInputsManager
