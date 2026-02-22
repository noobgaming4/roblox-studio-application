local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Mouse = Player:GetMouse()

local module = {}

local TweeningTime = 0
module.RunC = nil
module.CrosshairLevel = 0
module.DesiredCrosshairLevel = 0
function module.EnableCrosshair(ClientSession)
	
	UserInputService.MouseIconEnabled = false
	
	local CrosshairUI = Player.PlayerGui:WaitForChild("Crosshair_Plus")--UIHandler.CrosshairUI
	CrosshairUI.Enabled = true
	
	local OriginalFrameBotP = CrosshairUI.Frame.FrameBot.Position
	local OriginalFrameTopP = CrosshairUI.Frame.FrameTop.Position
	local OriginalFrameRightP = CrosshairUI.Frame.FrameRight.Position
	local OriginalFrameLeftP = CrosshairUI.Frame.FrameLeft.Position
		
	module.RunC = RunService.RenderStepped:Connect(function(DeltaTime)
		module.CrosshairLevel = module.CrosshairLevel + (module.DesiredCrosshairLevel - module.CrosshairLevel) * 0.15	
		
		CrosshairUI.Frame.FrameTop.Position = OriginalFrameTopP + UDim2.fromOffset(0, -module.CrosshairLevel)
		CrosshairUI.Frame.FrameBot.Position = OriginalFrameBotP + UDim2.fromOffset(0, module.CrosshairLevel)
		CrosshairUI.Frame.FrameRight.Position = OriginalFrameRightP + UDim2.fromOffset(module.CrosshairLevel, 0)
		CrosshairUI.Frame.FrameLeft.Position = OriginalFrameLeftP + UDim2.fromOffset(-module.CrosshairLevel, 0)
		
		CrosshairUI.Frame.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
		
		if TweeningTime > 0 and os.clock() - TweeningTime > 0.3 then
			TweeningTime = 0
			local WhiteColor = Color3.fromRGB(255,255,255)
			CrosshairUI.Frame.FrameTop.BackgroundColor3 = WhiteColor
			CrosshairUI.Frame.FrameBot.BackgroundColor3 = WhiteColor
			CrosshairUI.Frame.FrameRight.BackgroundColor3 = WhiteColor
			CrosshairUI.Frame.FrameLeft.BackgroundColor3 = WhiteColor
		end
	end)
end

function module.FlashColor(Color : Color3)
	TweeningTime = os.clock()
	
	local CrosshairUI = Player.PlayerGui:FindFirstChild("Crosshair_Plus")
	
	CrosshairUI.Frame.FrameTop.BackgroundColor3 = Color
	CrosshairUI.Frame.FrameBot.BackgroundColor3 = Color
	CrosshairUI.Frame.FrameRight.BackgroundColor3 = Color
	CrosshairUI.Frame.FrameLeft.BackgroundColor3 = Color
end

function module.SetCrosshairLevel(Level)
	module.DesiredCrosshairLevel = Level
end

function module.SetCrosshairLevelForce(Level)
	module.CrosshairLevel = Level
end

function module.DisableCrosshair()
	if module.RunC then
		module.RunC:Disconnect()
		module.RunC = nil
	end
	
	local CrosshairUI = Player.PlayerGui:FindFirstChild("Crosshair_Plus")
	if  CrosshairUI then
		CrosshairUI.Enabled = false
	end
	
	UserInputService.MouseIconEnabled = true
end

function module.CharacterAdded(ClientSession, UIHandler)
	module.CrosshairLevel = 0
	module.DesiredCrosshairLevel = 0
end

function module.CharacterDied(ClientSession, UIHandler)
	module.DisableCrosshair()
end


return module
