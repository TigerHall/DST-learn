--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_ephemeral_flower"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_ephemeral_flower.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集
    local function onpickedfn(inst, picker)
        if picker then
            if picker.components.sanity then
                picker.components.sanity:DoDelta(10)
            end
            if picker.components.health then
                picker.components.health:DoDelta(5)
            end
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, 4,{"tbat_resources_memory_crystal_ore"})
        for k, v in pairs(ents) do
            v:PushEvent("flower_picked")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 蝴蝶刷新控制
    local function is_avalable_spawn_butterfly(inst)
        if TheWorld:HasTag("cave") then
            return true
        end
        if TheWorld.state.isday then
            return false
        end
        return true
    end
    local function onoccupied(inst)
        
    end
    local function OnVacated(inst, child)

    end
    local function onspawnedfn(inst, child)
        if not is_avalable_spawn_butterfly(inst) then
            child:Remove()
            return
        end
        child.flower = inst
        child.sg:GoToState("idle")
        child:ListenForEvent("onremove",function()
            child:PushEvent("cmd_fly_out")
        end,inst)
    end
    local function spawn_child_daily_task(inst)
        inst.spawned_child_today = false
    end
    local function spawn_child_fn(inst)
        if inst.spawned_child_today then
            return
        end
        if is_avalable_spawn_butterfly(inst) then
            local child = inst.components.spawner.child
            if child and child:IsValid() 
                and (child.components.inventoryitem == nil or child.components.inventoryitem.owner == nil)
                then
                    -- print("not need to spawn child")
            else
                inst.components.spawner:ReleaseChild()
                inst.spawned_child_today = true
            end
        end
    end
    local function spawn_child_task(inst)
        inst:DoTaskInTime(0, spawn_child_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_plant_ephemeral_flower")
        inst.AnimState:SetBuild("tbat_plant_ephemeral_flower")
        inst.AnimState:PlayAnimation("idle"..math.random(4))
        inst.AnimState:SetRayTestOnBB(true)
        inst.AnimState:SetScale(math.random() < 0.1 and 1 or -1, 1, 1)
        inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2) --butterfly deployspacing/2
        inst:AddTag("flower")
        inst:AddTag("tbat_plant_ephemeral_flower")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        --------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------
        --- 采集
            inst:AddComponent("pickable")
            inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
            inst.components.pickable:SetUp("tbat_food_ephemeral_flower", 10)
            inst.components.pickable.onpickedfn = onpickedfn
            inst.components.pickable.remove_when_picked = true
            inst.components.pickable.quickpick = true
            inst.components.pickable.wildfirestarter = true
        --------------------------------------------------------------------
        --- 可燃、作祟
            MakeSmallBurnable(inst)
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------------
        --- 刷蝴蝶
            inst:AddComponent("spawner")
            -- WorldSettings_Spawner_SpawnDelay(inst,100000,true)
            inst.components.spawner:Configure("tbat_animal_ephemeral_butterfly",100000)
            inst.components.spawner:SetOnOccupiedFn(onoccupied)
            inst.components.spawner:SetOnVacateFn(OnVacated)
            inst.components.spawner.onspawnedfn = onspawnedfn
            inst:WatchWorldState("phase",spawn_child_task)
            inst:WatchWorldState("cycles",spawn_child_daily_task)
            inst:DoTaskInTime(1,spawn_child_task)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
