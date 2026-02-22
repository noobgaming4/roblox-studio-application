local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local ToolModules = {}

local MainHudHandler = require(script.Parent.MainHudHandler)

local module = {}


local AddedC = nil

function module.Setup()
	for i,v in script:GetDescendants() do
		if v:IsA("ModuleScript") then
			ToolModules[v.Name] = require(v)
		end
	end
end

local CurrentToolModule = nil
local CurrentTool = nil
function module.CharacterAdded()
	local Character : Model = Player.Character
	
	local RegisteredTools = {}
	
	
	local function AddTool(Child : Tool)
		if Child:IsA("Tool") and Child:FindFirstChild("ToolType") and not RegisteredTools[Child] then
			RegisteredTools[Child] = true

			local ToolType = Child.ToolType.Value
			local ToolModule = ToolModules[ToolType]

			ToolModule.Added(Player, Child)
			
			
			
			Child.Equipped:Connect(function()
				CurrentToolModule = ToolModule
				CurrentTool = Child
				MainHudHandler.SetToolVisible(true)
				MainHudHandler.SetToolName(CurrentTool.DisplayName.Value)
				ToolModule.Equipped(Player,Child)
			end)

			Child.Unequipped:Connect(function()
				CurrentToolModule = nil
				CurrentTool = nil
				ToolModule.Unequipped(Player,Child)
				
				if not Player.Character:FindFirstChildOfClass("Tool") then
					MainHudHandler.SetToolVisible(false)
				end
			end)
			
			Child.Destroying:Connect(function()
				ToolModule.Removed(Player,Child)
			end)
		end
	end
	
	AddedC = Player.Backpack.ChildAdded:Connect(function(Child)
		AddTool(Child)
	end)
	
	for i,v in Player.Backpack:GetChildren() do
		AddTool(v)
	end
	
end

function module.CharacterDied()
	if AddedC then
		AddedC:Disconnect()
		AddedC = nil
	end
	if CurrentToolModule then
		CurrentToolModule.Unequipped(Player, CurrentTool)
	end
end

return module
