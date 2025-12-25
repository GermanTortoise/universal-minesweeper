--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local MIM = require(shared:WaitForChild("MouseInputsManager"))
local Remote = require(shared.remotes)
local Maid = require(shared.Maid)

local OnLeftClick = Remote.getBindableEvent("OnLeftClick")
local OnRightClick = Remote.getBindableEvent("OnRightClick")

local TextPart = {}
TextPart.__index = TextPart

export type TextPart = setmetatable<{
	Part: Part,
	Label: TextLabel,
	Idx: number,
	Val: number,
	Activated: boolean,
	Flagged: boolean,
	NearbyTiles: { TextPart },
	_maid: any,
}, typeof(TextPart)>

function TextPart.new(size: Vector3, location: CFrame, idx: number): TextPart
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

	self.Idx = idx
	self.Val = -1
	self.Activated = false -- should really be called revealed
	self.Flagged = false
	self.NearbyTiles = {}
	self._maid:GiveTask(function()
		table.clear(self.NearbyTiles)
	end)

	MIM.BindPartToClick(self.Part, function()
		if not self.Flagged then
			OnLeftClick:Fire(self.Idx)
		end
	end, function()
		if not self.Activated then
			OnRightClick:Fire(self.Idx)
		end
	end)

	return self
end

function TextPart.RegisterClick(self: TextPart, leftClickCallback, rightClickCallback)
	return MIM.BindPartToClick(self.Part, leftClickCallback, rightClickCallback)
end

function TextPart.UnregisterClick(self: TextPart)
	return MIM.UnbindPartFromClick(self.Part)
end

function TextPart.Reveal(self: TextPart, revealMines, val)
	self.Val = val
	self.Activated = true
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
	self:_toggleHiddenTiles()
end

function TextPart._show(self: TextPart)
	self.Part.Parent = game.Workspace
end

function TextPart._hide(self: TextPart)
	self.Part.Parent = nil
end

function TextPart.SetFlag(self: TextPart, flagged: boolean)
	self.Flagged = flagged
	if self.Flagged then
		self.Label.Text = "*Flag*"
	else
		self.Label.Text = ""
	end
	self:_toggleHiddenTiles()
end

--[[
Checks if this tile no longer provides information about nearby mines.

Requirements:
- Has correct number of flags nearby
- All nearby tiles are either activated or flags
]]
function TextPart._canHide(self: TextPart)
	for _, tile in self.NearbyTiles do
		if not tile.Activated and not tile.Flagged then
			return false
		end
	end
	return self:_hasCorrectNumberFlags()
end

function TextPart._toggleHiddenTiles(self: TextPart)
	for _, tile in self.NearbyTiles do
		-- ignore unknown/unactivted tiles by short circuit
		if tile.Activated and tile.Val > 0 then
			if tile:_canHide() then
				tile:_hide()
			else
				tile:_show()
			end
		end
	end
end

function TextPart._hasCorrectNumberFlags(self: TextPart)
	local nearbyFlags = 0
	for _, tile in self.NearbyTiles do
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Val == nearbyFlags
end

function TextPart.Destroy(self: TextPart)
	return self._maid:Destroy()
end

return TextPart
