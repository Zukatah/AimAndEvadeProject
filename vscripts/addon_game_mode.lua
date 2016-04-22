
if AAE == nil then
	_G.AAE = class({})
end



require( "utils.timer" )
require ("utils.utils")
require ("utils.messagesAndInfos")
require ("utils.chooseMode")
require ("entities.learnAbilities")
require ("entities.runes")
require ("entities.lightnings")





function Precache( context )
		--Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "model", "models/courier/gold_mega_greevil/gold_mega_greevil.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )

			PrecacheUnitByNameSync('npc_dota_hero_zuus', context)
			PrecacheUnitByNameSync('npc_dota_hero_bristleback', context)
			PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)
			PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bristleback.vsndevts", context)
			
			PrecacheResource( "particle", "particles/econ/items/lina/lina_head_headflame/lina_flame_hand_headflame.vpcf", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_clinkz/clinkz_strafe_flare.vpcf", context )
			
			PrecacheResource( "particle", "particles/fireball/axe_vanguard_passive.vpcf", context )
			PrecacheResource( "particle", "particles/fireball/explosion.vpcf", context )
			
			PrecacheResource( "particle", "particles/mcbomb/explosion.vpcf", context )
			PrecacheResource( "particle", "particles/mcbomb/explosion_1.vpcf", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_lina/lina_spell_dragon_slave_fire_smoke.vpcf", context )
			
			--ForceStaff test
			PrecacheResource( "particle", "particles/items_fx/force_staff.vpcf", context )
			
			--Forcestaff
			PrecacheResource( "particle", "particles/items_fx/force_staff.vpcf", context )
			
			-- Lightnings
			PrecacheResource( "particle", "particles/units/heroes/hero_wisp/wisp_tether.vpcf", context )
			PrecacheResource( "particle", "particles/forcestaff/wisp_tether.vpcf", context )
			PrecacheResource( "particle", "particles/lightning/stormspirit_electric_vortex_owner_1.vpcf", context )
			
			PrecacheResource( "particle", "particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", context )
			PrecacheResource( "particle", "particles/try/zuus_arc_lightning.vpcf", context )
			PrecacheResource( "particle", "particles/basic_rope/basic_rope.vpcf", context )
			
			-- Pyroblast
			PrecacheResource( "particle", "particles/pyroblast/pyro_missile.vpcf", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf", context )
			PrecacheResource( "particle", "particles/pyroblast/phoenix_fire_spirit_burn.vpcf", context )
			PrecacheResource( "particle", "particles/pyroblast/explosion_1.vpcf", context )
			
			-- FrostFork
			PrecacheResource( "particle", "particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf", context )
			
			PrecacheResource( "particle", "particles/arcingspark/stormspirit_ball_lightning_sphere_new.vpcf", context )
			
			--Frostring
			PrecacheResource( "particle", "particles/items2_fx/shivas_guard_active.vpcf", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf", context )
			
			-- Magic Lasso
			PrecacheResource( "particle", "particles/magiclasso/wisp_tether_lasso.vpcf", context )
			
			-- map lightnings
			PrecacheResource( "particle", "particles/maplightnings/wisp_tether_map.vpcf", context )
			PrecacheResource( "particle", "particles/maplightnings/move/wisp_tether_map_move.vpcf", context )
			
			-- Interceptor Missile
			PrecacheResource( "particle", "particles/interceptormissile/wisp_tether.vpcf", context )
end



function Activate()
    GameRules.AAE = AAE()
    GameRules.AAE:InitGameMode()
end



function AAE:InitGameMode()
	local GameMode = GameRules:GetGameModeEntity()
	AAE.GameModeSelected = 0
	AAE.gameInterval = 0 --Count to avoid showing lightning effects 30 time per second.
	
	AAE.allUnits = {} --Currently the only table, that uses entity indices as key.
	AAE.timerTable = {} --Save information attached to any timer in the corresponding entry in this table.
	AAE.channelInformation = {} --TODO: Is this table really necessary? Is there a better way to handle channeled spells?
	
	AAE.buffsOnUnitTab = {}
	AAE.modsInBuffTab = {}
	AAE.modTypeTab = {} --true = built-in, false = self-written
	AAE.buffInfoTab = {}--isBuff (true if treated as buff, false if treated as debuff), isMovementModifier (true if buff has an attribute, that determines the movement speed factor)
	
	AAE.unitTypeInfo = {}
	AAE.combatSystem = {}
	AAE.lightningTab = {}
	
	AAE.arcSparkGroup = {}
	
	AAE.runes = {}
	
	AAE.MIN_X = -3850.0
	AAE.MIN_Y = -3850.0
	AAE.MAX_X = 3850.0
	AAE.MAX_Y = 3850.0
	AAE.LIGHTNING_LENGTH = AAE.MAX_X - AAE.MIN_X

	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetGoldPerTick( 0 )
	GameRules:SetHeroSelectionTime( 0.0 )
	GameRules:SetPreGameTime( 5.0 )
	GameRules:SetTreeRegrowTime( 60 )
	GameRules:SetSameHeroSelectionEnabled(true) 
	GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
	
	GameMode:SetTowerBackdoorProtectionEnabled( false )
	GameMode:SetRecommendedItemsDisabled( true )
	GameMode:SetTopBarTeamValuesVisible( false )
	
	--GameMode:SetCameraDistanceOverride( 1500 )
	
	--Initialize information about unit types (is unit type affected by physics or a dummy/particle effect unit type? What is its collision size (important for collision finding functions)? What is its base movement speed?).
	AAE.unitTypeInfo["aae_dummy_mage_mcBomb_missile"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_mcBomb_explosion"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_mcBomb_explosion_1"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_fireball_missile"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_fireball_explosion"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_deadlyRange_missile"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_pyroblast_missile"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_pyroblast_missile_1"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_pyroblast_cast"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_forcestaff"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_frostFork"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_lightning_touch_1"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_arcingSpark"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_frostring"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_frostring_1"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_magicLasso"] = { physics = false, collisionSize = 50, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_mage_interceptorMissile_missile"] = { physics = true, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["npc_dota_necronomicon_warrior_test"] = { physics = true, collisionSize = 50, baseMs=522 }
	AAE.unitTypeInfo["npc_dota_lightning"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_rune_gnome"] = { physics = true, collisionSize = 50, baseMs=522 }
	AAE.unitTypeInfo["aae_dummy_rune_haste"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_rune_doubleDamage"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_rune_portkey"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_rune_portkey_target"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_rune_invisibility"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_rune_regeneration"] = { physics = false, collisionSize = 0, baseMs=0 }
	AAE.unitTypeInfo["aae_dummy_loop_sounds"] = { physics = false, collisionSize = 0, baseMs=0 }
	
	-- InBuffTable initialization
	AAE.modsInBuffTab["knockback"] = { "modifier_rooted" }
	AAE.modsInBuffTab["deadlyRange_Dot"] = { "DeadlyRange_Dot" }
	AAE.modsInBuffTab["frostFork_Slow"] = { "FrostFork_SlowEffect" }
	AAE.modsInBuffTab["frostring_Slow"] = { "Frostring_SlowEffect" }
	AAE.modsInBuffTab["magicLasso"] = { "MagicLasso_Hook", "modifier_rooted" }
	AAE.modsInBuffTab["interceptorMissile"] = { "InterceptorMissile_Symbol", "modifier_rooted" }
	AAE.modsInBuffTab["iceBlock"] = { "IceBlock_Symbol" }
	AAE.modsInBuffTab["snowball"] = { "Snowball_Symbol", "modifier_rooted" }
	AAE.modsInBuffTab["snowball_Slow"] = { "Snowball_SlowEffect" }
	AAE.modsInBuffTab["rune_haste"] = { "Rune_Haste" }
	AAE.modsInBuffTab["rune_doubleDamage"] = { "Rune_DoubleDamage" }
	AAE.modsInBuffTab["rune_invisibility"] = { "modifier_invisible" }
	AAE.modsInBuffTab["rune_regeneration"] = { "Rune_Regeneration" }
	AAE.modsInBuffTab["iceAge_Slow"] = { "IceAge_SlowEffect" }
	
	-- BuffInfoTable initialization
	AAE.buffInfoTab["knockback"] = { isBuff = false, isMovementModifier = false }
	AAE.buffInfoTab["deadlyRange_Dot"] = { isBuff = false, isMovementModifier = false }
	AAE.buffInfoTab["frostFork_Slow"] = { isBuff = false, isMovementModifier = true }
	AAE.buffInfoTab["frostring_Slow"] = { isBuff = false, isMovementModifier = true }
	AAE.buffInfoTab["magicLasso"] = { isBuff = false, isMovementModifier = false }
	AAE.buffInfoTab["interceptorMissile"] = { isBuff = true, isMovementModifier = false }
	AAE.buffInfoTab["iceBlock"] = { isBuff = true, isMovementModifier = false }
	AAE.buffInfoTab["snowball"] = { isBuff = false, isMovementModifier = false }
	AAE.buffInfoTab["snowball_Slow"] = { isBuff = false, isMovementModifier = true }
	AAE.buffInfoTab["rune_haste"] = { isBuff = true, isMovementModifier = true }
	AAE.buffInfoTab["rune_doubleDamage"] = { isBuff = true, isMovementModifier = false }
	AAE.buffInfoTab["rune_invisibility"] = { isBuff = true, isMovementModifier = false }
	AAE.buffInfoTab["rune_regeneration"] = { isBuff = true, isMovementModifier = false }
	AAE.buffInfoTab["iceAge_Slow"] = { isBuff = false, isMovementModifier = true }
	
	-- modTypeTable initialization
	AAE.modTypeTab["modifier_rooted"] = true --true = built-in, false = self-written
	AAE.modTypeTab["DeadlyRange_Dot"] = false
	AAE.modTypeTab["FrostFork_SlowEffect"] = false
	AAE.modTypeTab["Frostring_SlowEffect"] = false
	AAE.modTypeTab["MagicLasso_Hook"] = false
	AAE.modTypeTab["InterceptorMissile_Symbol"] = false
	AAE.modTypeTab["IceBlock_Symbol"] = false
	AAE.modTypeTab["Snowball_Symbol"] = false
	AAE.modTypeTab["Snowball_SlowEffect"] = false
	AAE.modTypeTab["Rune_Haste"] = false
	AAE.modTypeTab["Rune_DoubleDamage"] = false
	AAE.modTypeTab["modifier_invisible"] = true
	AAE.modTypeTab["Rune_Regeneration"] = false
	AAE.modTypeTab["IceAge_SlowEffect"] = false
	
	-- lightningTable initialization
	AAE.lightningTab[1] = { startX = AAE.MIN_X, startY = AAE.MAX_Y, endX = AAE.MAX_X, endY = AAE.MAX_Y, normX = 1, normY = 0 } -- TOP
	AAE.lightningTab[2] = { startX = AAE.MAX_X, startY = AAE.MAX_Y, endX = AAE.MAX_X, endY = AAE.MIN_Y, normX = 0, normY = -1 } -- RIGHT
	AAE.lightningTab[3] = { startX = AAE.MAX_X, startY = AAE.MIN_Y, endX = AAE.MIN_X, endY = AAE.MIN_Y, normX = -1, normY = 0 } -- BOTTOM
	AAE.lightningTab[4] = { startX = AAE.MIN_X, startY = AAE.MIN_Y, endX = AAE.MIN_X, endY = AAE.MAX_Y, normX = 0, normY = 1 } -- LEFT
	AAE.lightningTab[5] = { startX = -2800.0, startY = -2800.0, startTargetX = -2800., startTargetY = -2800.0, startDeltaX = 1.0, startDeltaY = 0.0, startRemDist = 0.0, startSpeed = 1.0, endX = -1800.0, endY = -1800.0, endTargetX = -1800.0, endTargetY = -1800.0, endDeltaX = 1.0, endDeltaY = 0.0, endRemDist = 0.0, endSpeed = 1.0, normX = math.sqrt(2)/2, normY = math.sqrt(2)/2, move = true, lightDummy = nil, lightParticle = nil } -- MOVING
	AAE.lightningTab[6] = { startX =  1800.0, startY =  1800.0, startTargetX = 1800.0, startTargetY = 1800.0, startDeltaX = 1.0, startDeltaY = 0.0, startRemDist = 0.0, startSpeed = 1.0, endX =  2800.0, endY =  2800.0, endTargetX = 2800.0, endTargetY = 2800.0, endDeltaX = 1.0, endDeltaY = 0.0, endRemDist = 0.0, endSpeed = 1.0, normX = math.sqrt(2)/2, normY = math.sqrt(2)/2, move = true, lightDummy = nil, lightParticle = nil } -- MOVING

	--initialization of streak table
	AAE.streakTable = {[3]="#Streak_KillingSpree", [4]="#Streak_Dominating", [5]="#Streak_MegaKill", [6]="#Streak_Unstoppable", [7]="#Streak_WickedSick", [8]="#Streak_MonsterKill", [9]="#Streak_Godlike", [10]="#Streak_BeyondGodlike"}
	AAE.multikillTable = {[2]="#Kill_DoubleKill", [3]="#Kill_TripleKill", [4]="#Kill_UltraKill", [5]="#Kill_Rampage"}

	-- Hook into game events
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( AAE, "OnEntityKilled" ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( AAE, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_item_purchased", Dynamic_Wrap( AAE, "ItemPurchased" ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( AAE, "GameStateEvents" ), self )
	
	AAE.EnteredArena = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}															-- needed to disable the shop
	AAE.Utils.Timer.Init()
	
	AAE.GameType = 0 --0=FFA, 1=Teamfight_Deathmatch, 2=Teamfight_Arena-Mode
	AAE._lastTime = GameRules:GetGameTime()
	GameMode:SetThink( "Think", self, 0.01 )
	
	GameRules:SetHideKillMessageHeaders(true)
	
	AAE.PlayerKills = {}
	AAE.PlayerDeaths = {}
	AAE.PlayerStreak = {}
	AAE.PlayerMultikill = {}
	
	for i=0,9,1 do
		AAE.PlayerKills[i] = 0
		AAE.PlayerDeaths[i] = 0
		AAE.PlayerStreak[i] = 0
		AAE.PlayerMultikill[i] = {curCount = 0, lastTime = -10.0} --First Entry is Count, second entry is last time a hero was killed.
	end

	AAE.Utils.Timer.Register( SpawnRunes, 0.999999999, GetTimerIndex() )
	AAE.Utils.Timer.Register( RunePickup, 0.01, GetTimerIndex() )
end



function AAE:Think()
	local ctime = GameRules:GetGameTime()
	local dtime = ctime - AAE._lastTime
	AAE._lastTime = ctime
	AAE.Utils.Timer.Think( ctime )
	return 0.01
end



--Statistic updates and respawns and kill messsages--
function AAE:OnEntityKilled( event )
	local killedUnitIndex = event.entindex_killed
	local killedUnit = EntIndexToHScript( killedUnitIndex )
	AAE.allUnits[tonumber(killedUnitIndex)] = nil
	
	if (AAE.GameType == 0 or AAE.GameType == 1) then																				-- if dying unit real hero: respawn after 5s
		if (killedUnit:IsRealHero()) then
			local timerIndex = GetTimerIndex()
			AAE.timerTable[timerIndex] = { unit = killedUnit }
			AAE.Utils.Timer.Register( RespawnHero, 5, timerIndex )
		end
	end
	
	if(AAE.GameType == 0) then																										-- FFA
		if (killedUnit:IsRealHero()) then																							-- no illus
			for key, value in pairs(AAE.combatSystem[killedUnit]) do																-- for each player p:
				if (value > AAE._lastTime and killedUnit:GetOwner() ~= PlayerResource:GetPlayer(key)) then							-- did p damage killedUnit recently? suicide doesn't count
					if(killedUnit:GetOwner():GetTeam() == PlayerResource:GetPlayer(key):GetTeam()) then								-- if killed unit is of same team increase kill count, cause FFA
						PlayerResource:IncrementKills(key, 1)
					end
					if (AAE.PlayerMultikill[key].lastTime + 5.0 > AAE._lastTime) then
						AAE.PlayerMultikill[key].curCount = AAE.PlayerMultikill[key].curCount + 1
					else
						AAE.PlayerMultikill[key].curCount = 1
					end
					
					AAE.PlayerMultikill[key].lastTime = AAE._lastTime
					AAE.PlayerKills[key] = AAE.PlayerKills[key] + 1																	-- independent of Dota2 KillCount
					AAE.PlayerStreak[key] = AAE.PlayerStreak[key] + 1

					StreakAndMultikillHeaders (key)
				end
			end
			AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] = AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] +1		-- independent of Dota2 DeathCount
			AAE.PlayerStreak[killedUnit:GetOwner():GetPlayerID()] = 0
		else
			AAE.combatSystem[killedUnit] = nil
		end
	else
		if(AAE.GameType == 1) then																									-- Teamfight Deathmatch
			if (killedUnit:IsRealHero()) then																						-- no illus
				for key, value in pairs(AAE.combatSystem[killedUnit]) do															-- for each player p:
					if (value > AAE._lastTime and killedUnit:GetOwner() ~= PlayerResource:GetPlayer(key)) then						-- did p damage killedUnit recently? suicide doesn't count
						if(killedUnit:GetOwner():GetTeam() ~= PlayerResource:GetPlayer(key):GetTeam()) then							-- team kills don't ccount here
							if (AAE.PlayerMultikill[key][lastTime] + 5.0 > AAE._lastTime) then
								AAE.PlayerMultikill[key][curCount] = AAE.PlayerMultikill[key][curCount] + 1
							else
								AAE.PlayerMultikill[key][curCount] = 1
							end

							AAE.PlayerMultikill[key][lastTime] = AAE._lastTime
							AAE.PlayerKills[key] = AAE.PlayerKills[key] + 1
							AAE.PlayerStreak[key] = AAE.PlayerStreak[key] + 1

							StreakAndMultikillHeaders (key)
						end
					end
				end
				AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] = AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] +1
				AAE.PlayerStreak[killedUnit:GetOwner():GetPlayerID()] = 0
			else
				AAE.combatSystem[killedUnit] = nil
			end
		end
	end
end



function AAE:OnNPCSpawned( event )
	local spawnedUnitIndex = event.entindex
	local spawnedUnit = EntIndexToHScript( spawnedUnitIndex )
	
	if not spawnedUnit then
		AAE:SendCustomMessage ("[ERROR] OnNPCSpawned: Spawned unit is nil.", 1, 1)
		return
	end
	
	if (AAE.unitTypeInfo[spawnedUnit:GetUnitName()] == nil) then												-- Check if unittype is in table (unitTypeInfo)
		if (spawnedUnit:IsHero()) then																				-- Check if unit is Hero
			AAE.unitTypeInfo[spawnedUnit:GetUnitName()] = { physics = true, collisionSize = 70, baseMs = spawnedUnit:GetBaseMoveSpeed() }
			AAE.allUnits[spawnedUnitIndex] = { lightProtTime =  AAE._lastTime + 2.5 }												--Physicsunit spawned
			spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_bloodseeker_thirst_speed", {})
			
			for i=1,3,1 do
				local unit = CreateUnitByName("npc_dota_necronomicon_warrior_test", spawnedUnit:GetAbsOrigin(), true, spawnedUnit:GetOwner(), spawnedUnit:GetOwner(), spawnedUnit:GetTeamNumber())
				unit:FindAbilityByName("aae_m_mage_interceptorMissile"):SetLevel(1)
				unit:SetControllableByPlayer(spawnedUnit:GetOwner():GetPlayerID(), true)
				FindClearSpaceForUnit(unit, spawnedUnit:GetAbsOrigin(), true)
			end
			
		else
			GameRules:SendCustomMessage ("Error: Unit entered the map but has no entry in 'unitTypeInfo'.", 1, 1)
		end
	else
		if (AAE.unitTypeInfo[spawnedUnit:GetUnitName()].physics == false) then								--Dummyunit spawned
		else
			if (spawnedUnit:IsHero()) then
				AAE.allUnits[spawnedUnitIndex] = {lightProtTime =  AAE._lastTime + 2.5} 													--Physicsunit spawned
			else
				AAE.allUnits[spawnedUnitIndex] = {lightProtTime =  0}
			end
			spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_bloodseeker_thirst_speed", {})
		end
	end
	
	if (AAE.GameModeSelected == 0) then									-- Teleport player 1 for setting Game Mode
		if (spawnedUnit:GetPlayerOwnerID() == 0 and spawnedUnit:IsHero()) then 
			AAE.GameModeSelected = 1
			local timerId = GetTimerIndex()
			AAE.timerTable[timerId] = {spawnedUnit = spawnedUnit}
			AAE.Utils.Timer.Register( TelPlayerOne, 0.01, timerId )
		end
	end
end



function AAE:GameStateEvents( event )
	if (GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION) then		-- Create the dummy units which are placed around the map
		local player = PlayerResource:GetPlayer(0)
		
		for key, value in pairs (AAE.lightningTab) do
			local unit = CreateUnitByName("npc_dota_lightning", Vector(value.startX, value.startY, 128), false, player, player, 0)
			
			unit:FindAbilityByName("lightning_spell_settings"):SetLevel(1)
			unit:SetAbsOrigin(Vector(unit:GetAbsOrigin().x, unit:GetAbsOrigin().y, 150)) --We need this function, to increase the height of the lightning. Setting it to 150 while creating it doesn't work.
			value.lightDummy = unit
			value.lightParticle = ParticleManager:CreateParticle("particles/maplightnings/move/wisp_tether_map_move.vpcf", PATTACH_ABSORIGIN_FOLLOW, value.lightDummy)
			ParticleManager:SetParticleControl(value.lightParticle, 1, Vector(value.endX, value.endY, 150.0))
		end
		
		AAE.Utils.Timer.Register( UpdateLightnings, 0.01, GetTimerIndex())
		AAE.Utils.Timer.Register( MoveLightnings, 0.01, GetTimerIndex() )
	end
	
	if (GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME) then
		PregameInfoMessages ()
		SetStartGold ()
	end
end




