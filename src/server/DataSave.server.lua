-- Make sure "Enable Studio Access To API Services" is on in Game Settings! (*OR IT WON'T WORK*) --
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Saver = DataStoreService:GetDataStore("SaveLeaderstats")

Players.PlayerAdded:Connect(function(player)
	local Data
	local success, errormessage = pcall(function()
		Data = Saver:GetAsync(tostring(player.UserId))
	end)

	if not success then
		error(errormessage)
	end

	if Data then
		for i, v in Data do
			player:WaitForChild("leaderstats"):WaitForChild(i).Value = v
		end
	end
end)

local function Save(player)
	local SavedData = {}
	for _, v in pairs(player.leaderstats:GetChildren()) do
		SavedData[v.Name] = v.Value
	end

	local success, errormessage = pcall(function()
		Saver:SetAsync(tostring(player.UserId), SavedData)
	end)
	
	if not success then
		error(errormessage)
	end
end

Players.PlayerRemoving:Connect(Save)

game:BindToClose(function()
	for _, v in Players:GetPlayers() do
		Save(v)
	end
end)
