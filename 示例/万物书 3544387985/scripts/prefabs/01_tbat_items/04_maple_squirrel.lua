--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_maple_squirrel"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_maple_squirrel.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 回收
    local function workable_test_fn(inst,doer,right_click)        
        return right_click
    end
    local function workable_on_work_fn(inst,doer)
        doer.components.inventory:GiveItem(SpawnPrefab(this_prefab.."_kit"))
        inst:Remove()
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICKUP.GENERIC)
        replica_com:SetSGAction("doshortaction")
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
--- building fire
    local function create_fire(inst)
        local fx = inst:SpawnChild("campfirefire")
        fx.entity:SetParent(inst.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "slot", 0, 0, 0,true)
        fx.components.firefx:SetLevel(2)
        fx:Hide()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function create_fx(inst)
        local fx = inst:SpawnChild("tbat_sfx_maple_leaves_and_flames")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 建筑
    local function building_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_item_maple_squirrel")
        inst.AnimState:SetBuild("tbat_item_maple_squirrel")
        inst.AnimState:PlayAnimation("idle",true)
        inst.entity:SetPristine()
        workable_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("cooker")
        MakeHauntableLaunch(inst)
        inst:DoTaskInTime(0,create_fire)
        inst:DoTaskInTime(0,create_fx)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
        else                                
            inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品
    local function item_temperature_fn(inst)
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner:HasTag("player")
            and owner.components.temperature
            and owner.components.temperature:GetCurrent() < 20
            then
                -- owner.components.temperature:DoDelta(5)
                owner.components.temperature:SetTemperature(owner.components.temperature:GetCurrent() +5)

        end
    end
    local function on_deploy(inst, pt, deployer)
        local new_inst = SpawnPrefab(this_prefab)
        new_inst.Transform:SetPosition(pt.x, pt.y, pt.z)
        inst:Remove()
        SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(pt.x, pt.y, pt.z)
    end
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_maple_squirrel")
        inst.AnimState:SetBuild("tbat_item_maple_squirrel")
        inst.AnimState:PlayAnimation("item")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_maple_squirrel_kit","images/inventoryimages/tbat_item_maple_squirrel_kit.xml")
        -------------------------------------------------
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
            MakeHauntableLaunch(inst)
        -------------------------------------------------
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
            inst.components.deployable.ondeploy = on_deploy
        -------------------------------------------------
            inst:DoPeriodicTask(0.5,item_temperature_fn)
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets),
        Prefab(this_prefab.."_kit", item_fn, assets),
        MakePlacer(this_prefab.."_kit_placer",this_prefab,this_prefab,"idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

