local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")

local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")

local GameController = require(client.StarterPlayerScripts.GameController)

NewGame.OnClientEvent:Connect(function(shape: { number }, pos: Vector3)
	GameController.new(shape, pos)
end)
