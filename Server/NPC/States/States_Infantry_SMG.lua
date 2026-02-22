local Chat = game:GetService("Chat")
local Debris = game:GetService("Debris")

local module = {}

local Context = require(script.Parent.Parent.Context)
local SharedNPCTable = require(script.Parent.Parent.SharedNPCTable)
local HitterHandler = require(game:GetService("ServerStorage").Modules.HitterHandler)
local PathFinder = require(script.Parent.Pathfind)
local Voicelines = require(script.Parent.Parent.Parent.Voicelines)
local DamageHandler = require(game:GetService("ServerStorage").Modules.DamageHandler)


local MELEE_RANGE = 7
local MELEE_DAMAGE = 20

local function FireBurst(NPCTable, TargetPosition)
	NPCTable.CanUpdate = false

	for i = 1, math.random(3, 5) do

		HitterHandler.FireBulletNPC(NPCTable, NPCTable.Tool, TargetPosition)
		NPCTable.Animations.Fire:Play()
		task.wait(0.15)
	end

	NPCTable.CanUpdate = true
end

local function PlayVoiceline(NPCTable, Voicelines)
	local RandomVoice = Voicelines[math.random(1,#Voicelines)]
	local Sound : Sound = RandomVoice.Sound:Clone()
	Sound.Parent = NPCTable.Model.PrimaryPart
	
	Chat:Chat(NPCTable.Model.Head, RandomVoice.Line)
	Sound.PlaybackSpeed = math.random(95,105) / 100
	--Sound:Play()
	
	Debris:AddItem(Sound, Sound.TimeLength)
end

local RollAcceleration = 10
local function Roll(NPCTable)
	NPCTable.CanUpdate = false
	local PrimaryPart : Part = NPCTable.Model.PrimaryPart
	NPCTable.Animations.Roll:Play()
	PrimaryPart:ApplyImpulse( (PrimaryPart.AssemblyMass * RollAcceleration * 1) *  PrimaryPart.CFrame.LookVector )
	task.wait(1)
	NPCTable.CanUpdate = true
end

local function Melee(NPCTable, Target, DistanceToTarget)
	NPCTable.CanUpdate = false
	
	local MeleeAnim : AnimationTrack = NPCTable.Animations["Melee" .. tostring(math.random(1,2))]
	MeleeAnim:Play()
	
	NPCTable.Model.Humanoid:MoveTo(NPCTable.Model.PrimaryPart.Position)
	
	task.wait(0.6)
	
	local npcRoot = NPCTable.Model.PrimaryPart
	local targetRoot = Target:FindFirstChild("HumanoidRootPart")

	if npcRoot and targetRoot then
		local toTarget = (targetRoot.Position - npcRoot.Position).Unit
		local facingDot = npcRoot.CFrame.LookVector:Dot(toTarget)

		-- Only attack if facing roughly toward target (dot > 0.7 ≈ within ~45 degrees)
		if facingDot > 0.7 and DistanceToTarget < MELEE_RANGE then
			DamageHandler.DamageBullet(MELEE_DAMAGE, Target, Target.Humanoid, Vector3.new(0,300, 0), Target.Torso)
		end
	end
	
	task.wait(0.5)
	
	NPCTable.CanUpdate = true
end

local SQUAD_TALK_RATE = 3
local function SquadChatRequest(NPCTable, Voicelines)
	local Squad = SharedNPCTable.Squads[NPCTable.Squad]
	local LastChatTime = Squad.LastChat or 0
	if os.clock() - LastChatTime > SQUAD_TALK_RATE then
		Squad.LastChat = os.clock()
		PlayVoiceline(NPCTable, Voicelines)
	end
end

-- === STATE: IDLE ===========================================================
module.Idle = {
	Enter = function(NPCTable)
		PathFinder.DestroyPath(NPCTable)
		NPCTable.Animations.Idle:Play()
		NPCTable.Animations.Aim:Stop()
	end,

	Update = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		if Target then
			SquadChatRequest(NPCTable, Voicelines.TESTING_LINES.TARGET_SPOTTED)
			NPCTable.NextState = "CombatDecider"
		else
			if NPCTable.TargetPosition and (NPCTable.Model.PrimaryPart.Position - NPCTable.TargetPosition).Magnitude > 7 then
				NPCTable.NextState = "MoveToPosition"
			end
		end
	end,

	Leave = function(NPCTable)
		
	end,
}

-- === STATE: COMBAT DECIDER =================================================
module.CombatDecider = {
	Enter = function(NPCTable)
		NPCTable.Animations.Idle:Stop()
		NPCTable.Animations.Aim:Play()
		PathFinder.DestroyPath(NPCTable)
		
		if NPCTable.Model.PrimaryPart:CanSetNetworkOwnership() then
			NPCTable.Model.PrimaryPart:SetNetworkOwner(nil)
		end
	end,

	Update = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		if Target then
			local CanSeeTarget = Context.CheckCondition(NPCTable, "CanSeeTarget")
			if CanSeeTarget.See then
				if not NPCTable.CurrentCover then
					local Cover = Context.CheckCondition(NPCTable,"Cover")
					if Cover.Cover then
						SquadChatRequest(NPCTable, Voicelines.TESTING_LINES.CHANGE_POSITION)
						NPCTable.Cover = Cover.Cover
						NPCTable.NextState = "MoveToCover"
					else
						NPCTable.NextState = "CombatNoCover"
					end
				else
					NPCTable.NextState = "CombatInCover"
				end
				
			else
				NPCTable.NextState = "MoveToTarget"
			end
			
			
			
		else
			NPCTable.NextState = "Idle"
		end
	end,

	Leave = function(NPCTable) 
		
	end,
}

-- === STATE: COMBAT NO COVER ================================================
module.CombatNoCover = {
	Enter = function(NPCTable)
		NPCTable.MoveTime = os.clock() - 6
		NPCTable.FireTime = os.clock()
		NPCTable.LookAtUpdate = os.clock()
		NPCTable.TimesShot = 0
		
		SquadChatRequest(NPCTable, Voicelines.TESTING_LINES.NO_COVER)
	end,

	Update = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		local Model = NPCTable.Model
		local Humanoid = Model.Humanoid

		if not Target then
			NPCTable.NextState = "Idle"
			return
		end
		
		if TargetTable.Range < MELEE_RANGE and not NPCTable.CurrentPath then
			Melee(NPCTable, Target, TargetTable.Range)
			PathFinder.PathFindTo(NPCTable, NPCTable.Model.PrimaryPart.Position + (Target.PrimaryPart.Position - NPCTable.Model.PrimaryPart.Position).Unit*-10 )
		end
		
		if os.clock() - NPCTable.MoveTime > 4 and not NPCTable.CurrentPath then
			
			NPCTable.MoveTime = os.clock()

			local randomOffset = Model.PrimaryPart.CFrame.RightVector * math.random(-12, 12)
			local destination = Model.PrimaryPart.Position + randomOffset

			PathFinder.PathFindTo(NPCTable, destination)
		end

		if not NPCTable.CurrentPath and NPCTable.CanUpdate and os.clock() - NPCTable.FireTime > 2 then
			NPCTable.FireTime = os.clock()
			task.spawn(function()
				FireBurst(NPCTable, Target.PrimaryPart.Position)
			end)
			NPCTable.TimesShot += 1
			if NPCTable.TimesShot > 3 then
				NPCTable.NextState = "CombatDecider"
			end
		end

		if os.clock() - NPCTable.LookAtUpdate > 0.25 then
			NPCTable.LookAtUpdate = os.clock()
			local lookPos = Vector3.new(Target.PrimaryPart.Position.X, Model.PrimaryPart.Position.Y, Target.PrimaryPart.Position.Z)
			Model.HumanoidRootPart.AlignOrientation.CFrame = CFrame.lookAt(Model.PrimaryPart.Position, lookPos)
		end
	end,

	Leave = function(NPCTable)
		PathFinder.DestroyPath(NPCTable)
		NPCTable.MoveTime = nil
		NPCTable.FireTime = nil
		NPCTable.LookAtUpdate = nil
		NPCTable.TimesShot = nil
	end,
}

-- === STATE: MOVETOCOVER ===========================================================
module.MoveToCover = {
	Enter = function(NPCTable)
		PathFinder.DestroyPath(NPCTable)
		NPCTable.Animations.Idle:Play()
		NPCTable.Animations.Aim:Stop()
		
		NPCTable.Model.Humanoid.WalkSpeed = NPCTable.RunSpeed
		PathFinder.PathFindTo(NPCTable, NPCTable.Cover)
		NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = false
		
		
		if math.random(1,2) == 1 then
			Roll(NPCTable)
		end
	end,

	Update = function(NPCTable)
		local Distance = (NPCTable.Cover - NPCTable.Model.PrimaryPart.Position).Magnitude
		if Distance < 5 then
			NPCTable.NextState = "CombatDecider"
		end
		
		if not NPCTable.CurrentPath then
			NPCTable.CurrentCover = nil
			NPCTable.NextState = "CombatDecider"
		end
	end,

	Leave = function(NPCTable)
		NPCTable.Animations.Idle:Stop()
		NPCTable.Animations.Aim:Play()

		NPCTable.CurrentCover = NPCTable.Cover
		NPCTable.Cover = nil
		
		NPCTable.Model.Humanoid.WalkSpeed = NPCTable.WalkSpeed
		
		NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = true
	end,
}

-- === STATE: COMBATINCOVER ===========================================================
module.CombatInCover = {
	Enter = function(NPCTable)
		NPCTable.StandTime = os.clock()
		NPCTable.Standing = false
		NPCTable.FireTime = os.clock()
		NPCTable.LookAtUpdate = os.clock()
		NPCTable.TimesShot = 0
		
		NPCTable.Animations.Crouch:Play()
	end,

	Update = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		local Model = NPCTable.Model
		local Humanoid = Model.Humanoid

		if not Target then
			NPCTable.NextState = "Idle"
			return
		end
		
		if TargetTable.Range < MELEE_RANGE and not NPCTable.CurrentPath then
			Melee(NPCTable, Target, TargetTable.Range)
			PathFinder.PathFindTo(NPCTable, NPCTable.Model.PrimaryPart.Position + (Target.PrimaryPart.Position - NPCTable.Model.PrimaryPart.Position).Unit*-15 )
			NPCTable.Animations.Crouch:Stop()
			NPCTable.NextState = "WaitPath"
			NPCTable.CurrentCover = nil
			return
		end

		if NPCTable.Standing == true and os.clock() - NPCTable.FireTime > 1.5 then
			if os.clock() - NPCTable.StandTime < 3  then
				NPCTable.FireTime = os.clock()

				task.spawn(function()
					FireBurst(NPCTable, Target.PrimaryPart.Position)
				end)

				NPCTable.TimesShot += 1
				if NPCTable.TimesShot > 3 then
					NPCTable.CurrentCover = nil
					NPCTable.NextState = "CombatDecider"
				end
			else
				NPCTable.Standing = false
				NPCTable.Animations.Crouch:Play()
				NPCTable.StandTime = os.clock()
			end
			
		end
		
		if NPCTable.Standing == false and os.clock() - NPCTable.StandTime > 1.5 then
			NPCTable.Standing = true
			NPCTable.Animations.Crouch:Stop()
			NPCTable.StandTime = os.clock()
		end
		if os.clock() - NPCTable.LookAtUpdate > 0.25 then
			NPCTable.LookAtUpdate = os.clock()
			local lookPos = Vector3.new(Target.PrimaryPart.Position.X, Model.PrimaryPart.Position.Y, Target.PrimaryPart.Position.Z)
			Model.HumanoidRootPart.AlignOrientation.CFrame = CFrame.lookAt(Model.PrimaryPart.Position, lookPos)
		end
	end,

	Leave = function(NPCTable)
		PathFinder.DestroyPath(NPCTable)
		NPCTable.StandTime = nil
		NPCTable.FireTime = nil
		NPCTable.LookAtUpdate = nil
		NPCTable.TimesShot = nil
		NPCTable.Standing = nil
		NPCTable.Animations.Crouch:Stop()
	end,
}

module.WaitPath = {
	Enter = function(NPCTable)
		
	end,
	Update = function(NPCTable)
		if not NPCTable.CurrentPath then
			NPCTable.NextState = "CombatDecider"
		end
	end,
	Leave = function(NPCTable)
		
	end,
}

-- === STATE: MOVETOTARGET ===========================================================
module.MoveToTarget = {
	Enter = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		
		if Target then
			PathFinder.DestroyPath(NPCTable)
			NPCTable.Animations.Idle:Play()
			NPCTable.Animations.Aim:Stop()

			NPCTable.Model.Humanoid.WalkSpeed = NPCTable.RunSpeed
			PathFinder.PathFindTo(NPCTable, Target.PrimaryPart.Position)
			NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = false
		else
			NPCTable.NextState = "CombatDecider"
		end
		

	end,

	Update = function(NPCTable)
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target
		
		if Target then
			local CanSeeTarget = Context.CheckCondition(NPCTable, "CanSeeTarget")
			if CanSeeTarget.See then
				PathFinder.DestroyPath(NPCTable)
				NPCTable.NextState = "CombatDecider"
			end
		end
		
		if not NPCTable.CurrentPath then
			NPCTable.NextState = "CombatDecider"
		end
		
		
	end,

	Leave = function(NPCTable)
		NPCTable.Animations.Idle:Stop()
		NPCTable.Animations.Aim:Play()

		NPCTable.Model.Humanoid.WalkSpeed = NPCTable.WalkSpeed

		NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = true
	end,
}
-- === STATE: MOVETOPOSITION ===========================================================
module.MoveToPosition = {
	Enter = function(NPCTable)
		PathFinder.DestroyPath(NPCTable)
		NPCTable.Animations.Idle:Play()
		NPCTable.Animations.Aim:Stop()

		NPCTable.Model.Humanoid.WalkSpeed = NPCTable.RunSpeed
		PathFinder.PathFindTo(NPCTable, NPCTable.TargetPosition)
		NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = false

	end,

	Update = function(NPCTable)
		local Distance = (NPCTable.TargetPosition - NPCTable.Model.PrimaryPart.Position).Magnitude
		if Distance < 5 then
			NPCTable.NextState = "Idle"
		end
		
		local TargetTable = Context.CheckCondition(NPCTable, "ClosestEnemy")
		local Target = TargetTable.Target

		if Target then
			PathFinder.DestroyPath(NPCTable)
			NPCTable.NextState = "CombatDecider"
		end
		
		if not NPCTable.CurrentPath then
			NPCTable.CurrentCover = nil
			NPCTable.NextState = "Idle"
		end
	end,

	Leave = function(NPCTable)
		NPCTable.Animations.Idle:Stop()
		NPCTable.Animations.Aim:Play()

		NPCTable.Model.Humanoid.WalkSpeed = NPCTable.WalkSpeed

		NPCTable.Model.HumanoidRootPart.AlignOrientation.Enabled = true
	end,
}


return module
