local Ingredient = GLOBAL.Ingredient
local RecipeTabs = GLOBAL.RECIPETABS
local Tech = GLOBAL.TECH

GLOBAL.STRINGS.RECIPE_DESC.SLOW_FARMPLOT = "Grows seeds."
GLOBAL.STRINGS.RECIPE_DESC.FAST_FARMPLOT = "Grows seeds a bit faster."

AddRecipe2("slow_farmplot", { Ingredient("cutgrass", 8), Ingredient("poop", 4), Ingredient("log", 4) }, Tech.SCIENCE_ONE, "slow_farmplot_placer", {"COOKING", "GARDENING"})
AddRecipe2("fast_farmplot", { Ingredient("cutgrass", 10), Ingredient("poop", 6), Ingredient("rocks", 4) }, Tech.SCIENCE_TWO, "fast_farmplot_placer", {"COOKING", "GARDENING"})

-- 老农场收获时直接给予玩家作物了，先给作物的种子对应一个表格
local VEGGIE_SEED = {
    carrot = "carrot_seeds",
    corn = "corn_seeds",
    eggplant = "eggplant_seeds",
    durian = "durian_seeds",
    pomegranate = "pomegranate_seeds",
    pumpkin = "pumpkin_seeds",
    dragonfruit = "dragonfruit_seeds",
    tomato = "tomato_seeds",
    onion = "onion_seeds",
    garlic = "garlic_seeds",
    pepper = "pepper_seeds",
    asparagus = "asparagus_seeds",
    potato = "potato_seeds",
    watermelon = "watermelon_seeds",
}
-- 给收获额外添加一个种子，重写函数覆盖吧
AddComponentPostInit("crop", function(self)
    if TheWorld.ismastersim then
        local oldHarvest = self.Harvest
        self.Harvest = function(self, harvester, ...)
            local veggie_prefab = self.product_prefab -- 重要：原函数执行后product为空，保存一下作物的名字
            local success, product = oldHarvest(self, harvester, ...)
            if success and product then
                -- 执行额外种子逻辑
                local seed_prefab = VEGGIE_SEED[veggie_prefab]
                if seed_prefab ~= nil then
                    local seed = SpawnPrefab(seed_prefab)
                    if seed ~= nil then
                        if harvester ~= nil and harvester.components.inventory ~= nil then
                            harvester.components.inventory:GiveItem(seed, nil, self.inst:GetPosition())
                        else
                            seed.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                        end
                    end
                end
            end
            return success, product
        end        
    end
end)