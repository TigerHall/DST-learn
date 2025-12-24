----------------------------------------------------------------------------
---[[凶险护甲]]
----------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/terror_armor.zip"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
end

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
end

local function NoHoles(pt)
	return not TheWorld.Map:IsPointNearHole(pt)
end

local function IsSafePoint(pt)
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 4, {"explosive", "monster", "hostile"}, {"player", "INLIMBO", "companion", "spiderden"})
    return ents == nil or #ents == 0
end

local function GetSafePoint(inst)
    local pt = inst:GetPosition()
    local radius = 20

    if TheWorld.has_ocean then
		local function SafePoint(offset)
			local x = pt.x + offset.x
			local y = pt.y + offset.y
			local z = pt.z + offset.z
			return TheWorld.Map:IsAboveGroundAtPoint(x, y, z, true) and NoHoles(pt + offset) and IsSafePoint(pt + offset)
		end

		local offset = FindValidPositionByFan(math.random() * TWOPI, radius, 12, SafePoint)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.z = offset.z + pt.z
			return offset
		end
	else
		if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
			pt = FindNearbyLand(pt, 1) or pt
		end
        local function SafePoint(offset)
            return NoHoles(pt + offset) and IsSafePoint(pt + offset)
        end
		local offset = FindWalkableOffset(pt, math.random() * TWOPI, radius, 12, true, true, SafePoint)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.z = offset.z + pt.z
			return offset
		end
	end
end

local function OnMinHealth(owner)
    if owner:IsValid() then
        if owner.components.health ~= nil then
            local old_health = owner.components.health:GetPercent()
            owner.components.health:SetPercent(math.max(TUNING.HMR_TERROR_ARMOR_MINHEALTH, old_health))
        end
        if owner.components.hmrblinker ~= nil then
            local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if armor ~= nil and armor.prefab == "terror_armor" then
                local blink_data = {
                    tintcolor = {17 / 255, 4 / 255, 102 / 255},
                    blinkfx = {"terror_staff_blinkin_fx", "terror_staff_blinkout_fx"},
                    onblinkout = function(_owner)
                        if _owner and _owner:IsValid() and _owner.components.hmrblinker ~= nil then
                            _owner.components.hmrblinker:RemoveSource(armor)
                        end
                    end,
                }
                owner.components.hmrblinker:AddSource(armor, blink_data)
            end

            owner.components.hmrblinker:BlinkTo(GetSafePoint(owner))
        end

        local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if armor ~= nil and armor.prefab == "terror_armor" then
            armor.components.armor:TakeDamage(TUNING.HMR_TERROR_ARMOR_MAXCONDITION / 2)
        end
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "terror_armor")
	else
		owner.AnimState:OverrideSymbol("swap_body", "terror_armor", "swap_body")
	end
    owner.AnimState:SetSymbolLightOverride("swap_body", .1)

	inst:ListenForEvent("blocked", OnBlocked, owner)
    inst:ListenForEvent("minhealth", OnMinHealth, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:SetSymbolLightOverride("swap_body", 0)

	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end

    inst:RemoveEventCallback("blocked", OnBlocked, owner)
    inst:RemoveEventCallback("minhealth", OnMinHealth, owner)
end

local function SetEnabled(inst)
    inst.components.armor:SetAbsorption(TUNING.HMR_TERROR_ARMOR_SKILLED_ABSORPTION_PRECENT)
end

local function SetDisabled(inst)
    inst.components.armor:SetAbsorption(TUNING.HMR_TERROR_ARMOR_NORMAL_ABSORPTION_PERCENT)
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function OnTakeDamage(inst, damage_amount)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil then
        damage_amount = damage_amount or math.random(20, 30)
        local max_health = owner.components.health.maxhealth
        if damage_amount >= max_health * 0.2 then
            SpawnPrefab("terror_armor_fx"):SetFXOwner(owner, damage_amount, {planar = damage_amount * 0.1})
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("terror_armor")
    inst.AnimState:SetBuild("terror_armor")

    inst:AddTag("armor")
    inst:AddTag("terror_armor")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = {bank = "terror_armor", anim = "idle"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname ="images/inventoryimages/terror_armor.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.HMR_TERROR_ARMOR_MAXCONDITION, TUNING.HMR_TERROR_ARMOR_NORMAL_ABSORPTION_PERCENT)
    inst.components.armor:SetKeepOnFinished(true)
    inst.components.armor.onfinished = OnFinished
    inst.components.armor.ontakedamage = OnTakeDamage

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.TERROR_ARMOR, atlasname = "images/inventoryimages/terror_armor.xml", imagename = "terror_armor", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.TERROR_ARMOR_BROKEN, atlasname = "images/inventoryimages/terror_armor_broken.xml", imagename = "terror_armor_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:Toggle()

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(TUNING.HMR_TERROR_ARMOR_PLANAR_DEFENSE) -- 10

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("TERROR")
    inst.components.setbonus:SetOnEnabledFn(SetEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetDisabled)

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------
---[[受击特效]]
----------------------------------------------------------------------------
local fx_assets =
{
    Asset("ANIM", "anim/terror_armor_fx.zip"),
}

--DSV uses 4 but ignores physics radius
local MAXRANGE = 3
local NO_TAGS =	{ "bramble_resistant", "INLIMBO", "notarget", "noattack", "flight", "invisible", "wall", "player", "companion" }
local MUST_TAGS = { "_combat" }

local function OnUpdateThorns(inst)
    inst.range = inst.range + .75

    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, inst.range + 3, MUST_TAGS, NO_TAGS)) do
        if not inst.ignore[v] and v:IsValid() and v.entity:IsVisible() then
            local range = inst.range + v:GetPhysicsRadius(0)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                local attacker = inst.owner ~= nil and inst.owner:IsValid() and inst.owner or inst
                HMR_UTIL.Attack(attacker, v, inst.damage, inst.spdamage)
                inst.ignore[v] = true
            end
        end
    end

    if inst.range >= MAXRANGE then
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateThorns)
    end
end

local function SetFXOwner(inst, owner, damage, spdamage)
    inst.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.owner = owner
    inst.damage = damage
    inst.spdamage = spdamage
    -- inst.canhitplayers = not owner:HasTag("player") or TheNet:GetPVPEnabled()
    inst.ignore[owner] = true
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("thorny")

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("terror_armor_fx")
    inst.AnimState:SetBuild("terror_armor_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(OnUpdateThorns)

    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false

    inst.range = .75
    inst.ignore = {}
    inst.canhitplayers = true
    --inst.owner = nil

    inst.SetFXOwner = SetFXOwner

    return inst
end

return Prefab("terror_armor", fn, assets),
        Prefab("terror_armor_fx", fx_fn, fx_assets)