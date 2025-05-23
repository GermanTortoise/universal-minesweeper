--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")
local Tile = require(server.Tile)
local TextPart = require(client.StarterPlayerScripts.TextPart)
local BoardGen = require(shared.BoardGenerator)
local Types = require(shared.Types)
local Remote = require(shared.remotes)

type TileType = Types.Tile

local Board = {} :: Types.BoardImpl
Board.__index = Board

function Board.new(shape, numMines, position)
	local self = setmetatable({}, Board)
	local NewGame = Remote.getEvent("NewGame")
	wait(1) -- TODO: replace with something less dumb
	NewGame:FireAllClients(shape, position)
	self.Shape = shape
	self.Mines = numMines
	self.Position = position
	self.GameEnded = false
	self.FlagsCount = 0
	self.Tiles = {}
	self.totalNumTiles = 1
	for _, v in self.Shape do
		self.totalNumTiles *= v
	end
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	-- local resetterSize = Vector3.new(5, 3, 10)
	-- -- local e = self + Vector3.new(8, 0.75, -3)
	-- local resetterLocation = (CFrame.new(self.Position + Vector3.new(8, 0.75, -3)))
	-- local resetterAngle = CFrame.Angles(0, -math.pi / 2, -math.pi / 4)
	-- self.Resetter = TextPart.new(resetterSize, resetterLocation * resetterAngle)
	-- self.Resetter.Label.Text = "Click here to reset game"
	-- self.MinesCounter = TextPart.new(resetterSize, (resetterLocation + Vector3.new(12, 0, 0)) * resetterAngle)
	-- self.MinesCounter.Label.Text = "Mines left: 0"
	-- self.Resetter:RegisterClick(function()
	-- 	self:ResetGame()
	-- end, function()
	-- 	print("right click does nothing") -- remove later
	-- end)
	-- self:PrepareBoard()
	return self
end

function Board:PrepareBoard()
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	for i, _ in self.NumberBoard do
		self.Tiles[i] = Tile.new()
	end
	for idx, tile in self.Tiles do
		local nearbyTiles = BoardGen.indexOfNearbyTiles(idx, self.Shape)
		for _, tileIdx in nearbyTiles do
			table.insert(tile.NearbyTiles, self.Tiles[BoardGen.nDToFlatIndex(tileIdx, self.Shape)])
		end
	end
	self:UpdateMinesCounter()
end

function Board:ResetGame()
	print("Resetting")
	self.Tiles = {}
	self.GameEnded = false
	self.FlagsCount = 0
	self:PrepareBoard()
end

function Board:EndGame(revealMines)
	revealMines = revealMines or false
	if self.GameEnded then
		return
	end
	self.GameEnded = true
	local EndGame = Remote.getEvent("EndGame")
	EndGame:FireAllClients()
end

function Board:UpdateMinesCounter()
	self.MinesCounter.Label.Text = "Mines left: " .. tostring(self.Mines - self.FlagsCount)
	-- TODO: this
end

function Board:CheckVictory()
	local activated = 0
	for _, tile in self.Tiles do
		if tile.Activated then
			activated += 1
		end
	end
	if activated == self.totalNumTiles - self.Mines then
		self:EndGame(false)
		self.MinesCounter.Label.Text = "You won!"
	end
end

return Board
