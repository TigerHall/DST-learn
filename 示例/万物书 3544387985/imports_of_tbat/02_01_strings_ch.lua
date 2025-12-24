---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    文本库

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TBAT.STRINGS = TBAT.STRINGS or {}

TBAT.STRINGS["ch"] = TBAT.STRINGS["ch"] or {
      ---------------------------------------------------------------------------------------
      -- others 
            ["test_prefab"] = {
                  ["name"] = "测试",
                  ["inspect_str"] = "测试描述",
                  ["recipe_desc"] = "制作栏描述",
                  ["info"] = {
                        ["warning"] = "这是一个测试警告",
                        ["tip"] = {
                              [1] = "这是一个测试提示 1",
                              [2] = "这是一个测试提示 2",
                        },
                        ["error"] = {
                              ["error_1"] = "这是一个测试错误 1",
                              ["error_2"] = "这是一个测试错误 2",
                        }
                  
                  },
            },
            ["recipe_name"] = {
                  ["main"] = "万物书",
                  ["building"] = "万物书-建筑",
                  ["decoration"] = "万物书-装饰",
                  ["item"] = "万物书-道具",
            },        
      ---------------------------------------------------------------------------------------
      -- 00_tbat_others
            -- "test_item"	, 							--- 测试物品
      ---------------------------------------------------------------------------------------
      -- 01_tbat_items
            ["tbat_item_butterfly_wrapping_paper"] = {
                  ["name"] = "蝴蝶打包纸",
                  ["inspect_str"] = "你要带我去远方嘛？~",
                  ["recipe_desc"] = "你要带我去远方嘛？~",
            },
            ["tbat_item_butterfly_wrapped_pack"] = {
                  ["name"] = "蝴蝶包裹住的",
                  ["inspect_str"] = "蝴蝶包裹~",
                  ["safe_mod_error"] = "打包的安全模式不对，请在设置里切换",
            },
            ["tbat_item_holo_maple_leaf"] = {
                  ["name"] = "留影枫叶",
                  ["inspect_str"] = "为你留住你想看到的景象",
                  ["action_str"] = "记录",
            },
            ["tbat_item_holo_maple_leaf_packed"] = {
                  ["name"] = "留影枫叶:",
                  ["inspect_str"] = "已经记录了影像",
            },
            ["tbat_item_holo_maple_leaf_packed_building"] = {
                  ["name"] = "枫叶残影",
                  ["inspect_str"] = "来自枫叶记录的影像",
            },
            ["tbat_item_jellyfish_in_bottle"] = {
                  ["name"] = "伴生水母素",
                  ["inspect_str"] = "蒲公英猫猫需要它的陪伴",
                  ["item_fail"] = "猫猫已经有水母陪伴了",
            },
            ["tbat_item_maple_squirrel_kit"] = {
                  ["name"] = "枫叶鼠鼠",
                  ["inspect_str"] = "主人，崽崽冷冷要贴贴",
                  ["recipe_desc"] = "崽崽冷冷要贴贴",
            },
            ["tbat_item_maple_squirrel"] = {
                  ["name"] = "枫叶鼠鼠",
                  ["inspect_str"] = "大家一起贴贴",
            },
            ["tbat_item_snow_plum_wolf_kit"] = {
                  ["name"] = "梅雪小狼",
                  ["inspect_str"] = "我愿意在夜晚为你指路，我的主人",
                  ["recipe_desc"] = "我愿意在夜晚为你指路，我的主人",
            },
            ["tbat_item_snow_plum_wolf"] = {
                  ["name"] = "梅雪小狼",
                  ["inspect_str"] = "我愿意在夜晚为你指路，我的主人",
            },
            ["tbat_item_trans_core"] = {
                  ["name"] = "传送核心",
                  ["inspect_str"] = "它将带我找到家的方向",
                  ["recipe_desc"] = "它将带我找到家的方向",
            },
            ["tbat_item_blueprint"] = {
                  ["name"] = "蓝图",
                  ["inspect_str"] = "这是来自万物书的专属蓝图",
                  ["recipe_desc"] = "这是来自万物书的专属蓝图",
            },
            ["tbat_item_notes_of_adventurer"] = {
                  ["name"] = "冒险家笔记",
                  ["inspect_str"] = "冒险家笔记",
            },
            ["tbat_item_notes_of_adventurer_1"] = {
                  ["name"] = "冒险家笔记 : 1",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "这是她的字迹！你可以念给我听嘛？我有些东西可以送你",
            },
            ["tbat_item_notes_of_adventurer_2"] = {
                  ["name"] = "冒险家笔记 : 2",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "原来是这样……是新奇的生物呢",
            },
            ["tbat_item_notes_of_adventurer_3"] = {
                  ["name"] = "冒险家笔记 : 3",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "原来是这样……是新奇的生物呢",
            },
            ["tbat_item_notes_of_adventurer_4"] = {
                  ["name"] = "冒险家笔记 : 4",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "这是她希望看到的吗？确实令人着迷",
            },
            ["tbat_item_notes_of_adventurer_5"] = {
                  ["name"] = "冒险家笔记 : 5",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "这是她希望看到的吗？确实令人着迷",
            },
            ["tbat_item_notes_of_adventurer_6"] = {
                  ["name"] = "冒险家笔记 : 6",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "可爱的小家伙，可惜枫叶太红了，让人分辨不清其他色彩",
            },
            ["tbat_item_notes_of_adventurer_7"] = {
                  ["name"] = "冒险家笔记 : 7",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "可爱的小家伙，可惜枫叶太红了，让人分辨不清其他色彩",
            },
            ["tbat_item_notes_of_adventurer_8"] = {
                  ["name"] = "冒险家笔记 : 8",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "可爱的小家伙，可惜枫叶太红了，让人分辨不清其他色彩",
            },
            ["tbat_item_notes_of_adventurer_9"] = {
                  ["name"] = "冒险家笔记 : 9",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "亡灵的地方吗……它亦是真实的吗……",
            },
            ["tbat_item_notes_of_adventurer_10"] = {
                  ["name"] = "冒险家笔记 : 10",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "亡灵的地方吗……它亦是真实的吗……",
            },
            ["tbat_item_notes_of_adventurer_11"] = {
                  ["name"] = "冒险家笔记 : 11",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "所谓重生不过幻影，逝者已非故我……",
            },
            ["tbat_item_notes_of_adventurer_12"] = {
                  ["name"] = "冒险家笔记 : 12",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "所谓重生不过幻影，逝者已非故我……",
            },
            ["tbat_item_notes_of_adventurer_13"] = {
                  ["name"] = "冒险家笔记 : 13",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "所谓重生不过幻影，逝者已非故我……",
            },
            ["tbat_item_notes_of_adventurer_14"] = {
                  ["name"] = "冒险家笔记 : 14",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "所谓重生不过幻影，逝者已非故我……",
            },
            ["tbat_item_notes_of_adventurer_15"] = {
                  ["name"] = "冒险家笔记 : 15",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "锋芒之下的温柔，让人沉溺",
            },
            ["tbat_item_notes_of_adventurer_16"] = {
                  ["name"] = "冒险家笔记 : 16",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "锋芒之下的温柔，让人沉溺",
            },
            ["tbat_item_notes_of_adventurer_17"] = {
                  ["name"] = "冒险家笔记 : 17",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "像是活在一场温馨的梦里",
            },
            ["tbat_item_notes_of_adventurer_18"] = {
                  ["name"] = "冒险家笔记 : 18",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "像是活在一场温馨的梦里",
            },
            ["tbat_item_notes_of_adventurer_19"] = {
                  ["name"] = "冒险家笔记 : 19",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "谜局中穿梭，幻觉如荒诞的呓语",
            },
            ["tbat_item_notes_of_adventurer_20"] = {
                  ["name"] = "冒险家笔记 : 20",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "谜局中穿梭，幻觉如荒诞的呓语",
            },
            ["tbat_item_notes_of_adventurer_21"] = {
                  ["name"] = "冒险家笔记 : 21",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "灵魂有了着落，一切都是真实",
            },
            ["tbat_item_notes_of_adventurer_22"] = {
                  ["name"] = "冒险家笔记 : 22",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "灵魂有了着落，一切都是真实",
            },
            ["tbat_item_notes_of_adventurer_23"] = {
                  ["name"] = "冒险家笔记 : 23",
                  ["inspect_str"] = "这是谁留下的？也许应该问问那只绿色的大鸟",
                  ["traded_str"] = "灵魂有了着落，一切都是真实",
            },
            ["tbat_item_crystal_bubble"] = {
                  ["name"] = "水晶气泡",
                  ["inspect_str"] = "封存着深海气息的泡泡",
            },
            ["tbat_item_crystal_bubble_box"] = {
                  ["name"] = "水晶气泡",
                  ["inspect_str"] = "封存着深海气息的泡泡",
            },
            ["tbat_item_failed_potion"] = {
                  ["name"] = "失败的药剂",
                  ["inspect_str"] = "似乎炼制失败了",
            },
            ["tbat_item_wish_note_potion"] = {
                  ["name"] = "愿望之笺",
                  ["inspect_str"] = "愿望有无数种，但最多的一定是如果。",
            },
            ["tbat_item_wish_note_potion_debuff"] = {
                  ["name"] = "愿望之笺后遗症",
            },
            ["tbat_item_veil_of_knowledge_potion"] = {
                  ["name"] = "知识之纱",
                  ["inspect_str"] = "知识不仅来自于理性也来自虚幻与灵感。",
            },
            ["tbat_item_oath_of_courage_potion"] = {
                  ["name"] = "勇气之誓",
                  ["inspect_str"] = "勇气不只是战斗，更是直面强大。",
            },
            ["tbat_item_lucky_words_potion"] = {
                  ["name"] = "幸运之语",
                  ["inspect_str"] = "字符织就羽衣，掌心绽出幸运的馈赠",
            },
            ["tbat_item_peach_blossom_pact_potion"] = {
                  ["name"] = "桃花之约",
                  ["inspect_str"] = "桃夭与春日缱绻",
            },
            ["atbook_wiki"] = {
                  ["name"] = "万物之书",
                  ["inspect_str"] = "万物书的奇幻世界，此刻为你敞开",
                  ["recipe_desc"] = "万物之书"
            },
            ["atbook_wiki_place"] = {
                  ["name"] = "万物之书",
                  ["inspect_str"] = "万物书的奇幻世界，此刻为你敞开",
                  ["recipe_desc"] = "万物之书"
            },
      ---------------------------------------------------------------------------------------
      -- 02_tbat_materials
            ["tbat_material_miragewood"] = {
                  ["name"] = "幻源木",
                  ["inspect_str"] = "特别的木材，也许可以做一些新奇的家具",
            },
            ["tbat_material_dandelion_umbrella"] = {
                  ["name"] = "蒲公英花伞",
                  ["inspect_str"] = "去往你想去的方向",
                  ["no_target"] = "它飞走了，没带来任何指引",
            },
            ["tbat_material_dandycat"] = {
                  ["name"] = "蒲公英猫猫花朵",
                  ["inspect_str"] = "毛茸茸手感很好",
            },
            ["tbat_material_wish_token"] = {
                  ["name"] = "祈愿牌",
                  ["inspect_str"] = "似乎有念力在流转",
            },
            ["tbat_material_white_plum_blossom"] = {
                  ["name"] = "白梅花",
                  ["inspect_str"] = "是王的象征",
            },
            ["tbat_material_snow_plum_wolf_hair"] = {
                  ["name"] = "狼毛",
                  ["inspect_str"] = "有温度的毛发却带着细碎的寒霜",
            },
            ["tbat_material_snow_plum_wolf_heart"] = {
                  ["name"] = "狼心",
                  ["inspect_str"] = "它仿佛还在我手中跳动",
            },
            ["tbat_material_osmanthus_ball"] = {
                  ["name"] = "桂花球",
                  ["inspect_str"] = "这是小猫猫的玩具嘛~？",
            },
            ["tbat_material_osmanthus_wine"] = {
                  ["name"] = "桂花酒",
                  ["inspect_str"] = "猫咪也会喝酒嘛~？",
            },
            ["tbat_material_emerald_feather"] = {
                  ["name"] = "翠羽鸟的羽毛",
                  ["inspect_str"] = "这是羽毛还是树叶？",
            },
            ["tbat_material_liquid_of_maple_leaves"] = {
                  ["name"] = "枫液",
                  ["inspect_str"] = "似乎是某种粘合剂",
            },
            ["tbat_material_squirrel_incisors"] = {
                  ["name"] = "松鼠牙",
                  ["inspect_str"] = "这是。。松鼠的大金牙？？",
            },
            ["tbat_material_sunflower_seeds"] = {
                  ["name"] = "葵瓜子",
                  ["inspect_str"] = "那只胖嘟嘟的仓鼠最爱的收藏品",
            },
            ["tbat_material_starshard_dust"] = {
                  ["name"] = "星之碎屑",
                  ["inspect_str"] = "星光流转之下凝结的实体，闪闪发光",
            },
            ["tbat_material_four_leaves_clover_feather"] = {
                  ["name"] = "四叶草鹤羽毛",
                  ["inspect_str"] = "风托起幸运的绒毛，轻吻迷途者的眉梢",
            },
            ["tbat_material_lavender_laundry_detergent"] = {
                  ["name"] = "薰衣草洗衣液",
                  ["inspect_str"] = "小猫咪保持香香软软的秘诀，就在其中了喵呜",
            },
            -- ["tbat_material_green_leaf_mushroom"] = {  -- 废弃
            --       ["name"] = "森伞小菇",
            --       ["inspect_str"] = "这个到底是属于真菌？还是植物？",
            -- },
            ["tbat_material_memory_crystal"] = {
                  ["name"] = "记忆水晶",
                  ["inspect_str"] = "把时光磨成星光，藏进水晶的透亮里 ",
            },
      ---------------------------------------------------------------------------------------
      -- 03_tbat_equipments
            ["tbat_eq_fantasy_tool"] = {
                  ["name"] = "幻想工具",
                  ["inspect_str"] = "如果崽崽们能拿着工具给我干活就好了~",
                  ["recipe_desc"] = "如果崽崽们能拿着工具给我干活就好了~",
                  ["hammer_on"] = "锤铲：开",
                  ["hammer_off"] = "锤铲：关",
                  ["skin.2"] = "蝴蝶糖法杖",
                  ["skin.freya_s_wand"] = "芙蕾雅的魔法棒",
                  ["skin.cheese_heart_phantom_butterfly_dining_fork"] = "芝心幻蝶餐叉",
            },
            ["tbat_eq_universal_baton"] = {
                  ["name"] = "万物指挥棒",
                  ["inspect_str"] = "通通向我看过来~",
                  ["recipe_desc"] = "通通向我看过来~",
                  ["item_accept_fail"] = "已经不能继续升级了",
                  ["tbat_eq_universal_baton_3"] = "萌兔指挥杖",
                  ["tbat_eq_universal_baton_2"] = "爱心指挥官",
                  ["skin.snow_cap_rabbit_ice_cream"] = "雪顶兔兔冰淇淋",
                  ["skin.bunny_scepter"] = "芙蕾雅的小兔权杖",
                  ["skin.jade_sword_immortal"] = "玉剑仙",
            },
            ["tbat_eq_shake_cup"] = {
                  ["name"] = "摇摇杯",
                  ["inspect_str"] = "摇一摇，后续还能吨吨吨？",
                  ["recipe_desc"] = "摇一摇，后续还能吨吨吨？",
            },
            ["tbat_eq_world_skipper"] = {
                  ["name"] = "万物穿梭",
                  ["inspect_str"] = "诗和远方它都可以带我去往",
                  ["recipe_desc"] = "诗和远方它都可以带我去往",
                  ["action_str"] = "万物穿梭",
            },
            ["tbat_eq_furrycat_circlet"] = {
                  ["name"] = "猫猫花环",
                  ["inspect_str"] = "散发着桂花香气的花环~",
                  ["recipe_desc"] = "散发着桂花香气的花环~",
                  ["skin.strawberry_bunny"] = "莓语兔兔花冠",
            },
            ["tbat_eq_ray_fish_hat"] = {
                  ["name"] = "鳐鱼帽子",
                  ["inspect_str"] = "风中的帽子旅者",
                  ["recipe_desc"] = "带你见识海洋和陆地的奇妙之处",
                  ["skin.sweetheart_cocoa"] = "甜心可可花环",
            },
            ["tbat_eq_snail_shell_of_mushroom"] = {
                  ["name"] = "小蜗护甲",
                  ["inspect_str"] = "慢一点也没关系，柔软本就是勇气",
                  ["recipe_desc"] = "壳里藏着星光，每一步都是归途",
            },
            ["tbat_eq_jumbo_ice_cream_tub"] = {
                  ["name"] = "吨吨桶",
                  ["inspect_str"] = "举起来，吨吨吨，今天的活力值加满",
                  ["recipe_desc"] = "举起来，吨吨吨，今天的活力值加满",
            },
      ---------------------------------------------------------------------------------------
      -- 04_tbat_foods
            ["tbat_food_hedgehog_cactus_meat"] = {
                  ["name"] = "小仙肉",
                  ["inspect_str"] = "很可口的样子，但这是谁的肉？！",
            },
            ["tbat_food_pear_blossom_petals"] = {
                  ["name"] = "梨花瓣",
                  ["inspect_str"] = "像雪花般的口感",
            },
            ["tbat_food_cherry_blossom_petals"] = {
                  ["name"] = "樱花瓣",
                  ["inspect_str"] = "粉色的云端让人沉溺",
            },
            ["tbat_food_valorbush"] = {
                  ["name"] = "勇者玫瑰",
                  ["inspect_str"] = "我要用它来泡花茶",
            },
            ["tbat_food_crimson_bramblefruit"] = {
                  ["name"] = "绯露莓",
                  ["inspect_str"] = "甜滋滋的野果是陷阱么？",
            },
            ["tbat_food_jellyfish"] = {
                  ["name"] = "死亡的风铃水母",
                  ["inspect_str"] = "嗯？好像缩水了",
            },
            ["tbat_food_jellyfish_dried"] = {
                  ["name"] = "风干的风铃水母",
                  ["inspect_str"] = "像寄居蟹老太太晒的海带干",
            },
            ["tbat_food_raw_meat"] = {
                  ["name"] = "新鲜的肉",
                  ["inspect_str"] = "哪个动物身上的?",
            },
            ["tbat_food_raw_meat_cooked"] = {
                  ["name"] = "烤熟的肉",
                  ["inspect_str"] = "闻起来还不错~",
            },
            ["tbat_food_cocoanut"] = {
                  ["name"] = "椰子肉",
                  ["inspect_str"] = "看起来清甜可口",
            },
            ["tbat_food_lavender_flower_spike"] = {
                  ["name"] = "薰衣草花穗",
                  ["inspect_str"] = "风起时，每一缕香都是未寄的信",
            },
            ["tbat_food_ephemeral_flower"] = {
                  ["name"] = "识之昙花",
                  ["inspect_str"] = "以心为识，昙花一现，是限定的浪漫",
            },
            ["tbat_food_ephemeral_flower_butterfly_wings"] = {
                  ["name"] = "昙花蝴蝶翅膀",
                  ["inspect_str"] = "蝶翼下透过月光",
            },
            ["tbat_food_fantasy_potato"] = {
                  ["name"] = "幻想土豆",
                  ["inspect_str"] = "幻想土豆",
            },
            ["tbat_food_fantasy_potato_cooked"] = {
                  ["name"] = "烤熟的幻想土豆",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
            ["tbat_food_fantasy_potato_seeds"] = {
                  ["name"] = "幻想土豆种子",
                  ["inspect_str"] = "幻想土豆种子",
            },
            ["tbat_food_fantasy_potato_seeds_cooked"] = {
                  ["name"] = "烤熟的幻想土豆种子",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
            ["tbat_food_fantasy_peach"] = {
                  ["name"] = "幻想小桃",
                  ["inspect_str"] = "幻想小桃",
            },
            ["tbat_food_fantasy_peach_cooked"] = {
                  ["name"] = "烤熟的幻想小桃",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
            ["tbat_food_fantasy_peach_seeds"] = {
                  ["name"] = "幻想小桃种子",
                  ["inspect_str"] = "幻想小桃种子",
            },
            ["tbat_food_fantasy_peach_seeds_cooked"] = {
                  ["name"] = "烤熟的幻想小桃种子",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
            ["tbat_food_fantasy_apple"] = {
                  ["name"] = "幻想苹果",
                  ["inspect_str"] = "幻想苹果",
            },
            ["tbat_food_fantasy_apple_cooked"] = {
                  ["name"] = "烤熟的幻想苹果",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
            ["tbat_food_fantasy_apple_seeds"] = {
                  ["name"] = "幻想苹果种子",
                  ["inspect_str"] = "幻想苹果种子",
            },
            ["tbat_food_fantasy_apple_seeds_cooked"] = {
                  ["name"] = "烤熟的幻想苹果种子",
                  ["inspect_str"] = "即便熟了，依然要幻想",
            },
      ---------------------------------------------------------------------------------------
      -- 05_tbat_foods_cooked
            ["tbat_food_cooked_honey_meat_tower"] = {
                  ["name"] = "蜜汁肉肉塔",
                  ["inspect_str"] = "甜蜜蜜汁裹香肉，层层叠叠软萌萌",
                  ["oneat_talk"] = "依九说这一顿肉得配十碗米饭！",
            },
            ["tbat_food_cooked_blossom_roll"] = {
                  ["name"] = "樱花可颂卷",
                  ["inspect_str"] = "浓郁巧克力在酥脆可颂中旋转流淌",
            },
            ["tbat_food_cooked_fairy_hug"] = {
                  ["name"] = "抱抱小仙卷",
                  ["inspect_str"] = "把甜品当 “甜心萌友”",
            },
            ["tbat_food_cooked_rose_whisper_tea"] = {
                  ["name"] = "玫瑰花语茶",
                  ["inspect_str"] = "一壶热气氤氲的浪漫花语",
            },
            ["tbat_food_cooked_apple_snow_sundae"] = {
                  ["name"] = "苹果雪山圣代",
                  ["inspect_str"] = "冰凉雪顶，藏着满满莓果心意",
            },
            ["tbat_food_cooked_berry_rabbit_jelly"] = {
                  ["name"] = "莓果兔兔冻",
                  ["inspect_str"] = "鲜莓与奶冻的奇妙邂逅",
            },
            ["tbat_food_cooked_garden_table_cake"] = {
                  ["name"] = "花园物语蛋糕",
                  ["inspect_str"] = "像是花丛中长出的精致小方块",
            },
            ["tbat_food_cooked_peach_pudding_rabbit"] = {
                  ["name"] = "蜜桃布丁兔",
                  ["inspect_str"] = "软糯布丁遇见粉嫩小兔",
            },
            ["tbat_food_cooked_potato_fantasy_pie"] = {
                  ["name"] = "土豆奇幻派",
                  ["inspect_str"] = "水果与奶香的童话冒险",
            },
            ["tbat_food_cooked_peach_rabbit_mousse"] = {
                  ["name"] = "桃兔花椰慕斯",
                  ["inspect_str"] = "软萌治愈的甜心蛋糕",
            },
            ["tbat_food_cooked_rainbow_rabbit_milkshake"] = {
                  ["name"] = "彩虹兔兔奶昔",
                  ["inspect_str"] = "软萌兔子漂浮在泡泡奶香里",
            },
            ["tbat_food_cooked_forest_garden_roll"] = {
                  ["name"] = "花境森林卷",
                  ["inspect_str"] = "松软卷里藏着缤纷花境",
            },
            ["tbat_food_cooked_flower_bunny_cake"] = {
                  ["name"] = "花兔彩绮蛋糕",
                  ["inspect_str"] = "层层叠叠的梦幻舞台，甜美登场",
            },
            ["tbat_food_cooked_star_sea_jelly_cup"] = {
                  ["name"] = "星海水母冰杯",
                  ["inspect_str"] = "冰凉的玻璃杯里，藏着夏日的缤纷与星星的微笑",
            },
            ["tbat_food_cooked_snow_sheep_sushi"] = {
                  ["name"] = "雪顶绵羊寿司",
                  ["inspect_str"] = "海味的清新裹着米香，顶端点缀着一抹雪色童话",
            },
            ["tbat_food_cooked_forest_dream_bento"] = {
                  ["name"] = "森林梦境便当",
                  ["inspect_str"] = "打开盒子，就是小动物的秘密花园，绿意盎然",
            },
            ["tbat_food_cooked_bear_sun_platter"] = {
                  ["name"] = "小熊阳光拼盘",
                  ["inspect_str"] = "烤得金黄的肉香，像熊熊的拥抱般温暖",
            },
            ["tbat_food_cooked_bamboo_cat_bbq_skewers"] = {
                  ["name"] = "竹香小咪烤串",
                  ["inspect_str"] = "一串一梦，把猫咪的笑意和月光一起串起来",
            },
            ["tbat_food_cooked_flower_whisper_ramen"] = {
                  ["name"] = "花香耳语拉面",
                  ["inspect_str"] = "花瓣与温热的汤底碰撞，就像春天在耳边说秘密",
            },
            ["tbat_food_cooked_cloud_rabbit_steamed_bun"] = {
                  ["name"] = "软绵云兔馒头",
                  ["inspect_str"] = "软绵小兔安睡在月光里，奶香与甜梦交织",
            },
            ["tbat_food_cooked_pink_butterfly_steamed_bun"] = {
                  ["name"] = "粉蝶嘟嘟馍饼",
                  ["inspect_str"] = "酥脆的肉夹馍里裹挟着甜美派对",
            },
            ["tbat_food_cooked_butterfly_dance_rice"] = {
                  ["name"] = "花间蝶舞糯米饭",
                  ["inspect_str"] = "蝴蝶在花间轻轻起舞，糯香四溢",
            },
      ---------------------------------------------------------------------------------------
      -- 06_tbat_containers
            ["tbat_container_pear_cat"] = {
                  ["name"] = "梨花猫猫",
                  ["inspect_str"] = "千树万树梨花开，通通都到我家来。",
                  ["recipe_desc"] = "千树万树梨花开，通通都到我家来。",
                  ["onbuild_talk"] = "月黑之夜它似乎会变身",
                  ["skin.strawberry_jam"] = "草莓比熊",
                  ["skin.pudding"] = "喵喵布丁",
            },
            ["tbat_container_cherry_blossom_rabbit_mini"] = {
                  ["name"] = "樱花兔兔",
                  ["inspect_str"] = "哼，我可是春末的旅行者～！",
                  ["recipe_desc"] = "哼，我可是春末的旅行者～！",
                  ["onbuild_talk"] = "月圆的晚上给它某些喜欢的东西呢",
                  ["skin.icecream"] = "樱花甜筒",
                  ["skin.labubu_colourful_feather"]   =     "拉布布 : 彩羽",
                  ["skin.labubu_skyblue"]             =     "拉布布 : 碧蓝",
                  ["skin.labubu_pink_strawberry"]     =     "拉布布 : 粉莓",
                  ["skin.labubu_flower_bud"]          =     "拉布布 : 花苞",
                  ["skin.labubu_orange"]              =     "拉布布 : 橘暖",
                  ["skin.labubu_white_cherry"]        =     "拉布布 : 棉樱",
                  ["skin.labubu_lemon_yellow"]        =     "拉布布 : 柠光",
                  ["skin.labubu_dream_blue"]          =     "拉布布 : 蔚梦",
                  ["skin.labubu_moon_white"]          =     "拉布布 : 月白",
                  ["skin.labubu_purple_wind"]         =     "拉布布 : 紫岚",
            },
            ["tbat_container_cherry_blossom_rabbit"] = {
                  ["name"] = "樱花兔兔",
                  ["inspect_str"] = "哼，我可是春末的旅行者～！",
            },
            ["tbat_container_emerald_feathered_bird_collection_chest"] = {
                  ["name"] = "翠羽鸟收集箱",
                  ["inspect_str"] = "乘着风为你衔来万物",
                  ["recipe_desc"] = "乘着风为你衔来万物",
                  ["onbuild_talk"] = "一些不需要的记忆就随风逝去吧",
            },
            ["tbat_container_squirrel_stash_box"] = {
                  ["name"] = "鼠鼠囤货箱",
                  ["inspect_str"] = "小强盗的存款都在这里了",
                  ["recipe_desc"] = "小强盗的存款都在这里了",
            },
            ["tbat_container_mushroom_snail_cauldron"] = {
                  ["name"] = "蘑菇小蜗埚",
                  ["inspect_str"] = "菌伞轻摇月光，蜗壳藏满治愈秘语",
                  ["recipe_desc"] = "蜗行的小药炉，熬煮森林的呼吸",
                  ["unlock_info"] = "你已经解锁了配方【 {xxxx} 】",
                  ["cook_fail"] = "哎呀，做失败了，你需要去学会完整的【 {xxxx} 】配方",
                  ["cook_succeed"] = "你制作的【 {xxxx} 】完成了",
            },
            ["tbat_container_lavender_kitty"] = {
                  ["name"] = "薰衣草小猫",
                  ["inspect_str"] = "清理种植小能手，喵呜~",
                  ["recipe_desc"] = "居家必备的万能扫地机器猫",
                  ["fertilization"] = "区域施肥",
                  ["acceptted_announce"] = {"洗刷刷 ~ 洗刷刷 ~ ","快快快，快快快","我要更多 ！","再来一些 "},
            },
            ["tbat_container_little_crane_bird"] = {
                  ["name"] = "小小鹤草箱",
                  ["inspect_str"] = "这是小鸡还是小鸭？",
                  ["recipe_desc"] = "你的草图可都归我管了",
                  ["search_announce"] = {"找呀 ~ 找呀 ~ 找图图 ~ ","我要更多 ！","再来一些 "},
                  ["erasa_announce"] = {"擦呀 ~ 擦呀 ~ 擦 ~","我最喜欢擦这些图纸了 ~"},
            },
      ---------------------------------------------------------------------------------------
      -- 07_tbat_buildings
            ["tbat_the_tree_of_all_things"] = {
                  ["name"] = "万物之树",
                  ["inspect_str"] = "万物之树，万物之源",
            },
            ["tbat_the_tree_of_all_things_kit"] = {
                  ["name"] = "万物之树",
                  ["inspect_str"] = "万物之树，万物之源",
                  ["recipe_desc"] = "万物之树",
            },
            ["tbat_the_tree_of_all_things_vine_maple_squirrel"] = {
                  ["name"] = "秋枫树藤",
                  ["inspect_str"] = "它说 : 我主动给你，你别翻我的屋子了",
            },
            ["tbat_the_tree_of_all_things_vine_snow_plum_chieftain"] = {
                  ["name"] = "梅雪树藤",
                  ["inspect_str"] = "它说 : 本族长是狼，不是狐狸",
            },
            ["tbat_the_tree_of_all_things_vine_osmanthus_cat"] = {
                  ["name"] = "桂猫树藤",
                  ["inspect_str"] = "它说 : 我的桂花是最香的",
            },
            ["tbat_the_tree_of_all_things_vine_mushroom_snail"] = {
                  ["name"] = "蘑菇树藤",
                  ["inspect_str"] = "它说 : 我需要更多的光",
            },
            ["tbat_the_tree_of_all_things_vine_lavender_kitty"] = {
                  ["name"] = "薰衣草树藤",
                  ["inspect_str"] = "它说 : 我需要更多薰衣草洗衣液",
            },
            ["tbat_the_tree_of_all_things_vine_stinkray"] = {
                  ["name"] = "礁石树藤",
                  ["inspect_str"] = "它说 : 我需要更多泡泡和藤壶",
            },
            ["tbat_building_piano_rabbit"] = {
                  ["name"] = "星琴小兔",
                  ["inspect_str"] = "冒险家，我能为你弹奏不同的曲子",
                  ["recipe_desc"] = "冒险家，我能为你弹奏不同的曲子",
                  ["unlock_cmd_info_str"] = "需要给予{ITEM}，解锁{BUILDING}"
            },
            ["tbat_building_sunflower_hamster"] = {
                  ["name"] = "向日葵仓鼠灯",
                  ["inspect_str"] = "吸收阳光为你照亮黑暗！",
                  ["recipe_desc"] = "吸收阳光为你照亮黑暗！",
                  ["onbuild_talk"] = "会长大的小仓鼠",
                  ["skin.gumball_machine"] = "幻羽藤蔓灯",
            },
            ["tbat_building_stump_table"] = {
                  ["name"] = "软木餐桌",
                  ["inspect_str"] = "放上去的食物永远冒着热气",
                  ["recipe_desc"] = "放上去的食物永远冒着热气",
                  ["skin.sunbloom_side_table"] = "向阳茶点桌",
            },
            ["tbat_building_magic_potion_cabinet"] = {
                  ["name"] = "魔法药剂柜",
                  ["inspect_str"] = "这里面放的可都是宝贝",
                  ["recipe_desc"] = "这里面放的可都是宝贝",
                  ["skin.tree_ring_counter"] = "森语奇境",
                  ["skin.ferris_wheel"] = "云朵乐园烘培屋",
                  ["skin.gift_display_rack"] = "星琴礼品架",
                  ["skin.accordion"] = "乐琴旋转展厅",
                  ["skin.dreampkin_hut"] = "南瓜梦境屋",
                  ["skin.grid_cabinet"] = "花木跳趣格",
                  ["skin.puffcap_stand"] = "蘑菇萌趣台",
            },
            ["tbat_building_plum_blossom_table"] = {
                  ["name"] = "梅花餐桌",
                  ["inspect_str"] = "滴溜溜的小眼睛，可不能偷我的菜",
                  ["recipe_desc"] = "滴溜溜的小眼睛，可不能偷我的菜",
                  ["skin.sweetwhim_stand"] = "童话甜品台",
            },
            ["tbat_building_plum_blossom_hearth"] = {
                  ["name"] = "梅花灶台",
                  ["inspect_str"] = "镶嵌着狼族符文的可爱家具",
                  ["recipe_desc"] = "镶嵌着狼族符文的可爱家具",
                  ["skin.abysshell_stand"] = "深海贝壳甜品台",
            },
            ["tbat_building_cherry_blossom_rabbit_swing"] = {
                  ["name"] = "樱兔秋千",
                  ["inspect_str"] = "静心聆听风吹过耳边的声音",
                  ["recipe_desc"] = "静心聆听风吹过耳边的声音",
            },
            ["tbat_building_red_spider_lily_rocking_chair"] = {
                  ["name"] = "彼岸花摇椅",
                  ["inspect_str"] = "喜燥无常，懒且随意",
                  ["recipe_desc"] = "喜燥无常，懒且随意",
            },
            ["tbat_building_rough_cut_wood_sofa"] = {
                  ["name"] = "原木沙发",
                  ["inspect_str"] = "小精灵们说要和我坐一块儿",
                  ["recipe_desc"] = "小精灵们说要和我坐一块儿",
                  ["skin.2"] = "原木蹦蹦椅",
                  ["skin.magic_broom"] = "喵咪魔法扫帚",
                  ["skin.sunbloom"] = "向阳绒布沙发",
                  ["skin.lemon_cookie"] = "香柠甜筒沙发",
            },
            ["tbat_building_whisper_tome_squirrel_phonograph"] = {
                  ["name"] = "梦境物语集",
                  ["inspect_str"] = "它存在的样子是你心底的声音",
                  ["recipe_desc"] = "它存在的样子是你心底的声音",
                  ["skin.1"] = "松鼠留声机",
                  ["skin.spellwisp_desk"] = "幽蓝巫术桌",
                  ["skin.chirpwell"] = "童趣水井亭",
                  ["skin.purr_oven"] = "猫咪烘焙炉",
                  ["skin.swirl_vanity"] = "芙蕾雅の小兔梳妆台",
                  ["skin.birdchime_clock"] = "鸟语时钟",
            },
            ["tbat_building_woodland_lamp"] = {
                  ["name"] = "森林矮灯",
                  ["inspect_str"] = "温和的光线，小心别盯着看太久",
                  ["recipe_desc"] = "温和的光线，小心别盯着看太久",
                  ["skin.starwish"] = "星愿心灯柱",
            },
            ["tbat_building_conch_shell_decoration"] = {
                  ["name"] = "围边海螺贝壳装饰",
                  ["inspect_str"] = "可爱的小贝壳",
                  ["recipe_desc"] = "可爱的小贝壳",
                  ["skin_1"] = "派大星",
                  ["skin_2"] = "普通贝壳",
                  ["skin_3"] = "紫色贝壳",
                  ["skin_4"] = "海螺花",
                  ["skin_5"] = "蜗牛螺",
                  ["skin_6"] = "黄色海星",
            },
            ["tbat_building_conch_shell_decoration_kit"] = {
                  ["name"] = "围边海螺贝壳装饰",
                  ["inspect_str"] = "可爱的小贝壳",
                  ["recipe_desc"] = "可爱的小贝壳",
            },
            ["tbat_building_star_and_cloud_decoration"] = {
                  ["name"] = "围边星星云朵装饰",
                  ["inspect_str"] = "看星星月亮眨眼睛",
                  ["recipe_desc"] = "看星星月亮眨眼睛",
                  ["skin_1"] = "星星",
                  ["skin_2"] = "彩虹星星",
                  ["skin_3"] = "月亮星星",
                  ["skin_4"] = "蓝色云朵",
                  ["skin_5"] = "白色云朵",
                  ["skin_6"] = "包子云",
            },
            ["tbat_building_star_and_cloud_decoration_kit"] = {
                  ["name"] = "围边星星云朵装饰",
                  ["inspect_str"] = "看星星月亮眨眼睛",
                  ["recipe_desc"] = "看星星月亮眨眼睛",
            },
            ["tbat_building_snowflake_decoration"] = {
                  ["name"] = "围边雪花雪人装饰",
                  ["inspect_str"] = "漂亮的小雪花",
                  ["recipe_desc"] = "漂亮的小雪花",
                  ["skin_2"] = "多彩雪花",
                  ["skin_3"] = "精致雪花",
                  ["skin_4"] = "星星雪花",
                  ["skin_5"] = "小雪人",
                  ["skin_6"] = "玻璃球",
            },
            ["tbat_building_snowflake_decoration_kit"] = {
                  ["name"] = "围边雪花雪人装饰",
                  ["inspect_str"] = "漂亮的小雪花",
                  ["recipe_desc"] = "漂亮的小雪花",
            },
            ["tbat_building_cute_pet_stone_figurines"] = {
                  ["name"] = "萌宠小石雕",
                  ["inspect_str"] = "这样就能一直陪着我了，对吗？",
                  ["recipe_desc"] = "这样就能一直陪着我了，对吗？",
                  ["skin_2"] = "水母",
                  ["skin_3"] = "呆猫",
                  ["skin_4"] = "狐狸",
                  ["skin_5"] = "枫叶",
            },
            ["tbat_building_cute_pet_stone_figurines_kit"] = {
                  ["name"] = "萌宠小石雕",
                  ["inspect_str"] = "这样就能一直陪着我了，对吗？",
                  ["recipe_desc"] = "这样就能一直陪着我了，对吗？",
            },
            ["tbat_building_cute_animal_decorative_figurines"] = {
                  ["name"] = "萌宠装饰雕像",
                  ["inspect_str"] = "上次遇见，它还和我打招呼呢",
                  ["recipe_desc"] = "上次遇见，它还和我打招呼呢",
                  ["skin_1"] = "兔兔",
                  ["skin_2"] = "翠羽鸟",
                  ["skin_3"] = "萌兔",
                  ["skin_4"] = "四叶草鹤",
            },
            ["tbat_building_cute_animal_decorative_figurines_kit"] = {
                  ["name"] = "萌宠装饰雕像",
                  ["inspect_str"] = "上次遇见，它还和我打招呼呢",
                  ["recipe_desc"] = "上次遇见，它还和我打招呼呢",
            },
            ["tbat_building_cute_animal_wooden_figurines"] = {
                  ["name"] = "萌宠装饰木桩",
                  ["inspect_str"] = "有了你们就不孤单啦！",
                  ["recipe_desc"] = "有了你们就不孤单啦！",
                  ["skin_1"] = "一家三口",
                  ["skin_2"] = "兔子树桩",
                  ["skin_3"] = "粉兔树桩",
            },
            ["tbat_building_cute_animal_wooden_figurines_kit"] = {
                  ["name"] = "萌宠装饰木桩",
                  ["inspect_str"] = "有了你们就不孤单啦！",
                  ["recipe_desc"] = "有了你们就不孤单啦！",
            },
            ["tbat_building_carved_stone_tiles"] = {
                  ["name"] = "石雕台阶",
                  ["inspect_str"] = "它们说，怕我隔到脚",
                  ["recipe_desc"] = "它们说，怕我隔到脚",
                  ["skin_2"] = "圆台",
                  ["skin_3"] = "猫头",
                  ["skin_4"] = "小猫",
                  ["skin_5"] = "大猫爪",
                  ["skin_6"] = "小猫爪",
            },
            ["tbat_building_carved_stone_tiles_kit"] = {
                  ["name"] = "石雕台阶",
                  ["inspect_str"] = "它们说，怕我隔到脚",
                  ["recipe_desc"] = "它们说，怕我隔到脚",
            },
            ["wall_tbat_wood"] = {
                  ["name"] = "梅花木墙",
                  ["inspect_str"] = "我站在风中，寻觅梅花的香气",
                  ["recipe_desc"] = "我站在风中，寻觅梅花的香气",
            },
            ["wall_tbat_wood_item"] = {
                  ["name"] = "梅花木墙",
                  ["inspect_str"] = "我站在风中，寻觅梅花的香气",
                  ["recipe_desc"] = "我站在风中，寻觅梅花的香气",
            },
            ["wall_tbat_maple"] = {
                  ["name"] = "枫叶草墙",
                  ["inspect_str"] = "听，我正在演奏秋天",
                  ["recipe_desc"] = "被火红枫叶覆盖的草墙，像秋天般温暖",
            },
            ["wall_tbat_maple_item"] = {
                  ["name"] = "枫叶草墙",
                  ["inspect_str"] = "听，我正在演奏秋天",
                  ["recipe_desc"] = "被火红枫叶覆盖的草墙，像秋天般温暖",
            },
            ["wall_tbat_osmanthus_stone"] = {
                  ["name"] = "桂花石墙",
                  ["inspect_str"] = "石块间缠绕着金色桂花，散发淡淡甜香",
                  ["recipe_desc"] = "石块间缠绕着金色桂花，散发淡淡甜香",
            },
            ["wall_tbat_osmanthus_stone_item"] = {
                  ["name"] = "桂花石墙",
                  ["inspect_str"] = "石块间缠绕着金色桂花，散发淡淡甜香",
                  ["recipe_desc"] = "石块间缠绕着金色桂花，散发淡淡甜香",
                  ["skin.strawberry_cream_cake"] = "草莓奶芙蛋糕",
                  ["skin.coral_reef"] = "星贝珊瑚礁柱",
            },
            ["tbat_building_recruitment_notice_board"] = {
                  ["name"] = "招募栏",
                  ["inspect_str"] = "感谢游玩万物书～欢迎加入Q群：1049427294",
                  ["recipe_desc"] = "debug",
            },
            ["tbat_building_trade_notice_board"] = {
                  ["name"] = "交易栏",
                  ["inspect_str"] = "感谢游玩万物书～欢迎加入Q群：1049427294",
                  ["recipe_desc"] = "debug",
            },
            ["tbat_building_pet_house_common"] = {
                  ["start_follow_player"] = "领养这一只",
                  ["stop_follow_player"] = "归还宠物",
                  ["give_back_item_fail"] = "没有可归还的宠物",
                  ["house_full"] = "这里已经住满了",
            },
            ["tbat_building_snow_plum_pet_house"] = {
                  ["name"] = "梅雪木屋",
                  ["inspect_str"] = "散发着淡淡梅花香气",
                  ["recipe_desc"] = "散发着淡淡梅花香气",
            },
            ["tbat_building_osmanthus_cat_pet_house"] = {
                  ["name"] = "桂猫石屋",
                  ["inspect_str"] = "浓郁的桂花香气，让人心旷神怡",
                  ["recipe_desc"] = "浓郁的桂花香气，让人心旷神怡",
            },
            ["tbat_building_osmanthus_cat_pet_house_wild"] = {
                  ["name"] = "野外的桂猫石屋",
                  ["inspect_str"] = "浓郁的桂花香气，让人心旷神怡",
            },
            ["tbat_building_maple_squirrel_pet_house"] = {
                  ["name"] = "秋枫树屋",
                  ["inspect_str"] = "里面有一只会上蹿下跳的可爱生物",
                  ["recipe_desc"] = "秋枫之森，这里是枫叶松鼠的故乡",
            },
            ["tbat_building_maple_squirrel_pet_house_wild"] = {
                  ["name"] = "野外的秋枫树屋",
                  ["inspect_str"] = "秋枫之森，这里是枫叶松鼠的故乡",
                  ["work_succeed"] = "emmmm , 我这算在掏它的兜兜？",
                  ["work_night"] = "现在不是时候",
                  ["work_fail"] = "小强盗的名字应该给你！",
            },
            ["tbat_building_fantasy_shop"] = {
                  ["name"] = "瑶瑶奶悉的设计屋",
                  ["inspect_str"] = "店铺装修中，请攒够五百万再来",
            },
            ["tbat_building_cloud_wooden_sign"] = {
                  ["name"] = "云朵小木牌",
                  ["inspect_str"] = "嘿，走这边才对",
                  ["recipe_desc"] = "软绵绵的小木牌像飘来的云朵",
                  ["skin_1"] = "休息区",
                  ["skin_2"] = "卫生间",
                  ["skin_3"] = "小窝",
                  ["skin_4"] = "牧场",
                  ["skin_5"] = "厨房",
                  ["skin_6"] = "餐厅",
                  ["skin_7"] = "痴若离",
            },
            ["tbat_building_kitty_wooden_sign"] = {
                  ["name"] = "喵喵指示牌",
                  ["inspect_str"] = "喵喵~跟你走准没错",
                  ["recipe_desc"] = "挂着猫咪图案的小木牌，尾巴像箭头一样指路",
                  ["skin_1"] = "储物区",
                  ["skin_2"] = "科技区",
                  ["skin_3"] = "大别墅",
                  ["skin_4"] = "动物园",
                  ["skin_5"] = "观光区",
                  ["skin_6"] = "幻想岛",
                  ["skin_7"] = "展览馆",
                  ["skin_8"] = "种植园",
                  ["skin_9"] = "花花の",
                  ["skin_10"] = "阿茗の小屋",
                  ["skin_11"] = "阿瑶の小屋",
                  ["skin_12"] = "等秋零小屋",
                  ["skin_13"] = "芙蕾雅小屋",
            },
            ["tbat_building_bunny_wooden_sign"] = {
                  ["name"] = "兔影花木牌",
                  ["inspect_str"] = "蹦蹦跳跳~欢迎光临兔兔家",
                  ["recipe_desc"] = "木牌边缘点缀着花草，兔子的身影跃然其上",
                  ["skin_1"] = "剧院",
                  ["skin_2"] = "工厂",
                  ["skin_3"] = "农场",
                  ["skin_4"] = "集市",
                  ["skin_5"] = "花园",
                  ["skin_6"] = "兔兔",
                  ["skin_7"] = "雅集",
            },
            ["tbat_building_time_fireplace"] = {
                  ["name"] = "时光壁炉",
                  ["inspect_str"] = "坐下吧，我偷偷给你讲故事",
                  ["recipe_desc"] = "古老的壁炉闪着橙红火光，仿佛藏着旧日故事",
                  ["skin_with_flower"] = "花花装饰",
            },
            ["tbat_building_chesspiece_display_stand"] = {
                  ["name"] = "雕像展示台",
                  ["inspect_str"] = "嘘，这里的主角正在摆姿势呢",
                  ["recipe_desc"] = "高高的底座上矗立着雕像，庄重又静谧",
                  ["display"] = "展示台 : ",
            },
            ["tbat_building_green_campanula_with_cat"] = {
                  ["name"] = "发光的路灯花",
                  ["inspect_str"] = "为夜归人指引方向",
                  ["recipe_desc"] = "一朵在夜里绽放的灯花，花瓣温柔闪亮",
            },
            ["tbat_building_twin_goslings"] = {
                  ["name"] = "双生小鹅灯",
                  ["inspect_str"] = "它们是形影不离的好伙伴",
                  ["recipe_desc"] = "月牙环绕花藤，双鹅依偎，暖光梦幻又治愈",
            },
            ["tbat_building_lamp_moon_with_clouds"] = {
                  ["name"] = "花语云梦灯",
                  ["inspect_str"] = "闭上眼，听花儿悄悄讲梦话",
                  ["recipe_desc"] = "月亮形的灯饰缠绕着花语，梦幻如星光",
                  ["skin.starwish"] = "荧星彩云灯",
                  ["skin.sleeping_kitty"] = "月眠喵梦灯",
            },
            ["tbat_building_pot_animals_with_flowers"] = {
                  ["name"] = "萌宠装饰盆栽",
                  ["inspect_str"] = "每天看着它心情都会变好",
                  ["recipe_desc"] = "小巧的盆栽里探出萌萌的绿植，像小宠物般灵动",
                  ["skin.verdant_grove"] = "翠意绿植",
                  ["skin.bunny_cart"] = "花车萌趣",
                  ["skin.dreambloom_vase"] = "紫梦花瓶",
                  ["skin.foxglean_basket"] = "狐趣果篮",
                  ["skin.lavendream"] = "紫韵小花",
                  ["skin.cloudlamb_vase"] = "羊咩云花",
            },
            ["tbat_building_forest_mushroom_cottage"] = {
                  ["name"] = "森林蘑菇小窝",
                  ["inspect_str"] = "月光缝制的童话，住进蘑菇的柔软里",
                  ["recipe_desc"] = "月光缝制的童话，住进蘑菇的柔软里",
            },
            ["tbat_building_forest_mushroom_cottage_wild"] = {
                  ["name"] = "野外的森林蘑菇小窝",
                  ["inspect_str"] = "月光缝制的童话，住进蘑菇的柔软里",
                  ["recipe_desc"] = "月光缝制的童话，住进蘑菇的柔软里",
                  ["item_accepted.tbat_sensangu_item"] = "它会永远保护我们~",
                  ["item_accepted.tbat_item_oath_of_courage_potion"] = "冒险家你要保护好自己。",
                  ["item_accepted.tbat_item_veil_of_knowledge_potion"] = "覆纱的眼，看见万物低语。",
                  ["item_accepted.tbat_item_wish_note_potion"] = "愿望藏进信笺，你要走向星光。",
                  ["item_accepted.tbat_item_lucky_words_potion"] = "命运温柔的笔迹，把幸运馈赠给你们。",
            },
            ["tbat_building_four_leaves_clover_crane_lv1"] = {
                  ["name"] = "四叶草鹤雕像",
                  ["inspect_str"] = "需要什么能让其复苏呢？",
                  ["recipe_desc"] = "一个神奇的好运雕像",
                  ["accept_info"] = "某些家伙的羽毛",
                  ["not_full_moon_night"] = "貌似时机不对",
            },
            ["tbat_building_four_leaves_clover_crane_lv2"] = {
                  ["name"] = "四叶草鹤雕像",
                  ["inspect_str"] = "自然的祈愿站",
                  ["touch_action"] = "触摸四叶草",
                  ["touch_same_day"] = "今天已经被祝福过了",
                  ["touch_succeed_announce"] = "愿四叶草祝福你",
                  ["take_care_pet"] = "希望能带来足够的好运 ~ ",
            },
            ["tbat_building_lavender_flower_house_wild"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["name.pet"] = "野生的薰衣草猫猫",
                  ["mission_finished_announce"] = "哇哦 ~ 装饰得更漂亮了 ~ 新的任务进度为 {XXXX} , 请继续努力 ~",
                  ["mission_finished_announce.1"] = "哼，不要以为这样我就会和你回去！【 任务进度 1 / 5 】",
                  ["mission_finished_announce.2"] = "我很喜欢这个植物！冒险家！【 任务进度 2 / 5 】",
                  ["mission_finished_announce.3"] = "哇，装饰的更漂亮了，像花海一样 ！ 【 任务进度 3 / 5 】",
                  ["mission_finished_announce.4"] = "我想我们是好朋友了！冒险家！ 【 任务进度 4 / 5 】",
                  ["mission_finished_announce.5"] = "这是送你的礼物，我想我可以去你家里坐坐 【 任务完成 5 / 5 ，开启下一轮】",
                  ["action_button_str"] = "装修",
                  ["action_start_str"] = "装修",
                  ["action_stop_str"] = "停止装修",
            },
            ["tbat_building_lavender_flower_house_wild_lv1"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["inspect_str"] = "玻璃花房里藏着一只慵懒的小猫",
            },
            ["tbat_building_lavender_flower_house_wild_lv2"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["inspect_str"] = "玻璃花房里藏着一只慵懒的小猫",
            },
            ["tbat_building_lavender_flower_house_wild_lv3"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["inspect_str"] = "玻璃花房里藏着一只慵懒的小猫",
            },
            ["tbat_building_lavender_flower_house_wild_lv4"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["inspect_str"] = "玻璃花房里藏着一只慵懒的小猫",
            },
            ["tbat_building_lavender_flower_house_wild_lv5"] = {
                  ["name"] = "野外的薰衣草花房",
                  ["inspect_str"] = "玻璃花房里藏着一只慵懒的小猫",
            },
            ["tbat_building_lavender_flower_house"] = {
                  ["name"] = "薰衣草花房",
                  ["name.pet"] = "薰衣草猫猫",
                  ["inspect_str"] = "玻璃花房里藏着好些慵懒的小猫",
                  ["recipe_desc"] = "玻璃花房里藏着好些慵懒的小猫",
                  ["action_look_str"] = "查看花房",
                  ["action_pet_back_str"] = "归还宠物",
                  ["container.close"] = "喵喵喵 ~ ",
                  ["give_back_item_fail"] = "猫猫和花花草草都在房子里 ~ ",
            },
            ["tbat_building_reef_lighthouse"] = {
                  ["name"] = "礁石灯塔",
                  ["inspect_str"] = "礁石枕浪而眠，灯塔以温柔航标",
                  ["recipe_desc"] = "可以建造可爱鳐鱼的小窝",
                  ["action_look_str"] = "查看礁石",
                  ["action_pet_back_str"] = "归还宠物",
                  -- ["container.close"] = "喵喵喵 ~ ",
                  -- ["give_back_item_fail"] = "猫猫和花花草草都在房子里 ~ ",
            },
            ["tbat_building_reef_lighthouse_wild"] = {
                  ["name"] = "野外的礁石灯塔",
                  ["inspect_str"] = "礁石枕浪而眠，灯塔以温柔航标",
            },
      ---------------------------------------------------------------------------------------
      -- 08_tbat_resources
            ["tbat_resource_river_pebble"] = {
                  ["name"] = "河边石子",
                  ["inspect_str"] = "我每天都在听河水唱歌",
                  ["skin_2"] = "青苔",
                  ["skin_3"] = "低矮",
                  ["skin_4"] = "红珊瑚",
                  ["skin_5"] = "高个",
                  ["skin_6"] = "多姿珊瑚",
            },
            ["tbat_resource_river_pebble_item"] = {
                  ["name"] = "河边石子",
                  ["inspect_str"] = "我每天都在听河水唱歌",
                  ["recipe_desc"] = "圆润的小石子安静躺在河岸，微微泛光",
            },
            ["tbat_resource_kitty_stone"] = {
                  ["name"] = "花喵小石子",
                  ["inspect_str"] = "小小石头承载着萌芽与花开的生机",
                  ["skin_2"] = "大猫",
                  ["skin_3"] = "碎石",
                  ["skin_4"] = "小草石",
                  ["skin_5"] = "大草石",
            },
            ["tbat_resource_kitty_stone_item"] = {
                  ["name"] = "花喵小石子",
                  ["inspect_str"] = "小小石头承载着萌芽与花开的生机",
                  ["recipe_desc"] = "每一颗都圆滚滚、软乎乎",
            },
            ["tbat_resources_memory_crystal_ore_1"] = {
                  ["name"] = "记忆水晶矿",
                  ["inspect_str"] = "记忆的闪回是瞬间也是永恒",
            },
            ["tbat_resources_memory_crystal_ore_2"] = {
                  ["name"] = "记忆水晶矿",
                  ["inspect_str"] = "记忆的闪回是瞬间也是永恒",
            },
            ["tbat_resources_memory_crystal_ore_3"] = {
                  ["name"] = "记忆水晶矿",
                  ["inspect_str"] = "记忆的闪回是瞬间也是永恒",
            },
            ["tbat_resources_memory_crystal_ore_core"] = {
                  ["name"] = "记忆水晶矿心",
                  ["inspect_str"] = "可以用以移植记忆水晶矿源",
            },
      ---------------------------------------------------------------------------------------
      -- 09_tbat_plants
            ["tbat_plant_wild_hedgehog_cactus"] = {
                  ["name"] = "刺猬小仙",
                  ["inspect_str"] = "咕噜咕噜滚滚仙人",
            },
            ["tbat_plant_hedgehog_cactus_seed"] = {
                  ["name"] = "小仙种子",
                  ["inspect_str"] = "毛毛的，刺刺的，但…有点可爱",
            },
            ["tbat_plant_hedgehog_cactus_pot"] = {
                  ["name"] = "万物盆栽(小仙)",
                  ["inspect_str"] = "这里缺一只特殊的刺猬",
                  ["recipe_desc"] = "这里缺一只特殊的刺猬",
            },
            ["tbat_plant_hedgehog_cactus"] = {
                  ["name"] = "刺猬小仙盆栽",
                  ["inspect_str"] = "我一定可以照顾好它们！",
            },
            ["tbat_plant_coconut_tree"] = {
                  ["name"] = "清甜椰子树",
                  ["inspect_str"] = "这是小猫的猫爬架么？",
            },
            ["tbat_plant_coconut_cat_fruit"] = {
                  ["name"] = "清甜椰子",
                  ["inspect_str"] = "怎么样让这只小猫咪下来呢？",
            },
            ["tbat_plant_coconut_tree_seed"] = {
                  ["name"] = "发芽的清甜椰子",
                  ["inspect_str"] = "可以种植清甜椰子树",
            },
            ["tbat_plant_coconut_cat_kit"] = {
                  ["name"] = "椰子猫猫",
                  ["inspect_str"] = "摇头晃脑的小猫咪~~",
            },
            ["tbat_plant_coconut_cat"] = {
                  ["name"] = "椰子猫猫",
                  ["inspect_str"] = "摇头晃脑的小猫咪~~",
            },
            ["tbat_plant_pear_blossom_tree"] = {
                  ["name"] = "梨花树",
                  ["inspect_str"] = "海棠未雨，梨花先雪",
            },
            ["tbat_plant_pear_blossom_tree_kit"] = {
                  ["name"] = "梨花树苗",
                  ["inspect_str"] = "海棠未雨，梨花先雪",
            },
            ["tbat_plant_cherry_blossom_tree"] = {
                  ["name"] = "樱花树",
                  ["inspect_str"] = "落樱是春天的第一场雨",
            },
            ["tbat_plant_cherry_blossom_tree_kit"] = {
                  ["name"] = "樱花树苗",
                  ["inspect_str"] = "落樱是春天的第一场雨",
            },
            ["tbat_plant_crimson_maple_tree"] = {
                  ["name"] = "秋枫树",
                  ["inspect_str"] = "秋日里的枫叶看上去暖洋洋的",
            },
            ["tbat_plant_crimson_maple_tree_kit"] = {
                  ["name"] = "秋枫树苗",
                  ["inspect_str"] = "它能长出火红的枫叶",
            },
            ["tbat_plant_valorbush"] = {
                  ["name"] = "勇者玫瑰灌木",
                  ["inspect_str"] = "烈焰燃烧于心，握紧手中的勇气",
            },
            ["tbat_plant_valorbush_kit"] = {
                  ["name"] = "玫瑰植株",
                  ["inspect_str"] = "美丽的东西，我要带回家",
            },
            ["tbat_plant_crimson_bramblefruit"] = {
                  ["name"] = "绯露莓刺藤",
                  ["inspect_str"] = "无畏将凝结成赤红的果实",
            },
            ["tbat_plant_crimson_bramblefruit_kit"] = {
                  ["name"] = "刺藤植株",
                  ["inspect_str"] = "棘手的植物但没准可以饱腹？",
            },
            ["tbat_plant_lavender_bush"] = {
                  ["name"] = "薰衣草草丛",
                  ["inspect_str"] = "等待猫猫的出现",
            },
            ["tbat_plant_lavender_bush_kit"] = {
                  ["name"] = "干枯的薰衣草草丛",
                  ["inspect_str"] = "薰衣草草丛，能种出可爱的猫猫",
            },
            ["tbat_plant_osmanthus_bush"] = {
                  ["name"] = "桂花矮树",
                  ["inspect_str"] = "桂花矮树在这，桂花猫猫呢？",
            },
            ["tbat_plant_osmanthus_bush_kit"] = {
                  ["name"] = "干枯的桂花矮树",
                  ["inspect_str"] = "桂花矮树苗",
            },
            ["tbat_plant_dandycat"] = {
                  ["name"] = "蒲公英猫猫",
                  ["inspect_str"] = "它在邀请我与其一起探索世界",
            },
            ["tbat_plant_dandycat_kit"] = {
                  ["name"] = "蒲公英猫植株",
                  ["inspect_str"] = "风的旅人，随风而动",
            },
            ["tbat_projectile_dandelion_umbrella"] = {
                  ["name"] = "蒲公英花伞",
                  ["inspect_str"] = "为你打开心中的迷雾",
            },
            ["tbat_plant_jellyfish"] = {
                  ["name"] = "风铃水母",
                  ["inspect_str"] = "蒲公英猫的好朋友",
                  ["random_talk"] = {"蒲公英猫你知道吗，你是我在这个世界最好的朋友","蒲公英猫你说，会有冒险家找到我们吗？"},
                  ["player_close"] = {"蒲公英猫你看，是冒险家！","冒险家，你可以向我祈愿！"},
                  ["item_fail"] = "这家伙好像不打算给我东西",
            },
            ["tbat_plant_kitty_cattail"] = {
                  ["name"] = "喵蒲装饰草丛",
                  ["inspect_str"] = "喵喵~这是猫咪的秘密游乐园",
                  ["recipe_desc"] = "像蒲草一样的装饰丛中，藏着小猫咪的足迹",
                  ["skin_2"] = "躲",
                  ["skin_3"] = "冒泡",
                  ["skin_4"] = "围观",
                  ["skin_5"] = "一起",
                  ["skin_6"] = "叠叠乐",
                  ["skin_7"] = "强制围观",
            },
            ["tbat_plant_kitty_bush"] = {
                  ["name"] = "猫猫草墩",
                  ["inspect_str"] = "扑通~跳上来坐会儿嘛",
                  ["recipe_desc"] = "柔软的草墩上，印着可爱的猫爪纹",
                  ["skin_2"] = "强势围观",
                  ["skin_3"] = "讨论",
                  ["skin_4"] = "叠叠乐",
                  ["skin_5"] = "花花",
                  ["skin_6"] = "仰望",
                  ["skin_7"] = "保护",
                  ["skin_8"] = "贴贴",
                  ["skin_9"] = "背对",
                  ["skin_10"] = "深色",
                  ["skin_11"] = "惬意",
                  ["skin_12"] = "观望",
            },
            ["tbat_plant_water_plants_of_pond"] = {
                  ["name"] = "池边水草",
                  ["inspect_str"] = "小心点，鱼儿在偷偷瞧你",
                  ["recipe_desc"] = "清澈池水边，一簇柔软的水草轻轻摇曳",
            },
            ["tbat_plant_plum_blossom_bush"] = {
                  ["name"] = "梅影装饰花丛",
                  ["inspect_str"] = "盛开的花在风中摇曳",
                  ["recipe_desc"] = "盛开的花在风中摇曳",
                  ["skin.dreambloom"] = "绮梦花丛",
                  ["skin.mistbloom"] = "云雾花丛",
                  ["skin.mosswhisper"] = "绿语苔丛",
                  ["skin.bunnysleep_orchid"] = "兔眠花丛",
                  ["skin.warm_rose"] = "暖樱玫瑰丛",
                  ["skin.spark_rose"] = "星火玫瑰丛",
                  ["skin.luminmist_rose"] = "云光玫瑰丛",
                  ["skin.frostberry_rose"] = "莓霜玫瑰丛",
                  ["skin.stellar_rose"] = "星辰玫瑰丛",
            },
            ["tbat_plant_ephemeral_flower"] = {
                  ["name"] = "识之昙花",
                  ["inspect_str"] = "花瓣里流淌着液态的月光",
            },
            ["tbat_plant_fluorescent_moss"] = {
                  ["name"] = "荧光苔藓",
                  ["inspect_str"] = "荧光苔藓带着软乎乎的光，把平凡角落变成治愈小世界",
            },
            ["tbat_plant_fluorescent_moss_item"] = {
                  ["name"] = "荧光苔藓",
                  ["inspect_str"] = "慢慢来，黑暗里也有温柔相伴",
            },
            ["tbat_plant_fluorescent_mushroom"] = {
                  ["name"] = "发光蘑菇",
                  ["inspect_str"] = "发光蘑菇踮着脚，把夜路照得暖乎乎",
            },
            ["tbat_plant_fluorescent_mushroom_item"] = {
                  ["name"] = "发光蘑菇",
                  ["inspect_str"] = "再暗的路，也有温柔为你领航",
            },
            ["tbat_farm_plant_legin_cluster_sys"] = {
                  --- 植物簇系统使用的相关字符
                  ["action"] = "添加簇",
                  ["display"] = "簇",
                  ["accept_fail"] = "已经成熟了",
                  ["accept_fail.max"] = "已经是最大数量了",
            },
            ["tbat_farm_plant_fantasy_apple"] = {
                  ["name"] = "幻想苹果",
                  ["inspect_str"] = "幻想苹果",
            },
            ["tbat_eq_fantasy_apple_oversized"] = {
                  ["name"] = "巨型苹果狗",
                  ["inspect_str"] = "汪汪汪，这是一只小狗狗？",
            },
            ["tbat_eq_fantasy_apple_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型苹果狗",
                  ["inspect_str"] = "它好像有点鼠掉了....",
            },
            ["tbat_farm_plant_fantasy_apple_mutated"] = {
                  ["name"] = "幻想苹果狗",
                  ["inspect_str"] = "小狗狗你会偷吃苹果吗？",
            },
            ["tbat_eq_fantasy_apple_mutated_oversized"] = {
                  ["name"] = "巨型幻想苹果狗",
                  ["inspect_str"] = "汪汪汪，这是一只大狗狗？",
            },
            ["tbat_eq_fantasy_apple_mutated_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型幻想苹果狗",
                  ["inspect_str"] = "你好，你可以醒一醒吗？喂",
            },
            ["tbat_plant_mutated_fantasy_apple"] = {
                  ["name"] = "变异的苹果狗",
                  ["inspect_str"] = "小狗狗可不能偷吃我的红苹果",
            },
            ["tbat_plant_mutated_fantasy_apple_seed"] = {
                  ["name"] = "变异的苹果狗种子",
                  ["inspect_str"] = "变异的植物，相当特别",
            },
            ["tbat_farm_plant_fantasy_peach"] = {
                  ["name"] = "幻想小桃",
                  ["inspect_str"] = "幻想小桃",
            },
            ["tbat_eq_fantasy_peach_oversized"] = {
                  ["name"] = "巨型小桃兔",
                  ["inspect_str"] = "两只耳朵竖起来",
            },
            ["tbat_eq_fantasy_peach_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型小桃兔",
                  ["inspect_str"] = "似乎没有抢救的必要了",
            },
            ["tbat_farm_plant_fantasy_peach_mutated"] = {
                  ["name"] = "幻想小桃兔",
                  ["inspect_str"] = "可口的小兔叽",
            },
            ["tbat_eq_fantasy_peach_mutated_oversized"] = {
                  ["name"] = "巨型幻想小桃兔",
                  ["inspect_str"] = "蹦蹦跳跳真可爱",
            },
            ["tbat_eq_fantasy_peach_mutated_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型幻想小桃兔",
                  ["inspect_str"] = "它已经鼠掉了...",
            },
            ["tbat_plant_mutated_fantasy_peach"] = {
                  ["name"] = "变异的小桃兔",
                  ["inspect_str"] = "漂亮的桃花下有软萌的小兔",
            },
            ["tbat_plant_mutated_fantasy_peach_seed"] = {
                  ["name"] = "变异的小桃兔种子",
                  ["inspect_str"] = "变异的植物，相当特别",
            },
            ["tbat_farm_plant_fantasy_potato"] = {
                  ["name"] = "幻想土豆",
                  ["inspect_str"] = "幻想土豆",
            },
            ["tbat_eq_fantasy_potato_oversized"] = {
                  ["name"] = "巨型土豆鸡",
                  ["inspect_str"] = "土...土豆.......土豆鸡？？",
            },
            ["tbat_eq_fantasy_potato_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型土豆鸡",
                  ["inspect_str"] = "坏掉的土豆鸡是土豆泥吗？",
            },
            ["tbat_farm_plant_fantasy_potato_mutated"] = {
                  ["name"] = "幻想土豆鸡",
                  ["inspect_str"] = "哇，它长出来了鸡翅膀！",
            },
            ["tbat_eq_fantasy_potato_mutated_oversized"] = {
                  ["name"] = "巨型幻想土豆鸡",
                  ["inspect_str"] = "变异了，似乎更秃了",
            },
            ["tbat_eq_fantasy_potato_mutated_oversized_rotten"] = {
                  ["name"] = "腐烂的巨型幻想土豆鸡",
                  ["inspect_str"] = "变强了，但是头发没了，鸡也没了",
            },
            ["tbat_plant_mutated_fantasy_potato"] = {
                  ["name"] = "变异的土豆鸡",
                  ["inspect_str"] = "重新长出来了头发",
            },
            ["tbat_plant_mutated_fantasy_potato_seed"] = {
                  ["name"] = "变异的土豆鸡种子",
                  ["inspect_str"] = "变异的植物，相当特别",
            },
      ---------------------------------------------------------------------------------------
      -- 10_tbat_minerals
      ---------------------------------------------------------------------------------------
      -- 11_tbat_animals
            ["tbat_animal_snow_plum_chieftain"] = {
                  ["name"] = "梅雪族长",
                  ["name_pet"] = "驯养的梅雪族长",
                  ["inspect_str"] = "初雪落在梅枝上幻化而生的冬灵",
            },
            ["tbat_animal_osmanthus_cat"] = {
                  ["name"] = "桂花猫猫",
                  ["name_pet"] = "驯养的桂花猫猫",
                  ["inspect_str"] = "桂花载酒，念故人",
            },
            ["tbat_animal_maple_squirrel"] = {
                  ["name"] = "枫叶松鼠",
                  ["name_pet"] = "驯养的枫叶松鼠",
                  ["inspect_str"] = "一只会上蹿下跳的可爱生物",
                  ["following_player_in_danger_talk"] = {
                        "你可以的，我的主人",
                        "鼠鼠我在精神上支持你！",
                        "加油~你是坠厉害的主人~~",
                  }
            },
            ["tbat_animal_ephemeral_butterfly"] = {
                  ["name"] = "昙花蝴蝶",
                  ["inspect_str"] = "如梦如幻似泡沫",
            },
            ["tbat_animal_mushroom_snail"] = {
                  ["name"] = "蘑埚蜗牛",
                  ["inspect_str"] = "蘑菇上的炼药师",
                  ["reflect_damage_announce"] = "不要再打啦，这样是打不死蜗的 ~ ",
                  ["double_announce"] = "蜗蜗赐予你神迹 ~",
                  ["ghost_on_haunt"] = {"快走开啦 ~ ~ ","蜗其实是个社恐","别靠近蜗","呜呜呜不要欺负蜗"},
                  ["pot.open"] = "你看不懂的药剂方，蜗可以教你",
                  ["pot.close"] = "不看了嘛 ， 你学会了啦 ? ",
            },
            ["tbat_animal_four_leaves_clover_crane"] = {
                  ["name"] = "四叶草鹤",
                  ["inspect_str"] = "好运伴随左右",
            },
            ["tbat_pet_lavender_kitty"] = {
                  ["name"] = "薰衣草猫猫",
                  ["inspect_str"] = "居家必备的可爱小猫",
            },
            ["tbat_animal_stinkray"] = {
                  ["name"] = "帽子鳐鱼",
                  ["inspect_str"] = "风中的帽子旅者",
            },
      ---------------------------------------------------------------------------------------
      -- 12_tbat_boss
      ---------------------------------------------------------------------------------------
      -- 13_tbat_pets
            ["tbat_pet_eyebone"] = {
                  ["name"] = "宠物铃铛",
                  ["inspect_str"] = "万物书宠物用的跟随道具",
                  ["has_owner"] = "这家伙已经有其他主人了",
                  ["owner_is_player"] = "这家伙的主人就是我",
                  ["has_same_pet"] = "我已经有一只同样的了",
            },
      ---------------------------------------------------------------------------------------
      -- 14_tbat_turfs
            ["tbat_turf_water_lily_cat"] = {
                  ["name"] = "睡莲猫猫",
                  ["wild_inspect_str"] = "湖心的梦语者",
                  ["inspect_str"] = "它它它…它…好像喜欢被我踩着！",
                  ["grow_blocking"] = "湖心的梦语者,需要激活生长",
                  -- ["recipe_desc"] = "湖心的梦语者",
                  ["dig_faild"] = "有人站上面，挖走挺危险的",
                  ["dig_faild_cd"] = "这个挺坚固的，需要多试几次",
            },   
            ["tbat_turf_water_lily_cat_seed"] = {
                  ["name"] = "睡莲猫猫植株",
                  ["inspect_str"] = "它它它…它…好像喜欢被我踩着！",
            },   
            ["tbat_turf_water_lily_cat_leaf"] = {
                  ["name"] = "睡莲猫猫莲叶",
                  ["inspect_str"] = "可爱的东西，但是该怎么种植呢？",
            },   
            ["turf_tbat_turf_emerald_feather_leaves"] = {
                  ["name"] = "翠羽树叶地皮",
                  ["inspect_str"] = "鸟毛都薅秃啦",
                  ["recipe_desc"] = "鸟毛都薅秃啦",
            },
            ["turf_tbat_turf_fallen_cherry_blossoms"] = {
                  ["name"] = "岛屿落樱地皮",
                  ["inspect_str"] = "漂亮的樱花让我置身云端",
                  ["recipe_desc"] = "漂亮的樱花让我置身云端",
            },
            ["turf_tbat_turf_pearblossom_brewed_with_snow"] = {
                  ["name"] = "棠梨煎雪地皮",
                  ["inspect_str"] = "分不清是雪花还是梨花",
                  ["recipe_desc"] = "分不清是雪花还是梨花",
            },
            ["turf_tbat_turf_clover_butterfly"] = {
                  ["name"] = "蘑语林间地皮",
                  ["inspect_str"] = "漫步在林间小径",
                  ["recipe_desc"] = "飞舞着翡翠蝶的林间草地，仿佛能听见它们低语",
            },
            ["turf_tbat_turf_water_sparkles"] = {
                  ["name"] = "水光粼粼地皮",
                  ["inspect_str"] = "波光闪烁，像碎银撒满湖面",
                  ["recipe_desc"] = "浅浅的波纹泛着光，像碎银洒满水面",
            },
            ["turf_tbat_turf_lavender_dusk"] = {
                  ["name"] = "薰花晚霞地皮",
                  ["inspect_str"] = "紫花铺展，如晚霞轻落大地",
                  ["recipe_desc"] = "紫色花丛铺展开来，宛若晚霞落在大地上",
            },
            ["tbat_turfs_pack_chesspieces"] = {
                  ["name"] = "棋盘地毯",
                  ["inspect_str"] = "各色棋盘地毯",
                  ["recipe_desc"] = "各色棋盘地毯",
            },
            ["turf_tbat_turf_checkerfloor_blue"] = {
                  ["name"] = "蓝色棋盘地毯",
                  ["inspect_str"] = "清凉蓝格，静谧得像夏夜星空",
                  ["recipe_desc"] = "规整的棋盘格，清凉蓝色带来安静感",
            },
            ["turf_tbat_turf_checkerfloor_pink"] = {
                  ["name"] = "粉色棋盘地毯",
                  ["inspect_str"] = "粉格交错，甜美得像糖果拼成的路",
                  ["recipe_desc"] = "粉嫩的格子交错，甜美又俏皮",
            },
            ["turf_tbat_turf_checkerfloor_orange"] = {
                  ["name"] = "橙色棋盘地毯",
                  ["inspect_str"] = "暖橙铺地，仿佛阳光住了进去",
                  ["recipe_desc"] = "温暖的橙格子，像阳光照进了房间",
            },
            ["turf_tbat_turf_fake_ocean_shallow"] = {
                  ["name"] = "浅色海洋地皮",
                  ["inspect_str"] = "浅蓝清透，像晨光下的温柔海面",
                  ["recipe_desc"] = "浅蓝的水面轻柔澄澈，像刚苏醒的晨海",
            },
            ["turf_tbat_turf_fake_ocean_middle"] = {
                  ["name"] = "中色海洋地皮",
                  ["inspect_str"] = "湛蓝涌动，带着正午的活力",
                  ["recipe_desc"] = "海水湛蓝，层层涌动着活力与深邃",
            },
            ["turf_tbat_turf_fake_ocean_deep"] = {
                  ["name"] = "深色海洋地皮",
                  ["inspect_str"] = "深蓝翻涌，藏着夜海的神秘",
                  ["recipe_desc"] = "墨蓝色的波涛翻涌，藏着神秘的深海气息",
            },
            ["tbat_turfs_pack_ocean"] = {
                  ["name"] = "海洋地皮",
                  ["inspect_str"] = "深蓝翻涌，藏着夜海的神秘",
                  ["recipe_desc"] = "海洋风格的地皮",
            },
            ["tbat_turf_carpet_pink_fur"] = {
                  ["name"] = "粉绒花毯",
                  ["inspect_str"] = "用花瓣和羊毛编织的柔软小地毯",
                  ["recipe_desc"] = "用花瓣和羊毛编织的柔软小地毯",
                  ["skin.cream_puff_bread"] = "奶黄包拼接地垫",
                  ["skin.taro_bread"] = "香芋包拼接地垫",
                  ["skin.taro_bread_with_bell"] = "香芋铃铛拼接地垫",
                  ["skin.hello_kitty"] = "kitty 小猫垫",
            },
            ["tbat_turf_carpet_cat_claw"] = {
                  ["name"] = "萌爪喵地垫",
                  ["inspect_str"] = "可爱又软萌的猫咪图案",
                  ["recipe_desc"] = "毛茸茸的地垫上印着猫爪印，俏皮可爱",
                  ["skin.dreamweave_rug"] = "捕梦织羽地毯",
                  ["skin.petglyph_platform"] = "萌宠石刻地台",
            },
            ["tbat_turf_carpet_four_leaves_clover"] = {
                  ["name"] = "幸运草团",
                  ["inspect_str"] = "嫩绿四叶草，带来小小好运",
                  ["recipe_desc"] = "一大团嫩绿的四叶草，像把好运悄悄藏在脚下",
            },
      ---------------------------------------------------------------------------------------
      -- 15_tbat_debuffs
            ["tbat_debuff_stinkray_poison"] = {
                  ["name"] = "帽子鳐鱼剧毒",
            },
      ---------------------------------------------------------------------------------------
      -- 16_tbat_spells
      ---------------------------------------------------------------------------------------
      -- 17_tbat_sfx
            ["tbat_sfx_ground_fireflies"] = {
                  ["name"] = "荧光生物",
                  ["inspect_str"] = "荧光生物",
                  ["recipe_desc"] = "荧光生物",
            },
      ---------------------------------------------------------------------------------------
      -- 18_tbat_projectiles
      ---------------------------------------------------------------------------------------
      -- 19_tbat_characters
      ---------------------------------------------------------------------------------------
      -- 20_tbat_events
      ---------------------------------------------------------------------------------------
      -- 21_tbat_rooms
            ["tbat_room_anchor_fantasy_island_main"] = {
                  ["name"] = "地块锚点 : Main",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_a"] = {
                  ["name"] = "地块锚点 : A",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_b"] = {
                  ["name"] = "地块锚点 : B",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_c"] = {
                  ["name"] = "地块锚点 : C",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_d"] = {
                  ["name"] = "地块锚点 : D",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_e"] = {
                  ["name"] = "地块锚点 : E",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_f"] = {
                  ["name"] = "地块锚点 : F",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_room_anchor_fantasy_island_g"] = {
                  ["name"] = "地块锚点 : G",
                  ["inspect_str"] = "这个地块的锚点",
            },
            ["tbat_eq_anchor_cane"] = {
                  ["name"] = "万物书:锚点之杖",
                  ["inspect_str"] = "用来显示这个地块的锚点",
                  ["recipe_desc"] = "用来获取万物书岛屿上的锚点数据",
            },
            ["tbat_room_mini_portal_door"] = {
                  ["name"] = "迷你传送门",
                  ["inspect_str"] = "离开幻想岛屿",
            },
      ---------------------------------------------------------------------------------------
      -- 22_tbat_npc
            ["tbat_npc_emerald_feather_bird"] = {
                  ["name"] = "翠羽鸟",
                  ["inspect_str"] = "它的羽毛好好看",
                  ["wander_talk"] = {
                        "用我树叶写笔记的家伙好像不见了……她去哪里了",
                        "人类到底在忙些什么，为什么不爱和我玩。我……有点想她",
                        "她似乎写了很多内容，从秋天到春天，从酷暑到霜雪",
                        "她不会回来了，你们会一直陪着我吗…？",
                  },
                  ["item_accept_talk"] = {
                        "哦，我正在找这个！","哦，谢谢你","感谢你帮我带来这个！","谢了，朋友！",
                  },
            },
            ["tbat_npc_ty"] = {
                  ["name"] = "童瑶",
                  ["inspect_str"] = "策划之一",
                  ["onwork"] = "嘿嘿，你们在未来可能会很需要我们奥~",
            },
            ["tbat_npc_xmm"] = {
                  ["name"] = "悉茗茗",
                  ["inspect_str"] = "策划之一",
                  ["onwork"] = "我的小狐狸可爱嘛？这个可不出售~",
            },
      ---------------------------------------------------------------------------------------
      ---mz
            ["tbat_sensangu"] = {
                  ["name"] = "森伞菇",
                  ["inspect_str"] = "等风路过，伞下蜷着整座森林的呼吸",
            },
            ["tbat_sensangu_item"] = {
                  ["name"] = "森伞小菇",
                  ["inspect_str"] = "小蘑菇吗？看着比我脑袋还大",
            },
      ---------------------------------------------------------------------------------------
}
