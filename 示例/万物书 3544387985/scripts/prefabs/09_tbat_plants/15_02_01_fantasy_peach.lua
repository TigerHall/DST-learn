--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    农作物 ：
        【物品】农作物种子
        【物品】农作物巨大物
        【物品】农作物巨大物（打蜡）
        【物品】农作物巨大物（枯萎）

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 最终打包
    local ret_prefabs = {}
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_fantasy_peach_seed.zip"),
        Asset("ANIM", "anim/tbat_farm_plant_fantasy_peach.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local this_plant_name = "tbat_farm_plant_fantasy_peach"             --- 农作物名字（prefab)
    local oversized_item_prefab = "tbat_eq_fantasy_peach_oversized"     --- 采集后的巨大作物prefab
    local this_plant_def = PLANT_DEFS[this_plant_name]

    local oversized_perishtime = TUNING.PERISH_MED
    local OVERSIZED_PHYSICS_RADIUS = 0.1
    local OVERSIZED_MAXWORK = 1
    local OVERSIZED_PERISHTIME_MULT = 4
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 种子物品
    local function can_plant_seed(inst, pt, mouseover, deployer)
        local x, z = pt.x, pt.z
        return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
    end
    local function OnDeploy(inst, pt, deployer)
        local plant = SpawnPrefab(inst.components.farmplantable.plant)
        plant.Transform:SetPosition(pt.x, 0, pt.z)
        plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
        TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
        --plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
        inst:Remove()
    end
    local function seed_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("idle_water")
        else
            inst.AnimState:PlayAnimation("idle")
        end
    end
    local function Seed_GetDisplayName(inst)
        local registry_key = inst.plant_def.product
        local plantregistryinfo = inst.plant_def.plantregistryinfo
        return (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) and STRINGS.NAMES["KNOWN_"..string.upper(inst.prefab)] 
                or nil
    end
    local function seed_OnSave(inst, data)
        data.from_plant = inst.from_plant
    end
    local function seed_OnPreLoad(inst, data)
        if data ~= nil then
            inst.from_plant = data.from_plant
        end
    end
    local function fn_seeds()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_food_fantasy_peach_seed")
        inst.AnimState:SetBuild("tbat_food_fantasy_peach_seed")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetRayTestOnBB(true)
        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
        inst:AddTag("deployedplant")
        inst:AddTag("deployedfarmplant")
		inst:AddTag("oceanfishing_lure")
        inst.overridedeployplacername = "seeds_placer"
		inst.plant_def = PLANT_DEFS["tbat_farm_plant_fantasy_peach"]
		inst.displaynamefn = Seed_GetDisplayName
		inst._custom_candeploy_fn = can_plant_seed -- for DEPLOYMODE.CUSTOM
        MakeInventoryFloatable(inst)
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.SEEDS
            inst.components.edible.healthvalue = 0
            inst.components.edible.hungervalue = 1
            inst.components.edible.sanityvalue = 1
        -----------------------------------------------------------
        --- 落水
            inst:ListenForEvent("on_landed",seed_onland_event)
        -----------------------------------------------------------
        --- 堆叠
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -----------------------------------------------------------
        --- 交易、检查
            inst:AddComponent("tradable")
            inst:AddComponent("inspectable")
        -----------------------------------------------------------
        --- 物品
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_food_fantasy_peach_seeds","images/inventoryimages/tbat_food_fantasy_peach_seeds.xml")
        -----------------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
        -----------------------------------------------------------
        --- 直接烤
            inst:AddComponent("cookable")
            -- inst.components.cookable.product = "seeds_cooked"
            inst.components.cookable.product = "tbat_food_fantasy_peach_seeds_cooked"
        -----------------------------------------------------------
        --- 诱饵
            inst:AddComponent("bait")
        -----------------------------------------------------------
        --- 农作物
            inst:AddComponent("farmplantable")
            inst.components.farmplantable.plant = this_plant_name
        -----------------------------------------------------------
        -- 旧版农作物建筑 deprecated (used for crafted farm structures)
            -- inst:AddComponent("plantable")
            -- inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
            -- inst.components.plantable.product = name
        -----------------------------------------------------------
        -- 植物人种植 deprecated (used for wormwood)
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
            inst.components.deployable.restrictedtag = "plantkin"
            inst.components.deployable.ondeploy = OnDeploy
        -----------------------------------------------------------
        --- 鱼饵
            inst:AddComponent("oceanfishingtackle")
            inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})
        -----------------------------------------------------------
        -- 可燃，可作祟
            MakeSmallBurnable(inst)
            MakeSmallPropagator(inst)
            MakeHauntableLaunchAndPerish(inst)
        -----------------------------------------------------------
        -- 保存、读取
            inst.OnSave = seed_OnSave
            inst.OnPreLoad = seed_OnPreLoad
        -----------------------------------------------------------
        return inst
    end
    AddIngredientValues({"tbat_food_fantasy_peach_seeds"}, {seed=1})  --- 种子进入烹饪锅
    table.insert(ret_prefabs,Prefab("tbat_food_fantasy_peach_seeds", fn_seeds, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 巨型采摘后的作物
    local function oversized_calcweightcoefficient(name)
        if PLANT_DEFS[name].weight_data[3] ~= nil and math.random() < PLANT_DEFS[name].weight_data[3] then
            return (math.random() + math.random()) / 2
        else
            return math.random()
        end
    end
    local function oversized_onequip(inst, owner)  -- 玩家搬动巨大作物物品
        owner.AnimState:OverrideSymbol("swap_body", "tbat_farm_plant_fantasy_peach", "swap_body")
    end
    local function oversized_onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_body")
    end
    local function oversized_onfinishwork(inst, chopper)
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    end
    local function oversized_onburnt(inst)  --- 燃烧完成后
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    end
    local oversized_loots = {
        "smallmeat","smallmeat",
        "tbat_food_fantasy_peach_seeds","tbat_food_fantasy_peach_seeds",
        "tbat_food_fantasy_peach","tbat_food_fantasy_peach","tbat_food_fantasy_peach","tbat_food_fantasy_peach",
    }
    local function oversized_makeloots(inst)  --- 掉落物生成
        return oversized_loots
    end
    local function oversized_onperish(inst) --- 绝大作物物品-保鲜结束
        if inst.components.inventoryitem:GetGrandOwner() ~= nil then
            --- 在玩家身上，直接爆掉
            local loots = {}
            for i=1, #inst.components.lootdropper.loot do
                table.insert(loots, "spoiled_food")
            end
            inst.components.lootdropper:SetLoot(loots)
            inst.components.lootdropper:DropLoot()
        else
            --- 不在玩家身上，直接替换
            SpawnPrefab(inst.prefab.."_rotten").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        inst:Remove()
    end
    local function Oversized_OnSave(inst, data)
        data.from_plant = inst.from_plant
        data.harvested_on_day = inst.harvested_on_day
    end
    local function Oversized_OnPreLoad(inst, data)
        if data ~= nil then
            inst.from_plant = data.from_plant
            inst.harvested_on_day = data.harvested_on_day
        end
    end
    local function dowaxfn(inst, doer, waxitem) --- 喷腊
        local waxedveggie = SpawnPrefab(inst.prefab.."_waxed")
        if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == inst then
            doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
            doer.components.inventory:Equip(waxedveggie)
        else       
            waxedveggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        inst:Remove()
        return true
    end
    local function fn_oversized()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank(this_plant_def.bank)
        inst.AnimState:SetBuild(this_plant_def.build)
        inst.AnimState:PlayAnimation("idle_oversized",true)
        inst:AddTag("heavy")
        inst:AddTag("waxable")
	    inst:AddTag("show_spoilage")
        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)
        inst._base_name = this_plant_name
        inst.plant_def = this_plant_def
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
        --- 采摘日期记录
            inst.harvested_on_day = inst.harvested_on_day or (TheWorld.state.cycles + 1)
        -----------------------------------------------------------
        --- 重量组件物理引擎配置
            inst:AddComponent("heavyobstaclephysics")
            inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
            inst.components.heavyobstaclephysics:MakeSmallObstacle()
        -----------------------------------------------------------
        --- 腐烂速度
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(oversized_perishtime * OVERSIZED_PERISHTIME_MULT)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = nil
            inst.components.perishable:SetOnPerishFn(oversized_onperish)
        -----------------------------------------------------------
        --- 检查和物品
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem:SetSinks(true)
            inst.components.inventoryitem:TBATInit("tbat_eq_fantasy_peach_oversized","images/inventoryimages/tbat_eq_fantasy_peach_oversized.xml")
        -----------------------------------------------------------
        --- 穿戴（背负）
            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(oversized_onequip)
            inst.components.equippable:SetOnUnequip(oversized_onunequip)
            inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT
        -----------------------------------------------------------
        --- 敲开
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)
        -----------------------------------------------------------
        --- 喷腊
            inst:AddComponent("waxable")
            inst.components.waxable:SetWaxfn(dowaxfn)
        -----------------------------------------------------------
        --- 潜水
            inst:AddComponent("submersible")
            inst:AddComponent("symbolswapdata")
            inst.components.symbolswapdata:SetData(this_plant_def.build, "swap_body")
        -----------------------------------------------------------
        --- 重量
            local weight_data = this_plant_def.weight_data
            inst:AddComponent("weighable")
            inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDVEGGIES
            inst.components.weighable:Initialize(weight_data.min, weight_data.max)
            local coefficient = oversized_calcweightcoefficient(this_plant_name)
            inst.components.weighable:SetWeight(Lerp(weight_data[1], weight_data[2], coefficient))
        -----------------------------------------------------------
        --- 掉落物
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(oversized_makeloots(inst))
        -----------------------------------------------------------
        --- 可燃、可作祟
            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)
            MakeHauntableWork(inst)
        -----------------------------------------------------------
        --- 储存、读取
            inst.OnSave = Oversized_OnSave
            inst.OnPreLoad = Oversized_OnPreLoad
        -----------------------------------------------------------
        return inst
    end
    table.insert(ret_prefabs,Prefab(oversized_item_prefab, fn_oversized, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 打蜡后的物品
    local function displayadjectivefn(inst)
        return STRINGS.UI.HUD.WAXED
    end
    local function waxed_init(inst)
        inst.AnimState:PlayAnimation("idle_oversized", false)
        inst.AnimState:PushAnimation("wax_oversized",true)
        inst.AnimState:SetTime(3*math.random())
    end
    local function fn_oversized_waxed()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank(this_plant_def.bank)
        inst.AnimState:SetBuild(this_plant_def.build)
        -- inst.AnimState:PlayAnimation("wax_oversized",true)
        -- inst.AnimState:PlayAnimation(3*math.random())
        inst:AddTag("heavy")
        -- inst:AddTag("tbat_eq_fantasy_peach_oversized_waxed")
        inst.displayadjectivefn = displayadjectivefn
        inst:SetPrefabNameOverride(oversized_item_prefab)
        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)
        inst.plant_def = this_plant_def
        inst._base_name = this_plant_name
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
        --- 碰撞物理引擎
            inst:AddComponent("heavyobstaclephysics")
            inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
            inst.components.heavyobstaclephysics:MakeSmallObstacle()
        -----------------------------------------------------------
        --- 物品检查
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem:SetSinks(true)
            inst.components.inventoryitem:TBATInit("tbat_eq_fantasy_peach_oversized","images/inventoryimages/tbat_eq_fantasy_peach_oversized.xml")
        -----------------------------------------------------------
        --- 装备
            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(oversized_onequip)
            inst.components.equippable:SetOnUnequip(oversized_onunequip)
            inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT
        -----------------------------------------------------------
        --- 拆开
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)
        -----------------------------------------------------------
        --- 潜水
            inst:AddComponent("submersible")
            inst:AddComponent("symbolswapdata")
            inst.components.symbolswapdata:SetData(this_plant_def.build, "swap_body")
        -----------------------------------------------------------
        --- 掉落物
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(oversized_makeloots(inst))
        -----------------------------------------------------------
            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)
            MakeHauntableWork(inst)
        -----------------------------------------------------------
        --- 事件
            -- inst:ListenForEvent("onputininventory", CancelWaxTask)
            -- inst:ListenForEvent("ondropped", StartWaxTask)    
            -- inst.OnEntitySleep = CancelWaxTask
            -- inst.OnEntityWake = StartWaxTask
            -- StartWaxTask(inst)
            inst:DoTaskInTime(0,waxed_init)
        -----------------------------------------------------------
        return inst
    end
    table.insert(ret_prefabs,Prefab(oversized_item_prefab.."_waxed", fn_oversized_waxed, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 腐烂的巨大作物（物品）
    local function fn_oversized_rotten()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        local plant_def = PLANT_DEFS[this_plant_name]
        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_rot_oversized")
        inst:AddTag("farm_plant_killjoy")
        inst:AddTag("pickable_harvest_str")
		inst:AddTag("pickable")
		inst._base_name = this_plant_name
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
        --- 物品检查
            inst:AddComponent("inspectable")
            inst.components.inspectable.nameoverride = "VEGGIE_OVERSIZED_ROTTEN"
        -----------------------------------------------------------
        --- 拆开
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
            inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)
        -----------------------------------------------------------
        --- 采集
            inst:AddComponent("pickable")
            inst.components.pickable.onpickedfn = inst.Remove        
            inst.components.pickable:SetUp(nil)
            inst.components.pickable.use_lootdropper_for_product = true
            inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
        -----------------------------------------------------------
        --- 物品
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem.canbepickedup = false
            inst.components.inventoryitem:SetSinks(true)
        -----------------------------------------------------------
        --- 掉落物
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(plant_def.loot_oversized_rot)
        -----------------------------------------------------------
        --- 燃烧、作祟
            MakeMediumBurnable(inst)
            inst.components.burnable:SetOnBurntFn(oversized_onburnt)
            MakeMediumPropagator(inst)
            MakeHauntableWork(inst)
        -----------------------------------------------------------
        return inst
    end
    table.insert(ret_prefabs,Prefab(oversized_item_prefab.."_rotten", fn_oversized_rotten, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret_prefabs)