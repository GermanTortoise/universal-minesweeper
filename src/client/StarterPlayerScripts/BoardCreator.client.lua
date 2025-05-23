local shared = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer")
local Remote = require(shared.remotes)

local NewGame = Remote.getEvent("NewGame")
local BoardController = require(client.StarterPlayerScripts.BoardController)

NewGame.OnClientEvent:Connect(function(a, b)
	print("in the firing")
	BoardController.new(a, b)
end)
-- BoardController.new({ 1, 2 }, Vector3.new(0, 0, 0))
