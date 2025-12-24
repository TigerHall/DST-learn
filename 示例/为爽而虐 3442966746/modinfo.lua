version = "3.1.2.35"
author = "繁花丶海棠 | 胜天一猫 | leo2468"
forumthread = ""
api_version = 10
all_clients_require_mod = true
client_only_mod = false
dst_compatible = true
priority = -11110
icon_atlas = "modicon.xml"
icon = "modicon.tex"
server_filter_tags = {"为爽而虐", "HappyPatch", "暗影世界", "ShadowWorld"}
-- [url=http://wiki.flapi.cn/doku.php?id=02%E8%81%94%E6%9C%BAmod%E5%8C%BA:%E4%B8%BA%E7%88%BD%E8%80%8C%E8%99%90:%E9%A6%96%E9%A1%B5]电脑wiki 未更新[/url]
-- [url=http://wap.modwikis.com/mod/mainPage?_id=65e96518aa49810aaddef183]手机wiki 未更新[/url]
-- 国际化,1为中文,2为英文
local langid = 2
if locale == "zh" or locale == "zhr" or locale == "zht" then langid = 1 end
local function i18n(text, setnil)
    if text == nil or text == "" then return setnil == nil and "" or nil end
    if text[langid] ~= nil and text[langid] ~= "" then return text[langid] end
    if text[2] ~= nil and text[2] ~= "" then return text[2] end
    if text[1] ~= nil and text[1] ~= "" then return text[1] end
    return text
end
-- local version_dev = true
-- EMOJI From emoji_items.lua
name = version_dev and i18n({"󰀠 暗影世界", "Shadow World"}) or i18n({"󰀠 为爽而虐重制版", "Happy/Shadow World reworked"})
description = i18n({"当前版本:", "Version"}) .. version ..
                  (version_dev and i18n({" 模组为爽而虐的开发版本", " Mod [DST Patch For Happy]'s Dev Version"}) or "") .. "\n" .. i18n({
    [[原作者跑路了，这里是火鸡的改版
饥荒联机版的一个困难模式模组,兼容永不妥协,难度较高
模组四大主题,随机生物大小/暗影世界/简单模式/困难模式,分别独立开关
模组内置快捷收集整理存放功能
模组内置可选复活按钮(简单模式-角色加强-旺达选项)
模组可选随机季节(困难模式-天气/科技改动)

交流群607385645(院长的小群),更新日志见群与工坊模组改动记录
模组不定期更新频繁,此时建议订阅客户端模组：无视服务器模组过期]],
    [[A hard mode mod of DST.Compatible with uncompromising mode.

The mod's idea is that game is more hard to play at first,long term survive and fight with monsters.
In addition, the mod has made appropriate balance changes to the official character/some items/technology building/game settings.

QQ Group 607385645]]
})
-- bugtracker_config = {
--     email = "wakhh@qq.com",
--     upload_client_log = true,
--     upload_server_log = true,
--     upload_other_mods_crash_log = true,
--     auto_upload = false,
--     lang = "CHI"
-- }
-- 选项选择文本 左侧对齐或右侧对齐
-- 实现是在选择文本拼接空格达到总长度从而对齐
local labellength = ({30, 30})[langid]
local descriptionlength = ({18, 18})[langid]
local function filllabel(i)
    local str = ""
    for index = 1, labellength - i do str = str .. " " end
    return str
end
local function filldesc(i)
    local str = ""
    for index = 1, descriptionlength - i do str = str .. " " end
    return str
end
-- 预置默认字符串
local disabletext = i18n({"禁用" .. filldesc(4), "Disable" .. filldesc(7)})
local enabletext = i18n({filldesc(4) .. "启用", filldesc(6) .. "Enable"})
local partenabletext = i18n({filldesc(4) .. "部分", filldesc(4) .. "Part"})
local leftparttext = i18n({"部分" .. filldesc(4), "Part" .. filldesc(4)})
-- 小数的数值对齐时使用,支持0.001~9999.999
local function numberdigits(num)
    -- 必定有个位
    local digits = 1
    -- 小数部分
    if num % 1 ~= 0 then
        local newnum = num * 1000
        if newnum % 10 ~= 0 then
            digits = digits + 4
        elseif newnum % 100 ~= 0 then
            digits = digits + 3
        else
            digits = digits + 2
        end
    end
    -- 整数部分
    if num >= 1000 then
        digits = digits + 3
    elseif num >= 100 then
        digits = digits + 2
    elseif num >= 10 then
        digits = digits + 1
    end
    return digits
end
local function forconfoption(conf, i, fillindex, enabledesc, index, newmax, enablehover)
    conf.options[i + fillindex] = {
        description = enabledesc and (enabledesc[i] or enabledesc) or
            (index < 0 and (index == newmax and enabletext or partenabletext) or filldesc(numberdigits(index / 1000)) .. index / 1000),
        hover = enablehover and enablehover[i] or enablehover,
        data = index / 1000
    }
end
-- 通用选项
-- key索引键,label左侧文本,hover顶部描述,默认值,值最小值,值最大值,值间隔,启用时底部描述,禁用时底部描述,启用时右侧值文本,禁用时右侧值文本,颠倒启用禁用顺序
local function item(key, label, hover, default, min, max, step, enablehover, disablehover, enabledesc, disabledesc, revert)
    -- 这个item函数是用来构建各类选项的特制函数,非常专用化,可以定义新的函数
    -- 用法1：常见二值选项item("key","label","hover")
    -- 用法2：在二值选项后快速增加x个新可选("key","label","hover",true,nil,nil,-x)
    -- 用法3：定义一个多值选项item("key","label","hover",1,1,5,1)
    local conf = {name = key, label = label, hover = hover, options = {}, default = default == nil or default or false}
    if not revert then
        -- revert目前只用于item("Shadow Animals", i18n({"有暗影分身的生物", "Which Creatures Has Shadow"})选项
        conf.options[1] = {description = disabledesc or disabletext, hover = disablehover, data = false}
    end
    if min ~= nil and max ~= nil and step ~= nil then
        -- 用法3： 可禁用可选批量数值的选项,值没有true,可选选项长度动态计算
        -- item("key","label","hover",1,1,1000,1) 或 item("key","label","hover",-1,-1,-5,-1)
        -- 底部描述 enablehover 要么为字符串要么为可选选项长度的字符串数组
        -- 右侧值文本 enabledesc 填写要求同上,不填的话,值小于0视为填写了部分/启用,值大于0则显示数值本身
        local i = 1
        local fillindex = revert and 0 or 1
        local realstep = step > 0 and step or -step
        local newmin = min * 1000
        local newmax = max * 1000
        local newstep = step * 1000
        local realnewmin = newmin < newmax and newmin or newmax
        local realnewmax = newmin < newmax and newmax or newmin
        local realnewstep = newstep > 0 and newstep or -newstep
        local reallength = (realnewmax - realnewmin) / realnewstep
        if reallength < 102 then
            for index = newmin, newmax, newstep do
                forconfoption(conf, i, fillindex, enabledesc, index, newmax, enablehover)
                i = i + 1
            end
        else
            -- 如果可选数值选项超过100多种,则适当压缩部分选择,但不影响可选选项长度
            local startlength = realnewmin / realnewstep
            local diff1 = startlength + 20
            local diff2or5 = startlength + 50
            local diff5 = startlength + 100
            local diff10 = startlength + 200
            local diff20or50 = startlength + 400
            for index = newmin, newmax, newstep do
                local diff = index / realnewstep
                if diff < diff1 or (diff < diff2or5 and (diff % 2 == 0 or diff % 5 == 0)) or (diff < diff5 and diff % 5 == 0) or
                    (diff < diff10 and diff % 10 == 0) or (diff < diff20or50 and (diff % 20 == 0 or diff % 50 == 0)) or (diff % 50 == 0) then
                    forconfoption(conf, i, fillindex, enabledesc, index, newmax, enablehover)
                    i = i + 1
                end
            end
        end
        if revert then conf.options[i + fillindex] = {description = disabledesc or disabletext, hover = disablehover, data = false} end
    elseif min == nil and max == nil and step ~= nil and step < 0 and not revert then
        -- 用法2： 可禁用可启用且有多级可选的选项,该选项和上一选项差不多,但值多一个true
        -- item("key","label","hover",-1,nil,nil,-5)
        -- 多级可选 step step必须小于0,step代表从-1到step起的多级可选,-5则包含true在内有6个可选,可选选项长度为6
        -- 底部描述 enablehover 要么为字符串要么为可选选项长度或2长度的字符串数组,true值选项显示第一个字符串,2长度字符串数组时除true值选项外的选项都会用第二个字符串
        -- 右侧值文本 enabledesc 要么为字符串要么为可选选项长度或更短数组,更短则数组第二个值起需要为数值
        --                      true值选项为第一个字符串,后续选项会自动第二个数值上逐步加1显示,不填则视为填写部分/启用
        conf.options[2] = {
            description = enabledesc and (enabledesc[1] or (enabledesc[2] and enabletext) or enabledesc) or enabletext,
            hover = enablehover and enablehover[1] or enablehover,
            data = true
        }
        local i = 2
        for index = -1, step, -1 do
            -- 连续数字选项值显示(enabledesc[2] + i - 2),仅适用于item("Wilson Skill Points", i18n({"威尔逊技能组继续成长", "Wilson Has More Skill Points"})选项
            conf.options[i + 1] = {
                description = enabledesc and
                    (enabledesc[i] and ((-step + 1) > #enabledesc and (filldesc(numberdigits(enabledesc[i])) .. enabledesc[i]) or enabledesc[i]) or
                        (enabledesc[2] and filldesc(numberdigits(enabledesc[2] + i - 2)) .. (enabledesc[2] + i - 2)) or enabledesc) or
                    (index == step and enabletext or partenabletext),
                hover = enablehover and (enablehover[i] or enablehover[2] or enablehover) or index,
                data = index
            }
            i = i + 1
        end
    elseif min == "pairs" and max ~= nil and not revert then
        -- 多级自定义选项,暂未启用
        local i = 2
        for index = 2, #max, 2 do
            conf.options[i] = {
                description = enabledesc and (enabledesc[i] or enabledesc) or max[index - 1],
                hover = enablehover and enablehover[i] or enablehover,
                data = max[index]
            }
            i = i + 1
        end
    else
        -- 用法1：简单的二值选项,用法 item("key","label","hover"),可以很容易改造为上上个多级可选选项
        conf.options[revert and 1 or 2] = {description = enabledesc or enabletext, hover = enablehover, data = true}
        if revert then conf.options[2] = {description = disabledesc or disabletext, hover = disablehover, data = false} end
        -- min,max有值,只用于item("Shadow Prefab Setting", i18n({"暗影分身仇恨玩家", "Shadow Attack Player Actively"})选项
        if min ~= nil then conf.options[revert and 2 or 1].data = min end
        if max ~= nil then conf.options[revert and 1 or 2].data = max end
    end
    return conf
end
-- 标题选项
local function headeritem(label, hover, disablehover)
    return {name = "", label = label, hover = hover, options = {{description = "", hover = disablehover, data = false}}, default = false}
end
--  空白选项
local function spaceitem() return {name = "", label = "", hover = "", options = {{description = "", data = false}}, default = false} end
configuration_options = {
     item("Language In Game", i18n({"本模组游戏内语言", "Mod Language In Game"}), nil, false, -1, -2, -1, {"简体中文", "English"},
          i18n("自动设定", "Auto Setting"), {filldesc(8) .. "简体中文", filldesc(6) .. "English"}, filldesc(4) .. i18n({"自动", "Auto"})),
     item("Show Mod Icon In Game", i18n({"游戏内查看模组按钮", "Mods Info Flower Btn"}),
          i18n({"聊天区打字 `显示/隐藏/默认模组` 试试", "try chat input `show/hide/default mods` and enter"})),
     item("Tool Tips", i18n({"制作栏提示", "Crafting Menu Tooltips"}),
          i18n({"制作栏物品旁边提示对应模组改动", "Crafting Menu Item's Mod Tooltips"})),
     item("Encyclopedia_UI", i18n({"游戏内百科全书", "In-Game Encyclopedia"}),
          i18n({"游戏内查看模组列表置顶【百科全书】", "In-Game Encyclopedia in Mod List"})),
     item("Disable Outdate Tip", i18n({"限制模组版本更新提示", "Limit Mods Outdate Tip"}), i18n(
          {"模组的版本更新提示仅在出现和有新玩家时各显示一次", "Limit Mod's Version Tip only show once when init and player join"}), 1, 1,
          2, 1, {i18n({"仅限制本模组更新提示", "Only Disable The Mod's Tip"}), i18n({"限制所有模组更新提示", "Disable All Mod's Tip"})}, nil,
          enabletext),
     item("player tags limit", i18n({"角色标签限额扩展", "Roles' Tags Limit"}),
          i18n({"角色默认限制拥有63标签，现在为63+N*50", "Roles can have more tags.Default 63,Now is 63+N*50"}), false, 1, 10, 1),
     item("ignore client error", i18n({"强制拦截客户端错误", "Force Ignore Client Error"}),
          i18n({"只拦截客户端游戏内更新游戏API中遇到的错误", "Force Ignore Client Error in game's update API"}), false),
     item("Container Sort", i18n({"容器整理收集按钮", "Containers Buttons"}),
          i18n({"容器整理收集/末影箱穿越/衣柜换装按钮", "Sort and Collect/Shadow Container Exchange Button"}), -3, -1, -5, -1, {
          i18n({"无额外跨整和锁定按钮", "No Extra Multi Sort/Lock Button"}),
          i18n({"额外跨容器整理按钮(同类容器批量整理)", "Extra Multi Sort Button(Same Container Sort Together)"}),
          i18n({"额外锁定道具按钮(与跨整互斥)", "Extra Lock/Unlock Button(No Multi Sort Button)"}),
          i18n({"无额外按钮且禁用收集按钮", "No Extra Button and Disable Collect Button"}),
          i18n({"无额外按钮且禁用整理按钮", "No Extra Button and Disable Sort Button"})
     }, nil, enabletext),
     item("Items collect", i18n({"道具快捷收集存放", "Items Collect/Store"}),
          i18n({"Ctrl[Alt]右键道具,制作栏/智能锅收集道具", "Press Ctrl+Mouse Right Store Items;Craft menu Collcect Items"}), -3, -1, -3, -1,
          {i18n({"禁用收集", "Disable Collect"}), i18n({"禁用存放", "Disable Store"}), ""}),
     item("enable easy mode", i18n({"󰀜 简单模式总开关", "Enable 󰀜 Easy Mode"})),
     item("enable hard mode", i18n({"󰀕 困难模式总开关", "Enable 󰀕 Hard Mode"}),
          i18n({"不包含Ray和暗影世界内容的开关", "It not close Ray/Shadow World"})),
     --     item("simple chatbot", i18n({"千影小助手", "little QianYing"}), i18n({"召唤小助手来帮你吧", "call bot for help"})),
     --     spaceitem(),
     --     item("Server Paused", i18n({"服务器暂停/继续投票", "Vote for pause / resume"}, i18n({"投票暂停或继续", "Vote for pause / resume"}))),
     headeritem("Ray"),
     item("Random Sized", i18n({"随机生物大小", "Random biological size"}),
          i18n({"如生活调味料一般改变方方面面", "Change all aspects like seasoning in daily life"}), 1, 1, 1, 1,
          i18n({"启用随机大小", "Enable Random Sized"}), i18n({"禁用随机大小", "Random Sized"}), enabletext),
     item("ban op", i18n({"允许作弊", "not ban op"}),
          i18n({"禁用后，玩家禁止回档，使用控制台等", "Players are prohibited from rollback, using administrator privileges, etc"}), 1, 1, 1, 1,
          i18n({"启用作弊", "Enable cheating"}), i18n({"禁用作弊", "Disable cheating"}), enabletext),
     item("World ecosystem", i18n({"群系灭绝", "ecosystem extinction"}), i18n({
          "一直无底限的猎杀生物最终会导致生物永久覆灭",
          "The continuous and unrestrained hunting of wildlife will ultimately lead to the permanent extinction of species"
     }), false, 1, 1, 1, i18n({"启用群系灭绝", "Enable World ecosystem"}), i18n({"禁用群系灭绝", "World ecosystem"}), enabletext),
     item("World lose", i18n({"遗忘地图", "lose atlas"}), i18n({
          "玩家需使用月岩守卫标记，否则地图不会解锁。",
          "The player triggers the use of guard markers, otherwise the map will not be unlocked"
     }), false, 1, 1, 1, i18n({"启用遗忘", "Enable World ecosystem"}), i18n({"禁用遗忘", "World ecosystem"}), enabletext),
     item("World Unlock", i18n({"地图解锁", "World Unlock"}),
          i18n({"遗忘地图开启时玩家可以使用特殊手段来解锁地图。", "Players can use special methods to unlock the map"}), false, 1, 1, 1,
          i18n({"启用解锁", "Enable unlocking"}), i18n({"禁用解锁", "Disable unlocking"}), enabletext),
     headeritem(i18n({"󰀩 暗影世界" .. filllabel(11), "󰀩 Shadow World" .. filllabel(15)})),
     headeritem(i18n({"生物改动", "Creatures"})),
     item("Shadow World", i18n({"生物暗影分身数目", "Creatures' Shadow Number"}),
          i18n({"这个世界的生物会生成几个暗影分身", "Creatures will have N shadow in the world"}), 1, 1, 3, 1,
          i18n({"启用暗影世界", "Enable Shadow World"}), i18n({"禁用暗影世界", "Disable Shadow World"})),
     item("Shadow Animals", i18n({"有暗影分身的生物", "Which Creatures Has Shadow"}),
          i18n({"这个世界的哪些生物会生成暗影分身", "Whick creatures will have shadow in the world"}), false, 1, 7, 1, {
          i18n({"除boss外的生物会生成暗影分身", "Creatures except player and boss will have shadow in the world"}),
          i18n({"仅boss会生成暗影分身", "Only boss will have shadow in the world"}),
          i18n({"全部生成但boss残血25%或2500血以下时才生成", "all has but boss low health 25%/2500 will have shadow"}),
          i18n({"全部生成但蜂后和部分困难加强boss半血时生成", "all has but some boss low health 50%/5000 will have shadow"}),
          i18n({"全部生成但boss半血50%或5000血以下时才生成", "all has but boss half health 50%/5000 will have shadow"}),
          i18n({"仅boss残血25%或2500血以下时生成暗影分身", "only boss low health 25%/2500 will have shadow"}),
          i18n({"仅切斯特哈奇阿比盖尔伯尼", "only abigail/bernie/hutch/chester"})
     }, i18n({"除影怪和不可移动生物外大部分生物都会生成暗影分身", "Most creatures will have shadow except shadow/fixed creatures"}), {
          i18n({filldesc(6) .. "非boss", filldesc(7) .. "Notboss"}),
          i18n({filldesc(6) .. "仅boss", filldesc(4) .. "Boss"}),
          i18n({filldesc(6) .. "boss残血", filldesc(13) .. "BossLowHealth"}),
          i18n({filldesc(6) .. "boss特殊", filldesc(11) .. "BossSpecial"}),
          i18n({filldesc(6) .. "boss半血", filldesc(14) .. "BossHalfHealth"}),
          i18n({filldesc(8) .. "仅boss残血", filldesc(18) .. "OnlyBossLowHealth"}),
          i18n({filldesc(6) .. "仅宠物", filldesc(7) .. "OnlyPet"})
     }, i18n({filldesc(6) .. "大部分", filldesc(4) .. "Most"}), true), -- false为大部分,1为非boss,2为仅boss,3为...,最后一个true是revert颠倒顺序
     item("Shadow Num Limit", i18n({"暗影分身总数上限", "Shadow Num Limit"}), i18n(
          {"世界的暗影分身数目上限,BOSS/宠物不算;有但不能生成则减伤", "Per world,except Boss/Pet;If can't then creature reduce takendmg"}),
          18, 5, 30, 1, nil, nil, nil, i18n({filldesc(4) .. "无限", filldesc(7) .. "Unlimit"})),
     item("Shadow Regen Period", i18n({"暗影分身再生时间", "Shadow Rebirth Time"}), -- false为瞬间再生
          i18n({"死亡后多少秒再次生成", "N seconds rebirth after death"}), 240, 10, 480, 10, nil, nil, nil, filldesc(1) .. "1"),
     item("Shadow Help Self", i18n({"生物转移敌人仇恨", "Creatures Transfer Hatred to Shadow"}),
          i18n({"生物会将敌人仇恨转移给暗影分身", "When creatures attacked by enemy,it will transfer hatred to its shadow"}), 1, 1, 4, 1, {
          i18n({"只有没有攻击力的生物会转移敌人仇恨给分身", "Creatures No damage"}),
          i18n({"除boss外的生物都会转移仇恨,韦伯沃特很强", "Creatures except player and boss,strong webber and wurt"}),
          i18n({"boss残血25%时才转移敌人仇恨给分身", "all but boss only low health 25% "}),
          i18n({"大部分生物都会转移,韦伯沃特削弱很大", "Most creatures;weak webber and wurt when attack boss"})
     }, nil, {
          i18n({filldesc(6) .. "仅无害", filldesc(8) .. "OnlySafe"}),
          i18n({filldesc(6) .. "非boss", filldesc(7) .. "Notboss"}),
          i18n({filldesc(6) .. "boss残血", filldesc(13) .. "BossLowHealth"}),
          i18n({filldesc(6) .. "大部分", filldesc(4) .. "Most"})
     }, nil),
     item("Shadow Protect Creatures", i18n({"暗影分身保护本体", "Shadow Protect Creatures"}), i18n(
          {"关闭暗影分身独立仇恨;暗影分身有仇恨后仍共享本体仇恨", "Shadow will whether share creatures's target even it has own target"}),
          false),
     item("Shadow Prefab Setting", i18n({"暗影分身仇恨玩家", "Shadow Attack Player Actively"}),
          i18n({"暗影分身主动仇恨没有骨头头盔类防护的玩家", "Shadow will appear and hate player without bone helm near animal"}), true, true,
          false), -- true为和平机制,false为危险机制,实际值与显示信息相反,主要是为了兼容旧版本
     item("Shadow Epic Far Range", i18n({"本体远离驱散距离", "Epic Far Stop Range"}),
          i18n({"远离BOSSx距离后BOSS驱散暗影分身,非BOSS距离50", "Far away Epic x range,shadow disappear;Not epic 50"}), 200, 1000, 100, -100, nil,
          nil, nil, i18n({filldesc(4) .. "无限", filldesc(7) .. "Unlimit"})),
     item("Epic Shadow Far Range", i18n({"分身远离回归距离", "Epic Shadow Far Range"}),
          i18n({"远离Boss分身x距离后分身主动回归,非BOSS距离50", "Far away Epic's shadow x range,shadow disappear;Not epic 50"}), false, 1000,
          100, -100, nil, nil, nil, i18n({filldesc(4) .. "无限", filldesc(7) .. "Unlimit"})),
     item("Shadow Harder Level", i18n({"暗影世界第二周目", "Shadow World Second Mode"}), i18n(
          {"裂隙开启后,脱离加载或丢失仇恨,分身闪到本体周围", "When Enable Rifts,Shadow go back when leave load range or lose target"}),
          false),
     spaceitem(),
     headeritem(i18n({"󰀜 简单模式" .. filllabel(10), "󰀜 Easy Mode" .. filllabel(11)})),
     headeritem(i18n({"建筑改动", "Structures"})),
     item("Science Machine Refine Materials", i18n({"科学机器精炼材料", "Science Machine Refine Materials"}),
          i18n({"可以给予成品或材料进行加工,齿轮升级9次", "Give it product or ingredients,gears to level up"})),
     item("Alchemy Engine Redeem Gold Nugget", i18n({"炼金引擎有炼金术", "Alchemy Engine Alchemy"}),
          i18n({"有威尔逊部分炼金术给予炼金;齿轮升级", "Give materials to wilson's Alchemy;gears levelup"}), -1, nil, nil, -1,
          {i18n({"给予肉和玩具等可兑换金块", "Give meat and toy for gold nuggets"}), i18n({"禁用兑换金块", "Disable Redeem GoldNugget"})}),
     item("Shadow Manipulator Break Down Objects", i18n({"灵子分解器分解道具", "Shadow Manipulator Break Down Objects"}),
          i18n({"返还一半素材,小数点部分概率返还,绿宝石升级两次", "Give items returns 50% ingredients;Greengen levelup"})),
     item("Prestihatitator Redeem shadowmagic Tag", i18n({"暗影操控器兑换暗影魔法", "Prestihatitator Redeem shadowmagic Tag"}), i18n({
          "给予4噩梦燃料获得暗影魔法和工具标签并让读魔法书理智消耗变为1倍",
          "Give 4 nightmare fuels offers shadow magic/tool tag and consumes normal reading sanity"
     })),
     item("Terra Firma Tamper Redeem Desert Stone", i18n({"土地夯实器兑换沙之石", "Terra Firma Tamper Redeem Desert Stone"}),
          i18n({"给予蛋和玩具等可兑换沙之石;铥矿升级", "Give eggs and toy for desert stones;Thulecite levelup"}), true, nil, nil, -1,
          {" ", i18n({"改为使用懒人传送塔兑换沙之石", "Replace use Lazy Deserter to redeem"})}),
     item("Tackle Receptacle Use Fish Redeem", i18n({"钓具容器选择改动", "Tackle Receptacle Storage Tackle"}), nil, -1, nil, nil, -1, {
          i18n({"给予活鱼可兑换海带种子玩具金子触手皮", "Give live fish for kelp seeds toy gold nuggets tentacle spots"}),
          i18n({"禁用兑换但可存放菜肴和钓具箱内道具0.15倍缓鲜", "Disable Redeem but store/0.15 keep pot food and tackle box items"})
     }),
     item("Cartographer's Desk Make Blueprint", i18n({"制图桌制作蓝图", "Cartographer's Desk Make Blueprint"}), i18n({
          "给道具有莎草纸得道具蓝图,给莎草纸复制携带的纸制品",
          "Give item has papyrus get item Blueprint;Give papyrus has paperitem copy paperitem"
     })),
     item("Make Cooking Recipe Card", i18n({"烹饪锅制作食谱卡", "Crock Pot Make Recipe Card"}), i18n({"给予莎草纸", "Give papyrus"})),
     item("mannequin swap follower", i18n({"假人额Buff外交换随从", "Mannequin Swap Follower"}),
          i18n({"仅有攻击力的无仇恨的随从", "Only follower has damage and no target"}), true, nil, nil, -1,
          {i18n({"可以放入物品栏的随从放入假人物品栏", "Try Follower Put Into Mannequin's inventory"}), i18n({"不放入", "Not Put Into"})}),
     item("townportal use sandstone activate", i18n({"懒人传送塔保持激活", "Lazy Deserter Activate by Sand Stone"}),
          i18n({"给予沙之石保持激活;再右键其取消激活归还沙之石", "Give First lazy deserter to activate lazy deserter"})),
     item("dragonfly furnace stewer", i18n({"龙鳞火炉增强", "Dragonfly Furnace Buff"}),
          i18n({"放入足够食材;给燃料缩短做饭时间", "Give food Ingredients to cook;Give fuel to reduce cook time"}), -1, nil, nil, -1, {
          i18n({"可制作便携锅专属料理", "Include Warly's recipes"}),
          i18n({"根据角色标签决定是否可制作便携锅专属料理", "Not Include Warly's recipes"})
     }),
     item("Portable Crock Pot Multi", i18n({"便携烹饪锅批量调味", "Portable Crock Pot Multi"})),
     item("Terrariumchest_Extradrop", i18n({"泰拉宝箱掉落弹性容器", "Terrarium Chest Drop Flexible Container"})),
     item("Tent restores sanity penalty", i18n({"帐篷回复理智上限", "Tent restores sanity penalty"})),

     headeritem(i18n({"机制改动", "Settings"})),
     item("Sleep In Tent Even Danger", i18n({"危险入睡", "Sleep In Tent Even Danger"}),
          i18n({"睡觉无视危险", "Sleep In Tent Even Danger"}), true, nil,
          nil, -1, {i18n({"并强制脱离仇恨", "Force attacker lose target"}), i18n({"不强制脱离仇恨", "Not Force"})}),
     item("Haunt Telltale Heart To Revive", i18n({"作祟告密的心复活", "Haunt Telltale Heart To Revive"}),
          i18n({"作祟容器可以把心作祟出来了", "Even if it's in container"})),
     item("Construction Amulet Repair Equip", i18n({"材料建造修理道具", "Ingredients Repair Equip"}),
          i18n({"部分道具可以材料修理,或需携带建造;", "Use Ingredients Repair Some Items,May take Construction Amulet"}), true, nil, nil, -1,
          {"", i18n({"建造护符直接修理道具", "Use Construction Amulet Straight Repair Some Items"})}),
     item("Use Dock kit in Cave", i18n({"洞穴世界使用码头地皮", "Use Dock kit in Cave"}), nil, true, nil, nil, -1,
          {i18n({"码头4天后自毁", "Auto damage,only exist 4 days"}), i18n({"码头不会自毁", "Don't auto damage"})}),
     item("Spider Gland Can Heal Monster Meat", i18n({"净化怪兽肉为肉", "Heal Monster Meat Into Meat"}), i18n(
          {"使用蜘蛛腺体蚊子血袋药膏净化各种怪物食材", "Spider land,mosquito sack,healing salve and so on.Include cooked and dried ones"})),
     item("Use Fire To Cook", i18n({"用任意火焰烹饪", "Use Fire To Cook"}),
          i18n({"火炬,猪人火炬,冰篝火,燃烧的树木等", "Use pig Torch,burning tree and so on to cook"})),
     item("pickup irreplaceable item", i18n({"上线自动捡眼骨", "Auto Pickup Irreplaceable Item"}),
          i18n({"上线时自动捡起眼骨类道具", "Auto Pickup Irreplaceable Item When Connect"})),
     item("Pause Spawn Timers During Boss Fight", i18n({"Boss战暂停袭击倒计时", "Pause Spawn Timers During Boss Fight"}),
          i18n({"Boss战中暂停猎犬/蠕虫/海盗/时令Boss倒计时", "Pause hound/worm/pirate/seasonal boss timers during boss fights"})),

     headeritem(i18n({"装备改动", "Equips"})),
     item("Reskin Tool Upgrade", i18n({"清洁扫把连接科技", "Clean Sweeper Connect Prototyper"}),
          i18n({"目前仅支持可升级科技且困难需给过四本燃料", "Hard need Prestihatitator Redeem shadowmagic Tag;Now Support 4 prototyper"})),
     item("Deck Illuminator Equip Head", i18n({"甲板照明灯装备头部", "Deck Illuminator Equip Head"}), i18n({"彩蛋设定", "Easter egg settings"}),
          false),
     item("Glass Cutter Leap Attack", i18n({"注能玻璃刀跳跃斩击", "Infused Glass Cutter Leap Attack"}),
          i18n({"注能月亮碎片注能可跳劈,跳劈受益于理智或新鲜", "Need Infused Moon Shard activate.Sanity Effect damage and range"}), true,
          nil, nil, -1,
          {i18n({"玻璃刀击杀影怪回理智但困难模式移除妥协增伤", "Simpe Kill Shadow Get Sanity But Hardmode disable UM Extra Damage"}), " "}),
     item("Thulecite Equip Parry", i18n({"铥矿棒格挡敌人攻击", "Thulecite Club Parry Attack"}),
          i18n({"铥矿棒主动格挡攻击;铥矿三件套地下绝缘", "Thulecite Club can Parry attacks;Three Thulecite Equip cave insulation"}), true, nil,
          nil, -1, {"", i18n({"每次格挡时都恢复角色碰撞", "When Parry,toggle on role's physics"})}),
     item("Charged Nightsword", i18n({"充能暗夜剑", "Charged Nightsword"}),
          i18n({"充能后攻击消耗能量不消耗耐久;第4次攻击暗影突袭穿透并召唤暗影小人", "Charged consumes energy not durability;4th attack shadow strike and summon shadow minions"})),
     item("Multi Tool Is Almighty Tool", i18n({"多用斧镐更多功能", "Multi Tool Is Almighty Tool"}),
          i18n({"多用斧镐铲锤刮耕地,丢地可叉,配方改动", "dig,hammer,till,shave;drop ground pickup can terraform"})),
     item("Turf-Raiser Helm Plant Tree Cone", i18n({"超级高效刮地皮头盔", "Super Turf-Raiser Helm Tool"}),
          i18n({"范围快速工作种植部署施肥,放沙之石会修理", "Put tools or plant seeds or desert stones into it or equip tools"})),
     item("Shieldofterror Eat Owner", i18n({"恐怖盾牌捕虫", "Shield of Terror As Bug Net"}),
          i18n({"恐怖盾牌眼面具汲取敌人主人回复耐久", "Shield of Terror/Eye Mask Eat Owner/Attacker/Target"})),
     item("Clothing Enhancements", i18n({"衣物增强", "Clothing Enhancements"}),
          i18n({"让一些不太用得到的衣物变得更实用", "Make less frequently used clothing more practical"})),
     item("Scalemail Parry Freezable", i18n({"鳞甲抵抗持续冰冻", "Scalemail Parry Freezable"}),
          i18n({"鳞甲抵抗持续冰冻;熔岩虫召唤召回", "Scalemail better and 2/3 chance thaw from frozen"})),
     item("cooldown_orangestaff", i18n({"懒人手杖有冷却", "Lazy Deserter Cooldown"}),
          i18n({"冷却时间15s，仅冷却时消耗耐久", "Cooldown 15s,only consume durability when cooldown"})),   
     item("Shadow Thurible Has Light", i18n({"暗影香炉汲影照明", "Shadow Thurible Has Light"}),
          i18n({"吸收附近影怪生命恢复自身和骨头装备耐久", "recover by get health from near shadow creature"})),
     item("Bone Helm No Remove", i18n({"骨头头盔", "Bone Helmet"}), 
          i18n({"骨头头盔燃料修复，耐久为零不消失", "Bone Helmet Fuel Repair, Durability no disappear"})),
     item("Enlightened Crown Benefit From Spore", i18n({"启迪之冠过冬春夏", "Enlightened Crown Benefit From Spores"}), i18n({
          "护目;5孢子时提供热源/冷源/绝缘携带生效;蘑菇帽保暖隔热防水",
          "Goggles;5 Red/Blue/Green has warm/cold heat source/insulated even not equipped"
     }), true, nil, nil, -1, {
          i18n({"每红/蓝/绿孢子提供60保暖/60隔热/20%防水", "Each red/blue/green offers 60 warm/cold or 20% waterproof"}),
          i18n({"额外禁用启迪光照颜色", "extra disable hat light color"})
     }), 
     item("upgrade torch", i18n({"辉煌/绝望/亮茄火把", "Upgrade Your Torch"}), i18n(
          {"使用绝望石/纯粹辉煌/亮茄外壳升级你的火把(易伤/重伤)", "Use Brightshade Husk/Pure Brilliance/Dreadstone Upgrade Your Torch"})),
     item("Moongleam Weapon", i18n({"月熠奔雷/月熠晨星", "Elding Spear/Morning Star"}),
          i18n({"月熠进化充能奔雷矛,约束静电和月熠进化晨星锤", "Use Restrained Static/Moongleam Upgrade"})),
     item("hivehat", i18n({"蜂王冠升级为蜂巢", "Bee Queen Crown Change"}),
          i18n({"蜂巢蜂箱友好,给蜜蜂变蜂巢", "Beebox Friendly;Give bees change into Bee Hives"})),
     item("Horizon Expandinator", i18n({"视界扩展升级套件", "More Convenient Horizon Expandinator"}), 
          i18n({"视界扩展套件用于升级你的护目镜，增强视野范围，", "Horizon Expandinator Upgrade Goggles,Enhance View Range"})),
	item("scraphat", i18n({"拾荒尖帽耐久增强", "Scrap Hat Durability Buff"}), 
          i18n({"拾荒尖帽耐久增强50%，并且可以修理", "Scrap Hat Durability Buff 50%,and can be repaired"})),

     headeritem(i18n({"道具改动", "Props"})),
     item("trap_teeth", i18n({"犬牙/荆棘陷阱增强", "Tooth Trap/Thorn Trap Buff"}),
          i18n({"陷阱耐久提升，制作时需要多一颗狗牙", "Trap durability increase,need one more tooth to craft"})),
     item("Flare Spawn", i18n({"信号弹增强", "Flare Spawn"}),
          i18n({"流浪商人移动更慢，敌对信号弹夏秋50%召唤熊獾", "hostile flare 50% chance summoning bearger in summer and autumn."})),
     item("compass_show_trader", i18n({"指南针显示流浪商人", "Compass Show Wandering Trader"}),
          i18n({"指南针可以显示流浪商人位置", "Compass shows wandering trader on map"})),
     item("Tackle Box Can Hold Role's Item", i18n({"钓具箱容纳角色道具", "Tackle box Contains Role's Items"}),
          i18n({"钓具箱打开不掉落,放和保鲜孢子蜘蛛", "Tackle box won't drop when opening,and put/keep spore/spider"})),
     item("boat use shadowheart upgrade", i18n({"暗影心脏升级船只", "Shadow Heart Upgrade Boat"}),
          i18n({"暗影心脏放船上升级船只从而自动船舵,船损返还心脏", "Drop shadow heart on boat make its steering wheel auto"})),
     item("beef_bell use orangegem upgrade", i18n({"牛铃升级", "Upgraded Beefalo Bell"}), i18n({
          "橙宝石升级牛铃可收回，普通牛铃牛死后救赎之心复活，阴郁牛铃死亡惩罚减少",
          "Orange Gem Upgrade Beefalo Bell can be recovered;Normal Beefalo Bell can revive dead beefalo with heart of redemption;Gloomy Bell reduce punishment"
     })),
     item("ruinshat gem upgrade", i18n({"铥矿皇冠宝石升级", "Ruinshat Gem Upgrade"}), i18n({
          "红宝石获得原力场护盾，蓝宝石范围冰冻等",
          "redgem get forcefield shield, blue freeze rangely...."
     })),
     item("New Hambat 2", i18n({"全新火腿(๑•̀ㅂ•́)و✧", "New Hambat (๑•̀ㅂ•́)و✧"}),
          i18n({"火腿为什么不能吃?我不理解，但是我们火腿棒!很棒 (设置是最大重量)", "taste your hambat and be strong (config for hambat weight)"}), 10, 5, 10, 1),
     item("Enhanced_Eyeturret", i18n({"眼球炮塔增强", "Enhanced Eyeball Turret"}),
          i18n({"眼球炮塔可收回,死亡保护,冷却机制", "Eyeball turret retrievable, death protection, cooldown system"})),
     item("Tent_Upgrade", i18n({"睡袋升级帐篷", "Tent Upgrade"}),
          i18n({"睡觉无视时间，自动修复耐久翻倍，恢复能力更强", "Sleep ignore time, auto repair double durability, stronger recovery"})),     
     headeritem(i18n({"生物改动", "Plants"})),
     item("Twiggy Tree Can Pickable", i18n({"多枝树采集树枝", "Twiggy Tree Can Pickable"}),
          i18n({"多枝树长大阶段可采集树枝", "Pick twigs from grown Twiggy trees"})),
     item("Grass Gekko Regrow Grass", i18n({"草根变草蜥蜴再生", "Grass Gekko Regrow Grass"}),
          i18n({"草根变成草蜥蜴后原地再生一个枯萎草根", "New born grass gekko leave root on ground"})),
     item("Weed Product Can Plant", i18n({"杂草产物可以种植", "Weed Product Can Plant"}),
          i18n({"必忘我春秋复苏,和火荨麻犁地草可种植", "Forget-Me-Lots/Fire Nettles/Tillweed are now plantable for weeds"})),
     item("Glommer Eat Near Insects", i18n({"格罗姆会吃昆虫", "Glommer Eat Near Insects"})),
     item("Chester No Collision", i18n({"切斯特无碰撞体积", "Chester Has No Collision"})),
     headeritem(i18n({"新物品", "New things"})),
     item("player_tomb", i18n({"哀悼之穴", "tomb of player"}), i18n({"为不幸去世的玩家做点什么吧，坟头草什么的", "something would grow from player tomb ?"})),
     item("classic_farm", i18n({"经典农场", "classic farm"}), i18n({"可以制作经典的老式农场", "Make a classic old-school farm"})),
     headeritem(i18n({"角色改动", "Charaters"})),
     item("role_easy", i18n({"简单模式角色改动总开关", "Switch for Charaters of Easy Mode"})),
     item("Skilltree Points", i18n({"技能树继续成长", "Has More Skill Points"}),
          i18n({"全部经验时可以点满技能，技能组解禁，遗忘技能点功能等", "Can activate all skills finally,All characters unlock Moon Shadow"}), -6, nil, nil, -16,
          {"", i18n({"开荒时最多可有部分技能点", "New Game Start with x skill points"})}, nil, {enabletext, 0}),
     item("wilson_easy", i18n({"󰀰 威尔逊总开关", "󰀰 Wilson Switch"})),
     item("Wilson 1 Science Bonus", i18n({"威尔逊掌握科学机器科技", "Wilson Has 1 Science Bonus"})),
     item("Wilson Right Dodge", i18n({"威尔逊右键冲刺", "Wilson Right Dodge"}), i18n({"默认1秒CD", "Default 1s cd"}), 1, 0.5, 6, 0.5),
     item("Wilson Right Self Everything Encyclopedia", i18n({"威尔逊右键自身施放万物百科", "Wilson Right Self Everything Encyclopedia"}),
          i18n({"默认30秒CD", "Default 30s cd"}), 30, 10, 240, 10),
     item("ctrl disable right", i18n({"右键动作按Ctrl低优先", "Press Ctrl Right Low priority"}), i18n(
          {"按住Ctrl时,角色原自带右键动作优先,为爽右键动作禁用或低优先", "When Press Ctrl,right action of the mod has lower priority"})),
     item("right self need ctrl", i18n({"右键自身动作需按Ctrl", "Press Ctrl Right Self"}),
          i18n({"按住Ctrl时,才能释放为爽右键自身动作,防止误触", "Unless Press Ctrl,disable right self action of the mod"}), false),
     item("All Right Dodge", i18n({"全员右键冲刺", "All Right Dodge"}),
          i18n({"娱乐选项;需关闭其他角色的右键动作否则无效;默认1秒CD", "FOR FUN;Default 1s cd"}), false, 0.5, 6, 0.5),
     item("willow_easy", i18n({"󰀈 薇洛总开关", "󰀈 Willow Willowwitch"})),
     item("Willow Attack Dry/Burning Enemy", i18n({"薇洛狂热发光增伤", "Willow Attack Dry/Burning Enemy"}),
          i18n({"对潮湿冰冻/干燥/燃烧伤害为1/1.25/1.5且刷新狂热", "1/1.25/1.5x;Burning Frenzy/Bernie Battle Refresh"})),
     item("Willow SkillTree", i18n({"薇洛技能树优化", "Willow skilltree optimization"}), 
          i18n({"薇洛部分技能优化","Willow skilltree optimization"})),
     item("Willow Right Self Pyrokinetics Explained", i18n({"薇洛右键自身吸火控火", "Willow Right Self Pyrokinetics Explained"}),
          i18n({"默认3秒CD,薇洛200理智,余烬无限堆叠", "Default 3s cd,willow 200 sanity,Embers Unlimit stackable"}), 3, 3, 30, 3),
     item("Willow Fire Weapon Attack", i18n({"薇洛火焰武器增强效果", "Willow's Fire Weapon"}),
          i18n({"微洛切换火把打火机后仍有火焰,火焰笔火魔杖弹药改动", "Willow use torch/fire staff stronger"})),
     item("wolfgang_easy", i18n({"󰀙 沃尔夫冈总开关", "󰀙 Wolfgang Switch"})),
     item("Wolfgang break Powerup/down", i18n({"沃尔夫冈战斗时打断变身", "Wolfgang break Powerup/down"})),
     item("Wolfgang Strong Battle Speedup", i18n({"沃尔夫冈强壮时战斗加速", "Wolfgang Mighty Battle Speedup"}),
          i18n({"25%,8秒,且脱战饥饿速率降低(妥协模组后者无效)", "25%,8s,and leave battle hunger slow(UM Mod Unless)"})),
     item("Wolfgang Eat Food For Mightiness", i18n({"沃尔夫冈吃食物增加力量值", "Wolfgang Eat Food For Mightiness"}),
          i18n({"默认食物饥饿值的35%", "Default 35% hunger of food"}), 0.35, 0.5, 0.05, -0.05),
     item("Wolfgang Pause Drain When Satiated", i18n({"沃尔夫冈吃饱时不掉力量值", "Wolfgang Pause Drain When Satiated"}),
          i18n({"饥饿值高于100时不掉力量值,妥协模组无效", " Not drop when hunger value is higher than 100,UM Mod Unless"}), 100, 50, 150, 10),
     item("Wolfgang Eat Potato Buff", i18n({"沃尔夫冈吃土豆获得更多回复", "Wolfgang likes potatoes"}),
          i18n({"沃尔夫冈吃土豆（料理）更多属性加成，妥协开启时额外回复精神", "Wolfgang eats potatoes to get more replies"})),
     item("All dumbbell heat", i18n({"全员热铃", "dumbbell_heat for all"}),
          i18n({"所有人都可以制作热铃,但是会修改热铃配方.我们觉得使用热铃是懦弱的表现", "everyone can craft dumbbell_heat but modify its recipe"}), false),
     item("wendy_easy", i18n({"󰀜 温蒂总开关", "󰀜 Wendy Switch"})),
     item("Abigail Level Protect", i18n({"阿比盖尔等级保护", "Abigail Level Protect"}),
          i18n({"温蒂死亡姐姐不降级但困难模式持续降级;姐姐死亡降1级", "Wendy Death not delevel Abigail but hard slow delevel"})),
     item("Wendy Normal Attack Damage", i18n({"温蒂正常倍率", "Wendy Normal Attack Damage"}),
          i18n({"温蒂1.0伤害倍率，困难模式不生效", "Wendy 1.0x damage,hardmode not work"})),
     item("Wendy Share Debuff From Abigail", i18n({"温蒂共享阿比盖尔buff", "Wendy share Abigail buff"}), i18n({"温蒂共享光源，获得攻击防护buff","wendy share abigail buff"}),
          i18n({"温蒂共享光源，获得攻击防护buff", "Wendy share light and get attack buff"})),
     item("Wendy SkillTree", i18n({"温蒂技能树优化", "Wendy Strength"}), i18n({"温蒂部分技能优化","wendy strength"})),
     item("wx78_easy", i18n({"󰀔 WX-78总开关", "󰀔 WX-78 Switch"})),
     item("WX-78 Safe Remove Module", i18n({"WX-78拆电路板无损耗", "WX-78 Safe Remove Module"})),
     item("WX-78 Integrated Upgrade Module Level", i18n({"WX-78同种电路板融合升级", "WX-78 Integrated Upgrade Module Level"}),
          i18n({"同一个电路板最多发挥Max格插脚能力,最高3级，生物数据修理", "The same circuit can have up to max pins,maxleval 3, repair with Bio Data"})),
     item("WX-78 Eat Gears InCrease Data", i18n({"WX-78吃齿轮增加三维", "WX-78 Eat Gears Upgrade Self"}),
          i18n({"单个三维各加5点,增加15个;死亡恢复", "Per gear for 5 hunger/sanity/health,max 75.Recovery after death"})),
     item("WX-78 Circuit Enhancement", i18n({"WX-78电路增强", "WX-78 Circuit Enhancement"}), 
          i18n({"豆增压血量回复速度翻倍，血san上限均加，电气化过载"," Doubling bee module health recovery,  taser module overload"})),
     item("wickerbottom_easy", i18n({"󰀏 薇克巴顿总开关", "󰀏 Wickerbottom Switch"})),
     item("Wickerbottom Is Not Insomniac", i18n({"薇克巴顿正常休息", "Wickerbottom Sleep In Tent"}),
          i18n({"可以进帐篷睡觉,但仍免疫外界催眠", "Can sleep into tent but still avoid hypnosis"})),
     item("Wickerbottom No Sanity Dapperness", i18n({"薇克巴顿更难降低理智", "Wickerbottom No Sanity Dapperness"}),
          i18n({"免疫黑暗怪物装备掉理智", "Immune to dark,monster or equipment"})),
     item("Wickerbottom Read Book Less Use", i18n({"薇克巴顿读书消耗更少耐久", "Wickerbottom Read Book Less Use"}),
          i18n({"理智越高,消耗耐久越少,满理智消耗0.35次", "Higher sanity, use less durability, 0.35 times when full sanity"})),
     item("Wickerbottom Use Staff", i18n({"薇克巴顿冰火魔杖施法", "Wickerbottom Red/Blue Staff"}),
          i18n({"冰魔杖造冰刺,火魔杖造火球", "Use Red/Blue Staff Spell"})),
     item("Wickerbottom Daily Book", i18n({"薇克巴顿右键自身书柜", "Wickerbottom Right Self Bookcase"}),
          i18n({"书柜每日一本免费魔法书,且随种类提高科技", "Every Day get a magic book short exist and update tech with books"})),
     item("Wickerbottom Book Buff", i18n({"薇克巴顿书籍增强", "Wickerbottom Book Buff"}), 
          i18n({"控温学维持体温和100%防水4分钟，控火术消除妥协浓烟","temprature maintains and 100% waterproof for 4min, fire control eliminates UM smoke."})),
     item("woodie_easy", i18n({"󰀎 伍迪总开关", "󰀎 Woodie Switch"})),
     item("Woodie Eat Raw Meat", i18n({"伍迪可以吃生肉", "Woodie Can Eat Raw Meat"})),
     item("Woodie Hunger Wereness", i18n({"伍迪变身值使用饥饿值", "Woodie Hunger Wereness"}),
          i18n({"变身改用饥饿值,变身1.75倍饥饿速率", "Woodie use Hunger as wereness, 1.75* hunger rate"})),
     item("Kitschy Idol Need Less Materials", i18n({"俗气雕像配方材料减少", "Kitschy Idol Need Less Materials"}),
          i18n({"海狸像怪物肉消耗减少2；鹅像怪物肉和种子消耗减少1", "Beaver Idol monster meat -2;Beaver Idol monster meat/seed -1"})),
     item("Woodie Right Self Close Transform", i18n({"伍迪右键自身结束变身", "Woodie Right Self Close Transform"})),
     item("Woodie Moose Stronger Charge", i18n({"伍迪鹿人更猛烈地冲撞", "Woodie Moose Stronger Charge"}),
          i18n({"撞碎路途上的一切树木;移速加快", "Smash all the trees on the road;Move Faster"})),
     item("Woodie SkillTree", i18n({"伍迪技能树增强", "Woodie Better Skilltree"}),
          i18n({"更加强力的技能树效果", "Even more powerful skilltree"})),
     item("wes_easy", i18n({"󰀕 韦斯总开关", "󰀕 Wes Switch"})),
     item("Wes Normal Data Attack Work", i18n({"韦斯正常三维攻击伤害工作效率", "Wes Normal Data Attack Work"})),
     item("Wes Right Dodge Collide Balloon", i18n({"韦斯连续右键冲刺", "Wes Right Dodge Double"}), i18n({"默认2秒CD", "Default 2s cd"}), 2, 1, 10, 0.5),
     item("Balloon Stackable Per 50 Damage", i18n({"气球伤害50堆叠10", "Balloon Stackable Per 50 Damage"}),
          i18n({"对玩家依旧5点伤害,廉价火药;堆叠气球缠绕敌人", "Still 5 damage for player;max stack size 10;>=5 balloons can slow enermy"})),
     item("Equip Balloon Increase Speed", i18n({"气球装备增加移速和耐久", "Equip Balloon Increase Speed"}),
          i18n({"全种类气球装备有1.1倍移速加成和至少2天耐久", "Each balloon equipment lasts for 2 days with an additional speed of 1.1x"})),
     item("Equip Balloon Summon Tornado", i18n({"气球装备制造旋风", "Equip Balloon Summon Tornado"}),
          i18n({"挨打不伤己会反击旋风;旋风不损坏建筑", "Attacked not hurt and tornado don't destory structure"})),
     item("waxwell_easy", i18n({"󰀖 麦斯威尔总开关", "󰀖 Maxwell Switch"})),
     item("Maxwell Normal Health", i18n({"麦斯威尔150生命值", "Maxwell Has 150 Health"}),
          i18n({"麦斯威尔150点生命值", "Maxwell Has 150 Health"})),
     item("Maxwell Eat Petals Get Dark Petals", i18n({"麦斯威尔吃花瓣时获得恶魔花瓣", "Maxwell Eat Petals Get Dark Petals"}), false),
     item("Maxwell Unlock Dark Sword/Armor", i18n({"麦斯威尔解锁暗夜剑暗夜甲", "Maxwell Unlock Night Sword/Armor"})),
     item("Maxwell Right Lunge", i18n({"麦斯威尔右键闪袭", "Maxwell Right Lunge"}),
          i18n({"需要暗影等级不小于4,AOE伤害,6秒CD", "Need Shadow Level >= 4,aoe attack,6s cd"})),
     item("right Lunge need ctrl", i18n({"右键闪袭需要按住Ctrl", "Maxwell Lunge Need Press Ctrl"}),
          i18n({"按住Ctrl时,才能释放为爽右键闪袭动作,防止误触", "Unless Press Ctrl,disable right Lunge action"}), false),
     item("Maxwell Attacked Disappear", i18n({"麦斯威尔受击无敌", "Maxwell Attacked Disappear"}),
          i18n({"需要暗影等级不小于4,8~28秒CD", "Need Shadow Level >=4, 8~28s cd"})),
     item("Maxwell Right Self Sleepytime Stories", i18n({"麦斯威尔右键自身施放睡前故事", "Maxwell Right Self Sleepytime Stories"}),
          i18n({"默认30秒CD", "Default 30s cd"}), 30, 10, 120, 10),
     item("Maxwell removes UM nerf", i18n({"麦斯威尔移除不妥协削弱", "Maxwell Remove UM nerf"}),
          i18n({"移除暗影仆从承受伤害，存在时间，理智消耗削弱", "Remove Shadow Minion Take Damage,Exist Time,Sanity Cost nerf"})),
     item("wigfrid_easy", i18n({"󰀘 薇格弗德总开关", "󰀘 Wigfrid Switch"})),
     item("Wigfrid Inspiration Not Drop", i18n({"薇格弗德激励值脱战不掉落", "Wigfrid Inspiration Not Drop"}),
          i18n({"饥饿值和武器耐久增强", "DURABILITY/FIRE_RESIST Upgrade"})),
     item("Wigfrid Ride Right Dodge", i18n({"薇格弗德骑乘时右键冲刺", "Wigfrid Ride Right Dodge"}), 
          i18n({"默认1.5秒CD", "Default 1.5s cd"}), 1.5, 0.5, 6, 0.5),
     item("Wigfrid Right Self Reprise", i18n({"薇格弗德右键自己战士重奏", "Wigfrid Right Self Warrior's Reprise"}),
          i18n({"战士重奏复活队友,后续能力会短暂覆盖", "Warrior's Reprise Revive Player,later option will short override"})),
     item("Rude Interlude Provide Battle Helm", i18n({"粗鲁插曲提供全员头盔耐久", "Rude Interlude Provide Battle Helm"}),
          i18n({"吟唱粗鲁插曲12秒内右键自己重奏触发", "right self in 12s after Sing Rude Interlude"})),
     item("Startling Soliloquy Provide Battle Spear", i18n({"惊心独白提供全员武器耐久", "Startling Soliloquy Provide Battle Spear"}),
          i18n({"吟唱惊心独白12秒内右键自己重奏触发", "right self in 12s after Sing Startling Soliloquy"})),
     item("aoespell change", i18n({"矛盾右键动作改进", "Spear/Shield Straight Right"})),
     item("Sprint without moving forward",i18n({"武神奔雷耐久增加攻击返还cd","Sprint without moving forward"})),
     item("webber_easy", i18n({"󰀗 韦伯总开关", "󰀗 Webber Switch"})),
     item("Webber Eat Meat Lead Wild Spider", i18n({"韦伯吃肉食收买附近蜘蛛", "Webber Eat Meat Lead Wild Spider"}),
          i18n({"饥饿>102消耗3额外收买1直至100饥饿;随从不吃地面食物且跟随灵魂", "Hunger > 105 consumes 6 extra buys 1 to 100 hunger"})),
     item("Webber Eat Switcherdoodle Switch Spider", i18n({"韦伯吃涂鸦升级黑蜘蛛随从", "Webber Eat Switcherdoodle Switch Spider"}),
          i18n({"饥饿>124时消耗25额外升级1直至100饥饿", "Hunger > 124 costs 25 extra upgrade 1 to 100 hunger"})),
     item("Webber Murder Spider Get Switcherdoodle", i18n({"韦伯谋杀非黑蜘蛛时获得涂鸦", "Webber Murder Spider Get Switcher doodle"}),
          i18n({"饥饿>149消耗x饥饿获得1个", "Hunger > 149 consumes x hunger to get one"}), 75, 50, 150, 25),
     item("Webber Right Self Overcoming Arachnophobia", i18n({"韦伯右键自身施放克服蛛形纲恐惧症", "Webber Right Self Overcoming Arachnophobia"}),
          i18n({"默认15秒CD,韦伯200理智", "Default 15s cd,webber 200 sanity"}), 15, 5, 60, 5),
     item("Webber Uprade SpiderDen SpiderQueen", i18n({"韦伯升级三级蜘蛛巢为女王", "Webber Uprade SpiderDen SpiderQueen"}),
          i18n({"但困难模式蜘蛛巢改为需要给食物升级了", "Hard mode spider den replace give food to upgrade"})),
     item("Spider Help Work", i18n({"蜘蛛协助工作", "Spider Help Work"})),
     item("Hat Trick", i18n({"帽子戏法", "Hat Trick"}),
          i18n({"戴上帽子  目前 仅限韦伯", "just put on your hat . only for webber now"})),
     item("winona_easy", i18n({"󰀌 薇诺娜总开关", "󰀌 Winona Switch"})),
     item("Winona No Hungry Builder", i18n({"薇诺娜制作不再受饥饿值影响", "Winona No Hungry Builder"})),
     item("Winona Hammer Drop All Loot", i18n({"薇诺娜敲掉建筑获得全部材料", "Winona Hammer Drop All Loot"})),
     item("Winona Rotating Weapon Perpetual Attack", i18n({"薇诺娜右键旋转武器", "Winona Right Rotating Weapon"}),
          i18n({"旋转闪避,2秒CD,2.5秒1.5倍伤害和5秒1.33倍加速", "short invincible,2.5s 1.5x damage,5s 1.33x speed,2s CD"})),
     item("Winona Control Chess", i18n({"薇诺娜控制发条看守", "Winona Control Chess"}),
          i18n({"薇诺娜可以令发条随从看守当前位置", "Winona Control Chess Save Current Pos As Spawn Pos"})),
     item("Winona Right Self Hide Structures", i18n({"薇诺娜右键自身折叠建设", "Winona Right Self Hide Structures"}),
          i18n({"默认15秒CD", "Default 15s cd"}), 15, 5, 60, 5),
     item("warly_easy", i18n({"󰀨 沃利总开关", "󰀨 Warly Switch"})),
     item("Warly Double Personal Buff Time", i18n({"沃利专属buff时长翻倍", "Warly Eat Food Double effect"}),
          i18n({"专属菜肴和调味料理的buff时长翻倍；困难模式其余角色buff时间减半", "Warly's Special Dish and Seasoning Food Buff Time Double;Hardmode Other Role Buff Time Halved"})),
     item("Wally Salt Seasoning Double Freshness", i18n({"沃利盐调味料理双倍保鲜", "Warly Salt Seasoning Double Freshness"}),
          i18n({"盐调味后的料理获得两倍保质期", "Salt Seasoning Food Freshness Double"})),
     item("Warly Balanced Food", i18n({"沃利更强消化系统", "Warly Balanced Food"}),
          i18n({"沃利吃菜1.5倍回血，0.5倍扣血，重复食物仅理智惩罚，收集食谱减少惩罚;", "Warly Eat Veggie Heal 2x,Half Hurt,Repeat Food Only Sanity Penalty,Collect Recipes Reduce Penalty"})),
     item("Warly Use Perishable Weapon", i18n({"沃利使用新鲜度武器增伤", "Warly Use Perishable Weapon"}),
          i18n({"新鲜度1.25/1.0/0.75倍伤害", "More fresh more damage,1.25/1.0/0.75x damage"})),
     item("Warly Right Self Cook", i18n({"沃利右键自身便携烹饪", "Warly Right Self Open Cookpot"}),
          i18n({"沃利右键自身打开便携烹饪锅;困难模式不自带锅", "Warly Right Self Open a portable Cookpot"})),
     item("Warly Free Cook Per Day", i18n({"沃利烹饪返还食材", "Warly Cook Not Consume"}), 
          i18n({"沃利每天首次烹饪返还首个食材,困难模式50%概率返还次格", "Warly First Cook don't consume first or second Ingredient Every Day"})),
     item("walter_easy", i18n({"󰀤 沃尔特总开关", "󰀤 Walter Switch"})),     
     item("Walter No Damage Lose Sanity", i18n({"沃尔特受伤害时不再损失理智", "Walter No Damage Lose Sanity"}),
          i18n({"理智险境开启时仍受险境掉SAN影响", "Still affected when Sanity Danger is on"})),
     item("Walter Item Upgrade", i18n({"沃尔特专属道具增强", "Walter's Item Upgrade"}),
          i18n({"便携帐篷兔毛卷功能，便携火堆所有人可用且燃烧更久", "Portable Tent Rabbit Roll Function,Portable Campfire can be used by all and burn longer"})),
     item("Walter Has Other Pet", i18n({"沃尔特正常领养宠物", "Walter Can Has Pet"}),
          i18n({"四本暗影傀儡需要此项;且妥协沃比吃肉", "So he can normal use shadow magic"})),
     item("Walter Throw Slingshot First Attack", i18n({"沃尔特弹弓攻击优化", "Walter Slingshot Attack Fix"}),
          i18n({"兼容妥协勋章;困难模式沃尔特妥协蓄力连发伤害削弱", "UM/Medal Mod support walter Force Enable Slingshot"}), true, nil, nil,
          -1, {
          i18n({"wixie同沃尔特,仅空手可击退", "wixie only no handsitem can attack knock far enrmy"}),
          i18n({"普通攻击前扔接弹弓,4.5秒内2倍伤害", "Throw Slingshot Before Simple Attack;4.5s 2x damage"})
     }),
     item("Walter Ride Better", i18n({"骑乘沃比获得保护", "Better Safe Big Woby Mount"}),
          i18n({"沃比帮助闪避敌人攻击;沃尔特摔下时暂时无敌", "Big Woby Protect Walter When Ride"})),
     item("wortox_easy", i18n({"󰀀 沃拓克斯总开关", "󰀀 Wortox Switch"})),
     item("Wortox Eat Food Normal", i18n({"沃拓克斯吃食物获得75%三维", "Wortox Eat Food 75% H/S/H"})),    
     item("Wortox Free Blink", i18n({"沃拓克斯免费灵魂跳跃", "Wortox Free Blink"}),
          i18n({"灵魂回声时间延长，携带小于10个灵魂时第一段灵魂回声结束不消耗灵魂", "Wortox Soul Echo Time Extended,First Soul Echo End Without Consume Soul When Carry Less Than 10 Souls"})),
     item("Wortox No Drop Soul", i18n({"沃拓克斯死亡不掉落灵魂", "Don't Drop when death"}),
          i18n({"死亡不掉落灵魂", "Don't Drop when death"})),
     item("Wortox Use Soul Attack", i18n({"沃拓克斯的灵魂飞弹", "Wortox Use Soul Attack"})),
     item("Wortox damage upgrade", i18n({"沃拓克斯三维高时增伤", "Wortox Upgrade Damage"}),
          i18n({"三维均高于75%时获得25%增伤)", "When Hunger/Health/Sanity all above 75%, damage is increased by 25%"})),
     item("Wortox SkillTree", i18n({"沃拓克斯技能树优化", "Wortox skilltree optimization"}), 
          i18n({"灵魂飞弹穿刺，好孩子淘气包兼容，灵魂罐不泄露","Soul Missile Piercing, Good Boy Naughty Boy Compatible, Soul Jar Does Not Leak"})),
     item("Wortox Extra Soul Drop", i18n({"沃拓克斯高血量生物额外掉落灵魂", "Wortox Extra Soul Drop from High Health Creatures"}),
          i18n({"血量大于100/500/1000的生物分别有10%/30%/50%概率额外掉落灵魂", "Creatures with health > 100/500/1000 have 10%/30%/50% chance to drop extra souls"})),
     item("wormwood_easy", i18n({"󰀇 沃姆伍德总开关", "󰀇 Wormwood Switch"})),
     item("Wormwood Eat Food 50% Health", i18n({"沃姆伍德吃食物获得50%生命", "Wormwood Eat Food 50% Health"})),
     item("Wormwood Right Self To Hide", i18n({"沃姆伍德右键自身隐藏休憩", "Wormwood Right Self To Hide/Rest"})),
     item("Wormwood Regrow Farm Plant", i18n({"沃姆伍德采集农作物再生", "Wormwood Regrow Farm Plant"}),
          i18n({"困难模式需要高级耕作先驱帽", "Hard mode need Premier Gardeneer Hat"})),
     item("Wormwood TendTo Farm Plant Reduce Grow Time", i18n({"沃姆伍德生长中安抚植物减少生长时间", "Wormwood TendTo Farm Plant Reduce Grow Time with bloomness"})),
     item("Wormwood Soul Heal Soil", i18n({"沃姆伍德灵魂治愈地裂", "Wormwood Soul Heal Soil"})),
     item("Wormwood Photosynthesis", i18n({"沃姆伍德白天进行光合作用", "Wormwood Photosynthesis in day"}), 
          i18n({"沃姆伍德白天进行光合作用,恢复san值", "Wormwood Photosynthesis in day，recover sanity"})),
     item("Wormwood Eat Rewards Equip", i18n({"沃姆伍德吃食物获得装备", "Wormwood Eat Rewards Equip"}),
          i18n({"概率,苔藓骨头头盔,种子耕作帽,果蔬获得种子,石果蘑菇等...", "Fruits/Veggies give seeds,Seeds Give Gardeneer Hat..."})),
     item("Wormwood Eat Seeds Debuff",i18n({"沃姆伍德吃杂草能获得buff","Wormuwood have buff"}), 
          i18n({"沃姆伍德吃杂草能获得buff","Wormuwood have buff"}), false),
     item("Wormwood Thorns Generate Spiny Bindweed",i18n({"荆棘陷阱触发时触发刺藤","citeng"})),
     item("wurt_easy", i18n({"󰀐 沃特总开关", "󰀐 Wurt Switch"})),
     item("Wurt Eat Food Lead Wild Merm", i18n({"沃特吃食物收买附近鱼人", "Wurt Eat Food Lead Wild Merm"}),
          i18n({"饥饿>101消耗2额外收买1直至100饥饿", "Hunger > 102 consumes 3 extra buys 1 to 100 hunger"})),
     item("Wurt Eat Food Loyalty Follower", i18n({"沃特吃食物提高鱼人随从忠诚", "Wurt Eat Food Loyalty Follower"}),
          i18n({"饥饿>151消耗2额外延长1直至100饥饿", "Hunger > 152 consumes 3 extra and prolongs 1 to 100 hunger"})),
     item("Mermking Won't Hungry", i18n({"鱼人王不再饥饿", "Mermking Won't Hungry"})),
     item("Trade Fish with Merm", i18n({"和普通鱼人交易海鱼", "Trade Fish with Merm"}),
          i18n({"每天首次就像鱼人王一样;可给武器", "Once A day like mermking;Give Weapon"})),
     item("wanda_easy", i18n({"󰀱 旺达总开关", "󰀱 Wanda Switch"})),
     item("Wanda Don't Auto Drop Age", i18n({"旺达不再持续衰老", "Wanda Don't Auto Drop Age"})),
     item("Ageless Watch Help Temperature", i18n({"不老表恢复温度", "Ageless Watch Temperature Help"})),
     item("Wanda removes UM nerf", i18n({"旺达移除不妥协削弱", "Wanda removes UM nerf"}),
          i18n({"去除暗影生物额外伤害，警告表伤害削弱，二次机会表削弱", "Wanda Remove UM nerf"})),
     item("wanda Eat Petals Get Dark Petals", i18n({"旺达吃花瓣时获得恶魔花瓣", "wanda Eat Petals Get Dark Petals"})),
     item("Wanda Right Wrapback", i18n({"旺达右键倒走", "Wanda Right Warpback"})),
     item("Wanda Right Wrapfront", i18n({"旺达右键未来行走", "Wanda Right Warpfront"}), i18n({"娱乐选项", "FOR FUN"}), false, 2, 20, 1),
     item("right Wrapback need ctrl", i18n({"右键倒走需要按住Ctrl", "Warpback Need Press Ctrl"}),
          i18n({"按住Ctrl时,才能释放为爽右键倒走动作,防止误触", "Unless Press Ctrl,disable right Warpback action"}), false),
     item("Wanda Right Self Backtrek", i18n({"旺达右键自身裂缝表", "Wanda Right Self Rift Watch"})),
     item("Wanda Resurrect Self", i18n({"旺达按钮复活自己", "Wanda Button Resurrect Self"}), i18n(
          {"旺达死亡时世界不重置,右上角按钮复活自己(有CD)", "Wanda death stop world reset,right top button resurrect self(has cooldown)"}),
          true, nil, nil, -1,
          {i18n({"仅旺达有此复活按钮", "Only Wanda Has The Button"}), i18n({"全角色都有此复活按钮", "All Roles Has The Ability"})}),
     item("whoever_easy", i18n({"󰀖 其余角色总开关", "󰀖 Other Character Switch"})),     
     item("Wathom upgrade", i18n({"沃托姆饥饿受伤调整", "Wathom Hunger/TakeDamge Update"}),
          i18n({"妥协沃托姆饥饿150;额外受伤40%, 护甲不额外受伤, 攻击获得肾上腺素", "Wathom Hunger 150;Extra 40% damage taken,Armor no extra damage taken,Attack get adrenaline"})),
     item("Monster_characters_night_vision", i18n({"怪物角色获得夜视", "Monster characters get night vision"}),
          i18n({"沃特，韦伯，沃托姆，闪闪获得夜视和滤镜", "Walter,Webber,Wathom,Winky get night vision and filter"})),
     item("Start With Wonkey Disable Transform", i18n({"芜猴开局可选", "Start With Wonkey"}),
          i18n({"诅咒饰品不再导致变身", "Disable accursed trinket transform"})),
     item("Wonkey Run Wait Time", i18n({"芜猴助跑时间缩短", "Wonkey Run Wait Shorter Time"}),
          i18n({"默认步行1秒后奔跑,且奔跑无额外饥饿消耗", "Run Wait N Seconds,and run no extra consume hunger"}), 1, 0.5, 5, 0.5),
     item("Wonkey Right Self summon the powder_monkey", i18n({"海棠小分队", "powder_monkey team"}), 
          i18n({"芜猴右键自身召唤海棠小分队作战", "Wonkey Right Self summon the powder_monkey to fight for you"}), false),
     item("Wonkey Night Version", i18n({"芜猴夜视微光", "Wonkey Has Night Version"})),
     item("Wonkey Attack Steal item", i18n({"芜猴攻击偷取物品", "Wonkey Attack Steal item"})),
     item("Wonkey Toss Poop", i18n({"芜猴投掷便便", "Wonkey Toss Poop"})),
     item("Wonkey Remove Curse", i18n({"芜猴免疫诅咒饰品", "Wonkey Immuned to Curse"})),
     item("Role Gym", i18n({"全员健身房健身", "All Mighty Gym"}), i18n({" ", " Only Mighty Gym can update mightyness"}), true, nil, nil, -1, {
          i18n({"自带倍率的角色健身后获得1.25倍伤害buff,无自带倍率的角色健身后获得1.5倍伤害buff。", "Characters with multipliers gain 1.25x damage after fitness, others will gain 1.5x"}),
          i18n({"全员可制作健身房", "All roles can make Mighty Gym"})
     }),
     item("avoidselfdmg", i18n({"自伤避免", "Avoid Self Attack"}),
          i18n({"玩家对自己的无武器攻击不再有伤害了", "player attack self dmg is 0 unless weapon"})),
     item("entergift upgrade", i18n({"初始礼物升级", "Enter Gift Upgrade"}),
          i18n({"提供更多的首次进入礼物,受其他设置影响", "provide more gift for new player, effect by other config"})),
     spaceitem(),
     headeritem(i18n({"󰀕 困难模式" .. filllabel(11), "󰀕 Hard Mode" .. filllabel(12)})),
     headeritem(i18n({"角色改动", "Charaters"})),
     item("role_nerf", i18n({"困难模式角色改动总开关", "Switch for Charaters of Hard Mode"})),
     item("role_battle", i18n({"生存险境", "Danger Health"}), i18n(
          {
               "掉血配方掉一半黑血;治疗道具溢出时恢复黑血;强心针需血囊",
               "craft munu has half health penalty;Heal Item can heal some penalty"
          }), -1, -1, -2, -1,
          {i18n({"承受伤害+20%,回血-20%", "+20% damage taken, heal-20%"}), i18n({"承受伤害+33%,回血-33%", "+33% damage taken, heal -33%"})}),
     item("role_sanity", i18n({"理智险境", "Danger Sanity"}), i18n(
          {"掉血时按比例掉理智,不会掉到血量比下;重复单位增益理智光环取最大", "lose sanity when damaged (From Walter) and overeat"}),
          -2, -1, -2, -1, {
          i18n({"掉血时掉一半理智,吃撑掉一半溢出理智", "lose 0.5x sanity when damaged and overeat"}),
          i18n({"掉血时掉同样理智,吃撑掉一半溢出理智", "lose 1x/0.5x sanity when damaged and overeat"})
     }),
     item("role_hunger", i18n({"饥饿险境", "Danger Hunger"}), i18n({
          "饥饿死亡有饥饿上限惩罚,肉海带种子干/新鲜回血食物/强心针(需蛙腿,效能翻倍)恢复",
          "Hunger Has Penalty.Eat Dried/Fresh Health Food or Booster Shot to Heal"
     })),
     item("combat", i18n({"战斗险境", "Combat Reduce"}),
          i18n({"检查拳击袋,开关攻击伤害信息显示", "inspect Punching Bag open/close dmg status display"}), true, nil, nil, -1, {
          i18n({"使用原版机制，增益伤害全部乘算", "Original,not change"}),
          i18n({
               "角色伤害增益从乘算改成取最大,其余减半加算且上限至最大",
               "Damage Rate Change From multiply Into GetMax and part additive"
          })
     }, nil, {leftparttext, enabletext}),
     item("pvp_force", i18n({"友伤险境", "Betrayed Friends"}),
          i18n({"玩家无法互相攻击，但道具和随从仍可能误伤", "Players maybe attacked by mates' tools and followers"})),
     item("leader", i18n({"领袖险境", "Leader Limit"}),
          i18n({"玩家最多有x个有血量和攻击力的重复随从;超过则旧随从离开", "Max GroundHealthCombatRepeatFollower Number"}), 10, 8, 40, 1),
     item("haitang_curse_2", i18n({"海棠语险境", "speak like haitang"}), i18n({"诅咒会导致你炫耀自己的半吊子海棠语", "curse make you say money words"})),
     item("soul_wild", i18n({"魂游荒野", "Soul Wilderness"}), i18n({
          "灵魂有血怕太阳,作祟可灭火;灵魂死亡则大门/荒野忘却配方地图再生",
          "Soul can stop fires, has Health and will death to regate because sun or haunt"
     })),
     item("death_curse", i18n({"再生之殇", "Body Revive"}),
          i18n({"玩家复活后获得4分钟微光诅咒占位装备)", "Players revive will get a light curse equip for 4 mins"}), true, nil, nil, -1,
          {i18n({"玩家死亡后回档若活着也会诅咒", "Rollback also get"}), i18n({"禁用回档惩罚", "Disable Rollback Curse"})}),
     item("willow", i18n({"薇洛", "Willow"}),
          i18n({"薇洛理智黑化;潮湿伯尼受到额外伤害", "Willow sanity penalty;Wet bernie will take extra damage"})),
     item("wolfgang", i18n({"沃尔夫冈", "Wolfgang"}),
          i18n({"强壮1.75倍饥饿消耗;50力量变正常;妥协无效", "players too less will low dmg;mighty 1.75x hunger"})),
     item("wendy", i18n({"温蒂", "Wendy"}),
          i18n({"阿比盖尔收回无成长,成长和回血变慢,低温-20怕热50", "Abigail grow need out,regen/grow slower,is low temp/-20,scare hot/50"})),
     item("wx-78", i18n({"WX-78", "WX-78"}), i18n(
          {"妥协芯片削弱;超载非三维电路增加饥饿消耗;插拔电路不刷三维", "Hunger rate increase because over-flowing not 3var module"})),
     item("wickerbottom", i18n({"薇克巴顿", "Wickerbottom"}),
          i18n({"书籍耐久2次,书柜放书升级回复变慢，读书消耗材料", "Book durability 2 times,Bookcase upgrade slower,Read book consume material"})),
     item("woodie", i18n({"吴迪", "Woodie"}), 
          i18n({"变身成本增加;不能通过吃怪物肉变身", "Transformation Needs Livinglog；Cannot transfrom with monstermeat"})),
     item("wigfrid", i18n({"薇格弗德", "Wigfrid"}), 
          i18n({"薇格弗德骑牛激励值削弱至原1/3,脱战后歌曲停下", "Wigfrid's ride inspiration reduce to 1/3,song will stop when leave battle"})),
     item("winona", i18n({"薇诺娜", "Winona"}), i18n({"技能树削弱", "skilltree nerf"})),
     item("walter", i18n({"沃尔特", "Walter"}),
          i18n({"弹弓蓄力时间变久;妥协鞭炮弹沙石弹加速弹削弱", "UM some ammoe weak;UM slingshot slow right attack"})),
     item("wortox", i18n({"沃拓克斯", "Wortox"}), i18n({"技能树改动及角色削弱", "skilltree rework and character nerf"})),
     item("wurt", i18n({"沃特", "Wurt"}), i18n({
          "鱼人王需要三叉戟,战斗鱼人虚弱正常三维刷新;鱼人死时小概率变青蛙",
          "Merm king needs trident, mermguard always genetate;Merm death little chance become frog"
     })),
     item("wanda", i18n({"旺达", "Wanda"}), i18n({"不老表蓝宝石;溯源表橙宝石;机会表绿宝石", "Watch need more gem"})),
     item("legion_shield", i18n({"盾牌无伤", "Reduce Legion Shield"}), i18n({
          "棱镜模组盾击动作不再反伤而是短暂提供盾反系数相关的伤害减免",
          "Right Shield action from Legion mod can't do damage but reduce hurt 2s"
     })),
     item("norunattack", i18n({"攻速调整", "Attack Speed"}), i18n({
          "玩家攻速匹配实际动画,打断后摇可行动但不能提早发动攻击",
          "Players' attack use actual anim frames,behind can move but attack earlier"
     }), 0, 0, 20, 1, i18n({"额外增加攻击间隔帧", "add extra attack interval frames?"})),
     item("delay_leave", i18n({"延迟下线", "Delay Leave"}), i18n(
          {
               "延迟下线X秒;期间上线会提示暂时不接受其的连接;请安全区下线",
               "When disconnect,role'll still exist Ns when Connect will block"
          }), 15, 5, 60, 5),
     headeritem(i18n({"天气改动", "Weather"})),
     item("weather_change", i18n({"困难模式天气改动总开关", "Switch for Weather of Hard Mode"})),
     item("temperature_change", i18n({"玩家温度", "Player Temperature"}), i18n({
          "玩家保暖隔热削弱;玩家冻伤热伤温度削弱;暖石偏向真实温度",
          "Players have extra thermal insulation;easy to cold or hot;heatrock use real temp"
     }), -1, -1, -2, -1, {"-240,5~65", "-480,10~60"}),
     item("dusk_change", i18n({"漫漫长夜", "Long Night"}), nil, true, nil, nil, -2, {
          i18n({"黄昏的大部分时间变成了黑夜", "Dusk will be shorter"}),
          i18n({"黄昏使用夜间光照,夜视不再安全,官方夜视增加照明", "dusk no light and danger night version"}),
          i18n({"黄昏使用夜间光照", "dusk no light"})
     }, nil, {enabletext, i18n({filldesc(4) .. "经典", filldesc(9) .. "Classical"}), i18n({filldesc(4) .. "经典", filldesc(9) .. "Classical"})}),
     item("moonlight", i18n({"启迪新月", "Full Moon Unlock"}),
          i18n({"天体启迪时月亮正常阴晴圆缺,此外", "MoonStorm Don't lock full Moon,and"}), -4, -1, -6, -1, {
          i18n({"夜间始终有光照", "Night Always Has Light"}),
          i18n({"夜间仅新月时无光照", "Only New Moon Night No Light"}),
          i18n({"夜间新月和凹月时无光照", "New or 1/4 Moon Night No Light"}),
          i18n({"夜间圆月和凸月时有光照", "Full or 3/4 Moon Night Has Light"}),
          i18n({"夜间仅圆月时有光照", "Only Full Moon Night Has Light"}),
          i18n({"夜间始终无光照,这很离谱", "Night Always No Light,Outrageous"})
     }),
     item("sandstorm", i18n({"沙漠风暴", "Sand Storm"}),
          i18n({"秋天有沙尘暴,秋天来临时必下雨", "Sandstorm/Antlion in autumn/spring"})),
     item("moonisland", i18n({"月岛流星", "Meteor Island"}),
          i18n({"月岛矿区流星雨,月圆有月亮风暴;星象探测仪抵挡月亮风暴", "Moonstorm and Mereors;Astral Detector Parry Moonstorm"}), true,
          nil, nil, -1, {
          i18n({"护目镜现在有种类了不能完全防范住所有风暴", "Goggles Hat now has types for different storm"}),
          i18n({"禁用护目镜种类机制", "Disable Goggles Hat Type"})
     }),
     item("random_seasons", i18n({"混乱之季", "Random Seasons"}),
          i18n({"混乱:至多连续两季节相同,恶劣混乱:较少秋季且可能始终相同", "Random Seasons"}), -3, -1, -5, -1, {
          i18n({"混乱但原版月亮风暴存在时不再混乱", "Random But stop when real moon storm exist"}),
          i18n({"仅原版月亮风暴存在时混乱", "Random Only when real moon storm exist"}),
          i18n({"仅原版月亮风暴存在时恶劣混乱", "Bad Random Only when real moon storm exist"}),
          i18n({"始终混乱且原版月亮风暴存在时恶劣混乱", "Random and bad random when real moon storm exist"}),
          i18n({"始终恶劣混乱", "Random and bad random always"})
     }),
     item("rain_change", i18n({"空气湿度", "Air humidity"}), i18n({
          "春/夏/秋/冬/洞穴湿度倍率;水球雨;潮湿度增加更快",
          "Season S/S/A/W and cave humidity magnification,3~6x moisture rate,waterstreak rain"
     }), -1, -1, -2, -1, {"8/0.5/1/8/4/2", "16/1/2/16/4/4"}),
     item("summer_change", i18n({"夏季风暴", "Summer Heat flow"}),
          i18n({"夏季沙尘暴会不定期来袭且会坠落道具", "Summer will has short sandstorm"})),
     item("winter_change", i18n({"冬季寒光", "Winter Cold Light"}),
          i18n({"用火焰热源驱散冬季黑夜的闪烁极光吧", "use fire/heat source dispell the cold staff"}), true, nil, nil, -1,
          {i18n({"像青蛙雨一样,下雪时概率下雪球雪", "Winter May have Snowball Snow"}), i18n({"禁用雪球雪", "Disable Snowball Snow"})}),
     item("autumn_change", i18n({"秋季复苏", "Autumn recovery"}), i18n({
          "非秋季档案馆插入三颗彩虹宝石时令世界进入秋季;仅1洞穴世界或独行长路不会触发",
          "Enters autumn when iridescent gems inserted non-autumn archives;Single Cave Won't"
     }), -3, -1, -3, -1, {
          i18n({"消耗0颗彩虹宝石", "consume 0 iridescent gem"}),
          i18n({"消耗1颗彩虹宝石", "consume 1 iridescent gem"}),
          i18n({"消耗3颗彩虹宝石并让世界月圆", "consume 3 iridescent gems,and enter fullmoon"})
     }),
     headeritem(i18n({"科技改动", "Prototyper"})),
     item("other_change", i18n({"困难模式科技改动总开关", "Switch for Prototyper of Hard Mode"})),
     --     item("prototyper_change", i18n({"原型科技", "Prototyper"}), i18n({
     --         "科级建筑需要更多材料,科技等级累加制变取最大;万物百科不解锁",
     --         "Science machine needs gears. Prestihatitator green gems, manipulator atrium,weak science level."
     --     }), -1, nil, nil, -1, {i18n({"禁用档案馆更难解密", "Harder Distilled Knowledge"}), i18n({"启用档案馆更难解密", "More science harder"})}),
     item("Harder Prototyper Recipe", i18n({"艰苦原型", "Prototyper"}),
          i18n({"科级建筑需要更多材料", "Science/Prestihatitator/manipulator needs gears/green gems/shadow atrium"})),
     item("Harder Prototyper Level", i18n({"科技求取", "Science"}),
          i18n({"万物百科不再提供解锁而是三次免费制作,最多制作更高1级的配方", "The Encyclopedia of Everything no longer provides unlocking but with 3 times of making, and can only produce recipes that are 1 level higher "})),
     item("Harder Distilled Knowledge", i18n({"档案严密", "Distilled Knowledge"}),
          i18n({"档案馆更难解密,额外两种解密", "Harder Distilled Knowledge.Now has extra two type."})),
     item("sleepingbag", i18n({"野营帐篷", "Sleep Locale"}), i18n(
          {"建筑类睡眠恢复50%下的状态,道具类睡眠恢复45%上的状态", "Sleep in structure can recover until 50%;Sleep by item recover from 45%"})),
     item("moonrockidol", i18n({"暗影之门", "Shadow Door"}), i18n({
          "大门月黑和猴岛门会暗影化需要彩虹宝石净化;月岩雕像现在需要彩虹宝石",
          "Two door will shadow and need shadow heart;Moon rock idol now need iredescent gem"
     }), true, nil, nil, -1, {
          i18n({"每玩家仅获得一次各角色初始物品", "Only get start inv once of per role"}),
          i18n({"禁用单次初始物品机制", "Disable once Start inv"})
     }),
     item("oceanlife", i18n({"冒险之海", "Secret Ocean"}), i18n({
          "夹夹绞盘需要8点好感度;海盗船住猴岛;海盗地图开出更多宝藏或给女王换图纸",
          "winch requires 9 favorability;More Pirate;Pirate Map give sunkenchest and ..."
     }), true, nil, nil, -1, {
          i18n({"沉底宝藏概率掉落传送魔杖三叉戟启迪之冠等", "Sunken treasure may drop tele staff,trident,enlightened crown..."}),
          i18n({"禁用船上火堆火焰从巨大变大会让船只冒烟", "disable:firepitfire on boat become big from verybig will smolder boat"})
     }),
     item("worldgen", i18n({"复杂地形", "New World"}), i18n({"地表和洞穴世界地形都会有改动", "World Layouts will be change"}), false, nil, nil,
          -6, {
          i18n({"随机级别的岛屿冒险化地表地形", "random level islands"}),
          i18n({"0级岛屿冒险,基本无新岛屿", "0 Level islands,should no new islands"}),
          i18n({"1级岛屿冒险,很少岛屿", "1 Level islands,little islands"}),
          i18n({"2级岛屿冒险,有些岛屿", "2 Level islands,has islands"}),
          i18n({"3级岛屿冒险,较多岛屿", "3 Level islands,some islands"}),
          i18n({"4级岛屿冒险,很多岛屿", "4 Level islands,many islands"}),
          i18n({"梦幻机碎群岛(地图会非常非常大)", "dreamly extremely broken islands (makes map huge and huge)"})
     }),
     item("moonbase_change", i18n({"月台守护", "Moon Stone"}), i18n(
          {"月台有1个发条;每一些天后或月圆时再生1个上限3个", "1/3 clockwork spawns near moon stone.Every some days or full moon regen 1"}),
          false),
     item("cave_entrance", i18n({"洞梯限行", "Cave entrance"}), i18n({
          "洞口楼梯限行月黑切换;灵魂可出入;洞口伪装但附近有蝙蝠",
          "Entrance/Exit lock unless player ghost;cave entrance hide but near bat"
     }), true, nil, nil, -1, {
          i18n({"2火药炸开洞口;懒人魔杖远古钥匙打开楼梯", "2 Gunpowder Down;Orange staff and Ancient Key up"}),
          i18n("禁用洞口伪装", "Disable hidden cave entrance by bat")
     }),
     item("ancient_statue", i18n({"远古雕像", "Ancient statue"}),
          i18n({"远古雕像镐击时会生成多种事件,最后一下需要斧镐", "Ancient statues generate many event;Final work need Tough"}), true, nil,
          nil, nil,
          i18n({"原版锤击远古科技的效果;敲坏时额外元素反应", "Original hammering effects of ancient pseudoscience;cast spells when broken"})),
     item("ancient_altar", i18n({"远古科技", "Ancient Pseudoscience"}), i18n({
          "暴动平静时间交换；远古塔是三四本，制作可能破坏塔召唤暗影棋子;建造护符限制",
          "Riot/Calm time exchange;Ancient Tower has 3~4 book,craft maybe break tower and summon shadow chesspiece;Amulet Limit"
     }), -3, -1, -3, -1, {
          i18n({"锤击远古塔:>95%理智且完整远古科技塔必不锤击", "Hammering: 95% sanity when making exclusive items will not trigger"}),
          i18n({"建造护符限制:无法解锁配方（需靠近工作台）的物品无法减半材料消耗", "Amulet Limit: Items that require Prototyper to unlock cannot get half material cost"}),
          i18n({"全部启用:锤击+建造护符限制", "All: Hammering + Amulet Limit"})
     }),
     item("rocks_change", i18n({"矿物改动", "Mineral rocks"}), i18n({"稿击类石头耐久倍率", "Mines need more strikes for rocks"}), 2, 1, 16, 0.25),
     item("cheap_wrap", i18n({"廉价包装", "Cheap Wrap"}), i18n({"冬季盛宴包装纸效果变差,但是捆绑包装更好用", "giftwrap lose perishable, but better bundle"})),
     headeritem(i18n({"食物改动", "Food"})),
     item("food_change", i18n({"困难模式食物改动总开关", "Switch for Food of Hard Mode"})),
     item("fooddata_change", i18n({"食物改动", "Food"}),
          i18n({"负三维提高,正三维减少,50点以上最低减少", "Negative three status +, positive three status -, safer above 50 points"}), 
          -1, -1, -3, -1, {"10%~30%", "20%~50%", "33%~66%"}),
     item("cooking_change", i18n({"烹饪改动", "Cooking"}), i18n(
          {"烹饪锅需要燃料除非附近龙鳞火炉,火炉咩咩烹饪概率净化", "Cooking Pot now needs to be fueled unless near scaled furnace"}), -1,
          -1, -2, -1, {
          i18n({"容器内火焰背景代表燃料等级", "Flame background in the container represents fuel grade"}),
          i18n({"且全食材各食材度除怪物度和不可食用度外-0.25", "And the degree of all ingredients except grotesque and inedible is-0.25"})
     }),
     item("rabbits_change", i18n({"兔子改动", "Rabbits"}), i18n({
          "陷阱捕捉优化，兑换和善兔王道具需携带兔王棍",
          "traps catch more easily;need to carry the rabbit king's stick to exchange and good rabbit king items"
     })), 
     item("birds_change", i18n({"鸟类改动", "Birds"}), i18n({
          "鸟笼内鸟类会受食物血量影响;被击或喂食受伤会概率诅咒反击",
          "Birds in cages are affected by food blood volume; common birds fight back when they lose blood"
     })),
     item("oceanfish_change", i18n({"鱼类改动", "Oceanfish"}),
          i18n({"海鱼反季仅保鲜,手持挣扎,落地跳海,更难钓;", "Struggle when hold;Drop bottles,gems,accursed trinket;Harder Rod"}), true, nil,
          nil, -1,
          {i18n({"海鱼死亡时掉落瓶中信宝石诅咒饰品", "Shark's jump will knockout enermy"}), i18n({"禁用更难钓鱼", "Disable Hard Rod"})}),
     item("container_live", i18n({"动物箱庭", "Living Box"}), i18n({
          "动物会移动吃掉同容器内的食物,没食物不移动时大鱼会吃临近别种小鱼",
          "Animal move and eat food same container;no food/move fish eat near different type fish"
     }), true, nil, nil, -1, {
          i18n({"每分钟移动1格或吃1食物;1大鱼平均1天吃1小鱼", "Animal will move 1 slot per min for food"}),
          i18n({"吃食物和小鱼无视距离无需移动", "Ignore Slots Range and don't need move"})
     }),
     item("animal_change", i18n({"动物改动", "Animals"}),
          i18n({"主要动物再生时间倍率,非生长时间", "Regeneration time rate of major animals, non-growth time"}), 8, 1, 16, 0.25),
     item("beefalo", i18n({"牦牛改动", "Beefalo"}), i18n(
          {"驯化难度增大", "Beefalo Domestication Harder"})),
     item("koalefant", i18n({"大象改动", "Koalefant"}),
          i18n({"脚印间隔距离更远,大象成群出行", "Koalefants has herd group.Harder animals track"})),
     item("Seeds Weed Chance", i18n({"种子改动", "Seeds"}),
          i18n({"箱子可晾干;仅耕地可耕种", "Chester Dry Seeds;Limit Farm soil;Seeds Weeds Chance"})),
     item("farm_plant_change", i18n({"作物改动", "Farm plants"}), i18n({"作物生长时间倍率", "Growth time rate"}), 2, 1, 16, 0.125),
     item("Difficult farming", i18n({"艰难种植", "Difficult farming"}), i18n({"水土流失;动态肥耗；娇嫩作物；艰难育种",
          "Soil loss; dynamic consumption; delicate crops; difficult breeding"
     })),
     item("plant_change", i18n({"植物改动", "Plants"}), i18n({
          "除作物/水中木外,植物生长时间倍率;大理石豆可读书催生",
          "Growth time rate except for crops,oceantree; Marble beans can be spawned by reading book"
     }), 8, 1, 16, 0.25),
     item("action_change", i18n({"互动改动", "Easter egg"}),
          i18n({"采集海带概率有触手,敲骨架概率有幽灵...", "When actions with plants... will ..."})),
     headeritem(i18n({"怪物改动", "Monster"})),
     item("monster_change", i18n({"困难模式怪物改动总开关", "Switch for Monster of Hard Mode"})),
     item("wall_destroy", i18n({"无阻可挡", "Destory Walls"}), nil, true, nil, nil, -1, {
          i18n({"生物有仇恨时可以突破各类障碍了", "Creatures will destroy collision walls when has target"}),
          i18n({"生物主动攻击墙体食人花;宠物不会攻击", "Creatures will attack walls"})
     }),
     item("supermonster", i18n({"精英怪物", "Super Monster"}), i18n({
          "动物和某些怪物该概率有7种宝石属性(彩虹隐身),该概率有一种远程武器(蓝火)",
          "Animals and monsters now may be elemental or has range weapon"
     }), 0.075, 0.025, 1, 0.025),
     item("calmfire", i18n({"战斗镇定", "Battle Calm"}), i18n({"怪物的惊恐AI不会在最近被攻击时生效", "Not panic when attacked recent"})),
     item("nosrctarget", i18n({"无端仇恨", "No Source Target"}), i18n(
          {"危险非随从怪物无仇恨时被无来源攻击会仇恨附近玩家", "Danger Wild Monster no target attacked no src will heat near player"})),
     item("moveattack", i18n({"移动攻击", "Move When Attack"}),
          i18n({"青蛙/蝙蝠/蠕虫/蛞蝓龟/伏特羊;且各有其他增强", "Frogs/Bats/Worm/Slurtle/Volt Goat;And more update"})),
     item("flyingattack", i18n({"空袭攻击", "Flying Attack"}), i18n(
          {"玩家受到飞行单位的攻击仅头部手部护甲可防;果蝇增强", "Only hands/head armor parry flying creatures' attack;Fruitfly Upgrade"})),
     item("electrocute", i18n({"电击险境", "electrocute"}), 
          i18n({"电击倍率削弱，潮湿才触发电击硬直", "Electric damage rate nerf,only wet can trigger electric stun"})),
     item("bee", i18n({"蜜蜂加强", "Killer Bee"}), i18n({"杀人蜂间歇远程攻击", "Killer bee can range attack some time"})),
     item("fruitfly", i18n({"果蝇加强", "Fruit Fly"}),
          i18n({"果蝇移速变快,捕虫网秒杀;友好果蝇不吸引攻击", "Fruit Fly Fly faster;Friendly safe"})),
     item("warg", i18n({"猎犬加强", "Hounds"}), i18n({"猎犬丘加强", "hound mound update"}), -2, -1, -4, -1, {
          i18n({"常见猎犬迷你化;青年座狼各种猎犬血量调整", "Smaller Hounds,Faster Warg/Walrus"}),
          i18n({"座狼移动中攻击;成年座狼移速攻速嗅觉增加", "Warg will attack when moving"}),
          i18n({"猎犬也会移动中攻击了", "Warg and hounds will attack when moving"}),
          i18n({"猎犬取消迷你化增加血量", "Warg and hounds will attack when moving"})
     }),
     item("walrus", i18n({"海象加强", "Walrus"}), i18n({"海象移速更快血量更高海上行走", "Walrus is stronger and faster,Run On Ocean"}), -2, -1,
          -2, -1, {"", i18n({"海象巢双倍海象", "One camp Double Walrus"})}),
     item("chess", i18n({"发条加强", "Clockworks"}), i18n(
          {"发条损坏装置互转,通过月熠闪电带电反击,不免疫电击", "Clockwork<=>Damaged<=>Broken;Gen moonstorm spark to become electric"}), -1,
          nil, nil, -1, {
          i18n({"铥矿装备绝缘;发条装置难锤,薇诺娜爆炸BOSS例外", "Thulecite insulate,Broken clockworks toughness unless winona/gunpowder/epic"}),
          i18n({"发条再生时间从10天提高到35天", "Broken->Damaged->Clockwork need time become 35 days from 10days"})
     }),
     item("tentacle", i18n({"触手加强", "Tentacle"}), i18n({
          "触手被攻击后召唤树根,攻击命中则召唤缠绕根须,分别12秒CD",
          "Summons root after being attacked, and if the attack hits, summons binding roots, 12s CD respectively"
     })),
     item("pigman", i18n({"猪人加强", "Pigman"}), i18n({
          "猪人被喂食掉血时仇恨,联动疯猪,可给武器可换金子;噩梦猪人疲惫获得黑雾加速",
          "Pig feed/crazy change,trade weapon/gold;Nightmare Werepig into dark/speedup"
     })),
     item("otter", i18n({"水獭加强", "otter"}),
          i18n({"兄弟加强,攻击附加潮湿,满潮湿后附加击飞", "otter strength, attack with moisture increase, knockback with full moisture"})),
     item("shark", i18n({"鲨鱼加强", "Shark"}),
          i18n({"鲨鱼飞跃带击退;冰鲨遁脱控制,召唤冰墙加速", "Shark leap will knock out target;Shark boi update"})),
     item("spider", i18n({"蜘蛛加强", "Spider"}), i18n(
          {"蜘蛛阵亡时巢穴出兵,无蜘蛛时降级召唤白蜘蛛;女王蜘蛛疯狂跳跃", "Spiderden will do more;Spiderqueen‘s spiders jumo"}),
          true, nil, nil, -1, {
          i18n({"妥协寡妇加强且减少掉落", "UM Hooded Widow Update and reduce drop loop"}),
          i18n({"禁用妥协寡妇改动", "Disable UM Hooded Widow Change"})
     }),
     item("lunarthrall_plant", i18n({"亮茄加强", "Brightshade"}),
          i18n({"可寄生食人花等;亮茄和食人花增强", "Infest Lure Plant...Upgrade Lure Plant"})),
     item("shadowthrall", i18n({"墨荒加强", "Ink Blight"}), i18n({"无阻轮转/弹射法弹/魇食黑雾/熔合三项加强", "Please Test"})),
     item("monkey", i18n({"穴居猴加强", "Splumonkey"}),
          i18n({"穴居猴会主动仇恨携带素食的玩家;暗影猴暗影化", "Actively hate players with vegetarians and become real shadow"})),
     item("krampus", i18n({"坎普斯加强", "Krampus"}), i18n({
          "坎普斯现在携带冰猎犬和火猎犬,存在1分钟后激活逃跑AI,逃跑不会卡住了",
          "Summons 1 hound and 1 firehound and activate runaway AI after 1 minute"
     })),
     item("crawlingshadow", i18n({"爬行恐惧加强", "Crawling Horror"}), i18n({"护疗/遁地/死亡禁锢/形态转换", "Heal Protect/Under Ground/Death Pillar/Form Change"})),
     item("shadowbeak", i18n({"恐怖尖喙加强", "Terrorbeak"}),
          i18n({"冲刺/伪装/死亡陷阱/击落装备/形态转换", "Strike/Hide/Death Trap/Drop Equip/Form Change"})),
     item("oceanshadow", i18n({"恐怖利爪加强", "Terrorclaw"}),
          i18n({"近战远程双修/击退波纹/形态转换", "Melee&Range/Knockback Wave/Form Change"})),
     item("shadowleech", i18n({"寄生暗影加强", "Shadowleech"}), i18n(
          {"寄生暗影低理智时概率来袭/吸附玩家/跳跃攻击", "Shadowleech will come when low sanity/Attach Player/Jump Attack"})),
     item("ruinsnightmare", i18n({"潜伏梦魇加强", "Ruinsnightmare"}), i18n(
          {"潜伏梦魇移动攻击/玩家理智低时加速", "Move Attack/Speed Up When Enemy Low Sanity"})),
     item("leif", i18n({"树精加强", "Treeguard"}), i18n(
          {"森林复苏,树苗突击,群体共生;月亮孢子连环爆炸", "Forest Health,Sapling Attack"})),
     item("deerclops", i18n({"巨鹿加强", "Deerclops"}),
          i18n({"极光冰阵;命运极限-冰封怒雪域;伴随雪球雪天气", "Freeze attacker,low health 1/3 chance has snow ice area"}), true, nil, nil,
          -1, {
          i18n({"队友猪人帮忙解冻;无法客户端解控", "Help frozen teammates thaw; Pig man will help unfreeze"}),
          i18n("禁用巨鹿的雪球雪天气", "Disable Deerclops' Snow Weather")
     }),
     item("antlion", i18n({"蚁狮加强", "Antlion"}), i18n({"燃之沙,颚之刃,地底呼吸,沙暴践踏", "Burning Sand spikes"})),
     item("bearger", i18n({"熊獾改动", "[Bearger]"}), i18n({"妥协装甲熊灌同步普通熊灌", "Lunar Sync UM Simple"})),
     item("dragonfly", i18n({"龙蝇加强", "Dragonfly"}), i18n({"火之弹,极限-不息暴怒炽星火阵", "Fire shoot,Half health enrage"})),
     item("malbatross", i18n({"邪天翁加强", "Malbatross"}),
          i18n({"冰霜箭羽;如来神掌;妥协鸟嘴壶可放暖石", "Feather attack;FlyLand Skill;put Thermal Stone into UM Waterfowl Can"})),
     item("klaus", i18n({"克劳斯加强", "Klaus"}), i18n(
          {"海上行走，攻速加快", "Run on ocean,increases attack speed,rework enrage section"})),
     item("crabking", i18n({"帝王蟹加强", "Crabking"}),
          i18n({"再生之炮,守护蟹钳,破冰", "Claws will also crabking itself;it will hide in ocean;Face Trident/Cannonballs"})),
     item("gestalt", i18n({"附体虚影加强", "Gestalt"}), i18n({
          "附体熊灌/巨鹿/座狼攻速更快,每1/3血有更高血量分身则+1分身上限6",
          "Infest 3 Boss When 1/3 health,try exchange higher hp shadow,success add 1 shadow"
     })),
     item("shadowchesspieces", i18n({"暗影棋子加强", "Shadow ChessPieces"}), i18n({
          "影之囚笼,影之陷阱,阈值-影潮,阈值-影之转换,海上行走",
          "Run on ocean, use shadow sneak/prison and summons shadow creatures after death"
     }), true, nil, nil, -1, {
          i18n({"脱离视野不再消失", "Leave View Not Disappear"}),
          i18n({"脱离视野正常消失", "Leave View Normal Disappear"})
     }),
     item("eyeofterror", i18n({"双子魔眼加强", "Eyes of Terror"}), i18n({"血量翻倍,技能CD减半", "Double health, half skill cd"})),
     item("toadstool", i18n({"毒菌蟾蜍加强", "Toadstools"}),
          i18n({"血量减半;双倍爆炸;季节毒雾;遁地回巢", "half health;double sporebomb/sporecloud,season sporecloud"})),
     item("alterguardian", i18n({"天体英雄加强", "Celestial Champion"}), 
          nil, -3, -1, -4, -1, {
          i18n({"仅基础属性变化(移速等),其他功能禁用", "Only base attributes doubled"}),
          i18n({"完整增强但禁用技能CD减半", "Full enhancement but disable skill cd reduction"}),
          i18n({"完整增强包括技能CD减半", "Full enhancement with double health and half skill cd"}),
          i18n({"具体增强参见模组内百科", "Same as previous mode"})
     }),
     item("daywalker", i18n({"疯猪加强", "Scrappy Werepig"}), 
          i18n({"梦魇疯猪拾荒疯猪增强，更快更棘手", "Nightmare Werepig and Scrappy Werepig upgrade, faster and more tricky"})),
     item("minotaur", i18n({"远古守护者加强", "Ancient Guardian"}),
          i18n({"梦境花园,死亡20天后重置远古", "Dream Garden,reset ruins after 20 days of death"}), true, nil, nil, nil,
          i18n({"洞穴无法种植海星陷阱", "Cave cannot deploy anenemy traps"})),
     item("atriumstalker", i18n({"远古织影者加强", "Ancient Fuelweaver"}),
          i18n({"鬼手需不同玩家或武器轮换击败", "shadow hands need different weapon"}), -1, nil, nil, -2, {
          i18n({"血量攻速移速翻倍,技能CD减半", "Double health/speed, half skill cd"}),
          i18n("为敌人召唤暗影随从和转化敌人暗影分身", "Summon enermy's shadowprotector or friend enermy's shadow"),
          i18n({"禁用血量翻倍,禁用CD减半", "Disable Double Health,disable half skill cd"})
     }),
     item("epic_armor_5", i18n({"巨兽装甲", "Epic Armor"}), 
          i18n({"巨兽装甲,使得巨兽无法被轻松击败", "Epic armored, can not be defeated easily"}), 1, 1, 5, 1),
     item("epic_ruin", i18n({"巨兽摧毁", "Epic Ruin"}), 
          i18n({"生物死亡时按所受巨兽伤害占比减少战利品", "When a creature dies, the loot is reduced by the proportion of damage it received from BOSS."}), 0.6, 0.2, 1, 0.2, {
          i18n({"最大20%摧毁概率", "MAX 20% destroy chance"}),
          i18n({"最大40%摧毁概率", "MAX 40% destroy chance"}),
          i18n({"最大60%摧毁概率", "MAX 60% destroy chance"}),
          i18n({"最大80%摧毁概率", "MAX 80% destroy chance"}),
          i18n({"最大100%摧毁概率", "MAX 100% destroy chance"})
     }),
     item("Monster Harder Level", i18n({"怪物猎人第二周目!!!", "Monster World Second Mode!!!"}),
          i18n({"裂隙开启后,危险生物的攻击动画变快;不兼容请反馈", "When Enable Rifts,Monster's attack anim become faster;May Cause Bug"}),
          false, 1.1, 5, 0.1),
     headeritem(i18n({"额外改动", "Extra Chance"})),
     item("extra_change", i18n({"困难模式额外改动总开关", "Switch for Extra of Hard Mode"}), nil, false),
     item("balatro_rebalance", i18n({"谁是小丑？", "Who is the Joker?"}), i18n({"奖励变化及牌堆削弱", "rebalanced rewards and deck"})),
     item("wanderingtrader_tweak", i18n({"流浪商人", "wanderingtrader"}), i18n({"更多交易，废料科技", "more trades, scrap technology"})),
     item("boss_health", i18n({"BOSS血量", "Boss Health"}), i18n({"乘以", "multiply"}), false, 1, 100, 0.1),
     item("boss_speed", i18n({"BOSS移速", "Move Speed"}),
          i18n({"乘以;怪物/额外改动的移速攻速攻频加强同时生效时取较大者", "multiply"}), false, 1, 10, 0.05),
     item("boss_attackanim", i18n({"BOSS攻速!!!", "Attack Speed!!!"}), i18n({"乘以;攻击动画更快;不兼容请反馈", "multiply;May Has Bug"}), false,
          1, 10, 0.05),
     item("boss_attackspeed", i18n({"BOSS攻频", "Attack Frequency"}), i18n({"乘以;攻击周期更短", "multiply"}), false, 1, 10, 0.05),
     item("boss_attackrange", i18n({"BOSS攻击距离", "Attack Range"}), i18n({"乘以", "multiply"}), false, 1, 10, 0.05),
     item("boss_damage", i18n({"BOSS造成伤害", "Cause Damage"}), i18n({"乘以", "multiply"}), false, 0.1, 100, 0.1),
     item("boss_damagetake", i18n({"BOSS受到伤害", "Damage Taken"}), i18n({"乘以", "multiply"}), false, 0, 1, 0.01),
     item("boss_damagetake2", i18n({"BOSS损失血量", "Health Lost"}), i18n({"乘以", "multiply"}), false, 1, 0, -0.01),
     item("boss_maxdamagetake", i18n({"BOSS掉血上限", "Max Health Lost"}), i18n({"设为", "is"}), false, 1000, 1, -1),
     item("boss_healthregen", i18n({"BOSS每秒回血", "Health Regen"}), i18n({" ", "is"}), false, 1, 1000, 1),
     item("boss_notfreezable", i18n({"BOSS免疫冰冻", "Not Freezeable"}), nil, false),
     item("boss_notsleeper", i18n({"BOSS免疫催眠", "Not Sleeper"}), nil, false),
     item("boss_ocean", i18n({"BOSS海上行走", "Run On Ocean"}), nil, false),
     item("boss_notenemyregen", i18n({"BOSS攻击禁止敌疗", "Not Enemy Regen"}),
          i18n({"攻击使敌人10秒内无法回血", "attack enemy will make enemy disable health regen 10s"}), false),
     item("notboss_range", i18n({"非BOSS集合", ">Not Boss Range"}),
          i18n({"哪些生物会获得下面选项的加强", "Which creatures will be enhanced by the following options"}), true, nil, nil, nil,
          i18n({"除玩家和BOSS外的任何危险生物", "All hostile creatures except player and boss"}),
          i18n({"除玩家和BOSS外的任何生物", "All creatures except player and boss"}), i18n({filldesc(8) .. "危险生物", filldesc(7) .. "Hostile"}),
          i18n({filldesc(8) .. "全部生物", filldesc(3) .. "All"})),
     item("notboss_health", i18n({"非BOSS血量", "Not Boss Health"}), i18n({"乘以", "multiply"}), false, 1, 100, 0.1),
     item("notboss_speed", i18n({"非BOSS移速", "Move Speed"}),
          i18n({"乘以;怪物/额外改动的移速攻速攻频加强同时生效时取较大者", "multiply"}), false, 1, 10, 0.05),
     item("notboss_attackanim", i18n({"非BOSS攻速!!!", "Attack Speed!!!"}), i18n({"乘以;攻击等动画更快;不兼容请反馈", "multiply;May Has Bug"}),
          false, 1, 10, 0.05),
     item("notboss_attackspeed", i18n({"非BOSS攻频", "Attack Frequency"}), i18n({"乘以;攻击周期更短", "multiply"}), false, 1, 10, 0.05),
     item("notboss_attackrange", i18n({"非BOSS攻击距离", "Attack Range"}), i18n({"乘以", "multiply"}), false, 1, 10, 0.05),
     item("notboss_damage", i18n({"非BOSS造成伤害", "Cause Damage"}), i18n({"乘以", "multiply"}), false, 1, 100, 0.1),
     item("notboss_damagetake", i18n({"非BOSS受到伤害", "Damage Taken"}), i18n({"乘以", "multiply"}), false, 0, 1, 0.01),
     item("notboss_damagetake2", i18n({"非BOSS损失血量", "Health Lost"}), i18n({"乘以", "multiply"}), false, 1, 0, -0.01),
     item("notboss_maxdamagetake", i18n({"非BOSS掉血上限", "Max Health Lost"}), i18n({"设为", "is"}), false, 1000, 1, -1),
     item("notboss_healthregen", i18n({"非BOSS每秒回血", "Health Regen"}), i18n({" ", "is"}), false, 1, 1000, 1),
     item("notboss_ocean", i18n({"非BOSS海上行走", "Run On Ocean"}), nil, false),
     headeritem(i18n({"扩展改动", "Extension Extension"})),
     item("shengwuqishilu", i18n({"怪物启示录", "Monster Apocalypse"}), i18n({
          "除玩家墙建筑船只外的每天增长血量,多少天增长一倍",
          "Monster Except Player/Walls/Boats/Structures Upgrade Health Per day,how long a level"
     }), false, 140, 1400, 10),
     item("shengwuqishilu2", i18n({"伤害成长", "Attack Apocalypse"}),
          i18n({"生物每天增长伤害,多少天增长一倍", "Monster Upgrade Damage Per day,how long a level"}), false, 700, 7000, 50),
     item("shengwuqishilu3", i18n({"护甲成长", "Parry Apocalypse"}), i18n({
          "生物每天增长护甲,多少天增加1000点,减伤1-1000/(1000+护甲),上限95%",
          "Monster Upgrade x armor Per day,reduce damage:1000/(1000+armor)"
     }), false, 1400, 3500, 100)
}
