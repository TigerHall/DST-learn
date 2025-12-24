local chs = locale == "zh" or locale == "zhr"

name = chs and "简易存储" or "Simple Storage"
description = 
[[2025.09.19, Version = 1.2.11

已默认启用：高性能模式
1、该模式旨在大幅降低终端的使用延迟。
2、在作者的电脑上，经测试可以同时访问超过100个容器而不卡顿。
3、该模式下使用无线终端功能不会引起额外性能负担。

Enabled by default: high-performance mode
1. This mode aims to significantly reduce the latency of terminal usage.
2. On the author's computer, it has been tested that it can access over 100 containers simultaneously without lagging.
3. Using wireless terminal functions in this mode will not cause additional performance burden.
]]

author = "WIGFRID"
version = "1.2.11"
forumthread = ""

dst_compatible = true

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false

all_clients_require_mod= true
api_version = 6

api_version_dst = 10
server_filter_tags = {"SimpleStorage"}

icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = -1

local function AddTitle(title)
    return {
        name = "null",
        label = title,
        options = {{ description = "", data = 0 }},
        default = 0
    }
end

configuration_options =
{
    -- wirelessterminal
    chs and
    {
        name = "wirelessterminal",
        label = "无线终端",
		hover = "无线终端",
        options = {
            {description = "禁用", data = false},
            {description = "启用", data = true},
        },
        default = false
    }
    or
	{
        name = "wirelessterminal",
        label = "Wireless Terminal",
		hover = "Wireless Terminal",
        options = {
            {description = "Disable", data = false},
            {description = "Enable", data = true},
        },
        default = false
    },
    -- linkradius
    chs and
    {
        name = "linkradius",
        label = "连通半径",
		hover = "连通半径",
        options = {
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
            {description = "30", data = 30},
            {description = "50", data = 50},
        },
        default = 15
    }
    or
	{
        name = "linkradius",
        label = "Link Radius",
		hover = "Link Radius",
        options = {
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
            {description = "30", data = 30},
            {description = "50", data = 50},
        },
        default = 15
    },
    -- tech2
    chs and
    {
        name = "tech2",
        label = "自带科技二本",
		hover = "自带科技二本",
        options = {
            {description = "禁用", data = false},
            {description = "启用", data = true},
        },
        default = false
    }
    or
	{
        name = "tech2",
        label = "Comes with TECH-2",
		hover = "Comes with TECH-2",
        options = {
            {description = "Disable", data = false},
            {description = "Enable", data = true},
        },
        default = false
    },
    -- performance
    AddTitle(chs and "性能优化" or "Performance Optimization"),
    chs and
    {
        name = "performance",
        label = "高性能模式",
		hover = "高性能模式",
        options = {
            {description = "默认启用", data = true},
        },
        default = true
    }
    or
	{
        name = "performance",
        label = "High Performance",
		hover = "High Performance",
        options = {
            {description = "Default Enable", data = true},
        },
        default = true
    },
}