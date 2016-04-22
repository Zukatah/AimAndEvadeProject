
function bottom_teleport_func( trigger )
	--GameRules:SendCustomMessage("Teleport-Spot", 0, 1)

    local point =  Entities:FindByName( nil, "bottom_teleport_ent" ):GetAbsOrigin()         -- Get the position of the "point_teleport_spot"-entity we put in our map
    FindClearSpaceForUnit(trigger.activator, point, false)                                  -- Find a spot for the hero around 'point' and teleports to it
    trigger.activator:Stop()                                                                -- Stop the hero, so he doesn't move
    SendToConsole("dota_camera_center")                                                     -- Refocus the camera of said player to the position of the teleported hero.
end



function enter_teleport_func( trigger )
	GameRules:SendCustomMessage("Game started!", 0, 1)
	-- Get the position of the "point_teleport_spot"-entity we put in our map
    ----local point =  Entities:FindByName( nil, "enterarena" ):GetAbsOrigin()
    -- Find a spot for the hero around 'point' and teleports to it
    ----FindClearSpaceForUnit(trigger.activator, point, false)
	AAE:RandomEnterArena(trigger.activator)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
	AAE.EnteredArena[trigger.activator:GetPlayerID()+1] = 1		-- ENTERED ARENA (DISABLE SHOP)
	UTIL_ResetMessageTextAll()
end



function SelectTeamfight( trigger )
	--GameRules:SendCustomMessage("Teleport-Spot", 0, 1)
	-- Get the position of the "point_teleport_spot"-entity we put in our map
    local point =  Entities:FindByName( nil, "SelectGameModeArea2" ):GetAbsOrigin()
    -- Find a spot for the hero around 'point' and teleports to it
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
	UTIL_MessageText(1, "\n\nPlease choose now: Left: Teamfight Deathmatch; Right: Teamfight Arena-Mode", 0, 0, 255, 1000)
end



function SelectFFA( trigger )
	AAE.GameType = 0
	GameRules:SendCustomMessage("Mode: FFA", 0, 1)
	--GameRules:SendCustomMessage("Teleport-Spot", 0, 1)
	-- Get the position of the "point_teleport_spot"-entity we put in our map
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    -- Find a spot for the hero around 'point' and teleports to it
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end



function SelectTeamfightNormal( trigger )
		AAE.GameType = 1
	GameRules:SendCustomMessage("Mode: Teamfight Deathmatch", 0, 1)
	--GameRules:SendCustomMessage("Teleport-Spot", 0, 1)
	-- Get the position of the "point_teleport_spot"-entity we put in our map
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    -- Find a spot for the hero around 'point' and teleports to it
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end



function SelectTeamfightLMS( trigger )
	AAE.GameType = 2
	GameRules:SendCustomMessage("Mode: Teamfight Arena-Mode", 0, 1)
	--GameRules:SendCustomMessage("Teleport-Spot", 0, 1)
	-- Get the position of the "point_teleport_spot"-entity we put in our map
    local point =  Entities:FindByName( nil, "portAfterSetMode" ):GetAbsOrigin()
    -- Find a spot for the hero around 'point' and teleports to it
    FindClearSpaceForUnit(trigger.activator, point, false)
    trigger.activator:Stop()
    SendToConsole("dota_camera_center")
end

