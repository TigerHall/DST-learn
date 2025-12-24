--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
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
            fn = function(inst)                                                 -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst.components.growable:StartGrowing()
                inst.AnimState:PlayAnimation("stage_2",true)
            end,      
            growfn = function(inst)
                inst:RemoveTag("has_fruit")
            end,                                                        -- DoGrowth 的时候执行（时间到了）
        },
        {
            name = "step2",     --- 阶段2
            time = function(inst) return grow_time_by_step(inst,2) end,
            fn = function(inst)
                inst:AddTag("has_fruit")
                -- inst.components.growable:StopGrowing()
                inst.AnimState:PlayAnimation("stage_3",true)
            end,
            growfn = function(inst)
                inst:AddTag("has_fruit")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                -- inst.components.growable:StopGrowing()
                inst.AnimState:PlayAnimation("stage_2_to_3",false)
                inst.AnimState:PushAnimation("stage_3",true)
            end,
        },
    }
    local function picked_event(inst)
        inst.AnimState:PlayAnimation("stage_3_to_2",false)
        inst.__picked_event = inst.__picked_event or function()
            inst.components.growable:SetStage(1)
            inst:RemoveEventCallback("animover",inst.__picked_event)
        end
        inst:ListenForEvent("animover",inst.__picked_event)
    end
    local function init(inst)
        if inst.components.growable:GetStage() ~= 2 then
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
        if TBAT.DEBUGGING then
            doer.components.inventory:GiveItem(SpawnPrefab("tbat_plant_hedgehog_cactus_seed")) -- 测试期间给种子            
        end
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
--- 创建物品
    local function wild_plant_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_plant_hedgehog_cactus")
        inst.AnimState:SetBuild("tbat_plant_hedgehog_cactus")
        inst.AnimState:PlayAnimation("stage_2",true)
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
        inst:DoTaskInTime(0,init)
        inst:AddComponent("inspectable")
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- seed
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
        else
            inst.AnimState:Show("SHADOW")    
        end
    end
    local function seed_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_plant_hedgehog_cactus")
        inst.AnimState:SetBuild("tbat_plant_hedgehog_cactus")
        inst.AnimState:PlayAnimation("item_seed")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_plant_hedgehog_cactus_seed","images/inventoryimages/tbat_plant_hedgehog_cactus_seed.xml")
        MakeHauntableLaunch(inst)
        inst:ListenForEvent("on_landed",item_onland_event)
        inst:AddComponent("stackable")
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_plant_wild_hedgehog_cactus", wild_plant_fn, assets),
    Prefab("tbat_plant_hedgehog_cactus_seed", seed_fn, assets)
