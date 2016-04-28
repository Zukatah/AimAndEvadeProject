--require( "utils.timer" )
--require( "utils.utils" )
--require( "addon_game_mode" )


-- When unit walks in bottom port region, it gets ported into the middle
function bottom_teleport_func( trigger )
    local point =  Entities:FindByName( nil, "bottom_teleport_ent" ):GetAbsOrigin()         -- Get the position of the "point_teleport_spot"-entity we put in our map
    FindClearSpaceForUnit(trigger.activator, point, false)                                  -- Find a spot for the hero around 'point' and teleports to it
    trigger.activator:Stop()                                                                -- Stop the hero, so he doesn't move
    SendToConsole("dota_camera_center")                                                     -- Refocus the camera of said player to the position of the teleported hero.
end


-- Shop region to teleport hero in arena
function EnterArena( trigger )
	RandomEnterArena(trigger.activator)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
	AAE.EnteredArena[trigger.activator:GetPlayerID()+1] = 1		                            -- ENTERED ARENA (DISABLE SHOP)
	UTIL_ResetMessageTextAll()
end


-- Select mode: teamfight or FFA
function SelectTeamfight( trigger )
    local point =  Entities:FindByName( nil, "SelectGameModeArea2" ):GetAbsOrigin()
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
	UTIL_MessageText(1, "\n\nPlease choose now: Left: Teamfight Deathmatch; Right: Teamfight Arena-Mode", 0, 0, 255, 1000)
end


-- FFA selected, port unit to shop area
function SelectFFA( trigger )
	AAE.GameType = 0
	GameRules:SendCustomMessage("Mode: FFA", 0, 1)
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end


-- Teamfight Deathmatch selected, port unit to shop area
function SelectTeamfightNormal( trigger )
    AAE.GameType = 1
	GameRules:SendCustomMessage("Mode: Teamfight Deathmatch", 0, 1)
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end


-- Teamfight arena mode selected, port unit to shop area
function SelectTeamfightLMS( trigger )
	AAE.GameType = 2
	GameRules:SendCustomMessage("Mode: Teamfight Arena-Mode", 0, 1)
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end


--Necessary for picking game mode; TODO: Try to substiture by using dialogs
function TelPlayerOne (index)
    local spawnedUnit = AAE.timerTable[index].spawnedUnit
    local point =  Entities:FindByName( nil, "SelectGameModeArea1" ):GetAbsOrigin()
    FindClearSpaceForUnit(spawnedUnit, point, false)
    spawnedUnit:Stop()
end


-- Teleport player 1 for setting Game Mode
function PortPlayer1ToSetGameMode (spawnedUnit)
    if (AAE.GameModeSelected == 0) then
        if (spawnedUnit:GetPlayerOwnerID() == 0 and spawnedUnit:IsHero()) then
            AAE.GameModeSelected = 1
            local timerId = GetTimerIndex()
            AAE.timerTable[timerId] = {spawnedUnit = spawnedUnit}
            AAE.Utils.Timer.Register( TelPlayerOne, 0.01, timerId )
        end
    end
end