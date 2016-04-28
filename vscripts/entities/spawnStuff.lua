
function SpawnDummies (spawnedUnit)
    for i=1,3,1 do
        local unit = CreateUnitByName("npc_dota_necronomicon_warrior_test", spawnedUnit:GetAbsOrigin(), true, spawnedUnit:GetOwner(), spawnedUnit:GetOwner(), spawnedUnit:GetTeamNumber())
        unit:FindAbilityByName("aae_m_mage_interceptorMissile"):SetLevel(1)
        unit:SetControllableByPlayer(spawnedUnit:GetOwner():GetPlayerID(), true)
        FindClearSpaceForUnit(unit, spawnedUnit:GetAbsOrigin(), true)
    end
end



function RegisterUnitAndLightningProtection (spawnedUnit)
    if (AAE.unitTypeInfo[spawnedUnit:GetUnitName()] == nil) then											                                    	-- Check if unittype is in table (unitTypeInfo)
        if (spawnedUnit:IsHero()) then																			                                	-- Check if unit is Hero
            AAE.unitTypeInfo[spawnedUnit:GetUnitName()] = { physics = true, collisionSize = 70, baseMs = spawnedUnit:GetBaseMoveSpeed() }
            AAE.allUnits[spawnedUnit] = { lightProtTime =  AAE.currentTime + 2.5 }										                    		--Physicsunit spawned
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_bloodseeker_thirst_speed", {})

            SpawnDummies(spawnedUnit)
        else
            GameRules:SendCustomMessage ("Error: Non-Hero-Unit entered the map but has no entry in 'unitTypeInfo'.", 1, 1)
        end
    else
        if (AAE.unitTypeInfo[spawnedUnit:GetUnitName()].physics == false) then							                                           	--Dummyunit spawned
        else
            if (spawnedUnit:IsHero()) then
                AAE.allUnits[spawnedUnit] = {lightProtTime =  AAE.currentTime + 2.5} 												               	--Physicsunit spawned
            else
                AAE.allUnits[spawnedUnit] = {lightProtTime =  0}
            end
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_bloodseeker_thirst_speed", {})
        end
    end
end