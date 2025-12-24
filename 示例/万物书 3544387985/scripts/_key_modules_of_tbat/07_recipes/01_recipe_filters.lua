--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    制作栏分类

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 旧的制作栏
    -- AddRecipeFilter({ 
    --     name = string.upper("tbat_recipe_filter"),
    --     atlas = "images/widgets/tbat_recipe_filter.xml",
    --     image = "tbat_recipe_filter.tex"
    -- })
    -- STRINGS.UI.CRAFTING_FILTERS[string.upper("tbat_recipe_filter")] = TBAT:GetString2("recipe_name","main")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 建筑
    AddRecipeFilter({
        name = string.upper("tbat_recipe_filter_building"),
        atlas = "images/widgets/tbat_recipe_filter2.xml",
        image = "building.tex"
    })
    STRINGS.UI.CRAFTING_FILTERS[string.upper("tbat_recipe_filter_building")] = TBAT:GetString2("recipe_name","building")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装饰
    AddRecipeFilter({ 
        name = string.upper("tbat_recipe_filter_decoration"),
        atlas = "images/widgets/tbat_recipe_filter2.xml",
        image = "decoration.tex"
    })
    STRINGS.UI.CRAFTING_FILTERS[string.upper("tbat_recipe_filter_decoration")] = TBAT:GetString2("recipe_name","decoration")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 道具
    AddRecipeFilter({ 
        name = string.upper("tbat_recipe_filter_item"),
        atlas = "images/widgets/tbat_recipe_filter2.xml",
        image = "item.tex"
    })
    STRINGS.UI.CRAFTING_FILTERS[string.upper("tbat_recipe_filter_item")] = TBAT:GetString2("recipe_name","item")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
