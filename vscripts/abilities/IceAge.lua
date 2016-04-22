require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



iceAge_explosionAoe = 440.0



function IceAge_MissileUpdate(timerindex)
	local caster = AAE.timerTable[timerindex].caster
	local intervalCount = AAE.timerTable[timerindex].intervalCount + 1
	AAE.timerTable[timerindex].intervalCount = intervalCount
	local normVecDir = AAE.timerTable[timerindex].normVecDir
	local targetPoint = AAE.timerTable[timerindex].targetPoint
	local targetPointX = targetPoint.x
	local targetPointY = targetPoint.y
	local missileDummy = AAE.timerTable[timerindex].missileDummy
	local dummyPos = missileDummy:GetAbsOrigin()
	local dummyPosX = dummyPos.x
	local dummyPosY = dummyPos.y
	local distSq = (targetPointX-dummyPosX)*(targetPointX-dummyPosX)+(targetPointY-dummyPosY)*(targetPointY-dummyPosY)
	
	local newPos
	
	if (distSq < 8100.0) then
		newPos = VectorInMapBounds(targetPoint)
		missileDummy:SetAbsOrigin(newPos)
		
		explosionDummy = CreateUnitByName("aae_dummy_mage_fireball_explosion", newPos, false, casterOwner, casterOwner, caster:GetTeamNumber())
		explosionDummy:FindAbilityByName("aae_d_mage_fireball_explosion"):SetLevel(1)
		RemoveDummyTimedInit(explosionDummy, 3.0)
		RemoveDummyTimedInit(missileDummy, 0.2)
		
		for key, value in pairs(AAE.allUnits) do
			local pickedUnit = EntIndexToHScript(key)
			local pickedUnitPos = pickedUnit:GetAbsOrigin()
			local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
			local vecDistUnitExplosion = pickedUnitPos - newPos
			local dX = vecDistUnitExplosion.x
			local dY = vecDistUnitExplosion.y
			
			if (math.abs(dX) < iceAge_explosionAoe + pickedUnitSize and math.abs(dY) < iceAge_explosionAoe + pickedUnitSize) then
				if (dX*dX + dY*dY <= (iceAge_explosionAoe + pickedUnitSize)*(iceAge_explosionAoe + pickedUnitSize)) then
					local timerIndex = GetTimerIndex()
					IncreaseBuffCountOnUnit (pickedUnit, "iceAge_Slow", timerIndex, 0.8)
					RemoveBuffFromUnitTimedInit (pickedUnit, "iceAge_Slow", timerIndex, 8.0)
					DealDamage (caster, pickedUnit, 50.0)
				end
			end
		end
		
		AAE.timerTable[timerindex] = nil
	else
		newPos = VectorInMapBounds(dummyPos + 90 * normVecDir)
		missileDummy:SetAbsOrigin(newPos)
		return 0.01
	end
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local castDummy
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	
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
	
	castDummy = CreateUnitByName("aae_dummy_mage_pyroblast_cast", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	castDummy:FindAbilityByName("aae_d_mage_pyroblast_cast"):SetLevel(1)
	
	local timerIndex = GetTimerIndex()
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, normVecDir = normVecDir, targetPoint = targetPoint, castDummy = castDummy, castLoc = casterLoc, channelStartTime = GameRules:GetGameTime() }
	AAE.Utils.Timer.Register( IceAge_ChannelUpdate, 0.01, timerIndex )
end



function IceAge_ChannelUpdate (timerIndex)
	local caster = AAE.timerTable[timerIndex].caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local countdownLoc = casterLoc + Vector(0,128,0)
	local intervalCount = AAE.timerTable[timerIndex].intervalCount + 1
	local normVecDir = AAE.timerTable[timerIndex].normVecDir
	local targetPoint = AAE.timerTable[timerIndex].targetPoint
	local castDummy = AAE.timerTable[timerIndex].castDummy
	local castLoc = AAE.timerTable[timerIndex].castLoc
	local channelStartTime = AAE.timerTable[timerIndex].channelStartTime
	AAE.timerTable[timerIndex].intervalCount = intervalCount
	
	if (castLoc == casterLoc) then
		if (AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime == nil or AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime <= channelStartTime) then
			local def = { num = tonumber(150 - 3.3333333 * intervalCount), location = countdownLoc, duration = 0.1, color = Vector(255,0,0) }
			ShowFloatingNum(def)
			
			if (intervalCount < 45) then
				return 0.01
			else
				caster:Stop()
				
				local missileDummy = CreateUnitByName("aae_dummy_mage_arcingSpark", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
				missileDummy:FindAbilityByName("aae_d_mage_arcingSpark"):SetLevel(1)
				
				AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, normVecDir = normVecDir, targetPoint = targetPoint, missileDummy = missileDummy }
				AAE.Utils.Timer.Register( IceAge_LaunchMissile, 1.49999999, timerIndex )
			end
		end
	end
	
	castDummy:RemoveSelf()
end



function IceAge_LaunchMissile (timerIndex)
	AAE.Utils.Timer.Register( IceAge_MissileUpdate, 0.01, timerIndex )
end



function OnChannelInterrupted ( keys )
	local caster = keys.caster
	--GameRules:SendCustomMessage ("CI", 1, 1)
	AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime = GameRules:GetGameTime()
end



function OnChannelFinish ( keys )
	local caster = keys.caster
	--GameRules:SendCustomMessage ("CF", 1, 1)
	AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime = GameRules:GetGameTime()
end
