--------------------------------
--[[ 科技设置]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------

local require = GLOBAL.require
--------------------------------
--[[ 修改默认的科技树生成方式 ]]
--------------------------------

local TechTree = require("techtree")
--加入科技名称
table.insert(TechTree.AVAILABLE_TECH, "DORAEMON_TECH")
table.insert(TechTree.BONUS_TECH, "DORAEMON_TECH")
TechTree.Create = function(t)
    t = t or {}
    for i, v in ipairs(TechTree.AVAILABLE_TECH) do
        t[v] = t[v] or 0
    end
    return t
end

--------------------------------------------------------------------------
--[[ 制作等级中加入自己的部分 ]]
--------------------------------------------------------------------------
GLOBAL.TECH.NONE.DORAEMON_TECH = 0
GLOBAL.TECH.DORAEMON_TECH_1 = { DORAEMON_TECH = 1 }
GLOBAL.TECH.DORAEMON_TECH_2 = { DORAEMON_TECH = 2 }
GLOBAL.TECH.DORAEMON_TECH_3 = { DORAEMON_TECH = 3 }

--------------------------------------------------------------------------
--[[ 解锁等级中加入自己的部分 ]]
--------------------------------------------------------------------------

for k,v in pairs(TUNING.PROTOTYPER_TREES) do
    v.DORAEMON_TECH = 0
end

--FU_TECH_ONE可以改成任意的名字，这里和TECH.FU_TECH_ONE名字相同只是懒得改了
TUNING.PROTOTYPER_TREES.DORAEMON_TECH_1 = TechTree.Create({
    DORAEMON_TECH = 1,
})
TUNING.PROTOTYPER_TREES.DORAEMON_TECH_2 = TechTree.Create({
    DORAEMON_TECH = 2,
})
TUNING.PROTOTYPER_TREES.DORAEMON_TECH_3 = TechTree.Create({
    DORAEMON_TECH = 3,
})

--------------------------------------------------------------------------
--[[ 修改全部制作配方，对缺失的值进行补充 ]]
--------------------------------------------------------------------------

AddPrefabPostInit("player_classified", function(inst)
    inst.techtrees = GLOBAL.deepcopy(GLOBAL.TECH.NONE)
end)

for i, v in pairs(GLOBAL.AllRecipes) do
    if v.level.DORAEMON_TECH == nil then
        v.level.DORAEMON_TECH = 0
    end
end