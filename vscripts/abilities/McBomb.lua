require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



mcBomb_explosionAoe = 550.0



function McBombUpdate (index)
	local caster = AAE.timerTable[index].caster
	local missileDummy = AAE.timerTable[index].missileDummy
	local castLoc = AAE.timerTable[index].castLoc
	local lastBombLoc = AAE.timerTable[index].lastBombLoc
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local timerIndexSound = AAE.timerTable[index].timerIndexSound
	
	local casterOwner = caster:GetOwner()
	local curCasterLoc = caster:GetAbsOrigin()
	local newBombLoc = VectorInMapBounds((curCasterLoc - castLoc) * 3 + castLoc)
	local newCliffLevel = (GetGroundPosition(newBombLoc, nil)).z
	
	if (cliffLevel + 5.0 < newCliffLevel) then
		newBombLoc = lastBombLoc
	else
		if (intervalCount >= 75) then
		else
			missileDummy:SetAbsOrigin(newBombLoc)
			
			if (intervalCount % 1 == 0) then
				local def = { num = 250.0 - intervalCount * 3.333333333, location = newBombLoc, duration = 0.1, color = Vector(intervalCount*3.4, 255.0 - intervalCount*3.4, 0) }
				ShowFloatingNum(def)
			end
			
			AAE.timerTable[index].lastBombLoc = newBombLoc
			AAE.timerTable[index].intervalCount = intervalCount
			
			return 0.01
		end
	end

	local explosionDummy
	for i=0, 1, 1 do
		explosionDummy = CreateUnitByName("aae_dummy_mage_mcBomb_explosion", newBombLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		explosionDummy:FindAbilityByName("aae_d_mage_mcBomb_explosion"):SetLevel(1)
		RemoveDummyTimedInit(explosionDummy, 3.0)
		
		explosionDummy = CreateUnitByName("aae_dummy_mage_mcBomb_explosion_1", newBombLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		explosionDummy:FindAbilityByName("aae_d_mage_mcBomb_explosion_1"):SetLevel(1)
		RemoveDummyTimedInit(explosionDummy, 3.0)
	end
	RemoveDummyTimedInit(missileDummy, 0.4)

	StopSoundOnUnit(timerIndexSound)
	PlaySoundOnUnitInit("Hero_Techies.Suicide", explosionDummy, 4.0, false)
	
	for pickedUnit, _ in pairs(AAE.allUnits) do
		--local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		local vecDistUnitExplosion = pickedUnitPos - newBombLoc
		local dX = vecDistUnitExplosion.x
		local dY = vecDistUnitExplosion.y
		
		if (math.abs(dX) < mcBomb_explosionAoe + pickedUnitSize and math.abs(dY) < mcBomb_explosionAoe + pickedUnitSize) then
			if (dX*dX + dY*dY <= (mcBomb_explosionAoe + pickedUnitSize)*(mcBomb_explosionAoe + pickedUnitSize)) then
				local distUnitExplosion = math.sqrt(dX*dX + dY*dY)
				local distUnitExplosion2 = max(0.0, distUnitExplosion - pickedUnitSize)
				local knockbackDist
				
				if (distUnitExplosion == 0.0) then
					knockbackDist = (550.0 - distUnitExplosion) * 1.364
				else
					local normVecDistUnitExplosion = Vector(dX / distUnitExplosion, dY / distUnitExplosion, 0.0)
					knockbackDist = (550.0 - distUnitExplosion2) * 1.364
					KnockbackUnitInit ( pickedUnit, knockbackDist, normVecDistUnitExplosion )
				end
				
				DealDamage (caster, pickedUnit, knockbackDist / 4.5)
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
	
	local missileDummy = CreateUnitByName("aae_dummy_mage_mcBomb_missile", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_mcBomb_missile"):SetLevel(1)

	local timerIndexSound = PlaySoundOnUnitInit("Hero_Batrider.Firefly.loop", missileDummy, 2.0, true)
	
	local def = { num = 250, location = casterLoc, duration = 0.1, color = Vector(0,255,0) }
	ShowFloatingNum(def)
	
	AAE.timerTable[timerIndex] = { caster = caster, missileDummy = missileDummy, castLoc = casterLoc, lastBombLoc = casterLoc, intervalCount = 0, cliffLevel = cliffLevel, timerIndexSound = timerIndexSound }
	
	AAE.Utils.Timer.Register( McBombUpdate, 0.01, timerIndex )
end
