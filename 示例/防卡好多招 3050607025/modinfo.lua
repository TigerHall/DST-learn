local Ch = (locale == 'zh' or locale == 'zhr')
name = Ch and "防卡好多招" or "Lag Remover"
author = "大大果汁、凉时白开、小瑾、天涯共此时、小花朵"
version = "2.8.2"
-- 可通过命令自定义任何需清理物品和数量。
-- 单个物品：#keep_item@物品代码:数量，如#keep_item@hivehat:2
-- 多个物品：#keep_item@物品1代码:数量;物品2代码:数量，可输入多个，中间用;分隔。
--         如#keep_item@spiderhat:2;hivehat:2;monkey_smallhat:2;cutless:2;monkey_mediumhat
description11 = Ch and [[
特别感谢：大大果汁、凉时白开、小瑾
功能包括：
 ・ 1.掉落物自动堆叠；
 ・ 2.设置物品最大堆叠数量(40 - 999)；
 ・ 3.更多原本不可堆叠物品可进行堆叠；
 ・ 4.定期清理服务器垃圾物品(可配置。超过配置数量部分会被清理);
 ・ 5.按U私聊框，输入命令可立即清理:#clean或#清理;
 ・ 6.鱼人王、猪王、鸟笼、蚁狮可以批量交互；
 ・ 7.禁止树木重生；
 ・ 8.普通小树枝替换多枝树；
 ・ 9.砍树不留根；
 ・ 10.现在，任何物品都可添加到清理队列，详情查看创意工坊介绍页或modinfo.lua文件；

 ・ 只清理【自动清理细项】中的内容，其余物品不会被清理。
 ・ 有用物品记得放宝箱，超过配置数量部分会被清理！
 手动清理垃圾
按U私聊框，输入命令#clean可立即手动清理（需管理员权限）
可通过命令自定义任何需清理物品和数量。按U私聊输入命令，用法如下
单个物品：#keep_item@物品代码:数量，如#keep_item@hivehat:2
多个物品：#keep_item@物品1代码:数量;物品2代码:数量，可输入多个，中间用;分隔，如#keep_item@spiderhat:2;hivehat:2;monkey_smallhat:2;cutless:2;monkey_mediumhat:2
]]
description1 = Ch and [[
特别感谢：大大果汁、凉时白开、小瑾

只清理地面超过配置数量物品，容器内不会被清理！
只清理配置项列表物品，其余物品不会被清理！
若某物品最大地面保留数量为2（组），假设地面有3组该物品，堆叠数量分别为:1,10,20，那么那么将随机清理其中一组

>>如何手动触发清理？
按U私聊输入命令#cl

>>如何将配置中不存在的物品加入清理？
可通过命令自定义任何需清理物品和数量。按U私聊输入命令，用法如下
单个物品：#keep_item@物品代码:数量，如#keep_item@hivehat:2
多个物品：#keep_item@物品1代码:数量;物品2代码:数量，可输入多个，中间用;分隔
如#keep_item@spiderhat:2;hivehat:2;monkey_smallhat:2
]]  or [[
Special thanks: 大大果汁、凉时白开、小瑾
Features include:
 ・ 1. Falling objects are automatically stacked;
 ・ 2. Set the maximum number of stacked items(40 - 200);
 ・ 3. More non - stackable items can be stacked;
 ・ 4. Remove server garbage regularly(configurable).
 ・ 5. Press the U private chat box and enter the command #clean_world to clean it immediately
 ・ 6. Fast trading with Pigking, Mermking, birds
 ・ 7. Prohibit the regeneration of trees;
 ・ 8. Common twigs replace multi - branched trees;
 ・ 9. Cut down trees without leaving roots;
 ・ 10. See the introduction page of Creative Workshop for more information;
]]

description = '〔望月〕版本号: ' .. version .. '\n\n' .. description1

forumthread = ""
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = false
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
server_filter_tags = {"stack", "clean", "Lag Remover", "防卡好多招", "堆叠", "清理"}
priority = -11

local cleancycle = {}
cleancycle[1] = {description=""..(1).."", data=1}
cleancycle[2] = {description=""..(3).."", data=3}
for i = 5, 20, 5 do
    cleancycle[i / 5 + 2] = {description=""..(i).."", data=i}
end

local stackradius = {}
for i = 5, 45, 5 do
    stackradius[i / 5] = {description=""..(i).."", data=i}
end

local cleanunitx10_2 = {}
for i = 0, 6 do
    cleanunitx10_2[i + 1] = {description=""..(i * 2).."", data=i * 2}
end

local cleanunitx18_3 = {}
for i = 0, 6 do
    cleanunitx18_3[i + 1] = {description=""..(i * 3).."", data=(i * 3)}
end

local cleanunitx30_5 = {}
for i = 0, 6 do
    cleanunitx30_5[i + 1] = {description=""..(i * 5).."", data=i * 5}
end

local cleanunitx60_10 = {}
for i = 0, 6 do
    cleanunitx60_10[i + 1] = {description=""..(i * 10).."", data=i * 10}
end

local cleanunitx200_20 = {}
for i = 0, 10 do
    cleanunitx200_20[i + 1] = {description=""..(i * 20).."", data=(i * 20)}
end

cleanunitx10_2[8]    = {description=Ch and "不清理" or "Never clean up", data=99999}
cleanunitx18_3[8]    = {description=Ch and "不清理" or "Never clean up", data=99999}
cleanunitx30_5[8]    = {description=Ch and "不清理" or "Never clean up", data=99999}
cleanunitx60_10[8]   = {description=Ch and "不清理" or "Never clean up", data=99999}
cleanunitx200_20[12] = {description=Ch and "不清理" or "Never clean up", data=99999}

cleanunitx10_2[1]    = {description=Ch and "全清理" or "0", data=0}
cleanunitx18_3[1]    = {description=Ch and "全清理" or "0", data=0}
cleanunitx30_5[1]    = {description=Ch and "全清理" or "0", data=0}
cleanunitx60_10[1]   = {description=Ch and "全清理" or "0", data=0}
cleanunitx200_20[1]  = {description=Ch and "全清理" or "0", data=0}

-- 添加分段标题
local function addTitle(title)
    return {
        name = "EmptyNull",
        label = title,
        hover = nil,
        options = {
            { description = "", data = 0 }
        },
        default = 0
    }
end

configuration_options =
{
    addTitle(Ch and "==基本功能配置==" or "Basic Function Configurations"),
    {
        name = "CH_LANG",
        label = Ch and "语言(Language)" or "Language",
        options =
        {
            {description = "中文", data = true},
            {description = "English", data = false}
        },
        default = Ch and true or false
    },
    {
        name = "AUTO_STACK",
        label = Ch and "掉落堆叠" or "Auto stack",
        hover = Ch and "设置是否开启掉落物自动堆叠" or "Set whether to enable automatic stacking of dropped items",
        options =
        {
            {description = Ch and "开启" or "On", data = true, hover = Ch and "掉落相同的物品会自动堆叠在一起" or "Auto stack the same items on the ground."},
            {description = Ch and "禁用" or "Off", data = false, hover = Ch and "掉落相同的物品不会自动堆叠" or "Nothing will happen."}
        },
        default = true
    },
    {
        name = 'STACK_RADIUS',
        label = Ch and '堆叠半径' or 'Stack sadius',
        hover = Ch and "设置你的堆叠半径" or "Set your stacking radius",
        options = stackradius,
        default = 10
    },
    {
        name = "STACK_SIZE",
        label = Ch and "堆叠数值" or "Stack size",
        hover = Ch and "设置可堆叠物品的堆叠上限数值，建议最大999" or "Stack size，The recommended maximum is 999",
        options = 
        {	
            {description = Ch and "原始数值" or "Raw value", data = 0},
            {description = "40", data = 40},
            {description = "99", data = 99},
            {description = "100", data = 100},
            {description = "200", data = 200},
            {description = "500", data = 500},
            {description = "999", data = 999},
            {description = "9999", data = 9999},
            {description = "99999", data = 99999},
        },
        default = 100
    },
    {
        name = "STACK_OTHER_OBJECTS",
        label = Ch and "更多堆叠" or "Additional Items Stackable",
        hover = Ch and "可堆叠鱼类、鸟类、高脚鸟等原本不可堆叠的物品" or "Now you can stack fish, birds, tall bird egg, horn etc",
        options = 
        {	
            {description = Ch and "开启(含高鸟蛋)" or "On_A", data = "A", hover = Ch and  "此配置下可堆叠小兔子、鼹鼠、鸟类、蜘蛛类等等，包括高鸟蛋和岩浆虫卵" or ""},
            {description = Ch and "开启(无高鸟蛋)" or "On_B", data = "B",hover = Ch and  "此配置下可堆叠小兔子、鼹鼠、鸟类、蜘蛛类等等，不包括高鸟蛋和岩浆虫卵" or ""},
            {description = Ch and "禁用" or "Off", data = "OFF"}
        },
        default = "A"
    },
    {
        name = "BATCH_TRADE",
        label = Ch and "批量交易" or "Batch trade",
        hover = Ch and "支持猪王、鸟笼、鱼人王批量交易，不兼容永不妥协" or "instead of trade 1 by 1 , now you can trade a stack of item at once. Works to PigKing, Birds, MerdKing",
        options = 
        {	
            {description = Ch and "开启" or "On", data = true},
            {description = Ch and "禁用" or "Off", data = false}
        },
        default = true
    },
    {
        name = "TREES_NO_STUMP",
        label = Ch and "伐树无根" or "Trees no stump",
        hover = Ch and "砍伐树木后，自动移除树根(掉落1个木头)，防止卡顿" or "After chopping down trees, the stumps are automatically removed",
        options = 
        {	
            {description = Ch and "开启" or "On", data = true},
            {description = Ch and "禁用" or "Off", data = false}
        },
        default = true
    },
    {
        name = "TREES_NO_REGROWTH",
        label = Ch and "禁止树木循环" or "Trees no Regrowth",
        hover = Ch and "部分树木和大理石树长到第三阶段即停止循环生长， 防止卡顿" or "Evergreen, Marble trees and few other trees will stop regrowth at their 3rd stage.",
        options = 
        {	
            {description = Ch and "开启" or "On", data = true},
            {description = Ch and "禁用" or "Off", data = false}
        },
        default = true
    },
    {
        name = "TWIGGY",
        label = Ch and "我不要多枝树" or "No Twiggy",
        hover = Ch and "世界所有多枝树变成普通可采集小树苗" or "No more Twiggy in the game.",
        options = 
        {	
            {description = Ch and "开启" or "On", data = true},
            {description = Ch and "禁用" or "Off", data = false}
        },
        default = false
    },
    {
        name = "AUTO_CLEAN",
        label = Ch and "自动清理" or "Auto Clean",
        hover = Ch and "设置是否开启定时清理服务器无用物品" or "Clean the world in centain time, to make sure you game smooth. ",
        options =
        {
            {description = Ch and "开启" or "On", data = true, hover = Ch and "每过 N 天自动清理服务器无用物品" or "All servers clean every N days"},
            {description = Ch and "禁用" or "Off", data = false, hover = Ch and "啥事儿都不发生" or "Nothing will happen."}
        },
        default = true
    },
    {
        name = "CLEAN_DAYS",
        label = Ch and "清理周期" or "Cleaning cycle",
        hover = Ch and "每N天清理进行一次清理" or "Clean up per N days",
        options = cleancycle,
        default = 5	
    },
    {
        name = "ANNOUNCE_MODE",
        label = Ch and "清理宣告" or "Cleaning announcements",
        hover = Ch and "在游戏中以公告的形式说明具体清理内容" or "List what items cleaned by the mod",
        options =
        {
            {description = Ch and "开启" or "Off", data = false},
            {description = Ch and "关闭" or "On", data = true}
        },
        default = false
    },
	{
        name = "WINTER_ORNAMENT",
        label = Ch and "冬季盛宴/万圣夜" or "WINTER ORNAMENT",
        hover = Ch and "物品掉落30秒后自动清理处于地上的物品，容器内不影响" or "Cleanup dropped items after 30s (not in containers).",
        options = 
        {	
            {description = Ch and "掉落30s后清理" or "ON", hover = Ch and "物品掉落30秒后自动清理处于地上的物品，容器内不影响" or "Cleanup dropped items after 30s (not in containers).",data = true},
            {description = Ch and "禁用" or "OFF", data = false}
        },
        default = false
    },
    {
        name = "TEST_MODE",
        label = Ch and "测试模式" or "Test mode",
        options =
        {
            {description = Ch and "开启" or "On", data = true, hover = Ch and "测试模式开，清理周期变为10秒一次" or "Test mode on, clean cycle = 10s."},
            {description = Ch and "关闭" or "Off", data = false, hover = Ch and "测试模式关。" or "Test mode off"}
        },
        default = false,
        hover = Ch and "测试模式_非必要请勿修改" or "only for writer, leave it off"
    },
    addTitle(Ch and "==自动清理细项==" or "Automatic Cleaning Of Details"),
    {
        name = "food_candy",
        label = Ch and "节日零食/糖果" or "winter_food/candy",
        options = cleanunitx10_2,
        default = 0,	
        hover = Ch and "节节日零食/糖果的最大地面保留数量(组)" or "the maximum amount of the winter_food/candy"
    },
    {
        name = "winter_ornament",
        label = Ch and "冬季盛宴装饰" or "winter ornament",
        options = cleanunitx10_2,
        default = 0,	
        hover = Ch and "冬季盛宴装饰的最大地面保留数量(组)" or "the maximum amount of the winter ornament"
    },
    {
        name = "halloween_ornament",
        label = Ch and "万圣节装饰" or "halloween ornament",
        options = cleanunitx10_2,
        default = 0,	
        hover = Ch and "万圣节装饰的最大地面保留数量(组)" or "the maximum amount of the halloween ornament"
    },
    {
        name = "trinket",
        label = Ch and "万圣节小玩意" or "trinket",
        options = cleanunitx10_2,
        default = 0,	
        hover = Ch and "万圣节小玩意的最大地面保留数量(组)" or "the maximum amount of the trinket"
    },
    {
        name = "tentaclespike",
        label = Ch and "触手尖刺" or "tentaclespike",
        options = cleanunitx18_3,
        default = 6,	
        hover = Ch and "触手尖刺的最大地面保留数量(组)" or "the maximum amount of the tentaclespike"
    },
    {
        name = "grassgekko",
        label = Ch and "草蜥蜴" or "grassgekko",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "草蜥蜴的最大地面保留数量(组)" or "the maximum amount of the grassgekko"
    },
    {
        name = "armor_sanity",
        label = Ch and "影甲" or "armor_sanity",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "影甲的最大地面保留数量(组)" or "the maximum amount of the armor_sanity"
    },
    {
        name = "shadowheart",
        label = Ch and "影心" or "shadowheart",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "影心的最大地面保留数量(组)" or "the maximum amount of the shadowheart"
    },
    {
        name = "hound",
        label = Ch and "狗" or "hound",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "狗的最大地面保留数量(组)" or "the maximum amount of the hound"
    },
    {
        name = "firehound",
        label = Ch and "火狗" or "firehound",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "火狗的最大地面保留数量(组)" or "the maximum amount of the firehound"
    },
    {
        name = "spider",
        label = Ch and "蜘蛛/蜘蛛战士" or "spider/spider_warrior",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "蜘蛛/蜘蛛战士最大数量" or "the maximum amount of the spider/spider_warrior"
    },
    {
        name = "flies",
        label = Ch and "苍蝇/蚊子" or "flies/mosquito",
        options = cleanunitx10_2,
        default = 4,	
        hover = Ch and "苍蝇/蚊子的最大地面保留数量(组)" or "the maximum amount of the flies/mosquito"
    },
    {
        name = "bee",
        label = Ch and "蜜蜂/杀人蜂" or "bee/killerbee",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "蜜蜂/杀人蜂的最大地面保留数量(组)" or "the maximum amount of the bee/killerbee"
    },
    {
        name = "frog",
        label = Ch and "青蛙" or "frog",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "青蛙的最大地面保留数量(组)" or "the maximum amount of the frog"
    },
    {
        name = "beefalo",
        label = Ch and "牛" or "beefalo",
        options = cleanunitx60_10,
        default = 30,	
        hover = Ch and "牛的最大地面保留数量(组)" or "the maximum amount of the beefalo"
    },
    {
        name = "deer",
        label = Ch and "鹿" or "deer",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "鹿的最大地面保留数量(组)" or "the maximum amount of the deer"
    },
    {
        name = "slurtle",
        label = Ch and "鼻涕虫/蜗牛" or "slurtle/snurtle",
        options = cleanunitx30_5,
        default = 5,	
        hover = Ch and "鼻涕虫/蜗牛的最大地面保留数量(组)" or "the maximum amount of the slurtle/snurtle"
    },
    {
        name = "rocky",
        label = Ch and "石虾" or "rocky",
        options = cleanunitx60_10,
        default = 20,	
        hover = Ch and "石虾的最大地面保留数量(组)" or "the maximum amount of the rocky"
    },
    {
        name = "evergreen_sparse",
        label = Ch and "常青树" or "evergreen_sparse",
        options = cleanunitx200_20,
        default = 140,	
        hover = Ch and "常青树的最大地面保留数量(组)" or "the maximum amount of the evergreen_sparse"
    },
    {
        name = "twiggytree",
        label = Ch and "树枝树" or "twiggytree",
        options = cleanunitx200_20,
        default = 140,	
        hover = Ch and "树枝树的最大地面保留数量(组)" or "the maximum amount of the twiggytree"
    },
    {
        name = "marsh_tree",
        label = Ch and "针刺树" or "marsh_tree",
        options = cleanunitx200_20,
        default = 100,	
        hover = Ch and "针刺树的最大地面保留数量(组)" or "the maximum amount of the marsh_tree"
    },
    {
        name = "rock_petrified_tree",
        label = Ch and "石化树" or "rock_petrified_tree",
        options = cleanunitx200_20,
        default = 140,	
        hover = Ch and "石化树的最大地面保留数量(组)" or "the maximum amount of the rock_petrified_tree"
    },
    {
        name = "skeleton_player",
        label = Ch and "玩家尸体" or "skeleton_player",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "玩家尸体的最大地面保留数量(组)" or "the maximum amount of the skeleton_player"
    },
    {
        name = "spiderden",
        label = Ch and "蜘蛛巢" or "spiderden",
        options = cleanunitx30_5,
        default = 20,	
        hover = Ch and "蜘蛛巢的最大地面保留数量(组)" or "the maximum amount of the spiderden"
    },
    {
        name = "burntground",
        label = Ch and "陨石痕跡" or "burntground",
        options = cleanunitx10_2,
        default = 4,	
        hover = Ch and "陨石痕跡的最大地面保留数量(组)" or "the maximum amount of the burntground"
    },
    {
        name = "seeds",
        label = Ch and "种子" or "seeds",
        options = cleanunitx30_5,
        default = 10,	
        hover = Ch and "种子的最大地面保留数量(组)" or "the maximum amount of the seeds"
    },
    {
        name = "log",
        label = Ch and "木头" or "log",
        options = cleanunitx200_20,
        default = 60,	
        hover = Ch and "木头的最大地面保留数量(组)" or "the maximum amount of the log"
    },
    {
        name = "pinecone",
        label = Ch and "松果" or "pinecone",
        options = cleanunitx200_20,
        default = 60,	
        hover = Ch and "松果的最大地面保留数量(组)" or "the maximum amount of the pinecone"
    },
    {
        name = "cutgrass",
        label = Ch and "草" or "cutgrass",
        options = cleanunitx60_10,
        default = 10,	
        hover = Ch and "草的最大地面保留数量(组)" or "the maximum amount of the cutgrass"
    },
    {
        name = "twigs",
        label = Ch and "树枝" or "twigs",
        options = cleanunitx60_10,
        default = 10,	
        hover = Ch and "树枝的最大地面保留数量(组)" or "the maximum amount of the twigs"
    },
    {
        name = "rocks",
        label = Ch and "石头" or "rocks",
        options = cleanunitx60_10,
        default = 40,	
        hover = Ch and "石头的最大地面保留数量(组)" or "the maximum amount of the rocks"
    },
    {
        name = "nitre",
        label = Ch and "硝石" or "nitre",
        options = cleanunitx60_10,
        default = 40,	
        hover = Ch and "硝石的最大地面保留数量(组)" or "the maximum amount of the nitre"
    },
    {
        name = "flint",
        label = Ch and "燧石" or "flint",
        options = cleanunitx60_10,
        default = 40,	
        hover = Ch and "燧石的最大地面保留数量(组)" or "the maximum amount of the flint"
    },
    {
        name = "poop",
        label = Ch and "粪便" or "poop",
        options = cleanunitx30_5,
        default = 2,	
        hover = Ch and "粪便的最大地面保留数量(组)" or "the maximum amount of the poop"
    },
    {
        name = "guano",
        label = Ch and "鸟粪" or "guano",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "鸟粪的最大地面保留数量(组)" or "the maximum amount of the guano"
    },
    {
        name = "manrabbit_tail",
        label = Ch and "兔毛" or "manrabbit_tail",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "兔毛尾巴的最大地面保留数量(组)" or "the maximum amount of the manrabbit_tail"
    },
    {
        name = "silk",
        label = Ch and "蜘蛛丝" or "silk",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "蜘蛛丝的最大地面保留数量(组)" or "the maximum amount of the silk"
    },
    {
        name = "spidergland",
        label = Ch and "蜘蛛腺体" or "spidergland",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "蜘蛛腺体的最大地面保留数量(组)" or "the maximum amount of the spidergland"
    },
    {
        name = "stinger",
        label = Ch and "蜂刺" or "stinger",
        options = cleanunitx10_2,
        default = 2,
        hover = Ch and "蜂刺的最大地面保留数量(组)" or "the maximum amount of the stinger"
    },
    {
        name = "houndstooth",
        label = Ch and "狗牙" or "houndstooth",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "狗牙的最大地面保留数量(组)" or "the maximum amount of the houndstooth"
    },
    {
        name = "mosquitosack",
        label = Ch and "蚊子血袋" or "mosquitosack",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "蚊子血袋的最大地面保留数量(组)" or "the maximum amount of the mosquitosack"
    },
    {
        name = "glommerfuel",
        label = Ch and "格罗姆粘液" or "glommerfuel",
        options = cleanunitx10_2,
        default = 10,	
        hover = Ch and "格罗姆粘液的最大地面保留数量(组)" or "the maximum amount of the glommerfuel"
    },
    {
        name = "slurtleslime",
        label = Ch and "鼻涕虫粘液/鼻涕虫壳碎片" or "slurtleslime/slurtle_shellpieces",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "鼻涕虫粘液/鼻涕虫壳碎片的最大地面保留数量(组)" or "the maximum amount of the slurtleslime/slurtle_shellpieces"
    },
    {
        name = "spoiled_food",
        label = Ch and "腐烂食物" or "spoiled_food",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "腐烂食物的最大地面保留数量(组)" or "the maximum amount of the spoiled_food"
    },
    {
        name = "blueprint",
        label = Ch and "蓝图" or "blueprint",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "蓝图的最大地面保留数量(组)" or "the maximum amount of the blueprint"
    },
    {
        name = "axe",
        label = Ch and "斧子" or "axe",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "斧子的最大地面保留数量(组)" or "the maximum amount of the axe"
    },
    {
        name = "torch",
        label = Ch and "火把" or "torch",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "火把的最大地面保留数量(组)" or "the maximum amount of the torch"
    },
    {
        name = "pickaxe",
        label = Ch and "镐子" or "pickaxe",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "镐子的最大地面保留数量(组)" or "the maximum amount of the pickaxe"
    },
    {
        name = "hammer",
        label = Ch and "锤子" or "hammer",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "锤子的最大地面保留数量(组)" or "the maximum amount of the hammer"
    },
    {
        name = "shovel",
        label = Ch and "铲子" or "shovel",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "铲子的最大地面保留数量(组)" or "the maximum amount of the shovel"
    },
    {
        name = "razor",
        label = Ch and "剃刀" or "razor",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "剃刀的最大地面保留数量(组)" or "the maximum amount of the razor"
    },
    {
        name = "pitchfork",
        label = Ch and "干草叉" or "pitchfork",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "干草叉的最大地面保留数量(组)" or "the maximum amount of the pitchfork"
    },
    {
        name = "bugnet",
        label = Ch and "捕虫网" or "bugnet",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "捕虫网的最大地面保留数量(组)" or "the maximum amount of the bugnet"
    },
    {
        name = "fishingrod",
        label = Ch and "鱼竿" or "fishingrod",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "鱼竿的最大地面保留数量(组)" or "the maximum amount of the fishingrod"
    },
    {
        name = "spear",
        label = Ch and "长矛" or "spear",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "长矛的最大地面保留数量(组)" or "the maximum amount of the spear"
    },
    {
        name = "earmuffshat",
        label = Ch and "兔耳罩" or "earmuffshat",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "兔耳罩的最大地面保留数量(组)" or "the maximum amount of the earmuffshat"
    },
    {
        name = "winterhat",
        label = Ch and "冬帽" or "winterhat",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "冬帽的最大地面保留数量(组)" or "the maximum amount of the winterhat"
    },
    {
        name = "heatrock",
        label = Ch and "暖石" or "heatrock",
        options = cleanunitx10_2,
        default = 10,	
        hover = Ch and "暖石的最大地面保留数量(组)" or "the maximum amount of the heatrock"
    },
    {
        name = "trap",
        label = Ch and "动物陷阱" or "trap",
        options = cleanunitx60_10,
        default = 30,	
        hover = Ch and "动物陷阱的最大地面保留数量(组)" or "the maximum amount of the trap"
    },
    {
        name = "birdtrap",
        label = Ch and "鸟陷阱" or "birdtrap",
        options = cleanunitx60_10,
        default = 10,	
        hover = Ch and "鸟陷阱的最大地面保留数量(组)" or "the maximum amount of the birdtrap"
    },
    {
        name = "compass",
        label = Ch and "指南针" or "compass",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "指南针的最大地面保留数量(组)" or "the maximum amount of the compass"
    },
    {
        name = "driftwood_log",
        label = Ch and "浮木" or "driftwood_log",
        options = cleanunitx200_20,
        default = 100,	
        hover = Ch and "浮木的最大地面保留数量(组)" or "the maximum amount of the driftwood_log"
    },
    {
        name = "spoiled_fish",
        label = Ch and "变质鱼/小鱼" or "spoiled_fish/small",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "变质鱼/小鱼的最大地面保留数量(组)" or "the maximum amount of the spoiled_fish/small"
    },
    {
        name = "rottenegg",
        label = Ch and "臭鸡蛋" or "rottenegg",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "臭鸡蛋的最大地面保留数量(组)" or "the maximum amount of the rottenegg"
    },
    {
        name = "feather",
        label = Ch and "羽毛/啜食兽皮" or "feather/slurper_pelt",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "羽毛/啜食兽皮的最大地面保留数量(组)" or "the maximum amount of the feather/slurper_pelt"
    },
    {
        name = "pocket_scale",
        label = Ch and "弹簧秤" or "pocket_scale",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "弹簧秤的最大地面保留数量(组)" or "the maximum amount of the pocket_scale"
    },
    {
        name = "oceanfishingrod",
        label = Ch and "海钓竿" or "oceanfishingrod",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "海钓竿的最大地面保留数量(组)" or "the maximum amount of the oceanfishingrod"
    },
    {
        name = "sketch",
        label = Ch and "草图" or "sketch",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "所有草图的最大地面保留数量(组)" or "the maximum amount of all the sketch"
    },
    {
        name = "tacklesketch",
        label = Ch and "广告" or "tacklesketch",
        options = cleanunitx10_2,
        default = 2,	
        hover = Ch and "所有钓具草图的最大地面保留数量(组)" or "the maximum amount of all the tacklesketch"
    }
}