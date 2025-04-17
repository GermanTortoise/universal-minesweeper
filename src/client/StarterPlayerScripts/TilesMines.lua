--!strict
local Types = require(script.Parent:WaitForChild("Types"))
type TextPart = Types.TextPart
type Board = Types.Board
type Tile = Types.Tile
type Mine = Types.Mine

local module = {}

--
-- 5, 6, 1, 2, 3	shape
-- x, y, x, y, z
-- 1, 4, 1, 1, 2	index
--[[
		Gets position of tile relative to board origin/tile at index {1, 1, 1, ...}

		BoardGenerator was written with x and y as the ground plane, and z as the vertical axis.
		However, Roblox uses y for vertical, so we must swap the y and z values
	]]
function module.getBoardPosition(pos: { number }, shape: { number }): Vector3
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

	local idxTriples = buildTriples(pos)
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

function module.toggleFlag(self: any): boolean
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
		self.Board.FlagsCount += 1
	else
		self.TextPart.Label.Text = ""
		self.Board.FlagsCount -= 1
	end
	self.Board:UpdateMinesCounter()
	return not self.Flagged
end

return module
