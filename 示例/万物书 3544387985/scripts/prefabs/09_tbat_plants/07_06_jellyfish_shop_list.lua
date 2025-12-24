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
    ---- 常规兑换列表
        comm_list = {
            -- ["log"] = { prefab = "boards", num = 1},
            ["tbat_plant_coconut_cat_fruit"] = { prefab = "tbat_plant_coconut_tree_seed", num = 1},   --- 【清甜椰子】可以兑换【发芽的清甜椰子】
            ["tbat_turf_water_lily_cat_leaf"] = { prefab = "tbat_turf_water_lily_cat_seed", num = 1},   --- 【睡莲猫猫莲叶】可以兑换【睡莲猫猫子株】
            ["tbat_food_hedgehog_cactus_meat"] = { prefab = "tbat_plant_hedgehog_cactus_seed", num = 1},   --- 【小仙肉】可以兑换【小仙种子】
            ["tbat_material_dandelion_umbrella"] = { prefab = "tbat_material_wish_token", num = 1},   --- 【小仙蒲公英花伞】可以兑换【祈愿牌】
            ["tbat_material_squirrel_incisors"] = { prefab = "tbat_material_sunflower_seeds", num = 1},   --- 【松鼠牙】可以兑换【葵瓜子】
            ["tbat_material_liquid_of_maple_leaves"] = { prefab = "tbat_material_sunflower_seeds", num = 1},   --- 【枫液】可以兑换【葵瓜子】
            ["tbat_material_snow_plum_wolf_hair"] = { prefab = "tbat_material_white_plum_blossom", num = 1},   --- 【狼毛】可以兑换【白梅花】
            ["tbat_food_fantasy_apple"] = { prefab = "tbat_food_fantasy_apple_seeds", num = 1},   --- 苹果 种子兑换
            ["tbat_food_fantasy_peach"] = { prefab = "tbat_food_fantasy_peach_seeds", num = 1},   --- 桃子 种子兑换
            ["tbat_food_fantasy_potato"] = { prefab = "tbat_food_fantasy_potato_seeds", num = 1},   --- 土豆 种子兑换
        },
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---- 特殊兑换列表 : 遍历所有 。和上面的权限并联
        special_list = {
            ------------------------------------------------------------------------
            --- 示例。
                {
                    test = function(inst,item,doer)
                        if TBAT.DEBUGGING and item.prefab == "log" then
                            return true
                        end
                    end,
                    fn = function(inst,item,doer,item_num,remove_blocker_callback)
                        TBAT.FNS:GiveItemByPrefab(doer,"boards",10)
                    end,
                },
            ------------------------------------------------------------------------
            --- 蒲公英猫花朵可以兑换蒲公英猫植株（1%的概率额外给予一个伴生水母素）
                {
                    test = function(inst,item,doer)
                        if item.prefab == "tbat_material_dandycat" then
                            return true
                        end
                    end,
                    fn = function(inst,item,doer,item_num,remove_blocker_callback)
                        TBAT.FNS:GiveItemByPrefab(doer,"tbat_plant_dandycat_kit",item_num)
                        for i = 1, item_num, 1 do                            
                            if math.random(1000)/1000 <= 0.01 or TBAT.DEBUGGING then
                                TBAT.FNS:GiveItemByPrefab(doer,"tbat_item_jellyfish_in_bottle",1)
                            end
                        end
                    end,
                },
            ------------------------------------------------------------------------
            --- 3.任意笔记*1可以跟水母交换翠羽鸟的羽毛
                {
                    test = function(inst,item,doer)
                        if item:HasTag("tbat_item_notes_of_adventurer") then
                            return true
                        end
                    end,
                    fn = function(inst,item,doer,item_num,remove_blocker_callback)
                        TBAT.FNS:GiveItemByPrefab(doer,"tbat_material_emerald_feather",item_num)                        
                    end,
                },
            ------------------------------------------------------------------------
            --- 解锁农作物图鉴
                {
                    test = function(inst,item,doer)
                        local LIST = {
                            ["tbat_food_fantasy_apple"] = "tbat_farm_plant_fantasy_apple_mutated",
                            ["tbat_food_fantasy_peach"] = "tbat_farm_plant_fantasy_peach_mutated",
                            ["tbat_food_fantasy_potato"] = "tbat_farm_plant_fantasy_potato_mutated",
                        }
                        if LIST[item.prefab] then
                            return true
                        end
                        return false
                    end,
                    fn = function(inst,item,doer,item_num,remove_blocker_callback)
                        local LIST = {
                            ["tbat_food_fantasy_apple"] = "tbat_farm_plant_fantasy_apple_mutated",
                            ["tbat_food_fantasy_peach"] = "tbat_farm_plant_fantasy_peach_mutated",
                            ["tbat_food_fantasy_potato"] = "tbat_farm_plant_fantasy_potato_mutated",
                        }
                        local ret_plant = LIST[item.prefab]
                        TBAT.FNS:RPC_PushEvent(doer,"tbat_event.unlock_farm_plant_book_notes",ret_plant)
                    end,
                }
            ------------------------------------------------------------------------
        }
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
}