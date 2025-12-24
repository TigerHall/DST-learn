--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    冒险家笔记

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_notes_of_adventurer"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_notes_of_adventurer.zip"),
        Asset("IMAGE", "images/widgets/tbat_ui_notes_of_adventurer.tex"),
        Asset("ATLAS", "images/widgets/tbat_ui_notes_of_adventurer.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---  hud install
    local hud_install = require("prefabs/01_tbat_items/08_02_notes_hud")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 回收
    local function workable_test_fn(inst,doer,right_click)        
        return inst.replica.inventoryitem:IsGrandOwner(doer)
    end
    local function workable_pre_sg(inst,owner)

    end
    local function workable_on_work_fn(inst,doer)
        TBAT.FNS:RPC_PushEvent(doer,"open_hud",nil,inst)
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.OPEN_CRAFTING.READ)
        replica_com:SetSGAction("tbat_sg_empty_active")
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
            inst.AnimState:PlayAnimation("item_water")
        else                                
            inst.AnimState:PlayAnimation("item")
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
        inst.AnimState:SetBank("tbat_item_notes_of_adventurer")
        inst.AnimState:SetBuild("tbat_item_notes_of_adventurer")
        inst.AnimState:PlayAnimation("item",true)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst:AddTag("tbat_item_notes_of_adventurer")
        inst.entity:SetPristine()
        -------------------------------------------------
            workable_install(inst)
            hud_install(inst)
        -------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_notes_of_adventurer","images/inventoryimages/tbat_item_notes_of_adventurer.xml")
        -------------------------------------------------
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
            MakeHauntableLaunch(inst)
        -------------------------------------------------
            inst:AddComponent("erasablepaper")
        -------------------------------------------------
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local item_num = 23
    local ret = {Prefab(this_prefab, item_fn, assets)}
    for index = 1, item_num, 1 do
        local function temp_fn()
            local inst = item_fn()
            inst.index = index
            if not TheWorld.ismastersim then
                return inst
            end
            return inst            
        end
        table.insert(ret,Prefab(this_prefab.."_"..index, temp_fn))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)

