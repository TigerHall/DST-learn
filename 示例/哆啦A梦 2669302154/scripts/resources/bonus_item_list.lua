--------------------------------
--[[ 物品奖励]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-15]]
--[[ @updateTime: 2022-03-15]]
--[[ @email: x7430657@163.com]]
--------------------------------
-- 节日item
local festivalItemList =  {
    --冬季盛宴零食
    "winter_food1",
    "winter_food2",
    "winter_food3",
    "winter_food4",
    "winter_food5",
    "winter_food6",
    "winter_food7",
    "winter_food8",
    "winter_food9",
    "wintersfeastfuel",
    "crumbs",
    --万圣夜糖果
    "halloweencandy_1",
    "halloweencandy_2",
    "halloweencandy_3",
    "halloweencandy_4",
    "halloweencandy_5",
    "halloweencandy_6",
    "halloweencandy_7",
    "halloweencandy_8",
    "halloweencandy_9",
    "halloweencandy_10",
    "halloweencandy_11",
    "halloweencandy_12",
    "halloweencandy_13",
    "halloweencandy_14",
    --圣诞树挂饰
    "winter_ornament_plain1",
    "winter_ornament_plain2",
    "winter_ornament_plain3",
    "winter_ornament_plain4",
    "winter_ornament_plain5",
    "winter_ornament_plain6",
    "winter_ornament_plain7",
    "winter_ornament_plain8",
    "winter_ornament_plain9",
    "winter_ornament_plain10",
    "winter_ornament_plain11",
    "winter_ornament_plain12",
    "winter_ornament_fancy1",
    "winter_ornament_fancy2",
    "winter_ornament_fancy3",
    "winter_ornament_fancy4",
    "winter_ornament_fancy5",
    "winter_ornament_fancy6",
    "winter_ornament_fancy7",
    "winter_ornament_fancy8",
    "winter_ornament_boss_bearger",
    "winter_ornament_boss_deerclops",
    "winter_ornament_boss_moose",
    "winter_ornament_boss_dragonfly",
    "winter_ornament_boss_beequeen",
    "winter_ornament_boss_toadstool",
    "winter_ornament_boss_antlion",
    "winter_ornament_boss_fuelweaver",
    "winter_ornament_boss_klaus",
    "winter_ornament_boss_malbatross",
    "winter_ornament_boss_krampus",
    "winter_ornament_boss_noeyered",
    "winter_ornament_boss_noeyeblue",
    "winter_ornament_boss_crabking",
    "winter_ornament_boss_crabkingpearl",
    "winter_ornament_boss_hermithouse",
    "winter_ornament_boss_minotaur",
    "winter_ornament_boss_pearl",
    "winter_ornament_boss_toadstool_misery",
    "winter_ornament_festivalevents1",
    "winter_ornament_festivalevents2",
    "winter_ornament_festivalevents3",
    "winter_ornament_festivalevents4",
    "winter_ornament_festivalevents5",
    --圣诞树彩灯
    "winter_ornament_light1",
    "winter_ornament_light2",
    "winter_ornament_light3",
    "winter_ornament_light4",
    "winter_ornament_light5",
    "winter_ornament_light6",
    "winter_ornament_light7",
    "winter_ornament_light8",
    --万圣夜挂饰
    "halloween_ornament_1",
    "halloween_ornament_2",
    "halloween_ornament_3",
    "halloween_ornament_4",
    "halloween_ornament_5",
    "halloween_ornament_6",
    --玩具
    "antliontrinket",
    "trinket_1",
    "trinket_2",
    "trinket_3",
    "trinket_4",
    "trinket_5",
    "trinket_6",
    "trinket_7",
    "trinket_8",
    "trinket_9",
    "trinket_10",
    "trinket_11",
    "trinket_12",
    "trinket_13",
    "trinket_14",
    "trinket_15",
    "trinket_16",
    "trinket_17",
    "trinket_18",
    "trinket_19",
    "trinket_20",
    "trinket_21",
    "trinket_22",
    "trinket_23",
    "trinket_24",
    "trinket_25",
    "trinket_26",
    "trinket_27",
    "trinket_28",
    "trinket_29",
    "trinket_30",
    "trinket_31",
    --万圣节玩具
    "trinket_32",
    "trinket_33",
    "trinket_34",
    "trinket_35",
    "trinket_36",
    "trinket_37",
    "trinket_38",
    "trinket_39",
    "trinket_40",
    "trinket_41",
    "trinket_42",
    "trinket_43",
    "trinket_44",
    "trinket_45",
    "trinket_46",
    --皮弗娄牛玩偶
    "yotb_beefalo_doll_beast",
    "yotb_beefalo_doll_doll",
    "yotb_beefalo_doll_festive",
    "yotb_beefalo_doll_formal",
    "yotb_beefalo_doll_ice",
    "yotb_beefalo_doll_nature",
    "yotb_beefalo_doll_robot",
    "yotb_beefalo_doll_victorian",
    "yotb_beefalo_doll_war",
}
-- 材料和生物（球状光虫）
local materialItemList = {
    --植物材料
    "cutgrass",
    "twigs",
    "log",
    "driftwood_log",
    "livinglog",
    "charcoal",
    "ash",
    "cutreeds",
    "petals",
    "petals_evil",
    "foliage",
    "succulent_picked",
    "lightbulb",
    --虚空材料
    "nightmarefuel",
    "ghostflower",
    --精炼植物材料
    "rope",
    "boards",
    "papyrus",
    "waxpaper",
    --矿石材料
    "flint",
    "nitre",
    "rocks",
    "goldnugget",
    "marble",
    "moonrocknugget",
    "thulecite_pieces",
    "townportaltalisman",
    "gears",
    "saltrock",
    "moonglass",
    "transistor",
    --精炼矿石材料
    "cutstone",
    "marblebean",
    "thulecite",
    "dustmeringue",
    "refined_dust",
    --生物材料 羽毛
    "feather_robin_winter",
    "feather_robin",
    "feather_crow",
    "feather_canary",
    "goose_feather",
    "malbatross_feather",
    "malbatross_feathered_weave",
    --生物材料 牙齿
    "houndstooth",
    "walrus_tusk",
    --生物材料 骨头
    "boneshard",
    "fossil_piece",
    --生物材料 角
    "horn",
    "lightninggoathorn",
    "gnarwail_horn",
    "deer_antler",
    "deer_antler1",
    "deer_antler2",
    "deer_antler3",
    "klaussackkey",
    "minotaurhorn",
    --生物材料 眼球
    "deerclops_eyeball",
    --生物材料 甲壳
    "slurtle_shellpieces",
    "cookiecuttershell",
    --生物材料 皮毛
    "pigskin",
    "tentaclespots",
    "slurper_pelt",
    "furtuft",
    "bearger_fur",
    "dragon_scales",
    "shroom_skin",
    "manrabbit_tail",
    "beefalowool",
    "steelwool",
    "beardhair",
    --生物材料 蜜蜂
    "stinger",
    "honeycomb",
    "beeswax",
    --生物材料 蜘蛛
    "silk",
    "spidergland",
    "spidereggsack",
    --生物材料 卵
    "lavae_egg",
    "lavae_egg_cracked",
    "lavae_cocoon",
    --生物材料 其他
    "mosquitosack",
    "phlegm",
    "slurtleslime",
    "glommerwings",
    --生物材料 尾巴
    "coontail",
    --生物材料 肥料
    "poop",
    "guano",

    --生物
    -- 球状光虫
    "lightflier",
}

-- 道具
local propItemList = {
    --战斗道具
    "gunpowder",
    "beemine",
    "trap_teeth",
    "trap_bramble",
    "dug_trap_starfish",
    "sleepbomb",
    "panflute",
    "eyeturret_item",
    --医疗道具
    "healingsalve",
    "bandage",
    "lifeinjector",
    "reviver",
    "compostwrap",
    "tillweedsalve",
    --药水
    "halloweenpotion_bravery_small",
    "halloweenpotion_bravery_large",
    "halloweenpotion_health_small",
    "halloweenpotion_health_large",
    "halloweenpotion_sanity_small",
    "halloweenpotion_sanity_large",
    "halloweenpotion_embers",
    "halloweenpotion_sparks",
    "halloweenpotion_moon",
    --黑暗炼金药剂
    "ghostlyelixir_attack",
    "ghostlyelixir_speed",
    "ghostlyelixir_slowregen",
    "ghostlyelixir_fastregen",
    "ghostlyelixir_shield",
    "ghostlyelixir_retaliation",
    --温泉道具
    "bathbomb",
    --驱赶野兽道具
    "firecrackers",
    --换人道具
    "moonrockidol",
    "moonrockseed",
    "multiplayer_portal_moonrock_constr_plans",
    --换皮肤道具
    "reskin_tool",
    --隐士相关
    "hermit_pearl",
    "hermit_cracked_pearl",
    "messagebottle",
    "messagebottleempty",
    --远古用品
    "archive_lockbox",
    "archive_resonator_item",
    --贝壳钟
    "singingshell_octave3",
    "singingshell_octave4",
    "singingshell_octave5",
    --随从道具
    "abigail_flower",
    "bernie_inactive",
    "lavae_tooth",
    "fruitflyfruit",
    "chester_eyebone",
    "hutch_fishbowl",
    "glommerflower",
    "thurible",
    "houndwhistle",
    "onemanband",
    "pig_coin",
    "beef_bell",
    --暴动检测
    "nightmare_timepiece",
    "atrium_key",
    "shadowheart",
    --人物专属
    "balloons_empty",
    "wortox_soul",
    "battlesong_durability",
    "battlesong_healthgain",
    "battlesong_sanitygain",
    "battlesong_sanityaura",
    "battlesong_fireresistance",
    "battlesong_instant_taunt",
    "battlesong_instant_panic",
    --书
    "book_birds",
    "book_brimstone",
    "book_gardening",
    "book_horticulture",
    "book_silviculture",
    "book_sleep",
    "book_tentacles",
    "waxwelljournal",
    "cookbook",
    --雕像草图
    "chesspiece_moosegoose_sketch",
    "chesspiece_dragonfly_sketch",
    "chesspiece_bearger_sketch",
    "chesspiece_deerclops_sketch",
    "chesspiece_crabking_sketch",
    "chesspiece_malbatross_sketch",
    "chesspiece_antlion_sketch",
    "chesspiece_beequeen_sketch",
    "chesspiece_klaus_sketch",
    "chesspiece_minotaur_sketch",
    "chesspiece_stalker_sketch",
    "chesspiece_toadstool_sketch",
    "chesspiece_knight_sketch",
    "chesspiece_bishop_sketch",
    "chesspiece_rook_sketch",
    "chesspiece_formal_sketch",
    "chesspiece_muse_sketch",
    "chesspiece_pawn_sketch",
    "chesspiece_anchor_sketch",
    "chesspiece_butterfly_sketch",
    "chesspiece_moon_sketch",
    "chesspiece_claywarg_sketch",
    "chesspiece_clayhound_sketch",
    "chesspiece_carrat_sketch",
    "chesspiece_beefalo_sketch",
    --渔具图纸
    "oceanfishinglure_hermit_drowsy_tacklesketch",
    "oceanfishinglure_hermit_heavy_tacklesketch",
    "oceanfishinglure_hermit_rain_tacklesketch",
    "oceanfishinglure_hermit_snow_tacklesketch",
    "oceanfishingbobber_ball_tacklesketch",
    "oceanfishingbobber_oval_tacklesketch",
    "oceanfishingbobber_crow_tacklesketch",
    "oceanfishingbobber_robin_tacklesketch",
    "oceanfishingbobber_robin_winter_tacklesketch",
    "oceanfishingbobber_canary_tacklesketch",
    "oceanfishingbobber_goose_tacklesketch",
    "oceanfishingbobber_malbatross_tacklesketch",
    --萝卜鼠
    "yotc_carrat_scale_item",
    "yotc_carrat_gym_speed_item",
    "yotc_carrat_gym_reaction_item",
    "yotc_carrat_gym_stamina_item",
    "yotc_carrat_gym_direction_item",
    "yotc_carrat_race_start_item",
    "yotc_carrat_race_checkpoint_item",
    "yotc_carrat_race_finish_item",
    --皮弗娄牛
    "yotb_pattern_fragment_1",
    "yotb_pattern_fragment_2",
    "yotb_pattern_fragment_3",
    "yotb_post_item",
    "yotb_sewingmachine_item",
    "yotb_stage_item",
    "beefalo_groomer_item"
}

-- 有价值的物品（其实材料和道具也会有更珍贵的）
local valuableItemList = {
    -- 六色宝石
    "redgem",
    "orangegem",
    "yellowgem",
    "greengem",
    "bluegem",
    "purplegem",

    -- 几种魔杖，将唤月移至珍贵物品
    "firestaff",
    "orangestaff",
    "yellowstaff",
    "greenstaff",
    "icestaff",
    "telestaff",



    -- 六色护符
    "amulet",
    "orangeamulet",
    "yellowamulet",
    "greenamulet",
    "blueamulet",
    "purpleamulet",
}
-- 珍贵物品
local rareItemList = {
    -- 彩虹宝石
    "opalpreciousgem",
    -- 唤月魔杖
    "opalstaff",
    -- 曼德拉草
    "mandrake",
    -- 启迪之冠
    "alterguardianhat",
    -- 黄油
    --"butter",
    -- 白骨头盔
    "skeletonhat",
    -- 骨甲
    "armorskeleton",
    -- 浴血战鞍
    "saddle_war",
    -- 闪亮战鞍
    "saddle_race",
    -- 铥矿棒
    "ruins_bat",
    -- 铥矿冠
    "ruinshat",
    -- 铥矿甲
    "armorruins",
    -- 刺耳三叉戟
    "trident",
    -- 天文护目镜
    "moonstorm_goggleshat",
    -- 坎普斯背包
    "krampus_sack", --背包无法放入物品栏，后续也无法扔到垃圾洞里销毁

    -- 奇特的照明
    -- 红灯笼
    "redlantern",
    -- 漂浮灯笼
    "miniboatlantern",
}


-- c_give("lightflier",1)


-- 这里必须返回一个table,不能多个返回值
-- 因为require的原理,避免重复加载,保存在package.loaded[name] = require(path)
-- 多个返回值只能接收到第一个
return {festivalItemList = festivalItemList , materialItemList = materialItemList , propItemList = propItemList, valuableItemList = valuableItemList , rareItemList = rareItemList}