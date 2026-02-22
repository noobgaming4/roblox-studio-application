local module = {}

local TypeStates = {
	InfantrySMG = require(script.States_InfantrySMG),
	Monster = require(script.States_Monster),
	Spike = require(script.States_Spike)
}

function module.ChangeState(NPCTable, NewStateName)
	if NewStateName == NPCTable.State then
		NPCTable.NextState = nil
		return
	end
	TypeStates[NPCTable.Type][NPCTable.State].Leave(NPCTable)
	NPCTable.State = NewStateName
	TypeStates[NPCTable.Type][NPCTable.State].Enter(NPCTable)
end

function module.Update(NPCTable, DeltaTime)
	if NPCTable.NextState then
		module.ChangeState(NPCTable, NPCTable.NextState)
		NPCTable.NextState = nil
	end
	TypeStates[NPCTable.Type][NPCTable.State].Update(NPCTable, DeltaTime)
end

return module
