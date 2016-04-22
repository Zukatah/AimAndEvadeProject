require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



frostring_collisionSize = 60.0



function FrostringUpdate (index)
	local caster = AAE.timerTable[index].caster
	local castLoc = AAE.timerTable[index].castLoc
	local castLocX = castLoc.x
	local castLocY = castLoc.y
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local casterOwner = caster:GetOwner()
	local missileGroup = AAE.timerTable[index].missileGroup
	
	AAE.timerTable[index].intervalCount = intervalCount
	
	for i=1, 16, 1 do --Move all missiles
		local missile = missileGroup[i].missileDummy
		local missileDelta = Vector(missileGroup[i].dX, missileGroup[i].dY, 0.0)
		local missilePos = missile:GetAbsOrigin()
		local newMissilePos = VectorInMapBounds (missilePos + 20.0 * missileDelta)
		missile:SetAbsOrigin(newMissilePos)
	end
	
	for i=17, 32, 1 do --Move all missiles
		local missile = missileGroup[i].missileDummy
		local missileDelta = Vector(missileGroup[i].dX, missileGroup[i].dY, 0.0)
		local missilePos = missile:GetAbsOrigin()
		local newMissilePos = VectorInMapBounds (missilePos + 20.0 * missileDelta)
		missile:SetAbsOrigin(newMissilePos)
	end
	
	for key, value in pairs (AAE.allUnits) do --Check inner and outer circle for collisions with units
		local pickedUnit = EntIndexToHScript(key)
		local unitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize + frostring_collisionSize
		local unitPos = pickedUnit:GetAbsOrigin()
		local posX = unitPos.x
		local posY = unitPos.y
		local upperLimit = 20.0 * intervalCount + unitSize
		local lowerLimit = 20.0 * intervalCount - unitSize
		if (lowerLimit < 0.0) then
			lowerLimit = 0.0
		end
		
		if (pickedUnit ~= caster) then
			local sqDistCastToUnit = (posX-castLocX) * (posX-castLocX) + (posY-castLocY) * (posY-castLocY)
			if (sqDistCastToUnit <= upperLimit * upperLimit and sqDistCastToUnit >= lowerLimit * lowerLimit) then
				DealDamage (caster, pickedUnit, 8.0)
				local timerIndex = GetTimerIndex()
				IncreaseBuffCountOnUnit (pickedUnit, "frostring_Slow", timerIndex, 0.5)
				RemoveBuffFromUnitTimedInit (pickedUnit, "frostring_Slow", timerIndex, 5.0)
			end
		end
	end
	if (intervalCount < 30) then
		return 0.01
	end
	
	for i=1, 16, 1 do --Move all missiles
		local missile = missileGroup[i].missileDummy
		RemoveDummyTimedInit(missile, 0.3)
	end
	
	for i=17, 32, 1 do --Move all missiles
		local missile = missileGroup[i].missileDummy
		RemoveDummyTimedInit(missile, 0.3)
	end
	
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local missileGroup = {}
	local casterLoc = caster:GetAbsOrigin()
	local intervalCount = 0
	local timerIndex = GetTimerIndex()
	
	for i=1, 16, 1 do
		missileDummy = CreateUnitByName("aae_dummy_mage_frostring", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_frostring"):SetLevel(1)
		missileGroup[i] = { missileDummy = missileDummy, dX = math.cos(i * math.pi / 8.00), dY = math.sin(i * math.pi / 8.00) }
	end
	
	for i=17, 32, 1 do
		missileDummy = CreateUnitByName("aae_dummy_mage_frostring_1", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_frostring_1"):SetLevel(1)
		missileGroup[i] = { missileDummy = missileDummy, dX = math.cos(i * math.pi / 8.00), dY = math.sin(i * math.pi / 8.00) }
	end
	
	AAE.timerTable[timerIndex] = { caster = caster, missileGroup = missileGroup, castLoc = casterLoc, intervalCount = intervalCount }
	
	AAE.Utils.Timer.Register( FrostringUpdate, 0.01, timerIndex )
end
