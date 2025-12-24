local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local TOOLS_L = require("tools_legion")
local prefs = {}
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --专门放各个prefab独特的变量

fns.bfts = {
    m3 = TUNING.SEG_TIME*6,
    m6 = TUNING.SEG_TIME*12,
    m8 = TUNING.SEG_TIME*16,
    m12 = TUNING.SEG_TIME*24,
    m15 = TUNING.SEG_TIME*30 --一般buff最多只有15分钟
}

fns.GetAssets = function(name, other)
    local sets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
fns.GetAssets2 = function(name, build, other)
    local sets = {
        Asset("ANIM", "anim/"..build..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
fns.GetAssets_inv = function(name, other)
    local sets = {
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
fns.GetPrefabs_crop = function(name, other)
    local sets = {
        name.."_seeds", "splash_green",
        name.."_oversized", name.."_oversized_waxed", name.."_oversized_rotten"
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end

fns.CommonFn = function(inst, bank, build, anim, isloop)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle", isloop)
end
fns.ServerFn = function(inst, img)
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"
end
fns.ServerFn_veggie = function(inst)
    inst:AddComponent("bait")
    inst:AddComponent("tradable")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)
end
fns.ServerFn_burn = function(inst, burntime)
    MakeSmallBurnable(inst, burntime)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)
end

fns.SetStackable = function(inst, maxsize) --叠加组件
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = maxsize or TUNING.STACK_SIZE_SMALLITEM
end
fns.SetPerishable = function(inst, time, replacement, onperish) --新鲜度组件
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(time)
    if replacement ~= nil then
        inst.components.perishable.onperishreplacement = replacement
    end
    if onperish ~= nil then
        inst.components.perishable:SetOnPerishFn(onperish)
    end
    inst.components.perishable:StartPerishing()
end
fns.SetFuel = function(inst, value, fueltype) --燃料组件
    inst:AddComponent("fuel")
    if fueltype ~= nil then
        inst.components.fuel.fueltype = fueltype
    end
    inst.components.fuel.fuelvalue = value or TUNING.TINY_FUEL
end
fns.SetEdible = function(inst, dd) --食物组件
    inst:AddComponent("edible")
    inst.components.edible.foodtype = dd.foodtype or FOODTYPE.VEGGIE
    inst.components.edible.secondaryfoodtype = dd.foodtype2
    inst.components.edible.healthvalue = dd.health or 0
    inst.components.edible.hungervalue = dd.hunger or 0
    inst.components.edible.sanityvalue = dd.sanity or 0
    if dd.fn_eat ~= nil then
        inst.components.edible:SetOnEatenFn(dd.fn_eat)
    end
end
fns.SetCookable = function(inst, product) --烤制组件
    inst:AddComponent("cookable")
    inst.components.cookable.product = product
end
fns.SetLure = function(inst, dd) --海钓饵组件
    inst:AddComponent("oceanfishingtackle")
    inst.components.oceanfishingtackle:SetupLure(dd)
end
fns.SetWeighable = function(inst, kind) --称重组件
    --Tip: 非巨型的普通果实要想能在作物秤上显示，需要自己的build里有个 果实build名..01 的通道
    inst:AddComponent("weighable")
    inst.components.weighable.type = kind or TROPHYSCALE_TYPES.OVERSIZEDVEGGIES
end
fns.SetWaxable = function(inst, onwaxed) --打蜡组件
    inst:AddComponent("waxable")
    inst.components.waxable:SetWaxfn(onwaxed)
end
fns.SetDeployable = function(inst, ondeploy, mode, spacing) --摆放组件
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    if mode ~= nil then
        inst.components.deployable:SetDeployMode(mode)
    end
    inst.components.deployable:SetDeploySpacing(spacing or DEPLOYSPACING.LESS)
end
fns.SetOintmentLegion = function(inst, fn_check, fn_smear) --涂抹组件
    inst:AddComponent("ointmentlegion")
    inst.components.ointmentlegion.fn_check = fn_check
    inst.components.ointmentlegion.fn_smear = fn_smear
end
fns.SetTradable = function(inst, goldvalue, rocktribute) --交易组件
    inst:AddComponent("tradable")
    if goldvalue ~= nil then --大于0就能和猪王换等量金块，或者和蚁狮换1沙之石
        inst.components.tradable.goldvalue = goldvalue
    end
    if rocktribute ~= nil then --大于0就能给蚁狮，让蚁狮暂缓地震。延缓 0.33 x rocktribute 天地震
        inst.components.tradable.rocktribute = rocktribute
    end
end

fns.OnLandedClient_new = function(self, ...)
    if self.OnLandedClient_legion ~= nil then
        self.OnLandedClient_legion(self, ...)
    end
    if self.floatparam_l ~= nil then --即使不设置这个，官方也会有默认数值 -0.05
        self.inst.AnimState:SetFloatParams(self.floatparam_l, 1, self.bob_percent)
    end
end
fns.SetFloatable = function(inst, float) --漂浮组件
    MakeInventoryFloatable(inst, float[2], float[3], float[4])
    if float[1] ~= nil then
        local floater = inst.components.floater
        if floater.OnLandedClient_legion == nil then
            floater.OnLandedClient_legion = floater.OnLandedClient
            floater.OnLandedClient = fns.OnLandedClient_new
        end
        floater.floatparam_l = float[1]
    end
end

fns.Decor_owner = function(inst, furniture) --官方的代码很有兼容性，不用担心特效位置不对
    if inst._onownerchange ~= nil then
        inst._onownerchange(inst)
    end
end
fns.Decor_stackfix = function(inst, furniture) --官方代码不完善：叠加物且叠加数量大于1时，摆上桌子会不显示实体。得手动修修
    if inst:IsInLimbo() and furniture and inst.components.inventoryitem then
        local cpt = furniture.components.furnituredecortaker
        local giver = inst.components.inventoryitem.owner
        inst.components.inventoryitem:OnRemoved() --先得解除隐藏状态，FollowSymbol()得先不隐藏才能成功
        if cpt and cpt.ondecorgiven ~= nil then --然后重新执行一遍装饰逻辑
            cpt.ondecorgiven(furniture, inst, giver)
        end
    end
end
fns.SetFurnitureDecor_comm = function(inst) --装饰组件前置
    inst.entity:AddFollower() --能当装饰品需要这个
    inst:AddTag("furnituredecor") --能当装饰品
end
fns.SetFurnitureDecor_serv = function(inst, ondecor) --装饰组件
    inst:AddComponent("furnituredecor")
    if ondecor ~= nil then
        inst.components.furnituredecor.onputonfurniture = ondecor
    end
end

--------------------------------------------------------------------------
--[[ 料理相关 ]]
--------------------------------------------------------------------------

------通用料理

pas.prefabs_dish = { "spoiled_food" }
pas.MakeDish = function(dd)
    local realname = dd.basename or dd.name --当有调料时，basename 才是这个料理最初的代码名
    local food_symbol_build = dd.overridebuild or realname
    local foodassets = {
        Asset("ANIM", "anim/"..food_symbol_build..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..realname..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..realname..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..realname..".xml", 256)
    }
    local spicename = dd.spice ~= nil and string.lower(dd.spice) or nil
    if spicename ~= nil then
        table.insert(foodassets, Asset("ANIM", "anim/spices.zip"))
        table.insert(foodassets, Asset("ANIM", "anim/plate_food.zip"))
        table.insert(foodassets, Asset("INV_IMAGE", spicename.."_over"))
    end

    local foodprefabs = pas.prefabs_dish
    if dd.prefabs ~= nil then
        foodprefabs = shallowcopy(pas.prefabs_dish)
        for _, v in ipairs(dd.prefabs) do
            if not table.contains(foodprefabs, v) then
                table.insert(foodprefabs, v)
            end
        end
    end

    local function DisplayName_dish(inst)
        return subfmt(STRINGS.NAMES[dd.spice.."_FOOD"], { food = STRINGS.NAMES[string.upper(dd.basename)] })
    end

    table.insert(prefs, Prefab(dd.name, function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if spicename ~= nil then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
            inst.AnimState:OverrideSymbol("swap_garnish", "spices", spicename)

            inst:AddTag("spicedfood")

            --有调料时，调料本身的贴图是inventoryitem所对应的，料理本身的贴图反而成了背景
            inst.inv_image_bg = { atlas = "images/inventoryimages/"..realname..".xml", image = realname..".tex" }
        else
            inst.AnimState:SetBuild(food_symbol_build)
            inst.AnimState:SetBank(food_symbol_build)
        end
        --Tip: 动画文件里的默认动画，比如idle，所用到的第一张图最好不要太小，比如1x1，以及中心点设置也不要为0.0
        --否则，会导致打包后，游戏鼠标移到对应动画贴图上去时，没有正常的鼠标反应；或者只有部分贴图区域能出现鼠标反应
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:OverrideSymbol("swap_food", food_symbol_build, realname)

        inst:AddTag("preparedfood")
        if dd.tags ~= nil then
            for _, v in ipairs(dd.tags) do
                inst:AddTag(v)
            end
        end
        if dd.basename ~= nil then
            inst:SetPrefabNameOverride(dd.basename)
            if dd.spice ~= nil then
                inst.displaynamefn = DisplayName_dish
            end
        end
        if dd.float ~= nil then
            fns.SetFloatable(inst, dd.float)
        end
        if dd.fn_common ~= nil then
            dd.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.food_symbol_build = food_symbol_build
        inst.food_basename = dd.basename

        inst:AddComponent("edible")
        inst.components.edible.foodtype = dd.foodtype or FOODTYPE.GENERIC
        inst.components.edible.secondaryfoodtype = dd.secondaryfoodtype or nil
        inst.components.edible.hungervalue = dd.hunger or 0
        inst.components.edible.sanityvalue = dd.sanity or 0
        inst.components.edible.healthvalue = dd.health or 0
        inst.components.edible.temperaturedelta = dd.temperature or 0
        inst.components.edible.temperatureduration = dd.temperatureduration or 0
        inst.components.edible.nochill = dd.nochill or nil
        inst.components.edible.spice = dd.spice
        inst.components.edible:SetOnEatenFn(dd.oneatenfn)

        inst:AddComponent("inspectable")
        inst.wet_prefix = dd.wet_prefix --潮湿前缀

        inst:AddComponent("inventoryitem")
        -- if dd.OnPutInInventory then
		-- 	inst:ListenForEvent("onputininventory", dd.OnPutInInventory)
		-- end
        inst.components.inventoryitem.imagename = realname
        if spicename ~= nil then --带调料的料理
            inst.components.inventoryitem:ChangeImageName(spicename.."_over")
        elseif dd.basename ~= nil then --特殊情况
            inst.components.inventoryitem:ChangeImageName(dd.basename)
        else --普通料理
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..realname..".xml"
        end
        if dd.float == nil then
            inst.components.inventoryitem:SetSinks(true)
        end

        inst:AddComponent("bait")
        inst:AddComponent("tradable")

        fns.SetStackable(inst, nil)
        if dd.perishtime ~= nil and dd.perishtime > 0 then
            fns.SetPerishable(inst, dd.perishtime, "spoiled_food", nil)
		end
        if not dd.fireproof then
            MakeSmallBurnable(inst)
            MakeSmallPropagator(inst)
        end
        MakeHauntableLaunch(inst)

        if dd.fn_server ~= nil then
            dd.fn_server(inst)
        end

        return inst
    end, foodassets, foodprefabs))
end

for k, v in pairs(require("preparedfoods_legion")) do
    pas.MakeDish(v)
end
for k, v in pairs(require("preparedfoods_legion_spiced")) do
    if not v.notinitprefab then --部分调料后料理不用通用机制
        pas.MakeDish(v)
    end
end

--------------------------------------------------------------------------
--[[ 各种食物 ]]
--------------------------------------------------------------------------

table.insert(prefs, Prefab("petals_rose", function() ------蔷薇花瓣
    local inst = CreateEntity()
    fns.CommonFn(inst, "petals_rose", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.08, 0.95 })

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "petals_rose")
    fns.SetEdible(inst, { hunger = 9.375, sanity = 1, health = 8 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("petals_rose"), nil))

table.insert(prefs, Prefab("petals_lily", function() ------蹄莲花瓣
    local inst = CreateEntity()
    fns.CommonFn(inst, "petals_lily", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.08, 0.95 })

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "petals_lily")
    fns.SetEdible(inst, { hunger = 9.375, sanity = 10, health = -3 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("petals_lily"), nil))

table.insert(prefs, Prefab("petals_orchid", function() ------兰草花瓣
    local inst = CreateEntity()
    fns.CommonFn(inst, "petals_orchid", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.08, 0.95 })

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "petals_orchid")
    fns.SetEdible(inst, { hunger = 12.5, sanity = 5, health = 0 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("petals_orchid"), nil))

pas.OnEat_nightrose = function(inst, eater)
    --倪克斯、暗影势力的生物、当前不会被影怪主动攻击的玩家
    if eater:HasAnyTag("genesis_nyx", "shadow_aligned", "shadowdominance") then
        if eater.components.health ~= nil then
            if eater.components.health:IsDead() or eater:HasTag("playerghost") then
                return
            end
            eater.components.health:DoDelta(33, nil, inst.prefab)
        end
        if eater.components.sanity ~= nil then
            eater.components.sanity:DoDelta(6)
        end
        if eater.components.hunger ~= nil then
            eater.components.hunger:DoDelta(18.75)
        end
        if eater.components.genesis_blues ~= nil then
            eater.components.genesis_blues:DoDelta(-10)
        end
    end
end
table.insert(prefs, Prefab("petals_nightrose", function() ------夜玫瑰花瓣
    local inst = CreateEntity()
    fns.CommonFn(inst, "petals_nightrose", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.15, 1.2 })
    inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "petals_nightrose")
    fns.SetEdible(inst, { hunger = -9.375, sanity = -1, health = -8, fn_eat = pas.OnEat_nightrose })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.ServerFn_veggie(inst)
    fns.SetFuel(inst, TUNING.MED_LARGE_FUEL, FUELTYPE.NIGHTMARE)

    inst:AddComponent("z_repairerlegion")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.NIGHTMARE
    inst.components.repairer.finiteusesrepairvalue = TUNING.NIGHTMAREFUEL_FINITEUSESREPAIRVALUE/2

    return inst
end, fns.GetAssets("petals_nightrose"), nil))

pas.OnEat_shyerry = function(inst, eater)
    if eater.components.oldager == nil and eater.components.health ~= nil then
        eater:AddDebuff("buff_l_healthstorage", "buff_l_healthstorage", { value = 40 })
    end
end
table.insert(prefs, Prefab("shyerry", function() ------颤栗果
    local inst = CreateEntity()
    fns.CommonFn(inst, "shyerry", nil, "idle", nil)
    fns.SetFloatable(inst, { 0.04, "small", 0.25, 0.9 })

    inst.pickupsound = "vegetation_firm"
    inst:AddTag("cookable")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "shyerry")
    fns.SetEdible(inst, { hunger = 18.75, sanity = 0, health = 0, fn_eat = pas.OnEat_shyerry })
    fns.SetCookable(inst, "shyerry_cooked")
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_MED, "spoiled_food", nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("shyerry"), { "buff_l_healthstorage", "shyerry_cooked" }))

table.insert(prefs, Prefab("shyerry_cooked", function() ------烤颤栗果
    local inst = CreateEntity()
    fns.CommonFn(inst, "shyerry", nil, "cooked", nil)
    fns.SetFloatable(inst, { 0.02, "small", 0.2, 0.9 })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "shyerry_cooked")
    fns.SetEdible(inst, { hunger = 12.5, sanity = 1, health = 0 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets2("shyerry_cooked", "shyerry"), nil))

table.insert(prefs, Prefab("mint_l", function() ------猫薄荷
    local inst = CreateEntity()
    fns.CommonFn(inst, "mint_l", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.08, 0.95 })

    inst.pickupsound = "vegetation_firm"
    inst:AddTag("catfood")
    inst:AddTag("cattoy")
    inst:AddTag("catmint")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "mint_l")
    fns.SetEdible(inst, { hunger = 6, sanity = 8, health = 0 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_MED, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("mint_l"), nil))

table.insert(prefs, Prefab("albicans_cap", function() ------采摘的素白菇
    local inst = CreateEntity()
    fns.CommonFn(inst, "albicans_cap", nil, "idle", nil)
    fns.SetFloatable(inst, { 0.05, "small", 0.25, 1.2 })

    inst.pickupsound = "vegetation_firm"
    inst:AddTag("mushroom") --蘑菇农场用的
    inst:AddTag("cookable")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "albicans_cap")
    fns.SetEdible(inst, { hunger = 10, sanity = 0, health = 25 })
    fns.SetCookable(inst, "albicans_cap_cooked")
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FASTISH, "spoiled_food", nil)
    fns.ServerFn_veggie(inst)
    inst:AddComponent("z_repairerlegion")

    return inst
end, fns.GetAssets("albicans_cap"), { "albicans_cap_cooked" }))

table.insert(prefs, Prefab("albicans_cap_cooked", function() ------熟素白菇
    local inst = CreateEntity()
    fns.CommonFn(inst, "albicans_cap", nil, "cooked", nil)
    fns.SetFloatable(inst, { 0.01, "small", 0.2, 1.2 })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "albicans_cap_cooked")
    fns.SetEdible(inst, { hunger = 5, sanity = 5, health = 40 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_FAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets2("albicans_cap_cooked", "albicans_cap"), nil))

table.insert(prefs, Prefab("monstrain_leaf", function() ------雨竹叶
    local inst = CreateEntity()
    fns.CommonFn(inst, "monstrain_leaf", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.05, 1.1 })

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "monstrain_leaf")
    fns.SetEdible(inst, { hunger = 12.5, sanity = -15, health = -30, foodtype2 = FOODTYPE.MONSTER })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_MED, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("monstrain_leaf"), nil))

pas.OnEat_squamousfruit = function(inst, eater)
    if eater.components.moisture ~= nil then
        eater.components.moisture:DoDelta(-30)
    end
end
table.insert(prefs, Prefab("squamousfruit", function() ------鳞果
    local inst = CreateEntity()
    fns.CommonFn(inst, "squamousfruit", nil, "idle", nil)
    fns.SetFloatable(inst, { 0.05, "small", 0.2, 0.7 })

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "squamousfruit")
    fns.SetEdible(inst, { hunger = 25, sanity = -5, health = -3, fn_eat = pas.OnEat_squamousfruit })
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("squamousfruit"), nil))

pas.lure_bean_ice = {
    build = "oceanfishing_lure_mis", symbol = "hook_fig",
    single_use = true, lure_data = TUNING.OCEANFISHING_LURE.FIG
}
table.insert(prefs, Prefab("bean_l_ice", function() ------冰皂豆
    local inst = CreateEntity()
    fns.CommonFn(inst, "bean_l_ice", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.15, 1.1 })
    inst.pickupsound = "vegetation_firm"
    inst:AddTag("frozen") --放入冰冷容器后就会保鲜
    inst:AddTag("oceanfishing_lure") --海钓饵组件所需

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "bean_l_ice")
    fns.SetEdible(inst, { hunger = 9.375, sanity = -2.5, health = 20 })
    inst.components.edible.temperaturedelta = TUNING.COLD_FOOD_BONUS_TEMP
    inst.components.edible.temperatureduration = TUNING.FOOD_TEMP_AVERAGE

    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_SUPERSLOW, "spoiled_food", nil)
    inst:AddComponent("bait")
    inst:AddComponent("tradable")
    MakeHauntableLaunch(inst)
    inst:AddComponent("smotherer") --灭火组件
    fns.SetLure(inst, pas.lure_bean_ice)

    return inst
end, fns.GetAssets("bean_l_ice"), nil))

--------------------------------------------------------------------------
--[[ 各种道具 ]]
--------------------------------------------------------------------------

pas.OnLightning_core = function(inst) --因为拿在手上会有"INLIMBO"标签，所以携带时并不会吸引闪电，只有放在地上时才会
    if inst.components.fueled:GetPercent() < 1 then
        if math.random() < 0.5 then
            inst.components.fueled:DoDelta(5, nil)
        end
    end
end
table.insert(prefs, Prefab("tourmalinecore", function() ------电气石
    local inst = CreateEntity()
    fns.CommonFn(inst, "tourmalinecore", nil, "idle", nil)
    fns.SetFurnitureDecor_comm(inst)
    inst:AddTag("eleccore_l")
    inst:AddTag("lightningrod")
    inst:AddTag("battery_l")
    inst:AddTag("molebait")
    inst.pickupsound = "gem"
    LS_C_Init(inst, "tourmalinecore", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "tourmalinecore")
    fns.SetFurnitureDecor_serv(inst, nil)
    inst.components.inventoryitem:SetSinks(true) --它是石头，应该要沉入水底

    inst:AddComponent("bait")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.ELEC_L
    inst.components.fueled:InitializeFuelLevel(500)
    inst.components.fueled.accepting = true

    inst:AddComponent("batterylegion")
    inst.components.batterylegion:StartCharge()

    inst:ListenForEvent("lightningstrike", pas.OnLightning_core)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("tourmalinecore"), nil))

fns.CP_Open_item = function(self, doer, taskkey)
    if
        doer ~= nil and doer[taskkey] == nil and
        self.master.components.container:IsOpenedBy(doer)
    then
        local openpos = doer:GetPosition()
        doer[taskkey] = doer:DoPeriodicTask(0.5, function(doer)
            if doer:HasTag("playerghost") or (doer.components.health ~= nil and doer.components.health:IsDead()) then
                self:Close(doer)
            elseif doer:GetDistanceSqToPoint(openpos) > 4 then
                self:Close(doer)
            end
        end, 0.5)
        if doer.SoundEmitter then
            doer.SoundEmitter:PlaySound("maxwell_rework/magician_chest/open", nil, 0.7)
        end
    end
end
fns.CP_OnClose_item = function(self, doer, taskkey)
    if doer ~= nil and doer[taskkey] ~= nil then
        doer[taskkey]:Cancel()
        doer[taskkey] = nil
        if doer.SoundEmitter then
            doer.SoundEmitter:PlaySound("maxwell_rework/magician_chest/close", nil, 0.7)
        end
    end
end
pas.CP_Open_nut = function(self, doer, ...)
    self.Open_legion(self, doer, ...)
    fns.CP_Open_item(self, doer, "legiontask_boxopener")
end
pas.CP_OnClose_nut = function(self, doer, ...)
    self.OnClose_legion(self, doer, ...)
    if doer == nil or doer.legiontask_boxopener == nil then
        return
    end
    fns.CP_OnClose_item(self, doer, "legiontask_boxopener")
    if doer.components.health ~= nil and not doer.components.health:IsDead() and not doer:HasTag("playerghost") then
        local cost = 2
        if doer.siv_blood_l_reducer_v ~= nil then
            if doer.siv_blood_l_reducer_v >= 1 then
                cost = 0
            else
                cost = cost * (1-doer.siv_blood_l_reducer_v)
            end
        end
        if cost > 0 then
            --有人反馈被云松子扣血扣死后，背包打不开了，所以这里延迟扣血
            doer:DoTaskInTime(0.3, function()
                if doer.components.health ~= nil and not doer.components.health:IsDead() and not doer:HasTag("playerghost") then
                    doer.components.health:DoDelta(-cost, nil, self.inst.prefab, nil, nil, true)
                end
            end)
        end
    end
end
pas.OnLoadPostPass_nut = function(inst) --世界启动时，向世界容器注册自己
	if TheWorld.components.boxcloudpine ~= nil then
		TheWorld.components.boxcloudpine.openers[inst] = true
	end
end
table.insert(prefs, Prefab("boxopener_l", function() ------云松子
    local inst = CreateEntity()
    fns.CommonFn(inst, "boxopener_l", nil, "idle_nut", nil)
    fns.SetFurnitureDecor_comm(inst)
    fns.SetFloatable(inst, { 0.03, "small", 0.25, 0.9 })

    inst:AddTag("boxopener_l")

    inst:AddComponent("container_proxy")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "boxopener_l")
    fns.SetFurnitureDecor_serv(inst, nil)
    fns.SetFuel(inst, nil)
    MakeHauntableLaunch(inst)

    local container_proxy = inst.components.container_proxy
    container_proxy.Open_legion = container_proxy.Open
    container_proxy.OnClose_legion = container_proxy.OnClose
    container_proxy.Open = pas.CP_Open_nut
    container_proxy.OnClose = pas.CP_OnClose_nut

    inst.OnLoadPostPass = pas.OnLoadPostPass_nut
	if not POPULATING then
		if TheWorld.components.boxcloudpine ~= nil then
            TheWorld.components.boxcloudpine:SetMaster(inst)
        end
	end

    return inst
end, fns.GetAssets("boxopener_l"), nil))

pas.dapperness_opener = 100/(TUNING.DAY_TIME_DEFAULT*2)
pas.CP_Open_opener = function(self, doer, ...)
    self.Open_legion(self, doer, ...)
    fns.CP_Open_item(self, doer, "legiontask_boxopener2")
end
pas.CP_OnClose_opener = function(self, doer, ...)
    self.OnClose_legion(self, doer, ...)
    fns.CP_OnClose_item(self, doer, "legiontask_boxopener2")
end
pas.UpdateSanityHelper_opener = function(owner)
    if owner.components.sanity ~= nil then
        local bonus = pas.dapperness_opener
        if owner.components.sanity:IsLunacyMode() then
            bonus = -bonus
        end
        owner.components.sanity.externalmodifiers:SetModifier("sanityhelper_l", bonus, "boxopener_l")
    end
end
pas.SetFunction_opener = function(owner, isadd)
    if isadd then
        owner:ListenForEvent("sanitymodechanged", pas.UpdateSanityHelper_opener)
        pas.UpdateSanityHelper_opener(owner)
        TOOLS_L.AddEntValue(owner, "siv_blood_l_reducer", "siving_boxopener", 1, 0.25)
    else
        owner:RemoveEventCallback("sanitymodechanged", pas.UpdateSanityHelper_opener)
        if owner.components.sanity ~= nil then
            owner.components.sanity.externalmodifiers:RemoveModifier("sanityhelper_l", "boxopener_l")
        end
        TOOLS_L.RemoveEntValue(owner, "siv_blood_l_reducer", "siving_boxopener", 1)
    end
end
pas.OnOwnerChange_opener = function(inst, owner, newowners)
    if inst.owner_l == owner then --没变化
        return
    end
    --先取消以前的对象
    local ownerold = inst.owner_l
    if ownerold ~= nil and ownerold:IsValid() then
        if ownerold.legion_boxopener ~= nil then
            local newtbl
            ownerold.legion_boxopener[inst] = nil
            for k, _ in pairs(ownerold.legion_boxopener) do
                if k:IsValid() then
                    if newtbl == nil then
                        newtbl = {}
                    end
                    newtbl[k] = true
                end
            end
            if newtbl == nil then
                pas.SetFunction_opener(ownerold, false)
            end
            ownerold.legion_boxopener = newtbl
        else
            pas.SetFunction_opener(ownerold, false)
        end
    end
    --再尝试设置目前的对象
    inst.owner_l = owner
    if owner.legion_boxopener == nil then
        owner.legion_boxopener = {}
        pas.SetFunction_opener(owner, true)
    end
    owner.legion_boxopener[inst] = true
end
pas.OnRemove_opener = function(inst)
    pas.OnOwnerChange_opener(inst, inst)
end
table.insert(prefs, Prefab("siving_boxopener", function() ------子圭·系
    local inst = CreateEntity()
    fns.CommonFn(inst, "boxopener_l", nil, "idle_siv", nil)
    fns.SetFurnitureDecor_comm(inst)

    inst:AddTag("boxopener_l")

    inst:AddComponent("container_proxy")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "siving_boxopener")
    inst.components.inventoryitem:SetSinks(true)
    fns.SetFurnitureDecor_serv(inst, fns.Decor_owner)
    MakeHauntableLaunch(inst)

    local container_proxy = inst.components.container_proxy
    container_proxy.Open_legion = container_proxy.Open
    container_proxy.OnClose_legion = container_proxy.OnClose
    container_proxy.Open = pas.CP_Open_opener
    container_proxy.OnClose = pas.CP_OnClose_opener

    -- inst.owner_l = nil
    TOOLS_L.ListenOwnerChange(inst, pas.OnOwnerChange_opener, pas.OnRemove_opener)

    inst.OnLoadPostPass = pas.OnLoadPostPass_nut
	if not POPULATING then
		if TheWorld.components.boxcloudpine ~= nil then
            TheWorld.components.boxcloudpine:SetMaster(inst)
        end
	end

    return inst
end, fns.GetAssets2("siving_boxopener", "boxopener_l"), nil))

pas.dd_foliageath = {
    image = "foliageath_foliageath", atlas = "images/inventoryimages/foliageath_foliageath.xml",
    bank = nil, build = nil, anim = "foliageath", isloop = nil,
    togethered = "foliageath_mylove", --替换合并后的预制物名。默认不需要写，因为剑鞘本身特殊才写的
    --判断是否需要恢复耐久。第二个参数是为了识别是何种原因恢复耐久
    -- fn_recovercheck = function(inst, tag)end,
    --恢复耐久。根据 dt 这个时间参数来确定恢复的程度
    -- fn_recover = function(inst, dt, player, tag)end
}
pas.Test_fol = function(inst, doer, item, count)
    if item == nil then
        return false, "NOSWORD"
    elseif item.foliageath_data == nil then
        return false, "WRONGSWORD"
    end
    return true
end
pas.Do_fol = function(inst, doer, item, count)
    if item ~= nil then
        local togethered = SpawnPrefab(item.foliageath_data.togethered or "foliageath_together")
        if togethered ~= nil then
            togethered.components.swordscabbard:BeTogether(inst, item) --inst和item会在这里面被删除
        else
            item:Remove()
        end
    end
end
table.insert(prefs, Prefab("foliageath", function() ------青枝绿叶
    local inst = CreateEntity()
    fns.CommonFn(inst, "foliageath", nil, "lonely", nil)
    fns.SetFloatable(inst, { 0.15, "small", 0.4, 0.65 })

    inst:AddTag("swordscabbard")
    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.foliageath_data = pas.dd_foliageath

    fns.ServerFn(inst, "foliageath")
    fns.SetFuel(inst, TUNING.LARGE_FUEL)

    inst:AddComponent("emptyscabbardlegion")
    inst.components.emptyscabbardlegion.fn_test = pas.Test_fol
    inst.components.emptyscabbardlegion.fn_do = pas.Do_fol

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("foliageath"), { "foliageath_together", "foliageath_mylove" }))

pas.GetStatus_folto = function(inst)
    return "MERGED"
end
table.insert(prefs, Prefab("foliageath_together", function() ------入鞘后的青枝绿叶
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "foliageath", nil, "hambat", nil)
    fns.SetFloatable(inst, { 0.15, "small", 0.4, 0.65 })
    inst:SetPrefabNameOverride("foliageath")

    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "foliageath_hambat") --默认是火腿棒入鞘后的贴图
    inst.components.inspectable.getstatus = pas.GetStatus_folto

    inst:AddComponent("swordscabbard")
    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/foliageath.zip"),
    Asset("ATLAS", "images/inventoryimages/foliageath_rosorns.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_rosorns.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_rosorns.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_lileaves.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_lileaves.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_lileaves.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_orchitwigs.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_orchitwigs.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_orchitwigs.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_neverfade.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_neverfade.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_neverfade.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_hambat.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_hambat.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_hambat.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_bullkelp_root.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_bullkelp_root.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_bullkelp_root.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_foliageath.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_foliageath.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_foliageath.xml", 256),
    Asset("ATLAS", "images/inventoryimages/foliageath_dish_tomahawksteak.xml"),
    Asset("IMAGE", "images/inventoryimages/foliageath_dish_tomahawksteak.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/foliageath_dish_tomahawksteak.xml", 256)
}, { "foliageath" }))

pas.OnOwnerChange_follv = function(inst, owner, newowners)
    if inst.owner_l == owner then --没变化
        return
    end

    --先取消以前的对象
    local ownerold = inst.owner_l
    if ownerold ~= nil and ownerold:IsValid() and ownerold:HasTag("player") then
        if ownerold._follv_l ~= nil then
            local newtbl
            ownerold._follv_l[inst] = nil
            for k, _ in pairs(ownerold._follv_l) do
                if k:IsValid() then
                    if newtbl == nil then
                        newtbl = {}
                    end
                    newtbl[k] = true
                end
            end
            if newtbl == nil then
                if ownerold.components.sanity ~= nil then
                    ownerold.components.sanity.externalmodifiers:RemoveModifier("sanityhelper_l", "foliageath")
                end
            end
            ownerold._follv_l = newtbl
        else
            if ownerold.components.sanity ~= nil then
                ownerold.components.sanity.externalmodifiers:RemoveModifier("sanityhelper_l", "foliageath")
            end
        end
    end

    --再尝试设置目前的对象
    inst.owner_l = owner
    if owner:HasTag("player") then
        if owner._follv_l == nil then
            owner._follv_l = {}
            if owner.components.sanity ~= nil then
                owner.components.sanity.externalmodifiers:SetModifier(
                    "sanityhelper_l", TUNING.DAPPERNESS_LARGE, "foliageath")
            end
        end
        owner._follv_l[inst] = true
    end
end
pas.OnRemove_follv = function(inst)
    pas.OnOwnerChange_follv(inst, inst)
end
table.insert(prefs, Prefab("foliageath_mylove", function() ------青锋剑
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "foliageath", nil, "foliageath", nil)
    fns.SetFloatable(inst, { 0.15, "small", 0.4, 0.65 })

    inst:AddTag("feelmylove")
    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "foliageath_foliageath")
    inst:AddComponent("swordscabbard")
    MakeHauntableLaunch(inst)

    -- inst.owner_l = nil
    TOOLS_L.ListenOwnerChange(inst, pas.OnOwnerChange_follv, pas.OnRemove_follv)

    return inst
end, fns.GetAssets2("foliageath_foliageath", "foliageath"), { "foliageath" }))

pas.fooddd_explodcake = {
    hunger = 150, sanity = 5, health = 1, foodtype = FOODTYPE.GOODIES, foodtype2 = FOODTYPE.VEGGIE,
    fn_eat = function(inst, eater) --注意：该函数执行后，才会执行食物的删除操作
        --如果是一次性吃完类型的对象，直接爆炸吧，反正都要整体删除了
        if eater.components.eater and eater.components.eater.eatwholestack then
            inst.components.explosive:OnBurnt()
            return
        end
        --由于食用时会主动消耗一个，而爆炸会消耗全部，为了达到一次吃只炸一个的效果，新生成一个完成爆炸效果
        local fxfn = inst._dd_fxfn
        eater:DoTaskInTime(1.5+math.random(), function()
            if eater:IsValid() and not eater:IsInLimbo() then
                local cake = SpawnPrefab("explodingfruitcake")
                cake._dd_fxfn = fxfn
                cake.Transform:SetPosition(eater.Transform:GetWorldPosition())
                cake.components.explosive:OnBurnt()
            end
        end)
    end
}
pas.OnPutInInv_explodcake = function(inst, owner)
    if owner.prefab == "mole" then
        inst.components.explosive:OnBurnt()
    end
end
pas.Ignite_explodcake = function(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
    DefaultBurnFn(inst)
end
pas.Extinguish_explodcake = function(inst)
    inst.SoundEmitter:KillSound("hiss")
    DefaultExtinguishFn(inst)
end
pas.Explode_explodcake = function(inst)
    inst.SoundEmitter:KillSound("hiss")
    if inst._dd_fxfn ~= nil then
        inst._dd_fxfn(inst)
    else
        local fx = SpawnPrefab("explode_l_fruitcake")
        if fx ~= nil then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
end
table.insert(prefs, Prefab("explodingfruitcake", function() ------爆炸水果蛋糕
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "explodingfruitcake", nil, "idle", nil)
    fns.SetFurnitureDecor_comm(inst)
    inst:AddTag("molebait")
    inst:AddTag("explosive")
    inst:AddTag("pre-preparedfood")
    LS_C_Init(inst, "explodingfruitcake", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "explodingfruitcake")
    inst.components.inventoryitem:SetOnPutInInventoryFn(pas.OnPutInInv_explodcake)
    inst.components.inventoryitem:SetSinks(true)

    fns.SetStackable(inst, TUNING.STACK_SIZE_MEDITEM)
    fns.SetEdible(inst, pas.fooddd_explodcake)
    fns.SetFurnitureDecor_serv(inst, fns.Decor_stackfix)
    inst:AddComponent("bait")
    inst:AddComponent("tradable")

    MakeSmallBurnable(inst, 3 + math.random()*3)
    MakeSmallPropagator(inst)
    --V2C: Remove default OnBurnt handler, as it conflicts with
    --explosive component's OnBurnt handler for removing itself
    inst.components.burnable:SetOnBurntFn(nil)
    inst.components.burnable:SetOnIgniteFn(pas.Ignite_explodcake)
    inst.components.burnable:SetOnExtinguishFn(pas.Extinguish_explodcake)

    inst:AddComponent("explosive")
    inst.components.explosive:SetOnExplodeFn(pas.Explode_explodcake)
    inst.components.explosive.explosivedamage = 500 --火药伤害200
    inst.components.explosive.lightonexplode = false --不会点燃被炸者
    inst.components.explosive.explosiverange = 3.5 --火药半径是3

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end, fns.GetAssets("explodingfruitcake"), { "explode_l_fruitcake" }))

table.insert(prefs, Prefab("chestupgrader_l", function() ------月石角撑
    local inst = CreateEntity()
    fns.CommonFn(inst, "chestupgrader_l", nil, nil, nil)
    fns.SetFurnitureDecor_comm(inst)
    fns.SetFloatable(inst, { 0.05, "med", 0.2, 0.75 })

    inst:AddTag("chestupgrader_l") --能升级棱镜容器为无限容量

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "chestupgrader_l")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFurnitureDecor_serv(inst, fns.Decor_stackfix)

    local upgrader = inst:AddComponent("upgrader")
    upgrader.upgradetype = UPGRADETYPES.CHEST

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("chestupgrader_l")))

------

pas.dd_smear_sivbloodreduce = { build = "ointment_l_sivbloodreduce" }
pas.dd_smear_fireproof = { build = "ointment_l_fireproof" }

pas.Check_sivbloodreduce = function(inst, doer, target)
    if target.legionfn_smear_siv ~= nil then
        if target:HasTag("lifeless_l") then
            return false, "NONEED"
        else
            return true
        end
    end
    if target.components.combat == nil or target:HasTag("playerghost") or
        target.components.health == nil or target.components.health:IsDead()
    then
        return false, "NOUSE"
    end
    if --具有以下标签的对象，根本不会被窃血，所以也不用加buff
        target:HasTag("wall") or target:HasTag("structure") or target:HasTag("balloon") or
        target:HasTag("shadowminion") or target:HasTag("ghost")
    then
        return false, "NOUSE"
    end
    return true
end
pas.Smear_sivbloodreduce = function(inst, doer, target)
    if target.legionfn_smear_siv ~= nil then
        target.legionfn_smear_siv(target, doer, inst)
    else
        target:AddDebuff("buff_l_sivbloodreduce", "buff_l_sivbloodreduce", { value = fns.bfts.m6, max = fns.bfts.m15 })
    end
end
table.insert(prefs, Prefab("ointment_l_sivbloodreduce", function() ------弱肤药膏
    local inst = CreateEntity()
    fns.CommonFn(inst, "ointment_l_sivbloodreduce", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.25, 1 })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.dd_l_smear = pas.dd_smear_sivbloodreduce
    fns.ServerFn(inst, "ointment_l_sivbloodreduce")
    fns.SetStackable(inst, nil)
    fns.SetOintmentLegion(inst, pas.Check_sivbloodreduce, pas.Smear_sivbloodreduce)
    fns.SetFuel(inst, nil)
    fns.ServerFn_burn(inst, nil)

    return inst
end, fns.GetAssets("ointment_l_sivbloodreduce"), nil))

pas.Check_fireproof = function(inst, doer, target)
    if target.prefab == "nightstick" or target:HasTag("campfire") then
        return false, "NOUSE"
    end
    if target.components.burnable == nil or target:HasTag("burnt") then
        return false, "NOUSE"
    end
    if target.components.burnable.fireproof_legion then
        return false, "NONEED"
    end
    if target:HasTag("playerghost") or (target.components.health ~= nil and target.components.health:IsDead()) then
        return false, "NOUSE"
    end
    return true
end
pas.Smear_fireproof = function(inst, doer, target)
    if --是可燃物
        target:HasTag("wall") or target:HasTag("structure") or target:HasTag("balloon") or
        target.components.childspawner ~= nil or
        target.components.health == nil or target.components.combat == nil
    then
        local burnable = target.components.burnable
        burnable.fireproof_legion = true
        TOOLS_L.AddTag(target, "fireproof_legion", "fireproof_base")
        if burnable:IsBurning() or burnable:IsSmoldering() then
            burnable:Extinguish(true, -4) --涂抹完成，顺便灭火
        end
    else --是生物
        target:AddDebuff("buff_l_fireproof", "buff_l_fireproof", { value = fns.bfts.m6, max = fns.bfts.m15 })
    end
end
table.insert(prefs, Prefab("ointment_l_fireproof", function() ------防火漆
    local inst = CreateEntity()
    fns.CommonFn(inst, "ointment_l_fireproof", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.25, 1 })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.dd_l_smear = pas.dd_smear_fireproof
    fns.ServerFn(inst, "ointment_l_fireproof")
    fns.SetStackable(inst, nil)
    fns.SetOintmentLegion(inst, pas.Check_fireproof, pas.Smear_fireproof)
    fns.SetFuel(inst, nil)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("ointment_l_fireproof"), nil))

--------------------------------------------------------------------------
--[[ 基础材料 ]]
--------------------------------------------------------------------------

table.insert(prefs, Prefab("ahandfulofwings", function() ------虫翅碎片
    local inst = CreateEntity()
    fns.CommonFn(inst, "insectthings_l", nil, "wing", nil)
    fns.SetFloatable(inst, { nil, "small", 0.1, 1.2 })

    inst.pickupsound = "vegetation_grassy"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "ahandfulofwings")
    fns.SetStackable(inst, TUNING.STACK_SIZE_TINYITEM)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    inst:AddComponent("tradable")
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("ahandfulofwings", "insectthings_l"), nil))

table.insert(prefs, Prefab("insectshell_l", function() ------虫甲碎片
    local inst = CreateEntity()
    fns.CommonFn(inst, "insectthings_l", nil, "shell", nil)
    fns.SetFloatable(inst, { nil, "small", 0.1, 1.1 })

    inst.pickupsound = "vegetation_grassy"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "insectshell_l")
    fns.SetStackable(inst, TUNING.STACK_SIZE_TINYITEM)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    inst:AddComponent("z_repairerlegion")
    inst:AddComponent("tradable")
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("insectshell_l", "insectthings_l"), nil))

table.insert(prefs, Prefab("shyerrylog", function() ------宽大的木墩
    local inst = CreateEntity()
    fns.CommonFn(inst, "shyerrylog", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "med", 0.2, 0.8 })

    inst.pickupsound = "wood"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "shyerrylog")
    fns.SetEdible(inst, { hunger = 0, sanity = 0, health = 0, foodtype = FOODTYPE.WOOD }) --目前貌似就饼干切割机会吃木头
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.WOOD
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_BOARDS_HEALTH
    inst.components.repairer.boatrepairsound = "turnoftides/common/together/boat/repair_with_wood"

    fns.ServerFn_burn(inst, TUNING.LARGE_BURNTIME)

    return inst
end, fns.GetAssets("shyerrylog"), nil))

table.insert(prefs, Prefab("merm_scales", function() ------鱼鳞
    local inst = CreateEntity()
    fns.CommonFn(inst, "merm_scales", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "med", 0.1, 0.77 })

    inst:AddTag("cattoy")
    inst.pickupsound = "cloth"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "merm_scales")
    fns.SetEdible(inst, { hunger = 0, sanity = 0, health = 0, foodtype = FOODTYPE.HORRIBLE })
    fns.SetStackable(inst, nil)
    fns.SetTradable(inst, TUNING.GOLD_VALUES.MEAT * 2, nil)
    MakeHauntableLaunch(inst) --偏潮湿的道具，所以不会着火

    return inst
end, fns.GetAssets("merm_scales"), nil))

table.insert(prefs, Prefab("tourmalineshard", function() ------带电的晶石
    local inst = CreateEntity()
    fns.CommonFn(inst, "tourmalinecore", nil, "idle_shard", nil)
    fns.SetFurnitureDecor_comm(inst)
    inst:AddTag("battery_l")
    inst:AddTag("molebait")
    inst.pickupsound = "metal"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "tourmalineshard")
    inst.components.inventoryitem:SetSinks(true) --它是石头，应该要沉入水底

    fns.SetFurnitureDecor_serv(inst, fns.Decor_stackfix)
    fns.SetStackable(inst, TUNING.STACK_SIZE_MEDITEM)
    fns.SetTradable(inst, 4, 12)
    fns.SetEdible(inst, { hunger = 5, sanity = 0, health = 0, foodtype = FOODTYPE.ELEMENTAL })
    inst:AddComponent("bait")
    inst:AddComponent("batterylegion")
    inst:AddComponent("z_repairerlegion")
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("tourmalineshard", "tourmalinecore"), nil))

table.insert(prefs, Prefab("siving_rocks", function() ------子圭石。两个模组注册同名prefab，以最后加载的模组为准。棱镜比神话后加载
    local inst = CreateEntity()
    fns.CommonFn(inst, "myth_siving", nil, "siving_rocks", nil)

    inst:AddTag("molebait")
    inst:AddTag("quakedebris") --部分装备和生物能防御它的砸伤
    inst.pickupsound = "rock"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "siving_rocks")
    inst.components.inventoryitem:SetSinks(true)

    fns.SetStackable(inst, nil)
    fns.SetTradable(inst, 4, 6)
    fns.SetEdible(inst, { hunger = 5, sanity = 0, health = 0, foodtype = FOODTYPE.ELEMENTAL })
    inst:AddComponent("bait")
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("siving_rocks", "myth_siving"), nil))

--------------------------------------------------------------------------
--[[ 活性组织 ]]
--------------------------------------------------------------------------

pas.MakeTissue = function(name)
	local myname = "tissue_l_"..name
	table.insert(prefs, Prefab(myname, function()
        local inst = CreateEntity()
        fns.CommonFn(inst, "tissue_l", nil, "idle_"..name, nil)
        fns.SetFurnitureDecor_comm(inst)
        fns.SetFloatable(inst, { nil, "small", 0.1, 1 })

        inst:AddTag("tissue_l") --这个标签没啥用，就想加上而已
        inst.pickupsound = "vegetation_grassy"

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        fns.ServerFn(inst, myname)
        fns.SetFurnitureDecor_serv(inst, fns.Decor_stackfix)
        inst.components.inspectable.nameoverride = "TISSUE_L" --用来统一描述

        fns.SetStackable(inst, nil)
        fns.SetFuel(inst, nil)
        inst:AddComponent("tradable")
        fns.ServerFn_burn(inst, nil)

        return inst
    end, fns.GetAssets2(myname, "tissue_l"), nil))
end

pas.MakeTissue("cactus")
pas.MakeTissue("lureplant")
pas.MakeTissue("berries")
pas.MakeTissue("lightbulb")

--------------------------------------------------------------------------
--[[ 玩具 ]]
--------------------------------------------------------------------------

table.insert(prefs, Prefab("cattenball", function() ------猫线球
    local inst = CreateEntity()
    fns.CommonFn(inst, "toy_legion", nil, "toy_cattenball", nil)
    fns.SetFurnitureDecor_comm(inst)
    fns.SetFloatable(inst, { 0.08, "med", 0.25, 0.5 })

    inst:AddTag("cattoy")
    inst.pickupsound = "cloth"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cattenball")
    fns.SetFurnitureDecor_serv(inst, fns.Decor_stackfix)
    fns.SetStackable(inst, TUNING.STACK_SIZE_MEDITEM)
    fns.SetTradable(inst, 9, 3)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("cattenball", "toy_legion"), nil))

------玩具小海绵与玩具小海星：toy_spongebob，toy_patrickstar。隐藏废稿，不会做了

--------------------------------------------------------------------------
--[[ 可种植的物品 ]]
--------------------------------------------------------------------------

fns.OnDeploy = function(inst, pt, deployer, rot, dd)
    local tree
    if dd.skined then
        local skinname
        if LS_IsValidPlayer(deployer) then
            skinname = LS_LastChosenSkin(dd.prefab, deployer.userid)
        end
        if skinname == nil then
            tree = SpawnPrefab(dd.prefab)
        else
            tree = SpawnPrefab(dd.prefab, skinname, nil, deployer.userid)
        end
    else
        tree = SpawnPrefab(dd.prefab)
    end
    if tree ~= nil then
        -- if rot ~= nil then
        --     tree.Transform:SetRotation(rot)
        -- end
        tree.Transform:SetPosition(pt:Get())
        if inst.components.stackable ~= nil then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        if tree.components.pickable ~= nil then
            if dd.isempty then --直接进入生长状态
                tree.components.pickable:MakeEmpty()
            else
                tree.components.pickable:OnTransplant()
            end
        end
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound(dd.sound or "dontstarve/common/plant")
        end
        if tree.fn_planted ~= nil then --这个函数，棱镜里面已经没有东西在用了，可能要删
            tree.fn_planted(tree, pt)
        end
    end
end
fns.OnDeploy2 = function(inst, pt, deployer, rot, dd)
    local tree
    if inst.components.skinedlegion ~= nil then
        local skin = inst.components.skinedlegion:GetSkin()
        if skin == nil then
            tree = SpawnPrefab(dd.prefab)
        else
            tree = SpawnPrefab(dd.prefab, skin, nil, deployer.userid)
        end
    else
        tree = SpawnPrefab(dd.prefab)
    end
    if tree ~= nil then
        tree.Transform:SetPosition(pt:Get())
        if inst.components.stackable ~= nil then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound(dd.sound or "dontstarve/common/place_structure_stone")
        end
    end
end

pas.OnDeploy_rose = function(inst, pt, deployer, rot)
    local isit = nil
    if deployer ~= nil and deployer:HasTag("genesis_gaia") then isit = true end
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "rosebush", skined = true, isempty = isit, sound = nil })
end
table.insert(prefs, Prefab("dug_rosebush", function() ------蔷薇花丛(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "berrybush2", "rosebush", "dropped", nil)
    fns.SetFloatable(inst, { 0.03, "large", 0.2, {0.65, 0.5, 0.65} })

    inst:AddTag("deployedplant") --植株种植标签，植物人种下时能恢复精神等
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dug_rosebush")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_rose, DEPLOYMODE.PLANT, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("dug_rosebush", "rosebush"), nil))

pas.OnDeploy_lily = function(inst, pt, deployer, rot)
    local isit = nil
    if deployer ~= nil and deployer:HasTag("genesis_gaia") then isit = true end
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "lilybush", skined = true, isempty = isit })
end
table.insert(prefs, Prefab("dug_lilybush", function() ------蹄莲花丛(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "berrybush2", "lilybush", "dropped", nil)
    fns.SetFloatable(inst, { 0.03, "large", 0.2, {0.65, 0.5, 0.65} })

    inst:AddTag("deployedplant")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dug_lilybush")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_lily, DEPLOYMODE.PLANT, CONFIGS_LEGION.LILYBUSHSPACING or DEPLOYSPACING.MEDIUM)
    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("dug_lilybush", "lilybush"), nil))

pas.OnDeploy_orchid = function(inst, pt, deployer, rot)
    local isit = nil
    if deployer ~= nil and deployer:HasTag("genesis_gaia") then isit = true end
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "orchidbush", skined = true, isempty = isit })
end
table.insert(prefs, Prefab("dug_orchidbush", function() ------兰草花丛(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "berrybush2", "orchidbush", "dropped", nil)
    fns.SetFloatable(inst, { nil, "large", 0.1, {0.65, 0.5, 0.65} })

    inst:AddTag("deployedplant")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dug_orchidbush")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_orchid, DEPLOYMODE.PLANT, CONFIGS_LEGION.ORCHIDBUSHSPACING or DEPLOYSPACING.LESS)
    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("dug_orchidbush", "orchidbush"), nil))

pas.OnDeploy_nightrose = function(inst, pt, deployer, rot)
    local isit = nil
    if deployer ~= nil and deployer:HasTag("genesis_gaia") then isit = true end
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "nightrosebush", isempty = isit })
end
table.insert(prefs, Prefab("dug_nightrosebush", function() ------夜玫瑰花丛(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "nightrosebush", nil, "dropped", nil)
    fns.SetFloatable(inst, { 0.03, "large", 0.2, 0.65 })
    inst.AnimState:SetLightOverride(0.1)
    inst:AddTag("deployedplant")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dug_nightrosebush")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_nightrose, DEPLOYMODE.PLANT, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("dug_nightrosebush", "nightrosebush"), nil))

pas.OnDeploy_rose2 = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "rosebush", skined = true, isempty = true })
end
table.insert(prefs, Prefab("cutted_rosebush", function() ------蔷薇折枝
    local inst = CreateEntity()
    fns.CommonFn(inst, "rosebush", nil, "cutted", nil)
    fns.SetFloatable(inst, { nil, "large", 0.1, 0.55 })

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed") --能使其放入种子袋
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cutted_rosebush")
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_rose2, DEPLOYMODE.PLANT, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("cutted_rosebush", "rosebush"), nil))

pas.OnDeploy_lily2 = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "lilybush", skined = true, isempty = true })
end
table.insert(prefs, Prefab("cutted_lilybush", function() ------蹄莲芽束
    local inst = CreateEntity()
    fns.CommonFn(inst, "lilybush", nil, "cutted", nil)
    fns.SetFloatable(inst, { nil, "large", 0.1, 0.55 })

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cutted_lilybush")
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_lily2, DEPLOYMODE.PLANT, CONFIGS_LEGION.LILYBUSHSPACING or DEPLOYSPACING.MEDIUM)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("cutted_lilybush", "lilybush"), nil))

pas.OnDeploy_orchid2 = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "orchidbush", skined = true, isempty = true })
end
table.insert(prefs, Prefab("cutted_orchidbush", function() ------兰草种籽
    local inst = CreateEntity()
    fns.CommonFn(inst, "orchidbush", nil, "cutted", nil)
    fns.SetFloatable(inst, { nil, "large", 0.1, 0.55 })

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cutted_orchidbush")
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_orchid2, DEPLOYMODE.PLANT, CONFIGS_LEGION.ORCHIDBUSHSPACING or DEPLOYSPACING.LESS)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("cutted_orchidbush", "orchidbush"), nil))

pas.OnDeploy_nightrose2 = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "nightrosebush", isempty = true })
end
table.insert(prefs, Prefab("cutted_nightrosebush", function() ------夜玫瑰棘果
    local inst = CreateEntity()
    fns.CommonFn(inst, "petals_nightrose", nil, "cutted", nil)
    fns.SetFloatable(inst, { nil, "small", 0.15, 1.2 })
    inst.AnimState:SetLightOverride(0.1)

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed") --能使其放入种子袋
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cutted_nightrosebush")
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_nightrose2, DEPLOYMODE.PLANT, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("cutted_nightrosebush", "petals_nightrose"), nil))

pas.OnDeploy_lumpy = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "lumpy_sapling" })
end
table.insert(prefs, Prefab("cutted_lumpyevergreen", function() ------臃肿常青树嫩枝
    local inst = CreateEntity()
    fns.CommonFn(inst, "cutted_lumpyevergreen", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.2, 1.35 })

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "cutted_lumpyevergreen")
    fns.SetStackable(inst, nil)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_lumpy, DEPLOYMODE.PLANT, nil)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets("cutted_lumpyevergreen"), nil))

pas.OnTreeLive_siv_derivant = function(inst, state)
    inst.treeState = state
    if state == 2 then
        inst.AnimState:PlayAnimation("item_live")
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(0.6)
        inst.Light:Enable(true)
    elseif state == 1 then
        inst.AnimState:PlayAnimation("item")
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(0.3)
        inst.Light:Enable(true)
    else
        inst.AnimState:PlayAnimation("item")
        inst.components.bloomer:PopBloom("activetree")
        inst.Light:Enable(false)
    end
end
pas.OnDropped_siv_derivant = function(inst)
    inst.OnTreeLive(inst, 0) --不知道为啥捡起时已经关闭光源了，但还是发了光，所以这里丢弃时再次关闭光源
end
pas.OnPickup_siv_derivant = function(inst)
    inst.OnTreeLive(inst, nil)
end
pas.OnDeploy_siv_derivant = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "siving_derivant", skined = true })
end
pas.Decor_siv_derivant = function(inst, furniture)
    fns.Decor_stackfix(inst, furniture)
    pas.OnDropped_siv_derivant(inst)
end
table.insert(prefs, Prefab("siving_derivant_item", function() ------子圭奇型岩(物品)
    local inst = CreateEntity()
    inst.entity:AddLight()
    fns.CommonFn(inst, "siving_derivant", nil, "item", nil)
    fns.SetFurnitureDecor_comm(inst)

    inst.Light:Enable(false)
    inst.Light:SetRadius(0.3)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(15/255, 180/255, 132/255)

    inst:AddTag("siving_derivant")
    inst.pickupsound = "metal"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.treeState = 0
    inst.OnTreeLive = pas.OnTreeLive_siv_derivant

    fns.ServerFn(inst, "siving_derivant_item")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem:SetOnDroppedFn(pas.OnDropped_siv_derivant)
    inst.components.inventoryitem:SetOnPickupFn(pas.OnPickup_siv_derivant)

    fns.SetFurnitureDecor_serv(inst, pas.Decor_siv_derivant)
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetDeployable(inst, pas.OnDeploy_siv_derivant, nil, nil)
    inst:AddComponent("bloomer")

    return inst
end, fns.GetAssets2("siving_derivant_item", "siving_derivant"), nil))

pas.OnDeploy_monstrain = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "monstrain_wizen" })
end
table.insert(prefs, Prefab("dug_monstrain", function() ------雨竹块茎(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "monstrain", nil, "dropped", nil)
    fns.SetFloatable(inst, { nil, "small", 0.2, 1.2 })

    inst:AddTag("deployedplant")
    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dug_monstrain")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.SMALL_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_monstrain, DEPLOYMODE.PLANT, nil)
    fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

    return inst
end, fns.GetAssets2("dug_monstrain", "monstrain"), nil))

pas.OnDeploy_shyerrycore = function(inst, pt, deployer, rot)
    fns.OnDeploy(inst, pt, deployer, rot, { prefab = "shyerrycore_planted" })
end
table.insert(prefs, Prefab("shyerrycore_item", function() ------颤栗树心芽
    local inst = CreateEntity()
    fns.CommonFn(inst, "shyerrycore_planted", nil, "item", nil)
    fns.SetFloatable(inst, { 0.02, "med", 0.2, 0.7 })

    inst:AddTag("deployedplant")
    inst:AddTag("treeseed")
    inst.pickupsound = "vegetation_grassy"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "shyerrycore_item")
    fns.SetStackable(inst, TUNING.STACK_SIZE_LARGEITEM)
    fns.SetFuel(inst, TUNING.LARGE_FUEL)
    fns.SetDeployable(inst, pas.OnDeploy_shyerrycore, DEPLOYMODE.PLANT, DEPLOYSPACING.PLACER_DEFAULT)
    fns.ServerFn_burn(inst, TUNING.LARGE_BURNTIME)

    return inst
end, fns.GetAssets2("shyerrycore_item", "shyerrycore_planted", { Asset("ANIM", "anim/shyerrybush.zip") }), nil))

pas.OnDeploy_pebble_nitre = function(inst, pt, deployer, rot)
    fns.OnDeploy2(inst, pt, deployer, rot, { prefab = "pebble_l_nitre", sound = "aqol/new_test/rock" })
end
table.insert(prefs, Prefab("pebbleitem_l_nitre", function() ------碎石块(物品)
    local inst = CreateEntity()
    fns.CommonFn(inst, "pebble_l_nitre", nil, "item", nil)
    inst:AddTag("deploykititem") --为了让deployable组件的摆放动作显示为“放置”
    inst:AddTag("molebait")
    inst:AddTag("quakedebris")
    inst.pickupsound = "rock"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pebbleitem_l_nitre")
    inst.components.inventoryitem:SetSinks(true)

    fns.SetEdible(inst, { foodtype = FOODTYPE.ELEMENTAL, foodtype2 = FOODTYPE.NITRE, hunger = 0.5 })
    fns.SetStackable(inst, TUNING.STACK_SIZE_TINYITEM)
    fns.SetFuel(inst, TUNING.SMALL_FUEL*2, FUELTYPE.CHEMICAL)
    fns.SetDeployable(inst, pas.OnDeploy_pebble_nitre, nil, DEPLOYSPACING.NONE)
    inst:AddComponent("bait")
    inst:AddComponent("tradable")
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets2("pebbleitem_l_nitre", "pebble_l_nitre"), nil))

----------
--异种
----------

pas.assets_xeed = fns.GetAssets2("seeds_crop_l2", "seeds_crop_l")
pas.MakeXeed = function(k, dd)
    local cropprefab = "plant_"..k.."_l"
    local function DisplayName_xeed(inst)
        return STRINGS.NAMES[string.upper(cropprefab)]..STRINGS.NAMEDETAIL_L.XEEDS
    end
    local function OnDeploy_xeed(inst, pt, deployer, rot)
        fns.OnDeploy(inst, pt, deployer, rot, {
            prefab = cropprefab, skined = true, sound = "dontstarve/wilson/plant_seeds"
        })
    end
    table.insert(prefs, Prefab("seeds_"..k.."_l", function()
        local inst = CreateEntity()
        fns.CommonFn(inst, "seeds_crop_l", nil, "idle", nil)
        fns.SetFloatable(inst, { nil, "small", 0.2, 1.2 })

        inst:AddTag("deployedplant")
        inst:AddTag("treeseed")
        inst.pickupsound = "vegetation_firm"
        -- inst.overridedeployplacername = seedsprefab.."_placer" --这个可以让placer换成另一个
        inst.displaynamefn = DisplayName_xeed

        local imgbg
        if dd.image ~= nil then
            imgbg = { image = dd.image.name, atlas = dd.image.atlas }
        else
            imgbg = {}
        end
        if imgbg.image == nil then
            imgbg.image = k..".tex"
        end
        if imgbg.atlas == nil then
            imgbg.atlas = GetInventoryItemAtlas(imgbg.image)
        end
        inst.inv_image_bg = imgbg

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.legion_sivbirdfood = 1 --能给予玄鸟换取子圭石

        fns.ServerFn(inst, "seeds_crop_l2")
        inst.components.inspectable.nameoverride = "SEEDS_CROP_L"

        fns.SetStackable(inst, TUNING.STACK_SIZE_PELLET)
        fns.SetFuel(inst, TUNING.SMALL_FUEL)
        fns.SetDeployable(inst, OnDeploy_xeed, DEPLOYMODE.PLANT, nil)

        inst:AddComponent("plantablelegion")
        inst.components.plantablelegion.plant = cropprefab
        inst.components.plantablelegion.plant2 = dd.plant2 --同一个异种种子可能能升级第二种对象

        fns.ServerFn_burn(inst, TUNING.SMALL_BURNTIME)

        return inst
    end, pas.assets_xeed, nil))
end

for k, v in pairs(CROPS_DATA_LEGION) do
    pas.MakeXeed(k, v)
end

--------------------------------------------------------------------------
--[[ 作物种子、果实相关 ]]
--------------------------------------------------------------------------

fns.OVERSIZED_PHYSICS_RADIUS = 0.1
fns.OVERSIZED_PERISHTIME_MULT = 4
fns.lure_seeds = {
    build = "oceanfishing_lure_mis", symbol = "hook_seeds",
    single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED
}

fns.GetDisplayName_seeds = function(inst)
	local registry_key = inst.plant_def.product
	local plantregistryinfo = inst.plant_def.plantregistryinfo
	return (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo)
            and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)
            ) and STRINGS.NAMES["KNOWN_"..string.upper(inst.prefab)]
			or nil
end
fns.CanDeploy_seeds = function(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end
fns.OnDeploy_seeds = function(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab(inst.components.farmplantable.plant)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    --plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    inst:Remove()
end
fns.CommonFn_cropseeds = function(inst, product)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("deployedplant")
    inst:AddTag("deployedfarmplant")

    inst.pickupsound = "vegetation_firm"
    inst.overridedeployplacername = "seeds_placer"
    inst.plant_def = PLANT_DEFS[product]
    inst.displaynamefn = fns.GetDisplayName_seeds
    inst._custom_candeploy_fn = fns.CanDeploy_seeds -- for DEPLOYMODE.CUSTOM
end
fns.ServerFn_cropseeds = function(inst, product)
    inst:AddComponent("farmplantable")
    inst.components.farmplantable.plant = "farm_plant_"..product

    --已被舍弃的旧版农场的配合组件
    inst:AddComponent("plantable")
    inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
    inst.components.plantable.product = product

    --已被舍弃的植物人直接种作物的机制
    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
    inst.components.deployable.restrictedtag = "plantkin"
    inst.components.deployable.ondeploy = fns.OnDeploy_seeds
end

fns.OnEquip_crophuge = function(inst, owner)
	local swap = inst.components.symbolswapdata
    owner.AnimState:OverrideSymbol("swap_body", swap.build, swap.symbol)
end
fns.OnUnequip_crophuge = function(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end
fns.OnWorkedFinish_crophuge = function(inst, worker)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end
fns.OnBurnt_crophuge = function(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end
fns.CommonFn_crophuge = function(inst, bank, build, anim, isloop, product)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle_oversized", isloop)

    inst:AddTag("heavy")
    inst:AddTag("oversized_veggie")

    inst.gymweight = 4
    inst._base_name = product

    MakeHeavyObstaclePhysics(inst, fns.OVERSIZED_PHYSICS_RADIUS)
    inst:SetPhysicsRadiusOverride(fns.OVERSIZED_PHYSICS_RADIUS)
end
fns.ServerFn_crophuge = function(inst, build, swap, loot, fireproof)
    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(fns.OVERSIZED_PHYSICS_RADIUS)

    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(fns.OnEquip_crophuge)
    inst.components.equippable:SetOnUnequip(fns.OnUnequip_crophuge)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(fns.OnWorkedFinish_crophuge)

    inst:AddComponent("submersible")
    inst:AddComponent("symbolswapdata")
    inst.components.symbolswapdata:SetData(build, swap)

    inst:AddComponent("lootdropper")
    if loot ~= nil then
        inst.components.lootdropper:SetLoot(loot)
    end

    if not fireproof then
        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(fns.OnBurnt_crophuge)
        MakeMediumPropagator(inst)
    end

    MakeHauntableWork(inst)
end
fns.CommonFn_crophuge_rotten = function(inst)
    inst:AddTag("farm_plant_killjoy")
    inst:AddTag("pickable_harvest_str")
    inst:AddTag("pickable")
    inst.gymweight = 3
end
fns.ServerFn_crophuge_rotten = function(inst)
    inst.components.inspectable.nameoverride = "VEGGIE_OVERSIZED_ROTTEN"

    inst:AddComponent("pickable")
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable:SetUp(nil)
    inst.components.pickable.use_lootdropper_for_product = true
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
end

fns.OnPerish_crophuge = function(inst)
    -- vars for rotting on a gym
    local owner = inst.components.inventoryitem:GetGrandOwner()
	local gym = owner and owner:HasTag("gym") and owner or nil
    local rot = nil
    local slot = nil

	if owner and gym == nil then --玩家装备时烂掉就会直接烂在身上
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
fns.OnWaxed_crophuge = function(inst, doer, waxitem)
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
fns.CalcWeightCoefficient_crophuge = function(weight_data)
    if weight_data[3] ~= nil and math.random() < weight_data[3] then
        return (math.random() + math.random()) / 2
    else
        return math.random()
    end
end
fns.SetWeighable_crophuge = function(inst, kind, weight_data)
    fns.SetWeighable(inst, kind)
    inst.components.weighable:Initialize(weight_data[1], weight_data[2])
    local coefficient = fns.CalcWeightCoefficient_crophuge(weight_data)
    inst.components.weighable:SetWeight(Lerp(weight_data[1], weight_data[2], coefficient))
end
fns.GetLoots_crophuge = function(inst, name)
    local product = name
	local seeds = name.."_seeds"
    return { product, product, seeds, seeds, math.random() < 0.75 and product or seeds }
end
fns.OnSave_crophuge = function(inst, data)
	data.from_plant = inst.from_plant or false
    data.harvested_on_day = inst.harvested_on_day
end
fns.OnPreLoad_crophuge = function(inst, data)
	inst.from_plant = (data and data.from_plant) ~= false
	if data ~= nil then
        inst.harvested_on_day = data.harvested_on_day
	end
end
fns.Init_crophuge = function(inst)
    inst.harvested_on_day = inst.harvested_on_day or (TheWorld.state.cycles + 1)
    inst.from_plant = false

    inst.OnSave = fns.OnSave_crophuge
    inst.OnPreLoad = fns.OnPreLoad_crophuge
end

fns.DisplayAdjective_crophuge_wax = function(inst)
    return STRINGS.UI.HUD.WAXED
end
fns.PlayAnim_crophuge_wax = function(inst)
	inst.AnimState:PlayAnimation("wax_oversized")
    inst.AnimState:PushAnimation("idle_oversized", false)
end
fns.TaskOff_wax = function(inst)
	if inst._waxtask ~= nil then
		inst._waxtask:Cancel()
		inst._waxtask = nil
	end
end
fns.TaskOn_wax = function(inst)
	if not inst.inlimbo and inst._waxtask == nil then
		inst._waxtask = inst:DoTaskInTime(GetRandomMinMax(20, 40), fns.PlayAnim_crophuge_wax)
	end
end
fns.ServerFn_crophuge_wax = function(inst)
    inst:ListenForEvent("onputininventory", fns.TaskOff_wax)
    inst:ListenForEvent("ondropped", fns.TaskOn_wax)

    inst.OnEntitySleep = fns.TaskOff_wax
    inst.OnEntityWake = fns.TaskOn_wax

    fns.TaskOn_wax(inst)
end

----------
--松萝相关
----------

table.insert(prefs, Prefab("pineananas_seeds", function() ------松萝种子
    local inst = CreateEntity()
    fns.CommonFn(inst, "pineananas", nil, "seeds", nil)
    fns.CommonFn_cropseeds(inst, "pineananas")
    fns.SetFloatable(inst, { -0.1, "small", nil, nil })

    inst:AddTag("cookable") --烤制组件所需
    inst:AddTag("oceanfishing_lure") --海钓饵组件所需

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pineananas_seeds")
    fns.SetEdible(inst, { hunger = TUNING.CALORIES_TINY, sanity = nil, health = 0.5, foodtype = FOODTYPE.SEEDS })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_SUPERSLOW, "spoiled_food", nil)
    fns.SetCookable(inst, "seeds_cooked")
    fns.SetLure(inst, fns.lure_seeds)
    fns.ServerFn_cropseeds(inst, "pineananas")
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets_inv("pineananas_seeds", {
    -- Asset("ANIM", "anim/farm_plant_seeds.zip"), --Tip：不要再注册动官方作物动画，会导致动画顺序混乱，因为作物动画有注册顺序要求
    Asset("ANIM", "anim/pineananas.zip"),
    Asset("ANIM", "anim/oceanfishing_lure_mis.zip")
}), { "farm_plant_pineananas" }))

table.insert(prefs, Prefab("pineananas", function() ------松萝
    local inst = CreateEntity()
    fns.CommonFn(inst, "pineananas", nil, "idle", nil)
    fns.SetFloatable(inst, { nil, "small", 0.2, 0.9 })

    inst:AddTag("cookable")
    inst:AddTag("weighable_OVERSIZEDVEGGIES") --称重组件所需

    inst.pickupsound = "vegetation_firm"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pineananas")
    fns.SetEdible(inst, { hunger = 12, sanity = -10, health = 8 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_MED, "spoiled_food", nil)
    fns.SetCookable(inst, "pineananas_cooked")
    fns.SetWeighable(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets("pineananas"), fns.GetPrefabs_crop("pineananas", { "pineananas_cooked" })))

table.insert(prefs, Prefab("pineananas_cooked", function() ------烤松萝
    local inst = CreateEntity()
    fns.CommonFn(inst, "pineananas", nil, "cooked", nil)
    fns.SetFloatable(inst, { nil, "small", 0.2, 1 })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pineananas_cooked")
    fns.SetEdible(inst, { hunger = 18.5, sanity = 5, health = 16 })
    fns.SetStackable(inst, nil)
    fns.SetPerishable(inst, TUNING.PERISH_SUPERFAST, "spoiled_food", nil)
    fns.SetFuel(inst, nil)
    fns.ServerFn_veggie(inst)

    return inst
end, fns.GetAssets2("pineananas_cooked", "pineananas"), nil))

table.insert(prefs, Prefab("pineananas_oversized", function() ------巨型松萝
    local inst = CreateEntity()

    local plant_def = PLANT_DEFS["pineananas"]
    fns.CommonFn_crophuge(inst, plant_def.bank, plant_def.build, nil, nil, "pineananas")

    inst:AddTag("waxable") --打蜡组件所需
    inst:AddTag("show_spoilage")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    local myloot = fns.GetLoots_crophuge(inst, "pineananas")
    table.insert(myloot, "pinecone")

    fns.Init_crophuge(inst)
    fns.ServerFn(inst, "pineananas_oversized")
    fns.ServerFn_crophuge(inst, plant_def.build, "swap_body", myloot, nil)
    fns.SetWaxable(inst, fns.OnWaxed_crophuge)
    fns.SetWeighable_crophuge(inst, nil, plant_def.weight_data)
    fns.SetPerishable(inst, TUNING.PERISH_MED*fns.OVERSIZED_PERISHTIME_MULT, nil, fns.OnPerish_crophuge)

    return inst
end, fns.GetAssets2("pineananas_oversized", "farm_plant_pineananas"), nil))

table.insert(prefs, Prefab("pineananas_oversized_waxed", function() ------巨型松萝（打过蜡的）
    local inst = CreateEntity()

    local plant_def = PLANT_DEFS["pineananas"]
    fns.CommonFn_crophuge(inst, plant_def.bank, plant_def.build, nil, nil, "pineananas")

    inst.displayadjectivefn = fns.DisplayAdjective_crophuge_wax
    inst:SetPrefabNameOverride("pineananas_oversized")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pineananas_oversized_waxed")
    fns.ServerFn_crophuge(inst, plant_def.build, "swap_body", {"spoiled_food"}, nil)
    fns.ServerFn_crophuge_wax(inst)

    return inst
end, fns.GetAssets2("pineananas_oversized_waxed", "farm_plant_pineananas"), nil))

table.insert(prefs, Prefab("pineananas_oversized_rotten", function() ------巨型腐烂松萝
    local inst = CreateEntity()

    local plant_def = PLANT_DEFS["pineananas"]
    fns.CommonFn_crophuge(inst, plant_def.bank, plant_def.build, "idle_rot_oversized", nil, "pineananas")
    fns.CommonFn_crophuge_rotten(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "pineananas_oversized_rotten")
    fns.ServerFn_crophuge(inst, plant_def.build, "swap_body_rotten", plant_def.loot_oversized_rot, nil)
    fns.ServerFn_crophuge_rotten(inst)

    return inst
end, fns.GetAssets2("pineananas_oversized_rotten", "farm_plant_pineananas"), nil))

--------------------------------------------------------------------------
--[[ 鸳鸯石 ]]
--------------------------------------------------------------------------

-- Heatrock emits constant temperatures depending on the temperature range it's in
pas.emitted_temperatures = { -10, 10, 25, 40, 60 }

-- These represent the boundaries between the ranges (relative to ambient, so ambient is always "0")
pas.relative_temperature_thresholds = { -30, -10, 10, 30 }

pas.GetStatus_icire = function(inst)
    if inst.currentTempRange == 1 then
        return "FROZEN"
    elseif inst.currentTempRange == 2 then
        return "COLD"
    elseif inst.currentTempRange == 4 then
        return "WARM"
    elseif inst.currentTempRange == 5 then
        return "HOT"
    end
end
pas.GetRangeForTemperature_icire = function(temp, ambient)
    local range = 1
    for i,v in ipairs(pas.relative_temperature_thresholds) do
        if temp > ambient + v then
            range = range + 1
        end
    end
    return range
end
pas.Heat_icire = function(inst, observer)
    local range = pas.GetRangeForTemperature_icire(inst.components.temperature:GetCurrent(), TheWorld.state.temperature)
    if range <= 2 then
        inst.components.heater:SetThermics(false, true)
    elseif range >= 4 then
        inst.components.heater:SetThermics(true, false)
    else
        inst.components.heater:SetThermics(false, false)
    end
    return pas.emitted_temperatures[range]
end
pas.UpdateImage_icire = function(inst, range)
    inst.currentTempRange = range
    inst.AnimState:PlayAnimation(tostring(range), true)

    local canbloom = true
    local newname = "icire_rock"..tostring(range)
    if inst._dd ~= nil then
        newname = newname..inst._dd.img_pst
        inst.components.inventoryitem.atlasname = "images/inventoryimages_skin/"..newname..".xml"
        inst.components.inventoryitem:ChangeImageName(newname)
        canbloom = inst._dd.canbloom
        if inst._dd.tempfn ~= nil then
            inst._dd.tempfn(inst, range)
        end
    else
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..newname..".xml"
        inst.components.inventoryitem:ChangeImageName(newname)
    end

    --最冷与最热都会发光
    if range == 1 then
        inst._light.Light:SetColour(64/255, 64/255, 208/255)
        inst._light.Light:Enable(true)
    elseif range == 5 then
        inst._light.Light:SetColour(235/255, 165/255, 12/255)
        inst._light.Light:Enable(true)
    else
        canbloom = false
        inst._light.Light:Enable(false)
    end
    if canbloom then
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    else
        inst.AnimState:ClearBloomEffectHandle()
    end
end
pas.UpdateLight_icire = function(inst, range, ambient)
    if range == 1 or range == 5 then --最冷或最热都能发光
        local brightline = pas.relative_temperature_thresholds[4] --30度
        local relativetemp = inst.components.temperature:GetCurrent()
        if ambient >= relativetemp then --算出目前的温差
            relativetemp = ambient - relativetemp - brightline --温差与30度的差距
        else
            relativetemp = relativetemp - ambient - brightline --温差与30度的差距
        end
        brightline = brightline + 20
        inst._light.Light:SetIntensity(math.clamp(0.5*relativetemp/brightline, 0, 0.5)) --clamp()用于控制结果在0到0.5之间
    else
        inst._light.Light:SetIntensity(0)
    end
end
pas.TemperatureChange_icire = function(inst, data)
    local ambient_temp = TheWorld.state.temperature
    local range = pas.GetRangeForTemperature_icire(inst.components.temperature:GetCurrent(), ambient_temp)
    pas.UpdateLight_icire(inst, range, ambient_temp)
    if range ~= inst.currentTempRange then
        pas.UpdateImage_icire(inst, range)
    end
end
pas.OnOwnerChange_icire = function(inst, owner, newowners)
    if owner:HasTag("pocketdimension_container") or owner:HasTag("buried") then
        inst._light.entity:SetParent(inst.entity)
		if not inst._light:IsInLimbo() then
			inst._light:RemoveFromScene() --直接隐藏，就算因为温度变化导致亮起来了也没事
		end
        inst.inworldbox_l = true
        if inst._dd ~= nil and inst._dd.entsleepfn ~= nil then
            inst._dd.entsleepfn(inst)
        end
    else
        inst._light.entity:SetParent(owner.entity)
		if inst._light:IsInLimbo() then
			inst._light:ReturnToScene()
		end
        inst.inworldbox_l = nil
        if not inst:IsAsleep() then
            if inst._dd ~= nil and inst._dd.entwakefn ~= nil then
                inst._dd.entwakefn(inst)
            end
        end
    end
end
pas.TempFn_icire = function(inst)
    pas.UpdateImage_icire(inst, inst.currentTempRange or 3)
end
pas.OnEntityWake_icire = function(inst)
    if inst._dd ~= nil and inst._dd.entwakefn ~= nil then
        inst._dd.entwakefn(inst)
    end
end
pas.OnEntitySleep_icire = function(inst)
    if inst._dd ~= nil and inst._dd.entsleepfn ~= nil then
        inst._dd.entsleepfn(inst)
    end
end
pas.OnRemove_icire = function(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
end
pas.Wax_icire = function(inst, doer, waxitem, right)
    local dd = { state = inst.currentTempRange }
    return TOOLS_L.WaxObject(inst, doer, waxitem, "icire_rock_item_waxed", dd, nil)
end

table.insert(prefs, Prefab("icire_rock", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "heat_rock", nil, "3", true)
    fns.SetFurnitureDecor_comm(inst)
    inst.entity:AddSoundEmitter() --不知道为啥官方要给暖石加这个，应该是没用的
    inst.AnimState:OverrideSymbol("rock", "icire_rock", "rock")
    inst.AnimState:OverrideSymbol("shadow", "icire_rock", "shadow")

    inst:AddTag("heatrock")
    inst:AddTag("icebox_valid")
    inst:AddTag("bait")
    inst:AddTag("molebait") --吸引鼹鼠
    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分
    inst:AddTag("HASHEATER")
    inst:AddTag("waxable_l")

    LS_C_Init(inst, "icire_rock", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "icire_rock")
    inst.components.inspectable.getstatus = pas.GetStatus_icire
    inst.components.inventoryitem:SetSinks(true) --它是石头，应该要沉入水底
    fns.SetTradable(inst, 7, 10)
    fns.SetFurnitureDecor_serv(inst, fns.Decor_owner)

    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED
    inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED
    inst.components.temperature:IgnoreTags("heatrock")

    inst:AddComponent("heater")
    inst.components.heater.heatfn = pas.Heat_icire
    inst.components.heater.carriedheatfn = pas.Heat_icire
    inst.components.heater.carriedheatmultiplier = TUNING.HEAT_ROCK_CARRIED_BONUS_HEAT_FACTOR
    inst.components.heater:SetThermics(false, false)

    inst:ListenForEvent("temperaturedelta", pas.TemperatureChange_icire)

    --Create light
    inst._light = SpawnPrefab("heatrocklight")
    inst.currentTempRange = 1

    inst.fn_temp = pas.TempFn_icire
    pas.UpdateImage_icire(inst, 1)
    TOOLS_L.ListenOwnerChange(inst, pas.OnOwnerChange_icire)

    MakeHauntableLaunchAndSmash(inst)

    inst.OnEntitySleep = pas.OnEntitySleep_icire
    inst.OnEntityWake = pas.OnEntityWake_icire
    inst.OnRemoveEntity = pas.OnRemove_icire
    inst.legionfn_wax = pas.Wax_icire

    return inst
end, fns.GetAssets("icire_rock", {
    Asset("ATLAS", "images/inventoryimages/icire_rock1.xml"),
    Asset("IMAGE", "images/inventoryimages/icire_rock1.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/icire_rock1.xml", 256),
    Asset("ATLAS", "images/inventoryimages/icire_rock2.xml"),
    Asset("IMAGE", "images/inventoryimages/icire_rock2.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/icire_rock2.xml", 256),
    Asset("ATLAS", "images/inventoryimages/icire_rock3.xml"),
    Asset("IMAGE", "images/inventoryimages/icire_rock3.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/icire_rock3.xml", 256),
    Asset("ATLAS", "images/inventoryimages/icire_rock4.xml"),
    Asset("IMAGE", "images/inventoryimages/icire_rock4.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/icire_rock4.xml", 256),
    Asset("ATLAS", "images/inventoryimages/icire_rock5.xml"),
    Asset("IMAGE", "images/inventoryimages/icire_rock5.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/icire_rock5.xml", 256),
    Asset("ANIM", "anim/heat_rock.zip") --官方热能石动画模板
}), { "heatrocklight" }))

--------------------
--------------------

return unpack(prefs)
