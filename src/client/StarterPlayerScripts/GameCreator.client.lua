local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")
local BoardController = require(client.StarterPlayerScripts.GameController)

NewGame.OnClientEvent:Connect(function(shape, pos)
	BoardController.new(shape, pos)
end)
-- BoardController.new({ 1, 2 }, Vector3.new(0, 0, 0))
