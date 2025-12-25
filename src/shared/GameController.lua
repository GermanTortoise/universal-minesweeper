--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local BG = require(shared.BoardGenerator)
local TextPart = require(shared.TextPart)
local Remote = require(shared.remotes)
local Maid = require(shared.Maid)
local MIM = require(shared:WaitForChild("MouseInputsManager"))

local TILE_SPACING = 4
local TILE_SIZE = Vector3.new(2.5, 2.5, 2.5)

local NewGame = Remote.getEvent("NewGame")
local GameStarted = Remote.getEvent("GameStarted")
local EndGame = Remote.getEvent("EndGame")
local ResetGame = Remote.getEvent("ResetGame")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local OnLeftClick = Remote.getBindableEvent("OnLeftClick")
local OnRightClick = Remote.getBindableEvent("OnRightClick")
local ActivateTile = Remote.getEvent("ActivateTile")
local OnFlag = Remote.getEvent("Flag")

local player = Players.LocalPlayer
local PLAYERS_TEAM = Teams:WaitForChild("Playing") :: Team
local SPECTATORS_TEAM = Teams:WaitForChild("Spectators") :: Team

local GameController = {}
GameController.__index = GameController

export type GameController = setmetatable<{
	_maid: any,
	_textParts: { TextPart.TextPart },
}, typeof(GameController)>

function GameController.new()
	local self = setmetatable({}, GameController)
	self._maid = Maid.new()
	self._textParts = {} :: { TextPart.TextPart } -- this cast is necessary for type checking

	self:_updateView()
	self:_listenStart()

	return self
end

function GameController._listenStart(self: GameController)
	NewGame.OnClientEvent:Connect(function(shape: { number })
		-- assert(#self._textParts == 0, "there are still textparts")
		self:_newGame(shape)
	end)

	GameStarted.OnClientEvent:Connect(function()
		self:_enableInteraction()
	end)

	EndGame.OnClientEvent:Connect(function(tilesRevealed: { { number } }, revealed: boolean)
		self:_endGame(tilesRevealed, revealed)
	end)

	ResetGame.OnClientEvent:Connect(function()
		self:_reset()
	end)
end

function GameController._newGame(self: GameController, shape: { number })
	local totalNumTextParts = 1
	for _, v in shape do
		totalNumTextParts *= v
	end
	local origin = Vector3.new(0, 0, 0)
	for idx = 1, totalNumTextParts do
		local tilePos = self:_getBoardRelativePos(idx, shape)
		self._textParts[idx] = TextPart.new(TILE_SIZE, CFrame.new(origin + tilePos * TILE_SPACING), idx)
	end
	for _, tile in self._textParts do
		local nearbyTiles = BG.indexOfNearbyTiles(tile.Idx, shape)
		for _, idx in nearbyTiles do
			table.insert(tile.NearbyTiles, self._textParts[BG.nDToFlatIndex(idx, shape)])
		end
	end
	self:_updateView()
end

-- receive updates from board
function GameController._updateView(self: GameController)
	-- TODO: make custom struct for tilesRevealed
	local activate = ActivateTextParts.OnClientEvent:Connect(function(tilesRevealed: { { number } })
		for _, tileInfo in tilesRevealed do
			local idx = tileInfo[1]
			local val = tileInfo[2]
			self._textParts[idx]:Reveal(false, val)
		end
	end)

	local toggleFlag = ToggleFlag.OnClientEvent:Connect(function(textPart: number, flagged: boolean)
		self._textParts[textPart]:SetFlag(flagged)
	end)

	self._maid:GiveTask(activate)
	self._maid:GiveTask(toggleFlag)
end

-- send clicks to board
function GameController._enableInteraction(self: GameController)
	MIM.Start()
	local left = OnLeftClick.Event:Connect(function(idx: number)
		if not self._textParts[idx].Flagged and player.Team == PLAYERS_TEAM then
			ActivateTile:FireServer(idx)
		end
	end)
	local right = OnRightClick.Event:Connect(function(idx: number)
		if not self._textParts[idx].Activated and player.Team == PLAYERS_TEAM then
			OnFlag:FireServer(idx)
		end
	end)
	self._maid:GiveTask(left)
	self._maid:GiveTask(right)
end

function GameController._endGame(self: GameController, tilesRevealed: { { number } }, revealMines: boolean)
	for _, tileInfo in tilesRevealed do
		local idx = tileInfo[1]
		local val = tileInfo[2]
		self._textParts[idx]:Reveal(revealMines, val)
	end
	MIM.Stop()
	for _, tile in self._textParts do
		if tile.Val ~= 0 then
			tile:_show()
		end
	end
	self._maid:Destroy()
end

function GameController._reset(self: GameController)
	for _, tile in self._textParts do
		tile:Destroy()
	end
	table.clear(self._textParts)
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
