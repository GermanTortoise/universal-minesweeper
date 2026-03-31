--!strict

--[[
	A game instance
	Model
]]
local shared = game:GetService("ReplicatedStorage")

local Tile = require(shared.Tile)
local BoardGen = require(shared.BoardGenerator)
local Remote = require(shared.remotes)
local Maid = require(shared.Maid)
local TeamsHelpers = require(shared.TeamsHelpers)
local ArrayStuff = require(shared.ArrayStuff)

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
	NumMines: number,
	GameEnded: boolean,
	FlagsCount: number,
	Tiles: { Tile.Tile },
	CurrentMove: { Tile.TileMove },
	TotalProgress: { Tile.TileMove },
	RevealMines: boolean,
	FirstMoveMade: boolean,
}, typeof(Board)>

function Board.new(): Board
	local self = setmetatable({}, Board)
	self._maid = Maid.new()
	self.Shape = BoardGen.getRandomShape()
	local mineMultiplier = math.random() / 5 + 0.9 -- [0.9, 1.1]
	local totalNumTiles = 1
	for _, dim in self.Shape do
		totalNumTiles *= dim
	end
	self.NumMines = math.floor(mineMultiplier * DENSITIES[#self.Shape] * totalNumTiles)
	self.FlagsCount = 0
	self.Tiles = {}
	local numberBoard = BoardGen.new(self.Shape, self.NumMines)
	for idx, val in numberBoard do
		self.Tiles[idx] = { Activated = false, Flagged = false, Value = val }
	end
	self.CurrentMove = {}
	self.TotalProgress = {}
	self.GameEnded = false
	self.RevealMines = false
	self.FirstMoveMade = false
	self:_listenClicks()
	return self
end

function Board._listenClicks(self: Board)
	local left = ActivateTile.OnServerEvent:Connect(function(player, idx: number)
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
	local tile = self.Tiles[idx]
	if not self.FirstMoveMade and tile.Value < 0 then
		-- handle revealing a mine on the first move
		local safeIdx = math.random(#self.Tiles)
		while self.Tiles[safeIdx].Value < 0 do
			safeIdx = math.random(#self.Tiles)
		end
		tile = self.Tiles[safeIdx]
		self.Tiles[safeIdx] = self.Tiles[idx]
		self.Tiles[idx] = tile
	end
	self.FirstMoveMade = true
	if tile.Activated then
		self:_chord(idx)
	else
		self:_activateTile(idx)
	end
	if not self.GameEnded then
		self.TotalProgress = ArrayStuff.TableConcat(self.TotalProgress, self.CurrentMove)
		ActivateTextParts:FireAllClients(self.CurrentMove)
		table.clear(self.CurrentMove)
	end
end

function Board._rightClick(self: Board, idx: number)
	if not self.Tiles[idx].Activated then
		ToggleFlag:FireAllClients(idx, self:ToggleFlag(idx))
	end
end

function Board._endGame(self: Board)
	if self.GameEnded then
		return
	end
	print("you finished the game: ", not self.RevealMines, "good ly")
	self.GameEnded = true
	for idx, tile in self.Tiles do
		if not tile.Activated and (tile.Value >= 0 or (tile.Value < 0 and self.RevealMines)) then
			table.insert(self.CurrentMove, { Idx = idx, Val = tile.Value })
		end
	end
	self.TotalProgress = ArrayStuff.TableConcat(self.TotalProgress, self.CurrentMove)
	EndGame:FireAllClients(self.CurrentMove, self.RevealMines)
	table.clear(self.CurrentMove)
	Refresh:Fire(not self.RevealMines)
end

function Board._activateTile(self: Board, idx: number)
	-- TODO: figure out revealing 0's when there are misplaced flags
	local tile: Tile.Tile = self.Tiles[idx]
	if tile.Activated or tile.Flagged then
		return
	end
	tile.Activated = true
	table.insert(self.CurrentMove, { Idx = idx, Val = tile.Value })
	if tile.Value == 0 then
		for _, tileIdx in self:GetNearbyTiles(idx) do
			self:_activateTile(tileIdx)
		end
	elseif tile.Value < 0 then
		self.RevealMines = true
		self:_endGame()
	end
	self:_checkVictory()
end

function Board._chord(self: Board, idx: number)
	if self:HasCorrectNumberFlags(idx) then
		local nearbyTiles = self:GetNearbyTiles(idx)
		for _, adj in nearbyTiles do
			local adjTile = self.Tiles[adj]
			if not adjTile.Flagged and not adjTile.Activated then
				self:_activateTile(adj)
			end
		end
	end
end

function Board._checkVictory(self: Board)
	local activated = 0
	for _, tile in self.Tiles do
		if tile.Activated then
			activated += 1
		end
	end
	if activated == #self.Tiles - self.NumMines then
		self:_endGame(false)
	end
end

function Board.ToggleFlag(self: Board, idx: number): boolean
	local tile = self.Tiles[idx]
	if tile.Activated then
		return false
	end
	tile.Flagged = not tile.Flagged
	return tile.Flagged
end

function Board.GetNearbyTiles(self: Board, idx: number): { number }
	local nearbyTilesIdxs = BoardGen.indexOfNearbyTiles(idx, self.Shape)
	local nearbyTiles = {}
	for _, tileIdx in nearbyTilesIdxs do
		table.insert(nearbyTiles, BoardGen.nDToFlatIndex(tileIdx, self.Shape))
	end
	return nearbyTiles
end

function Board.HasCorrectNumberFlags(self: Board, idx: number)
	local nearbyFlags = 0
	for _, adj in self:GetNearbyTiles(idx) do
		local tile = self.Tiles[adj]
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Tiles[idx].Value == nearbyFlags
end

function Board.Onboard(self: Board, player: Player)
	if self.GameEnded then
		EndGame:FireClient(player, self.TotalProgress, self.RevealMines)
	else
		ActivateTextParts:FireClient(player, self.TotalProgress)
	end
end

function Board.UpdateMinesCounter(_self: Board)
	-- TODO: this
end

function Board.Destroy(self: Board)
	table.clear(self.Tiles)
	self._maid:Destroy()
end

return Board
