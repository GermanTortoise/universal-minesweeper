--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local Types = require(shared.Types)
local MIM = require(client.StarterPlayerScripts:WaitForChild("MouseInputsManager"))
local Remote = require(shared.remotes)

type TextPartType = Types.TextPartImpl

local TextPart: TextPartType = {} :: TextPartType
TextPart.__index = TextPart

function TextPart.new(size, location, idx)
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

	self.Idx = idx
	self.Val = nil
	self.Activated = false
	self.Flagged = false
	self.NearbyTiles = {}

	local LeftClick = Remote.getEvent("LeftClick")
	local RightClick = Remote.getEvent("RightClick")
	MIM.BindPartToClick(self.Part, function()
		LeftClick:FireServer(self.Idx)
	end, function()
		RightClick:FireServer(self.Idx)
	end)

	return self
end

function TextPart:RegisterClick(leftClickCallback, rightClickCallback)
	return MIM.BindPartToClick(self.Part, leftClickCallback, rightClickCallback)
end

function TextPart:UnregisterClick()
	return MIM.UnbindPartFromClick(self.Part)
end

function TextPart:Reveal(revealMines, val)
	self.Val = val
	if self.Val == 0 then
		self:UnregisterClick()
		self:_hide()
	elseif self.Val > 0 then
		self.Label.Text = tostring(self.Val)
		self.Part.BrickColor = BrickColor.new("Light stone grey")
		self.Label.TextColor3 = Color3.fromHSV(val / 8, 1, 0.75)
	elseif revealMines then
		self.Label.Text = tostring(self.Val)
		self.Label.Text = "X"
		self.Part.BrickColor = BrickColor.new("Bright red")
	end
end

function TextPart:_show()
	self.Part.Transparency = 0
	self.Part.CanCollide = true
	self.Label.Text = tostring(self.Val)
	-- self.collisionBox.CanCollide = true
	MIM.ShowToMouse(self.Part)
end

function TextPart:_hide()
	self.Part.Transparency = 1
	self.Part.CanCollide = false
	self.Label.Text = ""
	-- self.collisionBox.CanCollide = false
	MIM.HideFromMouse(self.Part)
end

function TextPart:ToggleFlag(flagged)
	self.Flagged = flagged
	if self.Flagged then
		self.Label.Text = "*Flag*"
	else
		self.Label.Text = ""
	end
	self:_toggleHiddenTiles()
end

--[[
Checks if this tile no longer provides information about nearby mines. \
Requirements:\
Has correct number of flags nearby, \
All nearby tiles are either activated or flags
]]
function TextPart:_canHide()
	for _, tile in self.NearbyTiles do
		if not tile.Activated and not tile.Flagged then
			return false
		end
	end
	return self:_hasCorrectNumberFlags()
end

function TextPart:_toggleHiddenTiles()
	for _, tile in self.NearbyTiles do
		-- ignore zeros, they are always hidden
		if tile.Val > 0 and tile.Activated then
			if tile:_canHide() then
				tile:_hide()
			else
				tile:_show()
			end
		end
	end
end

function TextPart:_hasCorrectNumberFlags()
	local nearbyFlags = 0
	for _, tile in self.NearbyTiles do
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Val == nearbyFlags
end

function TextPart:Destroy()
	return self.Part:Destroy()
end

return TextPart
