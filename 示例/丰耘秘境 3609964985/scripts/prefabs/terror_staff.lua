local prefs = {}

---------------------------------------------------------------------------
---[[法杖]]
---------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/terror_staff.zip"),
}

local SWAP_DATA_BROKEN = { sym_build = "terror_staff", sym_name = "swap_object_broken_float", bank = "terror_staff", anim = "idle_broken" }
local SWAP_DATA = { sym_build = "terror_staff", sym_name = "swap_object", bank = "terror_staff", anim = "idle" }

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    inst.components.floater:SetBankSwapOnFloat(true, 0, SWAP_DATA_BROKEN)
end

local function OnRepaired(inst)
    inst.components.floater:SetBankSwapOnFloat(true, -9, SWAP_DATA)
end

local function DisableOwnerBlink(inst, owner)
    if owner ~= nil and owner:IsValid() and owner.components.hmrblinker ~= nil then
        owner.components.hmrblinker:RemoveSource(inst)
    end
end

local function EnableOwnerBlink(inst, owner)
    if owner ~= nil and owner:IsValid() and owner.components.hmrblinker ~= nil then
        local blink_data = {
            tintcolor = {17 / 255, 4 / 255, 102 / 255},
            blinkfx = {"terror_staff_blinkin_fx", "terror_staff_blinkout_fx"},
            onblinkin = function(_owner)
                local item = inst.components.container:GetItemInSlot(1)
                if item ~= nil then
                    if item.components.stackable ~= nil and item.components.stackable:IsStack() then
                        item.components.stackable:Get(1):Remove()
                    else
                        item:Remove()
                    end
                    inst:OnItemChanged()
                end
                if inst.components.finiteuses ~= nil then
                    inst.components.finiteuses:Use(1)
                end
            end,
        }
        owner.components.hmrblinker:AddSource(inst, blink_data)
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_object", inst.GUID, "terror_staff")
    else
        owner.AnimState:OverrideSymbol("swap_object", "terror_staff", "swap_object")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end

    local item = inst.components.container:GetItemInSlot(1)
    if item ~= nil then
        EnableOwnerBlink(inst, owner)
    end

    HMR_UTIL.AddCharacterSkill(owner, "plantkin")
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end

    if owner ~= nil and owner:IsValid() and owner.components.hmrblinker ~= nil then
        owner.components.hmrblinker:RemoveSource(inst)
    end

    HMR_UTIL.RemoveCharacterSkill(owner, "plantkin")
end

local function SetBonusEnabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:IsValid() then
        HMR_UTIL.AddCharacterSkill(owner, "tendplant")
    end
end

local function SetBonusDisabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:IsValid() then
        HMR_UTIL.RemoveCharacterSkill(owner, "tendplant")
    end
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function OnItemChanged(inst, data)
    local item = inst.components.container:GetItemInSlot(1)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil and owner.components.hmrblinker ~= nil then
        if item ~= nil then
            EnableOwnerBlink(inst, owner)
        else
            DisableOwnerBlink(inst, owner)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("terror_staff")
    inst.AnimState:SetBuild("terror_staff")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("weapon")
    inst:AddTag("terror_weapon")
    inst:AddTag("terror_repairable")
    inst:AddTag("HMR_repairable")

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9, SWAP_DATA)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.items_accepted = {}

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.HMR_TERROR_STAFF_BASE_DAMAGE)
    inst.components.weapon:SetRange(2, 2)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.HMR_TERROR_STAFF_PLANAR_DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.HMR_TERROR_STAFF_MAXUSES)
    inst.components.finiteuses:SetUses(TUNING.HMR_TERROR_STAFF_MAXUSES)
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

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("terror_staff")

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.TERROR_STAFF, atlasname = "images/inventoryimages/terror_staff.xml", imagename = "terror_staff", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.TERROR_STAFF_BROKEN, atlasname = "images/inventoryimages/terror_staff_broken.xml", imagename = "terror_staff_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:SetOnRepairedFn(OnRepaired)
    inst.components.hmrrepairable:Toggle()

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("itemget", OnItemChanged)
    inst:ListenForEvent("itemlose", OnItemChanged)

    inst.OnItemChanged = OnItemChanged

    return inst
end
table.insert(prefs, Prefab("terror_staff", fn, assets))

---------------------------------------------------------------------------
---[[传送特效]]
---------------------------------------------------------------------------
local function OnAnimOver(inst)
    inst:DoTaskInTime(2 * FRAMES, inst.Remove)
end

local function MakeFX(name, anim)
    local fx_assets =
    {
        Asset("ANIM", "anim/terror_staff_blink_fx.zip"),
    }

    local function fx_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("terror_staff_blink_fx")
        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:SetFinalOffset(3)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:ListenForEvent("animover", OnAnimOver)
        inst.persists = false

        return inst
    end

    table.insert(prefs, Prefab(name, fx_fn, fx_assets))
end

MakeFX("terror_staff_blinkin_fx", "wortox_portal_jumpin")
MakeFX("terror_staff_blinkout_fx", "wortox_portal_jumpout")

return unpack(prefs)