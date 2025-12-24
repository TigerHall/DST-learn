--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_trans_core"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_trans_core.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 回收
    local function workable_test_fn(inst,doer,right_click)        
        return inst.replica.inventoryitem:IsGrandOwner(doer)
    end
    local function workable_pre_sg(inst,owner)
        if not TheWorld.ismastersim then
            return
        end
        if inst.fx then
            inst.fx:Remove()
        end
        local fx = SpawnPrefab(this_prefab.."_fx")
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object",0,0,0)
        inst.fx = fx
    end
    local function workable_on_work_fn(inst,doer)
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        local target = TheSim:FindFirstEntityWithTag("tbat_room_anchor_fantasy_island_main")
        if target == nil then
            return false
        end
        local x,y,z = target.Transform:GetWorldPosition()

        doer.components.playercontroller:RemotePausePrediction(5)
        z = z + 4
        doer.Transform:SetPosition(x,0,z)
        doer.Physics:Teleport(x,y,z)
        inst.components.stackable:Get():Remove()
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.REMOTE_TELEPORT.GENERIC)
        replica_com:SetSGAction("castspell")
        replica_com:SetPreActionFn(workable_pre_sg)
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
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            -- inst.AnimState:PlayAnimation("item_water")
        else                                
            -- inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_trans_core")
        inst.AnimState:SetBuild("tbat_item_trans_core")
        inst.AnimState:PlayAnimation("idle",true)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        -- inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        -------------------------------------------------
            workable_install(inst)
        -------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_trans_core","images/inventoryimages/tbat_item_trans_core.xml")
        -------------------------------------------------
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
            MakeHauntableLaunch(inst)
        -------------------------------------------------
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fx
    local function fx_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_item_trans_core")
        inst.AnimState:SetBuild("tbat_item_trans_core")
        inst.AnimState:PlayAnimation("idle",true)
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, item_fn, assets),
        Prefab(this_prefab.."_fx", fx_fn, assets)

