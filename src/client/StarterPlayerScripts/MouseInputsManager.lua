--!strict
local Types = require(script.Parent:WaitForChild("Types"))
type Tile = Types.Tile
local MouseInputsManager = {}

local LeftClickHandlers: { [BasePart]: () -> () } = {}
local RightClickHandlers: { [BasePart]: () -> () } = {}
local Neighbors: { [BasePart]: { Tile } } = {}
local Mouse = game.Players.LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = Color3.new()
SelectionBox.Parent = game.Players.LocalPlayer.PlayerGui
local HiddenParts = Instance.new("Folder")
HiddenParts.Parent = game.Workspace

function MouseInputsManager.initialize()
	-- Mouse.Target must be the same part on down and up to register a click
	-- This allows for "safe" clicking (drag away to "cancel")
	local targetL = nil
	local targetR = nil
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
		targetL, targetR = nil
	end)
	Mouse.Move:Connect(MouseInputsManager.UpdateSelectionBox)
	Mouse.TargetFilter = HiddenParts
end

function MouseInputsManager.BindPartToClick(
	part: Part,
	leftClickCallback: () -> (),
	rightClickCallback: () -> (),
	nearby: { Tile }
)
	LeftClickHandlers[part] = leftClickCallback
	RightClickHandlers[part] = rightClickCallback
	Neighbors[part] = nearby
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

function MouseInputsManager.HideFromMouse(part: BasePart)
	part.Parent = HiddenParts
end

function MouseInputsManager.ShowToMouse(part: BasePart)
	part.Parent = game.Workspace
end
return MouseInputsManager
