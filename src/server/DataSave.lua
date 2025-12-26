local DataStoreService = game:GetService("DataStoreService")
local Saver = DataStoreService:GetDataStore("SaveLeaderstats")

local DataSave = {}

function DataSave.InitData(player: Player)
	local Data
	local success, errormessage = pcall(function()
		Data = Saver:GetAsync(tostring(player.UserId))
	end)

	if not success then
		warn(errormessage)
	end

	if Data then
		for i, v in Data do
			player:WaitForChild("leaderstats"):WaitForChild(i).Value = v
		end
	end
end

function DataSave.Save(player: Player)
	local SavedData = {}
	for _, v in pairs(player.leaderstats:GetChildren()) do
		SavedData[v.Name] = v.Value
	end

	local success, errormessage = pcall(function()
		Saver:SetAsync(tostring(player.UserId), SavedData)
	end)
	
	if not success then
		warn(errormessage)
	end
end

return DataSave