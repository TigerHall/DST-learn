local assets =
{
    Asset("ANIM", "anim/honor_hat.zip"),
}

----------------------------------------------------------------------------
---[[辉煌法帽]]
----------------------------------------------------------------------------
local function UpdateLight(owner)
    if owner == nil or owner:HasTag("lamp") then
        return
    end

    local inst = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

    if inst == nil or not inst:HasTag("honor_hat") then
        return
    end

    if inst._light == nil then
        inst._light = SpawnPrefab("alterguardianhatlight")
        inst._light.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
        inst._light.entity:SetParent(owner.entity)
    end

    local sanity = owner.components.sanity:GetPercent()
    if sanity >= TUNING.HMR_HONOR_HAT_LIGHTUP_SANITY_PERCENT then
        inst._light.Light:Enable(true)
    else
        inst._light.Light:Enable(false)
    end
end

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    if inst._light ~= nil then
        inst._light:Remove()
        inst._light = nil
    end
end

local function onequip(inst, owner)
    -- 穿戴显示
    owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAT_HAIR")
	owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    if owner:HasTag("player") then
        local skin_build = inst:GetSkinBuild()
		if skin_build ~= nil then
			owner:PushEvent("equipskinneditem", inst:GetSkinName())
			owner.AnimState:OverrideItemSkinSymbol("headbase_hat", skin_build, "swap_hat", inst.GUID, "honor_hat")
		else
			owner.AnimState:OverrideSymbol("headbase_hat", "honor_hat", "swap_hat")
		end

        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_HELM")
        owner.AnimState:UseHeadHatExchange(true)
    else
        local skin_build = inst:GetSkinBuild()
		if skin_build ~= nil then
			owner:PushEvent("equipskinneditem", inst:GetSkinName())
			owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, "honor_hat")
		else
			owner.AnimState:OverrideSymbol("swap_hat", "honor_hat", "swap_hat")
		end
    end

    if inst.fx ~= nil then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("honor_hat_fx")
    inst.fx:AttachToOwner(owner)
    owner.AnimState:SetSymbolLightOverride("swap_hat", .1)

    -- 更新灯光
    UpdateLight(owner)
    inst:ListenForEvent("sanitydelta", UpdateLight, owner)

    -- 转换san光环为正值
    if owner ~= nil and owner.components.sanity ~= nil then
        owner.components.sanity.neg_aura_absorb = TUNING.HMR_HONOR_HAT_NEG_AURA_ABSORB
    end

    if not owner:HasTag("honor_hat_onwer") then
        owner:AddTag("honor_hat_onwer")
    end
end

local function onunequip(inst, owner)
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

    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
    owner.AnimState:SetSymbolLightOverride("swap_hat", 0)

    if owner:HasTag("honor_hat_onwer") then
        owner:RemoveTag("honor_hat_onwer")
    end

    -- 停止发光效果
    if inst._light ~= nil then
        inst._light:Remove()
        inst._light = nil
    end
    inst:RemoveEventCallback("sanitydelta", UpdateLight, owner)

    -- 停止转换san光环
    if owner ~= nil and owner.components.sanity ~= nil then
        owner.components.sanity.neg_aura_absorb = 0
    end
end

local function honor_enabled(inst)
    if inst._enabledtask == nil then
        inst._enabledtask = inst:DoPeriodicTask(1, function()
            inst.components.armor:Repair(TUNING.HMR_HONOR_HAT_SETBONUS_REPAIR_RATE)
            inst.components.inventoryitem.owner.components.sanity:DoDelta(TUNING.HMR_HONOR_HAT_SETBONUS_SANITY_RATE)
        end)
    end
end

local function honor_disabled(inst)
    if inst._enabledtask ~= nil then
        inst._enabledtask:Cancel()
        inst._enabledtask = nil
    end
end

local function onrepaired(inst)
    inst.AnimState:PlayAnimation("anim")
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_hat")
    inst.AnimState:SetBuild("honor_hat")

    inst:AddTag("honor_hat")
    inst:AddTag("honor_item")
    inst:AddTag("honor_repairable")
    inst:AddTag("lunarthrall_plant_friendly")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = {bank = "honor_hat", anim = "idle"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("hmrmodifier")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname ="images/inventoryimages/honor_hat.xml"
    -- inst.components.inventoryitem:SetOnDroppedFn(UpdateLight(inst))
	-- inst.components.inventoryitem:SetOnPutInInventoryFn(UpdateLight(inst))

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.HMR_HONOR_HAT_MAXCONDITION, TUNING.HMR_HONOR_HAT_NORMAL_ABSORPTION_PERCENT)
    inst.components.armor:SetKeepOnFinished(true)
    inst.components.armor.onfinished = OnFinished

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.HONOR_ARMOR, atlasname = "images/inventoryimages/honor_hat.xml", imagename = "honor_hat", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.HONOR_ARMOR_BROKEN, atlasname = "images/inventoryimages/honor_hat_broken.xml", imagename = "honor_hat_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:Toggle()

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.HMR_HONOR_HAT_WATERPROOFNESS)

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.HMR_HONOR_HAT_LUNAR_RESIST)
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.HMR_HONOR_HAT_SHADOW_RESIST)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")
    inst.components.setbonus:SetOnEnabledFn(honor_enabled)
    inst.components.setbonus:SetOnDisabledFn(honor_disabled)

    inst:ListenForEvent("repaired", onrepaired)

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------
---[[穿戴状态动画]]
----------------------------------------------------------------------------
local function CreateFxFollowFrame(i)
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("honor_hat")
	inst.AnimState:SetBuild("honor_hat")
	inst.AnimState:PlayAnimation("idle"..tostring(i), true)
	inst.AnimState:SetSymbolBloom("float_top")
	inst.AnimState:SetSymbolLightOverride("float_top", .5)
	inst.AnimState:SetSymbolMultColour("float_top", 1, 1, 1, .6)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.persists = false

	return inst
end

local function FollowFx_OnRemoveEntity(inst)
	for i, v in ipairs(inst.fx) do
		v:Remove()
	end
end

local function FollowFx_ColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.fx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function SpawnFollowFxForOwner(inst, owner, createfn, framebegin, frameend, isfullhelm)
	local follow_symbol = isfullhelm and owner:HasTag("player") and owner.AnimState:BuildHasSymbol("headbase_hat") and "headbase_hat" or "swap_hat"
	inst.fx = {}
	local frame
	for i = framebegin, frameend do
		local fx = createfn(i)
		frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
		fx.entity:SetParent(owner.entity)
		fx.Follower:FollowSymbol(owner.GUID, follow_symbol, nil, nil, nil, true, nil, i - 1)
		fx.AnimState:SetFrame(frame)
		fx.components.highlightchild:SetOwner(owner)
		table.insert(inst.fx, fx)
	end
	inst.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
	inst.OnRemoveEntity = FollowFx_OnRemoveEntity
end

local function OnEntityReplicated(inst)
    local owner = inst.entity:GetParent()
    if owner ~= nil then
        SpawnFollowFxForOwner(inst, owner, CreateFxFollowFrame, 1, 3, true)
    end
end

local function AttachToOwner(inst, owner)
    inst.entity:SetParent(owner.entity)
    if owner.components.colouradder ~= nil then
        owner.components.colouradder:AttachChild(inst)
    end
    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        SpawnFollowFxForOwner(inst, owner, CreateFxFollowFrame, 1, 3, true)
    end
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst:AddComponent("colouraddersync")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    inst.AttachToOwner = AttachToOwner
    inst.persists = false

    return inst
end

return  Prefab("honor_hat", fn, assets),
        Prefab("honor_hat_fx", fx_fn, assets)