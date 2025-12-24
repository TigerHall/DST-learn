local prefs = {}

local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local FARM_PLANTS_LIST = require("hmrmain/hmr_lists").FARM_PLANTS_LIST


local OVERSIZED_PHYSICS_RADIUS = 0.1
local OVERSIZED_MAXWORK = 1
local OVERSIZED_PERISHTIME_MULT = 4

------------------------------------------------------------------------------
---[[种子]]
------------------------------------------------------------------------------
local function can_plant_seed(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

local function update_seed_placer_outline(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:CanTillSoilAtPoint(x, y, z) then
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
		inst.outline.Transform:SetPosition(cx, cy, cz)
		inst.outline:Show()
	else
		inst.outline:Hide()
	end
end

local function seed_placer_postinit(inst)
	inst.outline = SpawnPrefab("tile_outline")

	inst.outline.Transform:SetPosition(2, 0, 0)
	inst.outline:ListenForEvent("onremove", function() inst.outline:Remove() end, inst)
	inst.outline.AnimState:SetAddColour(.25, .75, .25, 0)
	inst.outline:Hide()

	inst.components.placer.onupdatetransform = update_seed_placer_outline
end

local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab(inst.components.farmplantable.plant)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    if plant.SoundEmitter then
        plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    end
    inst:Remove()
end

------------------------------------------------------------------------------
---[[巨大化作物]]
------------------------------------------------------------------------------
local function oversized_calcweightcoefficient(name)
    if PLANT_DEFS[name].weight_data[3] ~= nil and math.random() < PLANT_DEFS[name].weight_data[3] then
        return (math.random() + math.random()) / 2
    else
        return math.random()
    end
end

local function oversized_onequip(inst, owner)
	local swap = inst.components.symbolswapdata
    owner.AnimState:OverrideSymbol("swap_body", swap.build, swap.symbol)
end

local function oversized_onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function oversized_onfinishwork(inst, chopper)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function oversized_onburnt(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function oversized_makeloots(inst, name, special_loots)
    local product = name
	local seeds = name.."_seeds"

    local loots = {product, product, seeds, seeds, math.random() < 0.7 and product or seeds}

    if special_loots then
        if type(special_loots) == "table" then
            for prefab, chance in pairs(special_loots) do
                if math.random() <= chance then
                    table.insert(loots, prefab)
                end
            end
        elseif type(special_loots) == "function" then
            loots = special_loots(inst, loots)
        end
    end

    return loots
end

local function oversized_onperish(inst)
    -- vars for rotting on a gym
	local owner = inst.components.inventoryitem:GetGrandOwner()
	local gym = owner and owner:HasTag("gym") and owner or nil
    local rot = nil
    local slot = nil

	if owner and gym == nil then
        local loots = {}
        for i=1, #inst.components.lootdropper.loot do
            table.insert(loots, "spoiled_food")
        end
        inst.components.lootdropper:SetLoot(loots)
        inst.components.lootdropper:DropLoot()
    else
        rot = SpawnPrefab(inst.prefab.."_rotten")
        rot.Transform:SetPosition(inst.Transform:GetWorldPosition())
		if gym then
            slot = gym.components.inventory:GetItemSlot(inst)
        end
    end

    inst:Remove()

    if gym and rot then
        gym.components.mightygym:LoadWeight(rot, slot)
    end
end

local function Seed_GetDisplayName(inst)
	local registry_key = inst.plant_def.product

	local plantregistryinfo = inst.plant_def.plantregistryinfo
	return (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and
        ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) and
        STRINGS.NAMES["KNOWN_"..string.upper(inst.plant_def.seed)] or
        STRINGS.NAMES[string.upper(inst.plant_def.seed)]
end

local function Oversized_OnSave(inst, data)
	data.from_plant = inst.from_plant or false
    data.harvested_on_day = inst.harvested_on_day
end

local function Oversized_OnPreLoad(inst, data)
	inst.from_plant = (data and data.from_plant) ~= false
	if data ~= nil then
        inst.harvested_on_day = data.harvested_on_day
	end
end

local function displayadjectivefn(inst)
    return STRINGS.UI.HUD.WAXED
end

local function dowaxfn(inst, doer, waxitem)
    local waxedveggie = SpawnPrefab(inst.prefab.."_waxed")

    if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == inst then
        doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
        doer.components.inventory:Equip(waxedveggie)
    else
        waxedveggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
        waxedveggie.AnimState:PlayAnimation("wax_oversized", false)
        waxedveggie.AnimState:PushAnimation("idle_oversized")
    end

    inst:Remove()
    return true
end

local PlayWaxAnimation

local function CancelWaxTask(inst)
	if inst._waxtask ~= nil then
		inst._waxtask:Cancel()
		inst._waxtask = nil
	end
end

local function StartWaxTask(inst)
	if not inst.inlimbo and inst._waxtask == nil then
		inst._waxtask = inst:DoTaskInTime(GetRandomMinMax(20, 40), PlayWaxAnimation)
	end
end

PlayWaxAnimation = function(inst)
    inst.AnimState:PlayAnimation("wax_oversized", false)
    inst.AnimState:PushAnimation("idle_oversized")
end


local function MakeVeggie(name)
    local assets =
    {
        Asset("ANIM", "anim/hmr_products.zip"),
        Asset("ANIM", "anim/oceanfishing_lure_mis.zip"),
        Asset("ANIM", "anim/"..PLANT_DEFS[name].build..".zip")
    }

    local prefabs =
    {
        name .. "_cooked",
        name .. "seeds",
        name .. "_oversized",
        name .. "_oversized_waxed",
        name .. "_oversized_rotten",
        "splash_green",
        "farm_plant_" .. name,
        "spoiled_food",
    }

	local dryable = FARM_PLANTS_LIST[name].dryable

    --种子
    local function MakeSeeds(seeds_name, data)
        local prefab_name = data.common_seeds or seeds_name
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            MakeInventoryPhysics(inst)

            inst.AnimState:SetBank("hmr_products")
            inst.AnimState:SetBuild("hmr_products")
            inst.AnimState:PlayAnimation(prefab_name)
            inst.AnimState:SetRayTestOnBB(true)

            inst.pickupsound = "vegetation_firm"

            inst:AddTag("cookable")
            inst:AddTag("deployedplant")
            inst:AddTag("deployedfarmplant")
            inst:AddTag("oceanfishing_lure")

            inst.overridedeployplacername = "seeds_placer"

            inst.plant_def = PLANT_DEFS[name]
            inst.displaynamefn = Seed_GetDisplayName

            inst._custom_candeploy_fn = can_plant_seed -- for DEPLOYMODE.CUSTOM

            MakeInventoryFloatable(inst)

            inst:SetPrefabName(prefab_name)

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.SEEDS

            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

            inst:AddComponent("tradable")
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.imagename = prefab_name
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab_name..".xml"

            inst.components.edible.healthvalue = TUNING.HEALING_TINY / 2
            inst.components.edible.hungervalue = TUNING.CALORIES_TINY

            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"

            inst:AddComponent("cookable")
            inst.components.cookable.product = "seeds_cooked"

            inst:AddComponent("bait")

            inst:AddComponent("farmplantable")
            inst.components.farmplantable.plant = "farm_plant_"..name

            -- deprecated (used for crafted farm structures)
            inst:AddComponent("plantable")
            inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
            inst.components.plantable.product = name

            -- deprecated (used for wormwood)
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
            inst.components.deployable.restrictedtag = "plantkin"
            inst.components.deployable.ondeploy = OnDeploy

            inst:AddComponent("oceanfishingtackle")
            inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})

            MakeSmallBurnable(inst)
            MakeSmallPropagator(inst)

            MakeHauntableLaunchAndPerish(inst)

            return inst
        end

        table.insert(prefs, Prefab(seeds_name, fn, assets, prefabs))
    end

    --果实
    local function MakeFruit(fruit_name, data)
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            MakeInventoryPhysics(inst)

            inst.AnimState:SetBank("hmr_products")
            inst.AnimState:SetBuild("hmr_products")
            inst.AnimState:PlayAnimation(fruit_name)

            inst.pickupsound = "vegetation_firm"

            --cookable (from cookable component) added to pristine state for optimization
            inst:AddTag("cookable")

            -- 标记《丰耘秘境》农作物产品
            inst:AddTag("hmr_product")

            if dryable ~= nil then
                --dryable (from dryable component) added to pristine state for optimization
                inst:AddTag("dryable")
            end

            --weighable (from weighable component) added to pristine state for optimization
            inst:AddTag("weighable_OVERSIZEDVEGGIES")

            local float = FARM_PLANTS_LIST[name].float_settings
            if float ~= nil then
                MakeInventoryFloatable(inst, float[1], float[2], float[3])
            else
                MakeInventoryFloatable(inst)
            end

            if FARM_PLANTS_LIST[name].lure_data ~= nil then
                inst:AddTag("oceanfishing_lure")
            end

            if data.common_postinit ~= nil then
                data.common_postinit(inst)
            end

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst:AddComponent("edible")
            inst.components.edible.healthvalue = data.health or 0
            inst.components.edible.hungervalue = data.hunger or 0
            inst.components.edible.sanityvalue = data.sanity or 0
            inst.components.edible.foodtype = FOODTYPE.VEGGIE
            inst.components.edible.secondaryfoodtype = data.secondary_foodtype

            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime or TUNING.PERISH_MED)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"

            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

            if dryable ~= nil then
                inst:AddComponent("dryable")
                inst.components.dryable:SetProduct(name.."_dried")
                inst.components.dryable:SetBuildFile(dryable.build)
                inst.components.dryable:SetDryTime(dryable.time)
            end

            inst:AddComponent("inspectable")

            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.imagename = fruit_name
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..fruit_name..".xml"

            -- Regular veggies are weighable but don't have a weight. They all show the same
            -- result when put in a trophyscale_oversizedveggies, and always replace other
            -- regular veggies when attempting to do so.
            inst:AddComponent("weighable")
            inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDVEGGIES

            MakeSmallBurnable(inst)

            MakeSmallPropagator(inst)

            inst:AddComponent("bait")

            inst:AddComponent("tradable")

            inst:AddComponent("cookable")
            inst.components.cookable.product = fruit_name.."_cooked"

            if data.lure_data ~= nil then
                inst:AddComponent("oceanfishingtackle")
                inst.components.oceanfishingtackle:SetupLure(data.lure_data)
            end

            MakeHauntableLaunchAndPerish(inst)

            if data.master_postinit ~= nil then
                data.master_postinit(inst)
            end

            return inst
        end

        table.insert(prefs, Prefab(fruit_name, fn, assets, prefabs))
    end

    --烹饪果实
    local function MakeCooked(cooked_name, data)
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            MakeInventoryPhysics(inst)

            inst.AnimState:SetBank("hmr_products")
            inst.AnimState:SetBuild("hmr_products")
            inst.AnimState:PlayAnimation(cooked_name)

            local float = data.float_settings
            if float ~= nil then
                MakeInventoryFloatable(inst, float[1], float[2], float[3])
            else
                MakeInventoryFloatable(inst)
            end

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"

            inst:AddComponent("edible")
            inst.components.edible.healthvalue = data.health or 0
            inst.components.edible.hungervalue = data.hunger or 0
            inst.components.edible.sanityvalue = data.sanity or 0
            inst.components.edible.foodtype = FOODTYPE.VEGGIE
            inst.components.edible.secondaryfoodtype = data.secondary_foodtype

            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

            inst:AddComponent("inspectable")

            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..cooked_name..".xml"

            MakeSmallBurnable(inst)
            MakeSmallPropagator(inst)

            inst:AddComponent("bait")

            inst:AddComponent("tradable")

            MakeHauntableLaunchAndPerish(inst)

            if data.master_postinit ~= nil then
                data.master_postinit(inst)
            end

            return inst
        end

        table.insert(prefs, Prefab(cooked_name, fn, assets))
    end

    --巨大果实
    local function MakeOversized(oversized_name, data)
        print("MakeOversized", oversized_name, data)
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            local plant_def = PLANT_DEFS[name]

            inst.AnimState:SetBank(plant_def.bank)
            inst.AnimState:SetBuild(plant_def.build)
            inst.AnimState:PlayAnimation("idle_oversized")
            inst.scrapbook_anim = "idle_oversized"

            inst:AddTag("heavy")
            inst:AddTag("waxable")
            inst:AddTag("oversized_veggie")
            inst:AddTag("show_spoilage")
            inst.gymweight = 4

            MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
            inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

            inst._base_name = name

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst.harvested_on_day = inst.harvested_on_day or (TheWorld.state.cycles + 1)

            inst:AddComponent("heavyobstaclephysics")
            inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)

            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime((data.perishtime or TUNING.PERISH_MED) * OVERSIZED_PERISHTIME_MULT)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = nil
            inst.components.perishable:SetOnPerishFn(oversized_onperish)

            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem:SetSinks(true)
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..oversized_name..".xml"

            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(oversized_onequip)
            inst.components.equippable:SetOnUnequip(oversized_onunequip)
            inst.components.equippable.walkspeedmult = name ~= "terror_ginger" and TUNING.HEAVY_SPEED_MULT or nil

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

            inst:AddComponent("waxable")
            inst.components.waxable:SetWaxfn(dowaxfn)

            inst:AddComponent("submersible")

            inst:AddComponent("symbolswapdata")
            inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

            local weight_data = plant_def.weight_data

            inst:AddComponent("weighable")
            inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDVEGGIES
            inst.components.weighable:Initialize(weight_data[1], weight_data[2])
            local coefficient = oversized_calcweightcoefficient(name)
            inst.components.weighable:SetWeight(Lerp(weight_data[1], weight_data[2], coefficient))

            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(oversized_makeloots(inst, name, data.special_loots))

            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)

            MakeHauntableWork(inst)

            inst.from_plant = false

            inst.OnSave = Oversized_OnSave
            inst.OnPreLoad = Oversized_OnPreLoad

            if data.master_postinit ~= nil then
                data.master_postinit(inst)
            end

            return inst
        end

        table.insert(prefs, Prefab(oversized_name, fn, assets, prefabs))
    end

    --巨型打蜡果实
    local function MakeOversizedWaxed(oversized_name, data)
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            local plant_def = PLANT_DEFS[name]

            inst.AnimState:SetBank(plant_def.bank)
            inst.AnimState:SetBuild(plant_def.build)
            inst.AnimState:PlayAnimation("idle_oversized")
            inst.scrapbook_anim = "idle_oversized"

            inst:AddTag("heavy")
            inst:AddTag("oversized_veggie")

            inst.gymweight = 4

            inst.displayadjectivefn = displayadjectivefn
            inst:SetPrefabNameOverride(oversized_name)

            MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
            inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

            inst._base_name = name

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst:AddComponent("heavyobstaclephysics")
            inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)

            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem:SetSinks(true)
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..oversized_name..".xml"

            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(oversized_onequip)
            inst.components.equippable:SetOnUnequip(oversized_onunequip)
            inst.components.equippable.walkspeedmult = name ~= "terror_ginger" and TUNING.HEAVY_SPEED_MULT or nil

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

            inst:AddComponent("submersible")
            inst:AddComponent("symbolswapdata")
            inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot({"spoiled_food"})

            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)

            MakeHauntableWork(inst)

            inst:ListenForEvent("onputininventory", CancelWaxTask)
            inst:ListenForEvent("ondropped", StartWaxTask)

            inst.OnEntitySleep = CancelWaxTask
            inst.OnEntityWake = StartWaxTask

            StartWaxTask(inst)

            if data.master_postinit ~= nil then
                data.master_postinit(inst, "waxed")
            end

            return inst
        end
        table.insert(prefs, Prefab(oversized_name, fn, assets, prefabs))
    end

    --巨型腐烂果实定义
    local function MakeOversizedRotten(oversized_name, data)
        local function fn()
            local inst = CreateEntity()

            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddNetwork()

            local plant_def = PLANT_DEFS[name]

            inst.AnimState:SetBank(plant_def.bank)
            inst.AnimState:SetBuild(plant_def.build)
            inst.AnimState:PlayAnimation("idle_rot_oversized")
            inst.scrapbook_anim = "idle_rot_oversized"

            inst:AddTag("heavy")
            inst:AddTag("farm_plant_killjoy")
            inst:AddTag("pickable_harvest_str")
            inst:AddTag("pickable")
            inst:AddTag("oversized_veggie")
            inst.gymweight = 3

            MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
            inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

            inst._base_name = name

            inst.entity:SetPristine()

            if not TheWorld.ismastersim then
                return inst
            end

            inst:AddComponent("heavyobstaclephysics")
            inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)

            inst:AddComponent("inspectable")
            inst.components.inspectable.nameoverride = "VEGGIE_OVERSIZED_ROTTEN"--覆盖原描述

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

            inst:AddComponent("pickable")
            inst.components.pickable.remove_when_picked = true
            inst.components.pickable:SetUp(nil)
            inst.components.pickable.use_lootdropper_for_product = true
            inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            --inst.components.inventoryitem.canbepickedup = false
            inst.components.inventoryitem:SetSinks(true)
            inst.components.inventoryitem:ChangeImageName(oversized_name)
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..oversized_name..".xml"

            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(oversized_onequip)
            inst.components.equippable:SetOnUnequip(oversized_onunequip)
            inst.components.equippable.walkspeedmult = name ~= "terror_ginger" and TUNING.HEAVY_SPEED_MULT or nil

            inst:AddComponent("submersible")
            inst:AddComponent("symbolswapdata")
            inst.components.symbolswapdata:SetData(plant_def.build, "swap_body_rotten")

            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(plant_def.loot_oversized_rot)

            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)

            MakeHauntableWork(inst)

            return inst
        end
        table.insert(prefs, Prefab(oversized_name, fn, assets, prefabs))
    end


    local data = FARM_PLANTS_LIST[name]

    local fruits_data = data.fruits
    for fruit_name, fruit_data in pairs(fruits_data) do
        MakeFruit(fruit_name, fruit_data)
    end

    local cooked_fruits_data = data.cooked
    for cooked_name, cooked_data in pairs(cooked_fruits_data) do
        MakeCooked(cooked_name, cooked_data)
    end

    local seeds_data = data.seeds
    for seed_name, seed_data in pairs(seeds_data) do
        MakeSeeds(seed_name, seed_data)
    end

    MakeOversized(name.."_oversized", data.oversized and data.oversized[name.."_oversized"] or {})
    MakeOversizedWaxed(name.."_oversized_waxed", data.oversized_waxed and data.oversized_waxed[name.."_oversized_waxed"] or {})
    MakeOversizedRotten(name.."_oversized_rotten", data.oversized_rotten and data.oversized_rotten[name.."_oversized_rotten"] or {})
end

for veggiename, veggiedata in pairs(FARM_PLANTS_LIST) do
    MakeVeggie(veggiename)
end

return unpack(prefs)
