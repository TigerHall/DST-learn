----------------------------------------------------------------------------
---[[护甲]]
----------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/honor_armor.zip"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

-- 装备耐久消失回调函数
local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    if inst.skill_enabled then
        inst:DisableSkill(inst.components.inventoryitem:GetGrandOwner())
    end
end

local function Dofx(inst)
    local owner = inst.components.inventoryitem.owner
    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end
    inst._fx = SpawnPrefab("honor_armor_fx")
    inst._fx.entity:SetParent(owner.entity)
    inst._fx.Transform:SetPosition(0, 0.2, 0)
    inst._fx.AnimState:PlayAnimation("hit")
    inst._fx.AnimState:PushAnimation("idle_loop")
    inst._fx.persists = false
end

-- 受伤时若技能处于开启状态，则减少护甲耐久
local function OnTakeDamage(inst, damage_amount)
    if inst.skill_enabled then
        inst.components.armor:Repair(-damage_amount * (TUNING.HMR_HONOR_ARMOR_SKILLED_CONDITION_LOSS_NULT - 1))
    end
end

local function OnHealthDelta(owner)
    if owner.components.health ~= nil and owner.components.hunger ~= nil then
        if owner.components.health:IsHurt() and owner._honor_armor_hunger_enabled then
            owner.components.hunger.burnratemodifiers:RemoveModifier(owner, "honor_armor")
            owner._honor_armor_hunger_enabled = false
        elseif not owner._honor_armor_hunger_enabled then
            owner.components.hunger.burnratemodifiers:SetModifier(owner, TUNING.HMR_HONOR_ARMOR_HUNGER_RATE_SLOWDOWN, "honor_armor")
            owner._honor_armor_hunger_enabled = true
        end
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "honor_armor", inst.GUID, "swap_body")
	else
		owner.AnimState:OverrideSymbol("swap_body", "honor_armor", "swap_body")
	end

    inst:ListenForEvent("blocked", OnBlocked, owner)

    if owner:HasTag("player") then
        -- 生命恢复
        HMR_UTIL.AddStatusEffect(owner, HMR_UTIL.STANDARD_STATUS.HEALTH, "honor_armor", TUNING.HMR_HONOR_ARMOR_HEALTH_REGEN_RATE, 1)
        -- 根据生命值变化调整饱食度
        owner:ListenForEvent("healthdelta", OnHealthDelta)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    inst:RemoveEventCallback("blocked", OnBlocked, owner)

    if owner:HasTag("player") then
        HMR_UTIL.RemoveStatusEffect(owner, HMR_UTIL.STANDARD_STATUS.HEALTH, "honor_armor")

        if owner.components.hunger ~= nil and owner._honor_armor_hunger_enabled then
            owner.components.hunger.burnratemodifiers:RemoveModifier(owner, "honor_armor")
            owner._honor_armor_hunger_enabled = false
        end
        owner:RemoveEventCallback("healthdelta", OnHealthDelta)

        if inst.skill_enabled then
            inst:DisableSkill(owner)
        end

        -- 确保取消所有护甲效果
        inst:DoTaskInTime(0, function()
            if inst._fx ~= nil then
                inst._fx:kill_fx()
                inst._fx = nil
            end
        end)
    end
end

local function EnabledOnHealthDelta(owner, data)
    local inst = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if data.oldpercent ~= 0 and data.newpercent <= TUNING.NONLETHAL_PERCENT and inst ~= nil and inst.prefab == "honor_armor" then
        owner.components.health:SetPercent(1, true)
        inst.components.armor:SetPercent(0)
    end
end

local function SetBonusEnabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    -- 受到致命伤害时效果
    if owner and owner.components.health then
        owner:ListenForEvent("healthdelta", EnabledOnHealthDelta)
    end
    inst.components.equippable.walkspeedmult = 1
end

local function SetBonusDisabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.health then
        owner:RemoveEventCallback("healthdelta", EnabledOnHealthDelta)
    end
    inst.components.equippable.walkspeedmult = TUNING.HMR_HONOR_ARMOR_WALKSPEED_MULT
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HMR_HONOR_ARMOR_WALKSPEED_MULT
end

local function EnableSkill(inst, owner)
    inst.skill_enabled = true
    inst.components.armor:SetAbsorption(TUNING.HMR_HONOR_ARMOR_SKILLED_ABSORPTION_PERCENT) -- 0.98
    owner = owner or inst.components.inventoryitem.owner
    Dofx(inst)
    -- 开启技能时每秒扣除2点饱食度
    HMR_UTIL.AddStatusEffect(owner, HMR_UTIL.STANDARD_STATUS.HUNGER, "honor_armor", -TUNING.HMR_HONOR_ARMOR_HUNGER_RATE_SKILLED, 1)
end

local function DisableSkill(inst, owner)
    inst.skill_enabled = false
    inst.components.armor:SetAbsorption(TUNING.HMR_HONOR_ARMOR_NORMAL_ABSORPTION_PRECENT) -- 0.85
    if owner ~= nil then
        HMR_UTIL.RemoveStatusEffect(owner, HMR_UTIL.STANDARD_STATUS.HUNGER, "honor_armor")
    end
    if inst._fx ~= nil then
        inst._fx:kill_fx()
        inst._fx = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_armor")
    inst.AnimState:SetBuild("honor_armor")

    inst:AddTag("armor")
    inst:AddTag("honor_armor")
    inst:AddTag("honor_item")
    inst:AddTag("honor_repairable")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = {bank = "honor_armor", anim = "idle"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.skill_enabled = false -- 开启技能标志

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.HMR_HONOR_ARMOR_MAXCONDITION, TUNING.HMR_HONOR_ARMOR_NORMAL_ABSORPTION_PRECENT)
    inst.components.armor:SetKeepOnFinished(true)
    inst.components.armor.onfinished = OnFinished
    inst.components.armor.ontakedamage = OnTakeDamage

    OnEnableEquipableFn(inst)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.HONOR_ARMOR, atlasname = "images/inventoryimages/honor_armor.xml", imagename = "honor_armor", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.HONOR_ARMOR_BROKEN, atlasname = "images/inventoryimages/honor_armor_broken.xml", imagename = "honor_armor_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:Toggle()

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(TUNING.HMR_HONOR_ARMOR_PLANAR_DEFENSE) -- 10

    -- 套装组件
    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")
    inst.components.setbonus:SetOnEnabledFn(SetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetBonusDisabled)

    -- 开启/关闭护甲技能
    inst.EnableSkill = EnableSkill
    inst.DisableSkill = DisableSkill

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------
---[[技能特效]]
----------------------------------------------------------------------------
local fx_assets =
{
   Asset("ANIM", "anim/honor_armor_fx.zip"),
}

local MAX_LIGHT_FRAME = 6

local function OnUpdateLight(inst, dframes)
    local done
    if inst._islighton:value() then
        local frame = inst._lightframe:value() + dframes
        done = frame >= MAX_LIGHT_FRAME
        inst._lightframe:set_local(done and MAX_LIGHT_FRAME or frame)
    else
        local frame = inst._lightframe:value() - dframes
        done = frame <= 0
        inst._lightframe:set_local(done and 0 or frame)
    end

    inst.Light:SetRadius(3 * inst._lightframe:value() / MAX_LIGHT_FRAME)

    if done then
        inst._lighttask:Cancel()
        inst._lighttask = nil
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    OnUpdateLight(inst, 0)
end

local function kill_fx(inst)
    inst.AnimState:PlayAnimation("close")
    inst._islighton:set(false)
    inst._lightframe:set(inst._lightframe:value())
    OnLightDirty(inst)
    inst:DoTaskInTime(.2, inst.Remove)
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("honor_armor_fx")
    inst.AnimState:SetBuild("honor_armor_fx")
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("idle_loop", true)

    inst.SoundEmitter:PlaySound("dontstarve/wilson/forcefield_LP", "loop")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_tinybyte(inst.GUID, "honor_armor_fx._lightframe", "lightdirty")
    inst._islighton = net_bool(inst.GUID, "honor_armor_fx._islighton", "lightdirty")
    inst._lighttask = nil
    inst._islighton:set(true)

    inst.entity:SetPristine()

    OnLightDirty(inst)

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    inst.kill_fx = kill_fx

    return inst
end

return Prefab("honor_armor", fn, assets),
    Prefab("honor_armor_fx", fx_fn, fx_assets)