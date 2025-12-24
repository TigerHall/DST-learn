local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local scrapbook_removedeps =
{
	"berries",
	"cave_banana",
	"cactus_meat",
	"berries_juicy",
	"fig",
	"kelp",
}

local assets =
{
    Asset("ANIM", "anim/hmr_randomseeds.zip"),
}

local function CanPlantSeed(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

local function OnDeploy2(inst, pt, deployer) --, rot)
    local farm_plant_prefab = "farm_plant_"..inst._type.."_seeds"
    local plant = SpawnPrefab(farm_plant_prefab)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    --plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    inst:Remove()
end

local function PickProduct(inst)
    local total_w = 0
    for k,v in pairs(PLANT_DEFS) do
        if v.honor_plant then
            total_w = total_w + (v[inst._type.."_weight"] or 1)
        end
    end

    local rnd = math.random() * total_w
    for k,v in pairs(PLANT_DEFS) do
        if v.honor_plant then
            rnd = rnd - (v[inst._type.."_weight"] or 1)
            if rnd <= 0 then
                return k
            end
        end
    end

    return "carrot"
end

local function MakeSeeds(name, type)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("hmr_randomseeds")
        inst.AnimState:SetBuild("hmr_randomseeds")
        inst.AnimState:PlayAnimation(type.."_seed")
        inst.AnimState:SetRayTestOnBB(true)

        inst.pickupsound = "vegetation_firm"

        inst:AddTag("deployedplant")
        inst:AddTag("deployedfarmplant")
        inst:AddTag("cookable")
        inst:AddTag("oceanfishing_lure")

        inst.overridedeployplacername = "seeds_placer"

        MakeInventoryFloatable(inst)

        inst._custom_candeploy_fn = CanPlantSeed

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst._type = type

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..inst._type.."_seeds.xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.SEEDS
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = TUNING.CALORIES_TINY/2

        inst:AddComponent("bait")

        inst:AddComponent("farmplantable")
        inst.components.farmplantable.plant = "farm_plant_"..inst._type.."_seeds"

        inst:AddComponent("oceanfishingtackle")
        inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        inst.components.deployable.restrictedtag = "plantkin"
        inst.components.deployable.ondeploy = OnDeploy2

        inst:AddComponent("plantable")
        inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
        inst.components.plantable.product = PickProduct

        inst:AddComponent("cookable")
        inst.components.cookable.product = "seeds_cooked"

        inst:AddComponent("tradable")
        inst:AddComponent("inspectable")

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst.scrapbook_removedeps = scrapbook_removedeps

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeSeeds("terror_seeds", "terror"),
    MakeSeeds("honor_seeds", "honor")