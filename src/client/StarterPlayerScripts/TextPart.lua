local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer").StarterPlayerScripts

local MIM = require(client:WaitForChild("MouseInputsManager"))
local Maid = require(shared.lib.Maid)

local TextPart = {}
TextPart.__index = TextPart

--[[
	A clickable part
]]
export type TextPart = setmetatable<{
	Part: Part,
	Label: TextLabel,
	_maid: any,
}, typeof(TextPart)>

function TextPart.new(size: Vector3, location: CFrame): TextPart
	local self = setmetatable({}, TextPart)
	self._maid = Maid.new()
	self.Part = Instance.new("Part")
	self._maid:GiveTask(self.Part)
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
	self.Label.Size = UDim2.fromScale(1, 1)
	self.Label.BackgroundTransparency = 1
	self.Label.TextScaled = true
	self.Label.Text = ""

	self.Label.Parent = surfaceGui
	surfaceGui.Parent = self.Part

	return self
end

function TextPart.RegisterClick(self: TextPart, leftClickCallback, rightClickCallback)
	return MIM.BindPartToClick(self.Part, leftClickCallback, rightClickCallback)
end

function TextPart.UnregisterClick(self: TextPart)
	return MIM.UnbindPartFromClick(self.Part)
end

function TextPart._show(self: TextPart)
	self.Part.Parent = game.Workspace
end

function TextPart._hide(self: TextPart)
	self.Part.Parent = nil
end

function TextPart.Destroy(self: TextPart)
	return self._maid:Destroy()
end

return TextPart
