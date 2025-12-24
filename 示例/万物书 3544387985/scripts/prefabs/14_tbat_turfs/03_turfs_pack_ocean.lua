--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    打包地皮使用


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_turfs_pack_ocean"
    local num_to_give = 4
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_turfs_pack_ocean.mid"] = {                    --- 
            bank = "cane",
            build = "swap_cane",
            atlas = "images/inventoryimages/tbat_turf_fake_ocean_middle.xml",
            image = "tbat_turf_fake_ocean_middle",  -- 不需要 .tex
            name = TBAT:GetString2("turf_tbat_turf_fake_ocean_middle","name"),        --- 切名字用的
            prefab = "turf_tbat_turf_fake_ocean_middle",
        },
        ["tbat_turfs_pack_ocean.deep"] = {                    --- 
            bank = "cane",
            build = "swap_cane",
            atlas = "images/inventoryimages/tbat_turf_fake_ocean_deep.xml",
            image = "tbat_turf_fake_ocean_deep",  -- 不需要 .tex
            name = TBAT:GetString2("turf_tbat_turf_fake_ocean_deep","name"),        --- 切名字用的
            prefab = "turf_tbat_turf_fake_ocean_deep",
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:SetDefaultSkinName(skins_data,this_prefab,TBAT:GetString2("turf_tbat_turf_fake_ocean_shallow","name"))
    TBAT.SKIN:AddForDefaultUnlock("tbat_turfs_pack_ocean.mid")
    TBAT.SKIN:AddForDefaultUnlock("tbat_turfs_pack_ocean.deep")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function OnBuilt(inst,builder)
        local default_prefab = "turf_tbat_turf_fake_ocean_shallow"
        local data = inst.components.tbat_com_skin_data:GetCurrentData()
        if data and data.prefab then
            default_prefab = data.prefab
        end
        local item = SpawnPrefab(default_prefab)
        item.components.stackable:SetStackSize(num_to_give)
        builder.components.inventory:GiveItem(item)
        inst:Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_com_skin_data")
        inst.OnBuilt = OnBuilt
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn)


