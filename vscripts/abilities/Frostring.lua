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
	
	for pickedUnit, _ in pairs (AAE.allUnits) do --Check inner and outer circle for collisions with units
		--local pickedUnit = EntIndexToHScript(key)
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
	local timerIndex = GetTimerIndex()
	
	for i=1, 16, 1 do
		local missileDummy = CreateUnitByName("aae_dummy_mage_frostring", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_frostring"):SetLevel(1)
		missileGroup[i] = { missileDummy = missileDummy, dX = math.cos(i * math.pi / 8.00), dY = math.sin(i * math.pi / 8.00) }
	end
	
	for i=17, 32, 1 do
		local missileDummy = CreateUnitByName("aae_dummy_mage_frostring_1", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		missileDummy:FindAbilityByName("aae_d_mage_frostring_1"):SetLevel(1)
		missileGroup[i] = { missileDummy = missileDummy, dX = math.cos(i * math.pi / 8.00), dY = math.sin(i * math.pi / 8.00) }
	end

	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.ColdFeetCast", caster, 3.0, false)  								--eisiger blow 2s lang (zB frostring)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.ColdFeetTick", caster, 3.0, false)    							--leises eingefrieren (1,5s) (zB frostdebuff)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.ColdFeetFreeze", caster, 3.0, false)								--eisiger blow 2s lang (zB frostring)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceVortexCast", caster, 3.0, false)								--bissel eisiger blow 1,5s, bissel ruhiger
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceVortex", caster, 3.0, false)									--ganz leiser frostiger hintergrundsound
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.ChillingTouchCast", caster, 3.0, false)							--kurzer frostiger hit (1s) vlt frostball hit?
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlast.Tracker", caster, 3.0, false)							--kurzer frostiger hit (1s) vlt frostball hit?
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlastRelease.Cast", caster, 3.0, false)						--kurzer frostlaunch (1s)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlastRelease.Cast.Self", caster, 3.0, false)					--kurzer frostlaunch (1s), etwas unfrostiger
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlast.Particle", caster, 3.0, false)							--eher unhörbar, dezent (usw)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlast.Target", caster, 3.0, false)							--richtig fetter frostsplatter (2s)
	--PlaySoundOnUnitInit("Hero_Ancient_Apparition.IceBlastRelease.Tick", caster, 3.0, false)						--leises eingefrieren (1,5s) (zB frostdebuff)

	--PlaySoundOnUnitInit("Hero_Crystal.CrystalNova", caster, 3.0, false)											--kurzer stark windiger froststoß (1,5s)
	--PlaySoundOnUnitInit("hero_Crystal.frostbite", caster, 3.0, false)												--Kristalisierung (2s) echt sau geil
	--PlaySoundOnUnitInit("hero_Crystal.freezingField.wind", caster, 5.0, false)									--Blizzard, super geil (5s), wind und frost usw
	--PlaySoundOnUnitInit("Hero_Crystal.CrystalNova.Yulsaria", caster, 3.0, false)									--leicht frostiger wind, aber hauptsächlich wind (2,5s); vlt auch eisblocksplatter (aber jo)
	--PlaySoundOnUnitInit("Hero_Crystal.FreezingField.Arcana", caster, 3.0, false)									--winter is coming blizzard mit hund, sau lang, sau gut
	--PlaySoundOnUnitInit("Hero_Crystal.ChoirOfIcewrack", caster, 3.0, false)										--hundegeheul, richtig gut, aber kein frost

	--PlaySoundOnUnitInit("Hero_DrowRanger.FrostArrows", caster, 3.0, false)										--frostsplinterhit, 1s, nicht schlecht
	--PlaySoundOnUnitInit("Hero_DrowRanger.Silence", caster, 3.0, false)											--eisiger blow, kleiner impact 1,5s

	--PlaySoundOnUnitInit("Hero_Invoker.ColdSnap", caster, 3.0, false)												--wasserimpact, knallt gut rein (3s), aber lang
	--PlaySoundOnUnitInit("Hero_Invoker.ColdSnap.Freeze", caster, 3.0, false)										--leicht eisiger und windiger launch (1,5s)
	--PlaySoundOnUnitInit("Hero_Invoker.IceWall.Cast", caster, 3.0, false)											--eisiger langer blow, 3,5s
	--PlaySoundOnUnitInit("Hero_Invoker.IceWall.Slow", caster, 3.0, false)											--ganz leises eisiges rasseln

	--PlaySoundOnUnitInit("Hero_Jakiro.IcePath", caster, 3.0, false)													--größere längere eiszersplitterung

	PlaySoundOnUnitInit("Ability.FrostNova", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.FrostArmor", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.FrostArmorDamage", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.ChainFrost", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.ChainFrostLoop", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.ChainFrostImpact.Hero", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.ChainFrostImpact.LF", caster, 3.0, false)													--größere längere eiszersplitterung
	--PlaySoundOnUnitInit("Hero_Lich.ChainFrostImpact.Creep", caster, 3.0, false)													--größere längere eiszersplitterung


	
	AAE.timerTable[timerIndex] = { caster = caster, missileGroup = missileGroup, castLoc = casterLoc, intervalCount = 0 }
	
	AAE.Utils.Timer.Register( FrostringUpdate, 0.01, timerIndex )
end
