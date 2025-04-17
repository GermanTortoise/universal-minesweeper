--!strict

local Tile = require(script.Parent:WaitForChild("Tile"))
local Mine = require(script.Parent:WaitForChild("Mine"))
local TextPart = require(script.Parent:WaitForChild("TextPart"))
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

type TileType = Types.Tile
type BoardType = Types.BoardImpl

local Board: BoardType = {} :: BoardType
Board.__index = Board

function Board.new(shape, numMines, position)
	local self = setmetatable({}, Board)
	self.Shape = shape
	self.Mines = numMines
	self.Position = position
	self.GameEnded = false
	self.CorrectlyFlaggedMines = 0
	self.FlagsCount = 0
	self.Tiles = {} :: { Types.Tile | Types.Mine }
	self.totalNumTiles = 1
	for _, v in ipairs(self.Shape) do
		self.totalNumTiles *= v
	end
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	local resetterSize = Vector3.new(5, 3, 10)
	local resetterLocation = (CFrame.new(self.Position + Vector3.new(8, 0.75, -3)))
	local resetterAngle = CFrame.Angles(0, -math.pi / 2, -math.pi / 4)
	self.Resetter = TextPart.new(resetterSize, resetterLocation * resetterAngle)
	self.Resetter.Label.Text = "Click here to reset game"
	self.MinesCounter = TextPart.new(resetterSize, (resetterLocation + Vector3.new(12, 0, 0)) * resetterAngle)
	self.MinesCounter.Label.Text = "Mines left: 0"
	self.Resetter:RegisterClick(function()
		self:ResetGame()
	end, function()
		print("right click does nothing") -- remove later
	end)
	self:PrepareBoard()
	return self
end

function Board:PrepareBoard()
	-- print("self board")
	-- print(self.Board)
	for i, v in ipairs(self.NumberBoard) do
		if v >= 0 then
			self.Tiles[i] = Tile.new(self, v, BoardGen.flatToNDIndex(i, self.Shape))
		else
			self.Tiles[i] = Mine.new(self, BoardGen.flatToNDIndex(i, self.Shape))
		end
	end
	self:UpdateMinesCounter()
end

function Board:ResetGame()
	print("Resetting")
	for _, tile in self.Tiles do
		tile.TextPart:Destroy()
	end
	self.Tiles = {}
	self.GameEnded = false
	self.FlagsCount = 0
	self.CorrectlyFlaggedMines = 0
	self:PrepareBoard()
end

function Board:EndGame(revealMines)
	revealMines = revealMines or true
	if self.GameEnded then
		return
	end
	self.GameEnded = true
	-- self.Tiles: {Tile | Mine}
	for idx, cell in self.Tiles do
		if self.NumberBoard[idx] >= 0 then
			-- positives are tiles
			local tile = cell :: Types.Tile
			tile:Activate()
		elseif revealMines then
			local mine = cell :: Types.Mine
			mine:Reveal()
		end
	end
end

function Board:UpdateMinesCounter()
	self.MinesCounter.Label.Text = "Mines left: " .. tostring(self.Mines - self.FlagsCount)
end

function Board:CheckVictory()
	if self.CorrectlyFlaggedMines == self.Mines then
		self:EndGame(false)
		self.MinesCounter.Label.Text = "You won!"
	end
end

return Board
