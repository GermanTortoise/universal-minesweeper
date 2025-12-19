--!strict
local client = game:GetService("StarterPlayer")

local MouseInputsManager = {}

local LeftClickHandlers: { [BasePart]: () -> () } = {}
local RightClickHandlers: { [BasePart]: () -> () } = {}
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = Color3.new()
SelectionBox.Parent = game:GetService("Players").LocalPlayer.PlayerGui
local HiddenParts = Instance.new("Folder")
HiddenParts.Parent = game.Workspace

-- Mouse.Target must be the same part on down and up to register a click
-- This allows for "safe" clicking (drag away to cancel)
local targetL: BasePart
local targetR: BasePart
UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		targetL = Mouse.Target
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		targetR = Mouse.Target
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if targetL == Mouse.Target then
			local handler = LeftClickHandlers[targetL]
			if handler then
				return handler()
			end
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		if targetR == Mouse.Target then
			local handler = RightClickHandlers[targetR]
			if handler then
				return handler()
			end
		end
	end
end)

Mouse.TargetFilter = HiddenParts

function MouseInputsManager.BindPartToClick(part: Part, leftClickCallback: () -> (), rightClickCallback: () -> ())
	LeftClickHandlers[part] = leftClickCallback
	RightClickHandlers[part] = rightClickCallback
	return UpdateSelectionBox()
end
function MouseInputsManager.UnbindPartFromClick(part)
	LeftClickHandlers[part] = nil
	RightClickHandlers[part] = nil
	return UpdateSelectionBox()
end
function UpdateSelectionBox()
	if LeftClickHandlers[Mouse.Target] or RightClickHandlers[Mouse.Target] then
		SelectionBox.Adornee = Mouse.Target
	else
		SelectionBox.Adornee = nil
	end
end
Mouse.Move:Connect(UpdateSelectionBox)
function MouseInputsManager.HideFromMouse(part: BasePart)
	part.Parent = HiddenParts
end

function MouseInputsManager.ShowToMouse(part: BasePart)
	part.Parent = game.Workspace
end

function MouseInputsManager.Reset()
	table.clear(LeftClickHandlers)
	table.clear(RightClickHandlers)
end
return MouseInputsManager
