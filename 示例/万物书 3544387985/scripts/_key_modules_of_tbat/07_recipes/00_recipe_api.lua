--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.RECIPE = Class()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 封装配方添加API
    --[[
    
            AddRecipe2(
                "hoshino_building_millennium_tactics_delegate_terminal",            --  --  inst.prefab  实体名字
                { Ingredient("gears", 2),Ingredient("boards", 4),Ingredient("papyrus", 4) }, 
                TECH.NONE, --- 魔法三本
                {
                    -- nounlock=true,
                    no_deconstruction=false,
                    builder_tag = "hoshino",    
                    atlas = "images/map_icons/hoshino_building_millennium_tactics_delegate_terminal.xml",
                    image = "hoshino_building_millennium_tactics_delegate_terminal.tex",
                    placer = "hoshino_building_millennium_tactics_delegate_terminal_placer",                       -------- 建筑放置器

                },
                {string.upper("millennium_tactics_delegate_terminal")}
            )
            RemoveRecipeFromFilter("hoshino_building_millennium_tactics_delegate_terminal","MODS")
    
    ]]--
    local recipes_index_list = {
        ["building"] = "tbat_recipe_filter_building",
        ["decoration"] = "tbat_recipe_filter_decoration",
        ["item"] = "tbat_recipe_filter_item",
    }
    function TBAT.RECIPE:AddRecipe(prefab,_Ingredients,tech,data,recipe_filters_or_index)
            local recipe_filters = {}
            ---------------------------------------------------------------------------------------
            -- 添加分类 : building decoration item
                if type(recipe_filters_or_index) == "string" then
                    local ret_index = recipes_index_list[recipe_filters_or_index] or "tbat_recipe_filter_building"
                    table.insert(recipe_filters,string.upper(ret_index))
                elseif type(recipe_filters_or_index) == "table" then
                    for k, v in pairs(recipe_filters_or_index) do
                        table.insert(recipe_filters,string.upper(v))
                    end
                end
            ---------------------------------------------------------------------------------------
            -- table.insert(recipe_filters,string.upper("tbat_recipe_filter"))
            if TBAT.RECIPE:GetLostTech() == tech then
                data.no_deconstruction = nil
            end
            AddRecipe2(prefab,_Ingredients or {},tech or TECH.NONE ,data,recipe_filters)
            RemoveRecipeFromFilter(prefab,"MODS")
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 配方
    function TBAT.RECIPE:CreateList(cmd)
        cmd = cmd or {
            {"log",2},
            {"boards",2},
        }
        local ret = {}
        for i,data in ipairs(cmd) do
            table.insert(ret,Ingredient(data[1] or "log", data[2] or 1))
        end
        return unpack(ret)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- components/map 用来同时 兼容放置 海里、陆地 用的
    --- 这部分代码 来自 模组 【多肉植物】 的 【多肉农场】。
    TBAT.RECIPE.BUILDMODE_LAND_WATER = "BUILDMODE_LAND_WATER"
    AddSimPostInit(function ()
        local _CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
        function Map:CanDeployRecipeAtPoint(pt, recipe, rot,...)
            local is_valid_ground = false
            if recipe.build_mode == TBAT.RECIPE.BUILDMODE_LAND_WATER then
                is_valid_ground = self:IsOceanAtPoint(pt.x, pt.y, pt.z, true) and (recipe.testfn == nil or recipe.testfn(pt, rot)) and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
                return is_valid_ground or (recipe.testfn == nil or recipe.testfn(pt, rot)) and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
            end
            return _CanDeployRecipeAtPoint(self, pt, recipe, rot,...)
        end
    end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------