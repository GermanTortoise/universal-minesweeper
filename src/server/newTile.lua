--!strict
local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")
local TP = require(client.StarterPlayerScripts.TextPart)
local BoardGen = require(shared.BoardGenerator)
local Types = require(shared.Types)
-- local MIM = require(client.StarterPlayerScripts.MouseInputsManager)

type TextPartType = Types.TextPart
type TileType = Types.TileImpl

local newTile = {}
newTile.__index = newTile

function newTile.new()
	local self = setmetatable({}, newTile)
	self.Activated = false
	self.Flagged = false
	self.NearbyTiles = {}
	return self
end

-- must do this after initializing all tiles
function newTile:InitNearbyTiles()
	local nearbyTiles = BoardGen.indexOfNearbyTiles(self.Idx, self.Board.Shape)
	for _, idx in nearbyTiles do
		table.insert(self.NearbyTiles, self.Board.Tiles[BoardGen.nDToFlatIndex(idx, self.Board.Shape)])
	end
end

return newTile
