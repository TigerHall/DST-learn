-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    初始化礼物


]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---

    local data_fns = {
        ----------------------------------------------------------------------
        --- 传送核心
            function(inst)
                if not TheWorld:HasTag("cave") and not inst.components.tbat_data_to_world:Get("gift.tbat_item_trans_core") then
                    inst.components.tbat_data_to_world:Set("gift.tbat_item_trans_core", true)
                    local item = SpawnPrefab("tbat_item_trans_core")
                    item.components.stackable:SetStackSize(2)
                    inst.components.inventory:GiveItem(item)
                end
            end,
        ----------------------------------------------------------------------
        --- 笔记
            function(inst)
                if not TheWorld:HasTag("cave") and not inst.components.tbat_data_to_world:Get("gift.tbat_item_notes_of_adventurer_1") then
                    inst.components.tbat_data_to_world:Set("gift.tbat_item_notes_of_adventurer_1", true)
                    local item = SpawnPrefab("tbat_item_notes_of_adventurer_1")
                    -- item.components.stackable:SetStackSize(2)
                    inst.components.inventory:GiveItem(item)
                end
            end,
        ----------------------------------------------------------------------
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function all_fn(inst)
        for k, fn in pairs(data_fns) do
            fn(inst)
        end
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
    ------------------------------------------------------
    --- 通用数据库
        if inst.components.tbat_data == nil then
            inst:AddComponent("tbat_data")
        end
        if inst.components.tbat_data_to_world == nil then
            inst:AddComponent("tbat_data_to_world")
        end
    ------------------------------------------------------
    ---
        inst:DoTaskInTime(0,all_fn)
    ------------------------------------------------------
end)
