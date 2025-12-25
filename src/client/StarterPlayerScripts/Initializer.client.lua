--!strict

local client = game:GetService("StarterPlayer")
local shared = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameController = require(shared.GameController)
local MIM = require(shared.MouseInputsManager)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
MIM.Init(mouse)

GameController.new()
