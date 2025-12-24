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
    local ALL_FOODS_DATA = require("_key_modules_of_tbat/15_cooking/01_01_phase2_cooked_foods_data")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    for prefab, data in pairs(ALL_FOODS_DATA) do
        local recipe_data = {
            test = data.cooking_test or function(cooker, names, tags)
            end,
            name = prefab, -- 料理名
            weight = data.cooking_weight or 10, -- 食谱权重
            priority = data.cooking_priority or 999, -- 食谱优先级
            foodtype = data.foodtype or GLOBAL.FOODTYPE.GOODIES, --料理的食物类型，比如这里定义的是肉类
            hunger = data.hungervalue or 0, --吃后回饥饿值
            sanity = data.sanityvalue or 0, --吃后回精神值
            health = data.healthvalue or 0, --吃后回血值
            stacksize = data.cooking_stacksize or 1,  --- 每次烹饪得到个数
            perishtime = data.perishtime or TUNING.PERISH_TWO_DAY, --腐烂时间
            cooktime = TBAT.DEBUGGING and 1/20 or 1/20*(data.cooktime or 0), --烹饪时间(单位20s :  数字1 为 20s ,)
            potlevel = data.potlevel or "low",  --- 锅里的贴图位置 low high  mid
            cookbook_tex = prefab..".tex", -- 在游戏内食谱书里的mod食物那一栏里显示的图标，tex在 atlas的xml里定义了，所以这里只写文件名即可
            cookbook_atlas = "images/inventoryimages/"..prefab..".xml",  
            overridebuild = prefab,          ----- build (zip名字)
            overridesymbolname = "pot",     ----- scml 的图层名字（图片所在的文件夹名）
            floater = {"med", nil, 0.55},
            oneat_desc = data.cooking_oneat_desc,    --- 副作用一栏显示的文本
            cookbook_category = "cookpot",
        }
        AddCookerRecipe("cookpot", recipe_data) -- 将食谱添加进普通锅
        AddCookerRecipe("portablecookpot", recipe_data) -- 将食谱添加进便携锅(大厨锅)
        AddCookerRecipe("archive_cookpot", recipe_data) --档案馆远古窑，有好多mod作者忽略了这口锅
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 调味料食谱
    local ALL_SPICE_DATA = {}
    for prefab, data in pairs(ALL_FOODS_DATA) do
        ALL_SPICE_DATA[prefab] = {
            test = data.cooking_test,
            priority = 999,
            weight = 10,
            foodtype = data.foodtype,
            hunger = data.hungervalue or 0, --吃后回饥饿值
            sanity = data.sanityvalue or 0, --吃后回精神值
            health = data.healthvalue or 0, --吃后回血值
            perishtime = data.perishtime or TUNING.PERISH_TWO_DAY, --腐烂时间
            cooktime = TBAT.DEBUGGING and 1/20 or 1/20*(data.cooktime or 0), --烹饪时间(单位20s :  数字1 为 20s ,)
            --- 给调料台调用
            overridebuild = prefab,          ----- build (zip名字)
            overridesymbolname = "pot",     ----- scml 的图层名字（图片所在的文件夹名）
        }
    end
    GenerateSpicedFoods(ALL_SPICE_DATA)
    local spicedfoods = require("spicedfoods")
    for k, recipe in pairs(spicedfoods) do
        AddCookerRecipe("portablespicer", recipe)
    end
    ------------------------------------------------------------------------------------------------------------------
    --- 处理落地上物品贴图不正常
        --------------------------------------
        --- 落水影子
            local function shadow_init(inst)
                if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
                    inst.AnimState:Hide("SHADOW")
                    inst.AnimState:HideSymbol("shadow")
                else                                
                    inst.AnimState:Show("SHADOW")
                    inst.AnimState:ShowSymbol("shadow")
                end
            end
        --------------------------------------
        for new_prefab, data in pairs(spicedfoods) do
            if data.basename and ALL_FOODS_DATA[data.basename] then
                local base_prefab = data.basename
                AddPrefabPostInit(new_prefab,function(inst)
                    inst.AnimState:SetBank(base_prefab)
                    inst.AnimState:SetBuild(base_prefab)
                    inst.AnimState:PlayAnimation("idle",true)
                    if not TheWorld.ismastersim then
                        return
                    end
                    --------------------------------------
                    --- 落水影子
                        inst:ListenForEvent("on_landed",shadow_init)
                        shadow_init(inst)
                    --------------------------------------
                end)
            end
        end
    ------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------