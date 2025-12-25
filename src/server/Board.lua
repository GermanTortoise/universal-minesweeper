--!strict

--[[
	A game instance
	Model
]]
local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")

local Tile = require(server.Tile)
local BoardGen = require(shared.BoardGenerator)
local Remote = require(shared.remotes)
local Maid = require(shared.Maid)
local BG = require(shared.BoardGenerator)
local TeamsHelpers = require(shared.TeamsHelpers)

local ToggleFlag = Remote.getEvent("ToggleFlag")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local EndGame = Remote.getEvent("EndGame")
local Refresh = Remote.getBindableEvent("Refresh")
local ActivateTile = Remote.getEvent("ActivateTile")
local Flag = Remote.getEvent("Flag")

local DENSITIES = table.freeze({ 0.2, 0.15, 0.07, 0.025 })

local Board = {}
Board.__index = Board

export type Board = setmetatable<{
	_maid: any,
	Shape: { number },
	Mines: number,
	GameEnded: boolean,
	FlagsCount: number,
	Tiles: { Tile.Tile },
	totalNumTiles: number,
	CurrentMove: { { number } },
	TotalProgress: { { number } },
	NumberBoard: { number },
}, typeof(Board)>

function Board.new(): Board
	local self = setmetatable({}, Board)
	self._maid = Maid.new()

	self.Shape = BG.getRandomShape()
	local mineMultiplier = math.random() / 5 + 0.9 -- 0.9 to 1.1
	-- TODO: handle or make sure this doesn't cause more mines than there are tiles
	local totalNumTiles = 1
	for _, dim in self.Shape do
		totalNumTiles *= dim
	end

	self.Mines = math.floor(mineMultiplier * DENSITIES[#self.Shape] * totalNumTiles)

	self.GameEnded = false
	self.FlagsCount = 0
	self.Tiles = {}
	self.CurrentMove = {} -- TODO: optimize this
	self.TotalProgress = {}
	self.totalNumTiles = 1
	for _, v in self.Shape do
		self.totalNumTiles *= v
	end
	self.NumberBoard = BoardGen.new(self.Shape, self.Mines)
	self:_initBoard()
	return self
end

function Board._initBoard(self: Board)
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
	self:_listenClicks()
end

function Board._listenClicks(self: Board)
	local left = ActivateTile.OnServerEvent:Connect(function(player, idx: number)
		print("activated")
		if player.Team ~= TeamsHelpers.GetPlayers() then
			warn(string.format("%s triggered ActivateTile as spectator", player.Name))
			return
		end
		if self.Tiles[idx].Flagged then
			warn(string.format("%s triggered ActivateTile despite flagged", player.Name))
			return
		end
		if self.GameEnded then
			warn(string.format("%s triggered ActivateTile despite game over", player.Name))
			return
		end
		self:_leftClick(idx) -- TODO: make team assignment more robust and prevent MIM on client too
	end)

	local right = Flag.OnServerEvent:Connect(function(player, idx: number)
		print("flagged")
		if player.Team ~= TeamsHelpers.GetPlayers() then
			warn(string.format("%s triggered Flag as spectator", player.Name))
			return
		end
		if self.Tiles[idx].Activated then
			warn(string.format("%s triggered Flag despite activated", player.Name))
			return
		end
		if self.GameEnded then
			warn(string.format("%s triggered Flag despite game over", player.Name))
			return
		end
		self:_rightClick(idx)
	end)

	self._maid:GiveTask(left)
	self._maid:GiveTask(right)
end

function Board._leftClick(self: Board, idx: number)
	table.clear(self.CurrentMove)
	local tile = self.Tiles[idx]
	if tile.Activated then
		self:_chord(tile)
	else
		self:_activateTile(tile)
	end
	if not self.GameEnded then
		ActivateTextParts:FireAllClients(self.CurrentMove)
	end
end

function Board._rightClick(self: Board, idx: number)
	if not self.Tiles[idx].Activated then
		ToggleFlag:FireAllClients(idx, self.Tiles[idx]:ToggleFlag())
	end
end

function Board.EndGame(self: Board, revealMines: boolean)
	revealMines = revealMines or false
	if self.GameEnded then
		return
	end
	print("you finished the game: ", not revealMines, "good ly")
	self.GameEnded = true
	for _, tile in self.Tiles do
		if not tile.Activated and (tile.Value >= 0 or (tile.Value < 0 and revealMines)) then
			table.insert(self.CurrentMove, { tile.Idx, tile.Value })
		end
	end
	EndGame:FireAllClients(self.CurrentMove, revealMines)
	Refresh:Fire()
	task.wait(1)
	self:Destroy()
end

function Board._activateTile(self: Board, tile: Tile.Tile)
	-- TODO: figure out revealing 0's when there are misplaced flags
	if tile.Activated or tile.Flagged then
		return
	end
	tile.Activated = true
	table.insert(self.CurrentMove, { tile.Idx, tile.Value })
	if tile.Value == 0 then
		for _, adj in tile.NearbyTiles do
			self:_activateTile(adj)
		end
	elseif tile.Value < 0 then
		self:EndGame(true)
	end
	self:_checkVictory()
end

function Board._chord(self: Board, tile: Tile.Tile)
	if tile:HasCorrectNumberFlags() then
		for _, adj in tile.NearbyTiles do
			if not adj.Flagged then
				self:_activateTile(adj)
			end
		end
	end
end

function Board._checkVictory(self: Board)
	-- print("checking")
	local activated = 0
	for _, tile in self.Tiles do
		if tile.Activated then
			activated += 1
		end
	end
	-- print(activated)
	if activated == self.totalNumTiles - self.Mines then
		self:EndGame(false)
	end
end

function Board.UpdateMinesCounter(_self: Board)
	-- self.MinesCounter.Label.Text = "Mines left: " .. tostring(self.Mines - self.FlagsCount)
	-- TODO: this
end

function Board.Destroy(self: Board)
	for _, tile in self.Tiles do
		table.clear(tile.NearbyTiles)
	end
	table.clear(self.Tiles)
	self._maid:Destroy()
end

return Board
