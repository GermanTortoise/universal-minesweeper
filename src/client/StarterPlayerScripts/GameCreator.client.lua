--!strict

local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")
local EndGame = Remote.getEvent("EndGame")
local ClearBoard = Remote.getEvent("ClearBoard")
local Ready = Remote.getEvent("Ready")

local GameController = require(client.StarterPlayerScripts.GameController)

local Game: GameController.GameController?

NewGame.OnClientEvent:Connect(function(shape: { number }, pos: Vector3)
	Game = GameController.new(shape, pos)
end)

EndGame.OnClientEvent:Connect(function(tilesRevealed: { { number } }, revealed: boolean)
	if Game then
		Game:EndGame(tilesRevealed, revealed)
	end
end)

ClearBoard.OnClientEvent:Connect(function()
	if Game then
		Game:Destroy()
	end
	Game = nil
	Ready:FireServer()
end)
