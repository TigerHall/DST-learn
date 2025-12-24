name = "宠物" -- mod的名称
description = "自动砍树，战斗，采集...\n五格装备栏 简易制作 物品信息  伤害数值 简易血条 永久保鲜 全图 显示状态 木牌传送\nF1:一键烹饪 F2:禁用宠物 F3:整理物品 F5:保存 F6:加载" -- mod的描述
author = "小乖" -- 作者名字
version = "1.0.0" -- mod的版本号


forumthread = ""
api_version = 6
api_version_dst = 10

reign_of_giants_compatible = true
shipwrecked_compatible = true
dont_starve_compatible = true

hamlet_compatible = true
all_clients_require_mod = false

--mod 图标配置
icon_atlas = "modicon.xml" -- mod图标的xml文件
icon = "modicon.tex" -- mod图标的tex文件


-- mod的配置选项
configuration_options = {
    {
        name = "show_global_map",
        label = "显示全局地图",
        options = {
            {description = "是", data = true},
            {description = "否", data = false},
        },
        default = true,
    },
    --添加一个配置，是否关闭自动保存
    {
        name = "disableautosave",
        label = "关闭自动保存",
        options = {
            {description = "是", data = true},
            {description = "否", data = false},
        },
        default = false,
    },
    --添加一个配置，当角色死亡的时候不删除档案
    {
        name = "disabledeleteondeath",
        label = "死亡不删除档案",
        options = {
            {description = "是", data = true},
            {description = "否", data = false},
        },
        default = true,
    },
}

