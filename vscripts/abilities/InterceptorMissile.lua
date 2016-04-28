require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



function InteceptorMissile_HookUpdate(index)
	local caster = AAE.timerTable[index].caster
	local targetMissile = AAE.timerTable[index].targetMissile
	local lightningBolt = AAE.timerTable[index].lightningBolt
	
	local casterPos = caster:GetAbsOrigin()
	local missilePos = targetMissile:GetAbsOrigin()
	local distance = math.sqrt((casterPos.x-missilePos.x)*(casterPos.x-missilePos.x) + (casterPos.y-missilePos.y)*(casterPos.y-missilePos.y))
	local delta = (missilePos - casterPos)
	delta.z = 0
	if (distance ~=0) then
		delta = delta/distance
	end
	
	if (GetBuffCountOnUnit (caster, "interceptorMissile", index) >= 1) then
		if (caster:IsAlive() and targetMissile:IsAlive()) then
			if (distance < 32.0) then
				AAE.allUnits[targetMissile] = nil
				targetMissile:ForceKill(true)
				caster:SetAbsOrigin(missilePos)
			else
				if (GetBuffCountOnUnit (caster, "magicLasso") >= 1 or GetBuffCountOnUnit (caster, "snowball") >= 1) then
				else
					caster:SetAbsOrigin( VectorInMapBounds(casterPos + delta * 32.0) )
				end
				ParticleManager:SetParticleControl(lightningBolt, 1, missilePos) --Move lightning target to the current position of the target missile.
				return 0.01
			end
		end
	end
	
	ParticleManager:DestroyParticle(lightningBolt, true)
	DecreaseBuffCountOnUnit (caster, "interceptorMissile", index)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	
	local targetPoint = nil
	if (keys.Target == "POINT" and keys.target_points[1]) then
		targetPoint = keys.target_points[1]
	else
		return
	end
	targetPoint.z = cliffLevel
	
	local normVecDir = targetPoint - casterLoc
	local targetCasterDist = math.sqrt(normVecDir.x*normVecDir.x + normVecDir.y*normVecDir.y)
	if (targetCasterDist ~= 0) then
		normVecDir = normVecDir/targetCasterDist
	else
		targetCasterDist = 1
		normVecDir = Vector(1.0, 0.0, 0.0)
	end
	
	local minDistSq = 40000.0
	local minDistUnit = nil
	
	for pickedUnit, _ in pairs(AAE.allUnits) do
		--local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitX = pickedUnitPos.x
		local pickedUnitY = pickedUnitPos.y
		
		if (pickedUnit:GetUnitName() == "aae_dummy_mage_interceptorMissile_missile") then
			local targetPickedDistSq = (pickedUnitX-targetPoint.x)*(pickedUnitX-targetPoint.x) + (pickedUnitY-targetPoint.y)*(pickedUnitY-targetPoint.y)
			if (targetPickedDistSq < minDistSq) then
				minDistSq = targetPickedDistSq
				minDistUnit = pickedUnit
			end
		end
	end
	
	if (minDistUnit == nil) then
		if (targetCasterDist > 650.0) then
			targetCasterDist = 650.0
		end
		missileDummy = CreateUnitByName("aae_dummy_mage_interceptorMissile_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_interceptorMissileProperties"):SetLevel(1)
		KnockbackUnitInit ( missileDummy, targetCasterDist, normVecDir )
	else
		local targetMissilePos = minDistUnit:GetAbsOrigin()
		local targetMissileDist = math.sqrt((targetMissilePos.x-casterLoc.x)*(targetMissilePos.x-casterLoc.x) + (targetMissilePos.y-casterLoc.y)*(targetMissilePos.y-casterLoc.y))
		if (targetMissileDist > 750.0) then
			--PlaySoundOnUnitInit("Hero_Juggernaut.HealingWard.Loop", caster, 1.0, true)
			
			local timerIndex = GetTimerIndex()
			
			local lightningBolt = ParticleManager:CreateParticle("particles/interceptormissile/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(lightningBolt,1,Vector(targetMissilePos.x, targetMissilePos.y, targetMissilePos.z + 20.0))
			
			IncreaseBuffCountOnUnit (caster, "interceptorMissile", timerIndex)
			
			AAE.timerTable[timerIndex] = { caster = caster, targetMissile = minDistUnit, lightningBolt = lightningBolt }
			AAE.Utils.Timer.Register( InteceptorMissile_HookUpdate, 0.01, timerIndex )
		else
			local explosionDummy = CreateUnitByName("aae_dummy_mage_mcBomb_explosion", targetMissilePos, false, casterOwner, casterOwner, caster:GetTeamNumber())
			explosionDummy:FindAbilityByName("aae_d_mage_mcBomb_explosion"):SetLevel(1)
			RemoveDummyTimedInit(explosionDummy, 3.0)
			AAE.allUnits[minDistUnit] = nil
			minDistUnit:ForceKill(true)
			caster:SetAbsOrigin(targetMissilePos)
		end
	end
end
