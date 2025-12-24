--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 万物之树
    if TBAT.DEBUGGING then
        TBAT.RECIPE:AddRecipe(
            "tbat_the_tree_of_all_things_kit",            --  --  inst.prefab  实体名字
            TBAT.DEBUGGING and {} or { Ingredient("log", 2) }, 
            TECH.NONE,
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/map_icons/tbat_the_tree_of_all_things.xml",
                image = "tbat_the_tree_of_all_things.tex",
                -- placer = "tbat_the_tree_of_all_things_placer",
                -- min_spacing = 3,

            },
            "building"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 招募栏
    if TBAT.DEBUGGING then
        TBAT.RECIPE:AddRecipe(
            "tbat_building_recruitment_notice_board",            --  --  inst.prefab  实体名字
            {}, 
            TBAT.RECIPE:GetTech(),
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/map_icons/tbat_building_recruitment_notice_board.xml",
                image = "tbat_building_recruitment_notice_board.tex",
                placer = "tbat_building_recruitment_notice_board_placer",
                min_spacing = 0.5,
            },
            "building"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 公告栏
    if TBAT.DEBUGGING then
        TBAT.RECIPE:AddRecipe(
            "tbat_building_trade_notice_board",            --  --  inst.prefab  实体名字
            {}, 
            TBAT.RECIPE:GetTech(),
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/map_icons/tbat_building_trade_notice_board.xml",
                image = "tbat_building_trade_notice_board.tex",
                placer = "tbat_building_trade_notice_board_placer",
                min_spacing = 0.5,
            },
            "building"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 蘑菇小蜗埚
    TBAT.RECIPE:AddRecipe(
        "tbat_container_mushroom_snail_cauldron",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_fluorescent_moss_item",20},
            {"tbat_plant_fluorescent_mushroom_item",20},
            {"tbat_material_miragewood",20},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_mushroom_snail_cauldron.xml",
            image = "tbat_container_mushroom_snail_cauldron.tex",
            placer = "tbat_container_mushroom_snail_cauldron_placer",
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 梨花猫猫
    TBAT.RECIPE:AddRecipe(
        "tbat_container_pear_cat",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",8},
            {"tbat_food_pear_blossom_petals",8},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_pear_cat.xml",
            image = "tbat_container_pear_cat.tex",
            placer = "tbat_container_pear_cat_placer",
            min_spacing = 1,

        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 樱花兔兔
    TBAT.RECIPE:AddRecipe(
        "tbat_container_cherry_blossom_rabbit_mini",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",8},
            {"tbat_food_cherry_blossom_petals",8},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_cherry_blossom_rabbit_mini.xml",
            image = "tbat_container_cherry_blossom_rabbit_mini.tex",
            min_spacing = 0.5,

        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 翠羽鸟收集箱
    TBAT.RECIPE:AddRecipe(
        "tbat_container_emerald_feathered_bird_collection_chest",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_emerald_feather",1},
            {"tbat_material_wish_token",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_emerald_feathered_bird_collection_chest.xml",
            image = "tbat_container_emerald_feathered_bird_collection_chest.tex",
            placer = "tbat_container_emerald_feathered_bird_collection_chest_placer",
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 薰衣草小猫
    TBAT.RECIPE:AddRecipe(
        "tbat_container_lavender_kitty",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_lavender_flower_spike",20},
            {"tbat_material_lavender_laundry_detergent",10},
            {"tbat_material_memory_crystal",50},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_lavender_kitty.xml",
            image = "tbat_container_lavender_kitty.tex",
            placer = "tbat_container_lavender_kitty_placer",
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 小小鹤草箱
    TBAT.RECIPE:AddRecipe(
        "tbat_container_little_crane_bird",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_four_leaves_clover_feather",6},
            {"tbat_material_miragewood",10},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_little_crane_bird.xml",
            image = "tbat_container_little_crane_bird.tex",
            placer = "tbat_container_little_crane_bird_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 星琴小兔
    TBAT.RECIPE:AddRecipe(
        "tbat_building_piano_rabbit_researchlab2",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_wish_token",2},
            {"tbat_material_starshard_dust",10},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_piano_rabbit.xml",
            image = "tbat_building_piano_rabbit.tex",
            placer = "tbat_building_piano_rabbit_placer",
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 向日葵仓鼠灯
    TBAT.RECIPE:AddRecipe(
        "tbat_building_sunflower_hamster",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_sunflower_seeds",6},
            {"tbat_animal_ephemeral_butterfly",2},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_sunflower_hamster.xml",
            image = "tbat_building_sunflower_hamster.tex",
            placer = "tbat_building_sunflower_hamster_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 梅雪木屋
    TBAT.RECIPE:AddRecipe(
        "tbat_building_snow_plum_pet_house",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_snow_plum_wolf_hair",10},
            {"tbat_material_snow_plum_wolf_heart",1},
            {"tbat_material_white_plum_blossom",10},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_snow_plum_pet_house.xml",
            image = "tbat_building_snow_plum_pet_house.tex",
            placer = "tbat_building_snow_plum_pet_house_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 桂猫石屋
    TBAT.RECIPE:AddRecipe(
        "tbat_building_osmanthus_cat_pet_house",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_osmanthus_wine",10},
            {"tbat_material_osmanthus_ball",5},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_osmanthus_cat_pet_house.xml",
            image = "tbat_building_osmanthus_cat_pet_house.tex",
            placer = "tbat_building_osmanthus_cat_pet_house_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 秋枫树屋
    TBAT.RECIPE:AddRecipe(
        "tbat_building_maple_squirrel_pet_house",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_liquid_of_maple_leaves",10},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_squirrel_incisors",5},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_maple_squirrel_pet_house.xml",
            image = "tbat_building_maple_squirrel_pet_house.tex",
            placer = "tbat_building_maple_squirrel_pet_house_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 鼠鼠囤货箱
    TBAT.RECIPE:AddRecipe(
        "tbat_container_squirrel_stash_box",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",10},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_container_squirrel_stash_box.xml",
            image = "tbat_container_squirrel_stash_box.tex",
            placer = "tbat_container_squirrel_stash_box_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 森林蘑菇小窝
    TBAT.RECIPE:AddRecipe(
        "tbat_building_forest_mushroom_cottage",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_fluorescent_moss_item",20},
            {"tbat_plant_fluorescent_mushroom_item",20},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_forest_mushroom_cottage.xml",
            image = "tbat_building_forest_mushroom_cottage.tex",
            placer = "tbat_building_forest_mushroom_cottage_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 四叶草鹤雕像
    TBAT.RECIPE:AddRecipe(
        "tbat_building_four_leaves_clover_crane_lv1",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_four_leaves_clover_feather",10},
            {"tbat_material_wish_token",10},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_four_leaves_clover_crane_lv1.xml",
            image = "tbat_building_four_leaves_clover_crane_lv1.tex",
            placer = "tbat_building_four_leaves_clover_crane_lv1_placer",
            min_spacing = 0.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 薰衣草花房
    TBAT.RECIPE:AddRecipe(
        "tbat_building_lavender_flower_house",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_food_lavender_flower_spike",10},
            {"tbat_material_lavender_laundry_detergent",10},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_miragewood",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_lavender_flower_house.xml",
            image = "tbat_building_lavender_flower_house.tex",
            placer = "tbat_building_lavender_flower_house_placer",
            min_spacing = 1.5,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 礁石灯塔
    TBAT.RECIPE:AddRecipe(
        "tbat_building_reef_lighthouse",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_item_crystal_bubble",10},
            {"tbat_food_ephemeral_flower",10},
            {"tbat_item_holo_maple_leaf",5},
            {"tbat_material_memory_crystal",50},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/map_icons/tbat_building_reef_lighthouse.xml",
            image = "tbat_building_reef_lighthouse.tex",
            placer = "tbat_building_reef_lighthouse_placer",
            min_spacing = 1.5,
            -- build_distance = 15,
            build_mode = TBAT.RECIPE.BUILDMODE_LAND_WATER,
            -- testfn = function(pt,rot) return true end,
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 刺猬小仙盆栽
    TBAT.RECIPE:AddRecipe(
        "tbat_plant_hedgehog_cactus_pot",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",10},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_plant_hedgehog_cactus_pot.xml",
            image = "tbat_plant_hedgehog_cactus_pot.tex",
        },
        "building"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------