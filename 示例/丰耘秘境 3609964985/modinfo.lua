local L = locale ~= "zh" and locale ~= "zhr"

name = "[DST]丰耘秘境 Harvest Mysterious Realm"

author = "晴浅"
version = "1.0.11"
priority = -999999999

description = not L and [[
风雨交加，电闪雷鸣，一双光团误入永恒大陆。
瞬息万变，光怪陆离，先辈们选择与这双神秘能量共生共存。
这双能量，一名为“辉煌”，另一名为“凶险”。
不是灾厄，也不会主动创造光明。
需要靠勤劳的双手，耕种、捕猎、收获、发展。

感谢游玩！
如您对本模组尚不了解，可在游戏内的“丰耘百科”中了解模组的详细信息。
如您在游玩中不幸遇到bug，或喜欢与小伙伴一起耕作，可添加模组交流群进行反馈。

交 流 群：667332070（Q）**12月1日前进群 免费领传说品质皮肤【凶险威澜台-魔法喷泉·粉嘟嘟】
开 发 者：晴浅（策划/代码/动画）  糊桃（美术）  娜娜（策划/美术/宣发）  素冥真仙（美术）  幽冥Dim（美术）
特别鸣谢：mooncake（代码/介绍网页）  肖羊小恩（美术）  逗豆豆逗（美术）  遗眷(介绍小程序撰写)   拾玖（介绍小程序平台）
模组版本：]]..version
or
[[
A silver lining pierces through a dark night with thunder, brought new vitality to THE CONSTANT. Ancestors of adventurers chose to coexist with these mysterious powers, "Perilous" and "Glorious". Those powers may bring disaster, they may not. You will decide how to use those powers. To build a bright new world or to be the Satan of THE CONSTANT. 
Thanks for subscribe.You can find more information by click the MOD BUTTON in the game. 
Created by:
QingQian (Game Design, Code, Illustration)  Hutao (Illustration)  Nana (Game Design, Advertising, Illustration)  Dim (Illustration)
Special Thanks to:
Sumingzhenxiang (Illustration)  Mooncake (Code, Web Design)  XiaoyangXiaoen (Illustration)  Doudou (Illustration)  ShiJiu (App Design)  YiJuan (App Design)
Mod Version:]]..version

forumthread = ""

api_version = 10

dst_compatible = true --兼容联机

dont_starve_compatible = false --不兼容原版
reign_of_giants_compatible = false --不兼容巨人DLC

all_clients_require_mod = true

icon_atlas = "images/icons/hmr_icon.xml"
icon = "hmr_icon.tex"

server_filter_tags = {
    "丰耘秘境", "HMR", "Harvest Mysterious Realm"
}

local INFO_STRINGS = {
    WORLD_GENERATION = {
        CH = "世界生成",
        EN = "World Generation",
    },
    CHERRY_ISLAND_GENERATION = {
        LABEL = {
            CH = "樱花岛生成难度",
            EN = "The generation difficulty of Cherry Island",
        },
        HOVER = {
            CH = "用于旧档补充未生成的樱花岛。难度越低，岛屿越容易在世界上生成，但同时可能会占用一些陆地面积。",
            EN = "It is used to supplement the ungenerated Sakura Island in the old file. The lower the difficulty, the easier it is for islands to form in the world, but at the same time, they may occupy some land area.",
        },
        OPTIONS = {
            MUST = {
                CH = "必然",
                EN = "Must",
            },
            EASY = {
                CH = "简单",
                EN = "Easy",
            },
            NORMAL = {
                CH = "正常",
                EN = "Normal",
            },
            DIFFICULT = {
                CH = "困难",
                EN = "Difficult",
            },
        },
    },

    EQUIPMENTS = {
        CH = "装备配置",
        EN = "Equipments",
    },
    HONOR_BACKPACK_SLOTS = {
        LABEL = {
            CH = "辉煌背包格子数量",
            EN = "The number of Honor Backpack Slots",
        },
        HOVER = {
            CH = "如果需要中途将格子数量从30调整至16，请先用30格进游戏将背包中的贵重物品取出，否则背包中的物品将会被吞！",
            EN = "Sets the number of Honor Backpack Slots.",
        },
        OPTIONS = {
            SIXTEEN = {
                CH = "16格",
                EN = "16",
            },
            THIRTY = {
                CH = "30格",
                EN = "30",
            },
        },
    },
    HONOR_STOWER_MAX_CONSUME = {
        LABEL = {
            CH = "自然亲和子塔每次最高消耗",
            EN = "The maximum consume of Firtilize for Honor Tower",
        },
        HOVER = {
            CH = "每次使用自然亲和子塔时的最高消耗百分比。",
            EN = "Sets the maximum consume of Firtilize for Honor Tower.",
        },
        OPTIONS = {
            RESERVE = {
                CH = "不使用完",
                EN = "Reserve",
            },
            TEN_PER = {
                CH = "10%",
                EN = "10%",
            },
            TWENTYFIVE_PER = {
                CH = "25%",
                EN = "25%",
            },
            FIFTY_PER = {
                CH = "50%",
                EN = "50%",
            },
            SEVENTYFIVE_PER = {
                CH = "75%",
                EN = "75%",
            },
            ONE_HUNDRED_PER = {
                CH = "100%",
                EN = "100%",
            },
        },
    }
}

local function GetString(key1, key2, key3)
    if key2 == nil then
        return INFO_STRINGS[key1][L and "EN" or "CH"]
    elseif key3 == nil then
        return INFO_STRINGS[key1][key2][L and "EN" or "CH"]
    else
        return INFO_STRINGS[key1][key2][key3][L and "EN" or "CH"]
    end
end

local function Title(key)
    return {
        name = "Title",
        label = GetString(key),
        options = {{description = "", data = ""}},
        default = "",
    }
end

--[[
配置项格式：
    name:配置项索引
    label:大标题
    hover:大标题下的详细描述
]]

-- 配置项
configuration_options = {
    Title("WORLD_GENERATION"),
    {
        name = "CHERRY_ISLAND_GENERATION",
        label = GetString("CHERRY_ISLAND_GENERATION", "LABEL"),
        hover = GetString("CHERRY_ISLAND_GENERATION", "HOVER"),
        options =
        {
            {description = GetString("CHERRY_ISLAND_GENERATION", "OPTIONS", "MUST"),        data = 0    },
            {description = GetString("CHERRY_ISLAND_GENERATION", "OPTIONS", "EASY"),        data = 30   },
            {description = GetString("CHERRY_ISLAND_GENERATION", "OPTIONS", "NORMAL"),      data = 52   },
            {description = GetString("CHERRY_ISLAND_GENERATION", "OPTIONS", "DIFFICULT"),   data = 60   },
        },
        default = 52,
    },

    Title("EQUIPMENTS"),
    {
        name = "HONOR_BACKPACK_SLOTS",
        label = GetString("HONOR_BACKPACK_SLOTS", "LABEL"),
        hover = GetString("HONOR_BACKPACK_SLOTS", "HOVER"),
        options =
        {
            {description = GetString("HONOR_BACKPACK_SLOTS", "OPTIONS", "SIXTEEN"),     data = 16   },
            {description = GetString("HONOR_BACKPACK_SLOTS", "OPTIONS", "THIRTY"),      data = 30   },
        },
        default = 30,
    },
    {
        name = "HONOR_STOWER_MAX_CONSUME",
        label = GetString("HONOR_STOWER_MAX_CONSUME", "LABEL"),
        hover = GetString("HONOR_STOWER_MAX_CONSUME", "HOVER"),
        options =
        {
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "RESERVE"),           data = 0.00 },
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "TEN_PER"),           data = 0.10 },
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "TWENTYFIVE_PER"),    data = 0.25 },
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "FIFTY_PER"),         data = 0.50 },
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "SEVENTYFIVE_PER"),   data = 0.75 },
            {description = GetString("HONOR_STOWER_MAX_CONSUME", "OPTIONS", "ONE_HUNDRED_PER"),   data = 1.00 },
        },
        default = 0.25,
    }
}