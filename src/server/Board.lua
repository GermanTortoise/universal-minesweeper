--!strict
local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")
local Tile = require(server.Tile)
local BoardGen = require(shared.BoardGenerator)
local Remote = require(shared.remotes)
local Maid = require(shared.Maid)

local LeftClick = Remote.getEvent("LeftClick")
local RightClick = Remote.getEvent("RightClick")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local EndGame = Remote.getEvent("EndGame")
local NewGame = Remote.getEvent("NewGame")
local Refresh = Remote.getBindableEvent("Refresh")

local Board = {}
Board.__index = Board

export type Board = setmetatable<
	{
		_maid: any,
		Shape: { number },
		Mines: number,
		Position: Vector3,
		GameEnded: boolean,
		FlagsCount: number,
		Tiles: { Tile.Tile },
		totalNumTiles: number,
		Move: { { number } },
		-- Resetter: TextPart,
		-- MinesCounter: TextPart,
		NumberBoard: { number },
	},
	typeof(Board)
>

function Board.new(shape: { number }, numMines: number, position: Vector3): Board
	local self = setmetatable({}, Board)
	self._maid = Maid.new()
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
 
function Board.PrepareBoard(self: Board)
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
	--wait(1) -- replace with handshake
	NewGame:FireAllClients(self.Shape, self.Position)
	-- once this fires, be ready to receive remotes
end

function Board.ListenClicks(self: Board)
	local left = LeftClick.OnServerEvent:Connect(function(_, idx: number)
		self:LeftClick(idx)
	end)
	local right = RightClick.OnServerEvent:Connect(function(_, idx: number)
		-- TODO (maybe): can probably do flagging on client for better latency
		ToggleFlag:FireAllClients(idx, self.Tiles[idx]:ToggleFlag())
	end)
	self._maid:GiveTask(left)
	self._maid:GiveTask(right)
end

function Board.LeftClick(self: Board, idx: number)
	table.clear(self.Move)
	local tile = self.Tiles[idx]
	if tile.Activated then
		self:_chord(tile)
	else
		self:ActivateTile(tile)
	end
	if not self.GameEnded then
		ActivateTextParts:FireAllClients(self.Move)
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
			table.insert(self.Move, { tile.Idx, tile.Value })
		end
	end
	EndGame:FireAllClients(self.Move, revealMines)
	Refresh:Fire()
	self:Destroy()
end

function Board.ActivateTile(self: Board, tile: Tile.Tile)
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

function Board._chord(self: Board, tile: Tile.Tile)
	if tile:HasCorrectNumberFlags() then
		for _, adj in tile.NearbyTiles do
			if not adj.Flagged then
				self:ActivateTile(adj)
			end
		end
	end
end

function Board.CheckVictory(self: Board)
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

function Board.UpdateMinesCounter(self: Board)
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
