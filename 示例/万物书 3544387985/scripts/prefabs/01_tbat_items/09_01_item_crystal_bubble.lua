--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_crystal_bubble"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_crystal_bubble.zip"),
        Asset("IMAGE", "images/widgets/tbat_item_crystal_bubble_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_item_crystal_bubble_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function ondeploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        SpawnPrefab("tbat_item_crystal_bubble_box").Transform:SetPosition(pt.x,0,pt.z)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- custom deploy fn
    local function _custom_candeploy_fn(inst, pt, mouseover, deployer, rot)
        return true
    end
    local function inventoryitem_replica_init(inst,replica_com)
        replica_com.DeploySpacingRadius = function()
            return 30
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水影子
        local function shadow_init(inst)
            if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
                inst.AnimState:Hide("SHADOW")
                inst.AnimState:HideSymbol("shadow")
            else                                
                inst.AnimState:Show("SHADOW")
                inst.AnimState:ShowSymbol("shadow")
            end
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
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
        local fx = SpawnPrefab(this_prefab)
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object",0,-100,0)
        fx:AddTag("INLIMBO")
        fx:AddTag("NOCLICK")
        inst.fx = fx
    end
    local function workable_on_work_fn(inst,doer)
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        local debuff_prefab = "tbat_item_crystal_bubble_debuff"
        doer:AddDebuff(debuff_prefab,debuff_prefab)
        inst.components.stackable:Get():Remove()
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.GENERIC)
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
--- 物品本体
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("tbat_item_crystal_bubble")
        inst.AnimState:SetBuild("tbat_item_crystal_bubble")
        inst.AnimState:PlayAnimation("item",true)
        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", nil, 0.77)
        inst:AddTag("usedeploystring")
        inst:AddTag("usedeployspacingasoffset")
        inst:AddTag("deploykititem")
        ----------------------------------------------------------------------
            inst._custom_candeploy_fn = _custom_candeploy_fn
        ----------------------------------------------------------------------
            inst.entity:SetPristine()
        ----------------------------------------------------------------------
        ---
            workable_install(inst)
            inst:ListenForEvent("TBAT_OnEntityReplicated.inventoryitem",inventoryitem_replica_init)
        ----------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ------------------------------------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_crystal_bubble","images/inventoryimages/tbat_item_crystal_bubble.xml")
        ------------------------------------------------------------------------------------------
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize =  TBAT.PARAM.STACK_40()
        ------------------------------------------------------------------------------------------
        --- 落水影子
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        ------------------------------------------------------------------------------------------
        --- 种植组件
            inst:AddComponent("deployable")                
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        ------------------------------------------------------------------------------------------
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- placer 相关的 hook
    local function placer_postinit_fn(inst)
        inst.AnimState:OverrideSymbol("slot",this_prefab,"empty")
        inst.AnimState:PlayAnimation("box",true)
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return  Prefab(this_prefab, item_fn,assets),
        MakePlacer(this_prefab.."_placer", "tbat_item_crystal_bubble", "tbat_item_crystal_bubble", "box", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

