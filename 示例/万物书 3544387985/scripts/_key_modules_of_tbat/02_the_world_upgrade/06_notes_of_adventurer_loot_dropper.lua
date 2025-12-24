-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    tbat_item_notes_of_adventurer_

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local data = {
        ["beequeen"] = {"tbat_item_notes_of_adventurer_2","tbat_item_notes_of_adventurer_3"},
        ["dragonfly"] = {"tbat_item_notes_of_adventurer_4","tbat_item_notes_of_adventurer_5"},
        ["bearger"] = {"tbat_item_notes_of_adventurer_6","tbat_item_notes_of_adventurer_7","tbat_item_notes_of_adventurer_8"},
        ["mutatedbearger"] = {"tbat_item_notes_of_adventurer_6","tbat_item_notes_of_adventurer_7","tbat_item_notes_of_adventurer_8"},
        ["klaus"] = {"tbat_item_notes_of_adventurer_9","tbat_item_notes_of_adventurer_10"},
        ["deerclops"] = {"tbat_item_notes_of_adventurer_11","tbat_item_notes_of_adventurer_12","tbat_item_notes_of_adventurer_13","tbat_item_notes_of_adventurer_14"},
        ["mutateddeerclops"] = {"tbat_item_notes_of_adventurer_11","tbat_item_notes_of_adventurer_12","tbat_item_notes_of_adventurer_13","tbat_item_notes_of_adventurer_14"},
        ["antlion"] = {"tbat_item_notes_of_adventurer_15","tbat_item_notes_of_adventurer_16"},
        ["eyeofterror"] = {"tbat_item_notes_of_adventurer_17","tbat_item_notes_of_adventurer_18"},
        ["twinofterror1"] = {"tbat_item_notes_of_adventurer_17","tbat_item_notes_of_adventurer_18"},
        ["twinofterror2"] = {"tbat_item_notes_of_adventurer_17","tbat_item_notes_of_adventurer_18"},
        ["moose"] = {"tbat_item_notes_of_adventurer_19","tbat_item_notes_of_adventurer_20"},
        ["daywalker"] = {"tbat_item_notes_of_adventurer_21","tbat_item_notes_of_adventurer_22","tbat_item_notes_of_adventurer_23"},
        ["daywalker2"] = {"tbat_item_notes_of_adventurer_21","tbat_item_notes_of_adventurer_22","tbat_item_notes_of_adventurer_23"},
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function loot_dropped_event(inst,_table)
        local target = _table and _table.inst
        local prefab = target and target.prefab
        -- print("666++++",prefab)
        local ret = data[prefab]
        if ret and target and target.components.lootdropper then
            local ret_prefab = ret[math.random(#ret)]
            if PrefabExists(ret_prefab) then
                target.components.lootdropper:SpawnLootPrefab(ret_prefab)
            end
        end
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end

    TheWorld:ListenForEvent("entity_droploot",loot_dropped_event)

end)