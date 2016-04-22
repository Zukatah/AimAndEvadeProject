require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



hauntingBlaze_collisionSize = 50.0
hauntingBlaze_explosionAoe = 440.0



function HauntingBlazeUpdate(index) --Create up to 18 lightning instances
	local caster = AAE.timerTable[index].caster
	local castLoc = AAE.timerTable[index].castLoc
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local missileDummy = AAE.timerTable[index].missileDummy
	local oldMissileLoc = missileDummy:GetAbsOrigin()
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local normVecDir = AAE.timerTable[index].normVecDir
	local curPoint
	local cliffLevel = AAE.timerTable[index].cliffLevel
	AAE.timerTable[index].intervalCount = intervalCount
	
	local locX = casterLoc.x
	local locY = casterLoc.y
	local distancePar
	if (normVecDir.y ~= 0.0) then
		distancePar = ((((-normVecDir.x / normVecDir.y) * (castLoc.y - locY)) + (castLoc.x - locX)) / (((-normVecDir.x * normVecDir.x) / normVecDir.y) - normVecDir.y))
	else
		if (normVecDir.x > 0.0) then
			distancePar = castLoc.y - locY
		else
			distancePar = locY - castLoc.y
		end
	end
	
	curPoint = VectorInMapBounds(Vector(castLoc.x + intervalCount * 40.0 * normVecDir.x, castLoc.y + intervalCount * 40.0 * normVecDir.y, 0.0) - Vector(-normVecDir.y * distancePar, normVecDir.x * distancePar, 0.0))
	local newCliffLevel = (GetGroundPosition(curPoint, nil)).z
	
	if (cliffLevel + 5.0 < newCliffLevel) then
		curPoint = oldMissileLoc
	else
		missileDummy:SetAbsOrigin(curPoint)
		if (intervalCount >= 100) then
		else
			local explosion = IsMissileColliding (caster, curPoint, hauntingBlaze_collisionSize)
			
			if (not explosion) then
				return 0.01
			end
		end
	end
	
	local explosionDummy = CreateUnitByName("aae_dummy_mage_fireball_explosion", curPoint, false, casterOwner, casterOwner, caster:GetTeamNumber())
	explosionDummy:FindAbilityByName("aae_d_mage_fireball_explosion"):SetLevel(1)
	RemoveDummyTimedInit(explosionDummy, 3.0)
	RemoveDummyTimedInit(missileDummy, 0.4)
	
	for key, value in pairs(AAE.allUnits) do
		local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		local vecDistUnitExplosion = pickedUnitPos - curPoint
		local dX = vecDistUnitExplosion.x
		local dY = vecDistUnitExplosion.y
		
		if (math.abs(dX) < hauntingBlaze_explosionAoe + pickedUnitSize and math.abs(dY) < hauntingBlaze_explosionAoe + pickedUnitSize) then
			if (dX*dX + dY*dY <= (hauntingBlaze_explosionAoe + pickedUnitSize)*(hauntingBlaze_explosionAoe + pickedUnitSize)) then
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
	local castLoc = caster:GetAbsOrigin()
	local missileDummy
	local intervalCount = 0
	local cliffLevel = (GetGroundPosition(castLoc, nil)).z
	local timerIndex = GetTimerIndex()
	
	local targetPoint = nil
	if (keys.Target == "POINT" and keys.target_points[1]) then
		targetPoint = keys.target_points[1]
	else
		return
	end
	targetPoint.z = cliffLevel
	
	local normVecDir = targetPoint - castLoc
	local vecDirLen = math.sqrt((normVecDir.x)*(normVecDir.x)+(normVecDir.y)*(normVecDir.y))
	if (vecDirLen ~= 0) then
		normVecDir=normVecDir/vecDirLen
	else
		normVecDir=Vector(1.0, 0.0, 0.0)
	end
	
	missileDummy = CreateUnitByName("aae_dummy_mage_fireball_missile", castLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_fireball_missile"):SetLevel(1)
	
	AAE.timerTable[timerIndex] = { caster = caster, castLoc = castLoc, missileDummy = missileDummy, intervalCount = intervalCount, cliffLevel = cliffLevel, normVecDir = normVecDir }
	AAE.Utils.Timer.Register( HauntingBlazeUpdate, 0.01, timerIndex )
end
