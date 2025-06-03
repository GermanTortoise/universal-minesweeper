local shared = game:GetService("ReplicatedStorage")
-- local client = game:GetService("StarterPlayer")
local server = game:GetService("ServerScriptService")

local Remotes = require(shared.remotes)

local Refresh = Remotes.getBindableEvent("Refresh")

local Board = require(server.Board)
while true do
	print("Initializing... in 10 sec")
	task.wait(5)
	-- local gameElements = script.Parent:WaitForChild("GameElements")

	-- local MouseInputsManager = client.StarterPlayerScripts:WaitForChild("MouseInputsManager")
	-- MouseInputsManager.initialize()
	print("go!")
	Board.new({ 6, 6 }, 3, Vector3.new(0, 0, 0))
	print("Ready!")
	Refresh.Event:Wait()
	print("finished game")
end
