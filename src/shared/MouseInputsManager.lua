--!strict

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local shared = game:GetService("ReplicatedStorage")

local AS = require(shared.ArrayStuff)
local Maid = require(shared.Maid)

type ClickHandler = () -> ()

local MouseInputsManager = {}

-- Private module-level variables
local mouse: Mouse?
local selectionBox: SelectionBox?
local hiddenParts: Folder?
local leftClickHandlers: { [BasePart]: ClickHandler } = {}
local rightClickHandlers: { [BasePart]: ClickHandler } = {}
local initialized = false
local began: RBXScriptConnection?
local ended: RBXScriptConnection?

-- Define all local functions FIRST (at the top)
local function updateSelectionBox()
	if not mouse then
		return
	end
	if not selectionBox then
		return
	end

	local target = mouse.Target
	if target and (leftClickHandlers[target] or rightClickHandlers[target]) then
		selectionBox.Adornee = target
	else
		selectionBox.Adornee = nil
	end
end

local function listen()
	assert(mouse, "Mouse not initialized")
	assert(hiddenParts, "HiddenParts not initialized")

	local targetL: BasePart?
	local targetR: BasePart?

	began = UIS.InputBegan:Connect(function(input: InputObject)
		if not mouse then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			targetL = mouse.Target
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			targetR = mouse.Target
		end
	end)

	ended = UIS.InputEnded:Connect(function(input: InputObject)
		if not mouse then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if targetL and targetL == mouse.Target then
				local handler = leftClickHandlers[targetL]
				if handler then
					handler()
				end
			end
			targetL = nil
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if targetR and targetR == mouse.Target then
				local handler = rightClickHandlers[targetR]
				if handler then
					handler()
				end
			end
			targetR = nil
		end
	end)

	mouse.Move:Connect(function()
		updateSelectionBox()
	end)

	mouse.TargetFilter = hiddenParts
end

function MouseInputsManager.Init(mouseInstance: Mouse)
	if initialized then
		warn("MouseInputsManager already initialized")
		return
	end
	mouse = mouseInstance
	initialized = true
end

function MouseInputsManager.Start()
	selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = Color3.new(0, 0, 0)
	selectionBox.LineThickness = 0.075
	selectionBox.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	hiddenParts = Instance.new("Folder")
	hiddenParts.Name = "HiddenParts"
	hiddenParts.Parent = workspace
	listen()
end

function MouseInputsManager.BindPartToClick(
	part: BasePart,
	leftClickCallback: ClickHandler?,
	rightClickCallback: ClickHandler?
)
	if leftClickCallback then
		leftClickHandlers[part] = leftClickCallback
	end
	if rightClickCallback then
		rightClickHandlers[part] = rightClickCallback
	end
	updateSelectionBox()
end

function MouseInputsManager.UnbindPartFromClick(part: BasePart)
	leftClickHandlers[part] = nil
	rightClickHandlers[part] = nil
	updateSelectionBox()
end

function MouseInputsManager.HideFromMouse(part: BasePart)
	assert(hiddenParts, "HiddenParts not initialized")
	part.Parent = hiddenParts
end

function MouseInputsManager.ShowToMouse(part: BasePart)
	part.Parent = workspace
end

function MouseInputsManager.Stop()
	if selectionBox then
		selectionBox:Destroy()
	end
	if hiddenParts then
		hiddenParts:Destroy()
	end
	if began then
		began:Disconnect()
	end
	if ended then
		ended:Disconnect()
	end

	table.clear(leftClickHandlers)
	table.clear(rightClickHandlers)

	updateSelectionBox()
end

function MouseInputsManager.Destroy()
	MouseInputsManager.Stop()

	mouse = nil
	selectionBox = nil
	hiddenParts = nil
	initialized = false
end

return MouseInputsManager
