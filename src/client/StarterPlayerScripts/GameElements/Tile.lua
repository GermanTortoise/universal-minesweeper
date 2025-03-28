--!strict

local TP = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
-- local Board = require(script.Parent.Board)
-- send tileclicked to board somehow other than using instance of board
type TileImpl = {
	__index: TileImpl,
	new: (board: any, value: number, arr: { number }) -> Tile,
	Activate: (self: Tile) -> (),
	Reveal: (self: Tile) -> (),
	ToggleFlag: (self: Tile) -> (),
}

type TextPartType = TP.TextPart

export type Tile = typeof(setmetatable(
	{} :: { TextPart: TextPartType, Activated: boolean, Board: any, Value: number, Idx: { number }, Flagged: boolean },
	{} :: TileImpl
))

local Tile: TileImpl = {} :: TileImpl
Tile.__index = Tile

function Tile.new(board, value, arr)
	local self = setmetatable({}, Tile) :: Tile
	local TILE_CUBE_SIZE = 5
	-- local absPos = Vector3.new()
	-- local accumulator = Vector3.new(1, 1, 1)
	--[[
		5, 6, 1, 2, 3	shape
		x, y, x, y, z 
		1, 4, 1, 1, 2	index

		BoardGenerator was written with x and y as the ground plane, and z as the vertical axis
		However, Roblox uses y for vertical, so we swap the y and z values
	]]
	local function buildTriples(input: { number }): { { number } }
		-- {x3, y3, x2, y2, z2, x1, y1, z1} to
		-- {{x1, y1, z1}, {x2, y2, z2}, {x3, y3}}
		local triple = { 0, 0, 0 }
		local tripleGroups = {}
		for i = #input, 1, -1 do
			table.insert(triple, 1, input[i])
			if #triple == 3 or i == 1 then
				table.insert(tripleGroups, 1, triple)
				triple = {}
			end
		end
		return tripleGroups
	end

	local xyzGroups = buildTriples(arr)
	local shapeGroups = buildTriples(board.Shape)
	local arrBoardPosition = { 0, 0, 0 }
	local accumulator = { 1, 1, 1 }

	for i = 1, #arr do
		local level = (i + 2 - (i - 1) % 3) / 3 -- floor divison + offset
		local xyz = xyzGroups[level]
		if level == 1 then
			for j, v in ipairs(xyz) do
				arrBoardPosition[j] += (v - 1)
			end
		else
			local shape = shapeGroups[level - 1]
			for k, v in ipairs(shape) do
				-- print(k)
				accumulator[k] *= v
				arrBoardPosition[k] += xyz[k] * accumulator[k]
			end
		end
	end

	local vector3BoardPosition = Vector3.new(arrBoardPosition[1], arrBoardPosition[3], arrBoardPosition[2]) -- SWAP Y AND Z

	self.TextPart = TP.new(Vector3.new(4.5, 2, 4.5), CFrame.new(board.Position + vector3BoardPosition * TILE_CUBE_SIZE))
	self.Activated = false
	self.Board = board
	self.Value = value
	self.Idx = arr
	self.Flagged = false
	self.TextPart:RegisterClick(function()
		self:Activate()
	end, function()
		self:ToggleFlag()
	end)
	return self
end

function Tile:Activate()
	-- print("clicked!")
	if self.Activated then
		return
	end
	self.Activated = true
	self.TextPart:UnregisterClick()
	return self:Reveal()
end

function Tile:Reveal()
	self.TextPart.Part.BrickColor = BrickColor.new("Light stone grey")
	if self.Value == 0 then
		self.TextPart.Part.Transparency = 1
		self.TextPart.Part.CanCollide = false
		local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
		for _, tile in ipairs(nearbyTiles) do
			-- all nearby tiles must not be mines because curr is 0
			-- so no need to check for mines
			BoardGen.get(self.Board.Tiles, tile):Activate()
		end
	else
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	end
end

function Tile:ToggleFlag()
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.TextPart.Label.Text = "*Flag*"
		self.Board.FlagsCount = self.Board.FlagsCount + 1
	else
		self.TextPart.Label.Text = ""
		self.Board.FlagsCount = self.Board.FlagsCount - 1
	end
	return self.Board:UpdateMinesCounter()
end
-- pass a function to Tile to update mines counter instead of the entire board
return Tile
