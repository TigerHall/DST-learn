local winona = require("prefabs/winona")

-- 校准观察机不允许学习特定蓝图解锁（TECH.LOST）的物品
AddComponentPostInit("recipescanner", function(self)
    local _Scan = self.Scan
    self.Scan = function(self, target, doer)

        -- 获取配方
        local recipe
        if target.SCANNABLE_RECIPENAME then
            recipe = GetValidRecipe(target.SCANNABLE_RECIPENAME)
        else
            recipe = AllRecipes[target.prefab]
            if recipe and recipe.source_recipename then
                recipe = GetValidRecipe(recipe.source_recipename)
            end
        end

        -- 女工专属的配方需要排除
        local winona_exceptions = {
            winona_storage_robot = true,
            winona_telebrella = true,
            winona_teleport_pad_item = true
        }

        if recipe and recipe.level == TECH.LOST and not winona_exceptions[recipe.name] then
            return false, "CANTLEARN"  -- 禁止学习
        end

        return _Scan(self, target, doer)
    end
end)

--位面打击伤害与发电机装载纯净辉煌数量有关







