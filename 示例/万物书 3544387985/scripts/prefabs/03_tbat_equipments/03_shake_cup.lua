--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    摇摇杯

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_shake_cup"
    local max_finiteuses = 600
    local type_upgrade_item = "tbat_material_four_leaves_clover_feather"
    local type_upgrade_item_max = 3
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_shake_cup.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hunger task
    local function hunger_task(inst)
        local owner = inst.components.inventoryitem.owner
        -- print("hunger task",inst.components.finiteuses:GetUses(),owner.components.hunger:GetPercent())
        if inst.components.finiteuses:GetUses() > 0 and owner and owner.components.hunger:GetPercent() < 0.99 then
            owner.components.hunger:DoDelta(1,true)
            inst.components.finiteuses:Use()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- equip / unequip
    local function onequip(inst, owner)
        ------------------------------------------
        --- 穿戴
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
            owner.AnimState:ClearOverrideSymbol("swap_object")
            local fx = SpawnPrefab(this_prefab.."_fx")
            fx.entity:SetParent(owner.entity)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(owner.GUID, "swap_object",0,0,0,true)
            inst.fx = fx
        ------------------------------------------
        --- 任务
            if owner:HasTag("player") and owner.components.hunger then
                if inst.__hunger_task then
                    inst.__hunger_task:Cancel()
                end
                inst.__hunger_task = inst:DoPeriodicTask(1,hunger_task)
            end
        ------------------------------------------
    end
    local function onunequip(inst, owner)
        ------------------------------------------
        --- 穿戴
            owner.AnimState:ClearOverrideSymbol("swap_object")
            owner.AnimState:Hide("ARM_carry")
            owner.AnimState:Show("ARM_normal")
            if inst.fx then
                inst.fx:Remove()
                inst.fx = nil
            end
        ------------------------------------------
        --- 任务
            if inst.__hunger_task then
                inst.__hunger_task:Cancel()
                inst.__hunger_task = nil
            end
        ------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local cooking = require("cooking")
    local function acceptable_test_fn(inst,item,doer,right_click)
        if cooking.IsCookingIngredient(item.prefab) then
            return true
        end
        if item.prefab == type_upgrade_item then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 升级
            if item.prefab == type_upgrade_item then
                inst.components.tbat_data:Add(type_upgrade_item,1,0,type_upgrade_item_max)
                item.components.stackable:Get():Remove()
                inst:PushEvent("type_upgrade_info_update")
                return true
            end
        --------------------------------------------------
        -- 
            if inst.components.finiteuses:GetPercent() >= 1 then
                return false
            end
        --------------------------------------------------
        -- 
            local hunger_value = 0
            if item.components.edible then
                hunger_value = item.components.edible.hungervalue
            end
            hunger_value = math.max(hunger_value,0)
        --------------------------------------------------
        --
            if item.components.stackable == nil then
                item:Remove()
                inst.components.finiteuses:Use(-1*hunger_value)
            else
                local stack_num = item.components.stackable:StackSize()
                while true do
                    item.components.stackable:Get():Remove()
                    stack_num = stack_num - 1
                    inst.components.finiteuses:Use(-1*hunger_value)
                    if stack_num <= 0 or inst.components.finiteuses:GetPercent() > 1 then
                        break
                    end
                end
            end
            if inst.components.finiteuses:GetPercent() > 1 then
                inst.components.finiteuses:SetPercent(1)
            end
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ADD_CARD_TO_DECK)
        replica_com:SetSGAction("doshortaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- type upgrade 
    local function type_upgrade_event_fn(inst)
        local str = TBAT:GetString2(this_prefab,"name") .. "\n"
        local item_name = STRINGS.NAMES[string.upper(type_upgrade_item)]
        local current_num = inst.components.tbat_data:Add(type_upgrade_item,0,0,type_upgrade_item_max)
        str = str .. item_name .. " :  " .. current_num .. "/" .. type_upgrade_item_max
        inst.components.named:SetName(str)
        if current_num >= type_upgrade_item_max then
            
            local owner = inst.components.inventoryitem:GetGrandOwner()
            local container = owner and (owner.components.inventory or owner.components.container)
            if container then
                container:GiveItem(SpawnPrefab("tbat_eq_jumbo_ice_cream_tub"))
            else
                local x,y,z = inst.Transform:GetWorldPosition()
                SpawnPrefab("tbat_eq_jumbo_ice_cream_tub").Transform:SetPosition(x,y,z)
            end
            inst:Remove()
        end
    end
    local function type_upgrade_com_install(inst)
        inst:ListenForEvent("type_upgrade_info_update",type_upgrade_event_fn)
        inst:DoTaskInTime(0,type_upgrade_event_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onload / onsave init
    local function data_on_load(com)
        local value = com:Get("percent")
        if value then
            com.inst:DoTaskInTime(0,function()
                com.inst.components.finiteuses:SetPercent(value)                
            end)
        end
    end
    local function data_on_save(com)
        local value = com.inst.components.finiteuses:GetPercent()
        com:Set("percent",value)
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
        inst.AnimState:SetBank("tbat_eq_shake_cup")
        inst.AnimState:SetBuild("tbat_eq_shake_cup")
        inst.AnimState:PlayAnimation("idle",true)
        --weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        acceptable_com_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("named")
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(0)
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_eq_shake_cup","images/inventoryimages/tbat_eq_shake_cup.xml")
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        MakeHauntableLaunch(inst)
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(max_finiteuses)
        inst.components.finiteuses:SetUses(0)
        -- inst.components.finiteuses:SetOnFinished(inst.Remove)
        TBAT.FNS:ShadowInit(inst)
        inst:AddComponent("tbat_data")
        inst.components.tbat_data:AddOnLoadFn(data_on_load)
        inst.components.tbat_data:AddOnSaveFn(data_on_save)
        type_upgrade_com_install(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_eq_shake_cup")
        inst.AnimState:SetBuild("tbat_eq_shake_cup")
        inst.AnimState:PlayAnimation("in_hand",true)
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    Prefab(this_prefab.."_fx", fx, assets)
