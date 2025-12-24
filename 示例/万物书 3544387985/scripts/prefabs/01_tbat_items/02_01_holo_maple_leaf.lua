--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_item_holo_maple_leaf"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_holo_maple_leaf.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item use to com    
    local function item_use_to_test_fn(inst,target,doer,right_click)
        return right_click and target and target.prefab
    end
    local function item_use_to_active_fn(inst,target,doer)
        -----------------------------------------------------------------------------------------------------
        ---
            inst.components.stackable:Get():Remove()
        -----------------------------------------------------------------------------------------------------
        ---
            local item = SpawnPrefab("tbat_item_holo_maple_leaf_packed")
            item:PushEvent("Remember",target)
            doer.components.inventory:GiveItem(item)
        -----------------------------------------------------------------------------------------------------
        return true
    end
    local function item_use_to_com_replica_init(inst,replica_com)
        replica_com:SetTestFn(item_use_to_test_fn)
        replica_com:SetDistance(15)
        replica_com:SetText(this_prefab,TBAT:GetString2(this_prefab,"action_str"))
    end
    local function item_use_to_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_item_use_to",item_use_to_com_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_item_use_to")
        inst.components.tbat_com_item_use_to:SetActiveFn(item_use_to_active_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:PlayAnimation("water")
        else
            inst.AnimState:Show("SHADOW")
            inst.AnimState:PlayAnimation("idle")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_holo_maple_leaf")
        inst.AnimState:SetBuild("tbat_item_holo_maple_leaf")
        inst.AnimState:PlayAnimation("idle")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        item_use_to_com_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_item_holo_maple_leaf","images/inventoryimages/tbat_item_holo_maple_leaf.xml")
        inst:ListenForEvent("on_landed",item_onland_event)
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
