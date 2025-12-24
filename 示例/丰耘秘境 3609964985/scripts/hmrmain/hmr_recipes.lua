--[[
    AddRecipe2（name，ingredients，tech，config，filters）
    是用于向指定的模块（mod）添加新的配方的。在《饥荒联机版》中，配方是玩家可以制作的物品的蓝图。
    函数的参数如下：
    - name：这是一个字符串，表示新配方的名称。
    - ingredients：这是一个表，表示制作新物品所需的材料。
    - tech：这是一个表，表示制作新物品所需的科技等级。必须使用常量表TECH的值
    - config：这是一个表，包含了配方的其他配置信息，例如是否需要解锁等。
    - filters：这是一个表，包含了配方的过滤器名称。

    参数ingredients：
        ingredients参数是一个表，表中的所有内容需要用ingredient包装。
        例如ingredients = {Ingredient("cutgrass", 1), Ingredient("twigs", 1)}
        Ingredient，它代表《饥荒联机版》中的一个配方成分。
        类的构造函数接收以下参数：
        - ingredienttype：这是一个字符串，表示配方成分的类型。即配方所需要的原材料的预制件。特殊的是，消耗精神血量值制作，血量精神值的预制件为CHARACTER_INGREDIENT.HEALTH和CHARACTER_INGREDIENT.SANITY。
        - amount：这是一个数字，表示需要的配方成分的数量。
        - atlas：这是一个字符串，表示配方成分的图集路径。如果提供了atlas参数，函数会调用resolvefilepath函数获取完整的文件路径。
        - deconstruct：这个参数在代码中没有被使用，可能是一个布尔值，表示是否可以拆解这个配方成分。
        - imageoverride：这是一个字符串，表示配方成分的图片覆盖。如果提供了imageoverride参数，它会被用作配方成分的图片。
        类的构造函数的主要逻辑如下：
        1. 如果ingredienttype是CHARACTER_INGREDIENT.HEALTH或CHARACTER_INGREDIENT.SANITY，函数会检查amount是否是5的倍数。这是因为角色的健康和理智成分的消耗只能是5的倍数。
        2. 函数会将参数赋值给类的属性。例如，self.type会被设置为ingredienttype，self.amount会被设置为amount等。
        这个类的主要作用是存储配方成分的信息，包括成分的类型、数量、图集路径和图片覆盖等。

    参数config：
        - placer(string): 放置物 prefab，用于显示一个建筑的临时放置物，在放下建筑后就会消失。
        - min_spacing：这是一个数字，表示制作物品时所需的最小空间。
        - nounlock：这是一个布尔值，表示是否需要解锁配方。如果nounlock为true，则玩家可以立即制作这个物品，无需先解锁配方。如果为 false，只能在对应的科技建筑旁制作。否则在初次解锁后，就可以在任意地点制作。
        - numtogive：这是一个数字，表示制作物品时所得的数量。
        - builder_tag：这是一个字符串，表示制作物品的建造者标签。要求具备的制作者标签。如果人物没有此标签，便无法制作物品，可以用于人物的专属物品。
        - atlas：这是一个字符串，表示物品的图集路径。必填！！否则但图标会是空的
        - image：这是一个字符串或函数，表示物品的图片路径或生成图片的函数。包含在atlas中，可以不填。
        - testfn：这是一个函数，用于测试是否可以制作物品。放置时的检测函数，比如有些建筑对地形有特殊要求，可以使用此函数检测。
        - product：这是一个字符串，表示制作的物品的名称。
        - build_mode：这是一个字符串，表示制作物品的模式。必须使用常量表BUILDMODE.形如BUILDMODE.LAND，具体取值为无限制（NONE）、地上（LAND）和水上（WATER）
        - build_distance：这是一个数字，表示制作物品的距离。
        - filter：这是一个字符串，表示过滤器的名称。
        - nameoverride：这是一个字符串，用于覆盖配方在制作菜单中的名称。
        - description：这是一个字符串，用于覆盖配方在制作菜单中的描述。
        - fxover：这是一个布尔值，表示是否覆盖特效。
        - canbuild：这是一个函数，用于测试是否可以制作物品。
        - sg_state或buildingstate：这是一个字符串，表示制作物品时的SG状态。
        - no_deconstruction：这是一个函数或布尔值，表示是否可以拆解物品。
        - require_special_event：这是一个字符串，表示制作物品所需的特殊事件。
        - dropitem：这是一个布尔值，表示是否在制作物品时掉落物品。
        - actionstr：这是一个字符串，表示动作字符串。
        - hint_msg：这是一个字符串，表示提示消息。
        - manufactured：这是一个布尔值，表示是否由制作站处理物品的创建。
        - station_tag：这是一个字符串，表示制作站的标签。
        - allowautopick：这是一个布尔值，表示是否允许自动拾取物品。
    参数filters：
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
]]

----------------------------------------------------------------------------------------
---[[科学机器]]
----------------------------------------------------------------------------------------
AddPrototyperDef("honor_machine", {
	icon_atlas = "images/icons/honor_tech.xml",
    icon_image = "honor_tech.tex",
	is_crafting_station = false,
	action_str = "HONOR_STUDY",
})

AddPrototyperDef("terror_machine", {
	icon_atlas = "images/icons/terror_tech.xml",
    icon_image = "terror_tech.tex",
	is_crafting_station = false,
	action_str = "TERROR_STUDY",
})

----------------------------------------------------------------------------------------
---[[制作栏]]
----------------------------------------------------------------------------------------
-- 辉煌科技
AddRecipeFilter({
	name = "HONOR_SCIENCE",
	atlas = "images/inventoryimages/honor_splendor.xml",	--原始贴图54x54像素，64x64的也会默认缩放成54x54
	image = "honor_splendor.tex",
	--image_size = 80,  --表示缩放到80x80像素
})

-- 凶险科技
AddRecipeFilter({
	name = "TERROR_SCIENCE",
	atlas = "images/inventoryimages/terror_dangerous.xml",
	image = "terror_dangerous.tex",
})

-- 丰耘科技
AddRecipeFilter({
	name = "HMR_SCIENCE",
	atlas = "images/icons/hmr_tech.xml",
	image = "hmr_tech.tex",
})

----------------------------------------------------------------------------------------
---[[丰耘科技]]
----------------------------------------------------------------------------------------
---[[箱子]]
AddRecipe2("hmr_chest_store",  -- 青衢纳宝箱
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 2, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("ice", 4),
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_store.xml",
        image = "hmr_chest_store.tex",
        -- fxover={ bank="hmr_chest_store", build="hmr_chest_store", anim="idle" },
        placer = "hmr_chest_store_placer",
        min_spacing = 2,
    },
    {"HMR_SCIENCE", "STRUCTURES", "CONTAINERS"}
)

AddRecipe2("hmr_chest_transmit",  -- 云梭递运箱
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("terror_mucous", 2, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
        Ingredient("gunpowder", 2),
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_transmit.xml",
        image = "hmr_chest_transmit.tex",
        placer = "hmr_chest_transmit_placer",
        min_spacing = 2,
    },
    {"HMR_SCIENCE", "STRUCTURES", "CONTAINERS"}
)

AddRecipe2("hmr_chest_recycle",  -- 龙龛探秘箱
    {
        Ingredient("terror_dangerous", 1, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("wagpunk_bits", 2)
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_recycle.xml",
        image = "hmr_chest_recycle.tex",
        placer = "hmr_chest_recycle_placer",
        min_spacing = 2,
    },
    {"HMR_SCIENCE", "STRUCTURES", "CONTAINERS"}
)

AddRecipe2("hmr_chest_factory",  -- 灵枢织造箱
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("livinglog", 15),
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_factory.xml",
        image = "hmr_chest_factory.tex",
        placer = "hmr_chest_factory_placer",
        min_spacing = 2,
    },
    {"HMR_SCIENCE", "STRUCTURES", "CONTAINERS"}
)

AddRecipe2("hmr_chest_display",  -- 华樽耀勋箱
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("terror_dangerous", 1, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("goldnugget", 10),
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_display.xml",
        image = "hmr_chest_display.tex",
        placer = "hmr_chest_display_placer",
        min_spacing = 2,
    },
    {"HMR_SCIENCE", "STRUCTURES", "CONTAINERS"}
)

AddRecipe2("hmr_chest_factory_core_item",  -- 灵枢织造箱核心
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("livinglog", 3),
    },
    TECH.HMR_TECH,
    {
        atlas = "images/inventoryimages/hmr_chest_factory_core_item.xml",
        image = "hmr_chest_factory_core_item.tex",
    },
    {"HMR_SCIENCE", "TOOLS"}
)

---[[家具/装饰]]
-- AddRecipe2("hmr_lemon_chair",  -- 柠檬椅子
--     {
--         Ingredient("terror_lemon", 10, "images/inventoryimages/terror_lemon.xml", nil, "terror_lemon.tex"),
--         Ingredient("boards", 1)
--     },
--     TECH.HMR_TECH,
--     {atlas = "images/inventoryimages/hmr_lemon_chair.xml", image = "hmr_lemon_chair.tex", placer = "hmr_lemon_chair_placer"},
--     {"HMR_SCIENCE", "TERROR_SCIENCE", "DECOR"}
-- )

-- AddRecipe2("hmr_lemon_stool",  -- 柠檬凳子
--     {
--         Ingredient("terror_lemon", 6, "images/inventoryimages/terror_lemon.xml", nil, "terror_lemon.tex"),
--         Ingredient("boards", 1)
--     },
--     TECH.HMR_TECH,
--     {atlas = "images/inventoryimages/hmr_lemon_stool.xml", image = "hmr_lemon_stool.tex", placer = "hmr_lemon_stool_placer"},
--     {"HMR_SCIENCE", "TERROR_SCIENCE", "DECOR"}
-- )

AddRecipe2("terror_lemon_bomb",  -- 柠檬炸弹
    {
        Ingredient("terror_lemon", 16, "images/inventoryimages/terror_lemon.xml", nil, "terror_lemon.tex"),
        Ingredient("gunpowder", 1),
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_lemon_bomb.xml", image = "terror_lemon_bomb.tex", numtogive = 4},
    {"TERROR_SCIENCE", "WEAPONS"}
)

-- AddRecipe2("hmr_blueberry_carpet_item",   -- 蓝莓地毯
--     {
--         Ingredient("terror_blueberry", 15, "images/inventoryimages/terror_blueberry.xml", nil, "terror_blueberry.tex"),
--         Ingredient("butterfly", 3),
--         Ingredient("ice", 2),
--         Ingredient("bluegem", 3),
--     },
--     TECH.HMR_TECH,
--     {atlas = "images/inventoryimages/hmr_blueberry_carpet_item.xml", image = "hmr_blueberry_carpet_item.tex"},
--     {"HMR_SCIENCE", "TERROR_SCIENCE", "DECOR"}
-- )

AddRecipe2("terror_blueberry_hat",  -- 蓝莓帽子
    {
        Ingredient("terror_blueberry", 25, "images/inventoryimages/terror_blueberry.xml", nil, "terror_blueberry.tex"),
        Ingredient("terror_mucous", 2, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_blueberry_hat.xml", image = "terror_blueberry_hat.tex"},
    {"TERROR_SCIENCE", "DECOR"}
)

----------------------------------------------------------------------------------------
---[[调味料]]
----------------------------------------------------------------------------------------
local SPICE_DATA_LIST = require("hmrmain/hmr_lists").SPICE_DATA_LIST
AddRecipe2("spice_honor_rice_prime",  -- 酒糟
    {Ingredient("honor_rice_prime", 1, "images/inventoryimages/honor_rice_prime.xml", nil, "honor_rice_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_honor_rice_prime.xml",
        image = "spice_honor_rice_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.honor_rice_prime.numtogive,
        nounlock = true
    },
    {"HONOR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_honor_coconut_prime",  -- 椰蓉
    {Ingredient("honor_coconut_prime", 1, "images/inventoryimages/honor_coconut_prime.xml", nil, "honor_coconut_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_honor_coconut_prime.xml",
        image = "spice_honor_coconut_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.honor_coconut_prime.numtogive,
        nounlock = true
    },
    {"HONOR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_honor_wheat_prime",  -- 面粉
    {Ingredient("honor_wheat_prime", 1, "images/inventoryimages/honor_wheat_prime.xml", nil, "honor_wheat_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_honor_wheat_prime.xml",
        image = "spice_honor_wheat_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.honor_wheat_prime.numtogive,
        nounlock = true
    },
    {"HONOR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_honor_tea_prime",  -- 茶叶
    {Ingredient("honor_tea_prime", 1, "images/inventoryimages/honor_tea_prime.xml", nil, "honor_tea_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_honor_tea_prime.xml",
        image = "spice_honor_tea_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.honor_tea_prime.numtogive,
        nounlock = true
    },
    {"HONOR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_terror_blueberry_prime",  -- 蓝莓果酱
    {Ingredient("terror_blueberry_prime", 1, "images/inventoryimages/terror_blueberry_prime.xml", nil, "terror_blueberry_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_terror_blueberry_prime.xml",
        image = "spice_terror_blueberry_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.terror_blueberry_prime.numtogive,
        nounlock = true
    },
    {"TERROR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_terror_ginger_prime",  -- 姜粉
    {Ingredient("terror_ginger_prime", 1, "images/inventoryimages/terror_ginger_prime.xml", nil, "terror_ginger_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_terror_ginger_prime.xml",
        image = "spice_terror_ginger_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.terror_ginger_prime.numtogive,
        nounlock = true
    },
    {"TERROR_SCIENCE", "CRAFTING_STATION"}
)

AddRecipe2("spice_terror_snakeskinfruit_prime",  -- 蛇皮果酱
    {Ingredient("terror_snakeskinfruit_prime", 1, "images/inventoryimages/terror_snakeskinfruit_prime.xml", nil, "terror_snakeskinfruit_prime.tex")},
    TECH.FOODPROCESSING_ONE,
    {
        atlas = "images/inventoryimages/spice_terror_snakeskinfruit_prime.xml",
        image = "spice_terror_snakeskinfruit_prime.tex",
        builder_tag = "professionalchef",
        numtogive = SPICE_DATA_LIST.terror_snakeskinfruit_prime.numtogive,
        nounlock = true
    },
    {"TERROR_SCIENCE", "CRAFTING_STATION"}
)

----------------------------------------------------------------------------------------
---[[精华]]
----------------------------------------------------------------------------------------
AddRecipe2("honor_tea_prime",  -- 茶叶精华
    {
        Ingredient("honor_tea", 40, "images/inventoryimages/honor_tea.xml", nil, "honor_tea.tex"),
        Ingredient("honor_jasmine", 30, "images/inventoryimages/honor_jasmine.xml", nil, "honor_jasmine.tex"),
        Ingredient("honor_dhp", 5, "images/inventoryimages/honor_dhp.xml", nil, "honor_dhp.tex"),
        Ingredient("petals", 5),
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_tea_prime.xml", image = "honor_tea_prime.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_coconut_prime",  -- 椰子精华
    {
        Ingredient("honor_coconut_meat", 55, "images/inventoryimages/honor_coconut_meat.xml", nil, "honor_coconut_meat.tex"),
        Ingredient("honor_coconut_juice", 10, "images/inventoryimages/honor_coconut_juice.xml", nil, "honor_coconut_juice.tex"),
        Ingredient("honor_greenjuice", 3, "images/inventoryimages/honor_greenjuice.xml", nil, "honor_greenjuice.tex"),
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_coconut_prime.xml", image = "honor_coconut_prime.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_wheat_prime",  -- 小麦精华
    {
        Ingredient("honor_wheat", 80, "images/inventoryimages/honor_wheat.xml", nil, "honor_wheat.tex"),
        Ingredient("butter", 1)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_wheat_prime.xml", image = "honor_wheat_prime.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_rice_prime",  -- 水稻精华
    {
        Ingredient("honor_rice", 80, "images/inventoryimages/honor_rice.xml", nil, "honor_rice.tex"),
        Ingredient("pepper", 5)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_rice_prime.xml", image = "honor_rice_prime.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_goldenlanternfruit_prime",  -- 金灯果精华
    {
        Ingredient("honor_goldenlanternfruit", 80, "images/inventoryimages/honor_goldenlanternfruit.xml", nil, "honor_goldenlanternfruit.tex"),
        Ingredient("honor_goldenlanternfruit_peel", 1, "images/inventoryimages/honor_goldenlanternfruit_peel.xml", nil, "honor_goldenlanternfruit_peel.tex"),
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_goldenlanternfruit_prime.xml", image = "honor_goldenlanternfruit_prime.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("terror_blueberry_prime",    -- 蓝莓精华
    {
        Ingredient("terror_blueberry", 80, "images/inventoryimages/terror_blueberry.xml", nil, "terror_blueberry.tex"),
        Ingredient("berries", 5)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/terror_blueberry_prime.xml", image = "terror_blueberry_prime.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_ginger_prime",    -- 洋姜精华
    {
        Ingredient("terror_ginger", 80, "images/inventoryimages/terror_ginger.xml", nil, "terror_ginger.tex"),
        Ingredient("honey", 5)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/terror_ginger_prime.xml", image = "terror_ginger_prime.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_snakeskinfruit_prime",   -- 蛇皮果精华
    {
        Ingredient("terror_snakeskinfruit", 80, "images/inventoryimages/terror_snakeskinfruit.xml", nil, "terror_snakeskinfruit.tex"),
        Ingredient("firenettles", 1)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/terror_snakeskinfruit_prime.xml", image = "terror_snakeskinfruit_prime.tex"},
    {"TERROR_SCIENCE"}
)

----------------------------------------------------------------------------------------
---[[辉煌阵营]]
----------------------------------------------------------------------------------------
AddRecipe2("honor_seeds",   -- 辉煌种子
    {Ingredient("petals", 1), Ingredient("seeds", 1)},
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_seeds.xml", image = "honor_seeds.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_plantfibre",  -- 植物纤维
    {Ingredient("honor_tea", 10, "images/inventoryimages/honor_tea.xml", nil, "honor_tea.tex")},
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_plantfibre.xml", image = "honor_plantfibre.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_greenjuice",  -- 植物清汁
    {
        Ingredient("honor_tea", 1, "images/inventoryimages/honor_tea.xml", nil, "honor_tea.tex"),
        Ingredient("honor_coconut_juice", 1, "images/inventoryimages/honor_coconut_juice.xml", nil, "honor_coconut_juice.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_greenjuice.xml", image = "honor_greenjuice.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_aloe_mucous",  -- 芦荟胶
    {
        Ingredient("honor_aloe", 8, "images/inventoryimages/honor_aloe.xml", nil, "honor_aloe.tex"),
        Ingredient("honor_coconut_juice", 1, "images/inventoryimages/honor_coconut_juice.xml", nil, "honor_coconut_juice.tex"),
        Ingredient("royal_jelly", 1)
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_aloe_mucous.xml", image = "honor_aloe_mucous.tex", numtogive = 4},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_hat",  -- 辉煌法帽
    {
        Ingredient("honor_splendor", 10, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 20, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_hat.xml", image = "honor_hat.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_armor",  -- 辉煌护甲
    {
        Ingredient("honor_splendor", 12, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 24, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_armor.xml", image = "honor_armor.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_multitool",  -- 辉煌多用工具
    {
        Ingredient("honor_splendor", 8, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 15, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_multitool.xml", image = "honor_multitool.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_staff",  -- 辉煌法杖
    {
        Ingredient("honor_splendor", 22, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 4, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_staff.xml", image = "honor_staff.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_backpack",    -- 辉煌背包
    {
        Ingredient("honor_splendor", 5, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 10, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("chestupgrade_stacksize", 1),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_backpack.xml", image = "honor_backpack.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_kit",  -- 辉煌修补套件
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 4, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
    },
    TECH.HONOR_TECH,
    {
        atlas = "images/inventoryimages/honor_kit.xml",
        image = "honor_kit.tex",
    },
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_machine", -- 自然亲和机器
    {
        Ingredient("honor_splendor", 8, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 16, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("hivehat", 1),
        Ingredient("spiderhat", 1)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/honor_machine.xml", image = "honor_machine.tex", placer = "honor_machine_placer"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_cookpot", -- 辉煌炼化容器
    {
        Ingredient("honor_splendor", 5, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 20, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("honor_rice_prime", 1, "images/inventoryimages/honor_rice_prime.xml", nil, "honor_rice_prime.tex"),
        Ingredient("honor_wheat_prime", 1, "images/inventoryimages/honor_wheat_prime.xml", nil, "honor_wheat_prime.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_cookpot.xml", image = "honor_cookpot.tex", placer = "honor_cookpot_placer"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_tower",   -- 自然亲和塔
    {
        Ingredient("honor_splendor", 10, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 12, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("wateringcan", 3),
        Ingredient("canary", 1),
        Ingredient("livinglog", 6),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_tower.xml", image = "honor_tower.tex", placer = "honor_tower_placer"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_stower",  -- 自然亲和子塔
    {
        Ingredient("honor_splendor", 2, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 4, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("honor_greenjuice", 2, "images/inventoryimages/honor_greenjuice.xml", nil, "honor_greenjuice.tex"),
        Ingredient("honor_aloe", 3, "images/inventoryimages/honor_aloe.xml", nil, "honor_aloe.tex"),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_stower.xml", image = "honor_stower.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_balance_maintainer_ground",   -- 自然平衡维持器
    {
        Ingredient("honor_splendor", 15, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 15, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("yellowgem", 3),
        Ingredient("greengem", 3),
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_balance_maintainer.xml", image = "honor_balance_maintainer.tex", placer = "honor_balance_maintainer_ground_placer"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_coconut_hat",  -- 巨型椰子壳(头盔)
    {
        Ingredient("honor_coconut", 20, "images/inventoryimages/honor_coconut.xml", nil, "honor_coconut.tex"),
        Ingredient("honor_plantfibre", 6, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex")
    },
    TECH.HONOR_TECH,
    {atlas = "images/inventoryimages/honor_coconut_hat.xml", image = "honor_coconut_hat.tex"},
    {"HONOR_SCIENCE"}
)

AddRecipe2("honor_goldenlanternfruit_lamp",  -- 金盏灯
    {
        Ingredient("honor_splendor", 1, "images/inventoryimages/honor_splendor.xml", nil, "honor_splendor.tex"),
        Ingredient("honor_plantfibre", 3, "images/inventoryimages/honor_plantfibre.xml", nil, "honor_plantfibre.tex"),
        Ingredient("honor_goldenlanternfruit", 3, "images/inventoryimages/honor_goldenlanternfruit.xml", nil, "honor_goldenlanternfruit.tex"),
        Ingredient("honor_goldenlanternfruit_peel", 1, "images/inventoryimages/honor_goldenlanternfruit_peel.xml", nil, "honor_goldenlanternfruit_peel.tex"),
    },
    TECH.HONOR_TECH,
    {
        atlas = "images/inventoryimages/honor_goldenlanternfruit_lamp.xml",
        image = "honor_goldenlanternfruit_lamp.tex",
        placer = "honor_goldenlanternfruit_lamp_placer",
        min_spacing = 1
    },
    {"HONOR_SCIENCE"}
)

AddRecipe2("hmr_goatmilk", -- 山羊奶
    {
        Ingredient("honor_greenjuice", 2, "images/inventoryimages/honor_greenjuice.xml", nil, "honor_greenjuice.tex"),
        Ingredient("honor_macadamia", 1, "images/inventoryimages/honor_macadamia.xml", nil, "honor_macadamia.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages2.xml",
        image = "goatmilk.tex",
        product = "goatmilk",
    },
    {"HONOR_SCIENCE"}
)

AddRecipe2("hmr_butter", -- 黄油
    {
        Ingredient("goatmilk", 1),
        Ingredient("honor_cashew", 3, "images/inventoryimages/honor_cashew.xml", nil, "honor_cashew.tex"),
        Ingredient("honor_almond", 2, "images/inventoryimages/honor_almond.xml", nil, "honor_almond.tex"),
        Ingredient("honor_nut", 10, "images/inventoryimages/honor_nut.xml", nil, "honor_nut.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages1.xml",
        image = "butter.tex",
        product = "butter",
    },
    {"HONOR_SCIENCE"}
)

----------------------------------------------------------------------------------------
---[[凶险阵营]]
----------------------------------------------------------------------------------------
AddRecipe2("terror_seeds",  -- 凶险种子
    {Ingredient("petals_evil", 1), Ingredient("seeds", 2)},
    TECH.NONE,
    {
        atlas = "images/inventoryimages/terror_seeds.xml",
        image = "terror_seeds.tex",
        numtogive = 2
    },
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_kit",  -- 凶险修补套件
    {
        Ingredient("terror_dangerous", 1, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 3, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
    },
    TECH.TERROR_TECH,
    {
        atlas = "images/inventoryimages/terror_kit.xml",
        image = "terror_kit.tex",
    },
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_sword",  -- 凶险荆棘
    {
        Ingredient("terror_dangerous", 6, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 3, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex")
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_sword.xml", image = "terror_sword.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_staff",  -- 凶险手杖
    {
        Ingredient("terror_dangerous", 3, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 6, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex")
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_staff.xml", image = "terror_staff.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_hat",  -- 凶险笼罩
    {
        Ingredient("terror_dangerous", 6, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 8, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex")
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_hat.xml", image = "terror_hat.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_armor",  -- 凶险潜胄
    {
        Ingredient("terror_dangerous", 5, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 10, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex")
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_armor.xml", image = "terror_armor.tex"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_machine",  -- 凶险蔓延机器
    {
        Ingredient("terror_dangerous", 2, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 10, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
        Ingredient("lureplantbulb", 1),
        Ingredient("dug_marsh_bush", 1),
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/terror_machine.xml", image = "terror_machine.tex", placer = "terror_machine_placer", min_spacing = 2},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_tower",  -- 凶险威澜台
    {
        Ingredient("terror_dangerous", 10, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 2, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
        Ingredient("dragon_scales", 1),
        Ingredient("townportaltalisman", 1),
        Ingredient("deerclops_eyeball", 1),
    },
    TECH.TERROR_TECH,
    {atlas = "images/inventoryimages/terror_tower.xml", image = "terror_tower.tex", placer = "terror_tower_placer"},
    {"TERROR_SCIENCE"}
)

AddRecipe2("terror_bomb",  -- 凶险炸弹
    {
        Ingredient("terror_dangerous", 1, "images/inventoryimages/terror_dangerous.xml", nil, "terror_dangerous.tex"),
        Ingredient("terror_mucous", 4, "images/inventoryimages/terror_mucous.xml", nil, "terror_mucous.tex"),
        Ingredient("gunpowder", 1),
    },
    TECH.TERROR_TECH,
    {
        atlas = "images/inventoryimages/terror_bomb.xml",
        image = "terror_bomb.tex",
        numtogive = 4,
    },
    {"TERROR_SCIENCE"}
)

----------------------------------------------------------------------------------------
---[[樱海岛]]
----------------------------------------------------------------------------------------
AddRecipe2("turf_hmr_cherry_flower",   -- 樱花地皮
    {
        Ingredient("hmr_cherry_tree_flower", 8, "images/inventoryimages/hmr_cherry_tree_flower.xml", nil, "hmr_cherry_tree_flower.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 1, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_flower_turf.xml",
        image = "hmr_cherry_flower_turf.tex",
        numtogive = 4
    },
    {"HMR_SCIENCE"}
)

AddRecipe2("turf_hmr_cherry_grass",   -- 樱草地皮
    {
        Ingredient("cutgrass", 6),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_grass_turf.xml",
        image = "hmr_cherry_grass_turf.tex",
        numtogive = 8
    },
    {"HMR_SCIENCE"}
)

AddRecipe2("turf_hmr_cherry_mystery",   -- 樱海秘境地皮
    {
        Ingredient("hmr_cherry_tree_flower", 2, "images/inventoryimages/hmr_cherry_tree_flower.xml", nil, "hmr_cherry_tree_flower.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_mystery_turf.xml",
        image = "hmr_cherry_mystery_turf.tex",
        numtogive = 8
    },
    {"HMR_SCIENCE"}
)

AddRecipe2("turf_hmr_cherry_xmm",   -- 悉樱樱地皮
    {
        Ingredient("hmr_cherry_tree_flower", 1, "images/inventoryimages/hmr_cherry_tree_flower.xml", nil, "hmr_cherry_tree_flower.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_xmm_turf.xml",
        image = "hmr_cherry_xmm_turf.tex",
        numtogive = 8
    },
    {"HMR_SCIENCE"}
)

AddRecipe2("turf_hmr_cherry_road",   -- 樱花小径地皮
    {
        Ingredient("hmr_cherry_tree_flower", 1, "images/inventoryimages/hmr_cherry_tree_flower.xml", nil, "hmr_cherry_tree_flower.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 2, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
        Ingredient("hmr_cherry_rock_item", 2, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_road_turf.xml",
        image = "hmr_cherry_road_turf.tex",
        numtogive = 8
    },
    {"HMR_SCIENCE"}
)

AddRecipe2("hmr_cherry_lantern_post_item",   -- 樱花灯柱
    {
        Ingredient("hmr_cherry_rock_item", 3, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
        Ingredient("log", 2),
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/hmr_cherry_lantern_post_item.xml", image = "hmr_cherry_lantern_post_item.tex"},
    {"HMR_SCIENCE", "LIGHT"}
)

AddRecipe2("hmr_cherry_flowerpot_item",   -- 樱岩盆栽
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 2, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_flowerpot_item.xml",
        image = "hmr_cherry_flowerpot_item.tex",
        numtogive = 3,
    },
    {"HMR_SCIENCE", "DECOR"}
)

AddRecipe2("hmr_cherry_flowerpot_large_item",   -- 樱岩盆景
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 1, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_flowerpot_large_item.xml",
        image = "hmr_cherry_flowerpot_large_item.tex",
        numtogive = 1,
    },
    {"HMR_SCIENCE", "DECOR"}
)

AddRecipe2("hmr_cherry_decor_pot_item",   -- 樱花装饰花盆
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
        Ingredient("hmr_cherry_grass_seeds", 1, "images/inventoryimages/hmr_cherry_grass_seeds.xml", nil, "hmr_cherry_grass_seeds.tex"),
        Ingredient("poop", 4),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/hmr_cherry_decor_pot.xml",
        image = "hmr_cherry_decor_pot.tex",
        numtogive = 8,
    },
    {"HMR_SCIENCE", "DECOR"}
)

AddRecipe2("hmr_cherry_table",  -- 樱岩桌子
    {
        Ingredient("hmr_cherry_rock_item", 5, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("boards", 3)
    },
    TECH.NONE,
    {atlas = "images/inventoryimages/hmr_cherry_table.xml", image = "hmr_cherry_table.tex", placer = "hmr_cherry_table_placer"},
    {"HMR_SCIENCE",  "DECOR"}
)

----------------------------------------------------------------------------------------
---[[拆解配方]]
----------------------------------------------------------------------------------------
--[[
AddDeconstructRecipe(name, return_ingredients)
    name: prefab名
    return_ingredients：分解返还的材料，写完整材料即可，摧毁只会返还一半
]]

AddDeconstructRecipe("hmr_cherry_lantern_post",
    {
        Ingredient("hmr_cherry_rock_item", 3, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 4, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    }
)

AddDeconstructRecipe("hmr_cherry_flowerpot",
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 2, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    }
)

AddDeconstructRecipe("hmr_cherry_flowerpot_large",
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 1, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
    }
)

AddDeconstructRecipe("hmr_cherry_decor_pot",
    {
        Ingredient("hmr_cherry_rock_item", 1, "images/inventoryimages/hmr_cherry_rock_item.xml", nil, "hmr_cherry_rock_item.tex"),
        Ingredient("hmr_cherry_fluffy_ball", 1, "images/inventoryimages/hmr_cherry_fluffy_ball.xml", nil, "hmr_cherry_fluffy_ball.tex"),
        Ingredient("hmr_cherry_grass_seeds", 1, "images/inventoryimages/hmr_cherry_grass_seeds.xml", nil, "hmr_cherry_grass_seeds.tex"),
        Ingredient("poop", 1),
    }
)
