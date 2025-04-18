--!strict

local MouseInputsManager = {}

local LeftClickHandlers = {}
local RightClickHandlers = {}
local Mouse = game.Players.LocalPlayer:GetMouse()
local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = Color3.new()
SelectionBox.Parent = game.Players.LocalPlayer.PlayerGui

function MouseInputsManager.initialize()
	Mouse.Button1Down:Connect(function()
		do
			local handler = LeftClickHandlers[Mouse.Target]
			if handler then
				return handler()
			end
		end
	end)
	Mouse.Button2Down:Connect(function()
		do
			local handler = RightClickHandlers[Mouse.Target]
			if handler then
				return handler()
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
