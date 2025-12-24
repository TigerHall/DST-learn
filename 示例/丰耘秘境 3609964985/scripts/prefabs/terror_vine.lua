require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/terror_vine.zip"),
}

local function UpdateDamage(inst)
    local health = inst.components.health:GetPercent()
    local damage_mult = 1 + health
    inst.components.combat.externaldamagemultipliers:SetModifier(inst, damage_mult, "terror_vine")
end

local function OnAttacked(inst, data)
    UpdateDamage(inst)
end

local function OnTimerDone(inst, data)
    if data.name == "disappear" and not inst.components.health:IsDead() then
        inst.components.health:Kill()
    end
end

local function OnDeath(inst)
    if inst._owner ~= nil and inst._owner.components.health ~= nil and not inst._owner.components.health:IsDead() then
        inst._owner.components.health:DoDelta(TUNING.HMR_TERROR_SWORD_VINE_HEALTH_CONSUME)
    end
end

local function ShouldKeepTarget()
    return true
end

local function OnLoad(inst)
    inst.components.lootdropper:SpawnLootPrefab("healingsalve")
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("plant")
    inst:AddTag("hostile")
    inst:AddTag("soulless")
    inst:AddTag("NPCcanaggro")
    inst:AddTag("companion")

    inst.AnimState:SetBank("terror_vine")
    inst.AnimState:SetBuild("terror_vine")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetScale(1.2,1.2,1.2)

    inst.Transform:SetSixFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HMR_TERROR_VINE_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HMR_TERROR_VINE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TENTACLE_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

	inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.HMR_TERROR_VINE_PLANARDAMAGE)

	inst:AddComponent("colouradder")

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremove", OnDeath)

    MakeMediumFreezableCharacter(inst)
    inst.components.freezable:SetResistance(6)
    MakeMediumBurnableCharacter(inst)

    inst:SetStateGraph("SG_terror_vine")

    inst:DoTaskInTime(0, UpdateDamage)

    inst.OnLoad = OnLoad

    return inst
end

return Prefab("terror_vine", fn, assets)