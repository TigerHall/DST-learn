--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    变异的植物

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_farm_plant_fantasy_apple_mutated"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_farm_plant_fantasy_apple.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local GROW_DATA = {
        [1] = {     -- seed   刚刚种下
            index = "seed",
            loot = {{"tbat_food_fantasy_apple_mutated_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [2] = {     -- sprout  发芽
            index = "sprout",
            loot = {{"tbat_food_fantasy_apple_mutated_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [3] = {     -- small  生长中
            index = "small",
            loot = {{"tbat_food_fantasy_apple_mutated_seed"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [4] = {     -- med  生长中
            index = "med",
            loot = {{"tbat_food_fantasy_apple",2}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
        },
        [5] = {     -- full  结果
            index = "full",
            loot = {
                {"tbat_food_fantasy_apple",6},
                {"meat",2},
                {"tbat_food_fantasy_apple_mutated_seed"},
            },
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 3*TUNING.TOTAL_DAY_TIME,
            picked_fn = function(inst, picker, loot)
                -- inst.components.growable:SetStage(3)
                -- inst.components.growable:StartGrowing()
                inst:Remove()
            end,
        },
        [6] = {     -- oversized 巨大化
            index = "oversized",
            loot = {
                {"tbat_food_fantasy_apple",10},
                {"meat",4},
                {"tbat_food_fantasy_apple_mutated_seed",2},
            },
            pick_loot = {{"tbat_eq_fantasy_apple_mutated_oversized"}},
            time = TBAT.DEBUGGING and (TUNING.TOTAL_DAY_TIME - 10) or 10*TUNING.TOTAL_DAY_TIME,
            picked_fn = function(inst, picker, loot)
                inst:Remove()
            end,
        },
        [7] = {     -- rot 腐烂
            index = "rot",
            loot = {
                {"tbat_food_fantasy_apple_mutated_seed",2},
                {"spoiled_food",5},
            },
            time = nil,
            picked_fn = function(inst, picker, loot)
                inst:Remove()
            end,
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
        return ret_loot_table
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- chop workable
    local function workable_OnFinishCallback(inst, worker)
        local current_stage = inst.components.growable:GetStage()
        local ret_loot_table = loot_update_fn(inst,current_stage,false)
        inst.components.lootdropper:SetLoot(ret_loot_table)
        inst.components.lootdropper:DropLoot()
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
        inst.components.lootdropper:SetLoot(ret_loot_table)
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
            name = "seed",
            time = function(inst) return grow_time_by_step(inst,1) end, --到下一个阶段的事件
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_seed",false)
                inst.AnimState:PushAnimation("crop_seed",true)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_seed",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,1)
            end,
        },
        {
            name = "sprout",
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_sprout",false)
                inst.AnimState:PushAnimation("crop_sprout",true)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_sprout",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,2)
            end,
        },
        {
            name = "small",
            time = function(inst) return grow_time_by_step(inst,3) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_small",false)
                inst.AnimState:PushAnimation("crop_small",true)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_small",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,3)
            end,
        },
        {
            name = "med",
            time = function(inst) return grow_time_by_step(inst,4) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_med",false)
                inst.AnimState:PushAnimation("crop_med",true)
            end,   
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_med",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,4)
            end,                                                     
        },
        {
            name = "full",
            time = function(inst) return grow_time_by_step(inst,5) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_full",false)
                inst.AnimState:PushAnimation("crop_full",true)
                inst.SoundEmitter:PlaySound("farming/common/farm/grow_full")
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_full",true)
                inst.components.workable:SetWorkAction(ACTIONS.DIG)
                pick_loot_update(inst,5)
            end,
        },
        {
            name = "oversized",
            time = function(inst) return grow_time_by_step(inst,6) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_oversized_mutated",false)
                inst.AnimState:PushAnimation("crop_oversized_mutated",true)
                inst.SoundEmitter:PlaySound("farming/common/farm/grow_oversized")
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_oversized_mutated",true)
                inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
                pick_loot_update(inst,6)
            end,
        },
        {
            name = "rot",
            time = function(inst) return grow_time_by_step(inst,7)  end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("grow_rot_oversized_mutated",false)
                inst.AnimState:PushAnimation("crop_rot_oversized_mutated",true)
                inst.SoundEmitter:PlaySound("farming/common/farm/rot")
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("crop_rot_oversized_mutated",true)
                inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
                pick_loot_update(inst,7)
            end,
        },

    }
    local function grow_state_init(inst)

    end
    local function growable_com_install(inst)
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(5)
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- on plant
    local function on_plant_event_fn(inst,data)
        if data.pt then
            inst.Transform:SetPosition(data.pt:Get())
        end
        inst.components.growable:SetStage(1)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 切换
    local function on_switch(inst,target)
        local x,y,z = target.Transform:GetWorldPosition()
        target:Remove()
        inst.Transform:SetPosition(x,y,z)
        inst.components.growable:SetStage(6)
        growable_stages[6].growfn(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
		inst:SetDeploySmartRadius(0.5) --match visuals, seeds use CUSTOM spacing
        inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)
        inst.AnimState:SetBank("tbat_farm_plant_fantasy_apple")
        inst.AnimState:SetBuild("tbat_farm_plant_fantasy_apple")
        inst.AnimState:PlayAnimation("crop_seed",true)
        inst:AddTag("plant")
        inst.entity:SetPristine()
        -----------------------------------------------
        ---
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
            inst:ListenForEvent("OnSwitch",on_switch)
        -----------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
