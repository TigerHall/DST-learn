author = "童瑶，悉茗茗"
-- from stringutil.lua


----------------------------------------------------------------------------
--- 版本号管理：最后一位为内部开发版本号，或者修复小bug的时候进行增量。
---            倒数第二位为对外发布的内容量版本号，有新内容的时候进行增量。
---            第二位为大版本号，进行主题更新、大DLC发布的时候进行增量。
---            第一位暂时预留。 
----------------------------------------------------------------------------
local the_version = "0.02.00.0002"
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- from stringutil.lua
    local function tostring(arg)
        if arg == true then
            return "true"
        elseif arg == false then
            return "false"
        elseif arg == nil then
            return "nil"
        end
        return arg .. ""
    end
    local function ipairs(tbl)
        return function(tbl, index)
            index = index + 1
            local next = tbl[index]
            if next then
                return index, next
            end
        end, tbl, 0
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 语言相关的基础API  ---- 参数表： loc.lua 里面的localizations 表，code 为 这里用的index
    local function IsChinese()
        local language_flag = tostring(locale)
        if language_flag == "nil" then
            --- 云服务器不存在 locale ,默认中文
            return true
        else
            return language_flag == "zh" or language_flag == "zht" or language_flag == "zhr" or false
        end
    end
    local function ChooseTranslationTable_Test(_table)
        if IsChinese() then
            return _table["zh"]
        end
        if ChooseTranslationTable then
            return ChooseTranslationTable(_table)
        else
            return _table["zh"]
        end
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 描述
    local function GetName()
        local temp_table = {
            "The Book of All Things : Fantasy World", ----- 默认情况下(英文)
            ["zh"] = "万物书 - 幻想世界" ----- 中文
        }
        return ChooseTranslationTable_Test(temp_table)
    end

    local function GetDesc()
        local temp_table = {
            [[

        The Book of All Things : Fantasy World

        ]],
            ["zh"] = [[

    万物书-第一章【幻想世界】

    睁开眼，再次来到永恒大陆，熟悉的感觉扑面而来，但似乎与以前又有所不同。
    一座幻想岛屿生于海面，神秘的万物之树与翠羽鸟似乎在等待着什么。
    幻想与现实交织，一个个只存在于幻想中的生物出现在永恒大陆，
    各强大敌人所掉落的笔记似乎也讲述了一个不一般的故事。
    各位冒险家们通过在永恒领域内探索一起来新的世界或者收集前辈笔记来体验到各异的感受吧。
    是沉迷万物或是接近现实，一场充满幻想与现实的冒险即将开始。

    感谢各位游玩万物书，任何问题bug或者好的想法，可以加群联系我(群主）
    万物书交流群①：1049427294
    模组介绍页：https://www.alan.plus:9091/mod?type=WWS

    mod正在起步阶段，后续会有更多内容，请冒险家们尽情期待~
    第二期更新计划(画饼)
    1.新增4位幻想新生物
    2.新增3个幻想类作物
    3.新增药水炼制系统
    4.新增料理
    5.若干个装饰物

        ]]
        }
        local ret = the_version .. "  \n\n" .. ChooseTranslationTable_Test(temp_table)
        return ret
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--- debugging
    local debugging_flag = false
    if folder_name and folder_name == "The Book of All Things" or folder_name == "workshop-3573215226" then
        debugging_flag = true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------

name = debugging_flag and "万物书内测版" or GetName()
description = debugging_flag and "内部测试版\n内部测试版\n" or GetDesc()

version = the_version ------ MOD版本，上传的时候必须和已经在工坊的版本不一样

api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
forumthread = ""
dont_starve_compatible = true
dst_compatible = true
all_clients_require_mod = true

priority = -100 -- MOD加载优先级 影响某些功能的兼容性，比如官方Com 的 Hook
if not debugging_flag then
    server_filter_tags = {"万物书"}
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
--- OPTIONS
    local function Create_Number_Setting(start_num, stop_num, delta_num)
        local temp_options = {}
        local temp_index = 1
        delta_num = delta_num or 1
        local i = start_num

        -- 使用 while 循环代替 for 循环
        while i <= stop_num do
            temp_options[temp_index] = {
                description = tostring(i),
                data = i
            }
            temp_index = temp_index + 1
            i = i + delta_num
        end

        return temp_options
    end
    local function Create_Percent_Setting_With_1000_Mult(start_num, stop_num, delta_num) --- 百分比设置（1000倍扩大）
        local temp_options = Create_Number_Setting(start_num, stop_num, delta_num)
        for i, option in ipairs(temp_options) do
            option.description = (option.data / 10) .. "%"
        end
        return temp_options
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--- title 分隔符长度自适应函数
    local function GetTitle(name)
        -- 定义原始字符串的长度和填充字符
        local origin_length = 65 -- 原始字符串的总长度
        local padding_char = ' ' -- 用于填充的字符

        -- 获取 name 的长度
        local length = 0
        for _ in name:gmatch(".") do
            length = length + 1
        end

        -- 计算右边需要的空格数量
        local right_padding = origin_length - length

        -- 创建右侧的填充
        local right_padding_str = padding_char:rep(right_padding)

        -- 返回格式化后的字符串
        return name .. right_padding_str
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------
--- 快捷键
    local keys_option = {
        {description = "KEY_A", data = "KEY_A"},
        {description = "KEY_B", data = "KEY_B"},
        {description = "KEY_C", data = "KEY_C"},
        {description = "KEY_D", data = "KEY_D"},
        {description = "KEY_E", data = "KEY_E"},
        {description = "KEY_F", data = "KEY_F"},
        {description = "KEY_G", data = "KEY_G"},
        {description = "KEY_H", data = "KEY_H"},
        {description = "KEY_I", data = "KEY_I"},
        {description = "KEY_J", data = "KEY_J"},
        {description = "KEY_K", data = "KEY_K"},
        {description = "KEY_L", data = "KEY_L"},
        {description = "KEY_M", data = "KEY_M"},
        {description = "KEY_N", data = "KEY_N"},
        {description = "KEY_O", data = "KEY_O"},
        {description = "KEY_P", data = "KEY_P"},
        {description = "KEY_Q", data = "KEY_Q"},
        {description = "KEY_R", data = "KEY_R"},
        {description = "KEY_S", data = "KEY_S"},
        {description = "KEY_T", data = "KEY_T"},
        {description = "KEY_U", data = "KEY_U"},
        {description = "KEY_V", data = "KEY_V"},
        {description = "KEY_W", data = "KEY_W"},
        {description = "KEY_X", data = "KEY_X"},
        {description = "KEY_Y", data = "KEY_Y"},
        {description = "KEY_Z", data = "KEY_Z"},
        {description = "KEY_F1", data = "KEY_F1"},
        {description = "KEY_F2", data = "KEY_F2"},
        {description = "KEY_F3", data = "KEY_F3"},
        {description = "KEY_F4", data = "KEY_F4"},
        {description = "KEY_F5", data = "KEY_F5"},
        {description = "KEY_F6", data = "KEY_F6"},
        {description = "KEY_F7", data = "KEY_F7"},
        {description = "KEY_F8", data = "KEY_F8"},
        {description = "KEY_F9", data = "KEY_F9"},
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------
configuration_options =
{
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {
        name = "LANGUAGE",
        label = "Language/语言",
        hover = "Set Language/设置语言",
        options =
        {
          {description = "Auto/自动", data = "auto"},
          {description = "English", data = "en"},
          {description = "中文", data = "ch"},
          {description = "other", data = "other"},
        },
        default = "auto",
    },
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {name = "AAAA",label = IsChinese() and GetTitle("容器") or GetTitle("Contaienrs"),hover = "",options = {{description = "",data = 0}},default = 0},
    {
        name = "SPECIAL_CONTAINER_MAP_SEARCH",
        label = IsChinese() and GetTitle("范围自动收集") or GetTitle("Special Containers Auto Search"),
        hover = "",
        options = {
          {description = "OFF", data = false},
          {description = "ON", data = true},
        },
        default = true
    },
    {
        name = "SPECIAL_CONTAINER_MAP_SEARCH_CYCLE",
        label = IsChinese() and GetTitle("自动收集频率") or GetTitle("Special Containers Auto Search Cycle"),
        hover = IsChinese() and "自动搜索的间隔，最快5秒" or " ",
        options = Create_Number_Setting(5,600,5),
        default = 30
    },
    {
        name = "PEAR_CAT_SEARCH_RADIUS",
        label = IsChinese() and GetTitle("梨花猫猫搜索距离") or GetTitle("Pear Cat Search Radius"),
        hover = IsChinese() and "梨花猫猫搜索距离" or "Search Mode",
        options = {
            {description = IsChinese() and "半径20" or "R20", data = 20},
            {description = IsChinese() and "半径30" or "R30", data = 30},
            {description = IsChinese() and "半径40" or "R40", data = 40},
            {description = IsChinese() and "半径60" or "R60", data = 60},
            {description = IsChinese() and "半径100" or "R100", data = 100},
            {description = IsChinese() and "半径150" or "R150", data = 150},
            {description = IsChinese() and "半径200" or "R200", data = 200},
            {description = IsChinese() and "全图" or "Full Map", data = 999},
        },
        default = 999,
    },
    {
        name = "CHERRY_BLOSSOM_RABBIT_SEARCH_RADIUS",
        label = IsChinese() and GetTitle("樱花兔兔搜索距离") or GetTitle("Cherry Blossom Rabbit Search Radius"),
        hover = IsChinese() and "樱花兔兔搜索距离" or "Search Mode",
        options = {
            {description = IsChinese() and "半径20" or "R20", data = 20},
            {description = IsChinese() and "半径30" or "R30", data = 30},
            {description = IsChinese() and "半径40" or "R40", data = 40},
            {description = IsChinese() and "半径60" or "R60", data = 60},
            {description = IsChinese() and "半径100" or "R100", data = 100},
            {description = IsChinese() and "半径150" or "R150", data = 150},
            {description = IsChinese() and "半径200" or "R200", data = 200},
            {description = IsChinese() and "全图" or "Full Map", data = 999},
        },
        default = 999,
    },
    {
        name = "EFBCC_ALLOW_DECONSTRUCT",
        label = IsChinese() and GetTitle("翠羽鸟收集箱允许拆解") or GetTitle("Emerald Feathered Bird Chest allow deconstruct"),
        hover = IsChinese() and GetTitle("翠羽鸟收集箱允许拆解") or GetTitle("Emerald Feathered Bird Chest allow deconstruct"),
        options = {
          {description = "OFF", data = false},
          {description = "ON", data = true},
        },
        default = true
    },
    {
        name = "LAVENDER_KITTY_WORKING_AREA",
        label = IsChinese() and GetTitle("薰衣草小猫工作区域") or GetTitle("Lavender Kitty Working Area"),
        hover = IsChinese() and GetTitle("薰衣草小猫工作区域") or GetTitle("Lavender Kitty Working Area"),
        options = {
            {description = "3x3", data = "3x3"},
            {description = "5x5", data = "5x5"},
            {description = "7x7", data = "7x7"},
            {description = "9x9", data = "9x9"},
        },
        default = "5x5",
    },
    {
        name = "LITTLE_CRANE_SEARCH_RADIUS",
        label = IsChinese() and GetTitle("小小鹤草箱搜索距离") or GetTitle("Little Crane Box Search Radius"),
        hover = IsChinese() and GetTitle("小小鹤草箱搜索距离") or GetTitle("Little Crane Box Search Radius"),
        options = {
            {description = IsChinese() and "半径30" or "R30", data = 20},
            {description = IsChinese() and "半径60" or "R60", data = 60},
            {description = IsChinese() and "半径100" or "R100", data = 100},
            {description = IsChinese() and "半径200" or "R200", data = 200},
            {description = IsChinese() and "全图" or "Full Map", data = 0},
        },
        default = 0,
    },
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {name = "AAAA",label = IsChinese() and GetTitle("建筑") or GetTitle("Buildings"),hover = "",options = {{description = "",data = 0}},default = 0},
    {
        name = "MAIN_TREE_PROTECT_RADIUS",
        label = IsChinese() and GetTitle("万物之树覆盖半径") or GetTitle("Big Tree Protect Radius"),
        hover = IsChinese() and GetTitle("万物之树覆盖半径") or GetTitle("Big Tree Protect Radius"),
        options = {
          {description = "40", data = 40},
          {description = "28", data = 28},
        },
        default = 40,
    },
    {
        name = "atbook_numrecipepage",
        label = "[小狼]制作配方最大页数",
        hover = "制作配方最大页数",
        options =
        {
            { description = "3页", data = 3, hover = "制作配方最大3页" },
            { description = "5页", data = 5, hover = "制作配方最大5页" },
            { description = "8页", data = 8, hover = "制作配方最大8页" },
            { description = "10页", data = 10, hover = "制作配方最大10页" },
        },
        default = 5,
    },
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {name = "AAAA",label = IsChinese() and GetTitle("道具") or GetTitle("Items"),hover = "",options = {{description = "",data = 0}},default = 0},
    {
        name = "BUTTERFLY_WARPPING_PAPAER",
        label = IsChinese() and GetTitle("蝴蝶打包纸") or GetTitle("Butterfly Warp Paper"),
        hover = IsChinese() and GetTitle("蝴蝶打包纸") or GetTitle("Butterfly Warp Paper"),
        options = {
          {description = IsChinese() and "禁用" or "disable", data = 0},
          {description = IsChinese() and "安全使用" or "safe to use", data = 1},
          {description = IsChinese() and "不安全使用" or "not safe to use", data = 2},
        },
        default = 1
    },
    {
        name = "EQ_WORLD_SKIPPER",
        label = IsChinese() and GetTitle("道具 : 万物穿梭") or GetTitle("Item : World Skipper"),
        hover = IsChinese() and GetTitle("道具 : 万物穿梭") or GetTitle("Item : World Skipper"),
        options = {
          {description = IsChinese() and "禁用" or "disable", data = false},
          {description = IsChinese() and "启用" or "enable", data = true}
        },
        default = true
    },
    {
        name = "EQ_JUMBO_ICE_CREAM_TUB_HUNGER_MULT",
        label = IsChinese() and GetTitle("吨吨桶：玩家饥饿消耗速度") or GetTitle("Jumbo Ice Cream Tub : Player Hunger Down"),
        hover = IsChinese() and GetTitle("吨吨桶：玩家饥饿消耗速度") or GetTitle("Jumbo Ice Cream Tub : Player Hunger Down"),
        options = {
          {description = "50%", data = 50},
          {description = "80%", data = 80},
          {description = "正常速度", data = 100},
        },
        default = 50,
    },
    {
        name = "TBAT_BUFF_DISPLAY",
        label = IsChinese() and GetTitle("启用Buff显示") or GetTitle("Enable Buff Display"),
        hover = IsChinese() and GetTitle("是否显示Buff时间栏") or GetTitle("Whether to show buff time on the character"),
        options = {
            { description = "OFF", data = false },
            { description = "ON",  data = true },
        },
        default = false
    },
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {name = "AAAA",label = IsChinese() and GetTitle("动物") or GetTitle("Animals"),hover = "",options = {{description = "",data = 0}},default = 0},
    {
        name = "ANIMAL_PHYSICS_REMOVE",
        label = IsChinese() and GetTitle("MOD动物碰撞体积") or GetTitle("MOD animals physics collision"),
        hover = "",
        options = {
          {description = IsChinese() and "移除" or "remove", data = true},
          {description = IsChinese() and "不移除" or "don't remove", data = false},
        },
        default = false,
    },
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    {name = "AAAA",label = IsChinese() and GetTitle("DEBUG") or GetTitle("DEBUG"),hover = "",options = {{description = "",data = 0}},default = 0},
    {
        name = "DEBUGGING",
        label = IsChinese() and "开发者模式" or "Developer Mode",
        hover = IsChinese() and "开发者模式" or "Developer Mode",
        options = debugging_flag and {
          {description = "OFF",data = false}, 
          {description = "ON",data = true}
        } or {
          {description = "禁用",data = false},
          {description = "forbidden",data = false}
        },
        default = false
    },
  
}
