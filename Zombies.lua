local CollectionService = game:GetService("CollectionService")
--Physioc
wait()
local PS = game:GetService'PhysicsService'
PS:CollisionGroupSetCollidable('Players','Default',true)
PS:CollisionGroupSetCollidable('Npc','Default',true)
PS:CollisionGroupSetCollidable('Players','Npc',false)
PS:CollisionGroupSetCollidable('Npc','Npc',false)
--Table used to keep track of all alive zombies
local zombies = {}

local ZZ =nil




--Used to create new threads easily while avoid spawn()
function spawner(func,...)
	local co = coroutine.wrap(func)
	co(...)
end

--------------------------
----Zombie AI Handling----
--------------------------
local function isSpaceEmptyWithIgnoreList(position,target)
	
	local region = Region3.new(position - Vector3.new(1,2,1), position + Vector3.new(1,2,1)) -- change vec3 here to change how many npc can surround player at once
	return game.Workspace:IsRegion3EmptyWithIgnoreList(region,{target})
end
local function isSpaceEmpty(position)
	local region = Region3.new(position - Vector3.new(1,2,1), position + Vector3.new(1,2,1)) -- change vec3 here to change how many npc can surround player at once
	return game.Workspace:IsRegion3Empty(region)
end

function FindCloseEmptySpaceWithIgnoreList(zombie,original,targetItself)
	local targetPos = Vector3.new(0,0,0)
	local count = 0
	math.randomseed(os.time())
	repeat
		local xoff = math.random(4,5)
		if math.random() > .5 then
			xoff = xoff * -1
		end
		local zoff = math.random(4,5)
		if math.random() > .5 then
			zoff = zoff * -1
		end

		targetPos = Vector3.new(zombie.Position.X + xoff,zombie.Position.Y,zombie.Position.Z + zoff)
		if isSpaceEmptyWithIgnoreList(targetPos,targetItself) then
			return targetPos
		else
			targetPos = targetPos + Vector3.new(0,4,0)
		end

		count = count + 1
	until count > 10
	return original
end
function FindCloseEmptySpace(zombie,original)
	local targetPos = Vector3.new(0,0,0)
	local count = 0
	math.randomseed(os.time())
	repeat
		local xoff = math.random(2.1,3)
		if math.random() > .5 then
			xoff = xoff * -1
		end
		local zoff = math.random(2.1,3)
		if math.random() > .5 then
			zoff = zoff * -1
		end

		targetPos = Vector3.new(zombie.Position.X + xoff,zombie.Position.Y,zombie.Position.Z + zoff)
		if isSpaceEmpty(targetPos) then
			return targetPos
		else
			targetPos = targetPos + Vector3.new(0,4,0)
		end

		count = count + 1
	until count > 10
	return original
end
--Simple function for getting the distance between 2 points
function checkDist(part1,part2)
	if typeof(part1) ~= Vector3 then
		part1 = part1.Position
	else
		return
	end
	if typeof(part2) ~= Vector3 then 
		part2 = part2.Position
	else
		return
	end
	return (part1 - part2).Magnitude 
end


--Loops through the human tag to find the closest valid target
function updateTarget(zombie) -- CAN CHANGE USING OTHER THING LIKE RAYCAST
	local humans = CollectionService:GetTagged("Human")
	
		local target = nil
		local dist = 50
		for _,human in pairs(humans) do
		local root = human.RootPart
		if root then
			if root and human.Health > 0 and checkDist(root,zombie.root) < dist and human.Parent.Name ~= zombie.char.Name then
				dist = checkDist(root,zombie.root)
				target = root
			end
		end
		zombie.target = target
		end
			
	
end

--Target updating

-- Alightment


--
function Separation(zombie)
	local vector = Vector3.new(0,0,0)
	local neighborCount = 0
	local agentPosition = zombie.root.Position

	local zombieRP = zombie.char:FindFirstChild("HumanoidRootPart")
	if zombieRP then
		for _,v in pairs(CollectionService:GetTagged("Zombie")) do
			if v.Parent ~= zombie.char then
				if v.Parent:FindFirstChild("HumanoidRootPart") then
					if(agentPosition - v.Parent.HumanoidRootPart.Position).Magnitude <= 4  then
						vector = vector + Vector3.new((agentPosition.X - v.Parent.HumanoidRootPart.Position.X),1,(agentPosition.Z - v.Parent.HumanoidRootPart.Position.Z))

						neighborCount = neighborCount + 1

					end
				end			

			end
		end		
	end

	if neighborCount == 0 then

		return Vector3.new(0,0,0)
	end

	vector = vector / Vector3.new(neighborCount,1,neighborCount)


	return vector.Unit* Vector3.new(100,1,100) 
end
--Called to have the zombie path towards it's current target
function pathToTarget(zombie)
	
		local vector = Vector3.new(0,0,0)
		local neighborCount = 0
		local agentPosition = zombie.root.Position



		local path = game:GetService("PathfindingService"):CreatePath()
		path:ComputeAsync(zombie.root.Position,zombie.target.Position)
		local waypoints = path:GetWaypoints()
		local currentTarget = zombie.target
		for i,v in pairs(waypoints) do
			if v.Action == Enum.PathWaypointAction.Jump then
				zombie.human.Jump = false
			else
				if zombie.char:FindFirstChild("Hit") then
					return
				end
				if v == waypoints[#waypoints  ] then
					if isSpaceEmpty(v.Position) then
						zombie.human:MoveTo(v.Position)
					else
						zombie.human:MoveTo(FindCloseEmptySpace(v,zombie.root.Position))
					end
				else
					zombie.human:MoveTo(v.Position)
				end



				spawner(function()
					wait(0.5)
					if zombie.human.WalkToPoint.Y > zombie.root.Position.Y then
						zombie.human.Jump = false
					end
				end)
				zombie.human.MoveToFinished:Wait(1) -- changed from zombie.human.MoveToFinished:Wait() to reduce lagg
				if zombie.target then
					if checkDist(zombie.target,zombie.root) <= 5 then
					attack(zombie)
					wait(1)
					end


				elseif not zombie.target then				
					break
				end	
				if checkDist(currentTarget,waypoints[#waypoints]) > 5 or currentTarget ~= zombie.target then
					if isSpaceEmptyWithIgnoreList(zombie.target.Position,zombie.target.Parent) then
						pathToTarget(zombie)
					else
						pathToTarget2(zombie,FindCloseEmptySpaceWithIgnoreList(zombie.target,zombie.target.Position,zombie.Parent))

					end
					break
				end
			end
		end
	
	
end
--Second version path2t
function pathToTarget2(zombie,NewPlace)

	local vector = Vector3.new(0,0,0)
	local neighborCount = 0
	local agentPosition = zombie.root.Position

	local path = game:GetService("PathfindingService"):CreatePath()
	path:ComputeAsync(zombie.root.Position,NewPlace)
	local waypoints = path:GetWaypoints()
	local currentTarget = zombie.target
	for i,v in pairs(waypoints) do
		if v.Action == Enum.PathWaypointAction.Jump then
			zombie.human.Jump = false
		else
			if zombie.char:FindFirstChild("Hit") then
				return
			end
			if v == waypoints[#waypoints  ] then
				if isSpaceEmpty(v.Position) then
					zombie.human:MoveTo(v.Position)
				else
					zombie.human:MoveTo(FindCloseEmptySpace(v,zombie.root.Position))
				end
			else
				zombie.human:MoveTo(v.Position)
			end



			spawner(function()
				wait(0.5)
				if zombie.human.WalkToPoint.Y > zombie.root.Position.Y then
					zombie.human.Jump = false
				end
			end)
			zombie.human.MoveToFinished:Wait(1) -- changed from zombie.human.MoveToFinished:Wait() to reduce lagg
			if zombie.target then
				if checkDist(zombie.target,zombie.root) <= 5 then
					attack(zombie)
					wait(1)
				end
			elseif not zombie.target then				
				break
			end	
			if checkDist(currentTarget,waypoints[#waypoints]) > 5 or currentTarget ~= zombie.target then
				if isSpaceEmptyWithIgnoreList(zombie.target.Position,zombie.target.Parent) then
					pathToTarget(zombie)
				else
					pathToTarget2(zombie,FindCloseEmptySpaceWithIgnoreList(zombie.target,zombie.target.Position,zombie.Parent))

				end
			end
		end
	end


end

--Simple loop to handle the pathfinding function
function movementHandler(zombie)

	while wait(1) do
		if zombie.human.Health <= 0 then
			break
		end
		if zombie.target then
			if checkDist(zombie.target,zombie.root) > 5 then
				if isSpaceEmptyWithIgnoreList(zombie.target.Position,zombie.target.Parent) then
					pathToTarget(zombie)
				else
					pathToTarget2(zombie,FindCloseEmptySpaceWithIgnoreList(zombie.target,zombie.target.Position,zombie.Parent))

				end
				
			else
				attack(zombie)

			end

		end
	end
end

function attack(zombie)
	if zombie.char:FindFirstChild("Hit") then
		return
	end
	local human = zombie.target.Parent.Humanoid

	zombie.char:SetPrimaryPartCFrame(CFrame.lookAt(zombie.char:FindFirstChild("HumanoidRootPart").Position, zombie.target.Parent.HumanoidRootPart.Position))
	zombie.grabAnim:Play()

	if zombie.target then
		if checkDist(zombie.target,zombie.root) <= 5 then
			human:TakeDamage(5)
		end
	end




end




-------------------------------
----Zombie Table Management----
-------------------------------


--Simple function to check instances for humanoid then tag them if found
function tagHuman(instance)
	local human = instance:FindFirstChildWhichIsA("Humanoid")
	if human then
		CollectionService:AddTag(human,"Human")
	end
end

--Respawning that is tied the to the .Died event
function removeZombie(zombie)
	local index = table.find(zombies,zombie)
	table.remove(zombies,index)
	wait(5)
	zombie.char:Destroy()
	zombie.clone.Parent = workspace
end

--Adds Zombies to our zombies table, sets up respawning,
--and spawns a pathing thread for each zombie.
function addZombie(zombieHumanoid) -- CAN CHANGE
	table.insert(zombies,{
		char = zombieHumanoid.Parent,
		root = zombieHumanoid.RootPart,
		human = zombieHumanoid,
		target = nil,
		clone = zombieHumanoid.Parent:Clone(),
		grabAnim = zombieHumanoid:LoadAnimation(zombieHumanoid.Parent.Grab)
	})
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)

	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	zombieHumanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
	for _,zombie in pairs(zombies) do
		if zombie.human == zombieHumanoid then
			zombie.human.Died:Connect(function() removeZombie(zombie) end)
			for i,v in pairs(zombie.char:GetDescendants()) do
				if v.Name == "Hit" then
					return
				end

				if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
					if v ~= zombie.root then
						v.CollisionGroupId = _G.Npc
					end
					v:SetNetworkOwner(nil)
				
				end
			end
			spawner(function()
				while wait(1) do
					updateTarget(zombie)
				end
			end)

			spawner(movementHandler,zombie)

			break
		end
	end

end

--Checking each object in the workspace for a humanoid as it enters/respawns
workspace.ChildAdded:Connect(tagHuman)

--Whenever something is tagged as a zombie then we add it to our table of alive zombies
CollectionService:GetInstanceAddedSignal("Zombie"):Connect(function(zombieHumanoid)
	addZombie(zombieHumanoid)
end)

--Ran one time to add all current zombies in the workspace on run
function intialize()
	for _,v in pairs(CollectionService:GetTagged("Zombie")) do
		local found = false
		for _,x in pairs(zombies) do
			if x.human == v then
				found = true
			end
		end
		if not found then
			addZombie(v)
		end
	end
	for i,v in pairs(workspace:GetChildren()) do
		tagHuman(v)
	end
end

intialize()




