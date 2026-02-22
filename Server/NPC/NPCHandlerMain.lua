local Cells = require(script.Cells)
local SharedNPCTable = require(script.SharedNPCTable)

local NPC_Types = {}

local NPC_UPDATE_RATE = 0.1

local module = {}

function module.Init()
	Cells.Start()

	for i,v in script.Types:GetChildren() do
		NPC_Types[v.Name] = require(v)
	end
	
	task.spawn(function()
		while task.wait(NPC_UPDATE_RATE) do
			for i,NPCTable in SharedNPCTable.UpdateQueue do
				task.spawn(function()
					
					NPC_Types[NPCTable.Type].Update(NPCTable, NPC_UPDATE_RATE) 
				end)
			end
		end
	end)

end

function module.SpawnNPC(TypeName, Overwrite)
	local NPCTable = NPC_Types[TypeName].Spawn(Overwrite)
	NPCTable.Context = {}
	NPCTable.Type = TypeName
	table.insert(SharedNPCTable.NPCs, NPCTable)
	
	return NPCTable
end

return module
