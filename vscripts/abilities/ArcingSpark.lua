require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



arcingSpark_collisionSize = 30.0



function ArcingSparkUpdate(index)
	local caster = AAE.timerTable[index].caster 
	local missileDummy = AAE.timerTable[index].missileDummy
	local lastArcSparkLoc = missileDummy:GetAbsOrigin()
	local missileLoc = missileDummy:GetAbsOrigin()
	local missileLocX = missileLoc.x
	local missileLocY = missileLoc.y
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local normVecDir = AAE.timerTable[index].normVecDir
	local chargeCount = AAE.timerTable[index].chargeCount								-- hit lightning counter
	local curSpeed = 1200.0 * (1 + chargeCount * 0.2)									-- *1.2 per charge

    local arcSparkPar																	-- how far to a possible collision with a lightning
    local remainingArcSparkPar															-- the distance back after a collision with a lightning
    local collision = false																-- was there a collision?
    local collisionPointX
    local collisionPointY
    local mirrorLineMovementX															-- orthogonal line to the lightning
    local mirrorLineMovementY															-- orthogonal line to the lightning
    local distToMirroredLine																-- distance to the mirror line
    local pointOnMirroredLineX															-- point on mirrored line X
    local pointOnMirroredLineY															-- point on mirrored line Y
    local movementVecMirroredLineX														-- vector between pointOnMirroredLine and collision point
    local movementVecMirroredLineY														-- vector between pointOnMirroredLine and collision point
    local lightningMovementPar															-- 
    local lightningLength																-- length of the lightning we hit
	
	
	AAE.timerTable[index].intervalCount = intervalCount								-- save intervalCount in table
	
	for i, value in pairs(AAE.lightningTab) do										-- iterate through all lightnings
		if (normVecDir.x * AAE.lightningTab[i].normY == -normVecDir.y * AAE.lightningTab[i].normX) then			-- test if both (lightning and arcSpark) lines parallel
			arcSparkPar = -1.0
		elseif (AAE.lightningTab[i].normY == 0.0) then
			arcSparkPar = (AAE.lightningTab[i].startY - missileLocY) / normVecDir.y		-- normVecDir.y can't be 0 because the lines are not parallel
		else
			arcSparkPar = ((-AAE.lightningTab[i].normX / AAE.lightningTab[i].normY) * (AAE.lightningTab[i].startY - missileLocY) + AAE.lightningTab[i].startX - missileLocX) / (normVecDir.x + (-normVecDir.y * AAE.lightningTab[i].normX) / AAE.lightningTab[i].normY)
		end
		
		if (arcSparkPar <= curSpeed / 30.0 and arcSparkPar > 0.0) then
			collisionPointX = missileLocX + arcSparkPar * normVecDir.x
			collisionPointY = missileLocY + arcSparkPar * normVecDir.y
			lightningLength = math.sqrt((AAE.lightningTab[i].startX - AAE.lightningTab[i].endX) * (AAE.lightningTab[i].startX - AAE.lightningTab[i].endX) + (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY) * (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY) + (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY))	-- Lightning length
			
			if (AAE.lightningTab[i].normX == 0) then
				lightningMovementPar = (collisionPointY - AAE.lightningTab[i].startY) / AAE.lightningTab[i].normY
			else
				lightningMovementPar = (collisionPointX - AAE.lightningTab[i].startX) / AAE.lightningTab[i].normX
			end
			
			if (lightningMovementPar >= 0 and lightningMovementPar <= lightningLength) then							-- when collision was on lightning
				collision = true
				if (chargeCount < 8) then
					chargeCount = chargeCount + 1
					AAE.timerTable[index].chargeCount = chargeCount
				end
				remainingArcSparkPar = curSpeed/30.0 - arcSparkPar
				mirrorLineMovementX = -AAE.lightningTab[i].normY								-- build orthogonal line
				mirrorLineMovementY = AAE.lightningTab[i].normX
				
				if (AAE.lightningTab[i].normX ~= 0.0) then
					--GameRules:SendCustomMessage ("3.1", 1, 1)
					distToMirroredLine = 2.0 * (((-mirrorLineMovementX / mirrorLineMovementY) * (collisionPointY - missileLocY) + collisionPointX - missileLocX) / (AAE.lightningTab[i].normX + (-AAE.lightningTab[i].normY * mirrorLineMovementX) / mirrorLineMovementY))
				else
					--GameRules:SendCustomMessage ("3.2", 1, 1)
					if (AAE.lightningTab[i].normY > 0.0) then
						distToMirroredLine = (collisionPointY - missileLocY) * 2.0
					else
						distToMirroredLine = -(collisionPointY - missileLocY) * 2.0
					end
				end
				--GameRules:SendCustomMessage ("distToMirroredLine: " .. tostring(distToMirroredLine), 1, 1)
				pointOnMirroredLineX = missileLocX + AAE.lightningTab[i].normX * distToMirroredLine
				pointOnMirroredLineY = missileLocY + AAE.lightningTab[i].normY * distToMirroredLine
				movementVecMirroredLineX = (pointOnMirroredLineX - collisionPointX) / arcSparkPar
				movementVecMirroredLineY = (pointOnMirroredLineY - collisionPointY) / arcSparkPar
				--GameRules:SendCustomMessage ("X: " .. tostring(movementVecMirroredLineX) .. " Y: " .. tostring(movementVecMirroredLineY) .. " ArcSparkPark: " .. tostring(arcSparkPar), 1, 1)
				
				
				missileLocX = collisionPointX + remainingArcSparkPar * movementVecMirroredLineX
				missileLocY = collisionPointY + remainingArcSparkPar * movementVecMirroredLineY
				normVecDir.x = movementVecMirroredLineX
				normVecDir.y = movementVecMirroredLineY
				AAE.timerTable[index].normVecDir = Vector(normVecDir.x, normVecDir.y, 0.0)
				--GameRules:SendCustomMessage ("4", 1, 1)
				break
			end
		end
	end
	
	
	if (collision == false) then
		missileLocX = missileLocX + curSpeed/30.0 * normVecDir.x
		missileLocY = missileLocY + curSpeed/30.0 * normVecDir.y
	end
	--GameRules:SendCustomMessage ("Normvecdir:" .. tostring(normVecDir), 1, 1)
	--GameRules:SendCustomMessage ("missileLoc: " .. tostring(missileLoc), 1, 1)
	
	missileLoc = VectorInMapBounds (Vector(missileLocX, missileLocY, 0.0))
	missileDummy:SetAbsOrigin(missileLoc)
	--GameRules:SendCustomMessage ("Usw: " .. tostring(missileLoc), 1, 1)

	local unitCollision, targetUnit = IsMissileColliding (caster, missileLoc, arcingSpark_collisionSize)
	
	if (unitCollision) then --TODO: Implement all the chain lightning stuff...
		local dmg = 40.0 + 60.0 * chargeCount                           --base attack damage
		local hitTable = {}                                     		--Table of hit units. Lightning never strikes twice in the same place
		local targetLoc = targetUnit:GetAbsOrigin()
		local targetX = targetLoc.x
		local targetY = targetLoc.y
		local targetZ = targetLoc.z
		local casterLoc = caster:GetAbsOrigin()
		local casterX = casterLoc.x
		local casterY = casterLoc.y
		local lightStartUnit = caster
		local lightStartUnitLoc = lightStartUnit:GetAbsOrigin()
		local lightStartX = lightStartUnitLoc.x
		local lightStartY = lightStartUnitLoc.y
		
		PlaySoundOnUnitInit("Hero_Zuus.LightningBolt", targetUnit, 2.0, false)
		
		DealDamage (caster, targetUnit, dmg)
		hitTable[targetUnit:GetEntityIndex()] = true
		lightningBolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, lightStartUnit)
		ParticleManager:SetParticleControl(lightningBolt,1,Vector(targetX, targetY, targetZ + ((targetUnit:GetBoundingMaxs().z - targetUnit:GetBoundingMins().z)/2)))
	   
		while (true) do
			
			lightStartUnit = targetUnit
			lightStartX = targetX
			lightStartY = targetY
			
			local minDist = 1000000
			local minDistUnit = nil
			
			for key, value in pairs (AAE.allUnits) do
				local pickedUnit = EntIndexToHScript(key)
				local pickedUnitLoc = pickedUnit:GetAbsOrigin()
				local pickedUnitX = pickedUnitLoc.x
				local pickedUnitY = pickedUnitLoc.y
				local alreadyHit = false
				if (hitTable[pickedUnit:GetEntityIndex()] == nil) then
					local sqDistLightUnit = (lightStartX - pickedUnitX)*(lightStartX - pickedUnitX) + (lightStartY - pickedUnitY)*(lightStartY - pickedUnitY)
					--GameRules:SendCustomMessage (tostring(sqDistLightUnit), 1, 1)
					if (sqDistLightUnit < minDist) then
						minDist = sqDistLightUnit
						minDistUnit = pickedUnit
					end
				end
			end
			--GameRules:SendCustomMessage (tostring(minDist), 1, 1)
			if (minDist <= 160000) then
				
				targetUnit = minDistUnit                                           --unit becomes new start point
				targetLoc = targetUnit:GetAbsOrigin()
				targetX = targetLoc.x
				targetY = targetLoc.y
				targetZ = targetLoc.z
				lightningBolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, lightStartUnit)
				ParticleManager:SetParticleControl(lightningBolt,1,Vector(targetX, targetY, targetZ + ((targetUnit:GetBoundingMaxs().z - targetUnit:GetBoundingMins().z)/2)))
				hitTable[targetUnit:GetEntityIndex()] = true
				DealDamage (caster, targetUnit, dmg)
			else
				break
			end

		end
	end
	
	if (intervalCount >= 67 + chargeCount * 27 or unitCollision) then
		RemoveDummyTimedInit(missileDummy, 0.1)
		AAE.arcSparkGroup[missileDummy] = nil
		AAE.timerTable[index] = nil
	else
		return 0.01
	end
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local missileDummy
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
	
	missileDummy = CreateUnitByName("aae_dummy_mage_arcingSpark", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_arcingSpark"):SetLevel(1)
	AAE.arcSparkGroup[missileDummy] = {}
	
	for key, value in pairs (AAE.lightningTab) do --TODO: Side check
		if (-AAE.lightningTab[key].normY * casterLoc.x + AAE.lightningTab[key].normX * casterLoc.y >= -AAE.lightningTab[key].normY * AAE.lightningTab[key].startX + AAE.lightningTab[key].normX * AAE.lightningTab[key].startY) then
			AAE.arcSparkGroup[missileDummy][key] = true --right = true, left = false
		else
			AAE.arcSparkGroup[missileDummy][key] = false
		end
	end
	
	AAE.timerTable[timerIndex] = { caster = caster, missileDummy = missileDummy, intervalCount = 0, normVecDir = normVecDir, chargeCount = 0 }
	AAE.Utils.Timer.Register( ArcingSparkUpdate, 0.01, timerIndex )
end
