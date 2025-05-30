--!strict
local shared = game:GetService("ReplicatedStorage")
local Types = require(shared.Types)

local Tile = {} :: Types.TileImpl
Tile.__index = Tile

function Tile.new(val, idx)
	local self = setmetatable({}, Tile)
	self.Activated = false
	self.Flagged = false
	self.NearbyTiles = {}
	self.Value = val
	self.Idx = idx
	return self
end

function Tile:ToggleFlag()
	if self.Activated then
		return false
	end
	self.Flagged = not self.Flagged
	return self.Flagged
end

function Tile:HasCorrectNumberFlags()
	local nearbyFlags = 0
	for _, tile in self.NearbyTiles do
		if tile.Flagged then
			nearbyFlags += 1
		end
	end
	return self.Value == nearbyFlags
end

return Tile
