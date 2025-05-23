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

local Tile = {} :: Types.TileImpl
Tile.__index = Tile

function Tile.new()
	local self = setmetatable({}, Tile)
	self.Activated = false
	self.Flagged = false
	self.NearbyTiles = {}
	return self
end

return Tile
