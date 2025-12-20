--!strict

local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Remote = require(shared.remotes)
local BG = require(shared.BoardGenerator)
local Board = require(server.Board)

local Refresh = Remote.getBindableEvent("Refresh")
local ClearBoard = Remote.getEvent("ClearBoard")
local Ready = Remote.getEvent("Ready")

local DENSITIES = table.freeze({ 0.2, 0.15, 0.07, 0.025 })

local SPECTATORS: Team
local PLAYERS: Team

local InitHelpers = {}

InitHelpers.SPECTATORS = nil :: Team?
InitHelpers.PLAYERS = nil :: Team?

function InitHelpers.StartGame()
	print("Initializing... in 10 sec")
	local shape = BG.getRandomShape()
	local mineMultiplier = math.random() / 5 + 0.9 -- 0.9 to 1.1
	-- TODO: handle or make sure this doesn't cause more mines than there are tiles
	local totalNumTiles = 1
	for _, dim in shape do
		totalNumTiles *= dim
	end
	local mines = math.floor(mineMultiplier * DENSITIES[#shape] * totalNumTiles)

	Board.new(shape, mines, Vector3.new(0, 0, 0))
	-- Board.new({ 8, 8, 8, 4 }, 50, Vector3.new(0, 0, 0))

	print("Ready!")
	task.wait(2)

	for _, player in SPECTATORS:GetPlayers() do
		player.Team = PLAYERS
	end

	Refresh.Event:Wait()
	print("finished game")
	task.wait(5)
	for _, player in PLAYERS:GetPlayers() do
		player.Team = SPECTATORS
	end

	ClearBoard:FireAllClients()
	Ready.OnServerEvent:Wait()
	task.wait(2)
end

function InitHelpers.InitTeams()
	SPECTATORS = Instance.new("Team")
	SPECTATORS.Parent = Teams
	SPECTATORS.Name = "Spectators"
	SPECTATORS.AutoAssignable = false
    SPECTATORS.TeamColor = BrickColor.Gray()
	InitHelpers.SPECTATORS = SPECTATORS

	PLAYERS = Instance.new("Team")
	PLAYERS.Parent = Teams
	PLAYERS.Name = "Playing"
	PLAYERS.AutoAssignable = false
    PLAYERS.TeamColor = BrickColor.Blue()
	InitHelpers.PLAYERS = PLAYERS

    -- if there are players in game already
	for _, player in Players:GetPlayers() do
		player.Team = SPECTATORS
	end
end

return InitHelpers
