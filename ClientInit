
if game:IsLoaded() == false then
	game.Loaded:Wait()
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ClientSessionHandler = require(Modules:WaitForChild("ClientSessionHandler"))
local SendToServer = require(Modules:WaitForChild("SendServer"))
local ReceiveFromServer = require(Modules:WaitForChild("ReceiveFromServer"))

local DeathHandled = false
Player.CharacterAdded:Connect(function(Character)
	DeathHandled = false
	
	local Humanoid : Humanoid = Character:WaitForChild("Humanoid",0.3)
	Humanoid.Died:Connect(function()
		if DeathHandled == false then
			DeathHandled = true
			ClientSessionHandler.CharacterDied()
		end
		
	end)
	
	Character.Destroying:Connect(function()
		if DeathHandled == false then
			DeathHandled = true
			ClientSessionHandler.CharacterDied()
		end
	end)
	
	ClientSessionHandler.CharacterAdded()
end)

ClientSessionHandler.Init()

ReceiveFromServer.Start()
SendToServer.StartSending()

script.MainMenu.Parent = Player.PlayerGui
ClientSessionHandler.BanishToMainMenu()

SendToServer.AddPackage({
	Type = "Loaded",
	Data = true
})
