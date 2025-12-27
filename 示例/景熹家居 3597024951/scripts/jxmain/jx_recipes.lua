AddRecipeFilter({name = "JXTAB", atlas = "images/jx_tab.xml", image = "jx_tab.tex"}, 23)

-- 巴西木盆栽
AddRecipe2("jx_potted",
    {
        Ingredient("petals", 1),
        Ingredient("log", 2),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted.xml",
        image = "jx_potted.tex",
        placer = "jx_potted_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 竹篮向日葵盆栽
AddRecipe2("jx_potted_sunflower",
    {
        Ingredient("petals", 3),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_sunflower.xml",
        image = "jx_potted_sunflower.tex",
        placer = "jx_potted_sunflower_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 樱花酢浆草盆栽
AddRecipe2("jx_potted_cherry",
    {
        Ingredient("petals", 2),
        Ingredient("log", 1),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_cherry.xml",
        image = "jx_potted_cherry.tex",
        placer = "jx_potted_cherry_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 纯真花语盆栽
AddRecipe2("jx_potted_rose",
    {
        Ingredient("petals", 2),
        Ingredient("twigs", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_rose.xml",
        image = "jx_potted_rose.tex",
        placer = "jx_potted_rose_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 经典仙人球盆栽
AddRecipe2("jx_potted_cactus",
    {
        Ingredient("cactus_meat", 1),
        Ingredient("petals", 1),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_cactus.xml",
        image = "jx_potted_cactus.tex",
        placer = "jx_potted_cactus_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 哥伦比亚红掌盆栽
AddRecipe2("jx_potted_anthurium",
    {
        Ingredient("petals", 4),
        Ingredient("cutstone", 1),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_anthurium.xml",
        image = "jx_potted_anthurium.tex",
        placer = "jx_potted_anthurium_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 欧式虎皮兰盆栽
AddRecipe2("jx_potted_snakeplant",
    {
        Ingredient("petals", 6),
        Ingredient("twigs", 1),
        Ingredient("cutstone", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_snakeplant.xml",
        image = "jx_potted_snakeplant.tex",
        placer = "jx_potted_snakeplant_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 威尔士水仙花盆栽
AddRecipe2("jx_potted_narcissus",
    {
        Ingredient("petals", 4),
        Ingredient("twigs", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_narcissus.xml",
        image = "jx_potted_narcissus.tex",
        placer = "jx_potted_narcissus_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 栀子花盆栽
AddRecipe2("jx_potted_gardenia",
    {
        Ingredient("petals", 4),
        Ingredient("twigs", 1),
        Ingredient("cutgrass", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_gardenia.xml",
        image = "jx_potted_gardenia.tex",
        placer = "jx_potted_gardenia_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 传统龟背竹盆栽
AddRecipe2("jx_potted_monstera",
    {
        Ingredient("petals", 3),
        Ingredient("twigs", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_potted_monstera.xml",
        image = "jx_potted_monstera.tex",
        placer = "jx_potted_monstera_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 豆瓣绿盆栽
AddRecipe2("jx_green_palm",
    {
        Ingredient("petals", 3),
        Ingredient("twigs", 1),
        Ingredient("cutgrass", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_green_palm.xml",
        image = "jx_green_palm.tex",
        placer = "jx_green_palm_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 香格里拉玫瑰盆栽
AddRecipe2("jx_red_rose_potted",
    {
        Ingredient("petals", 4),
        Ingredient("twigs", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_red_rose_potted.xml",
        image = "jx_red_rose_potted.tex",
        placer = "jx_red_rose_potted_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 橘猫
AddRecipe2("jx_xuncat",
    {
        Ingredient("coontail", 1),
        Ingredient("papyrus", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_xuncat.xml",
        image = "jx_xuncat.tex",
        placer = "jx_xuncat_placer",
        min_spacing = 0.9
    },
    {"JXTAB"}
)

-- 手工编织菜篮
AddRecipe2("jx_basket",
    {
        Ingredient("silk", 4),
        Ingredient("boards", 2),
        Ingredient("rope", 8),
        Ingredient("petals", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_basket.xml",
        image = "jx_basket.tex",
    },
    {"JXTAB"}
)

-- 向日葵草帽
AddRecipe2("jx_hat_sunflower",
    {
        Ingredient("rope", 6),
        Ingredient("petals", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_hat_sunflower.xml",
        image = "jx_hat_sunflower.tex",
    },
    {"JXTAB"}
)

-- 白玫瑰蕾丝礼帽
AddRecipe2("jx_hat_white_rose",
    {
        Ingredient("petals", 1),
        Ingredient("rope", 2),
        Ingredient("silk", 1),
        Ingredient("pigskin", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_hat_white_rose.xml",
        image = "jx_hat_white_rose.tex",
    },
    {"JXTAB"}
)

-- 洛丽塔敏敏熊便当包
AddRecipe2("jx_pack",
    {
        Ingredient("silk", 6),
        Ingredient("beefalowool", 3),
        Ingredient("bearger_fur", 1),
        Ingredient("rope", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_pack.xml",
        image = "jx_pack.tex",
    },
    {"JXTAB"}
)

-- 洛丽塔野餐兔背包
AddRecipe2("jx_backpack",
    {
        Ingredient("manrabbit_tail", 3),
        Ingredient("cutgrass", 3),
        Ingredient("twigs", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_backpack.xml",
        image = "jx_backpack.tex",
    },
    {"JXTAB"}
)

-- 波奈特垂耳兔背包
AddRecipe2("jx_backpack_2",
    {
        Ingredient("manrabbit_tail", 3),
        Ingredient("cutgrass", 3),
        Ingredient("twigs", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_backpack_2.xml",
        image = "jx_backpack_2.tex",
    },
    {"JXTAB"}
)

-- 别墅门牌信箱
AddRecipe2("jx_mailbox",
    {
        Ingredient("cutstone", 1),
        Ingredient("petals", 3),
        Ingredient("goldnugget", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_mailbox.xml",
        image = "jx_mailbox.tex",
        placer = "jx_mailbox_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 复古电冰箱
AddRecipe2("jx_icebox",
    {
        Ingredient("goldnugget", 2),
        Ingredient("gears", 1),
        Ingredient("transistor", 1),
        Ingredient("cutstone", 2)
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_icebox.xml",
        image = "jx_icebox.tex",
        placer = "jx_icebox_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 欧罗巴制冰机
AddRecipe2("jx_icemaker",
    {
        Ingredient("transistor", 8),
        Ingredient("waterballoon", 2),
        Ingredient("oceanfish_medium_8_inv", 1),
        Ingredient("deerclops_eyeball", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_icemaker.xml",
        image = "jx_icemaker.tex",
        placer = "jx_icemaker_placer",
        --min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 复古电煮锅
AddRecipe2("jx_cookpot",
    {
        Ingredient("charcoal", 3),
        Ingredient("transistor", 1),
        Ingredient("cutstone", 1)
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_cookpot.xml",
        image = "jx_cookpot.tex",
        placer = "jx_cookpot_placer",
        min_spacing = 2
    },
    {"JXTAB"}
)

-- 青铜镶边烤箱
AddRecipe2("jx_oven",
    {
        Ingredient("marble", 2),
        Ingredient("log", 1),
        Ingredient("transistor", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_oven.xml",
        image = "jx_oven.tex",
        placer = "jx_oven_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 复古烤面包机
AddRecipe2("jx_toaster",
    {
        Ingredient("heatrock", 2),
        Ingredient("cutstone", 2),
        Ingredient("flint", 2),
        Ingredient("bird_egg", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_toaster5.xml",
        image = "jx_toaster5.tex",
    },
    {"JXTAB"}
)

-- 普罗旺斯格纹方桌
AddRecipe2("jx_table_3",
    {
        Ingredient("boards", 4),
        Ingredient("rope", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table_3.xml",
        image = "jx_table_3.tex",
        placer = "jx_table_3_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 普罗旺斯格纹椅子
AddRecipe2("jx_chair_2",
    {
        Ingredient("boards", 1),
        Ingredient("rope", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_chair_2.xml",
        image = "jx_chair_2.tex",
        placer = "jx_chair_2_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 古堡回廊展示桌
AddRecipe2("jx_table_6",
    {
        Ingredient("goldnugget", 3),
        Ingredient("boards", 2),
        Ingredient("pigskin", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table_6.xml",
        image = "jx_table_6.tex",
        placer = "jx_table_6_placer",
        --min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 佛罗伦萨实木餐桌
AddRecipe2("jx_table_2",
    {
        Ingredient("boards", 5),
        Ingredient("petals", 1),
        Ingredient("goldnugget", 3),
        Ingredient("silk", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table_2.xml",
        image = "jx_table_2.tex",
        placer = "jx_table_2_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 佛罗伦萨小皮凳
AddRecipe2("jx_chair_1",
    {
        Ingredient("log", 3),
        Ingredient("rope", 1),
        Ingredient("goldnugget", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_chair_1.xml",
        image = "jx_chair_1.tex",
        placer = "jx_chair_1_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 复古枫叶木盒
AddRecipe2("jx_chest",
    {
        Ingredient("boards", 2),
        Ingredient("goldnugget", 1),
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_chest.xml",
        image = "jx_chest.tex",
        placer = "jx_chest_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 温莎古典无窗餐柜
AddRecipe2("jx_bookcase",
    {
        Ingredient("boards", 6),
        Ingredient("rope", 3),
        Ingredient("redgem", 1),
        Ingredient("goldnugget", 6),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_bookcase.xml",
        image = "jx_bookcase.tex",
        placer = "jx_bookcase_placer",
        --min_spacing = 1
    },
    {"JXTAB"}
)

-- 欧式实木梳妆台
AddRecipe2("jx_table_5",
    {
        Ingredient("redgem", 1),
        Ingredient("boards", 4),
        Ingredient("rope", 2),
        Ingredient("beefalowool", 3),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table_5.xml",
        image = "jx_table_5.tex",
        placer = "jx_table_5_placer",
        -- min_spacing = 1
    },
    {"JXTAB"}
)

-- 巴洛克圆顶床
AddRecipe2("jx_tent",
    {
        Ingredient("silk", 4),
        Ingredient("twigs", 2),
        Ingredient("rope", 3)
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_tent.xml",
        image = "jx_tent.tex",
        placer = "jx_tent_placer",
        -- min_spacing = 1
    },
    {"JXTAB"}
)

-- 巴洛克鎏金浴缸
AddRecipe2("jx_bathtub",
    {
        Ingredient("marble", 3),
        Ingredient("cutstone", 2),
        Ingredient("goldnugget", 8),
        Ingredient("tentaclespots", 3),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_bathtub.xml",
        image = "jx_bathtub.tex",
        placer = "jx_bathtub_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 经典镶边洗衣机
AddRecipe2("jx_washer",
    {
        --Ingredient("yellowgem", 1),
        Ingredient("goldnugget", 8),
        Ingredient("marble", 2),
        Ingredient("transistor", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_washer.xml",
        image = "jx_washer.tex",
        placer = "jx_washer_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 复古电视机
AddRecipe2("jx_tv",
    {
        Ingredient("transistor", 3),
        Ingredient("cutstone", 2),
        Ingredient("boards", 2),
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_tv.xml",
        image = "jx_tv.tex",
        placer = "jx_tv_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 洛可可海缸柜
AddRecipe2("jx_fish_tank",
    {
        Ingredient("goldnugget", 5),
        Ingredient("boards", 6),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_fish_tank.xml",
        image = "jx_fish_tank.tex",
        placer = "jx_fish_tank_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 古典转盘电话机
AddRecipe2("jx_phonograph",
    {
        Ingredient("transistor", 1),
        Ingredient("goldnugget", 1),
        Ingredient("nightmarefuel", 1),
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_phonograph.xml",
        image = "jx_phonograph.tex",
    },
    {"JXTAB"}
)

-- 磁带录音机
AddRecipe2("jx_tapeplayer",
    {
        Ingredient("transistor", 1),
        Ingredient("goldnugget", 1),
        Ingredient("gears", 1),
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_tapeplayer.xml",
        image = "jx_tapeplayer.tex",
    },
    {"JXTAB"}
)

-- 布洛涅蕾丝真皮沙发
AddRecipe2("jx_sofa_1",
    {
        Ingredient("boards", 2),
        Ingredient("pigskin", 1),
        Ingredient("silk", 4),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_sofa_1.xml",
        image = "jx_sofa_1.tex",
        placer = "jx_sofa_1_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)
AddRecipe2("jx_sofa_2",
    {
        Ingredient("boards", 2),
        Ingredient("pigskin", 1),
        Ingredient("silk", 4),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_sofa_2.xml",
        image = "jx_sofa_2.tex",
        placer = "jx_sofa_2_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 布洛涅蕾丝餐桌
AddRecipe2("jx_table",
    {
        Ingredient("boards", 2),
        Ingredient("pigskin", 1),
        Ingredient("rope", 4),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table.xml",
        image = "jx_table.tex",
        placer = "jx_table_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 蔷薇红雕花真皮沙发
AddRecipe2("jx_sofa_3",
    {
        Ingredient("pigskin", 3),
        Ingredient("rope", 2),
        Ingredient("boards", 2),
        Ingredient("silk", 3),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_sofa_3.xml",
        image = "jx_sofa_3.tex",
        placer = "jx_sofa_3_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 蔷薇红真皮摇椅
AddRecipe2("jx_chair_3",
    {
        Ingredient("pigskin", 3),
        Ingredient("boards", 4),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_chair_3.xml",
        image = "jx_chair_3.tex",
        placer = "jx_chair_3_placer",
        --min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 蔷薇红雕花餐桌
AddRecipe2("jx_table_4",
    {
        Ingredient("boards", 4),
        Ingredient("rope", 4),
        Ingredient("silk", 3),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_table_4.xml",
        image = "jx_table_4.tex",
        placer = "jx_table_4_placer",
        min_spacing = 1.5
    },
    {"JXTAB"}
)

-- 复古缀饰床头灯
AddRecipe2("jx_lamp",
    {
        Ingredient("lightbulb", 1),
        Ingredient("twigs", 2),
        Ingredient("transistor", 1),
    },
    TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/jx_lamp.xml",
        image = "jx_lamp.tex",
    },
    {"JXTAB"}
)

-- 宝石玫瑰夜巡灯
AddRecipe2("jx_lantern",
    {
        Ingredient("redgem", 1),
        Ingredient("lightbulb", 2),
        Ingredient("petals", 2),
        Ingredient("goldnugget", 3),
    },
    TECH.SCIENCE_NONE,
    {
        atlas = "images/inventoryimages/jx_lantern.xml",
        image = "jx_lantern.tex",
    },
    {"JXTAB"}
)

-- 哥特式宫廷道路灯
AddRecipe2("jx_mushroom_light",
    {
        Ingredient("boards", 1),
        Ingredient("cutstone", 2),
        Ingredient("transistor", 1),
        Ingredient("lightbulb", 8),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_mushroom_light.xml",
        image = "jx_mushroom_light.tex",
        placer = "jx_mushroom_light_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 蔷薇红实木室内灯
AddRecipe2("jx_mushroom_light_2",
    {
        Ingredient("boards", 2),
        Ingredient("cutstone", 2),
        Ingredient("transistor", 2),
        Ingredient("lightbulb", 8),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_mushroom_light_2.xml",
        image = "jx_mushroom_light_2.tex",
        placer = "jx_mushroom_light_2_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 诺伊堡绿色煤油暖炉
AddRecipe2("jx_furnace",
    {
        Ingredient("charcoal", 8),
        Ingredient("goldnugget", 8),
        Ingredient("rope", 3),
        Ingredient("dragon_scales", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_furnace.xml",
        image = "jx_furnace.tex",
        placer = "jx_furnace_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 复古传统电风扇
AddRecipe2("jx_fan",
    {
        Ingredient("goose_feather", 3),
        Ingredient("transistor", 2),
        Ingredient("gears", 2),
        Ingredient("goldnugget", 8),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_fan.xml",
        image = "jx_fan.tex",
    },
    {"JXTAB"}
)

-- 蔷薇镶边大衣柜
AddRecipe2("jx_wardrobe",
    {
        Ingredient("boards", 6),
        Ingredient("goldnugget", 3),
        Ingredient("cutgrass", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_wardrobe.xml",
        image = "jx_wardrobe.tex",
        placer = "jx_wardrobe_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 红宝石复古缝纫机
AddRecipe2("jx_sewingmachine",
    {
        Ingredient("boards", 2),
        Ingredient("redgem", 1),
        Ingredient("silk", 4),
        Ingredient("houndstooth", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_sewingmachine.xml",
        image = "jx_sewingmachine.tex",
        placer = "jx_sewingmachine_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 宫廷风花茶壶
AddRecipe2("jx_wateringcan",
    {
        Ingredient("marble", 1),
        Ingredient("petals", 1),
        Ingredient("rope", 1),
        Ingredient("flint", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_wateringcan.xml",
        image = "jx_wateringcan.tex",
    },
    {"JXTAB"}
)

-- 庄园贵族纹水井
AddRecipe2("jx_well",
    {
        Ingredient("cutstone", 8),
        Ingredient("boards", 6),
        Ingredient("goldnugget", 8),
        Ingredient("rope", 6),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_well.xml",
        image = "jx_well.tex",
        placer = "jx_well_placer",
        min_spacing = 1
    },
    {"JXTAB"}
)

-- 复古甲壳虫汽车
AddRecipe2("jx_car",
    {
        Ingredient("wagpunk_bits", 10),
        Ingredient("trinket_6", 1),
        Ingredient("transistor", 8),
        Ingredient("gears", 3),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_car.xml",
        image = "jx_car.tex",
        placer = "jx_car_placer",
        min_spacing = 7
    },
    {"JXTAB"}
)

-- 经典红色马桶吸
AddRecipe2("jx_toilet_suction",
    {
        Ingredient("flint", 2),
        Ingredient("pigskin", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_toilet_suction.xml",
        image = "jx_toilet_suction.tex",
    },
    {"JXTAB"}
)

-- 女仆的蕾丝地毯包
AddRecipe2("jx_rug_bag",
    {
        Ingredient("slurper_pelt", 2),
        Ingredient("silk", 8),
        Ingredient("dragon_scales", 1),
        Ingredient("beefalowool", 8),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_bag.xml",
        image = "jx_rug_bag.tex",
    },
    {"JXTAB"}
)

-- 维也纳丝绒椭圆毯
AddRecipe2("jx_rug_oval_item",
    {
        Ingredient("beefalowool", 2),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_oval_item.xml",
        image = "jx_rug_oval_item.tex",
    },
    {"JXTAB"}
)

-- 森林之歌方形布毯
AddRecipe2("jx_rug_forest_item",
    {
        Ingredient("beefalowool", 2),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_forest_item.xml",
        image = "jx_rug_forest_item.tex",
    },
    {"JXTAB"}
)

-- 奥布松丝绸挂毯
AddRecipe2("jx_rug_aubusson_item",
    {
        Ingredient("silk", 1),
        Ingredient("beefalowool", 1),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_aubusson_item.xml",
        image = "jx_rug_aubusson_item.tex",
    },
    {"JXTAB"}
)

-- 传统平织方格地毯
AddRecipe2("jx_rug_tradition_item",
    {
        Ingredient("beefalowool", 2),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_tradition_item.xml",
        image = "jx_rug_tradition_item.tex",
    },
    {"JXTAB"}
)

-- 萨瓦纳瑞手工地毯
AddRecipe2("jx_rug_savannah_item",
    {
        Ingredient("beefalowool", 3),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_savannah_item.xml",
        image = "jx_rug_savannah_item.tex",
    },
    {"JXTAB"}
)

-- 印第安图腾三角毯
AddRecipe2("jx_rug_triangle_item",
    {
        Ingredient("beefalowool", 2),
        Ingredient("boards", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_rug_triangle_item.xml",
        image = "jx_rug_triangle_item.tex",
    },
    {"JXTAB"}
)

-- 花岗岩拼花瓷砖
AddRecipe2("turf_granite",
    {
        Ingredient("beefalowool", 3),
        Ingredient("boards", 2),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/turf_granite.xml",
        image = "turf_granite.tex",
        numtogive = 6
    },
    {"JXTAB"}
)

-- 复古蓝宝石西餐刀
AddRecipe2("jx_weapon_2",
    {
        Ingredient("bluegem", 1),
        Ingredient("goldnugget", 5),
        Ingredient("flint", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_weapon_2.xml",
        image = "jx_weapon_2.tex",
    },
    {"JXTAB"}
)

-- 复古红宝石西餐叉
AddRecipe2("jx_weapon_1",
    {
        Ingredient("redgem", 1),
        Ingredient("goldnugget", 5),
        Ingredient("flint", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_weapon_1.xml",
        image = "jx_weapon_1.tex",
    },
    {"JXTAB"}
)

-- 复古绿宝石西餐勺
AddRecipe2("jx_weapon_3",
    {
        Ingredient("greengem", 1),
        Ingredient("goldnugget", 5),
        Ingredient("flint", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_weapon_3.xml",
        image = "jx_weapon_3.tex",
    },
    {"JXTAB"}
)

-- 查理夫人的葡萄酒
AddRecipe2("jx_weapon_4",
    {
        Ingredient("purplegem", 1),
        Ingredient("ice", 5),
        Ingredient("log", 1),
    },
    TECH.SCIENCE_TWO,
    {
        atlas = "images/inventoryimages/jx_weapon_4.xml",
        image = "jx_weapon_4.tex",
    },
    {"JXTAB"}
)

-- 法式铸铁平底锅
AddRecipe2("jx_pan",
    {
        Ingredient("flint", 3),
        Ingredient("twigs", 1),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jx_pan.xml",
        image = "jx_pan.tex",
    },
    {"JXTAB"}
)

-- 老式深厚的铁锅
AddRecipe2("jx_hat_iron_pan",
    {
        Ingredient("cutstone", 1),
        Ingredient("log", 2),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jx_hat_iron_pan.xml",
        image = "jx_hat_iron_pan.tex",
    },
    {"JXTAB"}
)