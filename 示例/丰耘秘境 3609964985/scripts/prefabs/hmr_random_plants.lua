local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local SEEDS_DEFS = require("hmrmain/hmr_farm_plant")
local terror_def = SEEDS_DEFS.terror_seeds
local honor_def = SEEDS_DEFS.honor_seeds

local KILLJOY_PLANT_MUST_TAGS = {"farm_plant_killjoy"}
local POLLEN_SOURCE_NOT_TAGS = {"farm_plant_killjoy"}
local spoiled_food_loot = {"spoiled_food"}
local WEIGHTED_SEED_TABLE = require("prefabs/weed_defs").weighted_seed_table
local CANGROW_TAGS = { "daylight", "lightsource" }


local function IsTooDarkToGrow(inst)
if TheWorld.state.isnight and not inst.components.growable:GetCurrentStageData().night_grow then
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.DAYLIGHT_SEARCH_RANGE, CANGROW_TAGS)) do
        local lightrad = v.Light:GetCalculatedRadius() * .7
        if v:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
            return false
        end
    end
    return true
end
return false
end

--获取植物注册表键
local function GetPlantRegistryKey(inst)
    return inst.plantregistrykey
end

--获取研究阶段的
local function GetResearchStage(inst)
    return inst._research_stage:value() + 1	-- +1 to make it 1 a based rage
end

--获取显示名称
local function GetDisplayName(inst)
    local plantregistryinfo = inst.plant_def.plantregistryinfo
    if plantregistryinfo == nil then
        return nil
    end
    local research_stage = inst:GetResearchStage()
    local research_stage_info = plantregistryinfo[research_stage]
    local registry_key = inst:GetPlantRegistryKey()

    if research_stage_info == nil then
        return nil
    end
    local player_is_farmplantidentifier = (ThePlayer ~= nil and ThePlayer:HasTag("farmplantidentifier"))

    if research_stage_info.learnseed then
        local seed_name = string.upper(inst.plant_def.seed)
        if player_is_farmplantidentifier or (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) then
            seed_name = "KNOWN_"..seed_name
        end
        return subfmt(STRINGS.NAMES.FARM_PLANT_SEED, {seed = STRINGS.NAMES[seed_name]})
    end

    return (research_stage_info.is_rotten and STRINGS.NAMES.FARM_PLANT_ROTTEN)
        or (not (player_is_farmplantidentifier or ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo, research_stage)) and STRINGS.NAMES.FARM_PLANT_UNKNOWN)
        or nil
end

local function PushFruitFlySpawnerEvent(inst)
    if inst:HasTag("fruitflyspawner") then
        TheWorld:PushEvent("ms_fruitflyspawneractive", {plant = inst, check_others = false})
    end
end

local function UpdateResearchStage(inst, stage)
    if stage == 5 and inst.is_oversized then
        stage = 6
    elseif stage == 6 then
        stage = inst.is_oversized and 8 or 7
    end

    inst._research_stage:set(stage - 1) -- to make it a 0 a based range
end

local function GetStatus(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        return "BURNING"
    end

    local stage_data = inst.components.growable:GetCurrentStageData()

    local str = stage_data ~= nil and stage_data.inspect_str or nil

    if inst.is_oversized then
        str = str.."_OVERSIZED"
    end

    return str
end

--用于生成随机种子植物的描述信息
local function RandomSeedDescriptionFn(inst, viewer)
    if not viewer:HasTag("farmplantidentifier") then
        return nil
    end

    local plant_type = inst._identified_plant_type or inst:BeIdentified(viewer)

    return (plant_type and GetDescription(viewer, inst, inst.components.inspectable:GetStatus(viewer)) .. " " .. STRINGS.NAMES[string.upper(plant_type)])
        or nil
end

local function plantresearchfn(inst)
    return inst:GetPlantRegistryKey(), inst:GetResearchStage()
end

local function KillJoyStressTest(inst, currentstress, apply)
    local x, y, z = inst.Transform:GetWorldPosition()
    return #TheSim:FindEntities(x, y, z, TUNING.FARM_PLANT_KILLJOY_RADIUS, KILLJOY_PLANT_MUST_TAGS) > inst.plant_def.max_killjoys_tolerance
end

local function FamilyStressTest(inst, currentstress, apply)
    local x, y, z = inst.Transform:GetWorldPosition()
    local num_plants = inst.plant_def.family_min_count > 0 and #TheSim:FindEntities(x, y, z, inst.plant_def.family_check_dist, {inst.plant_def.plant_type_tag}, POLLEN_SOURCE_NOT_TAGS) or 0
    return num_plants < inst.plant_def.family_min_count
end

local function OvercrowdingStressTest(inst, currentstress, apply)
    local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(inst.Transform:GetWorldPosition())
    local count = 0
    for i = 1, #ents do
        if ents[i]:HasTag("farm_plant") then
            count = count + 1
            if count > TUNING.FARM_PANT_OVERCROWDING_MAX_PLANTS then
                return true
            end
        end
    end
    return false
end

local function SeasonStressTest(inst, currentstress, apply)
    return not inst.plant_def.good_seasons[TheWorld.state.season]
end

local function MoistureStressTest(inst, currentstress, apply)
    local moisture = inst.components.farmsoildrinker
    if moisture then
        return moisture:CalcPercentTimeHydrated() < inst.plant_def.moisture.min_percent
    end
    return false
end

local function NutrientsStressTest(inst, currentstress, apply)
    local x, y, z = inst.Transform:GetWorldPosition()
    if TheWorld.components.farming_manager then
        return TheWorld.components.farming_manager:CycleNutrientsAtPoint(x, y, z, inst.plant_def.nutrient_consumption, inst.plant_def.nutrient_restoration, not apply)
    end
    return true
end

local function HappinessStressTest(inst, currentstress, apply)
    return currentstress
end

local function on_happiness_changed(inst, stressed, doer)
    inst:DoTaskInTime(0.5 + math.random() * 0.5, function()
        local fx = SpawnPrefab(stressed and "farm_plant_unhappy" or "farm_plant_happy")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end)
end

local function GetDrinkRate(inst)
    return (inst.components.growable == nil or inst.components.growable:IsGrowing()) and inst.plant_def.moisture.drink_rate or 0
end

local function OnSoilMoistureStateChange(inst, is_soil_moist, was_soil_moist)
    inst.components.farmsoildrinker:UpdateMoistureTime(is_soil_moist, was_soil_moist)
end

local function ontendto(inst, doer)
    inst.components.farmplantstress:SetStressed("happiness", false, doer)
    return true
end

local function SetupLoot(lootdropper)
    local inst = lootdropper.inst

    if inst:HasTag("farm_plant_killjoy") then
        lootdropper:SetLoot(inst.is_oversized and inst.plant_def.loot_oversized_rot or spoiled_food_loot)
    elseif inst.components.pickable ~= nil then
        local plant_stress = inst.components.farmplantstress ~= nil and inst.components.farmplantstress:GetFinalStressState() or FARM_PLANT_STRESS.HIGH
        if inst.is_oversized then
            lootdropper:SetLoot({inst.plant_def.product_oversized})
        elseif plant_stress == FARM_PLANT_STRESS.LOW or plant_stress == FARM_PLANT_STRESS.NONE then
            lootdropper:SetLoot({inst.plant_def.product, inst.plant_def.seed, inst.plant_def.seed})
        elseif plant_stress == FARM_PLANT_STRESS.MODERATE then
            lootdropper:SetLoot({inst.plant_def.product, inst.plant_def.seed})
        else -- plant_stress == FARM_PLANT_STRESS.HIGH
            lootdropper:SetLoot({inst.plant_def.product})
        end
    end
end

local function GetGerminationTime(inst, stage_num, stage_data)
    local is_good_season = inst.plant_def.good_seasons[TheWorld.state.season]
    local grow_time = inst.plant_def.grow_time.seed
    return GetRandomMinMax(grow_time[1], grow_time[2]) * (is_good_season and 0.5 or 1)
end

local function MakePlantedSeed(inst, seed_state)
    if seed_state then
        inst:AddTag("planted_seed")
    else
        inst:RemoveTag("planted_seed")
    end
end

local function PlaySound(inst, sound)
    local sounds = inst.plant_def.sounds
    if sounds ~= nil and sounds[sound] ~= nil then
        inst.SoundEmitter:PlaySound(sounds[sound])
    end
end

local function PlaySowAnim(inst)
    if POPULATING or inst:IsAsleep() then
        inst.AnimState:PlayAnimation("sow_idle", true)
    else
        inst.AnimState:PlayAnimation("sow", false)
        inst.AnimState:PushAnimation("sow_idle", true)

        PlaySound(inst, "sow")
    end
end

local function CalcGrowTime(step, num_steps, min_time, max_time)
    local max_var = max_time - min_time
    local var_per_point = max_var / num_steps

    return min_time + step * var_per_point + math.random()*var_per_point
end

local function GetGrowTime(inst, stage_num, stage_data)
    local grow_time = inst.plant_def.grow_time[stage_data.name]
    local is_good_season = inst.plant_def.good_seasons[TheWorld.state.season]

    if grow_time ~= nil and inst.components.farmplantstress ~= nil then
        return CalcGrowTime(inst.components.farmplantstress.checkpoint_stress_points, inst.components.farmplantstress.num_stressors + 1, grow_time[1], grow_time[2]) * (is_good_season and 0.5 or 1)
    end
end

local function RepeatMagicGrowth(inst)
    inst._magicgrowthtask = nil
    if inst.components.growable ~= nil then
        inst.components.growable:DoMagicGrowth()
    end
end

local function domagicgrowthfn(inst)
    if inst._magicgrowthtask ~= nil then
        inst._magicgrowthtask:Cancel()
        inst._magicgrowthtask = nil
    end

    if inst.magic_growth_delay ~= nil then
        inst:AddTag("magicgrowth")
        inst._magicgrowthtask = inst:DoTaskInTime(inst.magic_growth_delay, RepeatMagicGrowth)
        inst.magic_growth_delay = nil
        return true
    end

    if inst.components.burnable == nil or not inst.components.burnable:IsBurning() then
        inst.components.growable:Resume()
    end

    if inst.components.growable:IsGrowing() then
        inst.no_oversized = true

        if inst.components.farmsoildrinker ~= nil then
            local remaining_time = inst.components.growable.targettime - GetTime()
            local drink = remaining_time * inst.components.farmsoildrinker:GetMoistureRate()

            local x, y, z = inst.Transform:GetWorldPosition()
            TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z, drink)
        end

        local magic_tending = inst.magic_tending

        inst.components.growable:DoGrowth()
        if inst.grew_into ~= nil then
            inst = inst.grew_into
        end

        if magic_tending and inst.components.farmplanttendable then
            inst.components.farmplanttendable:TendTo()
            inst.magic_tending = true
        end

        if inst.components.pickable == nil then
            inst:AddTag("magicgrowth")
            inst._magicgrowthtask = inst:DoTaskInTime(3 + math.random(), RepeatMagicGrowth)
        else
            inst:RemoveTag("magicgrowth")
            inst.magic_tending = nil
        end

        return true
    end

    inst:RemoveTag("magicgrowth")
    inst.magic_tending = nil
    return false
end

local function call_for_reinforcements(inst, target)
    if target ~= nil and not target:HasTag("plantkin") then
        local x, y, z = inst.Transform:GetWorldPosition()
        local defenders = TheSim:FindEntities(x, y, z, TUNING.FARM_PLANT_DEFENDER_SEARCH_DIST, {"farm_plant_defender"})
        for _, defender in ipairs(defenders) do
            if defender.components.burnable == nil or not defender.components.burnable.burning then
                defender:PushEvent("defend_farm_plant", {source = inst, target = target})
                break
            end
        end
    end
end

local function dig_up(inst, worker)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:DropLoot()
    end

    call_for_reinforcements(inst, worker)

    if inst.components.growable ~= nil then
        local stage_data = inst.components.growable:GetCurrentStageData()
        if stage_data ~= nil and stage_data.dig_fx ~= nil then
            SpawnPrefab(stage_data.dig_fx).Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end

    inst:Remove()
end
local function UpdateGrowing(inst)
    if inst.components.growable ~= nil and (inst.components.burnable == nil or not inst.components.burnable:IsBurning()) and not IsTooDarkToGrow(inst) then
        inst.components.growable:Resume()
    else
        inst.components.growable:Pause()
    end
end

local function onburnt(inst)
    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:DropLoot()
    end

    inst:Remove()
end

local function onignite(inst, source, doer)
    inst.components.farmplantstress:SetStressed("happiness", true, doer or source)

    if inst.components.growable ~= nil then
        UpdateGrowing(inst)
        if inst.components.farmplanttendable ~= nil then
            inst.components.farmplanttendable:SetTendable(inst.components.growable:GetCurrentStageData().tendable)
        end
    end
end

local function onextinguish(inst)
    UpdateGrowing(inst)
end

local function OnIsDark(inst)
    UpdateGrowing(inst)
    if TheWorld.state.isnight then
        if inst.nighttask == nil then
            inst.nighttask = inst:DoPeriodicTask(5, UpdateGrowing, math.random() * 5)
        end
    else
        if inst.nighttask ~= nil then
            inst.nighttask:Cancel()
            inst.nighttask = nil
        end
    end
end

local function OnLootPrefabSpawned(inst, data)
    local loot = data.loot
    if loot then
        loot.from_plant = true
    end
end

local function on_planted(inst, data)
    if data and data.doer and data.doer:HasTag("plantkin") then
        inst.long_life = true
    end
end

local function OnSave(inst, data)
    data.is_oversized = inst.is_oversized
    data.no_oversized = inst.no_oversized
    data.long_life = inst.long_life
    data.scale = inst.scale
    data.identified_plant_type = inst._identified_plant_type

    if inst._magicgrowthtask ~= nil then
        data.magicgrowthtime = GetTaskRemaining(inst._magicgrowthtask)
        data.magic_tending = inst.magic_tending
    end
end

local function OnPreLoad(inst, data)
    if data ~= nil then
        inst.is_oversized = data.is_oversized
        inst.no_oversized = data.no_oversized
        inst.scale = data.scale
        inst.long_life = data.long_life
    end
end

local function OnLoad(inst, data)
    if data then
        if data.magicgrowthtime then
            if inst._magicgrowthtask then
                inst._magicgrowthtask:Cancel()
            end
            inst._magicgrowthtask = inst:DoTaskInTime(data.magicgrowthtime, RepeatMagicGrowth)
            inst.magic_tending = data.magic_tending
            inst:AddTag("magicgrowth")
        end

        if data.identified_plant_type then
            inst._identified_plant_type = data.identified_plant_type
            inst:RemoveTag("israndomseed")
        end
    end
end

local function OnLoadPostPass(inst)
    if inst.components.growable ~= nil then
        inst.components.growable:Pause()
    end
end

local function pickfarmplant()
    if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
        return weighted_random_choice(WEIGHTED_SEED_TABLE)
    else
        local season = TheWorld.state.season

        local weights = {}
        local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD

        for k, v in pairs(PLANT_DEFS) do
            if v.terror_plant then
                weights[k] = v.terror_weight * ((PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[season]) and season_mod or 1)
            end
        end

        return "farm_plant_"..weighted_random_choice(weights)
    end
    --如果没有选择到任何植物，默认返回 weed_forgetmelots
    return "weed_forgetmelots"
end

--这个函数用于将当前实例替换为一个新的植物实例。
local function ReplaceWithPlant(inst)
    if inst == nil then
        return
    end
    local plant_prefab = inst._identified_plant_type or pickfarmplant()
    local plant = SpawnPrefab(plant_prefab)
    local x, y, z = inst.Transform:GetWorldPosition()
    if x and y and z then
        plant.Transform:SetPosition(x, y, z)
    end

    if plant.plant_def ~= nil then
        plant.no_oversized = true
        plant.long_life = inst.long_life
        plant.components.farmsoildrinker:CopyFrom(inst.components.farmsoildrinker)
        plant.components.farmplantstress:CopyFrom(inst.components.farmplantstress)
        plant.components.growable:DoGrowth()
        plant.AnimState:OverrideSymbol("veggie_seed", "farm_soil", "seed")
    end

    inst.grew_into = plant
    inst:Remove()
end

local function randomseed_become_identified(inst, doer)
    inst._identified_plant_type = inst._identified_plant_type or pickfarmplant()

    doer:PushEvent("idplantseed")
    inst:RemoveTag("israndomseed")

    return inst._identified_plant_type
end


local GROWTH_STAGES_RANDOMSEED =
{
    {
        name = "seed",
        time = GetGerminationTime,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, true)
            inst.components.farmplanttendable:SetTendable(stage_data.tendable)
            PlaySowAnim(inst)
        end,
        dig_fx = "dirt_puff",
        inspect_str = "SEED",
        tendable = true,
    },
    {
        name = "sprout",
        time = GetGrowTime,
        fn = function(inst, stage)
            ReplaceWithPlant(inst)
        end,
        dig_fx = "dirt_puff",
        inspect_str = "GROWING",
        tendable = true,
    },
}



local function pickfarmplant2()
    if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
        return weighted_random_choice(WEIGHTED_SEED_TABLE)
    else
        local season = TheWorld.state.season

        local weights = {}
        local season_mod = TUNING.SEED_WEIGHT_SEASON_MOD

        for k, v in pairs(PLANT_DEFS) do
            if v.honor_plant then
                weights[k] = v.honor_weight * ((PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[season]) and season_mod or 1)
            end
        end

        return "farm_plant_"..weighted_random_choice(weights)
    end
    return "weed_forgetmelots"
end

local function ReplaceWithPlant2(inst)
    if inst == nil then
        return
    end
    local plant_prefab = inst._identified_plant_type or pickfarmplant2()
    local plant = SpawnPrefab(plant_prefab)
    local x, y, z = inst.Transform:GetWorldPosition()
    if x and y and z then
        plant.Transform:SetPosition(x, y, z)
    end

    if plant.plant_def ~= nil then
        plant.no_oversized = true
        plant.long_life = inst.long_life
        plant.components.farmsoildrinker:CopyFrom(inst.components.farmsoildrinker)
        plant.components.farmplantstress:CopyFrom(inst.components.farmplantstress)
        plant.components.growable:DoGrowth()
        plant.AnimState:OverrideSymbol("veggie_seed", "farm_soil", "seed")
    end

    inst.grew_into = plant
    inst:Remove()
end

local function randomseed_become_identified2(inst, doer)
    inst._identified_plant_type = inst._identified_plant_type or pickfarmplant2()

    doer:PushEvent("idplantseed")
    inst:RemoveTag("israndomseed")

    return inst._identified_plant_type
end


local GROWTH_STAGES_RANDOMSEED2 =
{
    {
        name = "seed",
        time = GetGerminationTime,
        fn = function(inst, stage, stage_data)
            MakePlantedSeed(inst, true)
            inst.components.farmplanttendable:SetTendable(stage_data.tendable)
            PlaySowAnim(inst)
        end,
        dig_fx = "dirt_puff",
        inspect_str = "SEED",
        tendable = true,
    },
    {
        name = "sprout",
        time = GetGrowTime,
        fn = function(inst, stage)
            ReplaceWithPlant2(inst)
        end,
        dig_fx = "dirt_puff",
        inspect_str = "GROWING",
        tendable = true,
    },
}


local assets =
{
    Asset("ANIM", "anim/farm_soil.zip"),
    Asset("ANIM", "anim/farm_plant_terror_seed.zip"),
    Asset("SCRIPT", "scripts/prefabs/farm_plant_defs.lua"),
    Asset("SCRIPT", "scripts/prefabs/weed_defs.lua"),
}

local prefabs ={
    "spoiled_food",
    "farm_plant_happy",
    "farm_plant_unhappy",
}

if terror_def.product ~= nil then			table.insert(prefabs, terror_def.product) end
if terror_def.product_oversized ~= nil then	table.insert(prefabs, terror_def.product_oversized) end
if terror_def.seed ~= nil then				table.insert(prefabs, terror_def.seed) end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("farm_plant_terror_seed")
    inst.AnimState:SetBuild("farm_plant_terror_seed")
    inst.AnimState:OverrideSymbol("soil01", "farm_soil", "soil01")

    inst:SetDeploySmartRadius(0.5) --match visuals, seeds use CUSTOM spacing

    inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)

    inst:AddTag("plantedsoil")
    inst:AddTag("farm_plant")
    inst:AddTag("lunarplant_target")
    inst:AddTag("plant")
    if terror_def.plant_type_tag then
        inst:AddTag(terror_def.plant_type_tag)
    end
    if terror_def.is_randomseed then
        inst:AddTag("israndomseed")
    end
    inst:AddTag("plantresearchable")
    inst:AddTag("farmplantstress") --for plantresearchable component.
    inst:AddTag("tendable_farmplant") -- for farmplanttendable component

    inst._research_stage = (terror_def.stage_netvar or net_tinybyte)(inst.GUID, "farm_plant.research_stage") -- use inst:GetResearchStage() to access this value
    inst.plantregistrykey = terror_def.product
    inst.GetPlantRegistryKey = GetPlantRegistryKey
    inst.GetResearchStage = GetResearchStage

    inst.displaynamefn = GetDisplayName

    inst.plant_def = terror_def

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_overridedata= {"soil01", "farm_soil", "soil01"}
    inst.scrapbook_anim = terror_def.is_randomseed and "sow_idle" or "crop_full"

    inst._activatefn = PushFruitFlySpawnerEvent

    inst.UpdateResearchStage = UpdateResearchStage

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable.nameoverride = "FARM_PLANT"

    if terror_def.is_randomseed then
        -- A plant identifier can tell which seed this is.
        inst.components.inspectable.descriptionfn = RandomSeedDescriptionFn
    end

    inst:AddComponent("plantresearchable")

    inst.components.plantresearchable:SetResearchFn(plantresearchfn)

    inst:AddComponent("farmplantstress") -- 添加农作物压力组件
    inst.components.farmplantstress:AddStressCategory("nutrients", NutrientsStressTest) -- 添加营养压力测试
    inst.components.farmplantstress:AddStressCategory("moisture", MoistureStressTest) -- 添加湿度压力测试
    inst.components.farmplantstress:AddStressCategory("killjoys", KillJoyStressTest) -- 添加不良环境压力测试
    inst.components.farmplantstress:AddStressCategory("family", FamilyStressTest) -- 添加家庭压力测试
    inst.components.farmplantstress:AddStressCategory("overcrowding", OvercrowdingStressTest) -- 添加过度拥挤压力测试
    inst.components.farmplantstress:AddStressCategory("season", SeasonStressTest) -- 添加季节压力测试
    inst.components.farmplantstress:AddStressCategory("happiness", HappinessStressTest, on_happiness_changed) -- 添加幸福度压力测试，并在幸福度变化时调用 on_happiness_changed 函数

    inst:AddComponent("farmsoildrinker")
    inst.components.farmsoildrinker.getdrinkratefn = GetDrinkRate
    inst.components.farmsoildrinker.onsoilmoisturestatechangefn = OnSoilMoistureStateChange

    inst:AddComponent("farmplanttendable")
    inst.components.farmplanttendable.ontendtofn = ontendto

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.lootsetupfn = SetupLoot

    inst:AddComponent("growable")
    inst.components.growable.growoffscreen = true
    inst.components.growable.stages = terror_def.is_randomseed and GROWTH_STAGES_RANDOMSEED
    inst.components.growable:SetStage(1)
    inst.components.growable.loopstages = true
    inst.components.growable.loopstages_start = 2
    inst.components.growable.domagicgrowthfn = domagicgrowthfn
    inst.components.growable.magicgrowable = true
    inst.components.growable:StartGrowing()
    inst.components.growable:Pause()

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(dig_up)

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("domesticplantherd")

    if not terror_def.fireproof then
        MakeSmallBurnable(inst)--使植物可燃烧
        MakeSmallPropagator(inst)-- 使植物可传播火焰
        inst.components.burnable:SetOnBurntFn(onburnt)
        inst.components.burnable:SetOnIgniteFn(onignite)
        inst.components.burnable:SetOnExtinguishFn(onextinguish)
    end

    --inst.no_oversized = false

    if terror_def.is_randomseed then
        inst.BeIdentified = randomseed_become_identified
    end

    MakeWaxablePlant(inst)

    inst:WatchWorldState("isnight", OnIsDark)
    inst:DoTaskInTime(0, OnIsDark)

    inst:ListenForEvent("loot_prefab_spawned", OnLootPrefabSpawned)
    inst:ListenForEvent("on_planted", on_planted)

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end
------------------------------------------------------------凶险种子作物----------------------------------------------------------


--------------------------------------------------------辉煌种子作物----------------------------------------------
local assets2 =
{
    Asset("ANIM", "anim/farm_plant_honor_seed.zip"),
    Asset("ANIM", "anim/farm_soil.zip"),
    Asset("SCRIPT", "scripts/prefabs/farm_plant_defs.lua"),
    Asset("SCRIPT", "scripts/prefabs/weed_defs.lua"),
}

local prefabs2 ={
    "spoiled_food",
    "farm_plant_happy",
    "farm_plant_unhappy",
}

if honor_def.product ~= nil then			table.insert(prefabs, honor_def.product) end
if honor_def.product_oversized ~= nil then	table.insert(prefabs, honor_def.product_oversized) end
if honor_def.seed ~= nil then				table.insert(prefabs, honor_def.seed) end


local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("farm_plant_honor_seed")
    inst.AnimState:SetBuild("farm_plant_honor_seed")
    inst.AnimState:OverrideSymbol("soil01", "farm_soil", "soil01")

    inst:SetDeploySmartRadius(0.5) --match visuals, seeds use CUSTOM spacing

    inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)

    inst:AddTag("plantedsoil")
    inst:AddTag("farm_plant")
    inst:AddTag("lunarplant_target")
    inst:AddTag("plant")
    if honor_def.plant_type_tag then
        inst:AddTag(terror_def.plant_type_tag)
    end
    if honor_def.is_randomseed then
        inst:AddTag("israndomseed")
    end
    inst:AddTag("plantresearchable")
    inst:AddTag("farmplantstress") --for plantresearchable component.
    inst:AddTag("tendable_farmplant") -- for farmplanttendable component

    inst._research_stage = (honor_def.stage_netvar or net_tinybyte)(inst.GUID, "farm_plant.research_stage") -- use inst:GetResearchStage() to access this value
    inst.plantregistrykey = honor_def.product
    inst.GetPlantRegistryKey = GetPlantRegistryKey
    inst.GetResearchStage = GetResearchStage

    inst.displaynamefn = GetDisplayName

    inst.plant_def = honor_def

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_overridedata= {"soil01", "farm_soil", "soil01"}
    inst.scrapbook_anim = honor_def.is_randomseed and "sow_idle" or "crop_full"

    inst._activatefn = PushFruitFlySpawnerEvent

    inst.UpdateResearchStage = UpdateResearchStage

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable.nameoverride = "FARM_PLANT"

    if honor_def.is_randomseed then
        -- A plant identifier can tell which seed this is.
        inst.components.inspectable.descriptionfn = RandomSeedDescriptionFn
    end

    inst:AddComponent("plantresearchable")
    inst.components.plantresearchable:SetResearchFn(plantresearchfn)

    inst:AddComponent("farmplantstress")
    inst.components.farmplantstress:AddStressCategory("nutrients", NutrientsStressTest) -- 添加营养压力测试
    inst.components.farmplantstress:AddStressCategory("moisture", MoistureStressTest) -- 添加湿度压力测试
    inst.components.farmplantstress:AddStressCategory("killjoys", KillJoyStressTest) -- 添加不良环境压力测试
    inst.components.farmplantstress:AddStressCategory("family", FamilyStressTest) -- 添加家庭压力测试
    inst.components.farmplantstress:AddStressCategory("overcrowding", OvercrowdingStressTest) -- 添加过度拥挤压力测试
    inst.components.farmplantstress:AddStressCategory("season", SeasonStressTest) -- 添加季节压力测试
    inst.components.farmplantstress:AddStressCategory("happiness", HappinessStressTest, on_happiness_changed) -- 添加幸福度压力测试，并在幸福度变化时调用 on_happiness_changed 函数

    inst:AddComponent("farmsoildrinker")
    inst.components.farmsoildrinker.getdrinkratefn = GetDrinkRate
    inst.components.farmsoildrinker.onsoilmoisturestatechangefn = OnSoilMoistureStateChange

    inst:AddComponent("farmplanttendable")
    inst.components.farmplanttendable.ontendtofn = ontendto

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.lootsetupfn = SetupLoot

    inst:AddComponent("growable")
    inst.components.growable.growoffscreen = true
    inst.components.growable.stages = honor_def.is_randomseed and GROWTH_STAGES_RANDOMSEED2
    inst.components.growable:SetStage(1)
    inst.components.growable.loopstages = true
    inst.components.growable.loopstages_start = 2
    inst.components.growable.domagicgrowthfn = domagicgrowthfn
    inst.components.growable.magicgrowable = true
    inst.components.growable:StartGrowing()
    inst.components.growable:Pause()

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(dig_up)

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("domesticplantherd")

    if not honor_def.fireproof then
        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnBurntFn(onburnt)
        inst.components.burnable:SetOnIgniteFn(onignite)
        inst.components.burnable:SetOnExtinguishFn(onextinguish)
    end

    --inst.no_oversized = false

    if honor_def.is_randomseed then
        inst.BeIdentified = randomseed_become_identified2
    end

    MakeWaxablePlant(inst)

    inst:WatchWorldState("isnight", OnIsDark)
    inst:DoTaskInTime(0, OnIsDark)

    inst:ListenForEvent("loot_prefab_spawned", OnLootPrefabSpawned)
    inst:ListenForEvent("on_planted", on_planted)

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab(terror_def.prefab, fn, assets, prefabs),
       Prefab(honor_def.prefab, fn2, assets2, prefabs2)

