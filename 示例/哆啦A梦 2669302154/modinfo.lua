--------------------------------
--[[ mod相关信息]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
local zh = locale == "zh" or locale == "zhr" --中文
local _version = "2.3"

name = zh and "哆啦A梦科技" or "Doraemon Tech"
description = zh and
    "[版本]".._version.."\n"..
    "可以解锁哆啦A梦的相关魔法物品\n"..
    "感谢订阅本mod!本mod目前仅发布在Steam和WeGame平台\n"
 or
    "[Version]".._version.."\n"..
    "unlock some things about doraemon\n"..
    "Thanks for subscribing  this mod! And this mod only published on Steam and WeGame platform now.\n"
author = "谅直"
version = _version

forumthread = ""

dst_compatible = true--兼容联机
dont_starve_compatible = false --不兼容单机
all_clients_require_mod = true--所有人mod

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

--server_filter_tags = zh and {"哆啦A梦科技"} or {"doraemon tech"} --服务器标签可以不写
server_filter_tags = {"哆啦","哆啦A梦","哆啦A梦科技","科技","doraemon","doraemon tech","tech"}
configuration_options = {
    {
        name = "language",
        label = zh and "语言" or "language",
        hover = zh and "设置语言" or "Please Select Your Language",
        options =
        {
            {description = "中文", data = 'chs'},
            {description = "English", data = 'en'},
        },
        default = zh and 'chs' or 'en',
    },
    {
        name = "camera_share",
        label = zh and "摄像头是否共享" or "Whether the camera is shared",
        hover = zh and "共享则所有玩家都可以使用" or "If shared, all players can use it",
        options =
        {
            {description = "yes", data = true},
            {description = "no", data = false},
        },
        default = true,
    },
    {
        name = "destroy_bonus",
        label = zh and "销毁垃圾是否给予奖励" or "Is there a reward for trash destruction",
        hover = zh and "每销毁100个物品会给予奖励,每第五次奖励必会有高价值物品" or "A reward will be given for every 100 items destroyed,Every fifth reward must have a high value item",
        options =
        {
            {description = "yes", data = true},
            {description = "no", data = false},
        },
        default = true,
    },
    {
        name = "destroy_ground_backpack",
        label = zh and "秘密垃圾洞:销毁背包" or "Secret Garbage Hole: Destroy backpacks",
        hover = zh and "点击销毁会同时销毁附近的背包" or "Click Destroy to destroy nearby backpacks as well",
        options =
        {
            {description = "yes", data = true},
            {description = "no", data = false},
        },
        default = false,
    },
    {
        name = "destroy_ground_heavy",
        label = zh and "秘密垃圾洞:销毁重物" or "Secret Garbage Hole: Destroy heavy objects",
        hover = zh and "点击销毁会同时销毁附近的重物" or "Click Destroy to destroy nearby heavy objects as well",
        options =
        {
            {description = "yes", data = true},
            {description = "no", data = false},
        },
        default = false,
    },
}
