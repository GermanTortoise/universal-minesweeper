--!strict
local shared = game:GetService("ReplicatedStorage")
-- local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")
local Tile = require(server.Tile)
-- local TextPart = require(client.StarterPlayerScripts.TextPart)
local BoardGen = require(shared.BoardGenerator)
local Types = require(shared.Types)
local Remote = require(shared.remotes)

local LeftClick = Remote.getEvent("LeftClick")
local RightClick = Remote.getEvent("RightClick")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local EndGame = Remote.getEvent("EndGame")
local NewGame = Remote.getEvent("NewGame")

type TileType = Types.Tile

local Board = {} :: Types.BoardImpl
Board.__index = Board

function Board.new(shape, numMines, position)
	local self = setmetatable({}, Board)
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
	wait(1) -- replace with handshake
	NewGame:FireAllClients(self.Shape, self.Position)
	-- once this fires, be ready to receive remotes
end

function Board:ListenClicks()
	LeftClick.OnServerEvent:Connect(function(_, idx: number)
		self:LeftClick(idx)
	end)
	RightClick.OnServerEvent:Connect(function(_, idx: number)
		-- TODO (maybe): can probably do flagging on client for better latency
		ToggleFlag:FireAllClients(idx, self.Tiles[idx]:ToggleFlag())
	end)
end

function Board:LeftClick(idx)
	table.clear(self.Move)
	local tile = self.Tiles[idx]
	if tile.Activated then
		self:_chord(tile)
	else
		self:ActivateTile(tile)
	end
	ActivateTextParts:FireAllClients(self.Move)
end

function Board:EndGame(revealMines)
	revealMines = revealMines or false
	if self.GameEnded then
		return
	end
	self.GameEnded = true
	for _, tile in self.Tiles do
		if not tile.Activated and (tile.Value >= 0 or (tile.Value < 0 and revealMines)) then
			table.insert(self.Move, { tile.Idx, tile.Value })
		end
	end
	EndGame:FireAllClients(self.Move, revealMines)
end

function Board:ActivateTile(tile)
	-- TODO: figure out revealing 0's when there are misplaced flags
	if tile.Activated or tile.Flagged then
		return
	end
	tile.Activated = true
	table.insert(self.Move, { tile.Idx, tile.Value })
	if tile.Value == 0 then
		for _, adj in tile.NearbyTiles do
			self:ActivateTile(adj)
		end
	elseif tile.Value < 0 then
		self:EndGame(true)
	end
	self:CheckVictory()
end

function Board:_chord(tile)
	if tile:HasCorrectNumberFlags() then
		for _, adj in tile.NearbyTiles do
			if not adj.Flagged then
				self:ActivateTile(adj)
			end
		end
	end
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

function Board:ResetGame()
	print("Resetting")
	self.Tiles = {}
	self.GameEnded = false
	self.FlagsCount = 0
	self:PrepareBoard()
end

function Board:UpdateMinesCounter()
	-- self.MinesCounter.Label.Text = "Mines left: " .. tostring(self.Mines - self.FlagsCount)
	-- TODO: this
end

return Board
