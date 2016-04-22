require( "utils.timer" )



curIndex = 0
function GetTimerIndex ()
	curIndex = curIndex + 1
	return curIndex
end



function ShowFloatingNum(def)
	if not def.num or not def.location or def.num < 1 then
		return
	end
   
	local duration = def.duration or 1
	local color = def.color or Vector(255, 255, 255)
   
	-- Round number and display only needed digits
	local strnum = string.format("%.0f", def.num)
	local digits = strnum:len()
   
	-- Create the particle system that displays the text
	local pid = ParticleManager:CreateParticle("particles/msg_fx/msg_evade.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(pid, 0, def.location)
	ParticleManager:SetParticleControl(pid, 1, Vector(1, tonumber(strnum), 0))
	ParticleManager:SetParticleControl(pid, 2, Vector(duration, digits, digits))
	ParticleManager:SetParticleControl(pid, 3, color)
	
	AAE.Utils.Timer.Register( 
		function(index)
			ParticleManager:ReleaseParticleIndex(pid)
		end, 
		duration, GetTimerIndex() )
end



--Map Bounds: x = -3800 - 3800, y = -3800 - 3800
function VectorInMapBounds (vector)
	if (vector.x > AAE.MAX_X) then
		vector.x = AAE.MAX_X
	end
	if (vector.x < AAE.MIN_X) then
		vector.x = AAE.MIN_X
	end
	if (vector.y > AAE.MAX_Y) then
		vector.y = AAE.MAX_Y
	end
	if (vector.y < AAE.MIN_Y) then
		vector.y = AAE.MIN_Y
	end
	
	local cliffLevelVector = GetGroundPosition(vector, nil)
	local cliffLevel = cliffLevelVector.z

	return Vector( vector.x, vector.y, cliffLevel )
end



function GetRandomPosition()
	return VectorInMapBounds( Vector( AAE.MIN_X + math.random()*(AAE.MAX_X - AAE.MIN_X), AAE.MIN_Y + math.random()*(AAE.MAX_Y - AAE.MIN_Y), 0 ) )
end



function KnockbackUnit ( timerIndex )
	local unit = AAE.timerTable[timerIndex].unit
	local curSpeed = AAE.timerTable[timerIndex].curSpeed
	local normVec = AAE.timerTable[timerIndex].normVec
	
	if (GetBuffCountOnUnit (unit, "knockback", timerIndex) >= 1) then
		local unitPos = unit:GetAbsOrigin()
		local newUnitPos = VectorInMapBounds(unitPos + normVec*curSpeed/30.0)
		
		if (GetBuffCountOnUnit (unit, "magicLasso") >= 1 or GetBuffCountOnUnit (unit, "snowball") >= 1) then
		else
			unit:SetAbsOrigin(newUnitPos)
		end
		
		curSpeed = curSpeed - 100.0/3.0
		
		AAE.timerTable[timerIndex].curSpeed = curSpeed
		
		if (curSpeed > 0) then 
			return 0.01
		end
	end
	
	--GameRules:SendCustomMessage ("Delete because BuffCount = " .. tostring(GetBuffCountOnUnit (unit, "knockback", timerIndex)), 1, 1)
	local instancesCount = DecreaseBuffCountOnUnit (unit, "knockback", timerIndex)
	if (instancesCount <= 0) then
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end
	--GameRules:SendCustomMessage ("BuffCount after decrease = " .. tostring(GetBuffCountOnUnit (unit, "knockback", timerIndex)), 1, 1)
	
	AAE.timerTable[timerIndex] = nil
end



function KnockbackUnitInit ( unit, knockbackDist, normVec )
	local timerIndex = GetTimerIndex()
	local startSpeed = 44.72136 * math.sqrt(knockbackDist)
	
	IncreaseBuffCountOnUnit (unit, "knockback", timerIndex)
	
	AAE.timerTable[timerIndex] = { unit = unit, curSpeed = startSpeed, normVec = normVec }
	AAE.Utils.Timer.Register( KnockbackUnit, 0.01, timerIndex )
end



function IncreaseBuffCountOnUnit (unit, buffName, timerIndex, speedFactor) --modifier (e.g. rooted, silence, invu,    graphic modifiers / buffsymbol modifiers)
	--AAE:SendCustomMessage ("Unit " .. tostring(unit) .. " Buff " .. tostring(buffName), 1, 1)
	if (AAE.buffsOnUnitTab[unit] == nil) then
		AAE.buffsOnUnitTab[unit] = {}
		AAE.buffsOnUnitTab[unit][buffName] = {}
		AAE.buffsOnUnitTab[unit][buffName].buffCount = 1
		AAE.buffsOnUnitTab[unit][buffName].buffInstInf = {}
	else
		if (AAE.buffsOnUnitTab[unit][buffName] == nil) then
			AAE.buffsOnUnitTab[unit][buffName] = {}
			AAE.buffsOnUnitTab[unit][buffName].buffCount = 1
			AAE.buffsOnUnitTab[unit][buffName].buffInstInf = {}
		else
			AAE.buffsOnUnitTab[unit][buffName].buffCount = AAE.buffsOnUnitTab[unit][buffName].buffCount + 1
		end
	end
	
	if (timerIndex ~= nil) then
		if (AAE.buffInfoTab[buffName].isMovementModifier == true) then
			AAE.buffsOnUnitTab[unit][buffName].buffInstInf[timerIndex] = {speedFactor = speedFactor}
			UpdateMovementSpeed(unit)
		else
			AAE.buffsOnUnitTab[unit][buffName].buffInstInf[timerIndex] = true
		end
	end
	
	if (AAE.buffsOnUnitTab[unit][buffName].buffCount == 1) then
		for _, value in pairs(AAE.modsInBuffTab[buffName]) do
			local builtInMod = AAE.modTypeTab[value]
			
			if (builtInMod) then
				unit:AddNewModifier( unit, nil, value, {} )
			else
				local dummyItem = CreateItem("item_modifier_master", nil, nil) 
				dummyItem:ApplyDataDrivenModifier(unit, unit, value, {})
			end
			--AAE:SendCustomMessage ("Key " .. tostring(key) .. " Value " .. tostring(value), 1, 1)
		end
	end
	
	return AAE.buffsOnUnitTab[unit][buffName].buffCount
end



function DecreaseBuffCountOnUnit (unit, buffName, timerIndex)
	--GameRules:SendCustomMessage ("Dec unit  " .. tostring(unit) .. " buffName " .. tostring(buffName) .. " timerIndex " .. tostring(timerIndex), 1, 1)
	if (timerIndex == nil) then
		AAE.buffsOnUnitTab[unit][buffName].buffCount = AAE.buffsOnUnitTab[unit][buffName].buffCount - 1
	else
		if (AAE.buffsOnUnitTab[unit][buffName].buffInstInf[timerIndex] == nil) then
		else
			AAE.buffsOnUnitTab[unit][buffName].buffInstInf[timerIndex] = nil
			AAE.buffsOnUnitTab[unit][buffName].buffCount = AAE.buffsOnUnitTab[unit][buffName].buffCount - 1
			if (AAE.buffInfoTab[buffName].isMovementModifier == true) then
				UpdateMovementSpeed(unit)
			end
		end
	end
	
	if (AAE.buffsOnUnitTab[unit][buffName].buffCount <= 0) then
		for _, value in pairs(AAE.modsInBuffTab[buffName]) do
			unit:RemoveModifierByName(value)
		end
	end
	
	return AAE.buffsOnUnitTab[unit][buffName].buffCount
end



function RemoveBuffTypeFromUnit (unit, buffName)
	if (AAE.buffsOnUnitTab[unit] == nil) then
		return
	end
	
	if (AAE.buffsOnUnitTab[unit][buffName] == nil) then
		return
	end
	
	if (AAE.buffsOnUnitTab[unit][buffName].buffCount > 0) then
		AAE.buffsOnUnitTab[unit][buffName].buffInstInf = {}
		AAE.buffsOnUnitTab[unit][buffName].buffCount = 0
		
		for _, value in pairs(AAE.modsInBuffTab[buffName]) do
			unit:RemoveModifierByName(value)
		end
		
		if (AAE.buffInfoTab[buffName].isMovementModifier == true) then
			UpdateMovementSpeed(unit)
		end
	end
end



function RemoveBuffFromUnitTimed (timerIndex)
	local unit = AAE.timerTable[timerIndex].unit
	local buffName = AAE.timerTable[timerIndex].buffName
	DecreaseBuffCountOnUnit(unit, buffName, timerIndex)
	AAE.timerTable[timerIndex] = nil
end



function RemoveBuffFromUnitTimedInit (unit, buffName, timerIndex, duration)
	AAE.timerTable[timerIndex] = { unit = unit, buffName=buffName }
	AAE.Utils.Timer.Register( RemoveBuffFromUnitTimed, duration, timerIndex )
end



--Has unit 'unit' one or more buffs of the type 'buffName'? 
--The third parameter is optional: If it isn't nil, the function checks, if the corresponding timer has an entry in the buff 'buffName' (use it for example when you want to know if the buff has been purged meanwhile).
--Note: The function doesn't return 1, if the corresponding timer has an entry; it returns the number of buffs of the given type (so check, if return value >=1, not ==1).
function GetBuffCountOnUnit (unit, buffName, timerIndex)
	--GameRules:SendCustomMessage ("Get unit: " .. tostring(unit) .. " buffName: " .. tostring(buffName) .. " timerIndex " .. tostring(timerIndex), 1, 1)
	if (timerIndex == nil) then
		if (AAE.buffsOnUnitTab[unit] == nil) then
			AAE.buffsOnUnitTab[unit] = {}
			AAE.buffsOnUnitTab[unit][buffName] = {}
			AAE.buffsOnUnitTab[unit][buffName].buffCount = 0
			AAE.buffsOnUnitTab[unit][buffName].buffInstInf = {}
			return 0
		else
			if (AAE.buffsOnUnitTab[unit][buffName] == nil) then
				AAE.buffsOnUnitTab[unit][buffName] = {}
				AAE.buffsOnUnitTab[unit][buffName].buffCount = 0
				AAE.buffsOnUnitTab[unit][buffName].buffInstInf = {}
				return 0
			else
				return AAE.buffsOnUnitTab[unit][buffName].buffCount
			end
		end
	else
		if (AAE.buffsOnUnitTab[unit][buffName].buffInstInf[timerIndex] == nil) then
			return 0
		else
			return AAE.buffsOnUnitTab[unit][buffName].buffCount
		end
	end
end



function UpdateMovementSpeed (unit)
	local speedFactor = 1.0
	
	for key, value in pairs(AAE.buffsOnUnitTab[unit]) do
		if (AAE.buffInfoTab[key].isMovementModifier == true) then
			if (AAE.buffInfoTab[key].isBuff == true) then
				local highestSpeedFactor = 1.0
				for key1, value1 in pairs(value.buffInstInf) do
					if (value1.speedFactor > highestSpeedFactor) then
						highestSpeedFactor = value1.speedFactor
					end
					--AAE:SendCustomMessage ("Key1 " .. tostring(key1) .. " Value1 " .. tostring(value1) .. " Value1SpeedFactor " .. tostring(value1.speedFactor), 1, 1)
				end
				speedFactor = speedFactor * highestSpeedFactor
			else
				local lowestSpeedFactor = 1.0
				for key1, value1 in pairs(value.buffInstInf) do
					if (value1.speedFactor < lowestSpeedFactor) then
						lowestSpeedFactor = value1.speedFactor
					end
				end
				speedFactor = speedFactor * lowestSpeedFactor
			end
		end
	end
	
	local baseMs = AAE.unitTypeInfo[unit:GetUnitName()].baseMs
	unit:SetBaseMoveSpeed(baseMs * speedFactor)
end



function RemoveDummyTimed ( timerIndex )
	local dummy = AAE.timerTable[timerIndex].dummy
	dummy:ForceKill(true)
	AAE.timerTable[timerIndex] = nil
end



function RemoveDummyTimedInit (dummy, duration)
	timerIndex = GetTimerIndex()
	AAE.timerTable[timerIndex] = { dummy = dummy }
	AAE.Utils.Timer.Register( RemoveDummyTimed, duration, timerIndex )
end



function IsMissileColliding (caster, missileLoc, radius)
	for key, value in pairs(AAE.allUnits) do
	
		local pickedUnit = EntIndexToHScript(key)
		local pickedUnitPos = pickedUnit:GetAbsOrigin()
		local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
		
		local vecDistUnitExplosion = pickedUnitPos - missileLoc
		local dX = vecDistUnitExplosion.x
		local dY = vecDistUnitExplosion.y
		
		if (pickedUnit ~= caster) then
			if (math.abs(dX) < radius+pickedUnitSize and math.abs(dY) < radius+pickedUnitSize) then
				if (dX*dX + dY*dY <= (radius+pickedUnitSize)*(radius+pickedUnitSize)) then
					return true, pickedUnit
				end
			end
		end
	end

	return false, nil
end



function DealDamageOverTime (timerIndex)
	local caster = AAE.timerTable[timerIndex].caster
	local target = AAE.timerTable[timerIndex].target
	local dmgInterval = AAE.timerTable[timerIndex].dmgInterval
	local dmgPerTick = AAE.timerTable[timerIndex].dmgPerTick
	local totalIntervalCount = AAE.timerTable[timerIndex].totalIntervalCount
	local curIntervalCount = AAE.timerTable[timerIndex].curIntervalCount + 1
	local buffName = AAE.timerTable[timerIndex].buffName
	AAE.timerTable[timerIndex].curIntervalCount = curIntervalCount
	
	if (GetBuffCountOnUnit (target, buffName, timerIndex) < 1) then
		AAE.timerTable[timerIndex] = nil
	else
		DealDamage (caster, target, dmgPerTick)
		if ( curIntervalCount >= totalIntervalCount) then
			DecreaseBuffCountOnUnit (target, buffName, timerIndex)
			AAE.timerTable[timerIndex] = nil
		else
			return dmgInterval
		end
	end
end



function DealDamageOverTimeInit (caster, target, dmgInterval, dmgPerTick, totalIntervalCount, buffName)
	local timerIndex = GetTimerIndex()
	IncreaseBuffCountOnUnit (target, buffName, timerIndex)
	AAE.timerTable[timerIndex] = { caster = caster, target = target, dmgInterval = dmgInterval, dmgPerTick = dmgPerTick, totalIntervalCount = totalIntervalCount, curIntervalCount = 0, buffName = buffName }
	AAE.Utils.Timer.Register( DealDamageOverTime, dmgInterval, timerIndex )
end



function DealDamage (attacker, target, damage)
	if (GetBuffCountOnUnit (target, "iceBlock") < 1) then
		StartCombatMode(target, attacker:GetOwner():GetPlayerID())
		local damageTable = { victim = target, attacker = attacker, damage = damage, damage_type = DAMAGE_TYPE_PURE }
		if (GetBuffCountOnUnit (attacker, "rune_doubleDamage") > 0) then
			damageTable.damage = damage*2
		end
		if (GetBuffCountOnUnit (target, "rune_invisibility") > 0) then
			RemoveBuffTypeFromUnit (target, "rune_invisibility")
		end
		if (GetBuffCountOnUnit (target, "rune_regeneration") > 0) then
			RemoveBuffTypeFromUnit (target, "rune_regeneration")
		end
		ApplyDamage(damageTable)
	end
end



function StartCombatMode (targetUnit, attackingPlayerId) --Check if this function or TimerUpdate runs first in a game frame.
	if (AAE.combatSystem[targetUnit] == nil) then
		AAE.combatSystem[targetUnit] = {}
		AAE.combatSystem[targetUnit][attackingPlayerId] = AAE._lastTime + 5.0
	else
		AAE.combatSystem[targetUnit][attackingPlayerId] = AAE._lastTime + 5.0
	end
end



function PlaySoundOnUnitInit(soundname, unit, soundDuration, loop)
	local timerIndex = GetTimerIndex()
	local unitLoc = unit:GetAbsOrigin()
	local unitOwner = unit:GetOwner()
	
	local soundDummy = CreateUnitByName("aae_dummy_loop_sounds", unitLoc, false, unitOwner, unitOwner, unit:GetTeamNumber())
	soundDummy:FindAbilityByName("aae_d_mage_fireball_explosion"):SetLevel(1)
	soundDummy:EmitSound(soundname)
	
	AAE.timerTable[timerIndex] = { soundname = soundname, unit = unit, soundDummy = soundDummy, soundDuration = soundDuration, loop = loop}
	AAE.Utils.Timer.Register( PlaySoundOnUnit, soundDuration, timerIndex )
	AAE.Utils.Timer.Register( PlaySoundOnUnitUpdateDummyPos, 0.199999999, timerIndex )
	
	return timerIndex
end



function PlaySoundOnUnitUpdateDummyPos (timerIndex)
	if (AAE.timerTable[timerIndex] ~= nil) then
		local soundname = AAE.timerTable[timerIndex].soundname
		local unit = AAE.timerTable[timerIndex].unit
		local soundDummy = AAE.timerTable[timerIndex].soundDummy
		local soundDuration = AAE.timerTable[timerIndex].soundDuration
		local loop = AAE.timerTable[timerIndex].loop
	
		soundDummy:SetAbsOrigin(unit:GetAbsOrigin())
	
		return 0.199999999
	end
end



function PlaySoundOnUnit(timerIndex)
	if (AAE.timerTable[timerIndex] ~= nil) then
		local soundname = AAE.timerTable[timerIndex].soundname
		local unit = AAE.timerTable[timerIndex].unit
		local soundDummy = AAE.timerTable[timerIndex].soundDummy
		local soundDuration = AAE.timerTable[timerIndex].soundDuration
		local loop = AAE.timerTable[timerIndex].loop
		
		if (loop == true) then
			soundDummy:StopSound(soundname)
			soundDummy:EmitSound(soundname)
			return soundDuration
		end
		
		soundDummy:StopSound(soundname)
		soundDummy:ForceKill(true)
		AAE.timerTable[timerIndex] = nil
	end
end



function StopSoundOnUnit(timerIndex)
	if (AAE.timerTable[timerIndex] ~= nil) then
		local soundname = AAE.timerTable[timerIndex].soundname
		local unit = AAE.timerTable[timerIndex].unit
		local soundDummy = AAE.timerTable[timerIndex].soundDummy
		local soundDuration = AAE.timerTable[timerIndex].soundDuration
		local loop = AAE.timerTable[timerIndex].loop
		
		soundDummy:StopSound(soundname)
		soundDummy:ForceKill(true)
		AAE.timerTable[timerIndex] = nil
	end
end



-- Respawn hero and call "RandomEnterArena()"
function RespawnHero(index)
	local unit = AAE.timerTable[index].unit
	unit:RespawnHero(false, true, true) --(1.Par = Respawn Sound, 2.Par = ?, 3.Par = ?)
	RandomEnterArena(unit)
	AAE.timerTable[index] = nil
end



--Find random spot of height 128 and move unit there
function RandomEnterArena(unit)
	local x = 0
	local y = 0
	local continueSearch = true

	while (continueSearch == true) do
		x = RandomInt(-3740, 3825)
		y = RandomInt(-3800, 3800)
		if ((GetGroundPosition(Vector(x, y, 0), nil)).z == 128) then
			continueSearch = false
		end
	end
	unit:SetAbsOrigin(Vector(x, y, 128))
	FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	AAE.allUnits[unit:GetEntityIndex()].lightProtTime = AAE._lastTime + 2.5
end



--Necessary for picking game mode; TODO: Try to substiture by using dialogs
function TelPlayerOne (index)
	local spawnedUnit = AAE.timerTable[index].spawnedUnit
	local point =  Entities:FindByName( nil, "SelectGameModeArea1" ):GetAbsOrigin()
	FindClearSpaceForUnit(spawnedUnit, point, false)
	spawnedUnit:Stop()
end



--Set player start gold
function SetStartGold ()
	for variable = 0, 9, 1 do
		PlayerResource:SetGold(variable, 600, false)
	end
end
