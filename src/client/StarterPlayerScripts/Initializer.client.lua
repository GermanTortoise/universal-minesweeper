local client = game:GetService("StarterPlayer").StarterPlayerScripts

local Players = game:GetService("Players")

local MIM = require(client:WaitForChild("MouseInputsManager"))
local GameController = require(client.GameController)
local Chat = require(client.Chat)
-- local PlayerSettingsVis = require(client.PlayerSettingsVis)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
MIM.Init(mouse)

GameController.new()
Chat.init()
-- PlayerSettingsVis.init()