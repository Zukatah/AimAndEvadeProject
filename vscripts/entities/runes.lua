require( "utils.timer" )
require ("utils.utils")



--called every 1s, creates runes--
function SpawnRunes()
    local player = PlayerResource:GetPlayer(0) --I need any player for being the owner of the runes. TODO: Is there some sort of neutral player to avoid using the "first" player?
    local randPos
    local runeUnit

    --Spawn haste rune
    if (math.random() <= 0.02) then
        randPos = GetRandomPosition()
        runeUnit = CreateUnitByName("aae_dummy_rune_haste", randPos, false, player, player, 0)
        runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
        AAE.runes[runeUnit] = { runePos = randPos, runeType = 0 }
    end

    --Spawn double damage rune
    if (math.random() <= 0.02) then
        randPos = GetRandomPosition()
        runeUnit = CreateUnitByName("aae_dummy_rune_doubleDamage", randPos, false, player, player, 0)
        runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
        AAE.runes[runeUnit] = { runePos = randPos, runeType = 1 }
    end

    --Spawn double damage rune
    if (math.random() <= 0.02) then
        randPos = GetRandomPosition()
        runeUnit = CreateUnitByName("aae_dummy_rune_portkey", randPos, false, player, player, 0)
        runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
        AAE.runes[runeUnit] = { runePos = randPos, runeType = 2 }
    end

    --Spawn invisibility rune
    if (math.random() <= 0.02) then
        randPos = GetRandomPosition()
        runeUnit = CreateUnitByName("aae_dummy_rune_invisibility", randPos, false, player, player, 0)
        runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
        AAE.runes[runeUnit] = { runePos = randPos, runeType = 3 }
    end

    --Spawn invisibility rune
    if (math.random() <= 0.02) then
        randPos = GetRandomPosition()
        runeUnit = CreateUnitByName("aae_dummy_rune_regeneration", randPos, false, player, player, 0)
        runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
        AAE.runes[runeUnit] = { runePos = randPos, runeType = 4 }
    end

    return 0.999999999
end



--regeneration rune effect--
function Rune_Regeneration(timerIndex)
    local target = AAE.timerTable[timerIndex].target

    if (GetBuffCountOnUnit (target, "rune_regeneration", timerIndex) >= 1) then
        target:ModifyHealth(target:GetHealth()+10, nil, false, 0)
        target:SetMana(target:GetMana()+10)
        return 0.99999
    end

    AAE.timerTable[timerIndex] = nil
end



--checks 30 times per second for each rune, if unit is close to pick it up--
function RunePickup()
    local collision
    local removeTable = {}
    local player = PlayerResource:GetPlayer(0) --I need any player for being the owner of the runes. TODO: Is there some sort of neutral player to avoid using the "first" player?

    for runeUnit, runeInfoTable in pairs (AAE.runes) do
        collision = false

        for pickedUnit, _ in pairs (AAE.allUnits) do
            --local pickedUnit = EntIndexToHScript(physicUnit)
            local pickedUnitLoc = pickedUnit:GetAbsOrigin()
            local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize

            local runeX = runeInfoTable.runePos.x
            local runeY = runeInfoTable.runePos.y

            if pickedUnitLoc.x + 50.0 + pickedUnitSize > runeX then
                if pickedUnitLoc.x - 50.0 - pickedUnitSize < runeX then
                    if pickedUnitLoc.y + 50.0 + pickedUnitSize > runeY then
                        if pickedUnitLoc.y - 50.0 - pickedUnitSize < runeY then
                            if (pickedUnit:GetUnitName() ~= "aae_dummy_mage_interceptorMissile_missile") then
                                runeUnit:ForceKill(true)
                                collision = true

                                if (runeInfoTable.runeType == 0) then
                                    local timerIndex = GetTimerIndex()
                                    IncreaseBuffCountOnUnit (pickedUnit, "rune_haste", timerIndex, 1.5)
                                    RemoveBuffFromUnitTimedInit (pickedUnit, "rune_haste", timerIndex, 10.0)
                                else
                                    if (runeInfoTable.runeType == 1) then
                                        local timerIndex = GetTimerIndex()
                                        IncreaseBuffCountOnUnit (pickedUnit, "rune_doubleDamage", timerIndex)
                                        RemoveBuffFromUnitTimedInit (pickedUnit, "rune_doubleDamage", timerIndex, 10.0)
                                    else
                                        if (runeInfoTable.runeType == 2) then
                                            local randPos = GetRandomPosition()

                                            FindClearSpaceForUnit(pickedUnit, randPos, true)

                                            local targetDummy = CreateUnitByName("aae_dummy_rune_portkey_target", randPos, false, player, player, 0)
                                            targetDummy:FindAbilityByName("aae_d_mage_fireball_explosion"):SetLevel(1)
                                            RemoveDummyTimedInit (targetDummy, 3.0)
                                        else
                                            if (runeInfoTable.runeType == 3) then
                                                local timerIndex = GetTimerIndex()
                                                IncreaseBuffCountOnUnit (pickedUnit, "rune_invisibility", timerIndex)
                                                RemoveBuffFromUnitTimedInit (pickedUnit, "rune_invisibility", timerIndex, 10.0)
                                            else
                                                if (runeInfoTable.runeType == 4) then
                                                    pickedUnit:ModifyHealth(pickedUnit:GetHealth()+30, nil, false, 0)
                                                    pickedUnit:SetMana(pickedUnit:GetMana()+30)

                                                    local timerIndex = GetTimerIndex()
                                                    AAE.timerTable[timerIndex] = { target = pickedUnit }
                                                    IncreaseBuffCountOnUnit (pickedUnit, "rune_regeneration", timerIndex)
                                                    AAE.Utils.Timer.Register( Rune_Regeneration, 0.99999, timerIndex )
                                                else
                                                end
                                            end
                                        end
                                    end
                                end

                                break
                            end
                        end
                    end
                end
            end
        end

        if (collision == true) then
            removeTable[runeUnit] = true
        end
    end

    for key, value in pairs (removeTable) do
        AAE.runes[key] = nil
    end

    return 0.01
end