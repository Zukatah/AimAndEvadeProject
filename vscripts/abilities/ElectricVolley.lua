require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



electricVolley_collisionSize = 30.0



function ElectricVolley_MissileUpdate(timerindex)
	local caster = AAE.timerTable[timerindex].caster
	local castLoc = AAE.timerTable[timerindex].castLoc
	local intervalCount = AAE.timerTable[timerindex].intervalCount
	local cliffLevel = AAE.timerTable[timerindex].cliffLevel
	local normVecDir = AAE.timerTable[timerindex].normVecDir
	local missileGroup = AAE.timerTable[timerindex].missileGroup
	local curMissileCount = 0
	
	for key, value in pairs(missileGroup) do
		local missileIntCount = value.intervalCount + 1
		value.intervalCount = missileIntCount
		local missileDirection = value.direction
		local curVec
		
		curVec = Vector(castLoc.x + normVecDir.x * 20.0 * missileIntCount - normVecDir.y * 400.0 * missileDirection * math.sin(missileIntCount * 0.1396263), castLoc.y + normVecDir.y * 20.0 * missileIntCount + normVecDir.x * 400.0 * missileDirection * math.sin(missileIntCount * 0.1396263), 128.0)
		--GameRules:SendCustomMessage ("curVec: " .. tostring(curVec) .. " interval: " .. tostring(missileIntCount), 1, 1)
		curVec = VectorInMapBounds(curVec)
		key:SetAbsOrigin(curVec)
		
		local newCliffLevel = (GetGroundPosition(curVec, nil)).z
		
		if (cliffLevel + 5.0 < newCliffLevel) then
			missileGroup[key] = nil
			RemoveDummyTimedInit(key, 0.2)
		else
			local collision, targetUnit = IsMissileColliding (caster, curVec, electricVolley_collisionSize)
			
			if (collision) then
				PlaySoundOnUnitInit("Hero_Zuus.ArcLightning.Target", targetUnit, 2.0, false)
				
				DealDamage (caster, targetUnit, 60.0)
				
				missileGroup[key] = nil
				RemoveDummyTimedInit(key, 0.2)
			else
				if (missileIntCount >= 90) then
					missileGroup[key] = nil
					RemoveDummyTimedInit(key, 0.2)
				else
					curMissileCount = curMissileCount + 1
				end
			end
		end
	end
	
	if (intervalCount >= 150 and curMissileCount == 0) then
		AAE.timerTable[timerindex] = nil
		--GameRules:SendCustomMessage ("Electric Volley vorbei", 1, 1)
	else
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
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, normVecDir = normVecDir, castDummy = castDummy, castLoc = casterLoc, cliffLevel = cliffLevel, channelStartTime = GameRules:GetGameTime(), missileGroup = {} }
	AAE.Utils.Timer.Register( ElectricVolley_ChannelUpdate, 0.01, timerIndex )
	AAE.Utils.Timer.Register( ElectricVolley_MissileUpdate, 0.01, timerIndex )
end



function ElectricVolley_ChannelUpdate (timerIndex)
	local caster = AAE.timerTable[timerIndex].caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local countdownLoc = casterLoc + Vector(0,128,0)
	local intervalCount = AAE.timerTable[timerIndex].intervalCount + 1
	local normVecDir = AAE.timerTable[timerIndex].normVecDir
	local castDummy = AAE.timerTable[timerIndex].castDummy
	local castLoc = AAE.timerTable[timerIndex].castLoc
	local cliffLevel = AAE.timerTable[timerIndex].cliffLevel
	local channelStartTime = AAE.timerTable[timerIndex].channelStartTime
	local missileGroup = AAE.timerTable[timerIndex].missileGroup
	AAE.timerTable[timerIndex].intervalCount = intervalCount
	
	if (castLoc == casterLoc) then
		if (AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime == nil or AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime <= channelStartTime) then
			local def = { num = tonumber(500 - 3.3333333 * intervalCount), location = countdownLoc, duration = 0.1, color = Vector(255,0,0) }
			ShowFloatingNum(def)
			
			if (intervalCount % 25 == 0) then
				PlaySoundOnUnitInit("Hero_Zuus.LightningBolt.Cast", caster, 2.0, false)
				
				local missileDummy = CreateUnitByName("aae_dummy_mage_arcingSpark", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
				missileDummy:FindAbilityByName("aae_d_mage_arcingSpark"):SetLevel(1)
				missileGroup[missileDummy] = { direction = 1, intervalCount = 0 } --direction = 1 means, that the missile first moves right; -1 means moves left first.
				local missileDummy = CreateUnitByName("aae_dummy_mage_arcingSpark", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
				missileDummy:FindAbilityByName("aae_d_mage_arcingSpark"):SetLevel(1)
				missileGroup[missileDummy] = { direction = -1, intervalCount = 0 }
			end
			
			if (intervalCount < 150) then
				return 0.01
			else
				caster:Stop()
			end
		end
	end
	
	AAE.timerTable[timerIndex].intervalCount = 150
	castDummy:RemoveSelf()
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
