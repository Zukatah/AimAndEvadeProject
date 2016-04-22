require( "utils.timer" )
require ("utils.utils")



--Learn ability when item is bought-- TODO: Prevent players from repeatedly buying the same ability
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
