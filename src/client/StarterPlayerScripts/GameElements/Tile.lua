--!strict
local TP = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

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
	-- return self:Reveal(true)
end

function Tile:Reveal(revealMines)
	self.TextPart:UnregisterClick()
	if self.Value == 0 then
		self.TextPart.Part.Transparency = 1
		self.TextPart.Part.CanCollide = false
	elseif self.Value > 0 then
		self.TextPart.Part.BrickColor = BrickColor.new("Light stone grey")
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	elseif revealMines then
		self.TextPart.Label.Text = "X"
		self.TextPart.Part.BrickColor = BrickColor.new("Bright red")
	end
end

function Tile:ToggleFlag()
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
		self.Board.FlagsCount += 1
		if self.Value < 0 then
			self.Board.CorrectlyFlaggedMines += 1
		end
	else
		self.TextPart.Label.Text = ""
		self.Board.FlagsCount -= 1
		if self.Value < 0 then
			self.Board.CorrectlyFlaggedMines -= 1
		end
	end
	self.Board:UpdateMinesCounter()
	self.Board:CheckVictory()
	return not self.Flagged
end

return Tile
