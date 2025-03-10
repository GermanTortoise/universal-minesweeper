local Tile = require(script.Parent:WaitForChild("Tile"))
local Mine = require(script.Parent:WaitForChild("Mine"))
local TextPart = require(script.Parent:WaitForChild("TextPart"))
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))

local Board = {}
Board.__index = Board

function Board:new(shape: { number }, numMines: number, position: Vector3)
	self = setmetatable({}, Board)
	self.Shape = shape
	self.Mines = numMines
	self.Position = position
	self.GameEnded = false
	self.CorrectlyFlaggedMines = 0
	self.FlagsCount = 0
	-- self.Tiles = {}
	self.Tiles = BoardGen.empty(self.Shape)
	self.totalNumTiles = 1
	for _, v in ipairs(self.Shape) do
		self.totalNumTiles *= v
	end
	-- initialize board with empty arrays
	local resetterSize = Vector3.new(5, 3, 10)
	local resetterLocation = (CFrame.new(position + Vector3.new(8, 0.75, -3)))
	local resetterAngle = CFrame.Angles(0, -math.pi / 2, -math.pi / 4)
	self.Resetter = TextPart:new(resetterSize, resetterLocation * resetterAngle)
	self.Resetter.Label.Text = "Click here to reset game"
	self.Resetter:RegisterClick(function()
		self:ResetGame()
	end, function()
		print("right click does nothing") -- remove later
	end)
	self.MinesCounter = TextPart:new(resetterSize, (resetterLocation + Vector3.new(12, 0, 0)) * resetterAngle)
	self.MinesCounter.Label.Text = "Mines left: 0"
	self:PrepareBoard()
	return self
end

function Board:PrepareBoard()
	self.numberBoard = BoardGen.new(self.Shape, self.Mines)
	-- print("self board")
	-- print(self.Board)

	for idx = 1, self.totalNumTiles do
		local shapedIdx = BoardGen.flatToShapedIndices(idx, self.Shape)
		local cellValue = BoardGen.get(self.numberBoard, shapedIdx)
		if cellValue >= 0 then
			BoardGen.put(self.Tiles, shapedIdx, Tile:new(self, cellValue, shapedIdx), false)
		else
			BoardGen.put(self.Tiles, shapedIdx, Mine:new(self, shapedIdx), false)
		end
	end
	self:UpdateMinesCounter()
end

function Board:ResetGame()
	print("Resetting")
	for idx = 1, self.totalNumTiles do
		BoardGen.get(self.Tiles, BoardGen.flatToShapedIndices(idx, self.Shape)):Destroy()
	end
	self.Tiles = BoardGen.empty(self.Shape)
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
	for idx = 1, self.totalNumTiles do
		local tile = BoardGen.get(self.Tiles, BoardGen.flatToShapedIndices(idx, self.Shape))
		if tile.Value >= 0 or revealMines then
			tile:Activate()
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
