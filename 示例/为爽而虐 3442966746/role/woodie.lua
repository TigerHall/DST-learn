-- 俗气雕像需要活木
-- AddRecipePostInit("wereitem_beaver", function(inst) table.insert(inst.ingredients, Ingredient("livinglog", 1)) end)
-- AddRecipePostInit("wereitem_goose", function(inst) table.insert(inst.ingredients, Ingredient("livinglog", 1)) end)
AddRecipePostInit("wereitem_moose", function(inst) 
    table.insert(inst.ingredients, Ingredient("livinglog", 3)) 
end)

-- 食用怪物肉不能变身
AddComponentPostInit("wereeater", function(self)
    self.duration = 0.01 -- 消除一层怪物肉debuff的时间
end)


