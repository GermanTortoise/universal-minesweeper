local TextPart = require(script.Parent.TextPart)
local BoardGen = require(script.Parent.Parent:WaitForChild("BoardGenerator"))

local Tile = setmetatable({}, TextPart)
Tile.__index = Tile

function Tile:new(board, value, idx)
	local TILE_CUBE_SIZE = 5
	local absPos = Vector3.new() -- x, y, z THEY ARE DIFFERENTTTTTTTT	ignore
	local accumulator = Vector3.new(1, 1, 1)

	-- 5, 6, 1, 2, 3
	-- x, y, x, y, z
	-- 1, 4, 1, 1, 2
	for i = #idx, 1, -1 do
		local relativeIdx = (i - 1) % 3 + 1
		local backwardsIdx = #idx - i + 1
		-- print(i)
		-- print(relativeIdx, backwardsIdx)
		-- print(idx)
		local shape = board.Shape
		if relativeIdx == 1 then -- x
			-- TODO: refactor
			if backwardsIdx <= 3 then
				-- last three vals in [idx] are local pos in each 3d "chunk"
				absPos += Vector3.new(idx[i], 0, 0)
			else
				accumulator *= Vector3.new(shape[i + 3], 1, 1)
				absPos += Vector3.new(idx[i] * (accumulator.X + 1), 0, 0)
			end
		elseif relativeIdx == 3 then
			if backwardsIdx <= 3 then
				-- last three vals in [idx] are local pos in each 3d "chunk"
				absPos += Vector3.new(0, idx[i], 0)
			else
				accumulator *= Vector3.new(1, shape[i + 3], 1)
				absPos += Vector3.new(0, idx[i] * (accumulator.Y + 1), 0)
			end
		else
			if backwardsIdx <= 3 then
				-- last three vals in [idx] are local pos in each 3d "chunk"
				absPos += Vector3.new(0, 0, idx[i])
			else
				accumulator *= Vector3.new(1, 1, shape[i + 3])
				absPos += Vector3.new(0, 0, idx[i] * (accumulator.Z + 1))
			end
		end
	end

	self = TextPart:new(
		Vector3.new(4.5, 2, 4.5),
		CFrame.new(board.Position + absPos * TILE_CUBE_SIZE), -- x, z, y FROM THISSSSS 	ignore
		idx
	)
	setmetatable(self, Tile)
	self.Activated = false
	self.Board = board
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
		self.Part.Transparency = 1
		self.Part.CanCollide = false
		local nearbyTiles = BoardGen.indexNearbyTiles(self.Idx, self.Board.Shape)
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
