require( "utils.timer" )
require( "utils.utils" )



deadlyRange_collisionSize = 30.0



function DeadlyRange_MoveMissiles (index)
	local caster = AAE.timerTable[index].caster
	local casterLoc = caster:GetAbsOrigin()
	local missilesCreated = AAE.timerTable[index].missilesCreated
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local casterFacing = AAE.timerTable[index].casterFacing
	local casterFacingX = AAE.timerTable[index].casterFacingX
	local casterFacingY = AAE.timerTable[index].casterFacingY
	local missileGroup = AAE.timerTable[index].missileGroup
	local timerIndexSound = AAE.timerTable[index].timerIndexSound
	local curMissileCount = 0
	
	for key, value in pairs(missileGroup) do
		local intervalCount = value.intervalCount + 1
		value.intervalCount = intervalCount
		local missileDirection = value.direction
		local curVec
		
		if (intervalCount <= 30) then
			curVec = Vector(casterLoc.x + casterFacingX * 20.0 * intervalCount * missileDirection, casterLoc.y + casterFacingY * 20.0 * intervalCount * missileDirection, 128.0)
		else
			if (intervalCount <= 300) then --Drehgeschwindigkeit 1*PI pro Sekunde, also ca 57,296 Grad
				curVec = Vector(casterLoc.x + math.cos(casterFacing + (intervalCount - 30)  * 0.033333333) * 600.0 * missileDirection, casterLoc.y + math.sin(casterFacing + (intervalCount - 30)  * 0.033333333) * 600.0 * missileDirection, 128.0)
				if (intervalCount == 300) then
					value.dX = (curVec.x - casterLoc.x)/600.0
					value.dY = (curVec.y - casterLoc.y)/600.0
				end
			else
				curVec = Vector( casterLoc.x + (330 - intervalCount) * 20.0 * value.dX , casterLoc.y + (330 - intervalCount) * 20.0 * value.dY , 128.0)
			end
		end
		curVec = VectorInMapBounds(curVec)
		key:SetAbsOrigin(curVec)
		
		local newCliffLevel = (GetGroundPosition(curVec, nil)).z
		
		if (intervalCount >= 330 or not caster:IsAlive() or cliffLevel + 5.0 < newCliffLevel) then
			missileGroup[key] = nil
			key:RemoveSelf()
		else
			curMissileCount = curMissileCount + 1
			
			local collision, targetUnit = IsMissileColliding (caster, curVec, deadlyRange_collisionSize)
			
			if (collision) then
				DealDamageOverTimeInit (caster, targetUnit, 0.0999, 0.6, 75, "deadlyRange_Dot")
				
				missileGroup[key] = nil
				key:RemoveSelf()
			end
		end
	end
	
	if (missilesCreated == 16 and curMissileCount == 0) then
		StopSoundOnUnit(timerIndexSound)
		AAE.timerTable[index] = nil
	else
		return 0.01
	end
end



function DeadlyRange_CreateMissiles (index)
	local caster = AAE.timerTable[index].caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local missilesCreated = AAE.timerTable[index].missilesCreated + 2
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local missileGroup = AAE.timerTable[index].missileGroup
	local newCliffLevel = (GetGroundPosition(casterLoc, nil)).z
	AAE.timerTable[index].missilesCreated = missilesCreated
	
	if (cliffLevel + 5.0 >= newCliffLevel) then
		local missileDummy = CreateUnitByName("aae_dummy_mage_mcBomb_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_mcBomb_missile"):SetLevel(1)
		missileGroup[missileDummy] = { direction = 1, intervalCount = 0, dX = 1.0, dY = 0.0 }
		missileDummy = CreateUnitByName("aae_dummy_mage_mcBomb_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_mcBomb_missile"):SetLevel(1)
		missileGroup[missileDummy] = { direction = -1, intervalCount = 0, dX = 1.0, dY = 0.0 }
	end
	
	if (missilesCreated < 16) then
		return 0.399
	end
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterLoc = caster:GetAbsOrigin()
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	local casterFacing = (caster:GetAngles()).y * 0.01745329
	local dX = math.cos(casterFacing)
	local dY = math.sin(casterFacing)
	local missileGroup = {}

	local timerIndexSound = PlaySoundOnUnitInit("Hero_Phoenix.SunRay.Loop", caster, 5.0, true)
	
	local timerIndex = GetTimerIndex()
	AAE.timerTable[timerIndex] = { caster = caster, missilesCreated = 0, cliffLevel = cliffLevel, casterFacing = casterFacing, casterFacingX = dX, casterFacingY = dY, missileGroup = missileGroup, timerIndexSound = timerIndexSound }
	AAE.Utils.Timer.Register( DeadlyRange_MoveMissiles, 0.01, timerIndex )
	AAE.Utils.Timer.Register( DeadlyRange_CreateMissiles, 0.399, timerIndex )
end
