--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_turf_water_lily_cat_debug_seed"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_turf_water_lily_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装备
    local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_cane", "swap_cane")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end
    local function onunequip(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- spell_caster
    local function caster_test_fn(inst,doer,target,pt,right_click)
        if right_click and pt then
            return true
        end
        return false
    end
    local function spell_active_fn(inst,doer,target,pt)
        if pt == nil then
            return
        end
        if TBAT.___seed_fn then
            TBAT.___seed_fn(inst,doer,pt)
        end
        -- local plant = SpawnPrefab("tbat_turf_water_lily_cat")
        -- plant:PushEvent("deploy",{ 
        --     pt = Vector3(pt.x,0,pt.z),
        --     stop_grow = true
        -- })
        return true
    end
    local function caster_replica_init(inst,replica_com)
        replica_com:SetAllowCanCastOnImpassable(true)
        replica_com:SetDistance(10)
        replica_com:SetTestFn(caster_test_fn)
        replica_com:SetSGAction("quickcastspell")
        replica_com:SetText(this_prefab,"66666")
    end
    local function spell_caster_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_point_and_target_spell_caster",caster_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_point_and_target_spell_caster")
        inst.components.tbat_com_point_and_target_spell_caster:SetSpellFn(spell_active_fn)
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

        inst.AnimState:SetBank("cane")
        inst.AnimState:SetBuild("swap_cane")
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("weapon")

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()
        ---------------------------------------------------------
        ---
            spell_caster_install(inst)
        ---------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ---------------------------------------------------------
        ----
            inst:AddComponent("weapon")
            inst.components.weapon:SetDamage(0)
        ---------------------------------------------------------
        ----
            inst:AddComponent("inspectable")
        ---------------------------------------------------------
        ----
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("cane")
        ---------------------------------------------------------
        ----
            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
        ---------------------------------------------------------
        ----
            MakeHauntableLaunch(inst)
        ---------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
