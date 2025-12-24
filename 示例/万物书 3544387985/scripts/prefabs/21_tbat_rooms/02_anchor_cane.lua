--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_anchor_cane"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/cane.zip"),
        Asset("ANIM", "anim/swap_cane.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 

    local function special_spell_caster_test_fn(inst,doer,target,pt,right_click)
        if right_click and target then
            return true
        end
        return false
    end
    local function special_spell_caster_active_fn(inst,doer,target,pt)
        if target == nil then
            return true
        end
        local x,y,z = target.Transform:GetWorldPosition()
        local all_anchors = TheSim:FindEntities(x, 0, z, 500, {"tbat_room_anchor_fantasy_island"})
        local nearest_target = nil
        local nearest_dist = 500*500
        for i,temp_anchor in ipairs(all_anchors) do
            local dist_sq = doer:GetDistanceSqToInst(temp_anchor)
            if dist_sq < nearest_dist then
                nearest_target = temp_anchor
                nearest_dist = dist_sq
            end
        end
        if nearest_target == nil then
            return true
        end

        local target_pos = Vector3(target.Transform:GetWorldPosition())
        local anchor_pos = Vector3(nearest_target.Transform:GetWorldPosition())

        local vect = target_pos - anchor_pos

        vect.x = math.floor(vect.x*1000)/1000
        -- vect.y = math.floor(vect.y*1000)/1000
        vect.z = math.floor(vect.z*1000)/1000

        local distance = math.floor(vect:Length()*100)/100

        local str = "目标：".. target:GetDisplayName() .. "\n"
        str = str .. "物品代码: "..target.prefab .. "\n"
        str = str .. "最近锚点：".. nearest_target:GetDisplayName() .. "\n"
        str = str .. "X : ".. vect.x .. "  ,  "
        str = str .. "Z : ".. vect.z .. "\n"
        str = str .. "距离：".. distance .. "\n"
        -- doer.components.talker:Say(str)
        TheNet:Announce(str)

        print(target.prefab)
        return true
    end
    local function special_spell_caster_replica_init(inst,replica_com)
        replica_com:SetTestFn(special_spell_caster_test_fn)
        replica_com:SetText(this_prefab,"锚点指示")
        replica_com:SetSGAction("quickcastspell")
        replica_com:SetDistance(200)
    end
    local function special_spell_caster_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_point_and_target_spell_caster",special_spell_caster_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_point_and_target_spell_caster")
        inst.components.tbat_com_point_and_target_spell_caster:SetSpellFn(special_spell_caster_active_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
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

        --weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")

        local swap_data = {sym_build = "swap_cane"}
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85}, true, 1, swap_data)


        inst.entity:SetPristine()
        special_spell_caster_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("cane")
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.walkspeedmult = 1.5
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
