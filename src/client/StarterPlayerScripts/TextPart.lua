--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local Types = require(shared.Types)
-- local MouseInputsManager = require(client.StarterPlayerScripts.MouseInputsManager)

type TextPartType = Types.TextPartImpl

local TextPart: TextPartType = {} :: TextPartType
TextPart.__index = TextPart

function TextPart.new(size, location)
	local self = setmetatable({}, TextPart)

	self.Part = Instance.new("Part")
	self.Part.Anchored = true
	self.Part.Material = Enum.Material.SmoothPlastic
	self.Part.Size = size
	self.Part.CFrame = location
	self.Part.Parent = game.Workspace
	self.Part.CastShadow = false

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.CanvasSize = 25 * Vector2.new(size.Z, size.X)

	self.Label = Instance.new("TextLabel")
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.TextScaled = true
	self.Label.Text = ""

	self.Label.Parent = surfaceGui
	surfaceGui.Parent = self.Part
	return self
end

-- function TextPart:RegisterClick(leftClickCallback, rightClickCallback, nearby)
-- 	local Nearby = nearby or {}
-- 	return MouseInputsManager.BindPartToClick(self.Part, leftClickCallback, rightClickCallback, Nearby)
-- end

-- function TextPart:UnregisterClick()
-- 	return MouseInputsManager.UnbindPartFromClick(self.Part)
-- end

function TextPart:Destroy()
	self:UnregisterClick()
	return self.Part:Destroy()
end

return TextPart
