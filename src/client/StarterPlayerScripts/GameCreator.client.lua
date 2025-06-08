local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")
local EndGame = Remote.getEvent("EndGame")
local ClearBoard = Remote.getEvent("ClearBoard")
local Ready = Remote.getEvent("Ready")

local GameController = require(client.StarterPlayerScripts.GameController)

local Game
NewGame.OnClientEvent:Connect(function(shape: { number }, pos: Vector3)
	Game = GameController.new(shape, pos)
end)

EndGame.OnClientEvent:Connect(function(tilesRevealed: { { number } }, revealed: boolean)
	Game:EndGame(tilesRevealed, revealed)
end)

ClearBoard.OnClientEvent:Connect(function()
	Game:Destroy()
	Game = nil
	Ready:FireServer()
end)
