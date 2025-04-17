--!strict
local TP = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))
local TilesMines = require(script.Parent.Parent:WaitForChild("TilesMines"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

type TextPartType = Types.TextPart
type TileType = Types.TileImpl

local Tile: TileType = {} :: TileType
Tile.__index = Tile

function Tile.new(board, value, nDIdx)
	local self = setmetatable({}, Tile)
	local TILE_SPACING = 5
	local TILE_SIZE = Vector3.new(4.5, 2, 4.5)
	local tilePos = TilesMines.getBoardPosition(nDIdx, board.Shape)
	self.TextPart = TP.new(TILE_SIZE, CFrame.new(board.Position + tilePos * TILE_SPACING))
	self.Activated = false
	self.Board = board
	self.Value = value
	self.Idx = nDIdx
	self.Flagged = false
	self.TextPart:RegisterClick(function()
		self:Activate()
	end, function()
		TilesMines.toggleFlag(self) -- refactor to use self
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
		for _, idx in nearbyTiles do
			-- all nearby tiles must not be mines because curr is 0
			-- so no need to check for mines
			local tile = self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)] :: Types.Tile
			tile:Activate()
		end
	else
		self.TextPart.Label.Text = tostring(self.Value)
		self.TextPart.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	end
end

-- function Tile:ToggleFlag()
-- 	self.Flagged = not self.Flagged
-- 	if self.Flagged then
-- 		self.TextPart.Label.Text = "*Flag*"
-- 		self.Board.FlagsCount = self.Board.FlagsCount + 1
-- 	else
-- 		self.TextPart.Label.Text = ""
-- 		self.Board.FlagsCount = self.Board.FlagsCount - 1
-- 	end
-- 	return self.Board:UpdateMinesCounter()
-- end
-- pass a function to Tile to update mines counter instead of the entire board
return Tile
