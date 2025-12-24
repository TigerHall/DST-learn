
local BUILDING_PREFAB = string.upper("tbat_the_tree_of_all_things")
----------------------------------------------------------------------------------------
--- 弹出式 专属科技建筑。  添加活动tag给指定的 prefab，不能大写。 制作栏 左上角 的图标 和 鼠标过去的文字
    -- --- 绝对不能使用  AddPrototyperDef 函数
    -- PROTOTYPER_DEFS["tbat_the_tree_of_all_things"] = {      ----- 必须是 prefab 的名字
    --     icon_atlas = "images/map_icons/tbat_the_tree_of_all_things_128.xml", 
    --     icon_image = "tbat_the_tree_of_all_things_128.tex",	
    --     is_crafting_station = true,
    --     -- action_str = "TRADE",  --- 相关参数 参考 recipes.lua
    --     filter_text = "千年战术委托终端"
    -- }
----------------------------------------------------------------------------------------
--- 弹出式分类注册
    -- RECIPETABS[BUILDING_PREFAB] = { 
    --     str = BUILDING_PREFAB,
    --     sort = 999, 
    --     icon_atlas = "images/map_icons/tbat_the_tree_of_all_things.xml", 
    --     icon_image = "tbat_the_tree_of_all_things.tex",	
    --     crafting_station = true,
    --     shop = true
    -- }
----------------------------------------------------------------------------------------
-- --- 科技树交互参数 配置
    local TechTree = require("techtree")
    table.insert(TechTree.AVAILABLE_TECH,BUILDING_PREFAB) ---- 添加到科技树
    table.insert(TechTree.BONUS_TECH,BUILDING_PREFAB) ---- 有奖励的科技树
    -------------------- 科技参数
    TECH.NONE[BUILDING_PREFAB] = 0
    TECH[string.upper("tbat_the_tree_of_all_things_one")] = {
        [BUILDING_PREFAB] = 1,
    } -- 【重要笔记：有独立的"弹出式"分类的时候，不需要这个】
    for k,v in pairs(TUNING.PROTOTYPER_TREES) do    ---------- 给其他标签注入0参数
        v[BUILDING_PREFAB] = 0
    end
    TUNING.PROTOTYPER_TREES[BUILDING_PREFAB] = TechTree.Create({   ---- 靠近inst 的时候触发科技树标记位切换
        [BUILDING_PREFAB] = 1,
    })
    ------- 给其他的添加科技类别 --- TECH.NONE  ---- 这个可能就是 builder_replica 造成崩溃的原因
    for i, v in pairs(AllRecipes) do
        if v.level[BUILDING_PREFAB] == nil then
            v.level[BUILDING_PREFAB] = 0
        end
    end
----------------------------------------------------------------------------------------
local function GetTech()
    -- return TECH.NONE
    return TECH[string.upper("tbat_the_tree_of_all_things_one")]
end
----------------------------------------------------------------------------------------
function TBAT.RECIPE:GetTech()
    if TBAT.DEBUGGING then
        return TECH.NONE
    end
    return GetTech()
end
function TBAT.RECIPE:GetLostTech()
    -- if TBAT.DEBUGGING then
    --     return TECH.NONE
    -- end
    return TECH.LOST
end
----------------------------------------------------------------------------------------