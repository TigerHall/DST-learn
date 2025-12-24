---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    统一注册 【 images\inventoryimages 】 里的所有图标
    每个 xml 里面 只有一个 tex    

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if Assets == nil then
    Assets = {}
end

local files_name = {


	---------------------------------------------------------------------------------------
	-- 00_tbat_others
		-- "test_item"	, 							--- 测试物品
	---------------------------------------------------------------------------------------
	-- 01_tbat_items
		"tbat_item_butterfly_wrapping_paper",			-- 蝴蝶打包纸
		"tbat_item_butterfly_wrapped_pack",				-- 蝴蝶包裹
		"tbat_item_holo_maple_leaf",				-- 留影枫叶
		"tbat_item_jellyfish_in_bottle",				-- 伴生水母素
		"tbat_item_maple_squirrel_kit",				-- 枫叶鼠鼠
		"tbat_item_snow_plum_wolf_kit",				-- 梅雪小狼
		"tbat_item_trans_core",				-- 传送核心
		"tbat_item_blueprint",				-- 蓝图
		"tbat_item_notes_of_adventurer",				-- 冒险家日志
		"tbat_item_crystal_bubble",				-- 水晶气泡
		"tbat_item_failed_potion",				-- 【药剂】 失败药水
		"tbat_item_wish_note_potion",			-- 【药剂】 愿望之笺
		"tbat_item_veil_of_knowledge_potion", 	-- 【药剂】 知识之纱
		"tbat_item_oath_of_courage_potion", 	-- 【药剂】 勇气之誓
		"tbat_item_lucky_words_potion", 		-- 【药剂】 幸运之语
		"tbat_item_peach_blossom_pact_potion",	-- 【药剂】 桃花之约
		"atbook_wiki",	-- 万物之书
	---------------------------------------------------------------------------------------
	-- 02_tbat_materials
		"tbat_material_miragewood",						-- 幻木
		"tbat_material_dandelion_umbrella",						-- 蒲公英伞
		"tbat_material_dandycat",						-- 蒲公英猫猫
		"tbat_material_wish_token",						-- 祈愿牌
		"tbat_material_white_plum_blossom",						-- 白梅花
		"tbat_material_snow_plum_wolf_hair",						-- 狼毛
		"tbat_material_snow_plum_wolf_heart",						-- 狼心
		"tbat_material_osmanthus_ball",						-- 桂花球
		"tbat_material_osmanthus_wine",						-- 桂花酒
		"tbat_material_emerald_feather",						-- 翠羽鸟的羽毛
		"tbat_material_liquid_of_maple_leaves",						-- 枫液
		"tbat_material_squirrel_incisors",						-- 松鼠牙
		"tbat_material_sunflower_seeds",						-- 葵瓜子
		"tbat_material_starshard_dust",						-- 星辰
		"tbat_material_four_leaves_clover_feather",						-- 四叶草鹤羽毛
		"tbat_material_lavender_laundry_detergent",						-- 薰衣草洗衣液
		"tbat_material_green_leaf_mushroom",						-- 森伞小菇
		"tbat_material_memory_crystal",						-- 记忆水晶
	---------------------------------------------------------------------------------------
	-- 03_tbat_equipments
		"tbat_eq_fantasy_tool",							--- 幻想工具
		"tbat_eq_fantasy_tool2",									--- 幻想工具(皮肤)
		"tbat_eq_fantasy_tool_freya_s_wand",						--- 幻想工具(皮肤) -- 芙蕾雅的魔法棒
		"tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",	--- 幻想工具(皮肤) -- 芝心幻蝶餐叉
		"tbat_eq_universal_baton",						--- 万物指挥棒
		"tbat_eq_universal_baton_2",								--- 万物指挥棒(皮肤)
		"tbat_eq_universal_baton_3",								--- 万物指挥棒(皮肤)
		"tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",		--- 万物指挥棒(皮肤) - 雪顶兔兔冰淇淋
		"tbat_eq_universal_baton_bunny_scepter",					--- 万物指挥棒(皮肤) - 芙蕾雅的小兔权杖
		"tbat_eq_universal_baton_jade_sword_immortal",				--- 万物指挥棒(皮肤) - 玉剑仙
		"tbat_eq_shake_cup",						--- 摇摇杯
		"tbat_eq_world_skipper",						--- 万物穿梭
		"tbat_eq_furrycat_circlet",						--- 猫猫花环
		"tbat_eq_furrycat_circlet_strawberry_bunny",						--- 猫猫花环(皮肤) - 莓语兔兔花冠
		"tbat_eq_ray_fish_hat",											--- 鳐鱼帽子
		"tbat_eq_ray_fish_hat_sweetheart_cocoa",						--- 鳐鱼帽子(皮肤) -- 甜心可可花环
		"tbat_eq_snail_shell_of_mushroom",						--- 小蜗护甲
		"tbat_eq_jumbo_ice_cream_tub",						--- 吨吨桶
	---------------------------------------------------------------------------------------
	-- 04_tbat_foods
		"tbat_food_hedgehog_cactus_meat",				--- 小鲜肉
		"tbat_food_pear_blossom_petals",				--- 梨花花瓣
		"tbat_food_cherry_blossom_petals",				--- 樱花花瓣
		"tbat_food_valorbush",				--- 勇者玫瑰
		"tbat_food_crimson_bramblefruit",				--- 绯露莓
		"tbat_food_jellyfish",				--- 水母
		"tbat_food_jellyfish_dried",				--- 水母
		"tbat_food_raw_meat",				--- 新鲜的肉
		"tbat_food_raw_meat_cooked",				--- 烤熟的肉
		"tbat_food_cocoanut",				--- 椰子肉
		"tbat_food_lavender_flower_spike",				--- 薰衣草花穗
		"tbat_food_ephemeral_flower",				--- 识之昙花
		"tbat_food_ephemeral_flower_butterfly_wings",				--- 昙花蝴蝶翅膀
		"tbat_food_fantasy_potato",						--- 幻想土豆
		"tbat_food_fantasy_potato_cooked",				--- 幻想土豆
		"tbat_food_fantasy_potato_seeds",				--- 幻想土豆种子
		"tbat_food_fantasy_potato_seeds_cooked",			--- 幻想土豆种子
		"tbat_food_fantasy_peach",						--- 幻想小桃
		"tbat_food_fantasy_peach_cooked",				--- 幻想小桃
		"tbat_food_fantasy_peach_seeds",					--- 幻想小桃种子
		"tbat_food_fantasy_peach_seeds_cooked",			--- 幻想小桃种子
		"tbat_food_fantasy_apple",						--- 幻想苹果
		"tbat_food_fantasy_apple_cooked",				--- 幻想苹果
		"tbat_food_fantasy_apple_seeds",					--- 幻想苹果种子
		"tbat_food_fantasy_apple_seeds_cooked",			--- 幻想苹果
	---------------------------------------------------------------------------------------
	-- 05_tbat_foods_cooked
		"tbat_food_cooked_honey_meat_tower",		-- 蜜汁肉肉塔
		"tbat_food_cooked_blossom_roll",		-- 樱花可颂卷
		"tbat_food_cooked_fairy_hug",		-- 抱抱小仙卷
		"tbat_food_cooked_rose_whisper_tea",		-- 玫瑰花语茶
		"tbat_food_cooked_apple_snow_sundae",		-- 苹果雪山圣代
		"tbat_food_cooked_berry_rabbit_jelly",		-- 莓果兔兔冻
		"tbat_food_cooked_garden_table_cake",		-- 花园物语蛋糕
		"tbat_food_cooked_peach_pudding_rabbit",		-- 蜜桃布丁兔
		"tbat_food_cooked_potato_fantasy_pie",		-- 土豆奇幻派
		"tbat_food_cooked_peach_rabbit_mousse",		-- 桃兔花椰慕斯
		"tbat_food_cooked_rainbow_rabbit_milkshake",		-- 彩虹兔兔奶昔
		"tbat_food_cooked_forest_garden_roll",		-- 花境森林卷
		"tbat_food_cooked_flower_bunny_cake",		-- 花兔彩绮蛋糕
		"tbat_food_cooked_star_sea_jelly_cup",		-- 星海水母冰杯
		"tbat_food_cooked_snow_sheep_sushi",		-- 雪顶绵羊寿司
		"tbat_food_cooked_forest_dream_bento",		-- 森林梦境便当
		"tbat_food_cooked_bear_sun_platter",		-- 小熊阳光拼盘
		"tbat_food_cooked_bamboo_cat_bbq_skewers",		-- 竹香小咪烤串
		"tbat_food_cooked_flower_whisper_ramen",		-- 花香耳语拉面
		"tbat_food_cooked_cloud_rabbit_steamed_bun",		-- 软绵云兔馒头
		"tbat_food_cooked_pink_butterfly_steamed_bun",		-- 粉蝶嘟嘟馍饼
		"tbat_food_cooked_butterfly_dance_rice",		-- 花间蝶舞糯米饭
	---------------------------------------------------------------------------------------
	-- 06_tbat_containers
	---------------------------------------------------------------------------------------
	-- 07_tbat_buildings
		"tbat_building_cloud_wooden_sign",		--- 云朵小木牌
		"tbat_building_kitty_wooden_sign",		--- 喵喵小木牌
		"tbat_building_bunny_wooden_sign",		--- 兔兔小木牌
		"tbat_building_conch_shell_decoration_1",		--- 围边海螺贝壳装饰
		"tbat_building_conch_shell_decoration_2",		--- 围边海螺贝壳装饰
		"tbat_building_conch_shell_decoration_3",		--- 围边海螺贝壳装饰
		"tbat_building_conch_shell_decoration_4",		--- 围边海螺贝壳装饰
		"tbat_building_conch_shell_decoration_5",		--- 围边海螺贝壳装饰
		"tbat_building_conch_shell_decoration_6",		--- 围边海螺贝壳装饰
		"tbat_building_star_and_cloud_decoration_1",		--- 围边星星云朵装饰
		"tbat_building_star_and_cloud_decoration_2",		--- 围边星星云朵装饰
		"tbat_building_star_and_cloud_decoration_3",		--- 围边星星云朵装饰
		"tbat_building_star_and_cloud_decoration_4",		--- 围边星星云朵装饰
		"tbat_building_star_and_cloud_decoration_5",		--- 围边星星云朵装饰
		"tbat_building_star_and_cloud_decoration_6",		--- 围边星星云朵装饰
		"tbat_building_snowflake_decoration_1",		--- 围边雪花雪人装饰
		"tbat_building_snowflake_decoration_2",		--- 围边雪花雪人装饰
		"tbat_building_snowflake_decoration_3",		--- 围边雪花雪人装饰
		"tbat_building_snowflake_decoration_4",		--- 围边雪花雪人装饰
		"tbat_building_snowflake_decoration_5",		--- 围边雪花雪人装饰
		"tbat_building_snowflake_decoration_6",		--- 围边雪花雪人装饰
		"tbat_building_cute_pet_stone_figurines_1",		--- 萌宠小石雕
		"tbat_building_cute_pet_stone_figurines_2",		--- 萌宠小石雕
		"tbat_building_cute_pet_stone_figurines_3",		--- 萌宠小石雕
		"tbat_building_cute_pet_stone_figurines_4",		--- 萌宠小石雕
		"tbat_building_cute_pet_stone_figurines_5",		--- 萌宠小石雕
		"tbat_building_cute_animal_decorative_figurines_1",		--- 萌宠装饰雕像
		"tbat_building_cute_animal_decorative_figurines_2",		--- 萌宠装饰雕像
		"tbat_building_cute_animal_decorative_figurines_3",		--- 萌宠装饰雕像
		"tbat_building_cute_animal_decorative_figurines_4",		--- 萌宠装饰雕像
		"tbat_building_cute_animal_wooden_figurines_1",		--- 萌宠装饰木桩
		"tbat_building_cute_animal_wooden_figurines_2",		--- 萌宠装饰木桩
		"tbat_building_cute_animal_wooden_figurines_3",		--- 萌宠装饰木桩
		"tbat_building_carved_stone_tiles_1",		--- 石雕台阶
		"tbat_building_carved_stone_tiles_2",		--- 石雕台阶
		"tbat_building_carved_stone_tiles_3",		--- 石雕台阶
		"tbat_building_carved_stone_tiles_4",		--- 石雕台阶
		"tbat_building_carved_stone_tiles_5",		--- 石雕台阶
		"tbat_building_carved_stone_tiles_6",		--- 石雕台阶
		"tbat_building_time_fireplace",		--- 时光壁炉
		"tbat_building_time_fireplace_with_flower",		--- 时光壁炉(皮肤)
	---------------------------------------------------------------------------------------
	-- 08_tbat_resources
		"tbat_resource_river_pebble",					--- 河边石子
		"tbat_resource_river_pebble_2",					--- 河边石子(皮肤)
		"tbat_resource_river_pebble_3",					--- 河边石子(皮肤)
		"tbat_resource_river_pebble_4",					--- 河边石子(皮肤)
		"tbat_resource_river_pebble_5",					--- 河边石子(皮肤)
		"tbat_resource_river_pebble_6",					--- 河边石子(皮肤)
		"tbat_resource_kitty_stone",					--- 花喵小石子
		"tbat_resource_kitty_stone_2",					--- 花喵小石子(皮肤)
		"tbat_resource_kitty_stone_3",					--- 花喵小石子(皮肤)
		"tbat_resource_kitty_stone_4",					--- 花喵小石子(皮肤)
		"tbat_resource_kitty_stone_5",					--- 花喵小石子(皮肤)
	---------------------------------------------------------------------------------------
	-- 09_tbat_plants
		"tbat_plant_hedgehog_cactus_pot",				--- 刺猬小仙盆栽
		"tbat_plant_hedgehog_cactus_seed",				--- 小仙种子
		"tbat_plant_coconut_cat_fruit",					--- 清甜椰子
		"tbat_plant_coconut_tree_seed",					--- 发芽的清甜椰子
		"tbat_plant_coconut_cat_kit",					--- 椰子猫猫
		"tbat_plant_dandycat_kit",						--- 蒲公英猫猫
		"tbat_plant_kitty_cattail",						--- 喵蒲装饰草丛
		"tbat_plant_kitty_cattail_2",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_cattail_3",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_cattail_4",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_cattail_5",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_cattail_6",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_cattail_7",						--- 喵蒲装饰草丛(皮肤)
		"tbat_plant_kitty_bush",						--- 猫猫草墩
		"tbat_plant_kitty_bush_2",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_3",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_4",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_5",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_6",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_7",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_8",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_9",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_10",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_11",						--- 猫猫草墩(皮肤)
		"tbat_plant_kitty_bush_12",						--- 猫猫草墩(皮肤)
		"tbat_plant_water_plants_of_pond",						--- 池边水草
		"tbat_plant_water_plants_of_pond_2",						--- 池边水草(皮肤)
		"tbat_plant_water_plants_of_pond_3",						--- 池边水草(皮肤)
		"tbat_plant_water_plants_of_pond_4",						--- 池边水草(皮肤)
		"tbat_plant_water_plants_of_pond_5",						--- 池边水草(皮肤)
		"tbat_plant_water_plants_of_pond_6",						--- 池边水草(皮肤)
		"tbat_plant_water_plants_of_pond_7",						--- 池边水草(皮肤)
		"tbat_plant_fluorescent_moss_item",						--- 荧光苔藓
		"tbat_plant_fluorescent_mushroom_item",					--- 荧光蘑菇
		"tbat_eq_fantasy_apple_oversized",							--- 苹果 - 巨大作物
		"tbat_eq_fantasy_apple_mutated_oversized",					--- 苹果(变异) - 巨大作物
		"tbat_plant_mutated_fantasy_apple_seed",					--- 【棱镜变异】苹果
		"tbat_eq_fantasy_peach_oversized",							--- 桃 - 巨大作物
		"tbat_eq_fantasy_peach_mutated_oversized",					--- 桃(变异) - 巨大作物
		"tbat_plant_mutated_fantasy_peach_seed",					--- 【棱镜变异】桃
		"tbat_eq_fantasy_potato_oversized",							--- 土豆 - 巨大作物
		"tbat_eq_fantasy_potato_mutated_oversized",					--- 土豆(变异) - 巨大作物
		"tbat_plant_mutated_fantasy_potato_seed",					--- 【棱镜变异】土豆
	---------------------------------------------------------------------------------------
	-- 10_tbat_minerals
	---------------------------------------------------------------------------------------
	-- 11_tbat_animals
		"tbat_animal_maple_squirrel",					--- 枫树松鼠
		"tbat_animal_ephemeral_butterfly",					--- 昙花蝴蝶
	---------------------------------------------------------------------------------------
	-- 12_tbat_boss
	---------------------------------------------------------------------------------------
	-- 13_tbat_pets
	---------------------------------------------------------------------------------------
	-- 14_tbat_turfs
		"tbat_turf_water_lily_cat_seed",			-- 睡莲猫猫
		"tbat_turf_water_lily_cat_leaf",			-- 睡莲猫猫
		"tbat_turf_emerald_feather_leaves",			-- 翠羽树叶地皮
		"tbat_turf_fallen_cherry_blossoms",			-- 落樱地皮
		"tbat_turf_pearblossom_brewed_with_snow",			-- 棠梨煎雪地皮
		"tbat_turf_clover_butterfly",			-- 蘑语林间地皮
		"tbat_turf_water_sparkles",			-- 水光粼粼地皮
		"tbat_turf_lavender_dusk",			-- 薰花晚霞地皮
		"tbat_turf_checkerfloor_blue",			-- 蓝色棋盘地毯
		"tbat_turf_checkerfloor_pink",			-- 粉色棋盘地毯",
		"tbat_turf_checkerfloor_orange",			-- "橙色棋盘地毯"
		"tbat_turf_fake_ocean_shallow",			-- 假海洋地皮（浅海）
		"tbat_turf_fake_ocean_middle",			-- 假海洋地皮（中海）
		"tbat_turf_fake_ocean_deep",			-- 假海洋地皮（深海）
	---------------------------------------------------------------------------------------
	-- 15_tbat_debuffs
	---------------------------------------------------------------------------------------
	-- 16_tbat_spells
	---------------------------------------------------------------------------------------
	-- 17_tbat_sfx
	---------------------------------------------------------------------------------------
	-- 18_tbat_projectiles
	---------------------------------------------------------------------------------------
	-- 19_tbat_characters
	---------------------------------------------------------------------------------------
	-- 20_tbat_events
	---------------------------------------------------------------------------------------
	-- 21_tbat_rooms
	---------------------------------------------------------------------------------------
	-- 22_tbat_npc
	---------------------------------------------------------------------------------------
		"tbat_sensangu_item",						--- 森伞小菇图标
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------

}

for k, name in pairs(files_name) do
	if type(name) == "string" then
		table.insert(Assets, Asset( "IMAGE", "images/inventoryimages/".. name ..".tex" ))
		table.insert(Assets, Asset( "ATLAS", "images/inventoryimages/".. name ..".xml" ))
		table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/".. name ..".xml", 256) )
		RegisterInventoryItemAtlas("images/inventoryimages/".. name ..".xml", name .. ".tex")

	elseif type(name) == "function" then
		name()
	end			
end

function TBAT:GetAllInventoryImageFileNames()
	return files_name
end
