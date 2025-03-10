local Tile = require(script.Parent.Tile)

local Mine = setmetatable({}, Tile)
Mine.__index = Mine

function Mine:new(board, idx)
	self = Tile:new(board, -1, idx)
	setmetatable(self, Mine)
	return self
end

function Mine:Reveal()
	self.Label.Text = "X"
	self.Part.BrickColor = BrickColor.new("Bright red")
	return self.Board:EndGame()
end

function Mine:ToggleFlag()
	Tile.ToggleFlag(self)
	if self.Flagged then
		self.Board.CorrectlyFlaggedMines = self.Board.CorrectlyFlaggedMines + 1
	else
		self.Board.CorrectlyFlaggedMines = self.Board.CorrectlyFlaggedMines - 1
	end
	return self.Board:CheckVictory()
end

return Mine
