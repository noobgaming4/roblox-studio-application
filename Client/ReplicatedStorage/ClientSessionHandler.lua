local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local CameraHandler = require(script.CameraHandler)
local MovementModule = require(script.Movement)
local ToolHandler = require(script.ToolHandler)
local Weather = require(script.Weather)
local CrosshairHandler = require(script.CrosshairHandler)
local MainMenuModule = require(script.MainMenu)
local WaveUI = require(script.Wave)
local MainHudHandler  = require(script.MainHudHandler)

local module = {}

local Session = nil

function module.Init()
	Session = {}

	Weather.StartSounds()
	ToolHandler.Setup()
end

function module.CharacterAdded()
	local Character = Player.Character
	
	WaveUI.DisplayGui()
	MainHudHandler.CharacterAdded(Character)
	MovementModule.CharacterAdded()
	CameraHandler.CharacterAdded()
	ToolHandler.CharacterAdded()
	Weather.CharacterAdded()
	CrosshairHandler.CharacterAdded()
end 

function module.CharacterDied()
	local Character = Player.Character
	
	MovementModule.CharacterDied()
	CameraHandler.CharacterDied()
	ToolHandler.CharacterDied()
	Weather.CharacterDied()
	CrosshairHandler.CharacterDied()
end

function module.BanishToMainMenu()
	MainMenuModule.BanishToMainMenu()
end

return module
