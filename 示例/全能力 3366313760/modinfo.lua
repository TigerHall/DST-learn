local L = locale ~= "zh" and locale ~= "zhr" -- true 英文  false 中文

name = L and "All-Powerful" or "全能力"
description = [[
1.0.42改动：
1. 修复雪球发射器定位能力报错的问题
]]
author = "绯世行"
version = "1.0.47"

forumthread = ""

api_version = 10

priority = 0

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
    "character",
}

local ON = { description = L and "On" or "开", data = true }
local OFF = { description = L and "Off" or "关", data = false }
function SWITCH()
    return { ON, OFF }
end

local ALPHA = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
    "U", "V", "W", "X", "Y", "Z" }
---生成快捷键选项表
function KEYSLIST(closable, right_mouse)
    local list = {}
    if closable then
        list[#list + 1] = OFF
    end
    if right_mouse then
        list[#list + 1] = { description = L and "Mouse right" or "鼠标右键", data = "RIGHT" }
    end

    for i = 1, #ALPHA do
        list[#list + 1] = { description = ALPHA[i], data = ALPHA[i] }
    end
    return list
end

local EPSILON = 1e-10

local function IsEqual(a, b)
    if a == b then
        return true
    end
    if a == true or a == false or b == true or b == false then
        return false
    end
    return (a > b and (a - b) or (b - a)) < EPSILON
end

---生成数字选择表
---@param tab any 可选数字
---@param default any 默认值
---@param closable any 是否含有关闭选项
function NUMLIST(tab, default, closable, scale, prefix)
    scale = scale or 1
    prefix = prefix or ""
    local list = {}
    if closable then
        list[#list + 1] = { description = L and "Default" or "默认", data = false }
    end
    for i = 1, #tab do
        local val = tab[i]
        list[#list + 1] = { description = prefix .. (val * scale) .. (IsEqual(val, default) and "-default" or ""), data = tab[i] }
    end
    return list
end

local function TITLE(label)
    return { name = "", label = label, hover = "", options = { { description = "", data = false }, }, default = false }
end

--- gap是小数可能有误差，科雷又是用等号判断的，导致上下滑动对不上选项，有些值可以有些值会跳动
local function NUM_RANGE(...)
    local list = {}
    local count = 0
    local args = { ... }
    local group = 1
    while group < #args do
        local min, max, gap = args[group], args[group + 1], args[group + 2]
        gap = gap or 1
        for val = min, max, gap do
            count = count + 1
            list[count] = val
        end
        group = group + 3
    end
    return list
end

local function PERCENTAGE_LIST(min, max, gap, default)
    gap = gap or 1
    local list = {}
    local count = 0

    if default then
        count = count + 1
        list[count] = { description = "默认", data = false }
    end

    for val = min, max, gap do
        count = count + 1
        list[count] = { description = val .. "%", data = val }
    end
    return list
end

configuration_options = {
    {
        name = "language",
        label = L and "Language" or "语言",
        hover = L and "Set language of this mod." or "设置语言。",
        options = {
            { description = L and "Auto" or "自动", data = "AUTO" },
            { description = "English", data = "en" },
            { description = "中文", data = "zh" },
        },
        default = "AUTO",
    },
    {
        name = "aab_extend_tags",
        label = L and "Tag Extension" or "标签扩展",
        hover = L and "Prevent mod tag overflow to avoid crashes." or "如果你的mod标签加的多了或者功能开启的多了可能会导致标签溢出，进而导致崩溃，启用扩展可以避免这种崩溃。",
        options = SWITCH(),
        default = true,
    },
    {
        name = "crash_prevention",
        label = L and "Crash Prevention" or "崩溃预防",
        hover = L and
            "Prevent common crash issues and fix game bugs, such as common event push no data, object invalid interrupt event callback, object invalid disable delay task, etc." or
            "预防常见崩溃问题和修复游戏的bug，例如常见事件推送无data、对象无效中断事件回调、对象无效禁止延迟任务等。",
        options = SWITCH(),
        default = true,
    },
    {
        name = "error_tip",
        label = L and "Error Tracing" or "错误追踪",
        hover = L and "Displays the mod that directly caused the crash at the time of the crash, and outputs some logs." or "在崩溃的时候显示直接导致崩溃的mod，并输出部分日志。",
        options = SWITCH(),
        default = false,
    },

    TITLE(L and "Player" or "玩家"),
    {
        name = "health_max",
        label = L and "Max Health" or "玩家血量上限",
        hover = L and "Lock the upper limit, which does not get bigger or smaller for other reasons." or "锁定上限，不会因为其他原因而变大或变小。",
        options = NUMLIST(NUM_RANGE(75, 300, 25, 350, 1000, 50, 1100, 10000, 100), false, true),
        default = false,
    },
    {
        name = "sanity_max",
        label = L and "Max Sanity" or "玩家理智上限",
        hover = L and "Lock the upper limit, which does not get bigger or smaller for other reasons." or "锁定上限，不会因为其他原因而变大或变小。",
        options = NUMLIST(NUM_RANGE(75, 300, 25, 350, 1000, 50, 1100, 10000, 100), false, true),
        default = false,
    },
    {
        name = "hunger_max",
        label = L and "Max Hunger" or "玩家饱食度上限",
        hover = L and "Lock the upper limit, which does not get bigger or smaller for other reasons." or "锁定上限，不会因为其他原因而变大或变小。",
        options = NUMLIST(NUM_RANGE(75, 300, 25, 350, 1000, 50, 1100, 10000, 100), false, true),
        default = false,
    },
    {
        name = "attack_mult",
        label = L and "Attack Multiplier" or "玩家攻击倍率",
        options = NUMLIST(NUM_RANGE(50, 500, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "attack_taken_mult",
        label = L and "Hit multiplier" or "玩家受击倍率",
        hover = L and "The smaller the value, the lower the attack damage" or "值越小受到的攻击伤害越低",
        options = NUMLIST(NUM_RANGE(0, 300, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "speed_mult",
        label = L and "Speed multiplier" or "玩家移速倍率",
        options = NUMLIST(NUM_RANGE(50, 300, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "attack_heal",
        label = L and "Attack Heal" or "玩家攻击吸血",
        hover = L and "Healing as a percentage of damage dealt" or "回血量为造成伤害的百分比，同伤害下值越大回血越多。",
        options = PERCENTAGE_LIST(2, 100, 2, true),
        default = false,
    },
    {
        name = "health_regen",
        label = L and "Health Rege" or "玩家每秒回血",
        options = NUMLIST(NUM_RANGE(20, 1000, 20), false, true, 0.01),
        default = false,
    },
    {
        name = "hunger_mult",
        label = L and "Hunger Multiplier" or "玩家饥饿倍率",
        options = NUMLIST(NUM_RANGE(20, 300, 20), false, true, 0.01),
        default = false,
    },
    {
        name = "work_mult",
        label = L and "Work Multiplier" or "玩家工作倍率",
        options = NUMLIST(NUM_RANGE(50, 1000, 50), false, true, 0.01),
        default = false,
    },
    {
        name = "food_mult",
        label = L and "Cooking Yield" or "料理收益倍率",
        options = NUMLIST(NUM_RANGE(40, 500, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "not_cold_and_hot",
        label = L and "No Temperature Extremes" or "不会过冷过热",
        hover = L and "Does not affect temporary temperature changes from skills" or "不会改变技能产生的临时温度，比如克劳斯的技能。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "keep_ondeath",
        label = L and "Keep Items on Death" or "死亡物品不掉落",
        options = SWITCH(),
        default = false,
    },
    {
        name = "push_oceantreenut",
        label = L and "Push Knobbly Tree Nut" or "手推疙瘩树果",
        hover = L and "Right-click to push nuts into water" or "玩家可以左键地面的疙瘩树果，将其一点一点推入水中。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "not_drop",
        label = L and "Walk on Water" or "踏水",
        hover = L and "Options: Default, Consume Hunger, No Consumption" or "可以在水上行走而不掉下去。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Consume Hunger" or "消耗饱食度", data = 1 },
            { description = L and "No Consumption" or "无消耗", data = 2 },
        },
        default = false,
    },
    {
        name = "fast_doaction",
        label = L and "Fast Crafting" or "快速动作",
        hover = L and "Collection and production speed is faster." or "采集、制作速度更快。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "haunt_respawn",
        label = L and "Haunted Respawn" or "作祟复活",
        hover = L and "Players can be resurrected by haunting the skeleton or snitching heart." or "玩家可以通过作祟骨架或者告密的心来复活。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "recipe_derate_mult",
        label = L and "Recipe Discount" or "配方制作减免",
        hover = L and "Built-in permanent crafting reduction effect from the beginning." or "初始就自带的永久制作减免效果。",
        options = NUMLIST({ 0.25, 0.5, 0.75 }, false, true),
        default = false,
    },
    {
        name = "quick_build",
        label = L and "Quick Build" or "便捷制作",
        hover = L and "The recipe shows the materials required clearly, and you can use the materials in the box to make it." or "配方制作材料高亮，并且可以消耗箱子里的材料来制作。",
        options = NUMLIST({ 6, 8, 10, 12, 14, 16, 18, 20 }, false, true, nil, L and "Range: " or "范围："),
        default = false,
    },
    {
        name = "init_tech",
        label = L and "Initial Tech Level" or "初始科技",
        hover = L and "Higher values grant more starting tech" or "值越大，玩家自带的科技越高，并且包括前面选项包含的科技。",
        options = {
            { description = L and "Default" or "默认", data = 0 },
            { description = L and "Tech Level 1" or "初始一本", data = 1 },
            { description = L and "Tech Level 2" or "初始二本", data = 2 },
            { description = L and "Tech Level 3" or "初始三本", data = 3 },
            { description = L and "Tech Level 4" or "初始四本", data = 4 },
        },
        default = 0,
    },
    {
        name = "splash_damage",
        label = L and "Area Attack" or "范围攻击",
        hover = L and "Player attacks cause AOE damage to nearby units of the same type." or "玩家攻击时造成AOE伤害，不过只有附近同样的单位会受到伤害。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Nearby units take 0.3x damage" or "附近单位受到0.3倍的伤害", data = 0.3 },
            { description = L and "Nearby units take 0.5x damage" or "附近单位受到0.5倍的伤害", data = 0.5 },
            { description = L and "Nearby units take 0.75x damage" or "附近单位受到0.75倍的伤害", data = 0.75 },
            { description = L and "Nearby units take 1x damage" or "附近单位受到1倍的伤害", data = 1 },
        },
        default = false,
    },
    {
        name = "move_fx",
        label = L and "Motion effect" or "移动特效",
        hover = L and "Play some effects when the player moves, just beautiful." or "玩家移动时播放一些特效，仅美观。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Rose" or "玫瑰红", data = "cane_rose_fx" },
            { description = L and "Victorian" or "山羊头", data = "cane_victorian_fx" },
            { description = L and "Harlequin" or "愚人", data = "cane_harlequin_fx" },
            { description = L and "Ancient" or "远古", data = "cane_ancient_fx" },
            { description = L and "Candy Cane" or "拐杖糖", data = "cane_candy_fx" },
            { description = L and "Little grass" or "小花小草", data = "grass" },
        },
        default = false,
    },

    ----------------------------------------------------------------------------------------------------

    TITLE(L and "Ability" or "能力"),
    {
        name = "wilson_recipes",
        label = L and "Wilson Recipes" or "威尔逊配方",
        hover = L and "Default unlocks Wilson-related recipes, including skill tree related recipes." or "默认解锁威尔逊相关配方，包括技能树相关配方。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "heavy_not_slowdown",
        label = L and "No Slowdown When Heavy" or "背重物不减速",
        options = SWITCH(),
        default = false,
    },
    {
        name = "aab_might_slow_mult",
        label = L and "Wolfgang's power drop multiplier" or "力量下降倍率",
        hover = L and "Slow down the rate at which Wolfgang's strength drops." or "减慢沃尔夫冈力量值的下降速度。",
        options = NUMLIST(NUM_RANGE(0, 90, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "willow_bernie",
        label = L and "Willow Bernie" or "薇洛的伯尼",
        hover = L and "Player can craft and use Bernie." or "玩家可以制作和使用伯尼。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "willow_lighter",
        label = L and "Willow Lighter" or "薇洛技能",
        hover = L and "Player unlocks Willow lighter recipe and can collect embers and use skills." or "玩家解锁薇洛打火机配方，并且可以收集余烬和使用技能。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wormwood_recipes",
        label = L and "Wormwood Recipes and Farming" or "沃姆伍德能力",
        hover = L and "Unlocks Wormwood-related recipes and the ability to plant anywhere." or "解锁沃姆伍德相关配方并解锁随手种地的能力。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wendy_recipes",
        label = L and "Wendy Abilities" or "温蒂能力",
        hover = L and "Default unlocks Wendy-related recipes and the player can summon Abigail." or "解锁温蒂相关配方并且玩家可以召唤阿比盖尔。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "spawn_ghostflower",
        label = L and "Spawn Mourning Glory" or "骨灰罐生成哀悼荣耀",
        hover = L and "The Sisturn generates some Mourning Glory every day." or "姐妹骨灰罐每天早上会生成一些哀悼荣耀。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wx78_recipes",
        label = L and "WX-78 Abilities" or "WX-78能力",
        hover = L and "Default unlocks WX-78-related recipes and the player can assemble circuits." or "解锁WX-78相关配方并且玩家可以装配电路。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "waxwell_recipes",
        label = L and "Maxwell Abilities" or "麦斯威尔能力",
        hover = L and "Default unlocks Maxwell-related recipes and the player can use the Shadow Grimoire." or "解锁麦斯威尔的相关配方并且玩家可以使用暗影秘典。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "waxwelljournal_consume",
        label = L and "Shadow Grimoire Consumption" or "暗影秘典消耗",
        hover = L and "Using the Shadow Grimoire no longer deducts sanity cap and does not limit the number of summoned followers." or "使用暗影秘典不再扣除理智上限，并且不再限时随从召唤的数量。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Consume Sanity" or "消耗理智", data = 1 },
            { description = L and "Consume Hunger" or "消耗饱食度", data = 2 },
        },
        default = false,
    },
    {
        name = "waxwell_shadow_num",
        label = L and "Shadow Grimoire Minions" or "暗影秘典仆从数量",
        hover = L and "Number of Shadow Gladiators or Shadow Servants generated each time the book is read." or "提高每次召唤的仆从数量。",
        options = NUMLIST({ 2, 3, 4, 5, 6 }, false, true),
        default = false,
    },
    {
        name = "wathgrithr_recipes",
        label = L and "Wigfrid Abilities" or "薇格弗德能力",
        hover = L and "Default unlocks Wigfrid-related recipes and the player can use her exclusive equipment and battle song." or "默认解锁薇格弗德相关配方并且玩家可以使用其专属装备和战歌。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "winona_recipes",
        label = L and "Winona Abilities" or "薇诺娜能力",
        hover = L and "Default unlocks Winona-related recipes and the player can use her exclusive equipment." or "默认解锁薇诺娜相关配方并且玩家可以使用其专属装备。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "winona_look",
        label = L and "Winona Inspect" or "薇诺娜仔细检查",
        hover = L and "You can scrutinize wormholes and tentacle holes and jump directly from wormhole to wormhole." or "可以仔细检查虫洞和触手洞，直接进行虫洞间跳跃。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "walter_recipes",
        label = L and "Walter Recipes" or "沃尔特能力",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wanda_recipes",
        label = L and "Wanda Recipes" or "旺达配方",
        hover = L and "Default unlocks Wanda-related recipes and the player can use her exclusive equipment." or "默认解锁旺达相关配方并且玩家可以使用其专属装备。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wickerbottom_recipes",
        label = L and "Wickerbottom Books" or "薇克巴顿书籍",
        hover = L and "Player unlocks Wickerbottom-related recipes and can read books." or "玩家解锁薇克巴顿相关配方并且可以读书。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "warly_recipes",
        label = L and "Warly Recipes" or "沃利配方",
        hover = L and "Default unlocks Warly-related recipes and the player can use his exclusive equipment." or "默认解锁沃利相关配方并且玩家可以使用其专属装备。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "eat_unlimited",
        label = L and "Unlimited Eat" or "进食无限制",
        hover = L and "Characters such as Valkyries, Fish men, and cooks no longer restrict what they can eat." or "女武神、小鱼人、厨师等角色不再限制可以吃的食物。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wortox_blink",
        label = L and "Wortox Blink" or "沃拓克斯能力",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wurt_recipes",
        label = L and "Wurt Ability" or "沃特能力",
        hover = L and "Unlock the relevant formula of Walt, and the Fishman will not actively attack the player, the player can also call on their own Fishman army." or
            "解锁沃特的相关配方，并且鱼人不会主动攻击玩家，玩家也能号召自己的鱼人大军。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "merm_dont_starve",
        label = L and "Merm king Don't starve to death" or "鱼人王不会饿死",
        options = SWITCH(),
        default = false,
    },
    {
        name = "super_luck",
        label = L and "Lucy axe reinforcement" or "露西斧强化",
        hover = L and "It can be chiseled and dug, and the efficiency is 2" or "可以凿、挖，并且效率都为2。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "wes_recipes",
        label = L and "Wes's balloon" or "韦斯气球",
        hover = L and "We can make Wes's balloons." or "可以制作韦斯的气球。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "jumping_dodge_key",
        label = L and "Jumping dodge" or "跳跃闪避",
        hover = L and "Players can right-click the ground to jump, during the jump invincible." or "玩家可以右键地面进行跳跃，跳跃期间无敌。",
        options = KEYSLIST(true, true),
        default = false,
    },
    {
        name = "roll_dodge_key",
        label = L and "Roll dodge" or "滑铲闪避",
        hover = L and "The player can right-click the ground to slide the shovel, during the sliding shovel invincible." or "玩家可以右键地面或按下快捷键进行滑铲，滑铲期间无敌。",
        options = KEYSLIST(true, true),
        default = false,
    },
    {
        name = "time_stop",
        label = L and "Time Stop key" or "时停",
        hover = L and
            "When the player presses the shortcut key to trigger the time stop, the surrounding creatures will stop for a period of time, lasting 8 seconds, and the skills will cool down for 60 seconds" or
            "玩家按下快捷键触发时间停止，周围的生物都会停止动作一段时间，持续8秒，技能冷却60秒",
        options = KEYSLIST(true),
        default = false,
    },
    {
        name = "pick_minion",
        label = L and "Pick minion" or "采集分身",
        hover = L and "Players can right right-click can be collected, cut, dig, chisel buildings, consume satiety summoned the corresponding doppelganger to work." or
            "玩家可以右键可采集、砍伐、挖、凿、拾取物品和建造，消耗饱食度召唤对应的分身进行工作。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "attack_spawn_tentacle",
        label = L and "Attack summons Shadow Tentacles" or "攻击召唤暗影触手",
        hover = L and "With its own thulium rod function, each attack has the probability to summon a shadow tentacle around the enemy to assist in combat." or
            "自带铥矿棒效果，每次攻击有概率在敌人周围召唤一个暗影触手辅助战斗。",
        options = PERCENTAGE_LIST(10, 100, 10, true),
        default = false,
    },
    {
        name = "attack_spawn_gestalt",
        label = L and "Attack summons gestalt" or "攻击召唤启迪虚影",
        hover = L and "Comes with the effect of the Crown of Enlightenment, generating small shadows to assist in attacks with each hit." or
            "自带启迪之冠效果，每次攻击在附近生成小虚影辅助攻击。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "chain_arrow_burst",
        label = L and "Burst Arrows key" or "爆裂箭矢快捷键",
        hover = L and
            "Attack enemies to generate arrows that fly towards them and stick upon hitting. Press a hotkey to detonate the arrows. If the targeted enemy dies, all arrows fly towards nearby enemies." or
            "攻击敌人会在周围生成飞箭飞向敌人，命中后留在敌人身上，玩家按下快捷键后可引爆飞箭，如果命中的单位死亡，所有的飞箭会飞向附近的其他敌人。",
        options = KEYSLIST(true),
        default = false,
    },
    {
        name = "damage_share",
        label = L and "Damage Sharing" or "伤害分担",
        hover = L and "The player's damage is partially transferred to the follower. Higher values mean more damage is absorbed by the follower." or
            "玩家受到的伤害会有一部分转移到随从身上，由随从承担一部分伤害，值越大随从分担的伤害越多。",
        options = PERCENTAGE_LIST(10, 100, 10, true),
        default = false,
    },
    {
        name = "my_pig",
        label = L and "Pigman friend" or "猪人朋友",
        hover = L and
            "The player is born with a gold belt, you can right-click the gold belt to summon and recall the pig man, the pig man permanently follow, and strengthen with the days." or
            "玩家出生自带一个金腰带，可以右键金腰带召唤和召回猪人，猪人永久跟随，并且随天数强化。",
        options = SWITCH(),
        default = false,
    },


    ----------------------------------------------------------------------------------------------------
    TITLE(L and "Attack" or "战斗"),

    {
        name = "attack_speed",
        label = L and "Weapon Speed Up" or "武器攻击速度",
        hover = L and "Upgrade weapon attack speed with gold nuggets." or "可用金块右键武器升级武器的攻击速度。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "body_finiteuses_mult",
        label = L and "Armor Durability" or "护甲头盔耐久消耗倍率",
        options = NUMLIST(NUM_RANGE(0, 300, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "weapon_finiteuses_mult",
        label = L and "Weapon Durability" or "武器耐久消耗倍率",
        options = NUMLIST(NUM_RANGE(0, 300, 10), false, true, 0.01),
        default = false,
    },
    {
        name = "infinite_amulet",
        label = L and "Amulet infinitely durable" or "护符无限耐久",
        options = SWITCH(),
        default = false,
    },
    {
        name = "finiteuses_heal",
        label = L and "Slow Durability Recovery" or "装备缓慢回复耐久",
        options = SWITCH(),
        default = false,
    },
    {
        name = "follow_time_mult",
        label = L and "Follower Time Multiplier" or "随从雇佣时长倍率",
        hover = L and "Higher values mean longer hire durations." or "值越大，雇佣的时长越多。",
        options = NUMLIST(NUM_RANGE(125, 500, 25), false, true, 0.01),
        default = false,
    },
    {
        name = "followme",
        label = L and "Follower follow player" or "随从上下洞穴跟随",
        hover = L and "Players go up and down caves with their minions." or "玩家上下洞穴的时候随从也跟着上下洞穴。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "follower_attack_shadowcreature",
        label = L and "Minions can attack shadow creature" or "随从可以攻击影怪",
        hover = L and "Creatures hired by the player can attack shadow creature." or "被玩家雇佣的生物可以攻击影怪。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "auto_fill",
        label = L and "Auto Refill" or "自动填充弹药补充燃料",
        hover = L and "Automatically refill ammo and fuel for certain items." or "没燃料的时候会从物品栏里找，适用于暗影秘典、弹弓、嚎弹炮",
        options = SWITCH(),
        default = false,
    },
    {
        name = "super_trap",
        label = L and "Super Trap" or "陷阱强化",
        hover = L and "Enhancements for Houndtooth traps and thorn traps, features include all-user manufacturability, automatic reset, and unlimited durability." or
            "针对犬牙陷阱和荆棘陷阱的强化，功能包括所有人可制造、自动重置、无限耐久。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Can build Bramble Trap" or "可以制作荆棘陷阱", data = 1 },
            { description = L and "Build + Reset" or "制作+重置", data = 2 },
            { description = L and "Build + Unlimited" or "制作+无限耐久", data = 3 },
            { description = L and "Build+Reset+Unlimited" or "制作+重置+无限耐久", data = 4 },
        },
        default = false,
    },

    ----------------------------------------------------------------------------------------------------

    TITLE(L and "Creature" or "生物"),

    {
        name = "monkey_weak",
        label = L and "Monkey Buff/Debuff" or "猴子削弱",
        hover = L and "Weaken or strengthen monkeys." or "削弱猴子，或者加强它们",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Heavily Weakened" or "大大的削弱", data = 1 },
            { description = L and "Weakened" or "削弱", data = 2 },
            { description = L and "Strengthened" or "加强它们", data = 3 },
            { description = L and "Super Strengthened" or "超级强化", data = 4 },
        },
        default = false,
    },
    {
        name = "pigman_maxhealth",
        label = L and "Pigman Max Health" or "猪人血量上限",
        hover = L and "Don't ask me why I can adjust the pig's health limit." or "不要问我为什么可以调整猪人的血量上限。",
        options = NUMLIST(NUM_RANGE(300, 500, 50, 600, 5000, 100), false, true),
        default = false,
    },
    {
        name = "tallbird_not_attack",
        label = L and "Tallbird do not attack players." or "高脚鸟不攻击玩家",
        hover = L and "The Highbird will not actively attack the player." or "高脚鸟不会主动攻击玩家。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "catch_rabbit",
        label = L and "Catch Rabbit" or "抓兔子",
        hover = L and "The player can build a rabbit nest in the crafting bar, and can directly right-click the rabbit nest to catch the rabbit out." or
            "玩家可以在制作栏建造兔子窝，可以直接右键兔子窝把兔子抓手里。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "pigking_accept_stacks",
        label = L and "Pigking whole group give" or "猪王整组给予",
        hover = L and "Players can directly give one set of items at a time each time they trade with PigKing." or "玩家每次同猪王交易时可以一次直接给予一组物品。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "birdcage_not_death",
        label = L and "Birdcage birds don't starve to death" or "鸟笼的鸟不会饿死",
        hover = L and "Birdcage birds don't starve to death" or "鸟笼里的鸟不会饿死。",
        options = SWITCH(),
        default = false,
    },

    ----------------------------------------------------------------------------------------------------
    TITLE(L and "Container modification" or "容器修改"),
    {
        name = "max_item_slots",
        label = L and "Playe max item slots" or "玩家物品栏槽上限",
        hover = L and "Set a maximum number of tiles in the player's inventory." or "设置玩家物品栏的格子数量上限。",
        options = NUMLIST({ 35, 55 }, false, true),
        default = false,
    },
    {
        name = "backpack_item",
        label = L and "Backpack in Inventory" or "背包可放入物品栏",
        hover = L and "Put backpacks in your inventory instead of just equipping or dropping them." or "可以把背包放入物品栏，而不是只能装备和掉在地上。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "backpack_init_upgrade",
        label = L and "Backpack Infinite Stack" or "背包无限堆叠",
        hover = L and "Items in backpacks can stack infinitely." or "背包内的物品可以无限堆叠。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "backpack_container",
        label = L and "Pack Capacity" or "背包容量",
        hover = L and "Increase the capacity of backpack and fresh-keeping backpack capacity." or "提高背包和保鲜背包容量的容量。",
        options = NUMLIST({ 16, 18, 21, 24, 27 }, false, true),
        default = false,
    },
    {
        name = "backpack_armor",
        label = L and "Backpack Add Armor" or "背包添加防御",
        hover = L and "Adds defense values to all packs." or "给所有背包添加防御值。",
        options = PERCENTAGE_LIST(10, 100, 10, true),
        default = false,
    },
    {
        name = "bundlewrap_container",
        label = L and "Bundle Capacity" or "捆绑包装容量",
        hover = L and "Increase the capacity of bundle wraps." or "提高捆绑包裹的容量。",
        options = NUMLIST({ 9, 16, 25 }, false, true),
        default = false,
    },
    {
        name = "chest_item",
        label = L and "Chest in Inventory" or "箱子可放入物品栏",
        hover = L and "Pick up chests by right-clicking and put them in your inventory." or "可以右键收回箱子，把箱子放入物品栏。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "chest_init_upgrade",
        label = L and "Chest Infinite Stack" or "箱子物品无限堆叠",
        hover = L and "Chests start with upgraded effects without manual upgrades." or "箱子初始就是升级后的效果，不需要手动升级。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Wooden and Dragon Chests" or "木箱和龙鳞箱生效", data = 1 },
            { description = L and "All Chests" or "所有箱子生效", data = 2 },
        },
        default = false,
    },
    {
        name = "treasurechest_container",
        label = L and "Wooden Chest Capacity" or "木箱容量",
        hover = L and "Increase the capacity of wooden chests." or "提高木箱的容量。",
        options = NUMLIST({ 16, 25, 36, 49, 64 }, false, true),
        default = false,
    },
    {
        name = "icebox_freshness",
        label = L and "Fridge Freshness" or "冰箱保鲜",
        hover = L and "Set the spoilage rate of food in the fridge." or "设置冰箱内食物的腐烂速度",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Spoilage Rate 25%" or "腐烂倍率25%", data = 0.25 },
            { description = L and "Spoilage Rate 20%" or "腐烂倍率20%", data = 0.2 },
            { description = L and "Spoilage Rate 15%" or "腐烂倍率15%", data = 0.15 },
            { description = L and "Spoilage Rate 10%" or "腐烂倍率10%", data = 0.1 },
            { description = L and "Spoilage Rate 5%" or "腐烂倍率5%", data = 0.05 },
            { description = L and "Pause decay" or "暂停腐烂", data = 0 },
            { description = L and "Freshness Rate 5%" or "返鲜倍率5%", data = -0.05 },
            { description = L and "Freshness Rate 10%" or "返鲜倍率10%", data = -0.1 },
            { description = L and "Freshness Rate 15%" or "返鲜倍率15%", data = -0.15 },
            { description = L and "Freshness Rate 20%" or "返鲜倍率20%", data = -0.2 },
        },
        default = false,
    },
    {
        name = "icebox_container",
        label = L and "Fridge Capacity" or "冰箱盐盒容量",
        hover = L and "Increase the capacity of fridges." or "提高冰箱和盐盒的容量。",
        options = NUMLIST({ 16, 25, 36, 49, 64 }, false, true),
        default = false,
    },
    {
        name = "container_no_test",
        label = L and "Containers are not limited to items" or "容器放入物品不限制",
        hover = L and "There are no restrictions on the contents of containers such as refrigerators, salt boxes, and polar bear badger buckets." or "冰箱、盐盒、极地熊獾桶等容器里的物品不受限制，装什么都可以。",
        options = {
            { description = L and "Default" or "默认", data = false },
            { description = L and "Icebox salt box items are not limited" or "冰箱盐盒物品不限制", data = 1 },
            { description = L and "Common container items are not limited" or "常见容器物品不限制", data = 2 },
        },
        default = false,
    },
    {
        name = "container_auto_pickup",
        label = L and "Automatic box collection" or "箱子自动拾取",
        hover = L and "Use the right Nugget button to turn on or off the collection mode, which automatically collects nearby items similar to those in the box." or
            "使用金块右键箱子开启或关闭收集模式，收集模式下自动收集附近和箱子里一样的物品。",
        options = NUMLIST({ 8, 12, 16, 25, 36 }, false, true, nil, L and "Range: " or "范围："),
        default = false,
    },

    ----------------------------------------------------------------------------------------------------
    TITLE(L and "New item" or "新增物品"),
    {
        name = "powerful_sword",
        label = L and "Powerful Sword" or "尚方宝剑",
        hover = L and
            "Players can craft weapons such as the Great Sword, which can slash, gouge, dig, hammer, and has the ability to right-click block." or
            "玩家可以制作武器大剑，大剑可以砍、凿、挖、锤，并且带有右键格挡技能。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "item_duplicator",
        label = L and "Item duplicator" or "物品复制机",
        hover = L and
            "Players can build item replicators in the Crafting bar, come with a container, and copy the items in the container every two days, only can copy the items that can be stacked." or
            "玩家可在制作栏建造物品复制机，自带一个容器，每隔一天复制一份容器里的物品，只能复制可以堆叠的物品。",
        options = {
            { description = L and "Off" or "关", data = false },
            { description = L and "Maximum 1" or "上限1个", data = 1 },
            { description = L and "Maximum 2" or "上限2个", data = 2 },
            { description = L and "Maximum 3" or "上限3个", data = 3 },
            { description = L and "Maximum 4" or "上限4个", data = 4 },
            { description = L and "Maximum 5" or "上限5个", data = 5 },
            { description = L and "Maximum 6" or "上限6个", data = 6 },
            { description = L and "Maximum 7" or "上限7个", data = 7 },
            { description = L and "Maximum 8" or "上限8个", data = 8 },
            { description = L and "No limit" or "无限制", data = -1 },
        },
        default = false,
    },
    {
        name = "trusty_shooter",
        label = L and "Pew-matic Horn" or "气枪喇叭",
        hover = L and "Can make air gun horn, can put most items, high frequency firing and special items have special effects." or
            "可以制作气枪喇叭，可放入大部分物品，高频发射并且特殊物品拥有特殊效果。",
        options = SWITCH(),
        default = false,
    },

    ----------------------------------------------------------------------------------------------------
    TITLE(L and "Other" or "其他"),
    {
        name = "stack_max",
        label = L and "Stack Max" or "堆叠上限",
        hover = L and "Set the stack limit for stackable items." or "设置可堆叠的物品的堆叠上限。",
        options = NUMLIST({ 99, 999 }, false, true),
        default = false,
    },
    {
        name = "drop_stack",
        label = L and "Drop Stacking" or "掉落堆叠",
        hover = L and "Items dropped on the ground automatically stack within a set range." or "物品掉在地上自动堆叠，设置堆叠触发的范围。",
        options = {
            { description = L and "Off" or "关", data = false },
            { description = L and "Range 4" or "范围4", data = 4 },
            { description = L and "Range 6" or "范围6", data = 6 },
            { description = L and "Range 8" or "范围8", data = 8 },
            { description = L and "Range 10" or "范围10", data = 10 },
            { description = L and "Range 12" or "范围12", data = 12 },
            { description = L and "Range 14" or "范围14", data = 14 },
            { description = L and "Range 16" or "范围16", data = 16 },
            { description = L and "Range 18" or "范围18", data = 18 },
            { description = L and "Range 20" or "范围20", data = 20 },
        },
        default = false,
    },
    {
        name = "super_bundlewrap",
        label = L and "Universal Wrap" or "万物打包纸",
        hover = L and "Wrap all buildings with a bundle wrap, use on buildings with left-click." or "捆绑包装可以打包所有建筑，手持左键对建筑使用。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "dragonflyfurnace_decompose",
        label = L and "Dragonfly Furnace Decompose" or "龙鳞火炉分解",
        hover = L and "When 'destroyed', the furnace will attempt to decompose items inside first." or "龙鳞火炉的“摧毁”会对里面的物品先尝试一次分解，类似拆解法杖一样。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "ent_drop_mult",
        label = L and "Drop Rate Multiplier" or "掉落物掉落倍率",
        hover = L and "Increase loot drops from defeated enemies." or "杀死单位后多掉点。",
        options = NUMLIST({ 2, 3, 4, 5 }, false, true),
        default = false,
    },
    {
        name = "pick_drop_mult",
        label = L and "Harvest Rate Multiplier" or "采集收获倍率",
        hover = L and "Get extra items when harvesting and picking." or "采集和收获时获得额外数量物品。",
        options = NUMLIST({ 2, 3, 4, 5 }, false, true),
        default = false,
    },
    {
        name = "pot_and_rack_mult",
        label = L and "Cooking pot and drying rack Harvest Rate Multiplier" or "烹饪锅和晾肉架收获倍率",
        hover = L and "Get extra items when harvesting and picking." or "收获时获得额外数量物品。",
        options = NUMLIST({ 2, 3, 4, 5 }, false, true),
        default = false,
    },
    {
        name = "super_multitool_axe_pickaxe",
        label = L and "Multi-Tool Axe Pickaxe" or "全能多用斧镐",
        hover = L and "Support hammer and shovel functions." or "多用斧镐支持锤子、铲子功能。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "force_oversized",
        label = L and "Crop Giantization" or "作物100%巨大化",
        hover = L and "Crops always grow to giant size upon maturity." or "只要成熟，就是巨大化！。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "super_dock_kit",
        label = L and "Dock Kit Enhancement" or "码头套装强化",
        hover = L and "Dock kits can be placed in open sea, deep sea, and cave void." or "码头套装可以在中海、深海、洞穴虚空铺设。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "sea_reclamation",
        label = L and "Land Reclamation" or "填海造陆",
        hover = L and "Ground tiles can be placed directly on water, and pitchforks can turn ground into water." or "地皮可以直接铺在海上，草叉可以铲掉地面成为海洋。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "structure_invincible",
        label = L and "Invincible Structure" or "建筑无敌",
        hover = L and "Walls become invincible, or all buildings become invincible and only the player can destroy them." or "墙体变为无敌，或者所有建筑都无敌，只有玩家可以摧毁。",
        options = {
            { description = L and "Off" or "关", data = false },
            { description = L and "Wall invincible" or "墙体无敌", data = 1 },
            { description = L and "Wall and structure invincible" or "墙体和建筑无敌", data = 2 },
        },
        default = false,
    },
    {
        name = "auto_door",
        label = L and "auto-door" or "自动门",
        hover = L and
            "The player can open the automatic mode by right-clicking the door, the player will open when he is close, and the player will close automatically when he is far away." or
            "玩家右键门可以开启自动模式，玩家靠近就会打开，远离就会自动关闭。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "batch_cooking",
        label = L and "Batch Cooking" or "整组烹饪",
        hover = L and "Each pot and container slot can hold a group of ingredients." or "每个锅每个容器槽可以放一组食材",
        options = SWITCH(),
        default = false,
    },
    {
        name = "deploy_not_space",
        label = L and "No Space Between Placements" or "放置无间距",
        hover = L and "Buildings can be placed with no space between them." or "放置建筑的时候没有间距。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "infinite_skillxp",
        label = L and "Unlimited Skill Points" or "用不完的技能点",
        hover = L and "Increase player skill point cap to 100." or "玩家技能点上限提高到100，足够点完所有无限制的技能。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "phonograph_loop",
        label = L and "Phonograph Loop" or "留声机歌曲循环",
        hover = L and "Phonograph songs will loop instead of stopping after 60 seconds." or "留声机歌曲将会循环播放，不会再播放60秒就停下。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "quick_change_role",
        label = L and "Easy Change Role" or "便捷换人",
        hover = L and "Players can initially make Moon Rock Idol in the production bar, right-click Idol can directly change the role." or "玩家初始可以在制作栏制作月岩雕像，右键雕像可以直接更换角色。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "firesuppressor_not_consume",
        label = L and "Ice Flingomatic Unlimited Fuel" or "雪球发射器无限燃料",
        options = SWITCH(),
        default = false,
    },
    {
        name = "firesuppressor_orient",
        label = L and "Ice Flingomatic Orient Launch" or "雪球发射器定位发射",
        hover = L and "You can left-click the Ice Flingomatic to remove a directional device, and the Ice Flingomatic will be fired wherever the device is." or
            "可以左键雪球发射器取下一个定位装置，装置在哪雪球器就会往哪发射。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "firesuppressor_not_firepit",
        label = L and "Ice Flingomatic Won't put out Firepit" or "雪球发射器不熄灭火坑",
        hover = L and "The Ice Flingomatic will no longer fire snowballs at fire pits and campfires." or "雪球发射器不会再向火坑和营火发射雪球。",
        options = SWITCH(),
        default = false,
    },

    {
        name = "bootleg_land_teleport",
        label = L and "Bootleg Getaway Land Teleport" or "出逃腿靴陆地传送",
        hover = L and "The Bootleg Getaway can be used for land transport, and the vortex can be opened by right-clicking the land." or "出逃腿靴可用于陆地传送，右键陆地即可开启旋涡。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "plant_not_transplanted",
        label = L and "Remove Plant Transplant Mark" or "移除植物移植标记",
        hover = L and "Remove the plant's transplant marker, meaning that all plants are naturally occurring." or "移除植物的移植标记，即所有植物都是自然生成的状态。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "crop_loot_pick",
        label = L and "Unlimited crop collection" or "作物无限采集",
        hover = L and "Crops fall back to stage 1 after collection rather than disappearing." or "作物采集后会退回到1阶段而不是直接消失。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "rock_avocado_fruit_no_maturity",
        label = L and "Stone Fruit Bush will not overripe" or "石果不过熟",
        hover = L and "Stone fruit bushes will not enter the overripe stage." or "石果灌木丛不会进入过熟阶段。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "forgetmelots_no_four",
        label = L and "Remove Forget-Me-Lots four stages" or "移除必忘我四阶段",
        hover = L and "Forget-Me-Lots will not enter the final stage than oblivion" or "比忘我不会进入最后一个阶段（抽薹阶段）",
        options = SWITCH(),
        default = false,
    },

    {
        name = "heatrock_not_consume",
        label = L and "Thermal Stone infinitely durable" or "暖石无限耐久",
        options = SWITCH(),
        default = false,
    },
    {
        name = "saltlick_not_consume",
        label = L and "Salt Lick infinitely durable" or "舔盐块无限耐久",
        options = SWITCH(),
        default = false,
    },
    {
        name = "mushroom_light_not_consume",
        label = L and "Mushlight is always bright" or "蘑菇灯永亮",
        hover = L and "The items in the mushroom lamp and the mushroom lamp will not continue to rot and can be used forever." or "蘑菇灯和菌伞灯内的物品不会继续腐烂，可以永久使用。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "cursed_monkey_token_drop",
        label = L and "Accursed Trinket can be discarded" or "可以丢弃诅咒饰品",
        hover = L and "Cursed items do not attach to the player, and the player can actively discard cursed items" or "诅咒饰品不会吸附玩家，玩家也可以主动丢弃诅咒饰品",
        options = SWITCH(),
        default = false,
    },
    {
        name = "monkey_merm_talk",
        label = L and "Can understand monkey and merm talk" or "可以听懂猴子鱼人说话",
        hover = L and "Can understand monkey and merm talk." or "可以听懂猴子和鱼人说话。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "super_farm_hoe",
        label = L and "Super Garden Hoe" or "超级园艺锄",
        hover = L and "The garden hoe hoe hoe nine pits, and comes with a container, you can put seeds, when the hoe hoe automatic planting." or "园艺锄一锄九坑，并且自带一个容器，可以放入种子，锄坑的时候自动播种。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "fish_fast_respawn",
        label = L and "Pond unlimited fishing" or "池塘无限钓鱼",
        hover = L and "There is no limit to the number of pond fishing, you can fish all the time." or "池塘钓鱼次数无上限，可以一直钓鱼。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "townportal_map_blink",
        label = L and "The Lazy Deserter minimap transfer" or "懒人传送塔可小地图传送",
        hover = L and "After touching the lazy tower, open the map and right-click the other lazy tower to transfer." or "触摸懒人传送塔后打开地图右键其他懒人传送塔进行传送。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "portable_bullkelp_plant",
        label = L and "Portable Bull Kelp" or "便捷公牛海带",
        hover = L and "Bull kelp can be picked up from the sea by right-clicking, and bull kelp stems can be planted without spacing." or "可以右键拾取海里的公牛海带，公牛海带茎可以无间隔种植。",
        options = SWITCH(),
        default = false,
    },

    {
        name = "irreplaceable_item_not_drop",
        label = L and "Unique items don't drop off the line" or "独特物品下线不掉落",
        hover = L and "Unique items such as ancient keys, celestial orb, eye bone, and Grom flower will not be dropped when the player is offline." or
            "身上远古钥匙、天体宝球、眼骨、格罗姆花等独特物品在玩家下线和上下洞穴时不会掉落。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "refresh_point_visible",
        label = L and "Bio refresh point viewable" or "生物刷新点可视",
        hover = L and "On the ground, it shows the refreshing point of life in the ancient area of the cave and other biological groups such as Volt sheep and Pieflo cattle." or
            "在地上显示伏特羊、皮弗娄牛等生物群和地洞远古区生物的刷新点。",
        options = {
            { description = L and "Off" or "关", data = false },
            { description = L and "Only Show biological groups" or "仅显示群落刷新点", data = 1 },
            { description = L and "Show biological groups and Ancient area" or "群落和远古区生物都显示", data = 2 },
        },
        default = false,
    },
    {
        name = "monkey_mediumhat_pirate_stash",
        label = L and "Captain's Tricorn brush treasure" or "船长帽刷宝藏",
        hover = L and "The player can directly craft the Captain's tricorn hat, refreshing a treasure spot near the wearer at regular intervals." or
            "玩家可以直接制作船长的三角帽，每隔一段时间在佩戴者附近刷新一个藏宝点。",
        options = SWITCH(),
        default = false,
    },
    {
        name = "supe_ancienttree_seed",
        label = L and "Surprising Seed Strengthen" or "惊喜种子强化",
        hover = L and "Surprise seeds and the corresponding two plants grow without restriction to the field, without limitation to the season."
            or "惊喜种子以及对应的两个植物生长不限制地皮，不限制季节。",
        options = SWITCH(),
        default = false,
    },
}
