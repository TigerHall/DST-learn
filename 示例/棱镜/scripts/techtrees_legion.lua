-- 代码作者：ti_Tout

local _G = GLOBAL

--------------------------------------------------------------------------
--[[ 修改默认的科技树生成方式 ]]
--------------------------------------------------------------------------

local TechTree = require("techtree")

table.insert(TechTree.AVAILABLE_TECH, "ELECOURMALINE")	--其实就是加个自己的科技树名称
table.insert(TechTree.AVAILABLE_TECH, "SIVING")

local Create_old = TechTree.Create
TechTree.Create = function(t, ...)
	local newt = Create_old(t, ...)
	newt["ELECOURMALINE"] = newt["ELECOURMALINE"] or 0
	newt["SIVING"] = newt["SIVING"] or 0
	return newt
end

--------------------------------------------------------------------------
--[[ 新制作栏 ]]
--------------------------------------------------------------------------

AddPrototyperDef("elecourmaline", { --第一个参数是指玩家靠近时会解锁科技的prefab名
	icon_atlas = "images/station_recast.xml", icon_image = "station_recast.tex",
	is_crafting_station = true,
	action_str = "RECAST", --台词已在语言文件中
	filter_text = STRINGS.UI.CRAFTING_STATION_FILTERS.RECAST
})
AddPrototyperDef("siving_thetree", {
	icon_atlas = "images/station_siving.xml", icon_image = "station_siving.tex",
	is_crafting_station = false,
	action_str = "SIVING"
})

AddRecipeFilter({ --重铸青光
	name = "RECAST", atlas = "images/station_recast.xml", image = "station_recast.tex", custom_pos = true
})
AddRecipeFilter({ --生命子圭
	name = "SIVING", atlas = "images/station_siving.xml", image = "station_siving.tex"
})
AddRecipeFilter({ --棱镜里
	name = "LEGION", atlas = "images/filter_legion.xml", image = "filter_legion.tex"
})

--------------------------------------------------------------------------
--[[ 制作等级中加入自己的部分 ]]
--------------------------------------------------------------------------

_G.TECH.NONE.ELECOURMALINE = 0
_G.TECH.ELECOURMALINE_ONE = { ELECOURMALINE = 1 }
-- _G.TECH.ELECOURMALINE_TWO = { ELECOURMALINE = 2 } --解锁等级中间隔一个等级，能使得没法解锁时，不会显示出来
_G.TECH.ELECOURMALINE_THREE = { ELECOURMALINE = 3 }

_G.TECH.NONE.SIVING = 0
_G.TECH.SIVING_ONE = { SIVING = 1 }
_G.TECH.SIVING_THREE = { SIVING = 3 }

--------------------------------------------------------------------------
--[[ 解锁等级中加入自己的部分 ]]
--------------------------------------------------------------------------

for _, v in pairs(TUNING.PROTOTYPER_TREES) do
    v.ELECOURMALINE = 0
	v.SIVING = 0
end

--ELECOURMALINE_ONE可以改成任意的名字，这里和TECH.ELECOURMALINE_ONE名字相同只是懒得改了
TUNING.PROTOTYPER_TREES.ELECOURMALINE_ONE = TechTree.Create({ ELECOURMALINE = 1 })
TUNING.PROTOTYPER_TREES.ELECOURMALINE_THREE = TechTree.Create({ ELECOURMALINE = 3 })

TUNING.PROTOTYPER_TREES.SIVING_ONE = TechTree.Create({ SIVING = 1 })
TUNING.PROTOTYPER_TREES.SIVING_THREE = TechTree.Create({ SIVING = 3 })

--------------------------------------------------------------------------
--[[ 修改全部制作配方，对缺失的值进行补充 ]]
--------------------------------------------------------------------------

for _, v in pairs(AllRecipes) do
	if v.level.ELECOURMALINE == nil then
		v.level.ELECOURMALINE = 0
	end
	if v.level.SIVING == nil then
		v.level.SIVING = 0
	end
end

--------------------------------------------------------------------------
--[[ 让某个制作栏分类能显示全部对象，不管能不能解锁或制作 ]]
--------------------------------------------------------------------------

if not TheNet:IsDedicated() then
	local craftingmenu_widget = require "widgets/redux/craftingmenu_widget"

	local ApplyFilters_old = craftingmenu_widget.ApplyFilters
	craftingmenu_widget.ApplyFilters = function(self, ...)
		if
			(self.current_filter_name == "LEGION" or self.current_filter_name == "SIVING") and
			CRAFTING_FILTERS[self.current_filter_name] ~= nil
		then
			self.filtered_recipes = {}
			local filter_recipes = FunctionOrValue(CRAFTING_FILTERS[self.current_filter_name].default_sort_values) or nil
			if filter_recipes == nil then
				return ApplyFilters_old(self, ...)
			end
			for i, recipe_name in metaipairs(self.sort_class) do
				local data = self.crafting_hud.valid_recipes[recipe_name]
				if data and filter_recipes[recipe_name] ~= nil then
					table.insert(self.filtered_recipes, data)
				end
			end
			if self.crafting_hud:IsCraftingOpen() then
				self:UpdateRecipeGrid(self.focus and not TheFrontEnd.tracking_mouse)
			else
				self.recipe_grid.dirty = true
			end
		else
			return ApplyFilters_old(self, ...)
		end
	end
end
