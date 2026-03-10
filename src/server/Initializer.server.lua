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
local StartGame = Remote.getEvent("StartGame")
local EndGame = Remote.getEvent("EndGame")
local ResetGame = Remote.getEvent("ResetGame")
local ActivateTextParts = Remote.getEvent("ActivateTextParts")
local ActivateTile = Remote.getEvent("ActivateTile")
local ToggleFlag = Remote.getEvent("ToggleFlag")
local Flag = Remote.getEvent("Flag")
local Refresh = Remote.getBindableEvent("Refresh")
local ClientReady = Remote.getEvent("ClientReady")

local PLAYERS = TeamsHelpers.GetPlayers()
local SPECTATORS = TeamsHelpers.GetSpectators()

type GameStates = "Loading" | "Playing" | "Intermission"
local GameState: GameStates = "Intermission"

local board: Board.Board

local ReadyPlayers: { [Player]: boolean } = {}

local function OnPlayerAdded(player: Player)
	TeamsHelpers.SetSpectator(player)
	Leaderboard.leaderboardSetup(player)
	DataSave.InitData(player)
	ReadyPlayers[player] = false
end
local function Onboard(player: Player)
	-- player joined as spectator mid game
	if GameState == "Loading" or GameState == "Playing" then
		assert(board, "Board is nil while GameState is Loading/Playing")
		NewGame:FireClient(player, board.Shape)
		board:Onboard(player)
	end
end

-- players in game before server loads
for _, player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, player)
end
-- players joined after server loads
Players.PlayerAdded:Connect(function(player)
	OnPlayerAdded(player)
end)
-- player finishes loading and ready for onboarding
-- this might fire before server loads TODO: handle this
ClientReady.OnServerEvent:Connect(function(player)
	ReadyPlayers[player] = true
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

Players.PlayerRemoving:Connect(function(player)
	DataSave.Save(player)
	ReadyPlayers[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			DataSave.Save(player)
		end)
	end
	task.wait(3)
end)

while true do
	-- TODO: refactor this to make the states make more sense
	-- state change should not be in the middle of a block of code

	-- create board and replicate it to spectators
	-- all players are spectators at this point
	-- NewGame for players who are already joined and loaded
	print("Loading")
	board = Board.new()
	repeat
		task.wait()
	until #SPECTATORS:GetPlayers() >= 1
	for _, player in Players:GetPlayers() do
		if ReadyPlayers[player] then
			NewGame:FireClient(player, board.Shape)
		end
	end
	GameState = "Loading"
	-- Onboard for players who load after this point
	task.wait(5)

	-- move spectators to playing
	-- players who join at this point stay as spectators
	print("Playing")
	for _, player in SPECTATORS:GetPlayers() do
		player.Team = PLAYERS
	end
	StartGame:FireAllClients()
	GameState = "Playing"
	local victory = Refresh.Event:Wait()
	if victory then
		for _, player in PLAYERS:GetPlayers() do
			Leaderboard.addWin(player)
		end
	end
	board:Destroy()
	task.wait(3)

	-- clear board and move players back to spectators
	-- players who join at this point are not onboarded
	print("finished game")
	GameState = "Intermission"
	for _, player in PLAYERS:GetPlayers() do
		player.Team = SPECTATORS
	end
	ResetGame:FireAllClients()
	task.wait(2)
end
