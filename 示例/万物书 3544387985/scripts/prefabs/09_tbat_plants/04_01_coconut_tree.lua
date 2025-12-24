--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_coconut_tree"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_coconut_tree.zip"),
        Asset("ANIM", "anim/tbat_plant_coconut_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- chop workable
    local function official_workable_uninstall(inst)
        if inst.components.workable then
            inst:RemoveComponent("workable")
        end
    end
    local function chop_OnFinishCallback(inst, worker)
        inst.components.growable:StopGrowing()
        -- inst:Remove()
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst.AnimState:PlayAnimation("chop_burnt_finish")
        inst.AnimState:PushAnimation("chop_burnt_pst",false)
        inst:ListenForEvent("animqueueover",function()
            inst.components.lootdropper:SpawnLootPrefab("charcoal")
            inst:Remove()
        end)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    end
    local function official_workable_chop_install(inst)
        official_workable_uninstall(inst)        
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(chop_OnFinishCallback)
        -- inst.components.workable:SetOnWorkCallback(onhit)
    end
    local function dig_OnFinishCallback(inst, worker)
        inst:Remove()
    end
    local function official_workable_dig_install(inst)
        official_workable_uninstall(inst)        
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(dig_OnFinishCallback)
        -- inst.components.workable:SetOnWorkCallback(onhit)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- burnt com install
    local function onburntup(inst)
        inst.components.growable:SetStage(1)
    end
    local function burnt_com_uninstall(inst)
        if inst.components.burnable then
            inst:RemoveComponent("burnable")
        end
        if inst.components.propagator then
            inst:RemoveComponent("propagator")
        end
        inst:RemoveEventCallback("burntup",onburntup)
    end
    local function burnt_com_install(inst)
        burnt_com_uninstall(inst)
        MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(onburntup)
        MakeMediumPropagator(inst)
        inst:ListenForEvent("burntup", onburntup)   --- 烧完
        -- inst:ListenForEvent("onignite", onignite)   --- 冒烟
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长
    local function grow_time_by_step(inst,step)
        if TBAT.DEBUGGING then
            return 1*TUNING.TOTAL_DAY_TIME + 5
        end
        return 3*TUNING.TOTAL_DAY_TIME
    end
    local growable_stages = {
        --[[
        
            【笔记】 fn 先执行，再执行growfn ，onload的时候只执行 fn

        ]]--
        {
            name = "burnt",     --- 阶段2
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst:AddTag("burnt")
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("burnt",false)
                -- inst.components.growable:StopGrowing()
                -- burnt_com_uninstall(inst)
                -- official_workable_chop_install(inst)
            end,
            fn = function(inst)
                inst:AddTag("burnt")
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("burnt",true)
                inst.components.growable:StopGrowing()
                burnt_com_uninstall(inst)
                official_workable_chop_install(inst)
            end,
        },
        {
            name = "stage_1",     --- 阶段1  刚种下的时候
            time = function(inst) return grow_time_by_step(inst,1) end,
            growfn = function(inst)
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1",true)
            end,    -- DoGrowth 的时候执行（时间到了）
            fn = function(inst)     -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1",true)
                inst.components.growable:StartGrowing()
                burnt_com_uninstall(inst)
                official_workable_dig_install(inst)
            end,
        },
        {
            name = "stage_2", --- 
            time = function(inst) return grow_time_by_step(inst,1) end,
            growfn = function(inst) -- DoGrowth 的时候执行（时间到了）
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1_to_2",false)
                inst.AnimState:PushAnimation("stage_2",true)
                inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            end,   
            fn = function(inst)     -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_2",true)
                inst.components.growable:StartGrowing()
                burnt_com_install(inst)
                official_workable_uninstall(inst)
            end,                                                     
        },
        {
            name = "stage_3",     --- 阶段2
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst:AddTag("has_fruit")
                -- inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                inst.AnimState:PlayAnimation("stage_2_to_3",false)
                inst.AnimState:PushAnimation("stage_3",true)
                inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            end,
            fn = function(inst)
                inst:AddTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_3",true)
                inst.components.growable:StopGrowing()
                burnt_com_install(inst)
                official_workable_uninstall(inst)
            end,
        },

    }
    local function grow_state_init(inst)
        local stage = inst.components.growable:GetStage()
        if stage == 1 or stage == 4 then
            inst.components.growable:StopGrowing()
        else
            inst.components.growable:StartGrowing()
        end
    end
    local function growable_com_install(inst)
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(3)
        inst.components.growable.loopstages = false
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = false
        -- inst:ListenForEvent("plant_on_pick",picked_event)
        inst:DoTaskInTime(0,grow_state_init)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品拾取
    local function workable_test_fn(inst,doer,right_click)
        local replica_com = inst.replica._.tbat_com_workable
        if inst:HasTag("has_fruit") then
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        -- inst:PushEvent("plant_on_pick")
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_plant_coconut_cat_fruit"))
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_food_cocoanut"))
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_food_cocoanut"))
        inst.components.growable:SetStage(3)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
        return true
    end

    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICK.GENERIC)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetDistance(1)
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 雷劈
    local function lighting_task(inst)
        local stage = inst.components.growable:GetStage()
        if TheWorld.state.israining and not TheWorld:HasTag("cave") and (stage == 3 or stage == 4) and not inst.components.burnable:IsBurning() and math.random() < 0.3  then
            local x,y,z = inst.Transform:GetWorldPosition()
            TheWorld:PushEvent("ms_sendlightningstrike", Vector3(x,y,z))
        end
    end
    local function lighting_event_install(inst)
        inst:DoPeriodicTask(20,lighting_task,math.random(30))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.AnimState:SetBank("tbat_plant_coconut_tree")
        inst.AnimState:SetBuild("tbat_plant_coconut_tree")
        inst.AnimState:PlayAnimation("stage_1",true)

        inst.entity:SetPristine()
        -----------------------------------------------
        ---
            workable_install(inst)
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
        --- 生长
            growable_com_install(inst)
        -----------------------------------------------
        --- 雷劈
            lighting_event_install(inst)
        -----------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
