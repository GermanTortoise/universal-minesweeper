--!strict
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

-- local Ready = Remote.getEvent("Ready")

local PLAYERS = TeamsHelpers.GetPlayers()
local SPECTATORS = TeamsHelpers.GetSpectators()

local function OnPlayerAdded(player: Player)
	TeamsHelpers.SetSpectator(player)
	Leaderboard.leaderboardSetup(player)
	DataSave.InitData(player)
end

for _, player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, player)
end
Players.PlayerAdded:Connect(function(player)
	OnPlayerAdded(player)
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

task.wait(3) -- should match delay between rounds
-- the delay before the first round (when server starts)

while true do
	print("Initializing... in 10 sec")
	local board = Board.new()
	repeat
		task.wait()
	until #SPECTATORS:GetPlayers() >= 1
	NewGame:FireAllClients(board.Shape)
	print("Ready!")
	task.wait(2)

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
	print("finished game")
	task.wait(3)
	for _, player in PLAYERS:GetPlayers() do
		player.Team = SPECTATORS
	end
	ResetGame:FireAllClients()

	-- Ready.OnServerEvent:Wait()
	task.wait(2)
end
