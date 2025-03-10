local TextPart = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))

local Tile = setmetatable({}, TextPart)
Tile.__index = Tile

function Tile:new(board, value, idx)
	self = TextPart:new(Vector3.new(4.5, 2, 4.5), CFrame.new(board.Position + Vector3.new(idx[1] * 5, 0, idx[2] * 5)))
	setmetatable(self, Tile)
	self.Activated = false
	self.Board = board
	self.XPosition = idx[2]
	self.YPosition = idx[1]
	self.Value = value
	self.Idx = idx
	self:RegisterClick(function()
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
	self:UnregisterClick()
	return self:Reveal()
end

function Tile:Reveal()
	self.Part.BrickColor = BrickColor.new("Light stone grey")
	if self.Value == 0 then
		local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
		-- print(nearbyTiles)
		for _, tile in ipairs(nearbyTiles) do
			-- all nearby tiles must not be mines because curr is 0
			-- so no need to check for mines
			BoardGen.get(self.Board.Tiles, tile):Activate()
		end
	else
		self.Label.Text = self.Value
		self.Label.TextColor3 = Color3.fromHSV(self.Value / 8, 1, 0.75)
	end
end

function Tile:ToggleFlag()
	self.Flagged = not self.Flagged
	if self.Flagged then
		self.Label.Text = "*Flag*"
		self.Board.FlagsCount = self.Board.FlagsCount + 1
	else
		self.Label.Text = ""
		self.Board.FlagsCount = self.Board.FlagsCount - 1
	end
	return self.Board:UpdateMinesCounter()
end

return Tile
