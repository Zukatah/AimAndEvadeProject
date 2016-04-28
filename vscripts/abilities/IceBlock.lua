require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



function IceBlockUpdate (index)
	local caster = AAE.timerTable[index].caster
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local missileDummy = AAE.timerTable[index].missileDummy
	AAE.timerTable[index].intervalCount = intervalCount
	
	if (GetBuffCountOnUnit (caster, "iceBlock", index) >= 1) then
		missileDummy:SetAbsOrigin(caster:GetAbsOrigin())
		if (intervalCount < 83) then
			return 0.01
		end
	end
	
	missileDummy:ForceKill(true)
	DecreaseBuffCountOnUnit (caster, "iceBlock", index)
	AAE.timerTable[index] = nil
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local timerIndex = GetTimerIndex()
	
	local missileDummy = CreateUnitByName("aae_dummy_mage_frostring", casterLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	missileDummy:FindAbilityByName("aae_d_mage_frostring"):SetLevel(1)
	
	caster:Stop()
	IncreaseBuffCountOnUnit (caster, "iceBlock", timerIndex)
	
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = 0, missileDummy = missileDummy }
	
	AAE.Utils.Timer.Register( IceBlockUpdate, 0.01, timerIndex )
end



function OnOrder (keys)
	local caster = keys.caster
	if (GetBuffCountOnUnit (caster, "iceBlock") > 0) then
		RemoveBuffTypeFromUnit (caster, "iceBlock")
	end
	
	--for key, value in pairs (keys) do PrintLinkedConsoleMessage( "\n" .. "key " .. tostring(key) .. " value " .. tostring(value), "") end
end


