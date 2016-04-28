require( "utils.timer" )
require ("utils.utils")



function MoveLightnings()
    for key, value in pairs (AAE.lightningTab) do
        if (value.move ~= nil) then
            if (value.startRemDist <= value.startSpeed) then
                value.startX = value.startTargetX
                value.startY = value.startTargetY
                value.startTargetX = value.endTargetX + (math.random()*2-1)* 2000.0
                value.startTargetY = value.endTargetY + (math.random()*2-1)* 2000.0
                local tempVec = VectorInMapBounds(Vector(value.startTargetX, value.startTargetY, 128.0))
                value.startTargetX = tempVec.x
                value.startTargetY = tempVec.y
                value.startSpeed = (math.random()*300.0 + 100.0)/30.0
                value.startDeltaX = value.startTargetX - value.startX
                value.startDeltaY = value.startTargetY - value.startY
                value.startRemDist = math.sqrt(value.startDeltaX*value.startDeltaX + value.startDeltaY*value.startDeltaY)
                if (value.startRemDist == 0) then
                    value.startRemDist = 0.01
                end
                value.startDeltaX = value.startDeltaX / value.startRemDist
                value.startDeltaY = value.startDeltaY / value.startRemDist
            else
                value.startX = value.startX + value.startSpeed * value.startDeltaX
                value.startY = value.startY + value.startSpeed * value.startDeltaY
                value.startRemDist = value.startRemDist - value.startSpeed
            end
            if (value.endRemDist <= value.endSpeed) then
                value.endX = value.endTargetX
                value.endY = value.endTargetY
                value.endTargetX = value.startTargetX + (math.random()*2-1)* 2000.0
                value.endTargetY = value.startTargetY + (math.random()*2-1)* 2000.0
                local tempVec = VectorInMapBounds(Vector(value.endTargetX, value.endTargetY, 128.0))
                value.endTargetX = tempVec.x
                value.endTargetY = tempVec.y
                value.endSpeed = (math.random()*300.0 + 100.0)/30.0
                value.endDeltaX = value.endTargetX - value.endX
                value.endDeltaY = value.endTargetY - value.endY
                value.endRemDist = math.sqrt(value.endDeltaX*value.endDeltaX + value.endDeltaY*value.endDeltaY)
                if (value.endRemDist == 0) then
                    value.endRemDist = 0.01
                end
                value.endDeltaX = value.endDeltaX / value.endRemDist
                value.endDeltaY = value.endDeltaY / value.endRemDist
            else
                value.endX = value.endX + value.endSpeed * value.endDeltaX
                value.endY = value.endY + value.endSpeed * value.endDeltaY
                value.endRemDist = value.endRemDist - value.endSpeed
            end
            value.normX = value.endX - value.startX
            value.normY = value.endY - value.startY
            local dist = math.sqrt(value.normX*value.normX + value.normY*value.normY)
            if (dist == 0) then
                value.normX = 1.0
                value.normY = 0.0
            else
                value.normX = value.normX/dist
                value.normY = value.normY/dist
            end

            value.lightDummy:SetAbsOrigin(Vector(value.startX, value.startY, 150.0))
            ParticleManager:SetParticleControl(value.lightParticle, 1, Vector(value.endX, value.endY, 150.0))

            for arcSpark, arcSparkProps in pairs(AAE.arcSparkGroup) do
                local pickedUnitLoc = arcSpark:GetAbsOrigin()
                local uX = pickedUnitLoc.x
                local uY = pickedUnitLoc.y
                local oldVal = arcSparkProps[key]

                if ((-value.normY*uX + value.normX*uY >= -value.normY*value.startX + value.normX*value.startY) ~= oldVal) then
                    local sparkParOnLightLine = value.normX*uX + value.normY*uY
                    local lightStartParOnLightLine = value.normX*value.startX + value.normY*value.startY
                    local lightEndParOnLightLine = value.normX*value.endX + value.normY*value.endY

                    if (sparkParOnLightLine >= lightStartParOnLightLine and sparkParOnLightLine <= lightEndParOnLightLine or sparkParOnLightLine <= lightStartParOnLightLine and sparkParOnLightLine >= lightEndParOnLightLine) then
                        local distSparkLight = ((((-value.normX/value.normY) * (value.startY - uY) ) + (value.startX - uX)) / (((-value.normX * value.normX) / value.normY) - value.normY))
                        arcSpark:SetAbsOrigin(VectorInMapBounds(arcSpark:GetAbsOrigin() + distSparkLight * 1.1 * Vector(-value.normY, value.normX, 0)))
                    else
                        arcSparkProps[key] = not oldVal
                    end
                end

            end
        end
    end

    return 0.01
end



function UpdateLightnings()
    local filterPassedGroup
    local minX, maxX, minY, maxY
    AAE.gameInterval = AAE.gameInterval + 1

    for i=1, 6, 1 do
        filterPassedGroup = { }
        for pickedUnit, _ in pairs (AAE.allUnits) do
            --local pickedUnit = EntIndexToHScript(key)
            local pickedUnitLoc = pickedUnit:GetAbsOrigin()
            local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize

            if AAE.lightningTab[i].startX < AAE.lightningTab[i].endX then
                minX = AAE.lightningTab[i].startX
                maxX = AAE.lightningTab[i].endX
            else
                minX = AAE.lightningTab[i].endX
                maxX = AAE.lightningTab[i].startX
            end


            if AAE.lightningTab[i].startY < AAE.lightningTab[i].endY then
                minY = AAE.lightningTab[i].startY
                maxY = AAE.lightningTab[i].endY
            else
                minY = AAE.lightningTab[i].endY
                maxY = AAE.lightningTab[i].startY
            end


            if pickedUnitLoc.x + 145.0 + pickedUnitSize > minX then
                if pickedUnitLoc.x - 145.0 - pickedUnitSize < maxX then
                    if pickedUnitLoc.y + 145.0 + pickedUnitSize > minY then
                        if pickedUnitLoc.y - 145.0 - pickedUnitSize < maxY then
                            if (AAE.allUnits[pickedUnit].lightProtTime < AAE.currentTime) then
                                filterPassedGroup[pickedUnit] = true
                            end
                        end
                    end
                end
            end
        end

        for pickedUnit, _ in pairs (filterPassedGroup) do
            local pickedUnitLoc = pickedUnit:GetAbsOrigin()
            local pickedUnitSize = AAE.unitTypeInfo[pickedUnit:GetUnitName()].collisionSize
            local locX = pickedUnitLoc.x																-- x Location from pickedUnit
            local locY = pickedUnitLoc.y																-- y Location from pickedUnit
            --local distanceUnitLightning = 0.0															-- Distance from unit to Lightning
            local flashingArcLength = pickedUnitSize + 145.0											-- Maximum length of lightning striking unit
            local distancePar
            if (AAE.lightningTab[i].normY ~= 0.0) then
                distancePar = ((((-AAE.lightningTab[i].normX / AAE.lightningTab[i].normY) * (AAE.lightningTab[i].startY - locY)) + (AAE.lightningTab[i].startX - locX)) / (((-AAE.lightningTab[i].normX * AAE.lightningTab[i].normX) / AAE.lightningTab[i].normY) - AAE.lightningTab[i].normY))
            else
                if (AAE.lightningTab[i].normX > 0.0) then
                    distancePar = AAE.lightningTab[i].startY - locY




                else
                    distancePar = locY - AAE.lightningTab[i].startY
                end
            end

            -- minimum distance between lightning and unit
            local facLightDmg = math.abs(distancePar) / flashingArcLength
            if (facLightDmg < 1.0) then
                local closestPointOnLightX = locX - distancePar * AAE.lightningTab[i].normY
                local closestPointOnLightY = locY + distancePar * AAE.lightningTab[i].normX

                local lightningPar
                if (AAE.lightningTab[i].normY ~= 0.0) then
                    lightningPar = (closestPointOnLightY - AAE.lightningTab[i].startY) / AAE.lightningTab[i].normY				-- Lightning vector parameter
                else
                    lightningPar = (closestPointOnLightX - AAE.lightningTab[i].startX) / AAE.lightningTab[i].normX
                end

                local lightningLength = math.sqrt((AAE.lightningTab[i].startX - AAE.lightningTab[i].endX) * (AAE.lightningTab[i].startX - AAE.lightningTab[i].endX) + (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY) * (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY) + (AAE.lightningTab[i].startY - AAE.lightningTab[i].endY))	-- Lightning length
                local particlePointX
                local particlePointY

                if (lightningPar <= lightningLength and lightningPar >= 0) then
                    particlePointX = (closestPointOnLightX + locX) / 2.0
                    particlePointY = (closestPointOnLightY + locY) / 2.0
                else
                    if (lightningPar <= lightningLength + flashingArcLength and lightningPar > lightningLength) then
                        particlePointX = (AAE.lightningTab[i].endX + locX) / 2.0
                        particlePointY = (AAE.lightningTab[i].endY + locY) / 2.0
                    else
                        if (lightningPar >= -flashingArcLength and lightningPar < 0) then
                            particlePointX = (AAE.lightningTab[i].startX + locX) / 2.0
                            particlePointY = (AAE.lightningTab[i].startY + locY) / 2.0
                        end
                    end
                end

                if (AAE.gameInterval % 3 == 0) then
                    local unit = CreateUnitByName("aae_dummy_lightning_touch_1", Vector(particlePointX, particlePointY, 128), true, pickedUnit:GetOwner(), pickedUnit:GetOwner(), pickedUnit:GetTeamNumber())
                    unit:FindAbilityByName("aae_d_lightning_touch"):SetLevel(1)
                    RemoveDummyTimedInit(unit, 0.1)
                end

                DealDamage (pickedUnit, pickedUnit, 5*(1.0-facLightDmg)) -- facLightDmg between 0-1 5*
            end
        end
    end
    return 0.01
end


-- Create lightnings and set height to 150 after creation (can't do while creation)
function CreateLightnings ()
    for key, value in pairs (AAE.lightningTab) do
        value.lightDummy = CreateUnitByName("npc_dota_lightning", Vector(value.startX, value.startY, 128), false, PlayerResource:GetPlayer(0), PlayerResource:GetPlayer(0), 0)
        value.lightDummy:FindAbilityByName("lightning_spell_settings"):SetLevel(1)
        value.lightDummy:SetAbsOrigin(Vector(value.lightDummy:GetAbsOrigin().x, value.lightDummy:GetAbsOrigin().y, 150))
        value.lightParticle = ParticleManager:CreateParticle("particles/maplightnings/move/wisp_tether_map_move.vpcf", PATTACH_ABSORIGIN_FOLLOW, value.lightDummy)
        ParticleManager:SetParticleControl(value.lightParticle, 1, Vector(value.endX, value.endY, 150.0))
    end
end