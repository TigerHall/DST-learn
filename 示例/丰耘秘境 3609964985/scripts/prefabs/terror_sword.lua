local assets =
{
    Asset("ANIM", "anim/terror_sword.zip"),
}

local SWAP_DATA_BROKEN = { sym_build = "terror_sword", sym_name = "swap_object_broken_float", bank = "terror_sword", anim = "idle_broken" }
local SWAP_DATA = { sym_build = "terror_sword", sym_name = "swap_object", bank = "terror_sword", anim = "idle" }

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    inst.components.floater:SetBankSwapOnFloat(true, 0, SWAP_DATA_BROKEN)
end

local function OnRepaired(inst)
    inst.components.floater:SetBankSwapOnFloat(true, -25, SWAP_DATA)
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_object", inst.GUID, "terror_sword")
        local fx = inst.skin_follow_fx
        if fx ~= nil then
            local follow_fx = SpawnPrefab(fx)
            follow_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            follow_fx.entity:SetParent(owner.entity)
            follow_fx.entity:AddFollower()
            follow_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0)
            inst._fx = follow_fx
        end
    else
        owner.AnimState:OverrideSymbol("swap_object", "terror_sword", "swap_object")
    end

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        if inst._fx ~= nil then
            inst._fx:Remove()
            inst._fx = nil
        end
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function OnAttack(inst, attacker, target)
    inst._attack_count = (inst._attack_count or 0) + 1
    if inst._attack_count >= 3 and
        attacker.components.health ~= nil and
        attacker.components.health:GetPercent() > 0.4 and
        attacker.components.health.currenthealth > 2.5 * TUNING.HMR_TERROR_SWORD_VINE_HEALTH_CONSUME
    then
        local pt
        if target ~= nil and target:IsValid() then
            pt = target:GetPosition()
        else
            pt = attacker:GetPosition()
            target = nil
        end

        local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true)
        if offset ~= nil then
            attacker.components.health:DoDelta(-TUNING.HMR_TERROR_SWORD_VINE_HEALTH_CONSUME)
            local vine = SpawnPrefab("terror_vine", inst.vine_skin_name, 0)
            vine.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
            vine.components.combat:SetTarget(target)
            vine._owner = attacker

            inst._attack_count = 0
        end
    end
end

local function SetBonusEnabled(inst)
    inst.components.weapon:SetOnAttack(OnAttack)
end

local function SetBonusDisabled(inst)
    inst.components.weapon:SetOnAttack(nil)
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("terror_sword")
    inst.AnimState:SetBuild("terror_sword")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -25, SWAP_DATA)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.HMR_TERROR_SWORD_DAMAGE)
    inst.components.weapon:SetRange(2, 2)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.HMR_TERROR_SWORD_PLANARDAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.HMR_TERROR_SWORD_MAXUSES)
    inst.components.finiteuses:SetUses(TUNING.HMR_TERROR_SWORD_MAXUSES)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("TERROR")
    inst.components.setbonus:SetOnEnabledFn(SetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetBonusDisabled)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.HONOR_STAFF, atlasname = "images/inventoryimages/terror_sword.xml", imagename = "terror_sword", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.HONOR_STAFF_BROKEN, atlasname = "images/inventoryimages/terror_sword_broken.xml", imagename = "terror_sword_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:SetOnRepairedFn(OnRepaired)
    inst.components.hmrrepairable:Toggle()

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("terror_sword", fn, assets)
