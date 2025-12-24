--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    移植的刺猬小仙

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local RADIUS = 30
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_hedgehog_cactus.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长
    local function grow_time_by_step(inst,step)
        if TBAT.DEBUGGING then
            return 1*TUNING.TOTAL_DAY_TIME
        end
        return 3*TUNING.TOTAL_DAY_TIME
    end
    local growable_stages = {
        --[[
        
            【笔记】 fn 先执行，再执行growfn ，onload的时候只执行 fn

        ]]--
        {
            name = "step1",     --- 阶段1  刚种下的时候
            time = function(inst) return grow_time_by_step(inst,1) end,
            growfn = function(inst)
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1",true)
                inst.components.growable:StartGrowing()
            end,    -- DoGrowth 的时候执行（时间到了）
            fn = function(inst)     -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1",true)
                inst.components.growable:StartGrowing()
            end,
        },
        {
            name = "step2", --- 阶段1  刚种下的时候
            time = function(inst) return grow_time_by_step(inst,1) end,
            growfn = function(inst) -- DoGrowth 的时候执行（时间到了）
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_1_to_2",false)
                inst.AnimState:PushAnimation("stage_2",true)
                inst.components.growable:StartGrowing()
            end,   
            fn = function(inst)     -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_2",true)
                inst.components.growable:StartGrowing()
            end,                                                     
        },
        {
            name = "step3",     --- 阶段2
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst:AddTag("has_fruit")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                inst.AnimState:PlayAnimation("stage_2_to_3",false)
                inst.AnimState:PushAnimation("stage_3",true)
            end,
            fn = function(inst)
                inst:AddTag("has_fruit")
                inst.AnimState:PlayAnimation("stage_3",true)
            end,
        },
    }
    local function picked_event(inst)
        inst.AnimState:PlayAnimation("stage_3_to_2",false)
        inst.__picked_event = inst.__picked_event or function()
            inst.components.growable:SetStage(2)
            inst:RemoveEventCallback("animover",inst.__picked_event)
        end
        inst:ListenForEvent("animover",inst.__picked_event)
    end
    local function grow_state_init(inst)
        if inst.components.growable:GetStage() == 3 then
            inst.components.growable:StopGrowing()
        else
            inst.components.growable:StartGrowing()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品拾取
    local function workable_test_fn(inst,doer,right_click)
        local replica_com = inst.replica._.tbat_com_workable
        if inst:HasTag("has_fruit") then
            replica_com:SetSGAction("dolongaction")
            replica_com:SetText("tbat_plant_wild_hedgehog_cactus",STRINGS.ACTIONS.PICK.GENERIC)
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        inst:PushEvent("plant_on_pick")
        -- doer.components.inventory:GiveItem(SpawnPrefab("tbat_plant_hedgehog_cactus_seed"))
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_food_hedgehog_cactus_meat"))
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_food_hedgehog_cactus_meat"))
        return true
    end

    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_plant_wild_hedgehog_cactus",STRINGS.ACTIONS.PICK.GENERIC)
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
--- offical workable
    local function onhammered(inst, worker)
        inst.components.lootdropper:SpawnLootPrefab("tbat_plant_hedgehog_cactus_seed")
        inst.components.lootdropper:SpawnLootPrefab("tbat_plant_hedgehog_cactus_pot")
        inst:Remove()
    end
    local function official_workable_install(inst)
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)
        -- inst.components.workable:SetOnWorkCallback(onhit)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 照顾植物
    local function take_care_single_plant(inst,plant)
        ---------------------------------------------------------------
        ---- 施肥
            if plant.components.pickable then
                if plant.components.pickable:CanBeFertilized() then
                    local item = SpawnPrefab("compost")
                    plant.components.pickable:Fertilize(item)
                    item:Remove()
                end
                if plant.components.pickable:IsBarren() then
                    plant.components.pickable:MakeEmpty()
                end
            end
        ---------------------------------------------------------------
        ---- 照顾植物
            if plant.components.farmplanttendable ~= nil then
                plant.components.farmplanttendable:TendTo(inst)
            end
        ---------------------------------------------------------------
    end
    local function take_care_farm_plants_task(inst)
        if inst.components.growable:GetStage() == 1 then
            return
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,0,z, RADIUS)
        for k, tempInst in pairs(ents) do
            if tempInst:IsValid() and tempInst.prefab then
                take_care_single_plant(inst,tempInst)
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function plant_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_plant_hedgehog_cactus")
        inst.AnimState:SetBuild("tbat_plant_hedgehog_cactus")
        inst.AnimState:PlayAnimation("stage_1",true)
        inst:SetDeploySmartRadius(0.5)
        inst.entity:SetPristine()
        workable_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(1)
        inst.components.growable.loopstages = false
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = false
        inst:ListenForEvent("plant_on_pick",picked_event)
        inst:DoTaskInTime(0,grow_state_init)

        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")
        official_workable_install(inst)

        inst:DoPeriodicTask(10,take_care_farm_plants_task,math.random(30))
        inst:ListenForEvent("entitywake",take_care_farm_plants_task)

        inst:AddComponent("tbat_com_wild_fire_blocker")
        inst.components.tbat_com_wild_fire_blocker:SetRadius(RADIUS)
        inst:AddComponent("tbat_com_witherable_blocker")
        inst.components.tbat_com_witherable_blocker:SetRadius(RADIUS)

        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_plant_hedgehog_cactus", plant_fn, assets)
