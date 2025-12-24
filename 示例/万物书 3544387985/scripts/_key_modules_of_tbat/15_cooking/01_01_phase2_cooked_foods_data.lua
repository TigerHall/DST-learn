--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    local fwd_in_pdt_food_mixed_potato_soup = {
        test = function(cooker, names, tags)
            return (names.ice and names.ice >= 2) 
            and ( (names.potato or 0) + (names.potato_cooked or 0) >= 1) 
            and (tags.veggie and tags.veggie >=2)

            -- local ice_value = names.ice or 0
            -- local potato_value = names.potato or 0
            -- local potato_cooked_value = names.potato_cooked or 0
            -- local veggie_value = tags.veggie or 0
            -- if ice_value == 2 and potato_value + potato_cooked_value >= 1 and veggie_value >=2 then
            --     return true
            -- end
            -- return false
        end,
        name = "fwd_in_pdt_food_mixed_potato_soup", -- 料理名
        weight = 10, -- 食谱权重
        priority = 999, -- 食谱优先级
        foodtype = GLOBAL.FOODTYPE.GOODIES, --料理的食物类型，比如这里定义的是肉类
        hunger = 150, --吃后回饥饿值
        sanity = 30, --吃后回精神值
        health = 20, --吃后回血值
        stacksize = 1,  --- 每次烹饪得到个数
        perishtime = TUNING.PERISH_TWO_DAY*5, --腐烂时间
        cooktime = TUNING.FWD_IN_PDT_MOD___DEBUGGING_MODE and 1/4 or 30/20, --烹饪时间(单位20s :  数字1 为 20s ,)
        potlevel = "low",  --- 锅里的贴图位置 low high  mid
        cookbook_tex = "fwd_in_pdt_food_mixed_potato_soup.tex", -- 在游戏内食谱书里的mod食物那一栏里显示的图标，tex在 atlas的xml里定义了，所以这里只写文件名即可
        cookbook_atlas = "images/inventoryimages/fwd_in_pdt_food_mixed_potato_soup.xml",  
        overridebuild = "fwd_in_pdt_food_mixed_potato_soup",          ----- build (zip名字)
        overridesymbolname = "png",     ----- scml 的图层名字（图片所在的文件夹名）
        floater = {"med", nil, 0.55},
        oneat_desc = GetStringsTable("fwd_in_pdt_food_mixed_potato_soup")["oneat_desc"],    --- 副作用一栏显示的文本
        cookbook_category = "portablecookpot"
        -- temperature = TUNING.HOT_FOOD_BONUS_TEMP,          -- 这个是作用升温和降温的没试过数字行不行带HOT就是升温 COLD就是降温
	    -- temperatureduration = TUNING.FOOD_TEMP_LONG,     -- 这个是升温或者降温持续时间
    }

    -- AddCookerRecipe("cookpot", fwd_in_pdt_food_mixed_potato_soup) -- 将食谱添加进普通锅
    AddCookerRecipe("portablecookpot", fwd_in_pdt_food_mixed_potato_soup) -- 将食谱添加进便携锅(大厨锅)
    AddCookerRecipe("archive_cookpot", fwd_in_pdt_food_mixed_potato_soup) --档案馆远古窑，有好多mod作者忽略了这口锅

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local ALL_FOODS_DATA = {        
        ["tbat_food_cooked_honey_meat_tower"] = {
                ["name"] = "蜜汁肉肉塔",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 666,
                        healthvalue = 66,
                        sanityvalue = 66,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*30,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间
                        oneaten = function(inst, eater)
                                if eater:HasTag("player") then
                                        eater:AddDebuff("tbat_food_cooked_honey_meat_tower_debuff","tbat_food_cooked_honey_meat_tower_debuff")
                                        if eater.components.talker then
                                                eater.components.talker:Say(TBAT:GetString2("tbat_food_cooked_honey_meat_tower","oneat_talk"))
                                        end
                                end
                        end,
                        custom_init_fn = function(inst) -- 自定义初始化
                        end,
                        master_init_fn = function(inst) -- 自定义初始化
                        end,
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 10,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return 
                                        ( (names.meat or 0) + (names.cookedmeat or 0) == 1 )
                                        and ( (names.tallbirdegg or 0) + (names.tallbirdegg_cooked or 0) == 1 )
                                        and ( (names.potato or 0) + (names.potato_cooked or 0) == 1 )
                                        and ( (names.trunk_summer or 0) + (names.trunk_cooked or 0) + (names.trunk_winter or 0) == 1 )
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_blossom_roll"] = {
                ["name"] = "樱花可颂卷",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 58,
                        healthvalue = 3,
                        sanityvalue = 3,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 15,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_cherry_blossom_petals == 3)
                                and (tags.egg or 0) >= 0.5
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_fairy_hug"] = {
                ["name"] = "抱抱小仙卷",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 68,
                        healthvalue = 5,
                        sanityvalue = 5,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 20,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_hedgehog_cactus_meat or 0) == 3
                                and (names.tbat_food_crimson_bramblefruit or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_rose_whisper_tea"] = {
                ["name"] = "玫瑰花语茶",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 5,
                        healthvalue = 50,
                        sanityvalue = 5,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 15,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_valorbush or 0) == 3
                                and (names.ice or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_apple_snow_sundae"] = {
                ["name"] = "苹果雪山圣代",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 5,
                        healthvalue = 5,
                        sanityvalue = 50,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 15,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 3
                                and (names.ice or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_berry_rabbit_jelly"] = {
                ["name"] = "莓果兔兔冻",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 50,
                        healthvalue = 0,
                        sanityvalue = 50,
                        foodtype = FOODTYPE.VEGGIE,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 30,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) >= 1
                                        and (names.tbat_food_crimson_bramblefruit or 0) >= 1
                                        and names.honey
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_garden_table_cake"] = {
                ["name"] = "花园物语蛋糕",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 80,
                        healthvalue = 5,
                        sanityvalue = 30,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 20,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) >= 1
                                        and (names.tbat_food_cherry_blossom_petals or 0) >= 2
                                        and (tags.sweetener or 0) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_peach_pudding_rabbit"] = {
                ["name"] = "蜜桃布丁兔",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 80,
                        healthvalue = 30,
                        sanityvalue = 30,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 25,                      --- 烹饪时间（秒）
                        potlevel = "mid",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) == 1
                                and (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 1
                                and (names.tbat_food_fantasy_potato or 0) + (names.tbat_food_fantasy_potato_cooked or 0) == 1
                                and (names.tbat_food_cherry_blossom_petals or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_potato_fantasy_pie"] = {
                ["name"] = "土豆奇幻派",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 100,
                        healthvalue = 20,
                        sanityvalue = 20,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 20,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 1
                                and (names.tbat_food_fantasy_potato or 0) + (names.tbat_food_fantasy_potato_cooked or 0) == 1
                                and (names.tbat_food_cherry_blossom_petals or 0) == 1
                                and (names.tbat_food_pear_blossom_petals or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_peach_rabbit_mousse"] = {
                ["name"] = "桃兔花椰慕斯",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 80,
                        healthvalue = 5,
                        sanityvalue = 50,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 15,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_crimson_bramblefruit or 0) == 2
                                and (names.tbat_food_cocoanut or 0) == 1
                                and (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_rainbow_rabbit_milkshake"] = {
                ["name"] = "彩虹兔兔奶昔",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 10,
                        healthvalue = 10,
                        sanityvalue = 100,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*10,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 20,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) == 1
                                and (names.tbat_food_cherry_blossom_petals or 0) == 1
                                and (names.tbat_food_pear_blossom_petals or 0) == 1
                                and (names.ice or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_forest_garden_roll"] = {
                ["name"] = "花境森林卷",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 30,
                        healthvalue = 30,
                        sanityvalue = 30,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 10,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 1
                                and (names.tbat_food_valorbush or 0) == 2
                                and (tags.fruit or 0) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_flower_bunny_cake"] = {
                ["name"] = "花兔彩绮蛋糕",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 200,
                        healthvalue = 100,
                        sanityvalue = 200,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 60,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_fantasy_peach or 0) + (names.tbat_food_fantasy_peach_cooked or 0) == 1
                                and (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 1
                                and (names.tbat_food_cherry_blossom_petals or 0) == 1
                                and (tags.dairy or 0) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_star_sea_jelly_cup"] = {
                ["name"] = "星海水母冰杯",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 30,
                        healthvalue = 60,
                        sanityvalue = 120,
                        foodtype = FOODTYPE.GOODIES,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 30,                      --- 烹饪时间（秒）
                        potlevel = "low",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_jellyfish or 0) == 1
                                and (names.ice or 0) == 1
                                and (names.tbat_food_crimson_bramblefruit or 0) == 1
                                and (tags.sweetener) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_snow_sheep_sushi"] = {
                ["name"] = "雪顶绵羊寿司",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 150,
                        healthvalue = 10,
                        sanityvalue = 150,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 40,                      --- 烹饪时间（秒）
                        potlevel = "mid",  --- 锅里的贴图位置 low high  
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                        return (names.tbat_food_jellyfish and names.tbat_food_jellyfish >= 2)
                                and (names.tbat_food_pear_blossom_petals or 0) == 1
                                and (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_forest_dream_bento"] = {
                ["name"] = "森林梦境便当",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 100,
                        healthvalue = 10,
                        sanityvalue = 30,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 20,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_hedgehog_cactus_meat or 0)  == 2
                                and (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) >= 1
                                and (names.tbat_food_fantasy_potato or 0)  + (names.tbat_food_fantasy_potato_cooked or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_bear_sun_platter"] = {
                ["name"] = "小熊阳光拼盘",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 150,
                        healthvalue = 10,
                        sanityvalue = 10,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 25,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_hedgehog_cactus_meat or 0)  == 1
                                and (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) >= 2
                                and (tags.veggie or 0)  >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_bamboo_cat_bbq_skewers"] = {
                ["name"] = "竹香小咪烤串",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 50,
                        healthvalue = 10,
                        sanityvalue = 50,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 15,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) == 1
                                and (names.tbat_food_fantasy_potato or 0) + (names.tbat_food_fantasy_potato_cooked or 0) == 1
                                and (names.tbat_food_fantasy_apple or 0) + (names.tbat_food_fantasy_apple_cooked or 0) == 1
                                and (names.twigs or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_flower_whisper_ramen"] = {
                ["name"] = "花香耳语拉面",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 150,
                        healthvalue = 10,
                        sanityvalue = 10,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 40,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) >= 1
                                and (names.tbat_food_ephemeral_flower or 0) >= 2
                                and (tags.egg or 0) >= 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_cloud_rabbit_steamed_bun"] = {
                ["name"] = "软绵云兔馒头",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 80,
                        healthvalue = 10,
                        sanityvalue = 80,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 25,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_lavender_flower_spike or 0) == 2
                                and (names.tbat_food_ephemeral_flower or 0) == 1
                                and (names.tbat_food_hedgehog_cactus_meat or 0) == 1
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_pink_butterfly_steamed_bun"] = {
                ["name"] = "粉蝶嘟嘟馍饼",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 90,
                        healthvalue = 60,
                        sanityvalue = 60,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 30,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_raw_meat or 0) + (names.tbat_food_raw_meat_cooked or 0) >= 1
                                and (names.tbat_food_ephemeral_flower_butterfly_wings or 0) >= 1
                                and (names.tbat_food_lavender_flower_spike or 0) >= 1
                                and (tags.meat or 0) >= 1.5
                        end,
                -------------------------------------------
        },
        ["tbat_food_cooked_butterfly_dance_rice"] = {
                ["name"] = "花间蝶舞糯米饭",
                -------------------------------------------
                --- 食物prefab参数
                        hungervalue = 100,
                        healthvalue = 50,
                        sanityvalue = 50,
                        foodtype = FOODTYPE.MEAT,
                        stacksize = TUNING.STACK_SIZE_SMALLITEM,    --- 叠堆，可nil
                        perishtime = TUNING.PERISH_ONE_DAY*20,      --- 腐烂时间
                        burningtime = 10,       --- 着火时间 
                -------------------------------------------
                --- 烹饪
                        cooking_priority = 800,
                        cooking_stacksize = 1,
                        -- cooking_oneat_desc = "",         --- 烹饪书里的文本
                        cooktime = 40,                      --- 烹饪时间（秒）
                        potlevel = "high",  --- 锅里的贴图位置 low high  mid
                        cooking_test = function(cooker, names, tags)  --- 烹饪食谱Fn
                                return (names.tbat_food_ephemeral_flower_butterfly_wings or 0) == 1
                                and (names.tbat_food_lavender_flower_spike or 0) == 2
                                and (names.tbat_food_ephemeral_flower or 0) == 1
                        end,
                -------------------------------------------
        },

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return ALL_FOODS_DATA