--!strict
local TP = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))
local MIM = require(script.Parent.Parent:WaitForChild("MouseInputsManager"))

type TextPartType = Types.TextPart
type TileType = Types.TileImpl

local Tile: TileType = {} :: TileType
Tile.__index = Tile

function getBoardPosition(pos: { number }, shape: { number }): Vector3
	-- {x1, y1, z1, x2, y2, z2, x3, y3} to
	-- {{x1, y1, z1}, {x2, y2, z2}, {x3, y3}}
	local function buildTriples(idx: { number })
		local triple = {}
		local tripleGroups = {}
		for i = 1, #idx, 1 do
			table.insert(triple, idx[i])
			if #triple == 3 or i == #idx then
				table.insert(tripleGroups, triple)
				triple = {}
			end
		end
		return tripleGroups
	end

	local idxTriples = buildTriples(pos)
	local shapeTriples = buildTriples(shape)
	local relBoardIdx = idxTriples[1] -- innermost triple; each 3D board
	local shapeAccum = shapeTriples[1]
	for level = 2, #idxTriples, 1 do
		local curIdxTriple = idxTriples[level]
		local curShapeTriple = shapeTriples[level]
		for axis, idx in curIdxTriple do
			relBoardIdx[axis] += ((idx - 1) * (shapeAccum[axis] + 1))
		end
		for i, _ in curShapeTriple do
			shapeAccum[i] += 1
			shapeAccum[i] *= curShapeTriple[i]
		end
	end
	return Vector3.new(relBoardIdx[1], relBoardIdx[3], relBoardIdx[2])
end

function Tile.new(board, value, nDIdx)
	local self = setmetatable({}, Tile)
	local TILE_SPACING = 5
	local TILE_SIZE = Vector3.new(3, 3, 3)
	local tilePos = getBoardPosition(nDIdx, board.Shape)
	self.TextPart = TP.new(TILE_SIZE, CFrame.new(board.Position + tilePos * TILE_SPACING))
	self.Activated = false
	self.Board = board
	self.Value = value
	self.Idx = nDIdx
	self.Flagged = false
	self.NearbyTiles = {}
	self.TextPart:RegisterClick(function()
		self:LeftClick()
	end, function()
		self:ToggleFlag()
	end)
	self.TextPart.Label.Rotation = 90
	return self
end

-- must do this after initializing all tiles
function Tile:InitNearbyTiles()
	local nearbyTiles = BoardGen.indexOfNearbyTiles(self.Idx, self.Board.Shape)
	for _, idx in nearbyTiles do
		table.insert(self.NearbyTiles, self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)])
	end
end

function Tile:LeftClick()
	if self.Activated then
		self:_chord()
	else
		self:_activate()
	end
end

function Tile:_chord()
	if self:_hasCorrectNumberFlags() then
		for _, tile in self.NearbyTiles do
			if not tile.Flagged then
				tile:_activate()
			end
		end
	end
end

-- on first left click
function Tile:_activate()
	-- debugging
	-- self.TextPart.Part.BrickColor = BrickColor.new("Lime green")
	-- wait(0.5)
	-- self.TextPart.Part.BrickColor = BrickColor.new("Medium stone grey")
	-- TODO: figure out revealing 0's when there are misplaced flags
	if self.Activated or self.Flagged then
		return
	end
	self.Activated = true
	self:Reveal(true)
	if self.Value == 0 then
		for _, tile in self.NearbyTiles do
			tile:_activate()
		end
	elseif self.Value < 0 then
		self.Board:EndGame(true)
	end
	self:_toggleHiddenTiles()
	self.Board:CheckVictory()
end

function Tile:Reveal(revealMines)
	if self.Value == 0 then
		self.TextPart:UnregisterClick()
		self:_hide()
	elseif self.Value > 0 then
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Part.BrickColor = BrickColor.new("Light stone grey")
		self.TextPart.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	elseif revealMines then
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Label.Text = "X"
		self.TextPart.Part.BrickColor = BrickColor.new("Bright red")
	end
end

function Tile:_show()
	self.TextPart.Part.Transparency = 0
	self.TextPart.Part.CanCollide = true
	self.TextPart.Label.Text = tostring(self.Value)
	MIM.ShowToMouse(self.TextPart.Part)
end

function Tile:_hide()
	self.TextPart.Part.Transparency = 1
	self.TextPart.Part.CanCollide = false
	self.TextPart.Label.Text = ""
	MIM.HideFromMouse(self.TextPart.Part)
end

function Tile:ToggleFlag()
	if self.Activated then
		return false
	end
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
		self.Board.FlagsCount += 1
	else
		self.TextPart.Label.Text = ""
		self.Board.FlagsCount -= 1
	end
	self.Board:UpdateMinesCounter()
	self:_toggleHiddenTiles()
	return not self.Flagged
end

--[[
Checks if this tile no longer provides information about nearby mines. \
Requirements:\
Has correct number of flags nearby, \
All nearby tiles are either activated or flags
]]
function Tile:_canHide()
	for _, tile in self.NearbyTiles do
		if not tile.Activated and not tile.Flagged then
			return false
		end
	end
	return self:_hasCorrectNumberFlags()
end

function Tile:_toggleHiddenTiles()
	for _, tile in self.NearbyTiles do
		-- ignore zeros, they are always hidden
		if tile.Value > 0 and tile.Activated then
			if tile:_canHide() then
				tile:_hide()
			else
				tile:_show()
			end
		end
	end
end

function Tile:_hasCorrectNumberFlags()
	local nearbyFlags = 0
	for _, tile in self.NearbyTiles do
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Value == nearbyFlags
end

return Tile
