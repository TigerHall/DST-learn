--------------------------------
--[[ 建造配方和料理配方]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
-- name, ingredients, tab, level, placer, min_spacing, nounlock,numtogive, builder_tag, atlas, image, testfn
local Recipes = {
    {--竹蜻蜓
        name = TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB,
        ingredients = {
            Ingredient("minifan", 1),--旋风扇
            --Ingredient(CHARACTER_INGREDIENT.SANITY, 25),
            Ingredient("livinglog", 3),--活木
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,--魔法二本(魔法从二本开始),废弃去除科技限制
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB..".tex",
        filters = {"MAGIC","CLOTHING","SUMMER"},
    },
    {--还原光线
        name = TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB,
        ingredients = {
            --Ingredient("yellowgem", 1),--黄宝石 宝石有点难搞算了
            Ingredient("nightmarefuel", 7),-- 梦魇燃料
            Ingredient("transistor", 2),--电子元件
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".tex",
        filters = {"MAGIC","TOOLS"},
    },
    {--恶魔护照
        name = TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB,
        ingredients = {
            Ingredient("papyrus", 3),--莎草纸
            Ingredient("nightmarefuel", 3),--噩梦燃料
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".tex",
        filters = {"MAGIC","CLOTHING"},
    },
    {--感觉监视器
        name = TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB,
        ingredients = {
            Ingredient("transistor", 2),--电子元件
            Ingredient("gears", 1),--齿轮
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB..".tex",
        filters = {"MAGIC","STRUCTURES"},
    },
    {--感觉监视器摄像头
        name = TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB,
        ingredients = {
            Ingredient("transistor", 1),--电子元件
            Ingredient("boards", 1),--木板
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB..".tex",
        filters = {"MAGIC","STRUCTURES"},
    },
    {-- 记忆面包
        name = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB,
        ingredients = {
            Ingredient("seeds", 4),--种子
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".tex",
        placer_or_more_data = {
            canbuild = function(recipe , inst , pt, rotation)
                return false,STRINGS.DORAEMON_TECH.DORAEMON_MEMORY_BREAD_CANT_BUILD
            end,
        },
        filters = {"COOKING","MAGIC"},
    },
    {-- 秘密垃圾桶/洞
        name = TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB,
        ingredients = {
            Ingredient("townportaltalisman", 4),-- 沙之石
        },
        tab = CUSTOM_RECIPETABS[STRINGS.DORAEMON_TECH.NAME],
        level = TECH.NONE,
        atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".xml",
        image = TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".tex",
        placer_or_more_data = {
            placer = TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB.."_placer",
        },
        filters = {"STRUCTURES","MAGIC"},
    },
}

local IngredientValues = {
     {
         names = {"seeds"}, -- prefab名，可以设置多个
         --tags = {veggie = 0.5,seed = 1}, -- 属性值，可以设置多个
         tags = {seed = 1}, -- 属性值，可以设置多个
         cancook = true, -- 是否可以烹饪
         candry = false -- 是否可以晾干
     },
}
local CookerRecipes = {
    {
        cookers = {"cookpot","portablecookpot"}, -- prefab名，可以设置多个
        recipe = {
            test = function(cooker, names, tags) return names.seeds and not tags.meat and tags.seed and tags.seed >= 4 end,
            name = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB, -- 料理名
            priority = 1,-- 食谱权重
            weight = 1,-- 食谱优先级
            foodtype = FOODTYPE.GOODIES,-- 料理类型GOODIES
            health = TUNING.HEALING_TINY,
            hunger = TUNING.CALORIES_MED,
            sanity = TUNING.SANITY_TINY,
            perishtime = TUNING.PERISH_SUPERSLOW,
            --cooktime = 2, --烹饪时间 实际40秒
            cooktime = 0.5, --烹饪时间
            --overridebuild = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB,
            --overridesymbolname = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB,
            potlevel = "mid",-- high low mid 食材在锅里显示位置
            cookbook_tex = TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".tex", -- 在游戏内食谱书里的mod食物那一栏里显示的图标，tex在 atlas的xml里定义了，所以这里只写文件名即可
            cookbook_atlas = "images/inventoryimages/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".xml",
            -- temperature = TUNING.HOT_FOOD_BONUS_TEMP, --某些食物吃了之后有温度变化，则是在这地方定义的
            -- temperatureduration = TUNING.FOOD_TEMP_BRIEF,
            floater = {"small", 0.05, 0.7}
        }
    },
}
return {Recipes = Recipes, IngredientValues = IngredientValues , CookerRecipes = CookerRecipes}
