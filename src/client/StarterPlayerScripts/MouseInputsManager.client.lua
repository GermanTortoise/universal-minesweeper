--!strict
local shared = game:GetService("ReplicatedStorage")

local Types = require(shared.Types)
type Tile = Types.Tile
-- local MouseInputsManager = {}

local LeftClickHandlers: { [BasePart]: () -> () } = {}
local RightClickHandlers: { [BasePart]: () -> () } = {}
local Neighbors: { [BasePart]: { Tile } } = {}
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = Color3.new()
SelectionBox.Parent = game:GetService("Players").LocalPlayer.PlayerGui
local HiddenParts = Instance.new("Folder")
HiddenParts.Parent = game.Workspace

-- function MouseInputsManager.initialize()
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
-- end

function BindPartToClick(part: Part, leftClickCallback: () -> (), rightClickCallback: () -> (), nearby: { Tile })
	LeftClickHandlers[part] = leftClickCallback
	RightClickHandlers[part] = rightClickCallback
	Neighbors[part] = nearby
	return UpdateSelectionBox()
end
function UnbindPartFromClick(part)
	LeftClickHandlers[part] = nil
	RightClickHandlers[part] = nil
	return UpdateSelectionBox()
end
function UpdateSelectionBox()
	if LeftClickHandlers[Mouse.Target] or RightClickHandlers[Mouse.Target] then
		SelectionBox.Adornee = Mouse.Target
		-- for _, tile in Neighbors[Mouse.Target] do
		-- 	tile:SetHighlight(true)
		-- end
	else
		SelectionBox.Adornee = nil
		-- for _, tile in Neighbors[Mouse.Target] do
		-- 	tile:SetHighlight(false)
		-- end
	end
end
Mouse.Move:Connect(UpdateSelectionBox)
function HideFromMouse(part: BasePart)
	part.Parent = HiddenParts
end

function ShowToMouse(part: BasePart)
	part.Parent = game.Workspace
end
-- return MouseInputsManager
