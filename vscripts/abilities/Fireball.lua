require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



fireball_collisionSize = 30.0
fireball_explosionAoe = 440.0



function FireballUpdate(index)
	local caster = AAE.timerTable[index].caster
	local missileDummy = AAE.timerTable[index].missileDummy
	local lastFireballLoc = AAE.timerTable[index].lastFireballLoc
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local normVecDir = AAE.timerTable[index].normVecDir
	
	local casterOwner = caster:GetOwner()
	local newFireballLoc = VectorInMapBounds(lastFireballLoc + (normVecDir * 50.0)) --50
	local newCliffLevel = (GetGroundPosition(newFireballLoc, nil)).z
	
	if (cliffLevel + 5.0 < newCliffLevel) then
		newFireballLoc = lastFireballLoc
	else
		missileDummy:SetAbsOrigin(newFireballLoc)
		if (intervalCount >= 20) then --20
		else
			local explosion = IsMissileColliding (caster, newFireballLoc, fireball_collisionSize)
			
			if (not explosion) then
				AAE.timerTable[index].lastFireballLoc = newFireballLoc
				AAE.timerTable[index].intervalCount = intervalCount
			
				return 0.01
			end
		end
	end
	
	local explosionDummy = CreateUnitByName("aae_dummy_mage_fireball_explosion", newFireballLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	explosionDummy:FindAbilityByName("aae_d_mage_fireball_explosion"):SetLevel(1)
	RemoveDummyTimedInit(explosionDummy, 3.0)
	RemoveDummyTimedInit(missileDummy, 0.4)

	PlaySoundOnUnitInit("Hero_Batrider.Flamebreak.Impact", explosionDummy, 2.0, false)
	
	for pickedUnit, _ in pairs(AAE.allUnits) do
		--local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		local vecDistUnitExplosion = pickedUnitPos - newFireballLoc
		local dX = vecDistUnitExplosion.x
		local dY = vecDistUnitExplosion.y
		
		if (math.abs(dX) < fireball_explosionAoe + pickedUnitSize and math.abs(dY) < fireball_explosionAoe + pickedUnitSize) then
			if (dX*dX + dY*dY <= (fireball_explosionAoe + pickedUnitSize)*(fireball_explosionAoe + pickedUnitSize)) then
				local distUnitExplosion = math.sqrt(dX*dX + dY*dY)
				local distUnitExplosion2 = max(0.0, distUnitExplosion - pickedUnitSize)
				local knockbackDist
				
				if (distUnitExplosion == 0.0) then
					knockbackDist = 440.0 * 1.364
				else
					local normVecDistUnitExplosion = Vector(dX / distUnitExplosion, dY / distUnitExplosion, 0.0)
					knockbackDist = (440.0 - distUnitExplosion2) * 1.364
					KnockbackUnitInit ( pickedUnit, knockbackDist, normVecDistUnitExplosion )
				end
				
				DealDamage (caster, pickedUnit, knockbackDist / 10.909)
			end
		end
	end
	
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	local timerIndex = GetTimerIndex()
	
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
	
	local missileDummy = CreateUnitByName("aae_dummy_mage_fireball_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_fireball_missile"):SetLevel(1)

	PlaySoundOnUnitInit("Hero_Batrider.Flamebreak", missileDummy, 2.0, false)
	
	AAE.timerTable[timerIndex] = { caster = caster, missileDummy = missileDummy, lastFireballLoc = casterLoc, intervalCount = 0, cliffLevel = cliffLevel, normVecDir = normVecDir }
	AAE.Utils.Timer.Register( FireballUpdate, 0.01, timerIndex )
end
