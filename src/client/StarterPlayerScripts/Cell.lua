local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer").StarterPlayerScripts

local Remote = require(shared.lib.remotes)
local Maid = require(shared.lib.Maid)
local TextPart = require(client.TextPart)

local OnLeftClick = Remote.getBindableEvent("OnLeftClick")
local OnRightClick = Remote.getBindableEvent("OnRightClick")

local Cell = {}
Cell.__index = Cell

--[[
    An nD minesweeper cell
]]
export type Cell = setmetatable<{
	TextPart: TextPart.TextPart,
	Idx: number,
	Val: number,
	Activated: boolean,
	Flagged: boolean,
	NearbyTiles: { Cell },
	_maid: any,
}, typeof(Cell)>

function Cell.new(size: Vector3, location: CFrame, idx: number): Cell
	local self = setmetatable({}, Cell)
	self._maid = Maid.new()
	self.TextPart = TextPart.new(size, location, idx)
	self.Idx = idx
	self.Val = -1
	self.Activated = false
	self.Flagged = false
	self.NearbyTiles = {}
	self._maid:GiveTask(function()
		table.clear(self.NearbyTiles)
        self.TextPart:Destroy()
	end)

	self.TextPart:RegisterClick(function()
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

function Cell.Reveal(self: Cell, revealMines: boolean, val: number)
	self.Val = val
	self.Activated = true
	self.TextPart.Part.Transparency = 0
	if self.Val == 0 then
		self.TextPart:UnregisterClick()
		self:_hide()
	elseif self.Val > 0 then
		self.TextPart.Label.Text = tostring(self.Val)
		self.TextPart.Part.BrickColor = BrickColor.new("Light stone grey")
		self.TextPart.Label.TextColor3 = Color3.fromHSV(val / 8, 1, 0.75)
	elseif revealMines then
		self.TextPart.Label.Text = tostring(self.Val)
		self.TextPart.Label.Text = "X"
		self.TextPart.Part.BrickColor = BrickColor.new("Bright red")
	end
	self:_toggleHiddenTiles()
end

function Cell._show(self: Cell)
	self.TextPart.Part.Parent = game.Workspace
end

function Cell._hide(self: Cell)
	self.TextPart.Part.Parent = nil
end

function Cell.SetFlag(self: Cell, flagged: boolean)
	self.Flagged = flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
	else
		self.TextPart.Label.Text = ""
	end
	self:_toggleHiddenTiles()
end

--[[
Checks if this tile no longer provides information about nearby mines.

Requirements:
- Has correct number of flags nearby
- All nearby tiles are either activated or flags
]]
function Cell._canHide(self: Cell)
	for _, tile in self.NearbyTiles do
		if not tile.Activated and not tile.Flagged then
			return false
		end
	end
	return self:_hasCorrectNumberFlags()
end

function Cell._toggleHiddenTiles(self: Cell)
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

function Cell._hasCorrectNumberFlags(self: Cell)
	local nearbyFlags = 0
	for _, tile in self.NearbyTiles do
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Val == nearbyFlags
end

function Cell.Destroy(self: Cell)
	return self._maid:Destroy()
end

return Cell
