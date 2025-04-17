--!strict

-- local TP = require(script.Parent.TextPart)
-- local Tile = require(script.Parent.Tile)
local TP = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
local TilesMines = require(script.Parent.Parent:WaitForChild("TilesMines"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

-- type TextPartType = Types.TextPart
type MineType = Types.MineImpl

local Mine: MineType = {} :: MineType
Mine.__index = Mine

function Mine.new(board, nDIdx)
	local self = setmetatable({}, Mine)
	local TILE_SPACING = 5
	local TILE_SIZE = Vector3.new(4.5, 2, 4.5)
	local tilePos = TilesMines.getBoardPosition(nDIdx, board.Shape)
	self.Board = board
	self.Idx = nDIdx
	self.Flagged = false
	self.TextPart = TP.new(TILE_SIZE, CFrame.new(board.Position + tilePos * TILE_SPACING))
	self.TextPart:RegisterClick(function()
		self:Reveal()
	end, function()
		self:ToggleFlag()
	end)
	return self
end

function Mine:Reveal()
	self.TextPart.Label.Text = "X"
	self.TextPart.Part.BrickColor = BrickColor.new("Bright red")
	return self.Board:EndGame()
end

function Mine:ToggleFlag()
	TilesMines.toggleFlag(self)
	if self.Flagged then
		self.Board.CorrectlyFlaggedMines = self.Board.CorrectlyFlaggedMines + 1
	else
		self.Board.CorrectlyFlaggedMines = self.Board.CorrectlyFlaggedMines - 1
	end
	return self.Board:CheckVictory()
end

return Mine
