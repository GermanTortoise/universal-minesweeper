local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")

local Remote = require(shared.remotes)
local BG = require(shared.BoardGenerator)

local Refresh = Remote.getBindableEvent("Refresh")
local ClearBoard = Remote.getEvent("ClearBoard")
local Ready = Remote.getEvent("Ready")

local Board = require(server.Board)

local densities = { 0.2, 0.15, 0.07, 0.025 }

task.wait(2)
while true do
	print("Initializing... in 10 sec")
	local shape = BG.getRandomShape()
	local mineMultiplier = math.random() / 5 + 0.9 -- 0.9 to 1.1
	-- TODO: handle or make sure this doesn't cause more mines than there are tiles
	local totalNumTiles = 1
	for _, dim in shape do
		totalNumTiles *= dim
	end
	local mines = math.floor(mineMultiplier * densities[#shape] * totalNumTiles)

	Board.new(shape, mines, Vector3.new(0, 0, 0))
	-- Board.new({ 8, 8 }, 5, Vector3.new(0, 0, 0))

	print("Ready!")
	Refresh.Event:Wait()
	print("finished game")
	task.wait(5)
	ClearBoard:FireAllClients()
	Ready.OnServerEvent:Wait()
	task.wait(2)
end
-- TODO: stop detecting clicks after game over cuz it breaks things
-- but also gotta fix the root cause of stuff not deleting correctly
