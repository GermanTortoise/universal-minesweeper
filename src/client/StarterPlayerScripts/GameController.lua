--!strict
-- this can probably be a localscript
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local BG = require(shared.BoardGenerator)
local TextPart = require(client.StarterPlayerScripts.TextPart)
local Remote = require(shared.remotes)
local Types = require(shared.Types)

local TILE_SPACING = 4
local TILE_SIZE = Vector3.new(2.5, 2.5, 2.5)

local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local EndGame = Remote.getEvent("EndGame")

local function getBoardRelativePos(pos: number, shape: { number }): Vector3
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

local GameController = {} :: Types.GameControllerImpl
GameController.__index = GameController

function GameController.new(shape, boardPos)
	local self = setmetatable({}, GameController)
	local totalNumTextParts = 1
	for _, v in shape do
		totalNumTextParts *= v
	end
	self.TextParts = {}
	for idx = 1, totalNumTextParts do
		local tilePos = getBoardRelativePos(idx, shape)
		self.TextParts[idx] = TextPart.new(TILE_SIZE, CFrame.new(boardPos + tilePos * TILE_SPACING), idx)
	end
	-- TODO: do init nearby tiles
	for _, tile in self.TextParts do
		local nearbyTiles = BG.indexOfNearbyTiles(tile.Idx, shape)
		for _, idx in nearbyTiles do
			table.insert(tile.NearbyTiles, self.TextParts[BG.nDToFlatIndex(idx, shape)])
		end
	end

	ActivateTextParts.OnClientEvent:Connect(function(tilesRevealed: { { number } })
		for _, tileInfo in tilesRevealed do
			local idx = tileInfo[1]
			local val = tileInfo[2]
			self.TextParts[idx]:Reveal(false, val)
		end
	end)

	ToggleFlag.OnClientEvent:Connect(function(textPart: number, flagged: boolean)
		self.TextParts[textPart]:ToggleFlag(flagged)
	end)

	EndGame.OnClientEvent:Connect(function(tilesRevealed: { { number } }, revealMines: boolean)
		for _, tileInfo in tilesRevealed do
			local idx = tileInfo[1]
			local val = tileInfo[2]
			self.TextParts[idx]:Reveal(revealMines, val)
		end
	end)
end

return GameController
