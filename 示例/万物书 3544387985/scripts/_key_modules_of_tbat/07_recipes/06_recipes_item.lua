--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 锚点之杖
    if TBAT.DEBUGGING then
        TBAT.RECIPE:AddRecipe(
            "tbat_eq_anchor_cane",            --  --  inst.prefab  实体名字
            {}, 
            TECH.NONE,
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = GetInventoryItemAtlas("cane.tex"),
                image = "cane.tex",
                -- placer = "tbat_the_tree_of_all_things_placer",
                -- min_spacing = 3,
            },
            "item"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 幻想工具
    TBAT.RECIPE:AddRecipe(
        "tbat_eq_fantasy_tool",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_wish_token",10},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_eq_fantasy_tool.xml",
            image = "tbat_eq_fantasy_tool.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 蝴蝶打包纸
    if TBAT.CONFIG.BUTTERFLY_WARPPING_PAPAER ~= 0 then
        TBAT.RECIPE:AddRecipe(
            "tbat_item_butterfly_wrapping_paper",            --  --  inst.prefab  实体名字
            { TBAT.RECIPE:CreateList({
                {"tbat_material_dandelion_umbrella",1},
                {"tbat_item_holo_maple_leaf",10},
            }) }, 
            TBAT.RECIPE:GetTech(),
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/inventoryimages/tbat_item_butterfly_wrapping_paper.xml",
                image = "tbat_item_butterfly_wrapping_paper.tex",
                -- numtogive = 20
            },
            "item"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 万物指挥棒
    TBAT.RECIPE:AddRecipe(
        "tbat_eq_universal_baton",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_miragewood",2},
            {"tbat_food_cherry_blossom_petals",4},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_eq_universal_baton_2.xml",
            image = "tbat_eq_universal_baton_2.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摇摇杯
    if TBAT.DEBUGGING then
        TBAT.RECIPE:AddRecipe(
            "tbat_eq_shake_cup",            --  --  inst.prefab  实体名字
            TBAT.DEBUGGING and {} or { Ingredient("log", 2) }, 
            TBAT.RECIPE:GetTech(),
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/inventoryimages/tbat_eq_shake_cup.xml",
                image = "tbat_eq_shake_cup.tex",
                -- numtogive = 20
            },
            "item"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 枫叶松鼠
    TBAT.RECIPE:AddRecipe(
        "tbat_item_maple_squirrel_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_squirrel_incisors",5},
            {"tbat_material_liquid_of_maple_leaves",10},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_item_maple_squirrel_kit.xml",
            image = "tbat_item_maple_squirrel_kit.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 梅雪小狼
    TBAT.RECIPE:AddRecipe(
        "tbat_item_snow_plum_wolf_kit",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_snow_plum_wolf_hair",10},
            {"tbat_material_snow_plum_wolf_heart",1},
            {"tbat_material_white_plum_blossom",2},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_item_snow_plum_wolf_kit.xml",
            image = "tbat_item_snow_plum_wolf_kit.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 万物穿梭
    if TBAT.CONFIG.EQ_WORLD_SKIPPER then
        TBAT.RECIPE:AddRecipe(
            "tbat_eq_world_skipper",            --  --  inst.prefab  实体名字
            { TBAT.RECIPE:CreateList({
                {"tbat_material_starshard_dust",1},
                {"tbat_material_emerald_feather",1},
            }) }, 
            TBAT.RECIPE:GetTech(),
            {
                -- nounlock=true,
                no_deconstruction=false,
                atlas = "images/inventoryimages/tbat_eq_world_skipper.xml",
                image = "tbat_eq_world_skipper.tex",
                -- numtogive = 20
            },
            "item"
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 传送核心
    TBAT.RECIPE:AddRecipe(
        "tbat_item_trans_core",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_starshard_dust",1},
            {"tbat_material_dandelion_umbrella",1},
        }) }, 
        TBAT.RECIPE:GetTech(),
        {
            -- nounlock=true,
            no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_item_trans_core.xml",
            image = "tbat_item_trans_core.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 猫猫花环
    TBAT.RECIPE:AddRecipe(
        "tbat_eq_furrycat_circlet",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_material_osmanthus_ball",1},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_eq_furrycat_circlet.xml",
            image = "tbat_eq_furrycat_circlet.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 鳐鱼帽子
    TBAT.RECIPE:AddRecipe(
        "tbat_eq_ray_fish_hat",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_item_crystal_bubble",10},
            {"tbat_material_memory_crystal",20},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_eq_ray_fish_hat.xml",
            image = "tbat_eq_ray_fish_hat.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 小蜗护甲
    TBAT.RECIPE:AddRecipe(
        "tbat_eq_snail_shell_of_mushroom",            --  --  inst.prefab  实体名字
        { TBAT.RECIPE:CreateList({
            {"tbat_plant_fluorescent_mushroom_item",10},
            {"tbat_plant_fluorescent_moss_item",10},
            {"tbat_sensangu_item",1},
        }) }, 
        TBAT.RECIPE:GetLostTech(),
        {
            -- nounlock=true,
            -- no_deconstruction=false,
            atlas = "images/inventoryimages/tbat_eq_snail_shell_of_mushroom.xml",
            image = "tbat_eq_snail_shell_of_mushroom.tex",
            -- numtogive = 20
        },
        "item"
    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------