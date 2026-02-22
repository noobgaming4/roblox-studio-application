local RunService = game:GetService("RunService")

local Player = game:GetService("Players").LocalPlayer

local module = {}

local Camera = workspace.CurrentCamera

local Base = "Default"

local Modifiers = {}

local Bases = {}

function Bases.Default()
	return Camera.CFrame
end

local RunConnection = nil

function module.CharacterAdded()
	RunConnection = RunService.RenderStepped:Connect(function(DeltaTime)
		local CF1 = Bases[Base]()
		
		for i,v in Modifiers do
			CF1 *= v(DeltaTime)
		end
		
		if Camera.CFrame ~= CF1 then
			Camera.CFrame = CF1
		end
		
	end)
end

function module.CharacterDied()
	if RunConnection then
		RunConnection:Disconnect()
		RunConnection = nil
	end
	
	Modifiers = {}
end

function module.SetModifier(Name, Function)
	Modifiers[Name] = Function
end

function module.RemoveModifier(Name)
	Modifiers[Name] = nil
end

function module.SetBase(Name)
	Base = Name
end

return module
