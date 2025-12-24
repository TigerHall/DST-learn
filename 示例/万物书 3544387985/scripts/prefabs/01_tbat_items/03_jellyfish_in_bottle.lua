--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_jellyfish_in_bottle.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_use_to_test_fn(inst,target,doer,right_click)
        return target.prefab == "tbat_plant_dandycat"
    end
    local function item_use_to_active_fn(inst,target,doer)
        local call_back_table = {}
        target:PushEvent("bottle_get",call_back_table)
        if call_back_table.succeed then
            inst.components.stackable:Get():Remove()
            return true
        else
            return false,"item_fail"
        end
    end
    local function item_use_to_com_replica_init(inst,replica_com)
        replica_com:SetTestFn(item_use_to_test_fn)
        replica_com:SetText("tbat_item_jellyfish_in_bottle",STRINGS.ACTIONS.APPLYCONSTRUCTION.OFFER)
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
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
        else                                
            inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_jellyfish_in_bottle")
        inst.AnimState:SetBuild("tbat_item_jellyfish_in_bottle")
        inst.AnimState:PlayAnimation("item")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        item_use_to_com_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        -------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_jellyfish_in_bottle","images/inventoryimages/tbat_item_jellyfish_in_bottle.xml")
        -------------------------------------------------
            inst:AddComponent("stackable")
            -- inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM
        -------------------------------------------------
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
        --- 交互失败
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("item_fail",TBAT:GetString2("tbat_item_jellyfish_in_bottle","item_fail"))
        -------------------------------------------------
        MakeHauntableLaunch(inst)

        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_item_jellyfish_in_bottle", fn, assets)
