local module = {}

local Cells = {}
local Entities = {}

local UPDATE_RATE = 1

local CELL_SIZE = 300

local function Vector3ToCellPosition(Pos : Vector3)
	return Vector2.new( math.floor(Pos.X / CELL_SIZE), math.floor(Pos.Z / CELL_SIZE) )
end

local function RemoveFromCell(Entity)
	local OldCell =  Cells[Entity.CellPosition.X] and Cells[Entity.CellPosition.X][Entity.CellPosition.Y] or false
	
	if OldCell then
		local Find = table.find(OldCell, Entity)
		if Find then
			table.remove(OldCell, Find)
		end
		

		if #OldCell == 0 then
			Cells[Entity.CellPosition.X][Entity.CellPosition.Y] = nil

			local X_Count = 0
			for i,v in Cells[Entity.CellPosition.X] do
				X_Count += 1
			end
			if X_Count == 0 then
				Cells[Entity.CellPosition.X] = nil
			end
		end
	end
	
end

local function UpdateEntity(Entity)
	
	local Pos : Vector2 = Vector3ToCellPosition(Entity.Model.PrimaryPart.Position)
	
	if not (Pos == Entity.CellPosition) then
		
		if Entity.CellPosition then
			RemoveFromCell(Entity)
		end
		
		
		if not Cells[Pos.X] then
			Cells[Pos.X] = {}
		end
		if not Cells[Pos.X][Pos.Y] then
			Cells[Pos.X][Pos.Y] = {}
		end

		table.insert(Cells[Pos.X][Pos.Y], Entity)
		
		Entity.CellPosition = Pos
	end
	
end

local function DestroyEntity(Entity)
	RemoveFromCell(Entity)
	
	local Find = table.find(Entities, Entity)
	if Find then
		table.remove(Entities, Find)
	end
	
end

local function MakeEntity(Character : Model)
	local Entity = {
		Model = Character,
		CellPosition = nil--Vector3ToCellPosition(Character.PrimaryPart.Position),
	}
	table.insert(Entities, Entity)
	local Humanoid : Humanoid = Character.Humanoid
	
	Humanoid.Died:Connect(function()
		DestroyEntity(Entity)
	end)
	
	Character.Destroying:Connect(function()
		DestroyEntity(Entity)
	end)
	
	UpdateEntity(Entity)
	
	return Entity
end

local function Update()
	for i,v in Entities do
		UpdateEntity(v)
	end
end

function module.GetEntitiesInCellFromPosition(Position: Vector3)
	local CellPosition = Vector3ToCellPosition(Position)
	local results = {}

	for dx = -1, 1 do
		for dy = -1, 1 do
			local x = CellPosition.X + dx
			local y = CellPosition.Y + dy
			local column = Cells[x]
			if column then
				local cellEntities = column[y]
				if cellEntities then
					for _, entity in cellEntities do
						table.insert(results, entity)
					end
				end
			end
		end
	end

	return results
end


function module.MakeEntity(Character)
	MakeEntity(Character)
end

function module.Start()
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			Update()
		end
	end)
	
end

return module
