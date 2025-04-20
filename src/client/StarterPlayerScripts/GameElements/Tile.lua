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
	local TILE_SIZE = Vector3.new(4.5, 2, 4.5)
	local tilePos = getBoardPosition(nDIdx, board.Shape)
	self.TextPart = TP.new(TILE_SIZE, CFrame.new(board.Position + tilePos * TILE_SPACING))
	self.Activated = false
	self.Board = board
	self.Value = value
	self.Idx = nDIdx
	self.Flagged = false
	self.TextPart:RegisterClick(function()
		self:Activate()
	end, function()
		self:ToggleFlag()
	end)
	self.TextPart.Label.Rotation = 90
	return self
end

function Tile:Activate()
	-- print("clicked!")
	if self.Activated or self.Flagged then
		return
	end
	self.Activated = true
	self:Reveal(true)
	self.Board:CheckVictory()
	self:_toggleHiddenTiles()
	if self.Value == 0 then
		local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
		for _, idx in nearbyTiles do
			-- all nearby tiles must be safe because curr is 0
			-- so no need to check for mines
			local tile = self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)] :: Types.Tile
			tile:Activate()
		end
	elseif self.Value < 0 then
		self.Board:EndGame(true)
	end
end

function Tile:Reveal(revealMines)
	self.TextPart:UnregisterClick()
	if self.Value == 0 then
		self:_hide()
	elseif self.Value > 0 then
		self:_show()
		self.TextPart.Part.BrickColor = BrickColor.new("Light stone grey")
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	elseif revealMines then
		self:_show()
		self.TextPart.Label.Text = "X"
		self.TextPart.Part.BrickColor = BrickColor.new("Bright red")
	end
end
-- TODO: resolve overlapping functionality ↓↑
function Tile:_show()
	self.TextPart.Part.Transparency = 0
	self.TextPart.Part.CanCollide = true
	self.TextPart.Label.Text = tostring(self.Value)
	MIM.ShowToMouse(self.TextPart.Part)
end
function Tile:_hide()
	self.TextPart:UnregisterClick()
	self.TextPart.Part.Transparency = 1
	self.TextPart.Part.CanCollide = false
	self.TextPart.Label.Text = ""
	MIM.HideFromMouse(self.TextPart.Part)
end

--[[
Checks if this tile no longer provides information about nearby mines. \
Requirements:\
Has correct number of flags nearby, \
All nearby tiles are either revealed or flags
]]
function Tile:_canHide()
	local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
	local nearbyFlags = 0
	for _, idx in nearbyTiles do
		local tile = self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)]
		if tile.Flagged then
			nearbyFlags += 1
		end
		if not tile.Activated and not tile.Flagged then
			return false
		end
	end
	return self.Value == nearbyFlags
end

function Tile:_toggleHiddenTiles()
	local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
	for _, idx in nearbyTiles do
		local tile = self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)]
		if tile.Value >= 0 and tile.Activated then
			if tile:_canHide() then
				tile:_hide()
			else
				tile:_show()
			end
		end
	end
end

function Tile:ToggleFlag()
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
		self.Board.FlagsCount += 1
		if self.Value < 0 then
			-- self.Board.CorrectlyFlaggedMines += 1
			self:_toggleHiddenTiles()
		end
	else
		self.TextPart.Label.Text = ""
		self.Board.FlagsCount -= 1
		if self.Value < 0 then
			-- self.Board.CorrectlyFlaggedMines -= 1
			self:_toggleHiddenTiles()
		end
	end
	self.Board:UpdateMinesCounter()
	return not self.Flagged
end

return Tile
