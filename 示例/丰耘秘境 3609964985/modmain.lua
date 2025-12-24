GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k ) end})

PrefabFiles ={
    "hmr_furnitures",           -- 家具
    "hmr_flower_arch",          -- 家具_花拱门
    "hmr_primes",               -- 精华
    "hmr_igniter_fx",           -- 爆炸特效
    "hmr_naturalmaterials",     -- 自然材料
    "hmr_spices",               -- 香料
    "hmr_preparedfoods",        -- 烹饪食材
    "hmr_kits",                 -- 修补包
    "hmr_buffs",                -- buff
    "hmr_particle_fxs",         -- 粒子特效

    "hmr_chests",               -- 箱子 * 5
    "hmr_chest_factory_core",   -- 灵枢织造箱核心
    "hmr_dug_cavebananatree",   -- 灵枢织造箱_洞穴树
    "hmr_junkpiles",            -- 龙龛探秘箱_垃圾堆

    -- 辉煌围墙
    -- "honor_walls",
    -- "honor_walls_fx",

    -- 农作物相关
    "hmr_seeds",
    "hmr_random_plants",
    "hmr_farm_plant_products",
    "hmr_farm_plant_products_special",

    "honor_goldenlanternfruit_lamp",
    "honor_hybrid_rice",
    "honor_coconuttreeguard",

    -- 辉煌系列
    "honor_backpack",
    "honor_armor",
    "honor_multitool",
    "honor_staff",
    "honor_hat",
    "honor_blowdarts",

    "honor_machine",            -- 自然亲和机器
    "honor_cookpot",            -- 辉煌炼化容器
    "honor_tower",              -- 自然亲和塔
    "honor_stower",             -- 自然亲和字塔
    "honor_balance_maintainer", -- 自然平衡维持器

    -- 凶险事件
    "hmr_bees",
    "hmr_beesghost",

    -- 凶险系列
    "terror_staff",
    "terror_sword",
    "terror_vine",
    "terror_hat",
    "terror_armor",
    "terror_bomb",
    "terror_lemon_bomb",
    "terror_whip",

    "terror_machine",
    "terror_tower",

    "terror_greedybeetle",      -- 贪婪甲虫

    -- 樱海岛
    "hmr_cherry_grass",
    "hmr_cherry_flower",
    "hmr_cherry_rock",
    "hmr_cherry_tree",
    "hmr_cherry_carpet",
    "hmr_cherry_lantern_post",
    "hmr_cherry_island_center",
    "hmr_cherry_flowerpot",
    "hmr_cherry_decors",
}


-- 套装名称
GLOBAL.EQUIPMENTSETNAMES.HONOR = "HONOR"
GLOBAL.EQUIPMENTSETNAMES.TERROR = "TERROR"

-- 装备槽位
GLOBAL.HMR_EQUIPSLOTS = {
    BACKPACK = EQUIPSLOTS.BACK or EQUIPSLOTS.BACKPACK or EQUIPSLOTS.BODY,
    AMULET = EQUIPSLOTS.NECK or EQUIPSLOTS.AMULET or EQUIPSLOTS.BODY,
    CLOTHING = EQUIPSLOTS.BELLY or EQUIPSLOTS.CLOTHING or EQUIPSLOTS.BODY,
}

-- 模组配置
GLOBAL.HMR_CONFIGS = {
    HONOR_BACKPACK_SLOTS = GetModConfigData("HONOR_BACKPACK_SLOTS") or 16,
    HONOR_STOWER_MAX_CONSUME = GetModConfigData("HONOR_STOWER_MAX_CONSUME") or 0.00,
}

-- 语言配置文件需优先导入
modimport("scripts/hmrlanguages/hmr_ch")

modimport("scripts/hmrmain/hmr_util")
modimport("scripts/hmrmain/hmr_tuning")
modimport("scripts/hmrmain/hmr_userdatahook_api")
modimport("scripts/hmrmain/hmr_blink_api")

modimport("scripts/hmrmain/hmr_assets")
modimport("scripts/hmrmain/hmr_containers")
modimport("scripts/hmrmain/hmr_techtrees")
modimport("scripts/hmrmain/hmr_sgactions")
modimport("scripts/hmrmain/hmr_recipes")

modimport("scripts/hmrmain/hmr_farm_plant")
modimport("scripts/hmrmain/hmr_spicedfoods")
modimport("scripts/hmrmain/hmr_terrorevents")
modimport("scripts/hmrmain/hmr_init")

modimport("scripts/hmrmain/hmr_skin")
