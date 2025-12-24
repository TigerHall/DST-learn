-- 本模组需要的一些设定的通用补充
modimport("common/common.lua")
modimport("common/language2hm.lua")
modimport("common/replica.lua")
-- 弹药改动
modimport("common/projectile.lua") 
-- 诅咒改动
modimport("common/curse.lua") 
-- 持久化数据
modimport("common/temp.lua") 
-- 官方冲突修正,涵盖可选的replica错误修复补丁
modimport("common/patch.lua") 
modimport("common/recipe_util.lua")
modimport("common/food_util.lua")
modimport("common/newstate.lua")
modimport("common/bugfix.lua")
modimport("init/hover")
modimport("init/assets")

require("debugcommands2hm")
-- 永不妥协补丁
if TUNING.DSTU then modimport("common/um_patch.lua") end

-- 供其他模组访问
TUNING.HAPPYPATCHMOD = true 
TUNING.HappyPatchTest = modname == "HappyPatch"
TUNING.Plants = {}

-- 本模组额外实体
PrefabFiles = require("prefabs2hm") 

-- 简单模式
if TUNING.easymode2hm then
    -- 简单模式非角色改动
    modimport("easy/easy_creatures.lua")
    modimport("easy/easy_equipments.lua")
    modimport("easy/easy_item.lua")
    modimport("easy/easy_mechanics.lua")
    modimport("easy/easy_structures.lua")
    if GetModConfigData("classic_farm") then modimport("food/classic_farm.lua") end
    if GetModConfigData("role_easy") then
        modimport("easy/rightaction.lua")
        modimport("easy/rightselfaction.lua")
        if GetModConfigData("Skilltree Points") then 
            modimport("easy/skilltree_common.lua") 
        end
        if GetModConfigData("Role Gym") then modimport("easy/gym.lua") end
        if GetModConfigData("avoidselfdmg") then TUNING.avoidselfdmg2hm = true end
        -- 简单模式角色改动
        if GetModConfigData("wilson_easy") then modimport("easy/wilson_easy.lua") end
        if GetModConfigData("willow_easy") then modimport("easy/willow_easy.lua") end
        if GetModConfigData("wolfgang_easy") then modimport("easy/wolfgang_easy.lua") end
        if GetModConfigData("wendy_easy") then modimport("easy/wendy_easy.lua") end
        if GetModConfigData("wx78_easy") then modimport("easy/wx78_easy.lua") end
        if GetModConfigData("wickerbottom_easy") then modimport("easy/wickerbottom_easy.lua") end
        if GetModConfigData("woodie_easy") then modimport("easy/woodie_easy.lua") end
        if GetModConfigData("wes_easy") then modimport("easy/wes_easy.lua") end 
        if GetModConfigData("waxwell_easy") then modimport("easy/waxwell_easy.lua") end 
        if GetModConfigData("wigfrid_easy") then modimport("easy/wigfrid_easy.lua") end        
        if GetModConfigData("webber_easy") then modimport("easy/webber_easy.lua") end
        if GetModConfigData("winona_easy") then modimport("easy/winona_easy.lua") end
        if GetModConfigData("warly_easy") then modimport("easy/warly_easy.lua") end 
        if GetModConfigData("wortox_easy") then modimport("easy/wortox_easy.lua") end
        if GetModConfigData("wormwood_easy") then modimport("easy/wormwood_easy.lua") end
        if GetModConfigData("wurt_easy") then modimport("easy/wurt_easy.lua") end
        if GetModConfigData("walter_easy") then modimport("easy/walter_easy.lua") end
        if GetModConfigData("wanda_easy") then modimport("easy/wanda_easy.lua") end
        if GetModConfigData("whoever_easy") then modimport("easy/whoever_easy.lua") end

        if GetModConfigData("Wendy SkillTree") then modimport("easy/skilltree_wendy.lua") end
        if GetModConfigData("Willow SkillTree") then modimport("easy/skilltree_willow.lua") end
        if GetModConfigData("Woodie SkillTree") then modimport("easy/skilltree_woodie.lua") end
        if GetModConfigData("Wortox SkillTree") then modimport("easy/skilltree_wortox.lua") end
    end
end
-- 模组相关
if ((TUNING.TEMP2HM.openmods == nil and GetModConfigData("Show Mod Icon In Game")) or TUNING.TEMP2HM.openmods) and
    (TheNet:GetIsClient() or TUNING.DSA_ONE_PLAYER_MODE or (TheNet:GetServerIsClientHosted() and TheNet:GetIsServerAdmin())) then modimport("easy/ui.lua") end
if GetModConfigData("Disable Outdate Tip") then modimport("easy/mod.lua") end
-- 百科全书
if GetModConfigData("Encyclopedia_UI") then modimport("easy/encyclopedia.lua") end
-- 快捷存取和额外容器按钮
if GetModConfigData("Container Sort") or GetModConfigData("Items collect") then modimport("easy/containersort.lua") end
-- if GetModConfigData("simple chatbot") then modimport("easy/simplechatbot.lua") end
-- 暗影世界
if GetModConfigData("Shadow World") then modimport("shadowworld.lua") end
-- 随机生物大小
if GetModConfigData("Random Sized") then modimport("ray/suijishengwuapi.lua") end
-- 群系灭绝
if GetModConfigData("World ecosystem") then modimport("ray/shengwudamiejve.lua") end

-- 遗忘地图
if GetModConfigData("World lose") then modimport("ray/yincangditu.lua") end
-- 禁止控制台
if not GetModConfigData("ban op") then
    GLOBAL.ExecuteConsoleCommand = function() end
    AddSimPostInit(function()
        local UserCommands = require("usercommands")
        local rollback_command = UserCommands.GetCommandFromName("rollback")
        rollback_command.serverfn = function(params, caller) end
        local regenerate_command = UserCommands.GetCommandFromName("regenerate")
        regenerate_command.serverfn = function(params, caller) end
    end)
end
-- 制作栏提示
if GetModConfigData("Tool Tips") then
    modimport("scripts/widgets/craftslot_2hm.lua")
    modimport("init/tooltips2hm")
end

-- 困难模式
if TUNING.hardmode2hm then
    modimport("common/hardmode.lua")
    -- 科技改动
    if GetModConfigData("other_change") then
        modimport("tech/common.lua")
        if GetModConfigData("Harder Distilled Knowledge") then modimport("tech/distilledknowledge.lua") end
        if GetModConfigData("Harder Prototyper Recipe") then modimport("tech/prototyper.lua") end
        if GetModConfigData("Harder Prototyper Level") then modimport("tech/prototyperlevel.lua") end
        if GetModConfigData("oceanlife") then modimport("tech/oceanlife.lua") end
        if GetModConfigData("sleepingbag") then modimport("tech/sleep.lua") end
        if GetModConfigData("moonbase_change") then modimport("tech/moonbase.lua") end
        if GetModConfigData("moonrockidol") then modimport("tech/moonrockidol.lua") end
        if GetModConfigData("rocks_change") then modimport("tech/rocks.lua") end
        if GetModConfigData("cheap_wrap") then modimport("tech/cheap_wrap.lua") end
        if GetModConfigData("cave_entrance") and not TUNING.HappyPatchTest then modimport("tech/cave_entrance.lua") end
        if GetModConfigData("ancient_statue") then modimport("tech/ancient_statue.lua") end
        if GetModConfigData("ancient_altar") then modimport("tech/ancient_altar.lua") end
    end
    -- 角色改动
    if GetModConfigData("role_nerf") then
        if GetModConfigData("combat") then modimport("role/combat.lua") end
        if GetModConfigData("role_battle") and not TUNING.HappyPatchTest then modimport("role/health.lua") end
        if GetModConfigData("role_sanity") and not TUNING.HappyPatchTest then modimport("role/sanity.lua") end
        if GetModConfigData("role_hunger") and not TUNING.HappyPatchTest then modimport("role/hunger.lua") end
        if GetModConfigData("pvp_force") then modimport("role/pvp.lua") end
        if GetModConfigData("leader") then modimport("role/leader.lua") end
        -- if GetModConfigData("haitang_curse") then modimport("role/haitang_curse.lua") end
        if GetModConfigData("haitang_curse_2") then modimport("role/haitang_curse_2.lua") end
        if GetModConfigData("delay_leave") and not TUNING.HappyPatchTest then modimport("role/delayleave.lua") end
        if GetModConfigData("norunattack") then modimport("role/norunattack.lua") end
        if GetModConfigData("death_curse") and not TUNING.HappyPatchTest then modimport("role/death.lua") end
        if GetModConfigData("soul_wild") then modimport("role/soul.lua") end
        if GetModConfigData("legion_shield") then modimport("role/legion_shield.lua") end
        if GetModConfigData("willow") then modimport("role/willow.lua") end
        if GetModConfigData("webber") then modimport("role/webber.lua") end
        if GetModConfigData("wx-78") then modimport("role/wx78.lua") end
        if GetModConfigData("wendy") then modimport("role/wendy.lua") end
        if GetModConfigData("wolfgang") then modimport("role/wolfgang.lua") end
        if GetModConfigData("wickerbottom") then modimport("role/wickerbottom.lua") end
        if GetModConfigData("woodie") then modimport("role/woodie.lua") end
        if GetModConfigData("wigfrid") then modimport("role/wigfrid.lua") end
        if GetModConfigData("winona") then modimport("role/winona.lua") end
        if GetModConfigData("wormwood") then modimport("role/wormwood.lua") end
        if GetModConfigData("wortox") then modimport("role/wortox.lua") end
        if GetModConfigData("wurt") then modimport("role/wurt.lua") end
        if GetModConfigData("wanda") then modimport("role/wanda.lua") end
        if GetModConfigData("walter") then modimport("role/walter.lua") end
    end
    -- 天气改动
    if GetModConfigData("weather_change") then
        modimport("weather/weather.lua")
        if GetModConfigData("temperature_change") then modimport("weather/temperature.lua") end
        if GetModConfigData("rain_change") then modimport("weather/rain.lua") end
        if GetModConfigData("moonisland") then modimport("weather/moonisland.lua") end
        if GetModConfigData("sandstorm") then modimport("weather/sandstorm.lua") end
        if GetModConfigData("summer_change") then modimport("weather/summer.lua") end
        if GetModConfigData("winter_change") then modimport("weather/winter.lua") end
        if GetModConfigData("autumn_change") then modimport("weather/autumn.lua") end
        modimport("weather/seasons.lua")
        -- if GetModConfigData("random_seasons") then modimport("weather/seasons.lua") end
        if GetModConfigData("dusk_change") then modimport("weather/dusk.lua") end
        if GetModConfigData("moonlight") then modimport("weather/moonlight.lua") end
    end
    -- 食物改动
    if GetModConfigData("food_change") then
        if GetModConfigData("fooddata_change") then modimport("food/fooddata.lua") end
        if GetModConfigData("cooking_change") then modimport("food/cooking.lua") end
        if GetModConfigData("rabbits_change") then modimport("food/rabbits.lua") end
        if GetModConfigData("birds_change") then modimport("food/birds.lua") end
        if GetModConfigData("oceanfish_change") then modimport("food/oceanfish.lua") end
        if GetModConfigData("container_live") then modimport("food/container_live.lua") end
        if GetModConfigData("animal_change") then modimport("food/animal.lua") end
        if GetModConfigData("beefalo") then modimport("food/beefalo.lua") end
        if GetModConfigData("koalefant") then modimport("food/koalefant.lua") end
        if GetModConfigData("plant_change") then modimport("food/plant.lua") end
        if GetModConfigData("action_change") then modimport("food/action.lua") end
        if GetModConfigData("Seeds Weed Chance") then modimport("food/seeds.lua") end
        if GetModConfigData("Difficult farming") then modimport("food/farm.lua") end
        if GetModConfigData("farm_plant_change") then modimport("food/farm_plant.lua") end
    end
    -- 怪物加强
    if GetModConfigData("monster_change") then
        modimport("monster/common.lua")
        -- 新三王暗影分身改动
        if GetModConfigData("gestalt") and GetModConfigData("Shadow World") and
            (GetModConfigData("warg") or GetModConfigData("bearger") or GetModConfigData("deerclops")) then modimport("epic/lunarepic.lua") end
        -- 小怪改动
        if GetModConfigData("supermonster") then modimport("monster/supermonster.lua") end
        if GetModConfigData("calmfire") then modimport("monster/calmfire.lua") end
        if GetModConfigData("nosrctarget") then TUNING.nosrctarget2hm = true end
        if GetModConfigData("wall_destroy") then modimport("monster/wall.lua") end
        if GetModConfigData("moveattack") then modimport("monster/moveattack.lua") end
        if GetModConfigData("flyingattack") then modimport("monster/flying.lua") end
        if GetModConfigData("electrocute") then modimport("monster/electrocute.lua") end
        if GetModConfigData("bee") then modimport("monster/bee.lua") end
        if GetModConfigData("fruitfly") then modimport("monster/fruitfly.lua") end
        if GetModConfigData("shark") then modimport("monster/shark.lua") end
        if GetModConfigData("shadowthrall") then modimport("monster/shadowthrall.lua") end
        if GetModConfigData("lunarthrall_plant") then modimport("monster/lunarthrall_plant.lua") end
        if GetModConfigData("warg") then modimport("monster/hound.lua") end
        if GetModConfigData("walrus") then modimport("monster/walrus.lua") end
        if GetModConfigData("spider") then modimport("monster/spider.lua") end
        if GetModConfigData("pigman") then modimport("monster/pigman.lua") end
        if GetModConfigData("otter") then modimport("monster/otter.lua") end
        if GetModConfigData("monkey") then modimport("monster/monkey.lua") end
        -- 暗影生物增强，包含爬行恐惧、恐怖尖喙、寄生暗影、恐怖利爪、潜伏梦魇
        if GetModConfigData("crawlingshadow") or GetModConfigData("shadowbeak") or 
           GetModConfigData("shadowleech") or GetModConfigData("oceanshadow") 
           or GetModConfigData("ruinsnightmare") then 
            modimport("monster/shadow_creatures.lua") 
        end
        if GetModConfigData("chess") then modimport("monster/chess.lua") end
        if GetModConfigData("krampus") then modimport("monster/krampus.lua") end
        if GetModConfigData("tentacle") then modimport("monster/tentacle.lua") end
        -- BOSS加强
        if GetModConfigData("toadstool") then modimport("epic/toadstool.lua") end
        if GetModConfigData("bearger") then modimport("epic/bearger.lua") end
        if GetModConfigData("sharkboi") then modimport("epic/sharkboi.lua") end
        if GetModConfigData("leif") then modimport("epic/leif.lua") end
        if GetModConfigData("minotaur") then modimport("epic/minotaur.lua") end
        if GetModConfigData("malbatross") then modimport("epic/malbatross.lua") end
        if GetModConfigData("klaus") then modimport("epic/klaus.lua") end
        if GetModConfigData("shadowchesspieces") then modimport("epic/shadowchesspieces.lua") end
        if GetModConfigData("antlion") then modimport("epic/antlion.lua") end
        if GetModConfigData("deerclops") then modimport("epic/deerclops.lua") end
        if GetModConfigData("dragonfly") then modimport("epic/dragonfly.lua") end
        if GetModConfigData("crabking") then modimport("epic/crabking.lua") end
        if GetModConfigData("eyeofterror") then modimport("epic/eyeofterror.lua") end
        if GetModConfigData("atriumstalker") then modimport("epic/atriumstalker.lua") end
        if GetModConfigData("daywalker") then modimport("epic/daywalker.lua") end
        if GetModConfigData("epic_armor_5") then modimport("epic/epic_armor.lua") end
        if GetModConfigData("epic_ruin") then modimport("epic/epic_ruin.lua") end
        if GetModConfigData("alterguardian") then modimport("epic/alterguardian.lua") end
        -- 第二周目攻击动画加快
        if GetModConfigData("Monster Harder Level") then modimport("monster/secondlevel.lua") end
    end
    -- 额外改动
    if GetModConfigData("balatro_rebalance") then modimport("extra/balatro_rebalance.lua") end
    if GetModConfigData("wanderingtrader_tweak") then modimport("extra/wanderingtrader_tweak.lua") end
    if GetModConfigData("extra_change") then
        modimport("extra/extra.lua")
        if (GetModConfigData("boss_attackanim") or GetModConfigData("notboss_attackanim")) and not TUNING.upatkanim2hm then
            modimport("monster/secondlevel")
        end
    end
    -- 怪物启示录
    if GetModConfigData("shengwuqishilu") or GetModConfigData("shengwuqishilu2") or GetModConfigData("shengwuqishilu3") then
        modimport("ray/shengwuqishilu.lua")
    end
end



