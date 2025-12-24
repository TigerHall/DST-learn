--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    小蜗护甲

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_snail_shell_of_mushroom"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_snail_shell_of_mushroom.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 使用壳子
    local function OnBlocked(owner)
        owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
    end

    local function ProtectionLevels(inst, data)
        local equippedArmor = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
        if equippedArmor ~= nil then
            if inst.sg:HasStateTag("shell") then
                equippedArmor.components.armor:SetAbsorption(1)
            else
                local updated_shell_armor = equippedArmor.components.tbat_data and equippedArmor.components.tbat_data:Get("shell_armor")
                -- print("updated_shell_armor:",equippedArmor, updated_shell_armor)
                equippedArmor.components.armor:SetAbsorption(updated_shell_armor or 0.6)
                equippedArmor.components.useableitem:StopUsingItem()
            end
        end
    end

    local TARGET_MUST_TAGS = { "_combat" }
    local TARGET_CANT_TAGS = { "INLIMBO" }
    local function droptargets(inst)
        inst.task = nil

        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil and owner.sg:HasStateTag("shell") then
            local x, y, z = owner.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
            for i, v in ipairs(ents) do
                if v.components.combat ~= nil and v.components.combat.target == owner then
                    v.components.combat:SetTarget(nil)
                end
            end
        end
    end

    local function onuse(inst)
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil then
            owner.sg:GoToState("shell_enter")
            if inst.task ~= nil then
                inst.task:Cancel()
            end
            inst.task = inst:DoTaskInTime(10, droptargets)
        end
    end

    local function onstopuse(inst)
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 穿脱
    local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_body_tall", "tbat_eq_snail_shell_of_mushroom", "swap_body_tall")
        inst:ListenForEvent("blocked", OnBlocked, owner)
        inst:ListenForEvent("newstate", ProtectionLevels, owner)


    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_body_tall")
        inst:RemoveEventCallback("blocked", OnBlocked, owner)
        inst:RemoveEventCallback("newstate", ProtectionLevels, owner)
        onstopuse(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local level_sys_install_fn = require("prefabs/03_tbat_equipments/07_02_snail_shell_level_sys")
    local acceptable_com_install_fn = require("prefabs/03_tbat_equipments/07_03_snail_shell_acceptable_com")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("tbat_eq_snail_shell_of_mushroom")
    inst.AnimState:SetBuild("tbat_eq_snail_shell_of_mushroom")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("shell")
	inst:AddTag("hardarmor")

    inst.foleysound = "dontstarve/movement/foley/shellarmour"

    MakeInventoryFloatable(inst, "med", 0.2, 0.70)

    inst.entity:SetPristine()
    --------------------------------------------------------
    --- 等级系统
        level_sys_install_fn(inst)
        acceptable_com_install_fn(inst)
    --------------------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    --------------------------------------------------------
    --- 状态机和名字控制
        inst:AddComponent("tbat_data")
        inst:AddComponent("named")
    --------------------------------------------------------
    --- 物品检查
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_eq_snail_shell_of_mushroom","images/inventoryimages/tbat_eq_snail_shell_of_mushroom.xml")
    --------------------------------------------------------
    --- 盔甲
        inst:AddComponent("armor")
        inst.components.armor:InitCondition(1000, 0.6)
    --------------------------------------------------------
    --- 穿戴
        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
    --------------------------------------------------------
    --- 物品使用
        inst:AddComponent("useableitem")
        inst.components.useableitem:SetOnUseFn(onuse)
        inst.components.useableitem:SetOnStopUseFn(onstopuse)
        inst.components.equippable.walkspeedmult = 1
    --------------------------------------------------------
    ---
        MakeHauntableLaunch(inst)
    --------------------------------------------------------

    --------------------------------------------------------
    return inst
end

return Prefab(this_prefab, fn, assets)

