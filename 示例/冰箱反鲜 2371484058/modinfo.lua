local L = locale ~= "zh" and locale ~= "zhr" and locale ~= "zht"
version = "1.4.7"
name = L and "IceBox Refresh Food unlimited Day" or "冰箱返鲜上万天"
author = "傳說覺悟"
description = L and "version:"..version.." ID:2371484058\n1.IceBox and SaltBox can be upgraded via chestupgrade_stacksize. PS: After the upgrade, the tidying feature will be disabled.\n\n"..
[[
IceBox Refresh Food unlimited Day

History update:
1.Add IceBox and Saltbox slot setting 4x4 5x5 6x6.
2.Mushroom Lamp can put spores.
3.Added birdcage No Rot setting,seedpouch setting.
4.Fixed an issue that caused the return to freshness to fail to exceed the upper limit when running with the Island Adventures mod.
5.Remove the restriction that some items cannot be put in the refrige and salt box;

If the setting has no effect, please check whether it is used with other Refresh modules. If there is, it will give priority to other modules to work, so it has no effect.
]]
	or "当前版本: "..version.."   ID:2371484058\n1、更新使用弹性空间升级冰箱、盐盒后也能整理了；\n\n"..
[[
可以使有新鲜度的物品返鲜上万天，也可以让其立即腐烂

历史更新：
1.添加冰箱、盐盒支持 弹性空间 升级。
2.添加冰箱、盐盒格子设置4x4 5x5 6x6;
3.蘑菇灯可以放入孢子;
4.添加鸟笼永鲜设置，种子袋保鲜设置。

【注意】如果设置没有效果请检查是否与其他返鲜模组一起使用，如果有 可能冲突，因此没效果。

WeGame已发布
]]
forumthread = ""

api_version = 10
priority = 9

icon_atlas = "IceBox.xml"
icon = "IceBox.tex"

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true
client_only_mod = false
server_only_mod = true

server_filter_tags = { "icebox", "Refresh", "冰箱返鲜", "返鲜上万天", "返鲜", "icebox147",} --服务器标签

--兼容表，其他容器添加保鲜
--表内可手动添加，记得加逗号，主服务器加就行，加入房间的玩家一样生效
local otherlist = {
	"hiddenmoonlight",	--棱镜月藏宝匣
	--"revolvedmoonlight","revolvedmoonlight_pro",	--月轮宝盘
	--"backpack",			--背包
	"spicepack",			--厨师包
	--"piggyback",		--猪皮包
	--"myth_granary",		--神话谷仓
	--"myth_food_table",	--神话餐桌
}

translations = {
    ["en"] = {
		["开"] = "ON",
		["关"] = "OFF",
		["NULL"] = "",
		["突破天数"] = "Remove the day limit",
		["冰箱保鲜包冰妾"] = "IceBox IcePack Chester_ice",
		["盐盒设置"] = "SaltBox Set",
		["系统默认"] = "System default",
		["冰箱保鲜"] = "Ice Box",
		["盐盒保鲜"] = "Salt Box",
		["永久保鲜"] = "No Rot",
		["返鲜极慢"] = "Refresh(slow)",
		["返鲜慢"] = "Refresh",
		["返鲜快"] = "Refresh(fast)",
		["立刻腐烂"] = "Rot",
		["默认冰箱保鲜说明"] = "System default fridge",
		["默认盐盒保鲜说明"] = "The default salt box preservation degree of the system",
		["冰箱保鲜说明"] = "System fridge Freshness",
		["盐盒保鲜说明"] = "System Salt Box Freshness",
		["永久保鲜说明"] = "Permanent Freshness",
		["极慢返鲜说明"] = "Refresh unlimited Day(slow)",
		["慢速返鲜说明"] = "Refresh unlimited Day",
		["快速返鲜说明"] = "Refresh unlimited Day(fast)",
		["快速腐烂说明"] = "Put the food in and it will rot immediately",
		["锡鱼桶设置"] = "FishBox Set",
		["2倍保鲜"] = "2x freshness",
		["4倍保鲜"] = "4x freshness",
		["2倍保鲜说明"] = "2x freshness",
		["4倍保鲜说明"] = "4x freshness",
		["默认鱼桶说明"] = "The Default FishBox",
		["冰箱削弱"] = "1.5x",
		["冰箱削弱说明"] = "Default is 2x freshness, now it is 1.5x",
		["蘑菇灯设置"] = "MushroomLight Set",
		["骨灰罐设置"] = "Sisturn Set",
		["8倍保鲜"] = "8x freshness",
		["10倍保鲜"] = "10x freshness",
		["8倍保鲜说明"] = "8x freshness",
		["10倍保鲜说明"] = "10x freshness",
		["种子袋设置"]	= "Seedpouch Set",
		["坎普斯背包设置"] = "KrampusSack Set",
		["容器制冷"] = "Add fridge",
		["容器制冷说明"] = "The Container comes with a fridge effect and applies the fridge setting",
		["烹饪锅永鲜"] = "CookPot Set",
		["鸟笼永鲜"] = "Birdcage Set",
		["鸟笼永鲜说明"] = "No Die",
		["容器设置"] = "Container Set",
		["容器格子"] = "Container Slot",
		["容器格子说明"] = "Need to turn on the refrigerator and salt box slot setting to be effective",
		["容器格子关闭说明"] = "IceBox and saltbox settings do not take effect",
		["容器格子开启说明"] = "IceBox and saltbox settings take effect",
		["冰箱格子"] = "IceBox Slot",
		["冰箱盐盒格子说明"] = " ",
		["格子设置说明"] = " ",
		["9格"] = "9 Slot",
		["16格"] = "16 Slot",
		["25格"] = "25 Slot",
		["36格"] = "36 Slot",
		["盐盒格子"] = "SaltBox Slot",
		["胡子包设置"] = "Beard sack Set",
		["极地熊餐盒"] = "Beargerfur sack Set",
		["极地熊格子"] = "Beargerfur sack Slot",
		["极地熊格子说明"] = "",
		["其他容器列表"] = "Other Container List",
		["其他容器返鲜率"] = "Other Container RefreshLv",
		["其他容器返鲜率说明"] = "【Tips】If you add the list manually, you need to switch the Other Container List switch once to apply it.",
		["容器升级"] = "Chestupgrade_stacksize Box UP",
		["容器升级说明"] = "IceBox and SaltBox can be upgraded via chestupgrade_stacksize\nIf an error occurs, please turn this setting off",
		["存放类型开放"] = "Add storage types",
		["存放类型开放说明"] = "Remove storage restrictions on some fresh-keeping items",
		["冰箱"] = "IceBox",
		["盐盒"] = "SaltBox",
		["极地熊獾桶"] = "Beargerfur sack",
		["熊桶存放类型说明"] = "Same as Beard sack storage type",
		["蘑菇灯"] = "mushroom light",
		["蘑菇灯存放类型说明"] = "Can store spores",
	},
	["zh"] = {
		["开"] = "开",
		["关"] = "关",
		["NULL"] = "",
		["突破天数"] = "突破天数",
		["冰箱保鲜包冰妾"] = "冰箱/保鲜包/冰妾",
		["盐盒设置"] = "盐盒设置",
		["系统默认"] = "系统默认",
		["冰箱保鲜"] = "冰箱保鲜",
		["盐盒保鲜"] = "盐盒保鲜",
		["永久保鲜"] = "永久保鲜",
		["返鲜极慢"] = "返鲜(极慢)",
		["返鲜慢"] = "返鲜(慢)",
		["返鲜快"] = "返鲜(快)",
		["立刻腐烂"] = "立刻腐烂",
		["默认冰箱保鲜说明"] = "系统默认的冰箱保鲜程度",
		["默认盐盒保鲜说明"] = "系统默认的盐盒保鲜程度",
		["冰箱保鲜说明"] = "跟官方冰箱一样的保鲜程度",
		["盐盒保鲜说明"] = "跟官方盐盒一样的保鲜程度",
		["永久保鲜说明"] = "放入是什么样的新鲜程度就保持什么样的程度",
		["极慢返鲜说明"] = "放入后会返回最保鲜的状态，并且永远不会腐烂",
		["慢速返鲜说明"] = "返鲜，并慢速突破天数上限",
		["快速返鲜说明"] = "返鲜，并快速突破天数上限",
		["快速腐烂说明"] = "会快速腐烂",
		["锡鱼桶设置"] = "锡鱼桶设置",
		["2倍保鲜"] = "2倍保鲜",
		["4倍保鲜"] = "4倍保鲜",
		["2倍保鲜说明"] = "2倍保鲜",
		["4倍保鲜说明"] = "4倍保鲜",
		["默认鱼桶说明"] = "系统默认会返鲜的鱼桶",
		["冰箱削弱"] = "削弱",
		["冰箱削弱说明"] = "默认为2倍保鲜，现在是1.5倍",
		["蘑菇灯设置"] = "蘑菇灯设置",
		["骨灰罐设置"] = "骨灰罐设置",
		["8倍保鲜"] = "8倍保鲜",
		["10倍保鲜"] = "10倍保鲜",
		["8倍保鲜说明"] = "8倍保鲜",
		["10倍保鲜说明"] = "10倍保鲜",
		["种子袋设置"]	= "种子袋设置",
		["坎普斯背包设置"] = "坎普斯背包设置",
		["容器制冷"] = "容器制冷",
		["容器制冷说明"] = "容器可以冻暖石，保鲜率会自动适用冰箱设置",
		["烹饪锅永鲜"] = "烹饪锅永鲜",
		["鸟笼永鲜"] = "鸟笼永鲜",
		["鸟笼永鲜说明"] = "鸟不会死掉",
		["容器设置"] = "容器设置",
		["容器格子"] = "容器格子",
		["容器格子说明"] = "开启后下列的冰箱、盐盒格子设置才有效",
		["容器格子关闭说明"] = "关闭，下列设置不生效",
		["容器格子开启说明"] = "开启，下列设置生效",
		["冰箱格子"] = "冰箱格子",
		["冰箱盐盒格子说明"] = "与其他冰箱、盐盒扩容模组一起使用可能会引起冲突",
		["格子设置说明"] = " ",
		["9格"] = "9格",
		["16格"] = "16格",
		["25格"] = "25格",
		["36格"] = "36格",
		["盐盒格子"] = "盐盒格子",
		["胡子包设置"] = "胡子包设置",
		["极地熊餐盒"] = "极地熊獾桶设置",
		["极地熊格子"] = "极地熊獾桶格子",
		["极地熊格子说明"] = "",
		["其他容器列表"] = "其他容器列表",
		["其他容器返鲜率"] = "其他容器返鲜率",
		["其他容器返鲜率说明"] = "【注意】非专服如果手动添加了列表，需要把 其他容器列表 开关切换应用一次才能添加上",
		["容器升级"] = "弹性空间升级",
		["容器升级说明"] = "冰箱、盐盒可通过 弹性空间制造器 升级\n如果官方适配了支持该套件升级，请关闭此项设置以免发生崩溃！",
		["存放类型开放"] = "存放类型开放",
		["存放类型开放说明"] = "将保鲜容器部分新鲜度物品放入限制取消",
		["冰箱"] = "冰箱",
		["盐盒"] = "盐盒",
		["极地熊獾桶"] = "极地熊獾桶",
		["熊桶存放类型说明"] = "放入的类型跟胡子包一样",
		["蘑菇灯"] = "蘑菇灯",
		["蘑菇灯存放类型说明"] = "可放入孢子",
	},
	["zht"] = {
		["开"] = "開",
		["关"] = "關",
		["NULL"] = "",
		["突破天数"] = "突破天數",
		["冰箱保鲜包冰妾"] = "冰箱/保鮮包/冰妾",
		["盐盒设置"] = "鹽盒設置",
		["系统默认"] = "系統預設",
		["冰箱保鲜"] = "冰箱保鮮",
		["盐盒保鲜"] = "鹽盒保鮮",
		["永久保鲜"] = "永久保鮮",
		["返鲜极慢"] = "返鮮(極慢)",
		["返鲜慢"] = "返鮮(慢)",
		["返鲜快"] = "返鮮(快)",
		["立刻腐烂"] = "立刻腐爛",
		["默认冰箱保鲜说明"] = "系統預設的冰箱保鮮程度",
		["默认盐盒保鲜说明"] = "系統預設的鹽盒保鮮程度",
		["冰箱保鲜说明"] = "跟官方冰箱一樣的保鮮程度",
		["盐盒保鲜说明"] = "跟官方鹽盒一樣的保鮮程度",
		["永久保鲜说明"] = "放入是什麼樣的新鮮程度就保持什麼樣的程度",
		["极慢返鲜说明"] = "放入後會返回最保鮮的狀態，並且永遠不會腐爛",
		["慢速返鲜说明"] = "返鮮，並慢速突破天數上限",
		["快速返鲜说明"] = "返鮮，並快速突破天數上限",
		["快速腐烂说明"] = "會快速腐爛",
		["锡鱼桶设置"] = "錫魚桶設置",
		["2倍保鲜"] = "2倍保鮮",
		["4倍保鲜"] = "4倍保鮮",
		["2倍保鲜说明"] = "2倍保鮮",
		["4倍保鲜说明"] = "4倍保鮮",
		["默认鱼桶说明"] = "系統預設會返鮮的魚桶",
		["冰箱削弱"] = "削弱",
		["冰箱削弱说明"] = "默認為2倍保鮮，現在是1.5倍",
		["蘑菇灯设置"] = "蘑菇燈設置",
		["骨灰罐设置"] = "骨灰罐設置",
		["8倍保鲜"] = "8倍保鮮",
		["10倍保鲜"] = "10倍保鮮",
		["8倍保鲜说明"] = "8倍保鮮",
		["10倍保鲜说明"] = "10倍保鮮",
		["种子袋设置"]	= "種子袋設置",
		["坎普斯背包设置"] = "坎普斯背包設置",
		["容器制冷"] = "容器製冷",
		["容器制冷说明"] = "容器加入冰箱效果，同時適用冰箱設置",
		["烹饪锅永鲜"] = "烹飪鍋永鮮",
		["鸟笼永鲜"] = "鳥籠永鮮",
		["鸟笼永鲜说明"] = "鳥不會死掉",
		["容器设置"] = "容器設置",
		["容器格子"] = "容器格子",
		["容器格子说明"] = "開啟後下列的冰箱、鹽盒格子設置才有效",
		["容器格子关闭说明"] = "關閉，下列設置不生效",
		["容器格子开启说明"] = "開啟，下列設置生效",
		["冰箱格子"] = "冰箱格子",
		["冰箱盐盒格子说明"] = "與其他冰箱、鹽盒擴容模組一起使用可能會引起衝突",
		["格子设置说明"] = " ",
		["9格"] = "9格",
		["16格"] = "16格",
		["25格"] = "25格",
		["36格"] = "36格",
		["盐盒格子"] = "鹽盒格子",
		["胡子包设置"] = "鬍子包設置",
		["极地熊餐盒"] = "極地熊獾桶設置",
		["极地熊格子"] = "極地熊獾桶格子",
		["极地熊格子说明"] = "",
		["其他容器列表"] = "其他容器列表",
		["其他容器返鲜率"] = "其他容器返鮮率",
		["其他容器返鲜率说明"] = "【注意】非專服如果手動添加了列表，需要把 其他容器列表 開關切換應用一次才能添加上",
		["容器升级"] = "彈性空間升級",
		["容器升级说明"] = "冰箱、鹽盒可通過 彈性空間製造器 升級\n如果官方適配了支持該套件升級，請關閉此項設置以免發生崩潰！",
		["存放类型开放"] = "存放類型開放",
		["存放类型开放说明"] = "將保鮮容器部分新鮮度物品放入限制取消",
		["冰箱"] = "冰箱",
		["盐盒"] = "鹽盒",
		["极地熊獾桶"] = "極地熊獾桶",
		["熊桶存放类型说明"] = "放入的類型跟鬍子包一樣",
		["蘑菇灯"] = "蘑菇燈",
		["蘑菇灯存放类型说明"] = "可放入孢子",
	},
}
language = translations[locale]
if language == nil then language = translations["zh"] end

bugtracker_config = {
	--email = "chuansjw@qq.com",
	upload_client_log = true,
	upload_server_log = false,
	upload_other_mods_crash_log = true,
	--lang = "CHI",
}

configuration_options =
{
	{
		name = "UR_day",
		label = language["突破天数"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	{
		name = "FoodSp",
		label = language["冰箱保鲜包冰妾"],
		options =
	{
		{description = language["冰箱削弱"], data = 0.75, hover = language["冰箱削弱说明"]},
		{description = language["系统默认"], data = 0.5, hover = language["系统默认"]},
		{description = language["盐盒保鲜"], data = 0.25, hover = language["盐盒保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2, hover = language["极慢返鲜说明"]},
		{description = language["返鲜慢"], data = -10, hover = language["慢速返鲜说明"]},
		{description = language["返鲜快"], data = -100, hover = language["快速返鲜说明"]},
		{description = language["立刻腐烂"], data = 999999, hover = language["快速腐烂说明"]},
	},
		default = -100,
	},
	
	{
		name = "slbox",
		label = language["盐盒设置"],
		options =
	{
		{description = language["冰箱保鲜"], data = 0.5, hover = language["冰箱保鲜说明"]},
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2, hover = language["极慢返鲜说明"]},
		{description = language["返鲜慢"], data = -10, hover = language["慢速返鲜说明"]},
		{description = language["返鲜快"], data = -100, hover = language["快速返鲜说明"]},
		{description = language["立刻腐烂"], data = 999999, hover = language["快速腐烂说明"]},
	},
		default = false,
	},
	
	{
		name = "fsbox",
		label = language["锡鱼桶设置"],
		options =
	{
		{description = language["2倍保鲜"], data = 0.5, hover = language["2倍保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["4倍保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["系统默认"], data = false, hover = language["默认鱼桶说明"]},
		{description = language["返鲜快"], data = -100, hover = language["快速返鲜说明"]},
		{description = language["立刻腐烂"], data = 999999, hover = language["快速腐烂说明"]},
	},
		default = false,
	},
	
	{
		name = "mrlt",
		label = language["蘑菇灯设置"],
		options =
	{
		{description = language["2倍保鲜"], data = 0.5, hover = language["2倍保鲜说明"]},
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2, hover = language["极慢返鲜说明"]},
	},
		default = false,
	},
	
	{
		name = "sis_dt",
		label = language["骨灰罐设置"],
		options =
	{
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["2倍保鲜"], data = 0.5, hover = language["2倍保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["4倍保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2, hover = language["极慢返鲜说明"]},
	},
		default = 0,
	},
	
	{
		name = "seedpouch",
		label = language["种子袋设置"],
		options =
	{
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["4倍保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2, hover = language["极慢返鲜说明"]},
	},
		default = false,
	},
	
	{
		name = "krampus_sack",
		label = language["坎普斯背包设置"],
		options =
	{
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["容器制冷"], data = "cool", hover = language["容器制冷说明"]},
		{description = language["2倍保鲜"], data = 0.5, hover = language["冰箱保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["盐盒保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2},
		{description = language["返鲜慢"], data = -10},
		{description = language["返鲜快"], data = -100},
	},
		default = "cool",
	},
	
	{
		name = "beard_sack",
		label = language["胡子包设置"],
		options =
	{
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["2倍保鲜"], data = 0.5, hover = language["冰箱保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["盐盒保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2},
		{description = language["返鲜慢"], data = -10},
		{description = language["返鲜快"], data = -100},
	},
		default = false,
	},
	
	{
		name = "beargerfur_sack",
		label = language["极地熊餐盒"],
		options =
	{
		{description = language["2倍保鲜"], data = 0.5, hover = language["冰箱保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["盐盒保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["系统默认"], data = false, hover = language["系统默认"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2},
		{description = language["返鲜慢"], data = -10},
		{description = language["返鲜快"], data = -100},
	},
		default = false,
	},
	
	{
		name = "other_list",
        label = language["其他容器列表"],
		hover = "如：月藏宝匣，在 modinfo.lua 或 modoverrides.lua\n at modinfo.lua or modoverrides.lua",
		options = {
			{description = language["关"], data = false, hover = "列表关了其他容器返鲜率设置就无效了"},
			{description = language["开"], data = otherlist},
		},
        default = otherlist,
	},
	
	{
		name = "other_fx",
		label = language["其他容器返鲜率"],
		hover = language["其他容器返鲜率说明"],
		options =
	{
		{description = language["关"], data = false, hover = language["关"]},
		{description = language["容器制冷"], data = "cool", hover = language["容器制冷说明"]},
		{description = language["2倍保鲜"], data = 0.5, hover = language["冰箱保鲜说明"]},
		{description = language["4倍保鲜"], data = 0.25, hover = language["盐盒保鲜说明"]},
		{description = language["8倍保鲜"], data = 0.125, hover = language["8倍保鲜说明"]},
		{description = language["10倍保鲜"], data = 0.1, hover = language["10倍保鲜说明"]},
		{description = language["永久保鲜"], data = 0, hover = language["永久保鲜说明"]},
		{description = language["返鲜极慢"], data = -2},
		{description = language["返鲜慢"], data = -10},
		{description = language["返鲜快"], data = -100},
	},
		default = "cool",
	},
	
	{
		name = "cookpot_up",
		label = language["烹饪锅永鲜"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true, hover = language["永久保鲜"]},
	},
		default = true,
	},
	
	{
		name = "birdcage_up",
		label = language["鸟笼永鲜"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true, hover = language["鸟笼永鲜说明"]},
	},
		default = false,
	},
	
	{
		name = "",
		label = language["存放类型开放"],
		options =
	{
		{description = language["NULL"], data = 0},
	},
		default = 0,
	},
	
	{
		name = "itemtype_i",
		label = language["冰箱"],
		hover = language["存放类型开放说明"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	{
		name = "itemtype_s",
		label = language["盐盒"],
		hover = language["存放类型开放说明"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	{
		name = "itemtype_b",
		label = language["极地熊獾桶"],
		hover = language["熊桶存放类型说明"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	{
		name = "itemtype_m",
		label = language["蘑菇灯"],
		hover = language["蘑菇灯存放类型说明"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	{
		name = "",
		label = language["容器设置"],
		options =	{
						{description = language["NULL"], data = 0},
					},
		default = 0,
	},
	
	{
		name = "containers_upgraded",
		label = language["容器升级"],
		hover = language["容器升级说明"],
		options =
	{
		{description = language["关"], data = false},
		{description = language["开"], data = true},
	},
		default = true,
	},
	
	-- {
		-- name = "containers_up",
		-- label = language["容器格子"],
		-- hover = language["容器格子说明"],
		-- options =
	-- {
		-- {description = language["关"], data = false, hover = language["容器格子关闭说明"]},
		-- {description = language["开"], data = true, hover = language["容器格子开启说明"]},
	-- },
		-- default = true,
	-- },
	
	{
		name = "icebox_up",
		label = language["冰箱格子"],
		hover = language["冰箱盐盒格子说明"],
		options =
	{
		{description = language["系统默认"], data = false},
		{description = language["16格"], data = 1},
		{description = language["25格"], data = 2},
	},
		default = 1,
	},
	
	{
		name = "saltbox_up",
		label = language["盐盒格子"],
		hover = language["冰箱盐盒格子说明"],
		options =
	{
		{description = language["系统默认"], data = false},
		{description = language["25格"], data = 1},
		{description = language["36格"], data = 2},
	},
		default = 1,
	},
	
	{
		name = "beargerfur_sack_up",
		label = language["极地熊格子"],
		hover = language["极地熊格子说明"],
		options =
	{
		{description = language["系统默认"], data = false},
		{description = language["9格"], data = 1},
		{description = language["16格"], data = 2},
	},
		default = 1,
	},
}