----------------------------------------------------------------------------
---[[凶险笼罩]]
----------------------------------------------------------------------------
local assets = {
    Asset("ANIM", "anim/terror_hat.zip"),
}

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
end

local function DespawnLight(inst, num)
    if inst._spawnlight_task ~= nil then
        inst._spawnlight_task:Cancel()
        inst._spawnlight_task = nil
    end
    if inst._lights ~= nil then
        for i = 1, num or 1 do
            local light = table.remove(inst._lights, 1)
            if light and light:IsValid() then
                light.AnimState:PlayAnimation("idle_pst")
                light:DoTaskInTime(light.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, light.Remove)
            end
        end
    end
end

local function SpawnLight(inst, num)
    if inst._owner ~= nil then
        local owner = inst._owner
        if inst._lights == nil then
            inst._lights = {}
        end
        for i = 1, (num or 1) do
            local light = SpawnPrefab("terror_hat_light")
            local x, y, z = owner.Transform:GetWorldPosition()
            light.Transform:SetPosition(x, y, z)
            light:SetLeader(owner)
            light.owner = owner
            light.hat = inst
            light:StartDamageTask()
            table.insert(inst._lights, light)
        end
    end
end

local function GetTargetLigetNum(inst)
    local setbonus_enabled = inst.components.setbonus:IsEnabled()
    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or nil
    if owner and owner:HasTag("player") and not (
        owner.components.health and owner.components.health:IsDead() or
        owner:HasTag("playerghost") or
        owner.sg:HasStateTag("dead") -- 判断这个会让球回光返照
    )
    then
        return setbonus_enabled and 6 or 3
    else
        return 0
    end
end

local function UpdateLights(inst)
    if inst._spawnlight_task ~= nil then
        inst._spawnlight_task:Cancel()
        inst._spawnlight_task = nil
    end
    local target_light_num = GetTargetLigetNum(inst)
    local current_light_num = inst._lights and #inst._lights or 0
    if target_light_num > current_light_num then
        local num_to_spawn = math.max(target_light_num - current_light_num, 0)
        inst._spawnlight_task = inst:DoTaskInTime(0, function() SpawnLight(inst, num_to_spawn) end)
    elseif target_light_num < current_light_num then
        local num_to_despawn = math.max(current_light_num - target_light_num, 0)
        DespawnLight(inst, num_to_despawn)
    end
end

local TRANSFORM_STATES = {
    amulet_rebirth = true,
    wakeup = true,
    rebirth = true,
    wendy_gravestone_rebirth = true,
    gravestone_rebirth = true,
    portal_rez = true,
    rewindtime_rebirth = true,
    reviver_rebirth = true,

    death = true,
    start_rewindtime_revive = true,
    remoteresurrect = true,
}

local function OnNewState(inst, data)
    local hat = inst and inst:IsValid() and inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    if --[[data and data.statename and TRANSFORM_STATES[data.statename] and]] hat and hat ~= nil and hat:IsValid() then
        UpdateLights(hat)
    end
end

local function OnEquip(inst, owner)
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAT_HAIR")
	owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    if owner:HasTag("player") then
        local skin_build = inst:GetSkinBuild()
		if skin_build ~= nil then
			owner:PushEvent("equipskinneditem", inst:GetSkinName())
			owner.AnimState:OverrideItemSkinSymbol("headbase_hat", skin_build, "swap_hat", inst.GUID, "terror_hat")
		else
			owner.AnimState:OverrideSymbol("headbase_hat", "terror_hat", "swap_hat")
		end

        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_HELM")
        owner.AnimState:UseHeadHatExchange(true)
    else
        local skin_build = inst:GetSkinBuild()
		if skin_build ~= nil then
			owner:PushEvent("equipskinneditem", inst:GetSkinName())
			owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, "terror_hat")
		else
			owner.AnimState:OverrideSymbol("swap_hat", "terror_hat", "swap_hat")
		end
    end

    if owner:HasTag("player") then
        inst._owner = owner
        UpdateLights(inst)

        if owner.components.combat then
            owner.components.combat.externaldamagemultipliers:SetModifier(inst, TUNING.HMR_TERROR_HAT_DAMAGE_MULT, "terror_hat_damage_mult")
            owner.components.combat.externaldamagetakenmultipliers:SetModifier(inst, TUNING.HMR_TERROR_HAT_DAMAGETAKE_MULT, "terror_hat_damagetake_mult")
        end

        owner:ListenForEvent("newstate", OnNewState)
    end
end

local function OnUnequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAT_HAIR")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")
    if owner:HasTag("player") then
        owner.AnimState:ClearOverrideSymbol("headbase_hat")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_HELM")
        owner.AnimState:UseHeadHatExchange(false)
    else
        owner.AnimState:ClearOverrideSymbol("swap_hat")
    end

    if owner:HasTag("player") then
        inst._owner = nil
        owner:RemoveEventCallback("newstate", OnNewState)

        DespawnLight(inst, inst._lights and #inst._lights or 6)

        if owner.components.combat then
            owner.components.combat.externaldamagemultipliers:RemoveModifier(inst, "terror_hat_damage_mult")
            owner.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "terror_hat_damagetake_mult")
        end
    end
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end

local function SetEnabled(inst)
    inst.spdamage = {planar = 5}
    UpdateLights(inst)
end

local function SetDisabled(inst)
    inst.spdamage = nil
    UpdateLights(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("terror_hat")
    inst.AnimState:SetBuild("terror_hat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hat")
    inst:AddTag("show_spoilage")

    MakeInventoryFloatable(inst)
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale({1.1, 0.5, 1.1})

    local swap_data = { bank = "terror_hat", anim = "idle" }
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.HMR_TERROR_HAT_MAXCONDITION, TUNING.HMR_TERROR_HAT_ABSORPTION_PERCENT)
    inst.components.armor:SetKeepOnFinished(true)
    inst.components.armor.onfinished = OnFinished

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.TERROR_ARMOR, atlasname = "images/inventoryimages/terror_hat.xml", imagename = "terror_hat", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.TERROR_ARMOR_BROKEN, atlasname = "images/inventoryimages/terror_hat_broken.xml", imagename = "terror_hat_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:Toggle()

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.HMR_TERROR_HAT_WATERPROOFNESS)

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.HMR_TERROR_HAT_LUNAR_RESIST)
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.HMR_TERROR_HAT_SHADOW_RESIST)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("TERROR")
    inst.components.setbonus:SetOnEnabledFn(SetEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetDisabled)

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------
---[[凶险光球]]
----------------------------------------------------------------------------
local MakeFormationMember = require("prefabs/hmr_formation_common")
local light_assets = {
    Asset("ANIM", "anim/terror_hat_light.zip"),
}

local function light_commom_postinit(inst)
    RemovePhysicsColliders(inst)

    inst.entity:SetCanSleep(false)

    inst.AnimState:SetLightOverride(0.2)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("terror_hat_light")
    inst:AddTag("notarget")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("electricdamageimmune")

    inst.persists = false
end

local function DoDamage(inst)
    if inst.owner and inst.owner:IsValid() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local radius = 2
        local damage = 10
        local spdamage = inst.hat and inst.hat.spdamage
        local ents = TheSim:FindEntities(x, y, z, radius, nil, {"player", "playerghost", "wall", "structure", "FX", "CLASSIFIED", "companion", "notarget"})
        for k, v in pairs(ents) do
            local attack_success = HMR_UTIL.Attack(inst.owner or inst, v, damage, spdamage)
            if attack_success and inst.owner.components.health and not inst.owner.components.health:IsDead() then
                inst.owner.components.health:DoDelta(1)
            end
        end
    end
end

local function StartDamageTask(inst)
    inst._damage_task = inst:DoPeriodicTask(0.5, DoDamage)
end

local function LightOnRemove(inst)
    if inst and inst:IsValid() and inst._damage_task then
        inst._damage_task:Cancel()
        inst._damage_task = nil
    end
end

local function light_master_postinit(inst)
    inst.StartDamageTask = StartDamageTask
    inst:ListenForEvent("onremove", LightOnRemove)
end

local light_data = {
    radius = 3,
    rotation_speed = 0.9,
    formation_type = "terror_hat_light",
    min_size = 1,
    max_size = 6,
    light = {
        colour = {0.2, 0.0, 0.8, 1},
    },
    bank = "terror_hat_light",
    build = "terror_hat_light",
    anim = "idle_loop",
    anim_pre = "idle_pre",
    anim_pst = "idle_pst",
}

return Prefab("terror_hat", fn, assets),
    MakeFormationMember("terror_hat_light", light_commom_postinit, light_master_postinit, light_assets, nil, light_data)
