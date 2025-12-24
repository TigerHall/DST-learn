-- All Tags: fruit, monster, sweetener, veggie, meat, fish, egg, decoration, fat, dairy, inedible, seed, magic
----------------------------------------------------------------------------
---[[可入锅]]
----------------------------------------------------------------------------
local PRODUCTS = {
    -- 农作物
    {food = "honor_coconut_meat",      tags = {meat = 1, fruit = .5},               cancook = true, candry = false},
    {food = "honor_coconut_juice",     tags = {fruit = 1, sweetener = 1},           cancook = true, candry = false},
    {food = "honor_coconut_cooked",    tags = {meat = 1.5},                         cancook = true, candry = false},
    {food = "honor_tea",               tags = {sweetener = 1, veggie = 1},          cancook = true, candry = false},
    {food = "honor_tea_cooked",        tags = {sweetener = 1, veggie = 1},          cancook = true, candry = false},
    {food = "honor_jasmine",           tags = {fruit = 1, magic = 1},               cancook = true, candry = false},
    {food = "honor_jasmine_cooked",    tags = {magic = 2},                          cancook = true, candry = false},
    {food = "honor_dhp",               tags = {veggie = 1, magic = 1},              cancook = true, candry = false},
    {food = "honor_dhp_cooked",        tags = {magic = 2},                          cancook = true, candry = false},
    {food = "honor_rice",              tags = {veggie = 1.5},                       cancook = true, candry = false},
    {food = "honor_rice_cooked",       tags = {veggie = 2},                         cancook = true, candry = false},
    {food = "honor_wheat",             tags = {veggie = 1.5},                       cancook = true, candry = false},
    {food = "honor_wheat_cooked",      tags = {veggie = 2},                         cancook = true, candry = false},
    {food = "honor_sugarcane",         tags = {veggie = 1, fruit = 1},              cancook = true, candry = false},
    {food = "honor_sugarcane_cooked",  tags = {veggie = 1, fruit = .5},             cancook = true, candry = false},
    {food = "honor_goldenlanternfruit",tags = {fruit = 1, magic = 1},               cancook = true, candry = false},
    {food = "honor_goldenlanternfruit_cooked", tags = {magic = 2},                  cancook = true, candry = false},
    {food = "honor_aloe",              tags = {veggie = 1, meat = .5},              cancook = true, candry = false},
    {food = "honor_aloe_cooked",       tags = {meat = 1},                           cancook = true, candry = false},
    {foor = "honor_walnut",            tags = {veggie = 1},                         cancook = true, candry = false},
    {food = "honor_walnut_cooked",     tags = {veggie = 1.5},                       cancook = true, candry = false},
    {food = "honor_almond",            tags = {veggie = 1, fat = 1},                cancook = true, candry = false},
    {food = "honor_almond_cooked",     tags = {veggie = 1, fat = 1},                cancook = true, candry = false},
    {food = "honor_cashew",            tags = {veggie = 1, monster = .5},           cancook = true, candry = false},
    {food = "honor_cashew_cooked",     tags = {veggie = 2},                         cancook = true, candry = false},
    {food = "honor_macadamia",         tags = {veggie = 1, dairy = 1},              cancook = true, candry = false},
    {food = "honor_macadamia_cooked",  tags = {veggie = 1, dairy = 1},              cancook = true, candry = false},
    {food = "honor_hamimelon",         tags = {veggie = 1, fruit = 1},              cancook = true, candry = false},
    {food = "honor_hamimelon_cooked",  tags = {veggie = 1.5},                       cancook = true, candry = false},
    {food = "honor_mushroom",          tags = {veggie = 1, monster = .5},           cancook = true, candry = false},

    {food = "terror_blueberry",        tags = {fruit = 1, sweetener = .5},          cancook = true, candry = false},
    {food = "terror_blueberry_cooked", tags = {fruit = 1},                          cancook = true, candry = false},
    {food = "terror_ginger",           tags = {veggie = 1, monster = .5},           cancook = true, candry = false},
    {food = "terror_ginger_cooked",    tags = {veggie = 1},                         cancook = true, candry = false},
    {food = "terror_snakeskinfruit",   tags = {fruit = 1, monster = .5, meat = 1},  cancook = true, candry = false},
    {food = "terror_snakeskinfruit_cooked", tags = {fruit = 1, meat = 1.5},         cancook = true, candry = false},
    {food = "terror_litchi",           tags = {fruit = 1, magic = .5},              cancook = true, candry = false},
    {food = "terror_litchi_cooked",    tags = {fruit = .5, magic = 1},              cancook = true, candry = false},
    {food = "terror_lemon",            tags = {fruit = 1},                          cancook = true, candry = false},
    {food = "terror_lemon_cooked",     tags = {magic = 1.5},                        cancook = true, candry = false},
    {food = "terror_litchi",           tags = {fruit = 1, magic = .5},              cancook = true, candry = false},
    {food = "terror_litchi_cooked",    tags = {fruit = 1.5},                        cancook = true, candry = false},
    {food = "terror_coffee",           tags = {veggie = 1},                         cancook = true, candry = false},
    {food = "terror_coffee_cooked",    tags = {magic = 1.5},                        cancook = true, candry = false},
    {food = "terror_hawthorn",         tags = {fruit = 1},                          cancook = true, candry = false},
    {food = "terror_hawthorn_cooked",  tags = {fruit = 1.5},                        cancook = true, candry = false},
    {food = "terror_passionfruit",     tags = {fruit = 1, magic = .5},              cancook = true, candry = false},
    {food = "terror_passionfruit_cooked", tags = {fruit = 1.5},                     cancook = true, candry = false},

    -- 其他
    {food = "honor_greenjuice",        tags = {sweetener = .5},                     cancook = true, candry = false},

    -- 樱海岛
    {food = "hmr_cherry_tree_flower",  tags = {fruit = 1},                          cancook = true, candry = false},
    {food = "hmr_cherry_tree_fruit",   tags = {fruit = 1.5},                        cancook = true, candry = false},
    {food = "hmr_cherry_tree_seeds",   tags = {seed = 1.5},                         cancook = true, candry = false},
}

for _, product in ipairs(PRODUCTS) do
    AddIngredientValues({product.food}, product.tags, product.cancook, product.candry)
end

----------------------------------------------------------------------------
---[[料理配方]]
----------------------------------------------------------------------------
local preparedfoods = {
    hmr_cherry_soda = {
        test = function(cooker, names, tags)
            return names.ice and names.honor_greenjuice and names.hmr_cherry_tree_flower and names.terror_lemon
        end,
        priority = 10,
        weight = 1,
        foodtype = FOODTYPE.GOODIES,
        health = 0,
        hunger = 2,
        sanity = 50,
        perishtime = TUNING.PERISH_SLOW,
        cooktime = 0.5,
        potlevel = "low",
        floater = {"small", 0.05, 0.7},
    },
    hmr_cherry_litchi_congee = {
        test = function(cooker, names, tags)
            return names.hmr_cherry_tree_flower and names.hmr_cherry_tree_fruit and names.terror_litchi and names.honor_greenjuice
        end,
        priority = 10,
        weight = 1,
        foodtype = FOODTYPE.GOODIES,
        health = 60,
        hunger = 20,
        sanity = 30,
        perishtime = TUNING.PERISH_MED,
        cooktime = 0.5,
        potlevel = "high",
        floater = {"small", 0.05, 0.7},
    },
    hmr_cherry_daifuku = {
        test = function(cooker, names, tags)
            return names.hmr_cherry_tree_flower and names.hmr_cherry_tree_fruit and names.honor_rice and tags.sweetener
        end,
        priority = 10,
        weight = 1,
        foodtype = FOODTYPE.GOODIES,
        health = 10,
        hunger = 40,
        sanity = 80,
        perishtime = TUNING.PERISH_SLOW,
        cooktime = 0.5,
        potlevel = "med",
        floater = {"small", 0.05, 0.7},
    },
    hmr_cherry_sorbet = {
        test = function(cooker, names, tags)
            return names.hmr_cherry_tree_flower and names.hmr_cherry_tree_fruit and names.ice and names.ice >= 2
        end,
        priority = 10,
        weight = 1,
        foodtype = FOODTYPE.GOODIES,
        health = 5,
        hunger = 5,
        sanity = 40,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP * 2,
        temperatureduration = TUNING.BUFF_FOOD_TEMP_DURATION * 3,
        perishtime = TUNING.PERISH_SLOW,
        cooktime = 0.5,
        potlevel = "low",
        floater = {"small", 0.05, 0.7},
        oneatenfn = function(inst, eater)
            -- if eater.components.debuffable ~= nil then
            --     eater.components.debuffable:AddDebuff("hmr_cherry_sorbet_buff", "hmr_cherry_sorbet_buff")
            -- end
        end,
    }
}

for k,v in pairs(preparedfoods) do
    v.name = k
    v.basename = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0
    v.overridebuild = "hmr_preparedfoods"
    v.overridebank = "hmr_preparedfoods"
    v.overrideanim = k
    v.cookbook_category = "cookpot"

    AddCookerRecipe("cookpot", v, true)	--添加到烹饪锅
    AddCookerRecipe("portablecookpot", v, true)		--便携式烹饪锅
    -- AddCookerRecipe("portablespicer", v, true)
end

return preparedfoods