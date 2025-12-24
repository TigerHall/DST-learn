--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 测试配方
    if TBAT.DEBUGGING then


        TBAT.MSC:RegisterRecipe("tbat_food_cooked_berry_rabbit_jelly",{
            -----------------------------------------
            ---
                time = 30,      --- 烹饪时间
                stacksize = 1,  --- 每次烹饪得到个数
            -----------------------------------------
            --- 配方
                recipe = {
                    {"log",1},
                    {"log",1},
                    {"goldnugget",1},
                    {"goldnugget",1},
                },
            -----------------------------------------
            --- 锅子上的贴图
                overridebuild = "tbat_food_cooked_berry_rabbit_jelly",
                overridesymbolname = "pot",
            -----------------------------------------
            --- ui 预览使用两种形式。fn 或者data
                -- preview = function(box)                    
                -- end,
                preview = {
                    atlas = "images/inventoryimages/tbat_food_cooked_berry_rabbit_jelly.xml",
                    image = "tbat_food_cooked_berry_rabbit_jelly.tex",
                },
            -----------------------------------------                                                
            --- 失败产品 ( 可以全是nil )
                fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
                fail_stacksize = 1,
                fail_overridebuild = "tbat_item_failed_potion",
                fail_overridesymbolname = "pot",
            -----------------------------------------
            --- 失败UI预览预览使用两种形式。fn 或者data
                -- fail_preview = function(box)                    
                -- end,
                fail_preview = {
                    atlas = "images/inventoryimages/tbat_item_failed_potion.xml",
                    image = "tbat_item_failed_potion.tex",
                },
            -----------------------------------------
        })


    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 示例模板
    -- TBAT.MSC:RegisterRecipe("tbat_food_cooked_berry_rabbit_jelly",{
    --     -----------------------------------------
    --     --- 配方
    --         time = 30,      --- 烹饪时间
    --         stacksize = 1,  --- 每次烹饪得到个数
    --         recipe = { {"log",1}, {"log",1}, {"goldnugget",1},{"goldnugget",1}, },
    --         overridebuild = "tbat_food_cooked_berry_rabbit_jelly",  -- 锅子上用的build
    --         overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
    --         preview = {
    --             atlas = "images/inventoryimages/tbat_food_cooked_berry_rabbit_jelly.xml",
    --             image = "tbat_food_cooked_berry_rabbit_jelly.tex",
    --         },
    --     -----------------------------------------                                                
    --     --- 失败产品 ( 可以全是nil )
    --         fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
    --         fail_stacksize = 1,
    --         fail_overridebuild = "tbat_item_failed_potion",
    --         fail_overridesymbolname = "pot",
    --         fail_preview = {
    --             atlas = "images/inventoryimages/tbat_food_cooked_berry_rabbit_jelly.xml",
    --             image = "tbat_food_cooked_berry_rabbit_jelly.tex",
    --         },
    --     -----------------------------------------
    -- })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 愿望之笺
    TBAT.MSC:RegisterRecipe("tbat_item_wish_note_potion",{
        -----------------------------------------
        --- 配方
            time = 30,      --- 烹饪时间
            stacksize = 1,  --- 每次烹饪得到个数
            recipe = { {"tbat_material_starshard_dust",20}, {"tbat_material_wish_token",20}, {"tbat_food_fantasy_apple",10},{"tbat_material_snow_plum_wolf_heart",2}, },
            overridebuild = "tbat_item_wish_note_potion",  -- 锅子上用的build
            overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
            preview = {
                atlas = "images/inventoryimages/tbat_item_wish_note_potion.xml",
                image = "tbat_item_wish_note_potion.tex",
            },
        -----------------------------------------                                                
        --- 失败产品 ( 可以全是nil )
            fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
            fail_stacksize = 1,
            fail_overridebuild = "tbat_item_failed_potion",
            fail_overridesymbolname = "pot",
            fail_preview = {
                atlas = "images/inventoryimages/tbat_item_wish_note_potion.xml",
                image = "tbat_item_wish_note_potion.tex",
            },
        -----------------------------------------
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 知识之纱
    TBAT.MSC:RegisterRecipe("tbat_item_veil_of_knowledge_potion",{
        -----------------------------------------
        --- 配方
            time = 30,      --- 烹饪时间
            stacksize = 1,  --- 每次烹饪得到个数
            recipe = { {"tbat_material_memory_crystal",10}, {"tbat_food_ephemeral_flower",6}, {"tbat_food_ephemeral_flower_butterfly_wings",6},{"tbat_item_crystal_bubble",4}, },
            overridebuild = "tbat_item_veil_of_knowledge_potion",  -- 锅子上用的build
            overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
            preview = {
                atlas = "images/inventoryimages/tbat_item_veil_of_knowledge_potion.xml",
                image = "tbat_item_veil_of_knowledge_potion.tex",
            },
        -----------------------------------------                                                
        --- 失败产品 ( 可以全是nil )
            fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
            fail_stacksize = 1,
            fail_overridebuild = "tbat_item_failed_potion",
            fail_overridesymbolname = "pot",
            fail_preview = {
                atlas = "images/inventoryimages/tbat_item_wish_note_potion.xml",
                image = "tbat_item_wish_note_potion.tex",
            },
        -----------------------------------------
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 勇气之誓
    TBAT.MSC:RegisterRecipe("tbat_item_oath_of_courage_potion",{
        -----------------------------------------
        --- 配方
            time = 30,      --- 烹饪时间
            stacksize = 1,  --- 每次烹饪得到个数
            recipe = { {"tbat_food_crimson_bramblefruit",10}, {"tbat_food_valorbush",10}, {"tbat_plant_fluorescent_moss_item",10},{"tbat_food_fantasy_potato",10}, },
            overridebuild = "tbat_item_oath_of_courage_potion",  -- 锅子上用的build
            overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
            preview = {
                atlas = "images/inventoryimages/tbat_item_oath_of_courage_potion.xml",
                image = "tbat_item_oath_of_courage_potion.tex",
            },
        -----------------------------------------                                                
        --- 失败产品 ( 可以全是nil )
            fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
            fail_stacksize = 1,
            fail_overridebuild = "tbat_item_failed_potion",
            fail_overridesymbolname = "pot",
            fail_preview = {
                atlas = "images/inventoryimages/tbat_item_wish_note_potion.xml",
                image = "tbat_item_wish_note_potion.tex",
            },
        -----------------------------------------
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 幸运之语
    TBAT.MSC:RegisterRecipe("tbat_item_lucky_words_potion",{
        -----------------------------------------
        --- 配方
            time = 30,      --- 烹饪时间
            stacksize = 1,  --- 每次烹饪得到个数
            recipe = { {"tbat_material_four_leaves_clover_feather",2}, {"tbat_material_osmanthus_wine",10}, {"tbat_food_lavender_flower_spike",10},{"tbat_material_emerald_feather",1}, },
            overridebuild = "tbat_item_lucky_words_potion",  -- 锅子上用的build
            overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
            preview = {
                atlas = "images/inventoryimages/tbat_item_lucky_words_potion.xml",
                image = "tbat_item_lucky_words_potion.tex",
            },
        -----------------------------------------                                                
        --- 失败产品 ( 可以全是nil )
            fail_product_prefab = "tbat_item_failed_potion",  --- 为nil的时候，该配方不会失败
            fail_stacksize = 1,
            fail_overridebuild = "tbat_item_failed_potion",
            fail_overridesymbolname = "pot",
            fail_preview = {
                atlas = "images/inventoryimages/tbat_item_wish_note_potion.xml",
                image = "tbat_item_wish_note_potion.tex",
            },
        -----------------------------------------
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 桃花之约
    TBAT.MSC:RegisterRecipe("tbat_item_peach_blossom_pact_potion",{
        -----------------------------------------
        --- 配方
            time = 30,      --- 烹饪时间
            stacksize = 1,  --- 每次烹饪得到个数
            recipe = { {"tbat_food_fantasy_peach",10}, {"tbat_food_cherry_blossom_petals",10}, {"tbat_food_pear_blossom_petals",10},{"tbat_plant_fluorescent_mushroom_item",10}, },
            overridebuild = "tbat_item_peach_blossom_pact_potion",  -- 锅子上用的build
            overridesymbolname = "pot",                             -- 锅子上用的symbol - layer
            preview = {
                atlas = "images/inventoryimages/tbat_item_peach_blossom_pact_potion.xml",
                image = "tbat_item_peach_blossom_pact_potion.tex",
            },
        -----------------------------------------
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------