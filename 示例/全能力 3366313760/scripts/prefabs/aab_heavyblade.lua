local assets =
{
    Asset("ANIM", "anim/sword_buster.zip"),
    Asset("ANIM", "anim/swap_sword_buster.zip"),
}

local prefabs = {
    "nightsword_curve_fx"
}

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

----------------------------------------------------------------------------------------------------
local function DamageFn(inst)
    if inst._lastparrytime ~= nil and (inst._lastparrytime + TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_DURATION) >= GetTime() then
        return 52 + (inst._bonusdamage or 0)
    end
    return 52
end


local function SpellFn(inst, doer, pos)
    local duration_mult = TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_DURATION_MULT

    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), TUNING.WATHGRITHR_SHIELD_PARRY_DURATION * duration_mult)
    inst.components.rechargeable:Discharge(10) --冷却
end

local function OnParry(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)

    if inst.components.rechargeable:GetPercent() < 0.07 then --0.7秒反应时间
        --格挡成功
        if doer.SoundEmitter then
            doer.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
        end
        inst.components.rechargeable:SetPercent(1)
    end

    inst._lastparrytime = GetTime()
    inst._bonusdamage = math.max(damage * 0.5, 15) --有下限无上限
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

----------------------------------------------------------------------------------------------------

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_sword_buster", "swap_sword_buster")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst._vfx_fx_inst == nil then
        inst._vfx_fx_inst = SpawnPrefab("nightsword_curve_fx")
        inst._vfx_fx_inst.entity:AddFollower()
    end
    inst._vfx_fx_inst.entity:SetParent(owner.entity)
    inst._vfx_fx_inst.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -100, 0)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if inst._vfx_fx_inst ~= nil then
        inst._vfx_fx_inst:Remove()
        inst._vfx_fx_inst = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("sword_buster")
    inst.AnimState:SetBuild("sword_buster")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("parryweapon")
    inst:AddTag("rechargeable")
    inst:AddTag("tool")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
    inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "lavaarena_heavyblade"

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DamageFn)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    -- 格挡
    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(TUNING.WATHGRITHR_SHIELD_PARRY_ARC)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(800)
    inst.components.finiteuses:SetUses(800)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    -- inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    -- inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 1)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.DIG, 1)
    inst.components.tool:SetAction(ACTIONS.HAMMER, 1)
    inst.components.tool:EnableToughWork(true)

    return inst
end

return Prefab("aab_heavyblade", fn, assets, prefabs)
