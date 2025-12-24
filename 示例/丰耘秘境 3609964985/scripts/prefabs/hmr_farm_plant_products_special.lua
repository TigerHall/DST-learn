local PREFABS = {}

local FARM_PLANT_LIST = require("hmrmain/hmr_lists").FARM_PLANTS_LIST

------------------------------------------------------------------------------------------------
---[[库存物品]]
------------------------------------------------------------------------------------------------
local function MakeInventoryItem(name, data)
    local assets = {}
    local build = data.build or name
    local bank = data.bank or data.build or name
    if data.assets ~= nil then
        for _, v in pairs(data.assets) do
            table.insert(assets, v)
        end
    else
        table.insert(assets, Asset("ANIM", "anim/"..build..".zip"))
        if build ~= bank then
            table.insert(assets, Asset("ANIM", "anim/"..bank..".zip"))
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation(data.anim or "idle")

        MakeInventoryFloatable(inst, "small", .1)

        if data.common_postinit then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = data.stacksize or TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("tradable")

        MakeHauntableLaunch(inst)

        if data.burnable then
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            MakeSmallPropagator(inst)
        end

        if data.master_postinit then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(PREFABS, Prefab(name, fn, assets))
end

-- 芦荟胶
MakeInventoryItem("honor_aloe_mucous", {
    burnable = true,
    common_postinit = function(inst)
        local function GetFertilizerKey(inst)
            return inst.prefab
        end
        inst.GetFertilizerKey = GetFertilizerKey

        inst:AddTag("fertilizerresearchable")
        --selfstacker (from selfstacker component) added to pristine state for optimization
        inst:AddTag("selfstacker")

        MakeDeployableFertilizerPristine(inst)
    end,
    master_postinit = function(inst)
        inst:AddComponent("fertilizer")
        inst.components.fertilizer.fertilizervalue = TUNING.TOTAL_DAY_TIME * 8
        inst.components.fertilizer.soil_cycles = 20
        inst.components.fertilizer.withered_cycles = 2
        inst.components.fertilizer:SetNutrients({32, 32, 32})

        local function fertilizerresearchfn(inst)
            return inst:GetFertilizerKey()
        end
        inst:AddComponent("fertilizerresearchable")
        inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

        inst:AddComponent("healer")
        inst.components.healer:SetHealthAmount(TUNING.HEALING_MEDLARGE)

        inst:AddComponent("selfstacker")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        inst:AddComponent("tradable")

        MakeDeployableFertilizer(inst)
    end,
})

-- 植物清汁
MakeInventoryItem("honor_greenjuice", {
    master_postinit = function(inst)
        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 1
        inst.components.edible.hungervalue = 5
        inst.components.edible.sanityvalue = 30
        inst.components.edible.foodtype = FOODTYPE.GOODIES

        local function OnUseAsWatersource(inst)
            if inst.components.stackable:IsStack() then
                inst.components.stackable:Get():Remove()
            else
                inst:Remove()
            end
        end
        inst:AddComponent("watersource")
        inst.components.watersource.onusefn = OnUseAsWatersource
        inst.components.watersource.override_fill_uses = 4
    end,
})

-- 金灯果皮
MakeInventoryItem("honor_goldenlanternfruit_peel", {
    build = "hmr_products",
    anim = "honor_goldenlanternfruit_peel",
})

------------------------------------------------------------------------------------------------
---[[装备]]
------------------------------------------------------------------------------------------------
-- 蓝莓帽
local function blueberrycap_onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "terror_blueberry_hat", 'swap_hat')
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAT_HAIR")
	owner.AnimState:Hide("HAIR_NOHAT")
    --owner.AnimState:Hide("HAIR")
end

local function blueberrycap_onunequip(inst, owner)
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAT_HAIR")
	owner.AnimState:Show("HAIR_NOHAT")
	--owner.AnimState:Show("HAIR")
end

local function blueberrycap_onperish(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

table.insert(PREFABS, Prefab("terror_blueberry_hat", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("terror_blueberry_hat")
    inst.AnimState:SetBuild("terror_blueberry_hat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("show_spoilage")

    MakeInventoryFloatable(inst)
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.66)

    local swap_data = { bank = "terror_blueberry_hat", anim = "anim" }
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/terror_blueberry_hat.xml"

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(blueberrycap_onequip)
    inst.components.equippable:SetOnUnequip(blueberrycap_onunequip)
    inst.components.equippable.equippedmoisture = 1
    inst.components.equippable.maxequippedmoisture = 99

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.droprecipeloot = false
    inst.components.lootdropper:SetLoot({"bluegem", "bluegem", "bluegem", "terror_mucous"})

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.TOTAL_DAY_TIME * 2)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(blueberrycap_onperish)

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/terror_blueberry_hat.zip"),
}))


--[[ 巨大椰子壳,,应该是坚果壳
local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function ProtectionLevels(inst, data)
    local equippedArmor = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    if equippedArmor ~= nil then
        if inst.sg:HasStateTag("shell") then
            equippedArmor.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        else
            equippedArmor.components.armor:SetAbsorption(TUNING.ARMORSNURTLESHELL_ABSORPTION)
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
        inst.task = inst:DoTaskInTime(5, droptargets)
    end
end

local function onstopuse(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body_tall", "honor_huge_coconut_shell", "swap_body_tall")
    inst:ListenForEvent("blocked", OnBlocked, owner)
    inst:ListenForEvent("newstate", ProtectionLevels, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body_tall")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
    inst:RemoveEventCallback("newstate", ProtectionLevels, owner)
    onstopuse(inst)
end

local function onhammered(inst, worker)
    -- 锤击后在原地生成植物纤维
    if inst.components.lootdropper == nil then
        inst:AddComponent("lootdropper")
    end
    inst.components.lootdropper:SpawnLootPrefab("honor_splendor")
    inst:Remove()
end

table.insert(PREFABS, Prefab("honor_huge_coconut_shell", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_huge_coconut_shell")
    inst.AnimState:SetBuild("honor_huge_coconut_shell")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("shell")

    MakeInventoryFloatable(inst, "med", 0.2, 0.70)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_huge_coconut_shell.xml"
	inst.components.inventoryitem.imagename = "honor_huge_coconut_shell"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(1000, 0.45)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onuse)
    inst.components.useableitem:SetOnStopUseFn(onstopuse)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst:AddComponent("lootdropper")

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/honor_huge_coconut_shell.zip"),
    Asset("ATLAS", "images/inventoryimages/honor_huge_coconut_shell.xml"),
    Asset("IMAGE", "images/inventoryimages/honor_huge_coconut_shell.tex"),
}))]]



-- 巨大椰子壳
local function coconutshell_onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "honor_coconut_hat", "swap_hat")
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAT_HAIR")
	owner.AnimState:Hide("HAIR_NOHAT")
    --owner.AnimState:Hide("HAIR")

end

local function coconutshell_onunequip(inst, owner)
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAT_HAIR")
	owner.AnimState:Show("HAIR_NOHAT")
	--owner.AnimState:Show("HAIR")
end

table.insert(PREFABS, Prefab("honor_coconut_hat", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_coconut_hat")
    inst.AnimState:SetBuild("honor_coconut_hat")
    inst.AnimState:PlayAnimation("anim")
    inst.AnimState:SetScale(1.2, 1.2)

    inst:AddTag("hat")
    inst:AddTag("show_spoilage")
    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst)
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.7)

    local swap_data = { bank = "honor_coconut_hat", anim = "anim" }
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_coconut_hat.xml"
	inst.components.inventoryitem.imagename = "honor_coconut_hat"

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(coconutshell_onequip)
    inst.components.equippable:SetOnUnequip(coconutshell_onunequip)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMOR_SLURTLEHAT, TUNING.ARMOR_SLURTLEHAT_ABSORPTION)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/honor_coconut_hat.zip"),
}))

------------------------------------------------------------------------------------------------
---[[其他]]
------------------------------------------------------------------------------------------------
-- 自然亲和子塔指示器
local SCALE = 1--指示器范围  1.5是30
table.insert(PREFABS, Prefab("reticuleaoecatapulttakecare", function()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("winona_catapult_placement")
    inst.AnimState:SetBuild("winona_catapult_placement")
    inst.AnimState:PlayAnimation("idle_16d6")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed or ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(SCALE, SCALE)

    inst.deployhelper_key = "catapult_wakeup"
	inst.AnimState:SetLightOverride(1)

    return inst
end, {
    Asset("ANIM", "anim/winona_catapult_placement.zip")
}))

-- 金灯果灯光
do
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("daylight")

        inst.Light:SetFalloff(0.4)
        inst.Light:SetIntensity(.7)
        inst.Light:SetRadius(.5)
        inst.Light:SetColour(255 / 255, 165 / 255, 0 / 255)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        return inst
    end

    table.insert(PREFABS, Prefab("honor_goldenlanternfruit_light", fn))
end

return unpack(PREFABS)