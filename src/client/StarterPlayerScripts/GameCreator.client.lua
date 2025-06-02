local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")
local GameController = require(client.StarterPlayerScripts.GameController)

NewGame.OnClientEvent:Connect(function(shape, pos)
	GameController.new(shape, pos)
end)
-- GameController.new({ 1, 2 }, Vector3.new(0, 0, 0))
