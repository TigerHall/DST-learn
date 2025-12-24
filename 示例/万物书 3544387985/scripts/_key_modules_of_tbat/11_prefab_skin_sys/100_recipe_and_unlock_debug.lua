-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if not TBAT.DEBUGGING then
    return
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    GLOBAL.STRINGS.NAMES[string.upper("tbat_debug_test_building")] = "building"    -- -- 制造栏里展示的名字
    STRINGS.RECIPE_DESC[string.upper("tbat_debug_test_building")] = "建筑"  -- --  制造栏里展示的说明
    AddRecipe2(
        "tbat_debug_test_building",            --  --  inst.prefab  实体名字
        {}, 
        TECH.NONE, --- TECH.NONE
        {
            placer = "tbat_debug_test_building_placer",                       -------- 建筑放置器
            atlas = GetInventoryItemAtlas("horn.tex"),
            image = "horn.tex",
        },
        {"CHARACTER"}
    )
    RemoveRecipeFromFilter("tbat_debug_test_building","MODS")                       -- -- 在【模组物品】标签里移除这个。
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    GLOBAL.STRINGS.NAMES[string.upper("tbat_debug_test_item")] = "weapon"    -- -- 制造栏里展示的名字
    STRINGS.RECIPE_DESC[string.upper("tbat_debug_test_item")] = "武器"  -- --  制造栏里展示的说明
    AddRecipe2(
        "tbat_debug_test_item",            --  --  inst.prefab  实体名字
        {}, 
        TECH.NONE, --- TECH.NONE
        {
            atlas = GetInventoryItemAtlas("horn.tex"),
            image = "horn.tex",
        },
        {"CHARACTER"}
    )
    RemoveRecipeFromFilter("tbat_debug_test_item","MODS")                       -- -- 在【模组物品】标签里移除这个。
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
end)
