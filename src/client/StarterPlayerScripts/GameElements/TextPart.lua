local MouseInputsManager = require(script.Parent.Parent:WaitForChild("MouseInputsManager"))

local TextPart = {}
TextPart.__index = TextPart

function TextPart:new(size, location)
	self = setmetatable({}, TextPart)

	self.Part = Instance.new("Part")
	self.Part.Anchored = true
	self.Part.TopSurface = "Smooth"
	self.Part.BottomSurface = "Smooth"
	self.Part.Size = size
	self.Part.CFrame = location
	self.Part.Parent = game.Workspace

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.CanvasSize = 25 * Vector2.new(size.z, size.x)

	self.Label = Instance.new("TextLabel")
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.TextScaled = true
	self.Label.Text = ""

	self.Label.Parent = surfaceGui
	surfaceGui.Parent = self.Part
	return self
end

function TextPart:RegisterClick(leftClickCallback, rightClickCallback)
	return MouseInputsManager.BindPartToClick(self.Part, leftClickCallback, rightClickCallback)
end

function TextPart:UnregisterClick()
	return MouseInputsManager.UnbindPartFromClick(self.Part)
end

function TextPart:Destroy()
	self:UnregisterClick()
	return self.Part:Destroy()
end

return TextPart
