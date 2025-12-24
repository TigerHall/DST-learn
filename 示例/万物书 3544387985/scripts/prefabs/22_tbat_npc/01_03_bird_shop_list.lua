--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    remove_blocker_callback = {
        blocker_remove = true,
    }

                TBAT.FNS:GiveItemByPrefab(doer,ret_prefab, num)


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return {
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---- 常规兑换列表: 比例 1 : N
        comm_list = {
            -- ["log"] = { prefab = "boards", num = 1},
            -- ["tbat_plant_coconut_cat_fruit"] = { prefab = "tbat_plant_coconut_tree_seed", num = 1},   --- 【清甜椰子】可以兑换【发芽的清甜椰子】
            -- ["tbat_turf_water_lily_cat_leaf"] = { prefab = "tbat_turf_water_lily_cat_seed", num = 1},   --- 【睡莲猫猫莲叶】可以兑换【睡莲猫猫子株】
            -- ["tbat_food_hedgehog_cactus_meat"] = { prefab = "tbat_plant_hedgehog_cactus_seed", num = 1},   --- 【小仙肉】可以兑换【小仙种子】
            -- ["tbat_material_dandelion_umbrella"] = { prefab = "tbat_material_wish_token", num = 1},   --- 【小仙蒲公英花伞】可以兑换【祈愿牌】
            -- ["tbat_material_squirrel_incisors"] = { prefab = "tbat_material_sunflower_seeds", num = 1},   --- 【松鼠牙】可以兑换【葵瓜子】
            -- ["tbat_material_snow_plum_wolf_hair"] = { prefab = "tbat_material_white_plum_blossom", num = 1},   --- 【狼毛】可以兑换【白梅花】
        },
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---- 特殊兑换列表 : 遍历所有 。和上面的权限并联
        special_list = {
            ------------------------------------------------------------------------
            --- 示例。
                -- {
                --     test = function(inst,item,doer)
                --         if TBAT.DEBUGGING and item.prefab == "log" then
                --             return true
                --         end
                --     end,
                --     fn = function(inst,item,doer,item_num,remove_blocker_callback)
                --         TBAT.FNS:GiveItemByPrefab(doer,"boards",10)
                --     end,
                -- },
            ------------------------------------------------------------------------
            --- 
                {
                    test = function(inst,item,doer)
                        return item:HasTag("tbat_item_notes_of_adventurer")
                    end,
                    fn = function(inst,item,doer,item_num,remove_blocker_callback)
                        local index = item.index
                        item_num = item_num or 1
                        if index == nil then
                            TBAT.FNS:GiveItemByPrefab(doer,"atbook_wiki",item_num)
                        elseif index == 1 then
                            TBAT.FNS:GiveItemByPrefab(doer,"tbat_eq_shake_cup",item_num)
                            TBAT.FNS:GiveItemByPrefab(doer,"tbat_material_emerald_feather",item_num)
                            TBAT.FNS:GiveItemByPrefab(doer,"atbook_wiki",item_num)
                        elseif index == 2 or index == 3 then
                            TBAT.FNS:GiveItemByPrefab(doer,"royal_jelly",item_num * 6)
                        elseif index == 4 or index == 5 then
                            TBAT.FNS:GiveItemByPrefab(doer,"dragon_scales",item_num * 1)
                        elseif index == 6 or index == 7 or index == 8 then
                            TBAT.FNS:GiveItemByPrefab(doer,"bearger_fur",item_num * 1)
                        elseif index == 9 or index == 10 then
                            TBAT.FNS:GiveItemByPrefab(doer,"mandrake",item_num * 1)
                            while item_num > 0 do
                                if math.random(1000)/1000 <= 1/100 or TBAT.DEBUGGING then
                                    TBAT.FNS:GiveItemByPrefab(doer,"krampus_sack",1)                                
                                end
                                item_num = item_num - 1
                            end
                        elseif index == 11 or index == 12 or index == 13 or index == 14 then
                            TBAT.FNS:GiveItemByPrefab(doer,"deerclops_eyeball",item_num * 1)                            
                        elseif index == 15 or index == 16 then
                            TBAT.FNS:GiveItemByPrefab(doer,"townportaltalisman",item_num * 6)                            
                        elseif index == 17 or index == 18 then
                            TBAT.FNS:GiveItemByPrefab(doer,"milkywhites",item_num * 8)                            
                        elseif index == 19 or index == 20 then
                            TBAT.FNS:GiveItemByPrefab(doer,"goose_feather",item_num * 5)                            
                        elseif index == 21 or index == 22 or index == 23 then
                            TBAT.FNS:GiveItemByPrefab(doer,"wagpunk_bits",item_num * 6)                            
                        end
                    end,
                },
            ------------------------------------------------------------------------
        }
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
}