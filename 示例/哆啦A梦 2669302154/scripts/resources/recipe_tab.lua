--------------------------------
--[[ 建造栏]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Recipetabs = {
    --data.id, data.sort, data.atlas, data.icon, data.owner_tag, data.crafting_station
    {
        id = STRINGS.DORAEMON_TECH.NAME,
        sort = 999,
        atlas = "images/tab/doraemon_tab.xml",
        icon = "doraemon_tab.tex",
        owner_tag = nil,--玩家标签
        crafting_station=nil,--科技站
    },
}

return {
    Recipetabs = Recipetabs,
}