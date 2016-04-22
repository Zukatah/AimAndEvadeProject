require( "utils.timer" )
require( "utils.utils" )
require( "addon_game_mode" )



magicLasso_collisionSize = 50.0



function MagicLassoBackUpdate(index)
	local caster = AAE.timerTable[index].caster
	local intervalCount = AAE.timerTable[index].intervalCount
	local posTab = AAE.timerTable[index].posTab
	local lightTab = AAE.timerTable[index].lightTab
	local dummyTab = AAE.timerTable[index].dummyTab
	local hookedUnit = AAE.timerTable[index].hookedUnit
	local remHookDist = 33.33
	AAE.timerTable[index].intervalCount = intervalCount
	
	if (hookedUnit ~= nil) then
		if (GetBuffCountOnUnit (hookedUnit, "magicLasso", index) < 1) then
			hookedUnit = nil
			AAE.timerTable[index].hookedUnit = nil
		end
	end

	while (remHookDist > 0) do
		local curPoint = posTab[intervalCount]
		local lastPoint = posTab[intervalCount-1]
		local deltaPoints = lastPoint - curPoint
		deltaPoints.z = 0.0
		deltaPointsLen = math.sqrt(deltaPoints.x*deltaPoints.x+deltaPoints.y*deltaPoints.y)
		local curLight = lightTab[intervalCount]
		
		if (deltaPointsLen <= remHookDist) then
			remHookDist = remHookDist - deltaPointsLen
			ParticleManager:DestroyParticle(curLight, true)
			dummyTab[intervalCount]:RemoveSelf()
			intervalCount = intervalCount - 1
			AAE.timerTable[index].intervalCount = intervalCount
			if (hookedUnit ~= nil and remHookDist == 0.0) then
				hookedUnit:SetAbsOrigin(lastPoint)
			end
			if (intervalCount == 0) then
				remHookDist = 0.0
			end
		else
			deltaPoints = deltaPoints / deltaPointsLen --Normalize distance vector
			curPoint = curPoint + remHookDist * deltaPoints
			if (hookedUnit ~= nil) then
				hookedUnit:SetAbsOrigin(curPoint)
			end
			ParticleManager:SetParticleControl(curLight, 1, Vector(curPoint.x, curPoint.y, curPoint.z+60 )) --Move lightning target to new curPoint
			posTab[intervalCount] = curPoint
			remHookDist = 0
		end
		
	end
	
	if (intervalCount > 0) then
		return 0.01
	end
	
	if (hookedUnit ~= nil) then
		DecreaseBuffCountOnUnit (hookedUnit, "magicLasso", index)
		FindClearSpaceForUnit(hookedUnit, hookedUnit:GetAbsOrigin(), true)
	end
	AAE.timerTable[index] = nil
end



function MagicLassoUpdate(index) --Create up to 18 lightning instances
	local caster = AAE.timerTable[index].caster
	local casterOwner = caster:GetOwner()
	local casterLoc = caster:GetAbsOrigin()
	local intervalCount = AAE.timerTable[index].intervalCount + 1
	local normVecDir = AAE.timerTable[index].normVecDir
	local posTab = AAE.timerTable[index].posTab
	local lightTab = AAE.timerTable[index].lightTab
	local dummyTab = AAE.timerTable[index].dummyTab
	local curPoint = VectorInMapBounds(casterLoc + intervalCount * 61.9 * normVecDir)
	
	AAE.timerTable[index].intervalCount = intervalCount
	
	local lastLoc = posTab[intervalCount-1]
	posTab[intervalCount] = curPoint
	lightDummy = CreateUnitByName("aae_dummy_mage_magicLasso", lastLoc, false, casterOwner, casterOwner, caster:GetTeamNumber())
	lightDummy:FindAbilityByName("aae_d_mage_magicLasso"):SetLevel(1)
	lightDummy:SetAbsOrigin(Vector(lightDummy:GetAbsOrigin().x, lightDummy:GetAbsOrigin().y, lightDummy:GetAbsOrigin().z+60))
	dummyTab[intervalCount] = lightDummy
	lightningBolt = ParticleManager:CreateParticle("particles/magiclasso/wisp_tether_lasso.vpcf", PATTACH_ABSORIGIN_FOLLOW, lightDummy)
	ParticleManager:SetParticleControl(lightningBolt,1,Vector(curPoint.x, curPoint.y, curPoint.z+60))
	lightTab[intervalCount] = lightningBolt
	
	local collision, hookedUnit = IsMissileColliding (caster, curPoint, magicLasso_collisionSize)
	
	if (collision and GetBuffCountOnUnit (hookedUnit, "magicLasso") <= 0 and GetBuffCountOnUnit (hookedUnit, "snowball") <= 0) then
		AAE.timerTable[index].hookedUnit = hookedUnit
		DealDamage (caster, hookedUnit, 70.0)
		IncreaseBuffCountOnUnit (hookedUnit, "magicLasso", index)
	end
	
	if (collision or intervalCount >= 18) then
		AAE.Utils.Timer.Register( MagicLassoBackUpdate, 0.01, index )
	else
		return 0.066666666
	end
end



function OnSpellStart ( keys )
	local caster = keys.caster
	local castLoc = caster:GetAbsOrigin()
	local intervalCount = 0
	local cliffLevel = (GetGroundPosition(castLoc, nil)).z
	local timerIndex = GetTimerIndex()
	local lightTab = {}
	local posTab = {}
	local dummyTab = {}
	
	local targetPoint = nil
	if (keys.Target == "POINT" and keys.target_points[1]) then
		targetPoint = keys.target_points[1]
	else
		return
	end
	targetPoint.z = cliffLevel
	
	local normVecDir = targetPoint - castLoc
	local vecDirLen = math.sqrt((normVecDir.x)*(normVecDir.x)+(normVecDir.y)*(normVecDir.y))
	if (vecDirLen ~= 0) then
		normVecDir=normVecDir/vecDirLen
	else
		normVecDir=Vector(1.0, 0.0, 0.0)
	end
	
	posTab[0] = castLoc
	
	AAE.timerTable[timerIndex] = { caster = caster, intervalCount = intervalCount, normVecDir = normVecDir, posTab = posTab, lightTab = lightTab, dummyTab = dummyTab, hookedUnit = nil }
	AAE.Utils.Timer.Register( MagicLassoUpdate, 0.066666666, timerIndex )
end
