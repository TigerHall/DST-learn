--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 森林矮灯
    TBAT.RECIPE:AddRecipe(
        "tbat_building_woodland_lamp",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_osmanthus_ball",2},
            {"tbat_material_white_plum_blossom",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_woodland_lamp.xml",
            image = "tbat_building_woodland_lamp.tex",
            placer = "tbat_building_woodland_lamp_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 梅花木墙
    TBAT.RECIPE:AddRecipe(
        "wall_tbat_wood_item",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",2},
            {"tbat_material_white_plum_blossom",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/wall_tbat_wood.xml",
            image = "wall_tbat_wood.tex",
            numtogive = 8
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 枫叶草墙
    TBAT.RECIPE:AddRecipe(
        "wall_tbat_maple_item",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_liquid_of_maple_leaves",1},
            {"tbat_item_holo_maple_leaf",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/wall_tbat_maple.xml",
            image = "wall_tbat_maple.tex",
            numtogive = 6
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 桂花石墙
    TBAT.RECIPE:AddRecipe(
        "wall_tbat_osmanthus_stone_item",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_osmanthus_wine",1},
            {"tbat_material_osmanthus_ball",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/wall_tbat_osmanthus_stone.xml",
            image = "wall_tbat_osmanthus_stone.tex",
            numtogive = 6
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 粉绒花毯 
    TBAT.RECIPE:AddRecipe(
        "tbat_turf_carpet_pink_fur",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",4},
            {"tbat_food_cherry_blossom_petals",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_turf_carpet_pink_fur.xml",
            image = "tbat_turf_carpet_pink_fur.tex",
            -- numtogive = 20
            placer = "tbat_turf_carpet_pink_fur_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 萌爪喵地垫 
    TBAT.RECIPE:AddRecipe(
        "tbat_turf_carpet_cat_claw",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_pear_blossom_petals",4},
            {"tbat_material_dandycat",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_turf_carpet_cat_claw.xml",
            image = "tbat_turf_carpet_cat_claw.tex",
            -- numtogive = 20
            placer = "tbat_turf_carpet_cat_claw_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 幸运草团 
    TBAT.RECIPE:AddRecipe(
        "tbat_turf_carpet_four_leaves_clover",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_fluorescent_moss_item",1},
            {"tbat_food_ephemeral_flower",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_turf_carpet_four_leaves_clover.xml",
            image = "tbat_turf_carpet_four_leaves_clover.tex",
            -- numtogive = 20
            placer = "tbat_turf_carpet_four_leaves_clover_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 发光的路灯花 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_green_campanula_with_cat",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",10},
            {"tbat_animal_ephemeral_butterfly",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_green_campanula_with_cat.xml",
            image = "tbat_building_green_campanula_with_cat.tex",
            -- numtogive = 20
            placer = "tbat_building_green_campanula_with_cat_placer",
            -- min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 双生小鹅灯 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_twin_goslings",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",4},
            {"tbat_material_dandycat",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_twin_goslings.xml",
            image = "tbat_building_twin_goslings.tex",
            -- numtogive = 20
            placer = "tbat_building_twin_goslings_placer",
            -- min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 花语云梦灯 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_lamp_moon_with_clouds",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_animal_ephemeral_butterfly",1},
            {"tbat_material_starshard_dust",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_lamp_moon_with_clouds.xml",
            image = "tbat_building_lamp_moon_with_clouds.tex",
            -- numtogive = 20
            placer = "tbat_building_lamp_moon_with_clouds_placer",
            -- min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 软木餐桌
    TBAT.RECIPE:AddRecipe(
        "tbat_building_stump_table",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",10},
            {"tbat_material_liquid_of_maple_leaves",3},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_stump_table.xml",
            image = "tbat_building_stump_table.tex",
            placer = "tbat_building_stump_table_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 魔法药剂柜
    TBAT.RECIPE:AddRecipe(
        "tbat_building_magic_potion_cabinet",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",5},
            {"tbat_material_liquid_of_maple_leaves",2},
            {"tbat_material_osmanthus_wine",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet.xml",
            image = "tbat_building_magic_potion_cabinet.tex",
            placer = "tbat_building_magic_potion_cabinet_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 梅花餐桌
    TBAT.RECIPE:AddRecipe(
        "tbat_building_plum_blossom_table",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",1},
            {"tbat_material_white_plum_blossom",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_plum_blossom_table.xml",
            image = "tbat_building_plum_blossom_table.tex",
            placer = "tbat_building_plum_blossom_table_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 梅花灶台
    TBAT.RECIPE:AddRecipe(
        "tbat_building_plum_blossom_hearth",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",1},
            {"tbat_material_white_plum_blossom",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_plum_blossom_hearth.xml",
            image = "tbat_building_plum_blossom_hearth.tex",
            placer = "tbat_building_plum_blossom_hearth_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 樱花兔兔秋千
    TBAT.RECIPE:AddRecipe(
        "tbat_building_cherry_blossom_rabbit_swing",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",30},
            {"tbat_food_cherry_blossom_petals",40},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_cherry_blossom_rabbit_swing.xml",
            image = "tbat_building_cherry_blossom_rabbit_swing.tex",
            placer = "tbat_building_cherry_blossom_rabbit_swing_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 彼岸花摇椅
    TBAT.RECIPE:AddRecipe(
        "tbat_building_red_spider_lily_rocking_chair",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_wish_token",5},
            {"tbat_material_osmanthus_ball",5},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_red_spider_lily_rocking_chair.xml",
            image = "tbat_building_red_spider_lily_rocking_chair.tex",
            placer = "tbat_building_red_spider_lily_rocking_chair_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 原木沙发
    TBAT.RECIPE:AddRecipe(
        "tbat_building_rough_cut_wood_sofa",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",8},
            {"tbat_material_liquid_of_maple_leaves",5},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_rough_cut_wood_sofa.xml",
            image = "tbat_building_rough_cut_wood_sofa.tex",
            placer = "tbat_building_rough_cut_wood_sofa_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 松鼠留声机
    TBAT.RECIPE:AddRecipe(
        "tbat_building_whisper_tome_squirrel_phonograph",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_squirrel_incisors",3},
            {"tbat_material_wish_token",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_whisper_tome_squirrel_phonograph.xml",
            image = "tbat_building_whisper_tome_squirrel_phonograph.tex",
            placer = "tbat_building_whisper_tome_squirrel_phonograph_placer",
            min_spacing = 0.5,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 围边海螺贝壳装饰
    TBAT.RECIPE:AddRecipe(
        "tbat_building_conch_shell_decoration_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_white_plum_blossom",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_conch_shell_decoration_1.xml",
            image = "tbat_building_conch_shell_decoration_1.tex",
            numtogive = 6
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 围边星星云朵装饰
    TBAT.RECIPE:AddRecipe(
        "tbat_building_star_and_cloud_decoration_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_starshard_dust",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_star_and_cloud_decoration_1.xml",
            image = "tbat_building_star_and_cloud_decoration_1.tex",
            numtogive = 6
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 围边雪花雪人装饰
    TBAT.RECIPE:AddRecipe(
        "tbat_building_snowflake_decoration_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_dandelion_umbrella",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_snowflake_decoration_1.xml",
            image = "tbat_building_snowflake_decoration_1.tex",
            numtogive = 6
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 萌宠小石雕
    TBAT.RECIPE:AddRecipe(
        "tbat_building_cute_pet_stone_figurines_kit",            --  --  inst.prefab  实体名字
        { Ingredient("rocks", 1) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_cute_pet_stone_figurines_1.xml",
            image = "tbat_building_cute_pet_stone_figurines_1.tex",
            numtogive = 3
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 萌宠装饰雕像
    TBAT.RECIPE:AddRecipe(
        "tbat_building_cute_animal_decorative_figurines_kit",            --  --  inst.prefab  实体名字
        { Ingredient("rocks", 2) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_cute_animal_decorative_figurines_1.xml",
            image = "tbat_building_cute_animal_decorative_figurines_1.tex",
            numtogive = 1
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 萌宠装饰木桩
    TBAT.RECIPE:AddRecipe(
        "tbat_building_cute_animal_wooden_figurines_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_cute_animal_wooden_figurines_1.xml",
            image = "tbat_building_cute_animal_wooden_figurines_1.tex",
            numtogive = 3
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 石雕台阶
    TBAT.RECIPE:AddRecipe(
        "tbat_building_carved_stone_tiles_kit",            --  --  inst.prefab  实体名字
        { Ingredient("rocks", 1) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_carved_stone_tiles_1.xml",
            image = "tbat_building_carved_stone_tiles_1.tex",
            numtogive = 3
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 地皮
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_emerald_feather_leaves",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_emerald_feather",1},
            {"tbat_food_pear_blossom_petals",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_emerald_feather_leaves.xml",
            image = "tbat_turf_emerald_feather_leaves.tex",
            numtogive = 8
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_fallen_cherry_blossoms",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",4},
            {"tbat_food_cherry_blossom_petals",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_fallen_cherry_blossoms.xml",
            image = "tbat_turf_fallen_cherry_blossoms.tex",
            numtogive = 20
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_pearblossom_brewed_with_snow",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",4},
            {"tbat_food_pear_blossom_petals",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_pearblossom_brewed_with_snow.xml",
            image = "tbat_turf_pearblossom_brewed_with_snow.tex",
            numtogive = 20
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_clover_butterfly",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_fluorescent_mushroom_item",4},
            {"tbat_plant_fluorescent_moss_item",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_clover_butterfly.xml",
            image = "tbat_turf_clover_butterfly.tex",
            numtogive = 20
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_water_sparkles",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_item_crystal_bubble",1},
            {"tbat_material_memory_crystal",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_water_sparkles.xml",
            image = "tbat_turf_water_sparkles.tex",
            numtogive = 20
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "turf_tbat_turf_lavender_dusk",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_lavender_flower_spike",4},
            {"tbat_food_ephemeral_flower",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_lavender_dusk.xml",
            image = "tbat_turf_lavender_dusk.tex",
            numtogive = 20
        },
        "decoration"
    )
    TBAT.RECIPE:AddRecipe(
        "tbat_turfs_pack_chesspieces",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_dandycat",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_checkerfloor_pink.xml",
            image = "tbat_turf_checkerfloor_pink.tex",
            -- numtogive = 20
        },
        "decoration"
    )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_checkerfloor_blue",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_checkerfloor_blue.xml",
    --         image = "tbat_turf_checkerfloor_blue.tex",
    --         numtogive = 20
    --     },
    --     "decoration"
    -- )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_checkerfloor_pink",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_checkerfloor_pink.xml",
    --         image = "tbat_turf_checkerfloor_pink.tex",
    --         numtogive = 20
    --     },
    --     "decoration"
    -- )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_checkerfloor_orange",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_checkerfloor_orange.xml",
    --         image = "tbat_turf_checkerfloor_orange.tex",
    --         numtogive = 20
    --     },
    --     "decoration"
    -- )
    TBAT.RECIPE:AddRecipe(
        "tbat_turfs_pack_ocean",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_coconut_cat_fruit",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_turf_fake_ocean_shallow.xml",
            image = "tbat_turf_fake_ocean_shallow.tex",
            -- numtogive = 4
        },
        "decoration"
    )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_fake_ocean_shallow",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_fake_ocean_shallow.xml",
    --         image = "tbat_turf_fake_ocean_shallow.tex",
    --         numtogive = 4
    --     },
    --     "decoration"
    -- )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_fake_ocean_middle",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_fake_ocean_middle.xml",
    --         image = "tbat_turf_fake_ocean_middle.tex",
    --         numtogive = 4
    --     },
    --     "decoration"
    -- )
    -- TBAT.RECIPE:AddRecipe(
    --     "turf_tbat_turf_fake_ocean_deep",            --  --  inst.prefab  实体名字
    --     { TBAT.RECIPE:CreateList({
    --         {"tbat_material_miragewood",4},
    --         {"tbat_food_pear_blossom_petals",4},
    --     }) }, 
    --     TBAT.RECIPE:GetTech(),
    --     {
    --         -- nounlock=true,
    --         no_deconstruction=false,
    --         atlas = "images/inventoryimages/tbat_turf_fake_ocean_deep.xml",
    --         image = "tbat_turf_fake_ocean_deep.tex",
    --         numtogive = 4
    --     },
    --     "decoration"
    -- )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 云朵小木牌 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_cloud_wooden_sign",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",6},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_cloud_wooden_sign.xml",
            image = "tbat_building_cloud_wooden_sign.tex",
            -- numtogive = 20
            placer = "tbat_building_cloud_wooden_sign_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 喵喵小木牌 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_kitty_wooden_sign",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",6},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_kitty_wooden_sign.xml",
            image = "tbat_building_kitty_wooden_sign.tex",
            -- numtogive = 20
            placer = "tbat_building_kitty_wooden_sign_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 兔兔小木牌 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_bunny_wooden_sign",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",6},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_bunny_wooden_sign.xml",
            image = "tbat_building_bunny_wooden_sign.tex",
            -- numtogive = 20
            placer = "tbat_building_bunny_wooden_sign_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 喵蒲装饰草丛 
    TBAT.RECIPE:AddRecipe(
        "tbat_plant_kitty_cattail",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_dandycat_kit",1},
            {"tbat_material_dandycat",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_plant_kitty_cattail.xml",
            image = "tbat_plant_kitty_cattail.tex",
            -- numtogive = 20
            placer = "tbat_plant_kitty_cattail_placer",
            min_spacing = 0,
            sg_state = "doshortaction",
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 时光壁炉 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_time_fireplace",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",10},
            {"tbat_material_starshard_dust",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_building_time_fireplace.xml",
            image = "tbat_building_time_fireplace.tex",
            -- numtogive = 20
            placer = "tbat_building_time_fireplace_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 猫猫草墩 
    TBAT.RECIPE:AddRecipe(
        "tbat_plant_kitty_bush",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_dandycat_kit",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_plant_kitty_bush.xml",
            image = "tbat_plant_kitty_bush.tex",
            -- numtogive = 20
            placer = "tbat_plant_kitty_bush_placer",
            min_spacing = 0,    
            sg_state = "doshortaction",
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 河边石子 
    TBAT.RECIPE:AddRecipe(
        "tbat_resource_river_pebble_item",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_memory_crystal",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_resource_river_pebble.xml",
            image = "tbat_resource_river_pebble.tex",
            numtogive = 6,
            -- placer = "tbat_resource_river_pebble_placer",
            min_spacing = 0,
            -- sg_state = "doshortaction",
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 池边水草 
    TBAT.RECIPE:AddRecipe(
        "tbat_plant_water_plants_of_pond",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_lavender_flower_spike",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_plant_water_plants_of_pond.xml",
            image = "tbat_plant_water_plants_of_pond.tex",
            -- numtogive = 20
            placer = "tbat_plant_water_plants_of_pond_placer",
            min_spacing = 0,
            sg_state = "doshortaction",
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 花喵小石子 
    TBAT.RECIPE:AddRecipe(
        "tbat_resource_kitty_stone_item",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_memory_crystal",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_resource_kitty_stone.xml",
            image = "tbat_resource_kitty_stone.tex",
            numtogive = 6,
            -- placer = "tbat_resource_kitty_stone_placer",
            -- min_spacing = 0,
            -- sg_state = "doshortaction",
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 雕像展示架 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_chesspiece_display_stand",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_memory_crystal",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_chesspiece_display_stand.xml",
            image = "tbat_building_chesspiece_display_stand.tex",
            -- numtogive = 20
            placer = "tbat_building_chesspiece_display_stand_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 萌宠装饰盆栽 
    TBAT.RECIPE:AddRecipe(
        "tbat_building_pot_animals_with_flowers",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_cherry_blossom_petals",2},
            {"tbat_food_pear_blossom_petals",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_pot_animals_with_flowers.xml",
            image = "tbat_building_pot_animals_with_flowers.tex",
            -- numtogive = 20
            placer = "tbat_building_pot_animals_with_flowers_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 梅影装饰花丛 
    TBAT.RECIPE:AddRecipe(
        "tbat_plant_plum_blossom_bush",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",1},
            {"tbat_material_white_plum_blossom",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_plant_plum_blossom_bush.xml",
            image = "tbat_plant_plum_blossom_bush.tex",
            -- numtogive = 20
            placer = "tbat_plant_plum_blossom_bush_placer",
            min_spacing = 0,
        },
        "decoration"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------