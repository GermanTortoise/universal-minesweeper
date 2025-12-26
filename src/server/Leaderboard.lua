--!strict

local Leaderboard = {}

function Leaderboard.leaderboardSetup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats
end

function Leaderboard.addWin(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	print("Adding win")
	if leaderstats then
		local wins = leaderstats:FindFirstChild("Wins") :: IntValue
		if wins then
			wins.Value += 1
		end
	end
end

return Leaderboard
