local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")
local client = game:GetService("StarterPlayer")

local Players = game:GetService("Players")

local Remote = require(shared.remotes)
local Board = require(server.Board)
local TeamsHelpers = require(shared.TeamsHelpers)
local DataSave = require(server.DataSave)
local Leaderboard = require(server.Leaderboard)

local NewGame = Remote.getEvent("NewGame")
local GameStarted = Remote.getEvent("GameStarted")
local EndGame = Remote.getEvent("EndGame")
local ResetGame = Remote.getEvent("ResetGame")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local ActivateTile = Remote.getEvent("ActivateTile")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local Flag = Remote.getEvent("Flag")
local Refresh = Remote.getBindableEvent("Refresh")
local ClientReady = Remote.getEvent("ClientReady")

-- local Ready = Remote.getEvent("Ready")

local PLAYERS = TeamsHelpers.GetPlayers()
local SPECTATORS = TeamsHelpers.GetSpectators()

type GameStates = "Loading" | "Playing" | "Intermission"
local GameState: GameStates

local board

local function OnPlayerAdded(player: Player)
	TeamsHelpers.SetSpectator(player)
	Leaderboard.leaderboardSetup(player)
	DataSave.InitData(player)
end
local function Onboard(player: Player)
	-- player joined as spectator mid game
	if GameState == "Playing" then
		assert(board, "Board is nil while GameState is Playing")
		NewGame:FireClient(player, board.Shape)
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, player)
end
Players.PlayerAdded:Connect(function(player)
	OnPlayerAdded(player)
end)
ClientReady.OnServerEvent:Connect(function(player)
	Onboard(player)
end)

-- task.spawn(function()
-- 	while task.wait(120) do
-- 		for _, player in Players:GetPlayers() do
-- 			task.spawn(function()
-- 				DataSave.Save(player)
-- 			end)
-- 		end
-- 	end
-- end)

Players.PlayerRemoving:Connect(DataSave.Save)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			DataSave.Save(player)
		end)
	end
	task.wait(3)
end)

while true do
	-- create board and replicate it to spectators
	-- all players are spectators at this point
	-- players who join at this point are treated the same as players already joined
	print("Loading")
	GameState = "Loading"
	board = Board.new()
	repeat
		task.wait()
	until #SPECTATORS:GetPlayers() >= 1
	NewGame:FireAllClients(board.Shape)
	task.wait(2)

	-- move spectators to playing
	-- players who join at this point stay as spectators
	print("Playing")
	GameState = "Playing"
	for _, player in SPECTATORS:GetPlayers() do
		player.Team = PLAYERS
	end
	GameStarted:FireAllClients()
	local victory = Refresh.Event:Wait()
	if victory then
		for _, player in PLAYERS:GetPlayers() do
			Leaderboard.addWin(player)
		end
	end
	task.wait(3)

	-- clear board and move players back to spectators
	-- players who join at this point are treated the same as players already joined
	print("finished game")
	GameState = "Intermission"
	for _, player in PLAYERS:GetPlayers() do
		player.Team = SPECTATORS
	end
	ResetGame:FireAllClients()
	task.wait(2)

	-- Ready.OnServerEvent:Wait()
end
