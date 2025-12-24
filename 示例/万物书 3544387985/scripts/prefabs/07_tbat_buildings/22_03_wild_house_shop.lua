--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_building_maple_squirrel_pet_house_wild"
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
                --- 蒲公英猫花朵可以兑换蒲公英猫植株（1%的概率额外给予一个伴生水母素）
                    {
                        test = function(inst,item,doer)
                            if item.prefab == "tbat_material_sunflower_seeds" then
                                return true
                            end
                        end,
                        fn = function(inst,item,doer,item_num,remove_blocker_callback)
                            local rand = math.random(1000)/1000
                            if rand < 0.4 then
                                TBAT.FNS:GiveItemByPrefab(doer,"tbat_item_holo_maple_leaf",1)
                            elseif rand < 0.8 then
                                TBAT.FNS:GiveItemByPrefab(doer,"tbat_material_squirrel_incisors",1)
                            else
                                TBAT.FNS:GiveItemByPrefab(doer,"tbat_plant_crimson_maple_tree_kit",1)    
                            end
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
            if not TheWorld.state.isday then
                ---------------------------------------------------------
                --- 每晚只出一次。
                    if inst:HasTag("trade_blocking") then
                        return false,"work_fail"
                    end
                    inst:AddTag("trade_blocking")
                    local temp_inst = CreateEntity()
                    temp_inst:WatchWorldState("cycles",function()
                        temp_inst:Remove()
                        inst:RemoveTag("trade_blocking")
                    end)
                ---------------------------------------------------------
                inst:PushEvent("force_spawn_cat")
                local monster = inst.components.leader:GetFollowersByTag("tbat_animal_maple_squirrel")[1]
                if monster then
                   monster.components.combat:SuggestTarget(doer) 
                end
                return false,"work_night"
            end
        --------------------------------------------------
        --- 次数够了
            if inst.components.tbat_data:Add("traded",0) >= 3 then
                return false,"work_fail"
            end
        --------------------------------------------------
        ---
            local item_num = 1
            if item.components.stackable then
                -- item_num = item.components.stackable:StackSize()
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
            inst.components.tbat_data:Add("traded",1)
        --------------------------------------------------
        return false,"work_succeed"
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ADDCOMPOSTABLE)
        replica_com:SetSGAction("give")
        replica_com:SetTestFn(acceptable_test_fn)
    end

    local function daily_rest_task(inst)
        inst.components.tbat_data:Set("traded",0)
    end

    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)

        inst:AddComponent("tbat_com_action_fail_reason")
        inst.components.tbat_com_action_fail_reason:Add_Reason("work_succeed",TBAT:GetString2(this_prefab,"work_succeed"))
        inst.components.tbat_com_action_fail_reason:Add_Reason("work_night",TBAT:GetString2(this_prefab,"work_night"))
        inst.components.tbat_com_action_fail_reason:Add_Reason("work_fail",TBAT:GetString2(this_prefab,"work_fail"))
    
        inst:WatchWorldState("cycles",daily_rest_task)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return acceptable_com_install