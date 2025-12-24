local priority_low = 61
local priority_med = 91
local priority_hig = 121

------

local items_legion = {
    dish_tomahawksteak = {
        test = function(cooker, names, tags)
            return names.horn and names.mint_l and (names.garlic or names.garlic_cooked)
                and (tags.meat and tags.meat >= 1)
        end,
        card_def = { ingredients = { {"horn",1}, {"mint_l",1}, {"garlic",1}, {"monstermeat",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 0, sanity = 0, health = 0,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 1.75,
        potlevel = "low",
        overridebuild = "dish_tomahawksteak",
        overridesymbolname = "base",
        oneat_desc = STRINGS.UI.COOKBOOK.DISH_TOMAHAWKSTEAK,
        notinitprefab = true, --兼容勋章的机制。此配方，不以勋章的通用方式生成调料后预制物

        cook_need = "牛角 猫薄荷 (烤)大蒜 肉度≥1",
        cook_cant = nil,
        recipe_count = 4
    }
}

------
------

for k, v in pairs(items_legion) do
    v.name = k
    if v.weight == nil then
        v.weight = 1
    end
    if v.priority == nil then
        v.priority = priority_low
    end
    -- if v.overridebuild == nil then --替换料理build。这样所有料理都可以共享一个build了，默认与料理名同名
    --     v.overridebuild = "dishes_legion"
    -- end
    -- v.overridesymbolname = nil, --替换烹饪锅的料理贴图的symbol。默认与料理名同名
    -- if v.oneatenfn ~= nil and v.oneat_desc == nil then
    --     v.oneat_desc = STRINGS.UI.COOKBOOK[string.upper(k)] --食谱中的食用效果的介绍语句
    -- end
    if v.cookbook_tex == nil then --食谱大图所用的image
        v.cookbook_tex = k..".tex"
    end
    if v.cookbook_atlas == nil then --食谱大图所用的atlas
        v.cookbook_atlas = "images/cookbookimages/"..k..".xml"
    end
    -- v.cookbook_category = "mod" --官方在AddCookerRecipe时就设置了，所以，cookbook_category 不需要自己写
end

return items_legion
