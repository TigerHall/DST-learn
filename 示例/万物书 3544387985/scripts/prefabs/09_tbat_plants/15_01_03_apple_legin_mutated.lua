--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    变异的植物

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_mutated_fantasy_apple"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_mutated_fantasy_apple.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local GROW_DATA = {
        [1] = {     -- sprout  发芽
            index = "sprout",
            loot = {{"tbat_plant_mutated_fantasy_apple_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [2] = {    -- small  生长中
            index = "small",
            loot = {{"tbat_plant_mutated_fantasy_apple_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [3] = {     -- med  生长中
            index = "med",
            loot = {{"tbat_plant_mutated_fantasy_apple_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [4] = {     -- full  结果
            index = "full",
            loot = {{"tbat_food_fantasy_apple",6},{"meat",2}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
            picked_fn = function(inst, picker, loot)
                inst.components.growable:SetStage(2)
                inst.components.growable:StartGrowing()
            end,
            ex_loot = {{"tbat_plant_mutated_fantasy_apple_seed"}},
        },
    }
    --- 转置一下
    local GROW_DATA_IDX = {}
    for k, v in pairs(GROW_DATA) do
        GROW_DATA_IDX[v.index] = v
        v.stage = k
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 更新掉落列表
    local function loot_update_fn(inst,current_stage,pick_action) 
        local STAGE_CMD = GROW_DATA[current_stage] or {}
        local LOOT_CMD = pick_action and STAGE_CMD.pick_loot or STAGE_CMD.loot
        local ret_loot_table = {}
        for k, tempCMD in pairs(LOOT_CMD) do
            local num = tempCMD[2] or 1
            local prefab = tempCMD[1]
            if PrefabExists(prefab) then
                for i = 1, num, 1 do
                    table.insert(ret_loot_table,prefab)                    
                end
            end
        end
        if not pick_action then
            local ex_loot = STAGE_CMD.ex_loot
            if ex_loot ~= nil then
                for k, tempCMD in pairs(ex_loot) do
                    local num = tempCMD[2] or 1
                    local prefab  = tempCMD[1]
                    if PrefabExists(prefab) then
                        for i = 1, num, 1 do
                            table.insert(ret_loot_table,prefab)
                        end
                    end
                end
            end
        end
        return ret_loot_table
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- chop workable
    local function workable_OnFinishCallback(inst, worker)
        local current_stage = inst.components.growable:GetStage()
        local ret_loot_table = loot_update_fn(inst,current_stage,false)
        inst.components.lootdropper:SetLoot(ret_loot_table)
        inst.components.lootdropper:DropLoot()
        --------------------------------------------------------
        --- 返还叠加的种子
            -- local level  = inst.components.tbat_data:Get("cluster") or 1
            -- if level > 1 then
            --     if worker:HasTag("player") then
            --         TBAT.FNS:GiveItemByPrefab(worker, this_prefab.."_seed", level-1)
            --     else
            --         for i = 2, level, 1 do
            --             inst.components.lootdropper:SpawnLootPrefab(this_prefab.."_seed")
            --         end
            --     end
            -- end
        --------------------------------------------------------
        inst:Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集
    local function pick_loot_update(inst,current_stage)
        local CMD = GROW_DATA[current_stage] or {}
        local picked_fn = CMD.picked_fn
        if picked_fn == nil then
            inst.components.pickable.canbepicked = false
            inst.components.lootdropper:SetLoot(nil)
            return
        end
        inst.components.pickable.canbepicked = true
        inst.components.pickable.onpickedfn = picked_fn
        local current_stage = inst.components.growable:GetStage()
        local ret_loot_table = loot_update_fn(inst,current_stage,true)
        -----------------------------------------
        --- 用来响应 簇计算 触发
            local call_back_table = {
                loot = ret_loot_table,
                new_loot = nil,
                stage = current_stage,
                loot_cmd_data = GROW_DATA[current_stage].loot,
            }
            inst:PushEvent("on_pick_loots_update",call_back_table)
            ret_loot_table = call_back_table.new_loot or call_back_table.loot
        -----------------------------------------
        inst.components.lootdropper:SetLoot(ret_loot_table)
    end
    local function pick_loot_force_update(inst)
        local current_stage = inst.components.growable:GetStage()
        pick_loot_update(inst,current_stage)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长
    local function grow_time_by_step(inst,current_step)
        return GROW_DATA[current_step].time
    end
    local growable_stages = {
        --[[
        
            【笔记】 fn 先执行，再执行growfn ，onload的时候只执行 fn
            【笔记】 time : 到下一个阶段的生长时间

        ]]--
        {
            name = "sprout",
            time = function(inst) return grow_time_by_step(inst,1) end, --到下一个阶段的事件
            growfn = function(inst)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_1_idle",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,1)
            end,
        },
        {
            name = "small",
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_1_to_2",false)
                inst.AnimState:PushAnimation("stage_2_idle",true)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_2_idle",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,2)
            end,
        },
        {
            name = "med",
            time = function(inst) return grow_time_by_step(inst,3) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_2_to_3",false)
                inst.AnimState:PushAnimation("stage_3_idle",true)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_3_idle",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,3)
            end,
        },
        {
            name = "full",
            time = function(inst) return grow_time_by_step(inst,4) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_3_to_4",false)
                inst.AnimState:PushAnimation("stage_4_idle",true)
            end,   
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_4_idle",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,4)
            end,                                                     
        },

    }
    local function grow_state_init(inst)

    end
    local function growable_com_install(inst)
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(4)
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 簇机制
    local legin_cluster_function_installer = require("prefabs/09_tbat_plants/15_00_legin_cluster_function_installer")    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- on plant
    local function on_plant_event_fn(inst,data)
        if data.pt then
            inst.Transform:SetPosition(data.pt:Get())
        end
        inst.components.growable:SetStage(1)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function plant_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
		inst:SetDeploySmartRadius(0.5) --match visuals, seeds use CUSTOM spacing
        inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)
        inst.AnimState:SetBank("tbat_plant_mutated_fantasy_apple")
        inst.AnimState:SetBuild("tbat_plant_mutated_fantasy_apple")
        inst.AnimState:PlayAnimation("stage_4_idle",true)
        inst:AddTag("plant")
        inst.entity:SetPristine()
        -----------------------------------------------
        ---
            legin_cluster_function_installer(inst,this_prefab.."_seed")
        -----------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------
        ---
            inst:AddComponent("lootdropper")
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
            TBAT.FNS:SnowInit(inst)
        -----------------------------------------------
        --- 直接敲坏、挖取
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(workable_OnFinishCallback)
        -----------------------------------------------
        --- 采集
            inst:AddComponent("pickable")
            inst.components.pickable.paused = true
            -- inst.components.pickable.onpickedfn = pickable_pickedfn
            inst.components.pickable.use_lootdropper_for_product = true
        -----------------------------------------------
        --- 生长
            growable_com_install(inst)
        -----------------------------------------------
        --- 烧焦
            MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
            inst.components.burnable:SetFXLevel(5)
            inst.components.burnable:SetOnBurntFn(inst.Remove)
            MakeMediumPropagator(inst)
        -----------------------------------------------
        --- 种植
            inst:ListenForEvent("OnPlant",on_plant_event_fn)
        -----------------------------------------------
        --- 强制更新掉落
            inst:ListenForEvent("pick_loot_force_update",pick_loot_force_update)
        -----------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- seed
    local function on_deploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        SpawnPrefab(this_prefab):PushEvent("OnPlant",{
            deployer = deployer,
            pt = pt,
        })        
    end
    local function seed_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank(this_prefab)
        inst.AnimState:SetBuild(this_prefab)
        inst.AnimState:PlayAnimation("item",true)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        -----------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_mutated_fantasy_apple_seed","images/inventoryimages/tbat_plant_mutated_fantasy_apple_seed.xml")
            MakeHauntableLaunch(inst)
        -----------------------------------------
        ---
            TBAT.FNS:ShadowInit(inst)
        -----------------------------------------
        ---
            inst:AddComponent("stackable")
        -----------------------------------------
        ---
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
            inst.components.deployable.ondeploy = on_deploy
            -- inst.components.deployable:SetDeploySpacing(0.1)
        -----------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local function placer_postinit_fn(inst)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, plant_fn, assets),
        Prefab(this_prefab.."_seed", seed_fn, assets),
        MakePlacer(this_prefab.."_seed_placer",this_prefab,this_prefab, "stage_1_idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)


