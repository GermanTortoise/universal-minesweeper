--!strict
local shared = game:GetService("ReplicatedStorage")
-- local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")
local Tile = require(server.Tile)
-- local TextPart = require(client.StarterPlayerScripts.TextPart)
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
	self.Move = {}
	self.totalNumTiles = 1
	for _, v in self.Shape do
		self.totalNumTiles *= v
	end
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	self:PrepareBoard()
	return self
end

function Board:PrepareBoard()
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	for idx, val in self.NumberBoard do
		self.Tiles[idx] = Tile.new(val, idx)
	end
	for idx, tile in self.Tiles do
		local nearbyTiles = BoardGen.indexOfNearbyTiles(idx, self.Shape)
		for _, tileIdx in nearbyTiles do
			table.insert(tile.NearbyTiles, self.Tiles[BoardGen.nDToFlatIndex(tileIdx, self.Shape)])
		end
	end
	self:ListenClicks()
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
	-- self.MinesCounter.Label.Text = "Mines left: " .. tostring(self.Mines - self.FlagsCount)
	-- TODO: this
end

function Board:ListenClicks()
	local LeftClick = Remote.getEvent("LeftClick")
	local RightClick = Remote.getEvent("RightClick")
	local ActivateTextParts = Remote.getEvent("ActivateTextParts")
	local ToggleFlag = Remote.getEvent("ToggleFlag")
	LeftClick.OnServerEvent:Connect(function(_, idx: number)
		table.clear(self.Move)
		self:LeftClick(idx)
		ActivateTextParts:FireAllClients(self.Move)
		print(self.Move)
		-- print("Left clicked")
	end)
	RightClick.OnServerEvent:Connect(function(_, idx: number)
		-- future: can probably do flagging on client for better latency
		ToggleFlag:FireAllClients(idx, self.Tiles[idx]:ToggleFlag())
		-- print("right clicked")
	end)
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
		-- self.MinesCounter.Label.Text = "You won!"
	end
end

function Board:LeftClick(idx)
	local tile = self.Tiles[idx]
	if tile.Activated then
		self:_chord(idx)
	else
		self:ActivateTile(tile)
	end
end

function Board:_chord(idx)
	local tile = self.Tiles[idx]
	if tile:HasCorrectNumberFlags() then
		for _, adj in tile.NearbyTiles do
			if not adj.Flagged then
				self:ActivateTile(adj)
			end
		end
	end
end

-- on first left click
function Board:ActivateTile(tile)
	-- TODO: figure out revealing 0's when there are misplaced flags
	if tile.Activated or tile.Flagged then
		return
	end
	table.insert(self.Move, { tile.Idx, tile.Value })
	tile.Activated = true
	if tile.Value == 0 then
		for _, adj in tile.NearbyTiles do
			self:ActivateTile(adj)
		end
	elseif tile.Value < 0 then
		self:EndGame(true)
	end
	-- self:_toggleHiddenTiles()
	self:CheckVictory()
end

return Board
