--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer").StarterPlayerScripts

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local TextChatService = game:GetService("TextChatService")

local BG = require(shared.lib.BoardGenerator)
local Cell = require(client.Cell)
local Remote = require(shared.lib.remotes)
local Maid = require(shared.lib.Maid)
local MIM = require(client:WaitForChild("MouseInputsManager"))
local Tile = require(shared.types.Tile)

local TILE_SPACING = 4
local TILE_SIZE = Vector3.new(2.5, 2.5, 2.5)

local NewGame = Remote.getEvent("NewGame")
local StartGame = Remote.getEvent("StartGame")
local EndGame = Remote.getEvent("EndGame")
local ResetGame = Remote.getEvent("ResetGame")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local OnLeftClick = Remote.getBindableEvent("OnLeftClick")
local OnRightClick = Remote.getBindableEvent("OnRightClick")
local ActivateTile = Remote.getEvent("ActivateTile")
local OnFlag = Remote.getEvent("Flag")
local ClientReady = Remote.getEvent("ClientReady")

local player = Players.LocalPlayer
local PLAYERS_TEAM = Teams:WaitForChild("Playing") :: Team
local SPECTATORS_TEAM = Teams:WaitForChild("Spectators") :: Team
local textChannel = TextChatService:WaitForChild("TextChannels") :: any
local generalChannel: TextChannel = textChannel.RBXGeneral

local GameController = {}
GameController.__index = GameController

export type GameController = setmetatable<{
	_maid: any,
	_cells: { Cell.Cell },
}, typeof(GameController)>

function GameController.new()
	local self = setmetatable({}, GameController)
	self._maid = Maid.new()
	self._cells = {} :: { Cell.Cell } -- this cast is necessary for type checking

	self:_updateView()
	self:_listenStart()

	return self
end

function GameController._listenStart(self: GameController)
	NewGame.OnClientEvent:Connect(function(shape: { number })
		-- assert(#self._cells == 0, "there are still textparts")
		self:_newGame(shape)
	end)

	StartGame.OnClientEvent:Connect(function()
		self:_enableInteraction()
	end)

	EndGame.OnClientEvent:Connect(function(tilesRevealed: { Tile.TileMove }, revealed: boolean, elapsed: number)
		self:_endGame(tilesRevealed, revealed, elapsed)
	end)

	ResetGame.OnClientEvent:Connect(function()
		self:_reset()
	end)
	ClientReady:FireServer()
end

function GameController._newGame(self: GameController, shape: { number })
	local totalNumTextParts = 1
	for _, v in shape do
		totalNumTextParts *= v
	end
	local origin = Vector3.new(0, 0, 0)
	for idx = 1, totalNumTextParts do
		local tilePos = self:_getBoardRelativePos(idx, shape)
		self._cells[idx] = Cell.new(TILE_SIZE, CFrame.new(origin + tilePos * TILE_SPACING), idx)
	end
	for _, tile in self._cells do
		local nearbyTiles = BG.indexOfNearbyTiles(tile.Idx, shape)
		for _, idx in nearbyTiles do
			table.insert(tile.NearbyTiles, self._cells[BG.nDToFlatIndex(idx, shape)])
		end
	end
	self:_updateView()
end

-- receive updates from board
function GameController._updateView(self: GameController)
	local activate = ActivateTextParts.OnClientEvent:Connect(function(tilesRevealed: { Tile.TileMove })
		for _, tileInfo in tilesRevealed do
			self._cells[tileInfo.Idx]:Reveal(false, tileInfo.Val)
		end
	end)

	local toggleFlag = ToggleFlag.OnClientEvent:Connect(function(textPart: number, flagged: boolean)
		self._cells[textPart]:SetFlag(flagged)
	end)

	self._maid:GiveTask(activate)
	self._maid:GiveTask(toggleFlag)
end

-- send clicks to board
function GameController._enableInteraction(self: GameController)
	MIM.Start()
	local left = OnLeftClick.Event:Connect(function(idx: number)
		if not self._cells[idx].Flagged and player.Team == PLAYERS_TEAM then
			local cell = self._cells[idx]
			cell.TextPart.Part.Transparency = 0.3
			ActivateTile:FireServer(idx)
		end
	end)
	local right = OnRightClick.Event:Connect(function(idx: number)
		if not self._cells[idx].Activated and player.Team == PLAYERS_TEAM then
			OnFlag:FireServer(idx)
		end
	end)
	self._maid:GiveTask(left)
	self._maid:GiveTask(right)
end

function GameController._endGame(
	self: GameController,
	tilesRevealed: { Tile.TileMove },
	revealMines: boolean,
	elapsed: number
)
	for _, tileInfo in tilesRevealed do
		self._cells[tileInfo.Idx]:Reveal(revealMines, tileInfo.Val)
	end
	MIM.Stop()
	for _, tile in self._cells do
		if tile.Val ~= 0 then
			tile:_show()
		end
	end
	self._maid:Destroy()
	generalChannel:DisplaySystemMessage(
		string.format("you finished the game %s good ly in %.2f seconds", tostring(not revealMines), elapsed)
	)
end

function GameController._reset(self: GameController)
	for _, tile in self._cells do
		tile:Destroy()
	end
	table.clear(self._cells)
end

function GameController._getBoardRelativePos(_self: GameController, pos: number, shape: { number }): Vector3
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

	local idxTriples = buildTriples(BG.flatToNDIndex(pos, shape))
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

return GameController
