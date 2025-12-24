---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    统一注册 【 images\map_icons 】 里的所有图标
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
	---------------------------------------------------------------------------------------
	-- 02_tbat_materials
	---------------------------------------------------------------------------------------
	-- 03_tbat_equipments
	---------------------------------------------------------------------------------------
	-- 04_tbat_foods
	---------------------------------------------------------------------------------------
	-- 05_tbat_foods_cooked
	---------------------------------------------------------------------------------------
	-- 06_tbat_containers
		"tbat_container_pear_cat",					-- 梨花猫猫
		"tbat_container_pear_cat_strawberry_jam",		-- 梨花猫猫(皮肤)  -- 草莓比熊
		"tbat_container_pear_cat_pudding",				-- 梨花猫猫(皮肤)  -- 喵喵布丁
		"tbat_container_cherry_blossom_rabbit_mini",					-- 樱花兔兔
		"tbat_container_cherry_blossom_rabbit",							-- 樱花兔兔
		"tbat_container_cherry_blossom_rabbit_icecream",							-- 樱花兔兔（皮肤） -- 樱花甜筒
		"tbat_container_cherry_blossom_rabbit_labubu_colourful_feather",			-- 樱花兔兔（皮肤） -- 拉布布:彩羽
		"tbat_container_cherry_blossom_rabbit_labubu_skyblue",						-- 樱花兔兔（皮肤） -- 拉布布:碧蓝
		"tbat_container_cherry_blossom_rabbit_labubu_pink_strawberry",				-- 樱花兔兔（皮肤） -- 拉布布:粉莓
		"tbat_container_cherry_blossom_rabbit_labubu_flower_bud",					-- 樱花兔兔（皮肤） -- 拉布布:花苞
		"tbat_container_cherry_blossom_rabbit_labubu_orange",						-- 樱花兔兔（皮肤） -- 拉布布:橘暖
		"tbat_container_cherry_blossom_rabbit_labubu_white_cherry",					-- 樱花兔兔（皮肤） -- 拉布布:棉樱
		"tbat_container_cherry_blossom_rabbit_labubu_lemon_yellow",					-- 樱花兔兔（皮肤） -- 拉布布:柠光
		"tbat_container_cherry_blossom_rabbit_labubu_dream_blue",					-- 樱花兔兔（皮肤） -- 拉布布:蔚梦
		"tbat_container_cherry_blossom_rabbit_labubu_moon_white",					-- 樱花兔兔（皮肤） -- 拉布布:月白
		"tbat_container_cherry_blossom_rabbit_labubu_purple_wind",					-- 樱花兔兔（皮肤） -- 拉布布:紫岚
		"tbat_container_emerald_feathered_bird_collection_chest",		-- 翠羽鸟收集箱
		"tbat_container_squirrel_stash_box",		-- 鼠鼠囤货箱
		"tbat_container_mushroom_snail_cauldron",		-- 蘑菇小蜗埚
		"tbat_container_lavender_kitty",		-- 薰衣草小猫
		"tbat_container_little_crane_bird",		-- 小小鹤草箱
	---------------------------------------------------------------------------------------
	-- 07_tbat_buildings
		"tbat_the_tree_of_all_things",					-- 万物之树
		"tbat_building_piano_rabbit",					-- 星琴小兔
		"tbat_building_sunflower_hamster",					-- 向日葵仓鼠灯
		"tbat_building_sunflower_hamster_gumball_machine",	-- 向日葵仓鼠灯（皮肤） -- 幻羽藤蔓灯
		"tbat_building_stump_table",						-- 软木餐桌
		"tbat_building_stump_table_sunbloom_side_table",	-- 软木餐桌(皮肤) -- 向阳茶点桌
		"tbat_building_magic_potion_cabinet",									-- 魔法药剂柜
		"tbat_building_magic_potion_cabinet_tree_ring_counter",					-- 魔法药剂柜（皮肤） -- 森语奇境
		"tbat_building_magic_potion_cabinet_ferris_wheel",						-- 魔法药剂柜（皮肤） -- 云朵乐园烘培屋
		"tbat_building_magic_potion_cabinet_gift_display_rack",					-- 魔法药剂柜（皮肤） -- 星琴礼品架
		"tbat_building_magic_potion_cabinet_accordion",							-- 魔法药剂柜（皮肤） -- 乐琴旋转展厅
		"tbat_building_magic_potion_cabinet_dreampkin_hut",						-- 魔法药剂柜（皮肤） -- 南瓜梦境屋
		"tbat_building_magic_potion_cabinet_grid_cabinet",						-- 魔法药剂柜（皮肤） -- 花木跳趣格
		"tbat_building_magic_potion_cabinet_puffcap_stand",						-- 魔法药剂柜（皮肤） -- 蘑菇萌趣台
		"tbat_building_plum_blossom_table",									-- 梅花餐桌
		"tbat_building_plum_blossom_table_sweetwhim_stand",					-- 梅花餐桌(皮肤) -- 童话甜品台
		"tbat_building_plum_blossom_hearth",					-- 梅花灶台
		"tbat_building_plum_blossom_hearth_abysshell_stand",	-- 梅花灶台（皮肤） -- 深海贝壳甜品台
		"tbat_building_cherry_blossom_rabbit_swing",					-- 樱花兔兔秋千
		"tbat_building_red_spider_lily_rocking_chair",					-- 彼岸花摇椅
		"tbat_building_rough_cut_wood_sofa",					-- 原木沙发
		"tbat_building_rough_cut_wood_sofa_magic_broom",		-- 原木沙发(皮肤)  -- 喵咪魔法扫帚
		"tbat_building_rough_cut_wood_sofa_sunbloom",			-- 原木沙发(皮肤)  -- 向阳绒布沙发
		"tbat_building_rough_cut_wood_sofa_lemon_cookie",		-- 原木沙发(皮肤)  -- 香柠甜筒沙发
		"tbat_building_whisper_tome_squirrel_phonograph",		-- 物语集 - 松鼠留声机
		"tbat_building_whisper_tome_spellwisp_desk",			-- 物语集（皮肤） - 幽蓝巫术桌
		"tbat_building_whisper_tome_chirpwell",					-- 物语集（皮肤） - 童趣水井亭
		"tbat_building_whisper_tome_purr_oven",					-- 物语集（皮肤） - 猫咪烘焙炉
		"tbat_building_whisper_tome_swirl_vanity",				-- 物语集（皮肤） - 芙蕾雅の小兔梳妆台
		"tbat_building_whisper_tome_birdchime_clock",			-- 物语集（皮肤） - 鸟语时钟
		"tbat_building_woodland_lamp",					-- 森林矮灯
		"tbat_building_woodland_lamp_starwish",			-- 森林矮灯（皮肤） -- 星愿心灯柱
		"wall_tbat_wood",					-- 梅花木墙
		"wall_tbat_maple",					-- 枫叶草墙
		"wall_tbat_osmanthus_stone",					-- 桂花石墙
		"tbat_wall_skin_strawberry_cream_cake",			-- 桂花石墙(皮肤) -- 草莓奶油蛋糕
		"tbat_wall_skin_coral_reef",					-- 桂花石墙(皮肤) -- 星贝珊瑚礁柱
		"tbat_building_recruitment_notice_board",					-- 告示招募栏
		"tbat_building_trade_notice_board",					-- 告示交易栏
		"tbat_building_snow_plum_pet_house",					-- 梅雪木屋
		"tbat_building_osmanthus_cat_pet_house",					-- 桂猫石屋
		"tbat_building_maple_squirrel_pet_house",					-- 秋枫树屋
		"tbat_building_fantasy_shop",					-- 瑶瑶奶悉的设计屋
		"tbat_building_chesspiece_display_stand",					-- 雕像展示台
		"tbat_building_green_campanula_with_cat",					-- 发光的路灯花
		"tbat_building_twin_goslings",					-- 双生小鹅灯
		"tbat_building_lamp_moon_with_clouds",					-- 花语云梦灯
		"tbat_building_lamp_moon_with_clouds_starwish",			-- 花语云梦灯(皮肤) -- 荧星彩云灯
		"tbat_building_lamp_moon_with_clouds_sleeping_kitty",	-- 花语云梦灯(皮肤) -- 月眠喵梦灯
		"tbat_building_pot_animals_with_flowers",					-- 萌宠装饰盆栽
		"tbat_building_pot_verdant_grove",							-- 萌宠装饰盆栽(皮肤)  -- 翠意绿植
		"tbat_building_pot_bunny_cart",								-- 萌宠装饰盆栽(皮肤)  -- 花车萌趣
		"tbat_building_pot_dreambloom_vase",						-- 萌宠装饰盆栽(皮肤)  -- 紫梦花瓶
		"tbat_building_pot_foxglean_basket",						-- 萌宠装饰盆栽(皮肤)  -- 狐趣果篮
		"tbat_building_pot_lavendream",								-- 萌宠装饰盆栽(皮肤)  -- 紫韵小花
		"tbat_building_pot_cloudlamb_vase",							-- 萌宠装饰盆栽(皮肤)  -- 羊咩云花
		"tbat_building_forest_mushroom_cottage",					-- 森林蘑菇小窝
		"tbat_building_four_leaves_clover_crane_lv1",					-- 四叶草鹤雕像
		"tbat_building_four_leaves_clover_crane_lv2",					-- 四叶草鹤雕像
		"tbat_building_lavender_flower_house",						-- 薰衣草花房
		"tbat_building_reef_lighthouse",						-- 礁石灯塔
	---------------------------------------------------------------------------------------
	-- 08_tbat_resources
		"tbat_resources_memory_crystal_ore_core",			-- 记忆水晶矿心
	---------------------------------------------------------------------------------------
	-- 09_tbat_plants
		"tbat_plant_pear_blossom_tree",				--- 梨花树
		"tbat_plant_pear_blossom_tree_kit",			--- 梨花树物品
		"tbat_plant_cherry_blossom_tree",			--- 樱花树
		"tbat_plant_cherry_blossom_tree_kit",		--- 樱花树物品
		"tbat_plant_crimson_maple_tree",			--- 秋枫树
		"tbat_plant_crimson_maple_tree_kit",		--- 秋枫树物品
		"tbat_plant_valorbush",						--- 勇者玫瑰灌木
		"tbat_plant_valorbush_kit",					--- 勇者玫瑰灌木
		"tbat_plant_crimson_bramblefruit",					--- 绯露莓刺藤
		"tbat_plant_crimson_bramblefruit_kit",					--- 绯露莓刺藤
		"tbat_plant_plum_blossom_bush",					--- 梅影装饰花丛
		"tbat_plant_plum_blossom_bush_dreambloom",					--- 梅影装饰花丛(皮肤) -- 绮梦花丛
		"tbat_plant_plum_blossom_bush_mistbloom",					--- 梅影装饰花丛(皮肤) -- 云雾花丛
		"tbat_plant_plum_blossom_bush_mosswhisper",					--- 梅影装饰花丛(皮肤) -- 绿语苔丛
		"tbat_plant_plum_blossom_bush_bunnysleep_orchid",			--- 梅影装饰花丛(皮肤) -- 兔眠花丛
		"tbat_plant_plum_blossom_bush_warm_rose",					--- 梅影装饰花丛(皮肤) -- 暖樱玫瑰丛
		"tbat_plant_plum_blossom_bush_spark_rose",					--- 梅影装饰花丛(皮肤) -- 星火玫瑰丛
		"tbat_plant_plum_blossom_bush_luminmist_rose",				--- 梅影装饰花丛(皮肤) -- 云光玫瑰丛
		"tbat_plant_plum_blossom_bush_frostberry_rose",				--- 梅影装饰花丛(皮肤) -- 莓霜玫瑰丛
		"tbat_plant_plum_blossom_bush_stellar_rose",				--- 梅影装饰花丛(皮肤) -- 星辰玫瑰丛
		"tbat_plant_lavender_bush",						--- 薰衣草草丛
		"tbat_plant_lavender_bush_kit",					--- 薰衣草草丛
		"tbat_plant_osmanthus_bush",					--- 桂花矮树
		"tbat_plant_osmanthus_bush_kit",				--- 桂花矮树
	---------------------------------------------------------------------------------------
	-- 10_tbat_minerals
	---------------------------------------------------------------------------------------
	-- 11_tbat_animals
	---------------------------------------------------------------------------------------
	-- 12_tbat_boss
	---------------------------------------------------------------------------------------
	-- 13_tbat_pets
	---------------------------------------------------------------------------------------
	-- 14_tbat_turfs
		"tbat_turf_water_lily_cat",					--- 睡莲猫猫
		"tbat_turf_carpet_pink_fur",					--- 粉绒花毯
		"tbat_turf_carpet_pink_fur_cream_puff_bread",					--- 粉绒花毯(皮肤) -- 奶黄包拼接地垫
		"tbat_turf_carpet_pink_fur_taro_bread",							--- 粉绒花毯(皮肤) -- 香芋包拼接地垫
		"tbat_turf_carpet_pink_fur_taro_bread_with_bell",				--- 粉绒花毯(皮肤) -- 香芋包拼接地垫（带铃铛）
		"tbat_turf_carpet_pink_fur_hello_kitty",						--- 粉绒花毯(皮肤) -- kitty 小猫垫
		"tbat_turf_carpet_cat_claw",					--- 萌爪喵地垫
		"tbat_turf_carpet_cat_claw_dreamweave_rug",		--- 萌爪喵地垫(皮肤)  -- 捕梦织羽地毯
		"tbat_turf_carpet_cat_claw_petglyph_platform",	--- 萌爪喵地垫(皮肤)  -- 萌宠石刻地台
		"tbat_turf_carpet_four_leaves_clover",			--- 幸运草团
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

	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------

}

for k, name in pairs(files_name) do
    table.insert(Assets, Asset( "IMAGE", "images/map_icons/".. name ..".tex" ))
    table.insert(Assets, Asset( "ATLAS", "images/map_icons/".. name ..".xml" ))
	AddMinimapAtlas("images/map_icons/".. name ..".xml")
	RegisterInventoryItemAtlas("images/map_icons/".. name ..".xml",name..".tex")
	table.insert(Assets, Asset("ATLAS_BUILD", "images/map_icons/".. name ..".xml", 256) )
end

function TBAT:GetAllMapIconFileNames()
	return files_name
end