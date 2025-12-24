

local _G = GLOBAL
-- local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

--------------------------------------------------------------------------
--[[ 可制作科技 ]]
--------------------------------------------------------------------------

--[[ 常见制作分类有：
    --官方的
    CHARACTER 角色专属
    TOOLS 工具
    LIGHT 光源、火
    PROTOTYPERS 科技台
    REFINE 精炼、加工
    WEAPONS 武器、战斗
    ARMOUR 护甲、防御
    CLOTHING 衣物、帽子(没有战斗功能、有精神恢复相关的装备可以分类到这里)
    RESTORATION 治疗
    COOKING 烹饪、厨具
    GARDENING 耕种、农具
    FISHING 捕渔、渔具
    SEAFARING 航行、船坞
    CONTAINERS 储物、容器(背包之类的也是容器哟)
    STRUCTURES 建筑
    MAGIC 魔法、暗影(主要是指关于暗影的魔法，和暗影无关或者与月亮有关的魔法就不要分类到这里了)
    RIDING 骑乘、驯化
    WINTER 冬季物品、御寒
    SUMMER 夏季物品、避暑、沙漠物品
    RAIN 天气物品、雨具
    DECOR 装饰建筑、装饰道具(没有太实际的功能，单纯好看，可以归类到这里)
    CRAFTING_STATION 一般，不可解锁只能制作的科技都会分到这里

    --棱镜专属
    RECAST 重铸青光
    SIVING 生命子圭
    LEGION 棱镜里
]]--

local function PlacerTest_carpet(pt, rot, tests) --地毯涉及区域得全是地面，不能悬在海上
    if tests == nil then tests = { -1.5, 1.5 } end

    for _, k1 in ipairs(tests) do
        for _, k2 in ipairs(tests) do
            if not TheWorld.Map:IsAboveGroundAtPoint(pt.x+k1, 0, pt.z+k2) then
                return false
            end
        end
    end
	return true
end
local function PlacerTest_carpet2(pt, rot)
	return PlacerTest_carpet(pt, rot, { -3.1, 0, 3.1 })
end

local function Test_pondbldg(pt, key)
    local x, y, z = pt:Get()
    if not TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then --必须得在地面上
        return false
    end
    local x2, y2, z2, rad, dist
    local ents = TheSim:FindEntities(x, 0, z, 7.5, { key }, { "INLIMBO", "NOCLICK" })
    for _, ent in ipairs(ents) do
        if ent.entity:IsVisible() and ent._dd_rad ~= nil then
            rad = ent._dd_rad[key]
            if rad ~= nil then
                x2, y2, z2 = ent.Transform:GetWorldPosition()
                dist = distsq(x, z, x2, z2)
                if dist >= rad[3] and dist <= rad[4] then --最终位置得在池塘周围
                    return true
                end
            end
        end
    end
    return false
end

local tech_recast
local lock_recast
if _G.CONFIGS_LEGION.TECHUNLOCK == "lootdropper" then
    tech_recast = { TECH.LOST, TECH.LOST }
    lock_recast = nil
else
    tech_recast = { TECH.ELECOURMALINE_ONE, TECH.ELECOURMALINE_THREE }
    lock_recast = true
end

------

AddRecipe2( --苔衣发卡
    "hat_lichen", {
        Ingredient("lightbulb", 6),
        Ingredient("cutlichen", 4)
    }, TECH.NONE, {
        atlas = "images/inventoryimages/hat_lichen.xml"
    }, { "LEGION", "CLOTHING", "LIGHT" }
)
AddRecipe2( --香包
    "sachet", {
        Ingredient("petals_rose", 3, "images/inventoryimages/petals_rose.xml"),
        Ingredient("petals_lily", 3, "images/inventoryimages/petals_lily.xml"),
        Ingredient("petals_orchid", 3, "images/inventoryimages/petals_orchid.xml")
    }, TECH.NONE, {
        atlas = "images/inventoryimages/sachet.xml"
    }, { "LEGION", "CLOTHING" }
)
AddRecipe2( --脱壳之翅
    "boltwingout", {
        Ingredient("ahandfulofwings", 40, "images/inventoryimages/ahandfulofwings.xml"),
        Ingredient("glommerwings", 1),
        Ingredient("stinger", 40)
    }, TECH.SCIENCE_TWO, {
        atlas = "images/inventoryimages/boltwingout.xml"
    }, { "LEGION", "ARMOUR", "CONTAINERS" }
)
AddRecipe2( --永不凋零
    "neverfade", {
        Ingredient("rosorns", 1, "images/inventoryimages/rosorns.xml"),
        Ingredient("lileaves", 1, "images/inventoryimages/lileaves.xml"),
        Ingredient("orchitwigs", 1, "images/inventoryimages/orchitwigs.xml")
    }, TECH.MAGIC_THREE, {
        atlas = "images/inventoryimages/neverfade.xml",
        -- image = nil, --默认为 (product参数 或 制作物名)..".tex"
        -- builder_tag = "masterchef", --拥有该标签的玩家才可制作，否则就完全不显示出来
        -- numtogive = 2, --一次制作得到物品数量
        -- nounlock = true, --该配方制作了不会永久解锁。不写就是制作一次就可以永久解锁了
        -- no_deconstruction = true, --该配方无法被魔法拆解
        -- station_tag = "shadow_forge", --科技站需要带有该标签，才能制作该道具
        -- product = "chum", --制作物会被替换为该参数所指对象
        -- description = "transmute_log", --制作栏描述会被该参数替换

        -- placer = "carpet_whitewood_big_placer", --如果是建筑摆放类的，需要指定 placer
        -- min_spacing = 1.5, --摆放限制距离。也就是 1.5半径内不能有其他对象。默认为3.2
        -- testfn = function(pt, rot) end, --额外的摆放限制函数
        -- build_distance = 2.5, --摆放半径。玩家离摆放位置的距离不大于该参数时就可以摆放了。默认为1
    }, { "LEGION", "WEAPONS" }
)
AddRecipe2( --木盾
    "shield_l_log", {
        Ingredient("boards", 2),
        Ingredient("rope", 2)
    }, TECH.SCIENCE_ONE, {
        atlas = "images/inventoryimages/shield_l_log.xml"
    }, { "LEGION", "WEAPONS", "ARMOUR" }
)
AddRecipe2( --砂之抵御
    "shield_l_sand", {
        Ingredient("townportaltalisman", 6),
        Ingredient("shield_l_log", 1, "images/inventoryimages/shield_l_log.xml"),
        Ingredient("turf_desertdirt", 3)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/shield_l_sand.xml"
    }, { "LEGION", "WEAPONS", "ARMOUR", "SUMMER" }
)
AddRecipe2( --多变的云
    "book_weather", {
        Ingredient("papyrus", 8),
        Ingredient("squamousfruit", 3, "images/inventoryimages/squamousfruit.xml"),
        Ingredient("raindonate", 3, "images/inventoryimages/raindonate.xml")
    }, TECH.MAGIC_THREE, {
        atlas = "images/inventoryimages/book_weather.xml"
    }, { "LEGION", "MAGIC", "WEAPONS", "RAIN" }
)
AddRecipe2( --鱼之息
    "hat_mermbreathing", {
        Ingredient("merm_scales", 3, "images/inventoryimages/merm_scales.xml")
    }, TECH.SCIENCE_TWO, {
        atlas = "images/inventoryimages/hat_mermbreathing.xml"
    }, { "LEGION", "CLOTHING" }
)
AddRecipe2( --巨人之脚
    "giantsfoot", {
        Ingredient("merm_scales", 3, "images/inventoryimages/merm_scales.xml"),
        Ingredient("pigskin", 3),
        Ingredient("manrabbit_tail", 3)
    }, TECH.SCIENCE_TWO, {
        atlas = "images/inventoryimages/giantsfoot.xml"
    }, { "LEGION", "CLOTHING", "CONTAINERS" }
)
AddRecipe2( --白木吉他
    "guitar_whitewood", {
        Ingredient("shyerrylog", 1, "images/inventoryimages/shyerrylog.xml"),
        Ingredient("steelwool", 1)
    }, TECH.SCIENCE_ONE, {
        atlas = "images/inventoryimages/guitar_whitewood.xml"
    }, { "LEGION", "GARDENING", "TOOLS" }
)
AddRecipe2( --简易打窝饵制作器
    "fishhomingtool_normal", {
        Ingredient("cutreeds", 1),
        Ingredient("stinger", 1)
    }, TECH.FISHING_ONE, {
        atlas = "images/inventoryimages/fishhomingtool_normal.xml"
    }, { "LEGION", "FISHING" }
)
AddRecipe2( --月炆宝炊套件
    "simmeredmoonlight_item", {
        Ingredient("redmooneye", 1),
        Ingredient("moonrocknugget", 2),
        Ingredient("charcoal", 1)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/simmeredmoonlight_item.xml"
    }, { "LEGION", "STRUCTURES", "CONTAINERS", "COOKING" }
)
AddRecipe2( --月藏宝匣套件
    "hiddenmoonlight_item", {
        Ingredient("bluemooneye", 1),
        Ingredient("moonrocknugget", 2),
        Ingredient("slurtle_shellpieces", 1)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/hiddenmoonlight_item.xml"
    }, { "LEGION", "STRUCTURES", "CONTAINERS", "COOKING" }
)
AddRecipe2( --月轮宝盘套件
    "revolvedmoonlight_item", {
        Ingredient("yellowmooneye", 1),
        Ingredient("moonrocknugget", 2),
        Ingredient("houndstooth", 1)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/revolvedmoonlight_item.xml"
    }, { "LEGION", "LIGHT", "CONTAINERS", "WINTER" }
)
AddRecipe2( --月石角撑
    "chestupgrader_l", {
        Ingredient("moonglass", 3),
        Ingredient("gnarwail_horn", 5),
        Ingredient("tourmalineshard", 3, "images/inventoryimages/tourmalineshard.xml")
    }, TECH.CELESTIAL_ONE, {
        nounlock = true, no_deconstruction = true,
        atlas = "images/inventoryimages/chestupgrader_l.xml"
    }, { "LEGION", "CRAFTING_STATION" }
)
AddRecipe2( --稀有基质培植盆
    "pot_whitewood", {
        Ingredient("shyerrylog", 2, "images/inventoryimages/shyerrylog.xml"),
        Ingredient("dish_shyerryjam", 2, "images/inventoryimages/dish_shyerryjam.xml"),
        Ingredient("turf_mud", 1), --泥泞地皮
        Ingredient("turf_fungus_moon", 1) --变异真菌地皮
    }, TECH.SCIENCE_TWO, {
        placer = "pot_whitewood_placer", min_spacing = 1,
        atlas = "images/inventoryimages/pot_whitewood.xml"
    }, { "LEGION", "GARDENING", "STRUCTURES" }
)
AddRecipe2( --白木展示台
    "chest_whitewood", {
        Ingredient("shyerrylog", 2, "images/inventoryimages/shyerrylog.xml"),
        Ingredient("flint", 2),
        Ingredient("charcoal", 2)
    }, TECH.SCIENCE_ONE, {
        atlas = "images/inventoryimages/chest_whitewood.xml",
        placer = "chest_whitewood_placer", min_spacing = 1
    }, { "LEGION", "CONTAINERS", "STRUCTURES" }
)
AddRecipe2( --白木展示柜
    "chest_whitewood_big", {
        Ingredient("shyerrylog", 6, "images/inventoryimages/shyerrylog.xml"),
        Ingredient("flint", 6),
        Ingredient("charcoal", 6)
    }, TECH.SCIENCE_TWO, {
        atlas = "images/inventoryimages/chest_whitewood_big.xml",
        placer = "chest_whitewood_big_placer", min_spacing = 1
    }, { "LEGION", "CONTAINERS", "STRUCTURES" }
)
AddRecipe2( --澡花壳
    "pondbldg_soak", {
        Ingredient("tacklecontainer", 1),
        Ingredient("dug_trap_starfish", 1),
        Ingredient("cactus_flower", 6)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/pondbldg_soak.xml",
        placer = "pondbldg_soak_placer", min_spacing = 0,
        testfn = function(pt, rot) return Test_pondbldg(pt, "pondbldg_soak") end
    }, { "LEGION", "RESTORATION" }
)
AddRecipe2( --鱼栖壳
    "pondbldg_fish", {
        Ingredient("tacklecontainer", 1),
        Ingredient("seeds_berries_l", 1, "images/inventoryimages/xeeds_berries.xml", nil, "xeeds_berries.tex"),
        Ingredient("fishhomingbait", 3, "images/inventoryimages/fishhomingbait1.xml", nil, "fishhomingbait1.tex")
    }, TECH.LOST, {
        atlas = "images/inventoryimages/pondbldg_fish.xml",
        placer = "pondbldg_fish_placer", min_spacing = 0, build_distance = 3,
        testfn = function(pt, rot) return Test_pondbldg(pt, "pondbldg_fish") end
    }, { "LEGION", "FISHING" }
)
AddRecipe2( --防火漆
    "ointment_l_fireproof", {
        Ingredient("firenettles", 5),
        Ingredient("lavae_egg", 1),
        Ingredient("slurtleslime", 5)
    }, TECH.SCIENCE_TWO, {
        numtogive = 12, no_deconstruction = true,
        atlas = "images/inventoryimages/ointment_l_fireproof.xml"
    }, { "LEGION", "SUMMER" }
)

------生命子圭

AddRecipe2( --弱肤药膏
    "ointment_l_sivbloodreduce", {
        Ingredient("succulent_picked", 1),
        Ingredient("green_cap", 3),
        Ingredient("spoiled_fish_small", 1),
        Ingredient("rock_avocado_fruit", 3, nil, nil, "rock_avocado_fruit_rockhard.tex") --石果的贴图和名字不一样
    }, TECH.SCIENCE_TWO, {
        numtogive = 4,
        atlas = "images/inventoryimages/ointment_l_sivbloodreduce.xml"
    }, { "LEGION", "SIVING", "RESTORATION" }
)
AddRecipe2( --云松子
    "boxopener_l", {
        Ingredient("foliageath", 1, "images/inventoryimages/foliageath.xml"),
        Ingredient("waterplant_planter", 1),
        Ingredient("cutted_lumpyevergreen", 5, "images/inventoryimages/cutted_lumpyevergreen.xml")
    }, TECH.MAGIC_THREE, {
        atlas = "images/inventoryimages/boxopener_l.xml"
    }, { "LEGION", "SIVING", "CONTAINERS" }
)
AddRecipe2( --子圭·系
    "siving_boxopener", {
        Ingredient("boxopener_l", 1, "images/inventoryimages/boxopener_l.xml"),
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("foliageath", 1, "images/inventoryimages/foliageath.xml"),
        Ingredient("rock_avocado_fruit_sprout", 1)
    }, TECH.SIVING_ONE, {
        atlas = "images/inventoryimages/siving_boxopener.xml"
    }, { "LEGION", "SIVING", "CONTAINERS" }
)
AddRecipe2( --子圭·育
    "siving_turn", {
        Ingredient("siving_rocks", 40, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("seeds", 40),
    }, TECH.SIVING_ONE, {
        placer = "siving_turn_placer", min_spacing = 1,
        atlas = "images/inventoryimages/siving_turn.xml"
    }, { "LEGION", "SIVING", "GARDENING", "STRUCTURES" }
)
AddRecipe2( --子圭·垄
    "siving_soil_item", {
        Ingredient("siving_rocks", 6, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("pinecone", 10)
    }, TECH.SIVING_ONE, {
        atlas = "images/inventoryimages/siving_soil_item.xml"
    }, { "LEGION", "SIVING", "GARDENING" }
)
AddRecipe2( --子圭·利川
    "siving_ctlwater_item", {
        Ingredient("siving_rocks", 20, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("greengem", 1),
        Ingredient("moonglass", 10)
    }, TECH.SIVING_ONE, {
        atlas = "images/inventoryimages/siving_ctlwater_item.xml"
    }, { "LEGION", "SIVING", "GARDENING", "STRUCTURES" }
)
AddRecipe2( --子圭·益矩
    "siving_ctldirt_item", {
        Ingredient("siving_rocks", 20, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("greengem", 1),
        Ingredient("townportaltalisman", 10)
    }, TECH.SIVING_ONE, {
        atlas = "images/inventoryimages/siving_ctldirt_item.xml"
    }, { "LEGION", "SIVING", "GARDENING", "STRUCTURES" }
)
AddRecipe2( --子圭·崇溟
    "siving_ctlall_item", {
        Ingredient("siving_ctlwater_item", 1, "images/inventoryimages/siving_ctlwater_item.xml"),
        Ingredient("siving_ctldirt_item", 1, "images/inventoryimages/siving_ctldirt_item.xml"),
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("singingshell_octave4", 1, nil, nil, "singingshell_octave4_1.tex")
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/siving_ctlall_item.xml"
    }, { "LEGION", "SIVING", "RECAST", "GARDENING", "STRUCTURES" }
)
AddRecipe2( --子圭·汲
    "siving_mask", {
        Ingredient("siving_rocks", 12, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("reviver", 2)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/siving_mask.xml"
    }, { "LEGION", "SIVING", "ARMOUR", "RESTORATION" }
)
AddRecipe2( --子圭·庇
    "siving_suit", {
        Ingredient("siving_rocks", 16, "images/inventoryimages/siving_rocks.xml"),
        Ingredient("yellowgem", 1)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/siving_suit.xml"
    }, { "LEGION", "SIVING", "ARMOUR" }
)
AddRecipe2( --子圭·翰
    "siving_feather_real", {
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("siving_feather_fake", 6, "images/inventoryimages/siving_feather_fake.xml"),
        Ingredient(CHARACTER_INGREDIENT.HEALTH, 30)
    }, TECH.LOST, {
        atlas = "images/inventoryimages/siving_feather_real.xml"
    }, { "LEGION", "SIVING", "WEAPONS" }
)
AddRecipe2( --子圭·歃
    "siving_mask_gold", {
        Ingredient("goggleshat", 1),
        Ingredient("siving_mask", 1, "images/inventoryimages/siving_mask.xml"),
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("dish_shyerryjam", 1, "images/inventoryimages/dish_shyerryjam.xml")
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/siving_mask_gold.xml"
    }, { "LEGION", "SIVING", "RECAST", "ARMOUR", "RESTORATION" }
)
AddRecipe2( --子圭·釜
    "siving_suit_gold", {
        Ingredient("onemanband", 1),
        Ingredient("siving_suit", 1, "images/inventoryimages/siving_suit.xml"),
        Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
        Ingredient("bundlewrap", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/siving_suit_gold.xml"
    }, { "LEGION", "SIVING", "RECAST", "ARMOUR", "CONTAINERS" }
)

------重铸青光

AddRecipe2( --斧铲-三用型
    "tripleshovelaxe", {
        Ingredient("axe", 1),
        Ingredient("pickaxe", 1),
        Ingredient("shovel", 1)
    }, tech_recast[1], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/tripleshovelaxe.xml"
    }, { "LEGION", "RECAST", "TOOLS" }
)
AddRecipe2( --扳手-双用型
    "dualwrench", {
        Ingredient("hammer", 1),
        Ingredient("goldnugget", 1),
        Ingredient("pitchfork", 1)
    }, tech_recast[1], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/dualwrench.xml"
    }, { "LEGION", "RECAST", "TOOLS" }
)
AddRecipe2( --鸳鸯石
    "icire_rock", {
        Ingredient("amulet", 1),
        Ingredient("heatrock", 2),
        Ingredient("blueamulet", 1)
    }, tech_recast[1], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/icire_rock.xml"
    }, { "LEGION", "RECAST", "WINTER", "SUMMER" }
)
AddRecipe2( --爆炸水果蛋糕
    "explodingfruitcake", {
        Ingredient("winter_food4", 1),
        Ingredient("gunpowder", 2)
    }, tech_recast[1], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/explodingfruitcake.xml"
    }, { "LEGION", "RECAST", "WEAPONS" }
)
AddRecipe2( --专业打窝饵制作器
    "fishhomingtool_awesome", {
        Ingredient("fishhomingtool_normal", 5, "images/inventoryimages/fishhomingtool_normal.xml"),
        Ingredient("chum", 2)
    }, tech_recast[1], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/fishhomingtool_awesome.xml"
    }, { "LEGION", "RECAST", "FISHING" }
)

AddRecipe2( --电气石
    "tourmalinecore", {
        Ingredient("redgem", 10),
        Ingredient("tourmalineshard", 10, "images/inventoryimages/tourmalineshard.xml"),
        Ingredient("moonstorm_spark", 10)
    }, tech_recast[2], {
        nounlock = lock_recast, no_deconstruction = true,
        atlas = "images/inventoryimages/tourmalinecore.xml"
    }, { "LEGION", "RECAST" }
)
AddRecipe2( --斧铲-黄金三用型
    "triplegoldenshovelaxe", {
        Ingredient("goldenaxe", 2),
        Ingredient("goldenpickaxe", 2),
        Ingredient("goldenshovel", 2)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/triplegoldenshovelaxe.xml"
    }, { "LEGION", "RECAST", "TOOLS" }
)
AddRecipe2( --牛仔帽
    "hat_cowboy", {
        Ingredient("beefalohat", 1),
        Ingredient("brush", 1),
        Ingredient("rainhat", 1),
        Ingredient("tophat", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/hat_cowboy.xml"
    }, { "LEGION", "RECAST", "RAIN", "SUMMER", "RIDING", "CLOTHING" }
)
AddRecipe2( --素白蘑菇帽
    "hat_albicans_mushroom", {
        Ingredient("red_mushroomhat", 1),
        Ingredient("green_mushroomhat", 1),
        Ingredient("blue_mushroomhat", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/hat_albicans_mushroom.xml"
    }, { "LEGION", "RECAST", "CLOTHING", "SUMMER", "GARDENING", "RAIN" }
)
AddRecipe2( --犀金胄甲
    "hat_elepheetle", {
        Ingredient("cookiecutterhat", 1),
        Ingredient("insectshell_l", 35, "images/inventoryimages/insectshell_l.xml"),
        Ingredient("goldnugget", 15),
        Ingredient("slurtlehat", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/hat_elepheetle.xml"
    }, { "LEGION", "RECAST", "ARMOUR" }
)
AddRecipe2( --犀金护甲
    "armor_elepheetle", {
        Ingredient("armormarble", 1),
        Ingredient("insectshell_l", 45, "images/inventoryimages/insectshell_l.xml"),
        Ingredient("goldnugget", 20),
        Ingredient("armorsnurtleshell", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/armor_elepheetle.xml"
    }, { "LEGION", "RECAST", "ARMOUR" }
)
AddRecipe2( --米格尔的吉他
    "guitar_miguel", {
        Ingredient("panflute", 1),
        Ingredient("onemanband", 1)
    }, tech_recast[2], {
        nounlock = lock_recast,
        atlas = "images/inventoryimages/guitar_miguel.xml"
    }, { "LEGION", "RECAST", "GARDENING", "RESTORATION", "TOOLS" }
)

AddRecipe2( --蛛网标记
    "web_hump_item", {
        Ingredient("monstermeat_dried", 12),
        Ingredient("minisign_item", 2),
        Ingredient("silk", 12)
    }, tech_recast[2], {
        nounlock = lock_recast, builder_tag = lock_recast and "spiderwhisperer" or nil,
        atlas = "images/inventoryimages/web_hump_item.xml"
    }, { "LEGION", "RECAST", "STRUCTURES", "CHARACTER" }
)
AddRecipe2( --灵魂契约
    "soul_contracts", {
        Ingredient("wortox_soul", 20),
        Ingredient("mapscroll", 5),
        Ingredient("reviver", 2),
        Ingredient("nightmarefuel", 20)
    }, tech_recast[2], {
        nounlock = lock_recast, builder_tag = lock_recast and "soulstealer" or nil,
        atlas = "images/inventoryimages/soul_contracts.xml"
    }, { "LEGION", "RECAST", "RESTORATION", "MAGIC", "CHARACTER" }
)

------模组联动

if _G.CONFIGS_LEGION.ENABLEDMODS.GENESIS then
    AddRecipe2( --夜玫瑰棘果
        "cutted_nightrosebush", {
            Ingredient("cutted_rosebush", 3, "images/inventoryimages/cutted_rosebush.xml"),
            Ingredient("genesis_flower_rose", 6, "images/inventoryimages/genesis_flower_rose.xml", nil, "genesis_flower_rose.tex"),
            Ingredient("genesis_dark_crystal", 3, "images/inventoryimages/genesis_crystal.xml", nil, "genesis_dark_crystal.tex")
        }, TECH.ANCIENT_FOUR, {
            nounlock = true,
            atlas = "images/inventoryimages/cutted_nightrosebush.xml"
        }, { "LEGION", "CRAFTING_STATION" }
    )
end

-- tech_recast = nil
-- lock_recast = nil

------装饰类

AddRecipe2( --白木地垫
    "carpet_whitewood", {
        Ingredient("shyerrylog", 1, "images/inventoryimages/shyerrylog.xml")
    }, TECH.NONE, {
        placer = "carpet_whitewood_placer", min_spacing = 0,
        atlas = "images/inventoryimages/carpet_whitewood.xml",
        testfn = PlacerTest_carpet
    }, { "LEGION", "DECOR" }
)
AddRecipe2( --白木地毯
    "carpet_whitewood_big", {
        Ingredient("shyerrylog", 4, "images/inventoryimages/shyerrylog.xml")
    }, TECH.SCIENCE_ONE, {
        placer = "carpet_whitewood_big_placer", min_spacing = 0,
        atlas = "images/inventoryimages/carpet_whitewood_big.xml",
        testfn = PlacerTest_carpet2
    }, { "LEGION", "DECOR" }
)
AddRecipe2( --线绒地垫
    "carpet_plush", {
        Ingredient("cattenball", 1, "images/inventoryimages/cattenball.xml"),
        Ingredient("beefalowool", 1),
        Ingredient("beardhair", 1)
    }, TECH.NONE, {
        placer = "carpet_plush_placer", min_spacing = 0,
        atlas = "images/inventoryimages/carpet_plush.xml",
        testfn = PlacerTest_carpet
    }, { "LEGION", "DECOR" }
)
AddRecipe2( --线绒地毯
    "carpet_plush_big", {
        Ingredient("cattenball", 2, "images/inventoryimages/cattenball.xml"),
        Ingredient("beefalowool", 4),
        Ingredient("beardhair", 2)
    }, TECH.SCIENCE_ONE, {
        placer = "carpet_plush_big_placer", min_spacing = 0,
        atlas = "images/inventoryimages/carpet_plush_big.xml",
        testfn = PlacerTest_carpet2
    }, { "LEGION", "DECOR" }
)
AddRecipe2( --白木地片
    "mat_whitewood_item", {
        Ingredient("shyerrylog", 1, "images/inventoryimages/shyerrylog.xml")
    }, TECH.NONE, {
        numtogive = 6,
        atlas = "images/inventoryimages/mat_whitewood_item.xml", image = "mat_whitewood_item.tex"
    }, { "LEGION", "DECOR" }
)
AddRecipe2( --细微之触
    "shadowbrush_l", {
        Ingredient("thulecite", 1),
        Ingredient("nightmarefuel", 3),
        Ingredient("beardhair", 15)
    }, TECH.ANCIENT_FOUR, {
        nounlock = true,
        atlas = "images/inventoryimages/shadowbrush_l.xml"
    }, { "LEGION", "DECOR", "CRAFTING_STATION" }
)
AddRecipe2( --碎石块
    "pebbleitem_l_nitre", {
        Ingredient("nitre", 1)
    }, TECH.NONE, {
        numtogive = 6,
        atlas = "images/inventoryimages/pebbleitem_l_nitre.xml"
    }, { "LEGION", "DECOR" }
)

if _G.CONFIGS_LEGION.DRESSUP then
    AddRecipe2( --幻象法杖
        "pinkstaff", {
            Ingredient("glommerwings", 1),
            Ingredient("livinglog", 1),
            Ingredient("glommerfuel", 1)
        }, TECH.MAGIC_TWO, {
            atlas = "images/inventoryimages/pinkstaff.xml"
        }, { "LEGION", "MAGIC", "DECOR" }
    )
    AddRecipe2( --皇帝的王冠
        "theemperorscrown", {
            Ingredient("nightmarefuel", 1),
            Ingredient("rocks", 1)
        }, TECH.NONE, {
            atlas = "images/inventoryimages/theemperorscrown.xml"
        }, { "LEGION", "CLOTHING", "DECOR" }
    )
    AddRecipe2( --皇帝的披风
        "theemperorsmantle", {
            Ingredient("nightmarefuel", 1),
            Ingredient("cutgrass", 1)
        }, TECH.NONE, {
            atlas = "images/inventoryimages/theemperorsmantle.xml"
        }, { "LEGION", "CLOTHING", "DECOR" }
    )
    AddRecipe2( --皇帝的权杖
        "theemperorsscepter", {
            Ingredient("nightmarefuel", 1),
            Ingredient("twigs", 1)
        }, TECH.NONE, {
            atlas = "images/inventoryimages/theemperorsscepter.xml"
        }, { "LEGION", "CLOTHING", "DECOR" }
    )
    AddRecipe2( --皇帝的吊坠
        "theemperorspendant", {
            Ingredient("nightmarefuel", 1),
            Ingredient("flint", 1)
        }, TECH.NONE, {
            atlas = "images/inventoryimages/theemperorspendant.xml"
        }, { "LEGION", "CLOTHING", "DECOR" }
    )
end

------npc交易类，不归类到棱镜栏中

AddRecipe2( --澡花壳的蓝图
    "wanderingtradershop_pondbldg_soak", {
        Ingredient("bean_l_ice", 4, "images/inventoryimages/bean_l_ice.xml")
    }, TECH.LOST, {
        image = "blueprint_rare.tex",
        limitedamount = true, nounlock = true, actionstr = "WANDERINGTRADERSHOP", sg_state = "give",
        product = "pondbldg_soak_blueprint", description = "npc_beef_pondbldg_soak"
    }, { "CRAFTING_STATION" }
)
AddRecipe2( --鱼栖壳的蓝图
    "wanderingtradershop_pondbldg_fish", {
        Ingredient("fishmeat", 4)
    }, TECH.LOST, {
        image = "blueprint_rare.tex",
        limitedamount = true, nounlock = true, actionstr = "WANDERINGTRADERSHOP", sg_state = "give",
        product = "pondbldg_fish_blueprint", description = "npc_beef_pondbldg_fish"
    }, { "CRAFTING_STATION" }
)
AddRecipe2( --猫线球
    "wanderingtradershop_cattenball", {
        Ingredient("beefalowool", 3)
    }, TECH.LOST, {
        image = "cattenball.tex", atlas = "images/inventoryimages/cattenball.xml",
        limitedamount = true, nounlock = true, actionstr = "WANDERINGTRADERSHOP", sg_state = "give",
        product = "cattenball", description = "npc_beef_cattenball"
    }, { "CRAFTING_STATION" }
)
AddRecipe2( --带电的晶石
    "wanderingtradershop_tourmalineshard", {
        Ingredient("pigskin", 1)
    }, TECH.LOST, {
        image = "tourmalineshard.tex", atlas = "images/inventoryimages/tourmalineshard.xml",
        limitedamount = true, nounlock = true, actionstr = "WANDERINGTRADERSHOP", sg_state = "give",
        product = "tourmalineshard", description = "npc_beef_tourmalineshard"
    }, { "CRAFTING_STATION" }
)

------分解配方：用来便于绿宝石法杖分解

AddDeconstructRecipe("web_hump", {
    Ingredient("monstermeat_dried", 12),
    Ingredient("minisign_item", 2),
    Ingredient("silk", 12)
})
AddDeconstructRecipe("siving_soil", {
    Ingredient("siving_rocks", 6, "images/inventoryimages/siving_rocks.xml"),
    Ingredient("pinecone", 10)
})
AddDeconstructRecipe("siving_ctlwater", {
    Ingredient("siving_rocks", 20, "images/inventoryimages/siving_rocks.xml"),
    Ingredient("greengem", 1),
    Ingredient("moonglass", 10)
})
AddDeconstructRecipe("siving_ctldirt", {
    Ingredient("siving_rocks", 20, "images/inventoryimages/siving_rocks.xml"),
    Ingredient("greengem", 1),
    Ingredient("townportaltalisman", 10)
})
AddDeconstructRecipe("siving_ctlall", {
    Ingredient("siving_ctlwater_item", 1, "images/inventoryimages/siving_ctlwater_item.xml"),
    Ingredient("siving_ctldirt_item", 1, "images/inventoryimages/siving_ctldirt_item.xml"),
    Ingredient("siving_derivant_item", 1, "images/inventoryimages/siving_derivant_item.xml"),
    Ingredient("singingshell_octave4", 1, nil, nil, "singingshell_octave4_1.tex")
})
