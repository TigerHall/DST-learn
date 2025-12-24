local L = locale ~= "zh" and locale ~= "zhr"
name = L and "Storeroom (New)" or "储藏室 (新地窖)"
version = "2.7.1"
author = "MrM + 傳說覺悟"

description = L and "Your personal space. The fix no longer affects SaltBox and Tin FishBox.\n\nMod version: "..version.."  update:\n"..[[
1. Support chestupgrade_stacksize upgrade;
2. When setting only player destruction, the bear badger will no longer be able to slap out items, including other creatures slapping.
3. Support setting the upper limit of the number of days for returning to freshness.

Historical update:
1.Add SortOut.
2.Add Container Drag, Alt+RMouseDrag, Minus Reset.
3.Add 36, 120, 140, 160 slots.
4.20 slots changed to 25 slots, 5x5 form.
5.Compatible with the new tech bar.
6.Material, marble replaced with pigskin.
7.remove collision effect
]]
		or "建造一个更大的储存空间！修复不再影响盐盒和锡鱼箱。\n当前版本："..version.."  更新：\n"..[[
1.支持弹性空间套件升级；
2.设置仅玩家破坏时，熊獾将不能再拍出物品，包括其他生物打击也不掉出物品。
3.支持设置返鲜突破天数上限。

历史更新：
1.新增整理功能；
2.新增容器拖移功能，Alt+鼠标右键拖移，减号复原。
3.新增36、120、140、160格；
4.20格更改为25格，九宫格形式。
5.适配新版科技栏，可以在建筑、储物栏建造；
6.材料大理石更换成猪皮，毕竟要防水且还是内卷式的门。
7.去除碰撞效果，支持建6锅且不影响使用。

Wegame已更新
]]
-- description = desc_variant["en"] or desc_variant["Ch"]

forumthread = ""
api_version = 10
priority = -10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true
client_only_mod = false
server_only_mod = true


server_filter_tags = { "storeroom new", "新储藏室", "dj271",}

icon_atlas = "storeroom.xml"
icon = "storeroom.tex"

configuration_options =
{
	L and {
		name = "Craft",
		label = "Craft",
		hover = "",
		options =
	{
		{description = "Easy", data = "Easy", hover = ""},
		{description = "Normal", data = "Normal", hover = ""},
		{description = "Hard", data = "Hard", hover = ""},
	},
		default = "Easy",
	} or {
		name = "Craft",
		label = "建造难度",
		hover = "设置建造难度，默认为简单，难度越大需要材料越多",
		options =
	{
		{description = "简单", data = "Easy", hover = ""},
		{description = "正常", data = "Normal", hover = ""},
		{description = "困难", data = "Hard", hover = ""},
	},
		default = "Easy",
	},

	L and {
		name = "Slots",
		label = "Slots",
		hover = "Set the number of build storeroom Slots, the default is 80 Slots",
		options =
	{
		{description = "25(5x5)", data = 20},
		{description = "36(6x6)", data = 36},
		{description = "40", data = 40},
		{description = "60", data = 60},
		{description = "80", data = 80},
		{description = "120", data = 120, hover = "it takes up a lot of screen space and will inevitably be blocked by other UIs;"},
		{description = "140", data = 140, hover = "it takes up a lot of screen space and will inevitably be blocked by other UIs;"},
		{description = "160", data = 160, hover = "Not recommended! ! It takes up a lot of screen space and will block many areas;"},
	},
		default = 80,
	} or {
		name = "Slots",
		label = "格子数量",
		hover = "设置建造储藏室格子的数量，默认为80格",
		options =
	{
		{description = "25(5x5)", data = 20},
		{description = "36(6x6)", data = 36},
		{description = "40", data = 40},
		{description = "60", data = 60},
		{description = "80", data = 80},
		{description = "120", data = 120, hover = "格子多了也不是好事，占屏空间大难免会被其他UI挡住；"},
		{description = "140", data = 140, hover = "格子多了也不是好事，占屏空间大难免会被其他UI挡住；"},
		{description = "160", data = 160, hover = "不建议！！占屏空间很大,会挡住很多区域；"},
	},
		default = 80,
	},

	L and {
		name = "srfresh",
		label = "fresh set",
		hover = "The default is normal chest, the fresh effect can be set, and other fresh Mod settings can be inherited.",
		options =
	{
		{description ="normal chest", data = false, hover = "normal chest"},
		{description ="IceBox fresh", data = "cool", hover = "2x freshness"},
		{description ="4x fresh", data = 0.25, hover = "4x freshness"},
		{description ="6x fresh", data = 0.167, hover = "6x freshness"},
		{description ="8x fresh", data = 0.125, hover = "8x freshness"},
		{description ="10x fresh", data = 0.1, hover = "10x freshness"},
		{description ="No Rot", data = 0, hover = "Permanent Freshness"},
		{description ="Refresh(slow)", data = -2, hover = "Refresh(slow)"},
		{description ="Refresh", data = -10, hover = "Refresh"},
		{description ="Refresh(fast)", data = -100, hover = "Refresh(fast)"},
	},
		default = "cool",
	} or {
		name = "srfresh",
		label = "保鲜设置",
		hover = "默认为普通箱子，可设置保鲜效果，支持继承其他保鲜模组设置",
		options =
	{
		{description ="普通箱子", data = false, hover = "普通的箱子"},
		{description = "制冷箱子", data = "cool", hover = "2倍保鲜，支持继承其他冰箱返鲜模组设置"},
		{description = "4倍保鲜", data = 0.25, hover = "4倍保鲜"},
		{description = "6倍保鲜", data = 0.167, hover = "6倍保鲜"},
		{description = "8倍保鲜", data = 0.125, hover = "8倍保鲜"},
		{description = "10倍保鲜", data = 0.1, hover = "10倍保鲜"},
		{description = "永久保鲜", data = 0, hover = "永久保鲜"},
		{description = "返鲜(慢)", data = -2, hover = "很缓慢的返鲜"},
		{description = "返鲜", data = -10, hover = "返鲜速度适中"},
		{description = "返鲜(快)", data = -100, hover = "很快就返鲜完"},
	},
		default = "cool",
	},

	L and {
		name = "Destroyable",
		label = "Destroyable",
		hover = "",
		options =
	{
		{description = "All", data = "DestroyByAll"},
		{description = "Only Player", data = "DestroyByPlayer"},
		{description = "Disabled", data = "DestroyOff"},
	},
		default = "DestroyByPlayer",
	} or {
		name = "Destroyable",
		label = "是否可破坏",
		hover = "设置储存室是否可破坏，默认为可破坏",
		options =
	{
		{description = "可被破坏", data = "DestroyByAll"},
		{description = "只玩家破坏", data = "DestroyByPlayer"},
		{description = "不可破坏", data = "DestroyOff"},
	},
		default = "DestroyByPlayer",
	},
	
	L and {
		name = "sroom_drag",
		label = "Container UI drag",
		hover = "Enable Container UI drag",
		options =
		{
			{description = "OFF", data = false},
			{description = "ON", data = true},
		},
		default = true,
	} or {
		name = "sroom_drag",
		label = "容器拖移",
		hover = "启用容器拖移",
		options =
		{
			{description = "关闭", data = false},
			{description = "开启", data = true},
		},
		default = true,
	},
	
	L and {
		name = "FreshnessUp",
		label = "Freshness Up",
		hover = "Breaking the limit of the number of days to freshness",
		options =
		{
			{description = "OFF", data = false},
			{description = "ON", data = true},
		},
		default = false,
	} or {
		name = "FreshnessUp",
		label = "突破返鲜天数",
		hover = "有新鲜度的物品达到最新鲜后天数还会继续往上累加",
		options =
		{
			{description = "关闭", data = false},
			{description = "开启", data = true},
		},
		default = false,
	},

	L and {
		name = "Language",
		label = "Language",
		options =
	{
		{description = "简体中文", data = "Ch"},
		{description = "Finnish", data = "Fn"},
		{description = "Francais", data = "Fr"},
		{description = "Croatian", data = "Cr"},
		{description = "German", data = "Gr"},
		{description = "English", data = "En"},
		{description = "Polish", data = "Pl"},
		{description = "Portuguese", data = "Pr"},
		{description = "Spanish", data = "Sp"},
		{description = "Swedish", data = "Sw"},
		{description = "Turkish", data = "Tr"},
	},
		default = "En",
	} or {
		name = "Language",
		label = "语言设置",
		options =
	{
		{description = "简体中文", data = "Ch"},
		{description = "Finnish", data = "Fn"},
		{description = "Francais", data = "Fr"},
		{description = "Croatian", data = "Cr"},
		{description = "German", data = "Gr"},
		{description = "English", data = "En"},
		{description = "Polish", data = "Pl"},
		{description = "Portuguese", data = "Pr"},
		{description = "Spanish", data = "Sp"},
		{description = "Swedish", data = "Sw"},
		{description = "Turkish", data = "Tr"},
	},
		default = "Ch",
	},
}
