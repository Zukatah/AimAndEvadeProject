require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



frostFork_collisionSize = 30.0



function FrostForkUpdate(index)
	local caster = AAE.timerTable[index].caster
	local intervalCount = AAE.timerTable[index].intervalCount + 1 --SPEICHERN
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local normVecDir = AAE.timerTable[index].normVecDir
	local forward = AAE.timerTable[index].forward --SPEICHERN
	local missileGroup = AAE.timerTable[index].missileGroup
	AAE.timerTable[index].intervalCount = intervalCount
	
	local casterOwner = caster:GetOwner()
	local newMissiles = { }
	local missileDummy = nil
	
	for key, value in pairs(missileGroup) do
		local missileDirection = value.direction -- +1 for turning left, -1 for turning right
		local lastPos = key:GetAbsOrigin()
		local newPos
		
		if (forward) then
			newPos = lastPos + 30.0 * normVecDir
		else
			newPos = Vector(lastPos.x - 30.0 * normVecDir.y * missileDirection, lastPos.y + 30.0 * normVecDir.x * missileDirection, 128.0)
		end
		newPos = VectorInMapBounds(newPos)
		newCliffLevel = newPos.z
		key:SetAbsOrigin(newPos)
		
		if (cliffLevel + 5.0 < newCliffLevel) then
			missileGroup[key] = nil
			key:RemoveSelf()
		else
			--------------WEITER
			local collision, targetUnit = IsMissileColliding (caster, newPos, frostFork_collisionSize)
			
			if (collision) then
				--GameRules:SendCustomMessage ("Name des Opfers: " .. tostring(targetUnit:GetUnitName()), 1, 1)
				
				DealDamage (caster, targetUnit, 45.0)
				
				local timerIndex = GetTimerIndex()
				IncreaseBuffCountOnUnit (targetUnit, "frostFork_Slow", timerIndex, 0.5)
				RemoveBuffFromUnitTimedInit (targetUnit, "frostFork_Slow", timerIndex, 5.0)
			
				missileGroup[key] = nil
				key:RemoveSelf()
			else
				if (intervalCount == 18 or intervalCount == 44 or intervalCount == 66  or intervalCount == 86) then
					value.direction = 1
					
					missileDummy = CreateUnitByName("aae_dummy_mage_frostFork", newPos, false, casterOwner, casterOwner, caster:GetTeamNumber())
					missileDummy:FindAbilityByName("aae_d_mage_frostFork"):SetLevel(1)
					newMissiles[missileDummy] = { direction = -1 }
				end
			end
			
			
		end
		
		
	end
	
	for key, _ in pairs(newMissiles) do
		missileGroup[key] = { direction = -1 }
	end
	
	--previous version: 18 forward, 16,8,4,2 to the sides
	if (intervalCount == 18 or intervalCount == 44 or intervalCount == 66 or intervalCount == 86) then
		forward = false
	else
		if (intervalCount == 26 or intervalCount == 48 or intervalCount == 68 or intervalCount == 87) then
			forward = true
		end
	end
	
	if (intervalCount < 105) then
		AAE.timerTable[index].forward = forward
		return 0.01
	end
	
	for key, value in pairs(missileGroup) do
		key:RemoveSelf()
	end
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local missileDummy
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	local timerIndex = GetTimerIndex()
	local missileGroup = { }
	
	local targetPoint = nil
	if (keys.Target == "POINT" and keys.target_points[1]) then
		targetPoint = keys.target_points[1]
	else
		return
	end
	targetPoint.z = cliffLevel
	
	local normVecDir = targetPoint - casterLoc
	local vecDirLen = math.sqrt((normVecDir.x)*(normVecDir.x)+(normVecDir.y)*(normVecDir.y))
	if (vecDirLen ~= 0) then
		normVecDir=normVecDir/vecDirLen
	else
		normVecDir=Vector(1.0, 0.0, 0.0)
	end
	
	missileDummy = CreateUnitByName("aae_dummy_mage_frostFork", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_frostFork"):SetLevel(1)
	missileGroup[missileDummy] = { direction = 1 }
	
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, cliffLevel = cliffLevel, normVecDir = normVecDir, forward = true, missileGroup = missileGroup }
	AAE.Utils.Timer.Register( FrostForkUpdate, 0.01, timerIndex )
end
