--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    打包地皮使用


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_turfs_pack_chesspieces"
    local num_to_give = 20
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_turfs_pack_chesspieces.blue"] = {                    --- 
            bank = "cane",
            build = "swap_cane",
            atlas = "images/inventoryimages/tbat_turf_checkerfloor_blue.xml",
            image = "tbat_turf_checkerfloor_blue",  -- 不需要 .tex
            name = TBAT:GetString2("turf_tbat_turf_checkerfloor_blue","name"),        --- 切名字用的
            prefab = "turf_tbat_turf_checkerfloor_blue",
        },
        ["tbat_turfs_pack_chesspieces.orange"] = {                    --- 
            bank = "cane",
            build = "swap_cane",
            atlas = "images/inventoryimages/tbat_turf_checkerfloor_orange.xml",
            image = "tbat_turf_checkerfloor_orange",  -- 不需要 .tex
            name = TBAT:GetString2("turf_tbat_turf_checkerfloor_orange","name"),        --- 切名字用的
            prefab = "turf_tbat_turf_checkerfloor_orange",
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:SetDefaultSkinName(skins_data,this_prefab,TBAT:GetString2("turf_tbat_turf_checkerfloor_pink","name"))
    TBAT.SKIN:AddForDefaultUnlock("tbat_turfs_pack_chesspieces.blue")
    TBAT.SKIN:AddForDefaultUnlock("tbat_turfs_pack_chesspieces.orange")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function OnBuilt(inst,builder)
        local default_prefab = "turf_tbat_turf_checkerfloor_pink"
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


