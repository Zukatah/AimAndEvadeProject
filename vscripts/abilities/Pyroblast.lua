require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



pyroblast_damageAoe = 440.0



function Pyroblast_MissileUpdate(timerindex)
	local caster = AAE.timerTable[timerindex].caster
	local missileDummy = AAE.timerTable[timerindex].missileDummy
	local missileLoc = AAE.timerTable[timerindex].missileLoc
	local intervalCount = AAE.timerTable[timerindex].intervalCount + 1
	local cliffLevel = AAE.timerTable[timerindex].cliffLevel
	local normVecDir = AAE.timerTable[timerindex].normVecDir
	local channelStr = AAE.timerTable[timerindex].channelStr
	
	local missileSpeed = 30.0 + channelStr * 0.045
	local missileIntervals = 40.0 + channelStr * 0.06
	local missileDmg = 4.0 + channelStr * 0.012
	
	local casterOwner = caster:GetOwner()
	local newMissileLoc = missileLoc + (normVecDir * missileSpeed)
	local newCliffLevel = (GetGroundPosition(newMissileLoc, nil)).z
	local endSpell = false
	
	if (cliffLevel + 133.0 < newCliffLevel) then
		newMissileLoc = missileLoc
		endSpell = true
	else
		missileDummy:SetAbsOrigin(newMissileLoc)
		if (intervalCount >= missileIntervals) then
			endSpell = true
		end
	end
	newMissileLoc = VectorInMapBounds(newMissileLoc)
	
	--TODO: Spawn more eye candy dummies later...
	local explosionDummy = CreateUnitByName("aae_dummy_mage_pyroblast_missile", newMissileLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	explosionDummy:FindAbilityByName("aae_d_mage_pyroblast_missile"):SetLevel(1)
	RemoveDummyTimedInit(explosionDummy, 2.5)
	
	if (intervalCount % 2 == 0) then
		explosionDummy = CreateUnitByName("aae_dummy_mage_pyroblast_missile_1", newMissileLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		explosionDummy:FindAbilityByName("aae_d_mage_pyroblast_missile_1"):SetLevel(1)
		RemoveDummyTimedInit(explosionDummy, 2.5)
	end
	
	
	
	
	for key, value in pairs(AAE.allUnits) do
		local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		local vecDistUnitExplosion = pickedUnitPos - newMissileLoc
		local dX = vecDistUnitExplosion.x
		local dY = vecDistUnitExplosion.y
		
		if (pickedUnit ~= caster) then
			if (math.abs(dX) < pyroblast_damageAoe + pickedUnitSize and math.abs(dY) < pyroblast_damageAoe + pickedUnitSize) then
				if (dX*dX + dY*dY <= (pyroblast_damageAoe + pickedUnitSize)*(pyroblast_damageAoe + pickedUnitSize)) then
					DealDamage (caster, pickedUnit, missileDmg)
				end
			end
		end
	end
	
	AAE.timerTable[timerindex].intervalCount = intervalCount
	AAE.timerTable[timerindex].missileLoc = newMissileLoc
	
	if (not endSpell) then
		return 0.01
	end
	
	RemoveDummyTimedInit(missileDummy, 0.2)
	
	AAE.timerTable[timerindex] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local castDummy
	local intervalCount = 0
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
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = intervalCount, normVecDir = normVecDir, castDummy = castDummy, castLoc = casterLoc, cliffLevel = cliffLevel, channelStartTime = GameRules:GetGameTime() }
	AAE.Utils.Timer.Register( Pyroblast_ChannelUpdate, 0.01, timerIndex )
end



function Pyroblast_ChannelUpdate (timerIndex)
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
	AAE.timerTable[timerIndex].intervalCount = intervalCount
	
	if (castLoc == casterLoc) then
		if (AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime == nil or AAE.allUnits[caster:GetEntityIndex()].lastChannelStartTime <= channelStartTime) then
			local def = { num = tonumber(3.3333333 * intervalCount), location = countdownLoc, duration = 0.1, color = Vector(255,0,0) }
			ShowFloatingNum(def)
			return 0.01
		end
	end
	
	--GameRules:SendCustomMessage ("Stop channelingGGGGGGGGGGGGGGGGGGGGGGGG" .. tostring(caster), 1, 1)
	--if (caster:FindAbilityByName("aae_m_mage_pyroblast"):IsChanneling()) then
		--caster:Stop()
	--end
	
	local missileDummy = CreateUnitByName("aae_dummy_mage_pyroblast_cast", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_pyroblast_cast"):SetLevel(1)
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, normVecDir = normVecDir, missileDummy = missileDummy, missileLoc = castLoc, channelStr = intervalCount, cliffLevel = cliffLevel }
	AAE.Utils.Timer.Register( Pyroblast_MissileUpdate, 0.01, timerIndex )
	
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
