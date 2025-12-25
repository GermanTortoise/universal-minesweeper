--!strict

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local initialized = false

local TeamsHelpers = {}

local function InitTeams()
	if initialized then
		return
	end
	TeamsHelpers._spectators = Instance.new("Team")
	TeamsHelpers._spectators.Parent = Teams
	TeamsHelpers._spectators.Name = "Spectators"
	TeamsHelpers._spectators.AutoAssignable = false
	TeamsHelpers._spectators.TeamColor = BrickColor.Gray()

	TeamsHelpers._players = Instance.new("Team")
	TeamsHelpers._players.Parent = Teams
	TeamsHelpers._players.Name = "Playing"
	TeamsHelpers._players.AutoAssignable = false
	TeamsHelpers._players.TeamColor = BrickColor.Blue()

	-- if there are players in game already
	-- for _, player in Players:GetPlayers() do
	-- 	player.Team = TeamsHelpers._spectators
	-- end
end

function TeamsHelpers.GetSpectators(): Team
	if not TeamsHelpers._spectators then
		error("SPECTATORS is nil")
	end
	return TeamsHelpers._spectators
end

function TeamsHelpers.GetPlayers(): Team
	if not TeamsHelpers._players then
		error("PLAYERS is nil")
	end
	return TeamsHelpers._players
end

InitTeams()

return TeamsHelpers
