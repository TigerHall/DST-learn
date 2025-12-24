-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    初始化宠物骨眼背包

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetBackpack(inst)
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.TBAT_PET_EYEBONE_BACKPACK)
        if item == nil then
            item = SpawnPrefab("tbat_pet_eyebone_backpack")
            inst.components.inventory:Equip(item)
        end
        return item
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- init
    local function backpack_init(inst)
        local item = GetBackpack(inst)
        item:ListenForEvent("unequipped",item.Remove)
        item:Link(inst)
        inst.TBAT_Get_Pet_Eyebone_Backpack = GetBackpack
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end    
    inst:DoTaskInTime(0,backpack_init)
    -- backpack_init(inst)
end)
