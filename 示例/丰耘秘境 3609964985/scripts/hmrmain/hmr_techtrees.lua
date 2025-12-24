local TechTree = require("techtree")

--------------------------------------------------------------------------
-- 修改默认的科技树生成方式
--------------------------------------------------------------------------

table.insert(TechTree.AVAILABLE_TECH, "HONOR_TECH")
table.insert(TechTree.AVAILABLE_TECH, "TERROR_TECH")
table.insert(TechTree.AVAILABLE_TECH, "HMR_TECH")

local Create_old = TechTree.Create
TechTree.Create = function(t, ...)
	local newt = Create_old(t, ...)
	newt["HONOR_TECH"] = newt["HONOR_TECH"] or 0
	newt["TERROR_TECH"] = newt["TERROR_TECH"] or 0
	newt["HMR_TECH"] = newt["HMR_TECH"] or 0
	return newt
end

--------------------------------------------------------------------------
-- 制作等级
--------------------------------------------------------------------------

TECH.NONE.HONOR_TECH = 0
TECH.NONE.TERROR_TECH = 0
TECH.NONE.HMR_TECH = 0 -- 可用 TECH.LOST 替换

TECH.HONOR_TECH = { HONOR_TECH = 1 }
TECH.TERROR_TECH = { TERROR_TECH = 1 }
TECH.HMR_TECH = { HMR_TECH = 1 }

--------------------------------------------------------------------------
-- 解锁等级
--------------------------------------------------------------------------

-- for _, v in pairs(TUNING.PROTOTYPER_TREES) do
--     v.HONOR_TECH = 0
-- 	v.TERROR_TECH = 0
-- 	v.HMR_TECH = 0
-- end

TUNING.PROTOTYPER_TREES.HONOR_TECH = TechTree.Create({ HONOR_TECH = 1 })
TUNING.PROTOTYPER_TREES.TERROR_TECH = TechTree.Create({ TERROR_TECH = 1 })
TUNING.PROTOTYPER_TREES.HMR_TECH = TechTree.Create({ HMR_TECH = 1 })

--------------------------------------------------------------------------
-- 修改全部制作配方，对缺失的值进行补充
--------------------------------------------------------------------------
for _, v in pairs(AllRecipes) do
	if v.level.HONOR_TECH == nil then
		v.level.HONOR_TECH = 0
	end
    if v.level.TERROR_TECH == nil then
		v.level.TERROR_TECH = 0
	end
	if v.level.HMR_TECH == nil then
		v.level.HMR_TECH = 0
	end
end

--------------------------------------------------------------------------
-- 显示当前未解锁的配方
--------------------------------------------------------------------------

-- if not TheNet:IsDedicated() then
-- 	local craftingmenu_widget = require "widgets/redux/craftingmenu_widget"

-- 	local ApplyFilters_old = craftingmenu_widget.ApplyFilters
-- 	craftingmenu_widget.ApplyFilters = function(self, ...)
-- 		if
-- 			(self.current_filter_name == "SAKURA_BOOK") and
-- 			CRAFTING_FILTERS[self.current_filter_name] ~= nil
-- 		then
-- 			self.filtered_recipes = {}
-- 			local filter_recipes = FunctionOrValue(CRAFTING_FILTERS[self.current_filter_name].default_sort_values) or nil
-- 			if filter_recipes == nil then
-- 				return ApplyFilters_old(self, ...)
-- 			end
-- 			for i, recipe_name in metaipairs(self.sort_class) do
-- 				local data = self.crafting_hud.valid_recipes[recipe_name]
-- 				if data and filter_recipes[recipe_name] ~= nil then
-- 					table.insert(self.filtered_recipes, data)
-- 				end
-- 			end
-- 			if self.crafting_hud:IsCraftingOpen() then
-- 				self:UpdateRecipeGrid(self.focus and not TheFrontEnd.tracking_mouse)
-- 			else
-- 				self.recipe_grid.dirty = true
-- 			end
-- 		else
-- 			return ApplyFilters_old(self, ...)
-- 		end
-- 	end
-- end