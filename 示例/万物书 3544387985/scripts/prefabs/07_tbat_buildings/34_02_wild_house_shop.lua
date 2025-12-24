--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_building_forest_mushroom_cottage_wild"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语
    local function WhisperTo_Origin(player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = "tbat_animal_mushroom_snail" ,
            sender_name = TBAT:GetString2("tbat_animal_mushroom_snail","name"),
            s_colour = {252/255,246/255,231/255},
            message = str,
            m_colour = {255/255,186/255,181/255},
        })
    end
    local function WhisperTo(player_or_userid,str)
        TheWorld:DoTaskInTime(1,function()
            WhisperTo_Origin(player_or_userid,str)
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local cmd_data = {
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ---- 常规兑换列表
            comm_list = {
                -- ["log"] = { prefab = "boards", num = 1},
                -- ["tbat_plant_coconut_cat_fruit"] = { prefab = "tbat_plant_coconut_tree_seed", num = 1},   --- 【清甜椰子】可以兑换【发芽的清甜椰子】
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
                --- 当玩家给予蘑菇小窝一个森伞小菇，小窝会触发台词：它会永远保护我们~ 并掉落【勇者之誓】的知识点
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_sensangu_item" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            doer.components.tbat_com_mushroom_snail_cauldron__for_player:Unlock("tbat_item_oath_of_courage_potion")
                            WhisperTo(doer,TBAT:GetString2(this_prefab,"item_accepted.tbat_sensangu_item"))
                        end,
                    },
                ------------------------------------------------------------------------
                --- 当玩家制作药剂【勇者之誓】给予蘑菇小窝后，小窝会触发台词：冒险家你要保护好自己.并掉落【知识之纱】的知识点
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_item_oath_of_courage_potion" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            doer.components.tbat_com_mushroom_snail_cauldron__for_player:Unlock("tbat_item_veil_of_knowledge_potion")
                            WhisperTo(doer,TBAT:GetString2(this_prefab,"item_accepted.tbat_item_oath_of_courage_potion"))
                        end,
                    },
                ------------------------------------------------------------------------
                --- 当玩家制作药剂【知识之纱】给予蘑菇小窝后，小窝会触发台词：覆纱的眼，看见万物低语 .  并掉落【愿望之笺】的知识点，【小蜗护甲】蓝图
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_item_veil_of_knowledge_potion" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            doer.components.tbat_com_mushroom_snail_cauldron__for_player:Unlock("tbat_item_wish_note_potion")
                            WhisperTo(doer,TBAT:GetString2(this_prefab,"item_accepted.tbat_item_veil_of_knowledge_potion"))
                            --- 蓝图 【小蜗护甲】蓝图
                            doer.components.inventory:GiveItem(SpawnPrefab("tbat_eq_snail_shell_of_mushroom_blueprint2"))
                        end,
                    },
                ------------------------------------------------------------------------
                --- 当玩家制作药剂【愿望之笺】给予蘑菇小窝后，小窝会触发台词：愿望藏进信笺，你要走向星光 .并掉落【幸运之语】的知识点，【森林蘑菇小窝】的蓝图
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_item_wish_note_potion" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            doer.components.tbat_com_mushroom_snail_cauldron__for_player:Unlock("tbat_item_lucky_words_potion")
                            WhisperTo(doer,TBAT:GetString2(this_prefab,"item_accepted.tbat_item_wish_note_potion"))
                            --- 蓝图 【森林蘑菇小窝】的蓝图
                            doer.components.inventory:GiveItem(SpawnPrefab("tbat_building_forest_mushroom_cottage_blueprint2"))
                        end,
                    },
                ------------------------------------------------------------------------
                --- 当玩家制作药剂【幸运之语】给予蘑菇小窝后，小窝会触发台词：命运温柔的笔迹，把幸运馈赠给你们 。 并掉落【森伞小菇】*4，【蘑菇小蜗埚】的蓝图
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_item_lucky_words_potion" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            WhisperTo(doer,TBAT:GetString2(this_prefab,"item_accepted.tbat_item_lucky_words_potion"))
                            --- 蓝图 【蘑菇小蜗埚】的蓝图
                            doer.components.inventory:GiveItem(SpawnPrefab("tbat_container_mushroom_snail_cauldron_blueprint2"))
                            --- 物品 并掉落【森伞小菇】*4，
                            TBAT.FNS:GiveItemByPrefab(doer,"tbat_sensangu_item",4)
                        end,
                    },
                ------------------------------------------------------------------------
            }
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function acceptable_test_fn(inst,item,doer,right_click)
        if cmd_data.comm_list[item.prefab] then
            return true
        end
        for i,temp_data in ipairs(cmd_data.special_list) do
            if temp_data and temp_data.test(inst,item,doer) then
                return true
            end
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        ---
        --------------------------------------------------
        ---
            local item_num = 1
            if item.components.stackable then
                item = item.components.stackable:Get(1)
            end
        --------------------------------------------------
        --- 普通物品
            local comm_data = cmd_data.comm_list[item.prefab]
            if comm_data then
                local ret_prefab = comm_data.prefab
                local num = comm_data.num or 1
                TBAT.FNS:GiveItemByPrefab(doer,ret_prefab, num*item_num)
            end
        --------------------------------------------------
        ---
            local remove_blocker_callback = {}
            for i,temp_data in ipairs(cmd_data.special_list) do
                if temp_data and temp_data.test(inst,item,doer) and temp_data.fn then
                    temp_data.fn(inst,item,doer,item_num,remove_blocker_callback)
                end
            end
        --------------------------------------------------
        ---
            if not remove_blocker_callback.blocker_remove then
                item:Remove()
            end
        --------------------------------------------------
        ---
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ADDCOMPOSTABLE)
        replica_com:SetSGAction("give")
        replica_com:SetTestFn(acceptable_test_fn)
    end

    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return acceptable_com_install