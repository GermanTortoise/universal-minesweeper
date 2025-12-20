--!strict
local shared = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService")

local Players = game:GetService("Players")

local InitHelpers = require(server.InitHelpers)


InitHelpers.InitTeams()
print("welcome\n")

Players.PlayerAdded:Connect(function(Player)
	if InitHelpers.SPECTATORS then
		Player.Team = InitHelpers.SPECTATORS
	end
end)

task.wait(3) -- should match delay between rounds
			 -- the delay before the first round (when server starts)

while true do
	InitHelpers.StartGame()
end
-- TODO: stop detecting clicks after game over cuz it breaks things
-- but also gotta fix the root cause of stuff not deleting correctly
