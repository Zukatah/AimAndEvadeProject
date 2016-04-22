
if AAE == nil then
	_G.AAE = class({})
end



require( "utils.timer" )
require ("map_port.map_config")
require ("utils.utils")



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
	
	-- Hook into game events
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( AAE, "OnEntityKilled" ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( AAE, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_item_purchased", Dynamic_Wrap( AAE, "ItemPurchased" ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( AAE, "GameStateEvents" ), self )
	
	AAE.EnteredArena = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}															-- needed to disable the shop
	AAE.SetPlayerGold = false																					-- Set to 1 when the first hero has entered the arena
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
	
	local timerIndex = GetTimerIndex()
	AAE.Utils.Timer.Register( SpawnRunes, 0.999999999, timerIndex )
	timerIndex = GetTimerIndex()
	AAE.Utils.Timer.Register( RunePickup, 0.01, timerIndex )
end



function SpawnRunes()
	local player = PlayerResource:GetPlayer(0) --I need any player for being the owner of the runes. TODO: Is there some sort of neutral player to avoid using the "first" player?
	local randPos
	local runeUnit
	
	if (math.random() <= 0.02) then --Spawn haste rune
		randPos = GetRandomPosition()
		runeUnit = CreateUnitByName("aae_dummy_rune_haste", randPos, false, player, player, 0)
		runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
		AAE.runes[runeUnit] = { runePos = randPos, runeType = 0 }
	end
	if (math.random() <= 0.02) then --Spawn double damage rune
		randPos = GetRandomPosition()
		runeUnit = CreateUnitByName("aae_dummy_rune_doubleDamage", randPos, false, player, player, 0)
		runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
		AAE.runes[runeUnit] = { runePos = randPos, runeType = 1 }
	end
	if (math.random() <= 0.02) then --Spawn double damage rune
		randPos = GetRandomPosition()
		runeUnit = CreateUnitByName("aae_dummy_rune_portkey", randPos, false, player, player, 0)
		runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
		AAE.runes[runeUnit] = { runePos = randPos, runeType = 2 }
	end
	if (math.random() <= 0.02) then --Spawn invisibility rune
		randPos = GetRandomPosition()
		runeUnit = CreateUnitByName("aae_dummy_rune_invisibility", randPos, false, player, player, 0)
		runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
		AAE.runes[runeUnit] = { runePos = randPos, runeType = 3 }
	end
	if (math.random() <= 0.02) then --Spawn invisibility rune
		randPos = GetRandomPosition()
		runeUnit = CreateUnitByName("aae_dummy_rune_regeneration", randPos, false, player, player, 0)
		runeUnit:FindAbilityByName("aae_rune_properties"):SetLevel(1)
		AAE.runes[runeUnit] = { runePos = randPos, runeType = 4 }
	end
	
	return 0.999999999
end



function Rune_Regeneration(timerIndex)
	local target = AAE.timerTable[timerIndex].target
	
	if (GetBuffCountOnUnit (target, "rune_regeneration", timerIndex) >= 1) then
		target:ModifyHealth(target:GetHealth()+10, nil, false, 0)
		target:SetMana(target:GetMana()+10)
		return 0.99999
	end
	
	AAE.timerTable[timerIndex] = nil
end



function RunePickup()
	local collision
	local removeTable = {}
	local player = PlayerResource:GetPlayer(0) --I need any player for being the owner of the runes. TODO: Is there some sort of neutral player to avoid using the "first" player?
	
	for runeUnit, runeInfoTable in pairs (AAE.runes) do
		collision = false
		
		for physicUnit, wayne in pairs (AAE.allUnits) do
			local pickedUnit = EntIndexToHScript(physicUnit)
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



function AAE:Think()
	local ctime = GameRules:GetGameTime()
	local dtime = ctime - AAE._lastTime
	AAE._lastTime = ctime
	AAE.Utils.Timer.Think( ctime )
	return 0.01
end



function AAE:OnEntityKilled( event )
	local killedUnitIndex = event.entindex_killed
	local killedUnit = EntIndexToHScript( killedUnitIndex )
	local attackingUnit = EntIndexToHScript( event.entindex_attacker )
	local damagebitVar = EntIndexToHScript( event.damagebits )
	AAE.allUnits[tonumber(killedUnitIndex)] = nil
	
	if (AAE.GameType == 0) then
		if (killedUnit:IsRealHero()) then
			local timerIndex = GetTimerIndex()
			AAE.timerTable[timerIndex] = { unit = killedUnit }													-- save unit in table
			AAE.Utils.Timer.Register( RespawnHero, 5, timerIndex )														-- Call RandomEnterArena in 5 seconds
		end
	else
		if (AAE.GameType == 1) then
			if (killedUnit:IsRealHero()) then
				local timerIndex = GetTimerIndex()
				AAE.timerTable[timerIndex] = { unit = killedUnit }													-- save unit in table
				AAE.Utils.Timer.Register( RespawnHero, 5, timerIndex )														-- Call RandomEnterArena in 5 seconds
			end
		end
	end
	
	
	if(AAE.GameType == 0) then --FFA
		if (killedUnit:IsRealHero()) then
			for key, value in pairs(AAE.combatSystem[killedUnit]) do
				if (value > AAE._lastTime and killedUnit:GetOwner() ~= PlayerResource:GetPlayer(key)) then
					if(killedUnit:GetOwner():GetTeam() == PlayerResource:GetPlayer(key):GetTeam()) then		-- Wenn geötete Einheit vom selben team ist gebe kill
						PlayerResource:IncrementKills(key, 1)
					end
					if (AAE.PlayerMultikill[key].lastTime + 5.0 > AAE._lastTime) then						-- 
						AAE.PlayerMultikill[key].curCount = AAE.PlayerMultikill[key].curCount + 1			-- Multikill
					else
						AAE.PlayerMultikill[key].curCount = 1
					end
					
					AAE.PlayerMultikill[key].lastTime = AAE._lastTime
					AAE.PlayerKills[key] = AAE.PlayerKills[key] + 1				-- unabhängig vom System
					AAE.PlayerStreak[key] = AAE.PlayerStreak[key] + 1			-- Streak 
					
					if (AAE.PlayerMultikill[key].curCount == 2) then
						ShowCustomHeaderMessage( "#Kill_DoubleKill", 0, 0, 5 )
					else
						if (AAE.PlayerMultikill[key].curCount == 3) then
							ShowCustomHeaderMessage( "#Kill_TripleKill", 0, 0, 5 )
						else
							if (AAE.PlayerMultikill[key].curCount == 4) then
								ShowCustomHeaderMessage( "#Kill_UltraKill", 0, 0, 5 )
							else
								if (AAE.PlayerMultikill[key].curCount >= 5) then
									ShowCustomHeaderMessage( "#Kill_Rampage", 0, 0, 5 )
								end
							end
						end
					end
					
					
					
					if (AAE.PlayerStreak[key] == 3) then
						ShowCustomHeaderMessage( "#Streak_KillingSpree", 0, 0, 5 )
					else
						if (AAE.PlayerStreak[key] == 4) then
							ShowCustomHeaderMessage( "#Streak_Dominating", 0, 0, 5 )
						else
							if (AAE.PlayerStreak[key] == 5) then
								ShowCustomHeaderMessage( "#Streak_MegaKill", 0, 0, 5 )
							else
								if (AAE.PlayerStreak[key] == 6) then
									ShowCustomHeaderMessage( "#Streak_Unstoppable", 0, 0, 5 )
								else
									if (AAE.PlayerStreak[key] == 7) then
										ShowCustomHeaderMessage( "#Streak_WickedSick", 0, 0, 5 )
									else
										if (AAE.PlayerStreak[key] == 8) then
											ShowCustomHeaderMessage( "#Streak_MonsterKill", 0, 0, 5 )
										else
											if (AAE.PlayerStreak[key] == 9) then
												ShowCustomHeaderMessage( "#Streak_Godlike", 0, 0, 5 )
											else
												if (AAE.PlayerStreak[key] >= 10) then
													ShowCustomHeaderMessage( "#Streak_BeyondGodlike", 0, 0, 5 )
												end
											end
										end
									end
								end
							end
						end
					end
						
					
					
					
					
					--ShowCustomHeaderMessage() --Noch zu integrieren! Eigene Kill Multikill und Streakinfos
					--GameRules:SendCustomMessage ("Multikillcount: " .. tostring(AAE.PlayerMultikill[key].curCount), 1, 1)
					--GameRules:SendCustomMessage ("Streak: " .. tostring(AAE.PlayerStreak[key]), 1, 1)
					--GameRules:SendCustomMessage ("PlayerId: " .. tostring(key) .. " Kills: " .. tostring(AAE.PlayerKills[key]), 1, 1)
				end
			end
			AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] = AAE.PlayerDeaths[killedUnit:GetOwner():GetPlayerID()] +1			-- unabhängig vom System
			AAE.PlayerStreak[killedUnit:GetOwner():GetPlayerID()] = 0
		else
			AAE.combatSystem[killedUnit] = nil
		end
		
	else
		
		if(AAE.GameType == 1) then --Teamfight Deathmatch
			if (killedUnit:IsRealHero()) then
				for key, value in pairs(AAE.combatSystem[killedUnit]) do
					if (value > AAE._lastTime and killedUnit:GetOwner() ~= PlayerResource:GetPlayer(key)) then
						if(killedUnit:GetOwner():GetTeam() == PlayerResource:GetPlayer(key):GetTeam()) then
						else
							if (AAE.PlayerMultikill[key][lastTime] + 5.0 > AAE._lastTime) then
								AAE.PlayerMultikill[key][curCount] = AAE.PlayerMultikill[key][curCount] + 1
							else
								AAE.PlayerMultikill[key][curCount] = 1
							end
							AAE.PlayerMultikill[key][lastTime] = AAE._lastTime
							AAE.PlayerKills[key] = AAE.PlayerKills[key] + 1
							AAE.PlayerStreak[key] = AAE.PlayerStreak[key] + 1
							
							if (AAE.PlayerMultikill[key].curCount == 2) then
								ShowCustomHeaderMessage( "#Kill_DoubleKill", 0, 0, 5 )
							else
								if (AAE.PlayerMultikill[key].curCount == 3) then
									ShowCustomHeaderMessage( "#Kill_TripleKill", 0, 0, 5 )
								else
									if (AAE.PlayerMultikill[key].curCount == 4) then
										ShowCustomHeaderMessage( "#Kill_UltraKill", 0, 0, 5 )
									else
										if (AAE.PlayerMultikill[key].curCount >= 5) then
											ShowCustomHeaderMessage( "#Kill_Rampage", 0, 0, 5 )
										end
									end
								end
							end
					
					
					
							if (AAE.PlayerStreak[key] == 3) then
								ShowCustomHeaderMessage( "#Streak_KillingSpree", 0, 0, 5 )
							else
								if (AAE.PlayerStreak[key] == 4) then
									ShowCustomHeaderMessage( "#Streak_Dominating", 0, 0, 5 )
								else
									if (AAE.PlayerStreak[key] == 5) then
										ShowCustomHeaderMessage( "#Streak_MegaKill", 0, 0, 5 )
									else
										if (AAE.PlayerStreak[key] == 6) then
											ShowCustomHeaderMessage( "#Streak_Unstoppable", 0, 0, 5 )
										else
											if (AAE.PlayerStreak[key] == 7) then
												ShowCustomHeaderMessage( "#Streak_WickedSick", 0, 0, 5 )
											else
												if (AAE.PlayerStreak[key] == 8) then
													ShowCustomHeaderMessage( "#Streak_MonsterKill", 0, 0, 5 )
												else
													if (AAE.PlayerStreak[key] == 9) then
														ShowCustomHeaderMessage( "#Streak_Godlike", 0, 0, 5 )
													else
														if (AAE.PlayerStreak[key] >= 10) then
															ShowCustomHeaderMessage( "#Streak_BeyondGodlike", 0, 0, 5 )
														end
													end
												end
											end
										end
									end
								end
							end
							
							--ShowCustomHeaderMessage() --Noch zu integrieren! Eigene Kill Multikill und Streakinfos
							--GameRules:SendCustomMessage ("PlayerId: " .. tostring(key) .. " Kills: " .. tostring(AAE.PlayerKills[key]), 1, 1)
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
	
	if (AAE.SetPlayerGold == false) then								-- Set start gold to 600
		if (spawnedUnit:IsHero() == true) then
			for variable = 0, 9, 1 do
				PlayerResource:SetGold(variable, 600, false)
			end
			AAE.SetPlayerGold = true
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



function TelPlayerOne (index)
	local spawnedUnit = AAE.timerTable[index].spawnedUnit
	local point =  Entities:FindByName( nil, "SelectGameModeArea1" ):GetAbsOrigin()
	FindClearSpaceForUnit(spawnedUnit, point, false)
	spawnedUnit:Stop()
end



function AAE:ItemPurchased( event )
	local playerId = event.PlayerID
	local player = PlayerResource:GetPlayer(playerId)
	local hero = player:GetAssignedHero()
	local item = hero:GetItemInSlot(0)
	if (AAE.EnteredArena[playerId+1] == 0) then
		
		if (event.itemname == "item_Fireball") then
			hero:AddAbility("aae_m_mage_fireball")
			hero:FindAbilityByName("aae_m_mage_fireball"):SetLevel(1)
		
		elseif (event.itemname == "item_MC-Bomb") then
			hero:AddAbility("aae_m_mage_mcBomb")
			hero:FindAbilityByName("aae_m_mage_mcBomb"):SetLevel(1)
			
		elseif (event.itemname == "item_DeadlyRange") then
			hero:AddAbility("aae_m_mage_deadlyRange")
			hero:FindAbilityByName("aae_m_mage_deadlyRange"):SetLevel(1)
			
		elseif (event.itemname == "item_Pyroblast") then
			hero:AddAbility("aae_m_mage_pyroblast")
			hero:FindAbilityByName("aae_m_mage_pyroblast"):SetLevel(1)
		
		elseif (event.itemname == "item_ForceStaff") then
			hero:AddAbility("aae_m_mage_forceStaff")
			hero:FindAbilityByName("aae_m_mage_forceStaff"):SetLevel(1)
			
		elseif (event.itemname == "item_ArcingSpark") then
			hero:AddAbility("aae_m_mage_arcingSpark")
			hero:FindAbilityByName("aae_m_mage_arcingSpark"):SetLevel(1)
			
		elseif (event.itemname == "item_MagicLasso") then
			hero:AddAbility("aae_m_mage_magicLasso")
			hero:FindAbilityByName("aae_m_mage_magicLasso"):SetLevel(1)
			
		elseif (event.itemname == "item_InterceptorMissile") then
			hero:AddAbility("aae_m_mage_interceptorMissile")
			hero:FindAbilityByName("aae_m_mage_interceptorMissile"):SetLevel(1)
		
		elseif (event.itemname == "item_FrostFork") then
			hero:AddAbility("aae_m_mage_frostFork")
			hero:FindAbilityByName("aae_m_mage_frostFork"):SetLevel(1)
		
		elseif (event.itemname == "item_Frostring") then
			hero:AddAbility("aae_m_mage_frostring")
			hero:FindAbilityByName("aae_m_mage_frostring"):SetLevel(1)
			
		
			
		elseif (event.itemname == "item_Snowball") then
			hero:AddAbility("aae_m_mage_snowball")
			hero:FindAbilityByName("aae_m_mage_snowball"):SetLevel(1)
			
		
			
		elseif (event.itemname == "item_IceBlock") then
			hero:AddAbility("aae_m_mage_iceBlock")
			hero:FindAbilityByName("aae_m_mage_iceBlock"):SetLevel(1)
		
		elseif (event.itemname == "item_HauntingBlaze") then
			hero:AddAbility("aae_m_mage_hauntingBlaze")
			hero:FindAbilityByName("aae_m_mage_hauntingBlaze"):SetLevel(1)
		
		elseif (event.itemname == "item_ElectricVolley") then
			hero:AddAbility("aae_m_mage_electricVolley")
			hero:FindAbilityByName("aae_m_mage_electricVolley"):SetLevel(1)
		
		elseif (event.itemname == "item_IceAge") then
			hero:AddAbility("aae_m_mage_iceAge")
			hero:FindAbilityByName("aae_m_mage_iceAge"):SetLevel(1)
		
		end
		
		hero:RemoveItem(item)
	end
	
	if (AAE.EnteredArena[event.PlayerID+1] == 1) then
		local item = hero:GetItemInSlot(6)
		hero:RemoveItem(item)
	end
end



function RespawnHero(index)
	-- Respawn hero and call "RandomEnterArena()"
	local unit = AAE.timerTable[index].unit
	
	unit:RespawnHero(false, true, true) --(1.Par = Respawn Sound, 2.Par = ?, 3.Par = ?)
	AAE:RandomEnterArena(unit)
	
	AAE.timerTable[index] = nil
end



function AAE:RandomEnterArena(unit)
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



function AAE:GameStateEvents( event )
	if (GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION) then		-- Create the dummy units which are placed around the map
		local player = PlayerResource:GetPlayer(0)
		
		for key, value in pairs (AAE.lightningTab) do
			local unit = CreateUnitByName("npc_dota_lightning", Vector(value.startX, value.startY, 128), false, player, player, 0)
			
			unit:FindAbilityByName("lightning_spell_settings"):SetLevel(1)
			unit:SetAbsOrigin(Vector(unit:GetAbsOrigin().x, unit:GetAbsOrigin().y, 150)) --We need this function, to increase the height of the lightning. Setting it to 150 while creating it doesn't work.
			value.lightDummy = unit
			
			--GameRules:SendCustomMessage ("Step3", 1, 1)
			--if (unit == nil) then
			--	GameRules:SendCustomMessage ("Step4", 1, 1)
			--end
			
			value.lightParticle = ParticleManager:CreateParticle("particles/maplightnings/move/wisp_tether_map_move.vpcf", PATTACH_ABSORIGIN_FOLLOW, value.lightDummy)
			ParticleManager:SetParticleControl(value.lightParticle, 1, Vector(value.endX, value.endY, 150.0))
		end
		
		AAE.Utils.Timer.Register( AAE.UpdateLightnings, 0.01, GetTimerIndex())
		AAE.Utils.Timer.Register( MoveLightnings, 0.01, GetTimerIndex() )
	end
	
	if (GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME) then
		--nothing anymore												-- Cast the tether wisp spell
		UTIL_MessageTextAll("Choose 5 abilities, the shortcuts are Q, W, E, R, T in the order you pick them (otherwise your specific DotA-config).\nAll abilities are skill shots, so the target is 'point' or 'no target' (but depended on your unit's facing) and not 'unit'.", 255, 0, 0, 1000)
		UTIL_MessageTextAll("\nBe aware of the moving lightning in the map. You can use them to enforce some abilities or to kick your enemys next to them.", 255, 0, 0, 1000)
		UTIL_MessageTextAll("\n\nMap created by Zukatah and Rogen.", 0, 255, 0, 1000)
		UTIL_MessageText(1, "\n\nPlease choose now: Left: Teamfight; Right: FFA", 0, 0, 255, 1000)
	end
end



function AAE:UpdateLightnings()
	local filterPassedGroup
	local minX, maxX, minY, maxY
	AAE.gameInterval = AAE.gameInterval + 1
	
	for i=1, 6, 1 do
		filterPassedGroup = { }
		for key, value in pairs (AAE.allUnits) do
			local pickedUnit = EntIndexToHScript(key)
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
							if (AAE.allUnits[key].lightProtTime < AAE._lastTime) then
								filterPassedGroup[pickedUnit] = true
							end
						end
					end
				end
			end
		end
		
		for pickedUnit, value in pairs (filterPassedGroup) do
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
