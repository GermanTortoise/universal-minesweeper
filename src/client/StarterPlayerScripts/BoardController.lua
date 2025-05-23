local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local BG = require(shared.BoardGenerator)
local TextPart = require(client.StarterPlayerScripts.TextPart)
local BoardController = {}
BoardController.__index = BoardController

local TILE_SPACING = 4
local TILE_SIZE = Vector3.new(2.5, 2.5, 2.5)

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
-- local Remote = require(shared.remotes)
-- local NewGame = Remote.getEvent("NewGame")
-- NewGame.OnClientEvent:Connect(print("e"))
function BoardController.new(shape: { number }, boardPos: Vector3)
	print("Reached")
	local self = setmetatable({}, BoardController)
	self.totalNumTiles = 1
	for _, v in shape do
		self.totalNumTiles *= v
	end
	self.Tiles = {}
	for idx = 1, self.totalNumTiles, 1 do
		local tilePos = getBoardRelativePos(idx, shape)
		self.Tiles[idx] = TextPart.new(TILE_SIZE, CFrame.new(boardPos + tilePos * TILE_SPACING))
	end
end

return BoardController
