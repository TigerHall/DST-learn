-- This information tells other players more about the mod
local Ch = locale =="zh"or locale=="zhr"
name = Ch and
"原生作物" or
"Nature Plant"  --mod名字
description = Ch and
"使移植作物施肥后变为原生状态" or
"A fertilized plant will transform to nature form"  --mod描述
author = "Lilith" --作者
version = "0.0.1" -- mod版本 上传mod需要两次的版本不一样

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
forumthread = ""


-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Compatible with Don't Starve Together
dst_compatible = true --兼容联机

-- Not compatible with Don't Starve
dont_starve_compatible = false --不兼容原版
reign_of_giants_compatible = false --不兼容巨人DLC

-- Character mods need this set to true
all_clients_require_mod = true --所有人mod

icon_atlas = "modicon.xml" --mod图标
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {  --服务器标签
}

configuration_options =
	Ch and
{
	{
		name = "Language",
		label = "语言",
		options =   {
						{description = "English", data = false},
						{description = "简体中文", data = true},
					},
			default = true,
	},
	{
		name = "Manuretype",
		label = "施肥类型",
		options =   {
						{description = "肥料包", data = true},
						{description = "任何肥料", data = false},
					},
			default = true,
	},
}or
{
	{
		name = "Language",
		label = "Language",
		options =   {
						{description = "English", data = false},
						{description = "Chinese", data = true},
					},
		default = false,
	},
	{
		name = "Manuretype",
		label = "Manure type",
		options =   {
						{description = "compost wrap", data = true},
						{description = "any manure", data = false},
					},
			default = true,
	},
} --mod设置