require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



function ForcestaffUpdate(index)
	local caster = AAE.timerTable[index].caster
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local cliffLevel = AAE.timerTable[index].cliffLevel
	local normVecDir = AAE.timerTable[index].normVecDir
	
	local casterLoc = caster:GetAbsOrigin()
	local casterOwner = caster:GetOwner()
	local newCasterLoc = VectorInMapBounds(casterLoc + (normVecDir * 66.667))
	local newCliffLevel = (GetGroundPosition(newCasterLoc, nil)).z
	local spellEnd = false
	
	
	if (GetBuffCountOnUnit (caster, "knockback", index) >= 1) then
		if (cliffLevel + 5.0 < newCliffLevel) then
			newCasterLoc = casterLoc
			spellEnd = true
		else
			if (GetBuffCountOnUnit (caster, "magicLasso") >= 1 or GetBuffCountOnUnit (caster, "snowball") >= 1) then
			else
				caster:SetAbsOrigin(newCasterLoc)
			end
			if (intervalCount >= 11) then
				spellEnd = true
			else
				AAE.timerTable[index].intervalCount = intervalCount
			end
		end
		
		local forcestaffDummy = CreateUnitByName("aae_dummy_mage_forcestaff", newCasterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
		forcestaffDummy:FindAbilityByName("aae_d_mage_forceStaff"):SetLevel(1)
		RemoveDummyTimedInit(forcestaffDummy, 0.2)
		
		if (not spellEnd) then
			return 0.01
		end
	end
	
	local instancesCount = DecreaseBuffCountOnUnit (caster, "knockback", index)
	if (instancesCount <= 0) then
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end
	
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterFacing = caster:GetAngles().y * 0.01745329
	local casterLoc = caster:GetAbsOrigin()
	local normVecDir = Vector( math.cos(casterFacing), math.sin(casterFacing), 0.0 )
	local cliffLevel = (GetGroundPosition(casterLoc, nil)).z
	local timerIndex = GetTimerIndex()
	
	caster:Stop()
	IncreaseBuffCountOnUnit (caster, "knockback", timerIndex)
	PlaySoundOnUnitInit("DOTA_Item.ForceStaff.Activate", caster, 1.0, false)
	
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, cliffLevel = cliffLevel, normVecDir = normVecDir, deinVater = deinVater }
	AAE.Utils.Timer.Register( ForcestaffUpdate, 0.01, timerIndex )
end
