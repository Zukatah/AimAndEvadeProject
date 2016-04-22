require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



snowball_collisionSize = 80.0
snowball_snowFieldSize = 350.0



function Snowball_SlowUnits(index)
	local caster = AAE.timerTable[index].caster
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local maxIntervals = AAE.timerTable[index].maxIntervals
	local snow = AAE.timerTable[index].snow
	local snowX = AAE.timerTable[index].snowX
	local snowY = AAE.timerTable[index].snowY
	AAE.timerTable[index].intervalCount = intervalCount
	
	for key, value in pairs(AAE.allUnits) do
		local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		local vecUnitSnowX = pickedUnitPos.x - snowX
		local vecUnitSnowY = pickedUnitPos.y - snowY
		
		if (math.abs(vecUnitSnowX) < snowball_snowFieldSize + pickedUnitSize and math.abs(vecUnitSnowY) < snowball_snowFieldSize + pickedUnitSize) then
			if (vecUnitSnowX*vecUnitSnowX + vecUnitSnowY*vecUnitSnowY <= (snowball_snowFieldSize + pickedUnitSize)*(snowball_snowFieldSize + pickedUnitSize)) then
				StartCombatMode (pickedUnit, caster:GetOwner():GetPlayerID())
				local timerIndex = GetTimerIndex()
				--IncreaseBuffCountOnUnit (pickedUnit, "snowball_Slow", timerIndex, 0.3)
				IncreaseBuffCountOnUnit (pickedUnit, "snowball_Slow", timerIndex, 0.3)
				RemoveBuffFromUnitTimedInit (pickedUnit, "snowball_Slow", timerIndex, 1.0)
			end
		end
	end
	
	if (intervalCount < maxIntervals) then
		return 0.06666
	end
	
	snow:ForceKill(true)
	AAE.timerTable[index] = nil
end



function Snowball_MoveMissiles(index)
	local caster = AAE.timerTable[index].caster
	local curLinePos = AAE.timerTable[index].curLinePos
	local snowball1 = AAE.timerTable[index].snowball1
	local snowball2 = AAE.timerTable[index].snowball2
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local normVecDir = AAE.timerTable[index].normVecDir
	local maxIntervals = AAE.timerTable[index].maxIntervals
	AAE.timerTable[index].intervalCount = intervalCount
	
	local distanceMidLine = math.sin(intervalCount/maxIntervals * math.pi) * 320
	local curLinePos = curLinePos + 32 * normVecDir
	AAE.timerTable[index].curLinePos = curLinePos
	
	local normVecDirOrt = Vector( normVecDir.y, -normVecDir.x, 0.0 )
	local newSnowball1Pos = VectorInMapBounds(curLinePos + distanceMidLine * normVecDirOrt)
	local newSnowball2Pos = VectorInMapBounds(curLinePos - distanceMidLine * normVecDirOrt)
	
	local newCliffLevelS1 = (GetGroundPosition(newSnowball1Pos, nil)).z
	local newCliffLevelS2 = (GetGroundPosition(newSnowball2Pos, nil)).z
	
	if (snowball1.missile:IsAlive()) then
		if (cliffLevel + 5.0 < newCliffLevelS1) then
			snowball1.missile:ForceKill(true)
			for key, value in pairs(snowball1.group) do
				DecreaseBuffCountOnUnit (key, "snowball", index)
				FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
			end
			snowball1.group = {}
			snowball1.prevGroup = {}
		else
			snowball1.missile:SetAbsOrigin(newSnowball1Pos)
			
			for key, value in pairs(snowball1.group) do
				key:SetAbsOrigin(newSnowball1Pos)
				snowball1.group[key] = snowball1.group[key] - 1
				if (snowball1.group[key] <= 0 or GetBuffCountOnUnit (key, "snowball", index) <= 0) then
					DecreaseBuffCountOnUnit (key, "snowball", index)
					FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
					snowball1.prevGroup[key] = true
					snowball1.group[key] = nil
				end
			end
			
			if (maxIntervals > intervalCount) then
				
				for key, value in pairs(AAE.allUnits) do
					local pickedUnit = EntIndexToHScript(key)
					local pickedUnitPos = pickedUnit:GetAbsOrigin()
					local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
					local vecDistUnitSnowball = pickedUnitPos - newSnowball1Pos
					dX = vecDistUnitSnowball.x
					dY = vecDistUnitSnowball.y
					
					if (pickedUnit ~= caster) then
						if (snowball1.group[pickedUnit] == nil and snowball2.group[pickedUnit] == nil and snowball1.prevGroup[pickedUnit] == nil and snowball2.prevGroup[pickedUnit] == nil) then
							if (math.abs(dX) < snowball_collisionSize + pickedUnitSize and math.abs(dY) < snowball_collisionSize + pickedUnitSize) then
								if (dX*dX + dY*dY <= (snowball_collisionSize + pickedUnitSize)*(snowball_collisionSize + pickedUnitSize)) then
									if (GetBuffCountOnUnit (pickedUnit, "magicLasso") <= 0 and GetBuffCountOnUnit (pickedUnit, "snowball") <= 0) then
										snowball1.group[pickedUnit] = 70 --Unit is for 70 intervals (2.1 seconds) within a snowball
										IncreaseBuffCountOnUnit (pickedUnit, "snowball", index)
									end
								end
							end
						end
					end
				end
				
			else
				snowball1.reachedTarget = true
				snowball1.missile:ForceKill(true)
				for key, value in pairs(snowball1.group) do
					DecreaseBuffCountOnUnit (key, "snowball", index)
					FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
				end
				snowball1.group = {}
				snowball1.prevGroup = {}
			end
		end
	end
	
	if (snowball2.missile:IsAlive()) then
		if (cliffLevel + 5.0 < newCliffLevelS2) then
			snowball2.missile:ForceKill(true)
			for key, value in pairs(snowball2.group) do
				DecreaseBuffCountOnUnit (key, "snowball", index)
				FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
			end
			snowball2.group = {}
			snowball2.prevGroup = {}
		else
			snowball2.missile:SetAbsOrigin(newSnowball2Pos)
			
			for key, value in pairs(snowball2.group) do
				key:SetAbsOrigin(newSnowball2Pos)
				snowball2.group[key] = snowball2.group[key] - 1
				if (snowball2.group[key] == 0 or GetBuffCountOnUnit (key, "snowball", index) <= 0) then
					DecreaseBuffCountOnUnit (key, "snowball", index)
					FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
					snowball2.prevGroup[key] = true
					snowball2.group[key] = nil
				end
			end
			
			if (maxIntervals > intervalCount) then
				
				for key, value in pairs(AAE.allUnits) do
					local pickedUnit = EntIndexToHScript(key)
					local pickedUnitPos = pickedUnit:GetAbsOrigin()
					local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
					local vecDistUnitSnowball = pickedUnitPos - newSnowball2Pos
					dX = vecDistUnitSnowball.x
					dY = vecDistUnitSnowball.y
					
					if (pickedUnit ~= caster) then
						if (snowball1.group[pickedUnit] == nil and snowball2.group[pickedUnit] == nil and snowball1.prevGroup[pickedUnit] == nil and snowball2.prevGroup[pickedUnit] == nil) then
							if (math.abs(dX) < snowball_collisionSize + pickedUnitSize and math.abs(dY) < snowball_collisionSize + pickedUnitSize) then
								if (dX*dX + dY*dY <= (snowball_collisionSize + pickedUnitSize)*(snowball_collisionSize + pickedUnitSize)) then
									if (GetBuffCountOnUnit (pickedUnit, "magicLasso") <= 0 and GetBuffCountOnUnit (pickedUnit, "snowball") <= 0) then
										snowball2.group[pickedUnit] = 70 --Unit is for 70 intervals (2.1 seconds) within a snowball
										IncreaseBuffCountOnUnit (pickedUnit, "snowball", index)
									end
								end
							end
						end
					end
				end
				
			else
				snowball2.reachedTarget = true
				snowball2.missile:ForceKill(true)
				for key, value in pairs(snowball2.group) do
					DecreaseBuffCountOnUnit (key, "snowball", index)
					FindClearSpaceForUnit(key, key:GetAbsOrigin(), true)
				end
				snowball2.group = {}
				snowball2.prevGroup = {}
			end
		end
	end
	
	if (snowball1.reachedTarget and snowball2.reachedTarget) then
		local casterOwner = caster:GetOwner()
		AAE.timerTable[index].snow = CreateUnitByName("aae_dummy_mage_fireball_missile", curLinePos, false, casterOwner, casterOwner, caster:GetTeamNumber())
		AAE.timerTable[index].snow:FindAbilityByName("aae_d_mage_fireball_missile"):SetLevel(1)
		AAE.timerTable[index].intervalCount = 0
		AAE.timerTable[index].maxIntervals = 150
		AAE.timerTable[index].snowX = curLinePos.x
		AAE.timerTable[index].snowY = curLinePos.y
		AAE.Utils.Timer.Register( Snowball_SlowUnits, 0.06666, index )
	else
		if (not snowball1.missile:IsAlive() and not snowball2.missile:IsAlive()) then
			AAE.timerTable[index] = nil
		else
			return 0.01
		end
	end
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local snowball1 = {} --missile, caughtUnits
	local snowball2 = {}
	local intervalCount = 0
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	local timerIndex = GetTimerIndex()
	
	local targetPoint = nil
	if (keys.Target == "POINT" and keys.target_points[1]) then
		targetPoint = keys.target_points[1]
	else
		return
	end
	targetPoint.z = cliffLevel
	
	local vecDir = targetPoint - casterLoc
	local vecDirLen = math.sqrt(vecDir.x*vecDir.x + vecDir.y*vecDir.y)
	
	if (vecDirLen ~= 0) then
		normVecDir=vecDir/vecDirLen
	else
		normVecDir=Vector(1.0, 0.0, 0.0)
	end
	
	local maxIntervals = math.floor(vecDirLen/32.0)+1
	
	if (maxIntervals % 2 ~= 0) then --WHY only even maxIntervals?
		maxIntervals = maxIntervals + 1
	end
	
	snowball1.missile = CreateUnitByName("aae_dummy_mage_fireball_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	snowball1.missile:FindAbilityByName("aae_d_mage_fireball_missile"):SetLevel(1)
	snowball2.missile = CreateUnitByName("aae_dummy_mage_fireball_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	snowball2.missile:FindAbilityByName("aae_d_mage_fireball_missile"):SetLevel(1)
	snowball1.group = {}
	snowball2.group = {}
	snowball1.prevGroup = {}
	snowball2.prevGroup = {}
	snowball1.reachedTarget = false
	snowball2.reachedTarget = false
	
	AAE.timerTable[timerIndex] = { caster = caster, curLinePos = casterLoc, snowball1 = snowball1, snowball2 = snowball2, intervalCount = intervalCount, maxIntervals = maxIntervals, cliffLevel = cliffLevel, normVecDir = normVecDir }
	AAE.Utils.Timer.Register( Snowball_MoveMissiles, 0.01, timerIndex )
end

