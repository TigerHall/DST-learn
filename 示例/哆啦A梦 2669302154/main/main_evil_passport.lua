--------------------------------
--[[ 恶魔护照相关设置]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-21]]
--[[ @updateTime: 2021-12-21]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Upvalue = require "util/upvalue"
local Table = require "util/table"
local Logger = require "util/logger"
-- 戴着恶魔护照也不会被触手攻击
do
    AddPrefabPostInit("tentacle",function(inst)
        if inst.components.combat then
            local  RETARGET_CANT_TAGS = Upvalue:Get(inst.components.combat.targetfn,"RETARGET_CANT_TAGS")
            if not Table:HasValue(RETARGET_CANT_TAGS,TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                table.insert(RETARGET_CANT_TAGS,TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
            end
        end
    end)
end

--[在以下大脑类中修改hunternotags或hunterfn方法,以实现恶魔护照,靠近不乱跑的功能]]
do
    -- 代码copy神话书说 白骨精化雾的实现
--[[    local function findhunter(value,tags)
        if value.findhuntered then -- 已加载过,避免重复
            return
        end
        if value.children ~= nil and type(value.children) == "table" then
            for k1,v1 in ipairs(value.children) do
                if type(v1) == "table" then
                    findhunter(v1,tags)
                end
            end
        elseif value.hunternotags ~= nil then
            for _,v2 in ipairs(tags) do
                if not Table:HasValue(value.hunternotags,v2) then
                    table.insert(value.hunternotags,v2)
                end
            end
            value.findhuntered = true
        elseif value.hunterfn ~= nil then
            local old_hunterfn = value.hunterfn
            value.hunterfn = function(guy,...)
                for _,v3 in ipairs(tags) do
                    if guy:HasTag(v3) then
                        return false
                    end
                end
                return old_hunterfn(guy,...)
            end
            value.findhuntered = true
        end
    end

    -- 需要修改大脑类中的runaway,保证玩家靠近他们,他们不跑
    local brainPostInits = {
        "koalefantbrain",-- 考拉象
        "rabbitbrain",-- 兔子
        "perdbrain",-- 火鸡
        "grassgatorbrain",-- 草鳄鱼grassgatorbrain  无花果树旁边那个生物,有点像水牛
        "grassgekkobrain", -- 草蜥蜴
        "grassgekkobrain", -- 草蜥蜴
        "lightninggoatbrain", -- 闪电羊
        "deerbrain", -- 无眼鹿
        "catcoonbrain", -- 浣熊/猫
        "butterflybrain", -- 蝴蝶
        "bunnymanbrain", -- 兔人
        "walrusbrain", -- 海象
        "krampusbrain", -- 坎普斯
    }

    for _,v in ipairs(brainPostInits) do
        AddBrainPostInit(v, function(self)
            for k, v in ipairs(self.bt.root.children) do
                if type(v) == "table" then
                    findhunter(v,{TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG})
                end
            end
        end)
    end]]
    -- 尝试更简单的 直接增加runaway的post init
    AddGlobalClassPostConstruct("behaviours/runaway","RunAway",function (self, ...)
        local tags = {TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG}
        if self.hunternotags ~= nil then
            for _,v2 in ipairs(tags) do
                if not Table:HasValue(self.hunternotags,v2) then
                    table.insert(self.hunternotags,v2)
                end
            end
        elseif self.hunterfn ~= nil then
            local old_hunterfn = self.hunterfn
            self.hunterfn = function(guy,...)
                for _,v3 in ipairs(tags) do
                    if guy:HasTag(v3) then
                        return false
                    end
                end
                return old_hunterfn(guy,...)
            end
        end
    end)
end

-- 靠近鸟,鸟不飞走
do
    local birdBrain = require "brains/birdbrain"
    local SHOULDFLYAWAY_MUST_TAGS = Upvalue:Get(birdBrain.OnStart,"SHOULDFLYAWAY_MUST_TAGS")
    if SHOULDFLYAWAY_MUST_TAGS then
        table.insert(SHOULDFLYAWAY_MUST_TAGS,TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
    end
end

-- 靠近秃鹫,秃鹫不飞走
do
    local buzzardBrain = require "brains/buzzardbrain"
    local FINDTHREAT_MUST_TAGS = Upvalue:Get(buzzardBrain.OnStart,"FINDTHREAT_MUST_TAGS")
    if FINDTHREAT_MUST_TAGS then
        table.insert(FINDTHREAT_MUST_TAGS,TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
    end
end

-- 以下代码抄自神话myth-hero\main\white_bone.lua
-- 感谢神话大佬们
-- 实现去除尝试攻击,和群体仇恨
do
    AddComponentPostInit("combat",function(self)
        local old_TryRetarget = self.TryRetarget
        function self:TryRetarget(...)
            if self.inst.evilPassPortNear  then -- 恶魔护照附近
                if self.targetfn ~= nil
                        and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead())
                        and not (self.inst.components.sleeper ~= nil and self.inst.components.sleeper:IsInDeepSleep()) then
                    local newtarget, forcechange = self.targetfn(self.inst)
                    if newtarget ~= nil and newtarget ~= self.target and not newtarget:HasTag("notarget") then
                        if newtarget:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                            -- 存在恶魔护照则直接返回
                            return
                        end
                    end
                end
            end
            -- 默认逻辑
            old_TryRetarget(self,...)
        end

        local old_ShareTarget = self.ShareTarget
        function self:ShareTarget(target,...) -- 群体仇恨 ，可能距离过远，就不判断self.inst.evilPassPortNear了
            -- 只要目标持有恶魔护照
            if  target and target:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                return
            end
            old_ShareTarget(self,target,...)
        end
    end)
end

-- 鬼魂攻击,其使用了aura组件
do
    AddComponentPostInit("aura",function(self)
        if self.auraexcludetags then
            table.insert(self.auraexcludetags,TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
        end
    end)
end

-- 月盲乌鸦,奇形鸟scripts/prefabs/birds_mutant.lua
do
    local function findBirdsMutant(self,value)
        if value.findBirdsMutanted then -- 已加载过,避免重复
            Logger:Debug("月盲乌鸦,奇形鸟已加载过")
            return
        end
        if value.children ~= nil and type(value.children) == "table" then
            for k1,v1 in ipairs(value.children) do
                if type(v1) == "table" then
                    findBirdsMutant(self,v1)
                end
            end
        elseif value.name ~= nil  then
            -- Attack: 月盲乌鸦的攻击
            -- Spit,waittospit: 奇形鸟的吐口水
            if  value.name == "Attack" or value.name == "Spit" or value.name == "waittospit"
            then
                local old_fn = value.fn
                value.fn = function(...)
                    local target = old_fn(...)
                    if target then
                        if type(target) =="table" and target:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                            -- 目标持有恶魔护照
                            return nil
                        end
                        -- 此时target 是shouldspit  shouldwaittospit的返回值
                        if type(target) == "boolean" and target then
                            -- 目标持有恶魔护照 , 返回false
                            Logger:Debug({"spit/shouldwaittospit的返回值",target})
                            if self.inst.components.combat.target
                                    and  self.inst.components.combat.target:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
                            then
                                return false
                            end
                        end
                    end
                    return old_fn(...)
                end
                value.findBirdsMutanted = true
            end
        end
    end
    AddBrainPostInit("bird_mutant_brain", function(self)
        Logger:Debug("月盲乌鸦,奇形鸟大脑类初始化")
        for k, v in ipairs(self.bt.root.children) do
            if type(v) == "table" then
                findBirdsMutant(self,v)
            end
        end
    end)
end


-- 饼干切割机
do
    --不切割恶魔护照的船 下面注释的代码存在问题,虽然设置成功但无作用
--[[    local cookiecutter = require "prefabs/cookiecutter"
    if cookiecutter then
        -- 发现船的的方法
        local  findtargetcheck = Upvalue:Get(cookiecutter.fn,"findtargetcheck")
        Logger:Debug({"饼干切割机findtargetcheck",findtargetcheck})
        if findtargetcheck then
            local oldFindtargetcheck = findtargetcheck
            local newFindtargetcheck = function(target)
                Logger:Debug("饼干切割机替换方法已执行")
                local valid = oldFindtargetcheck(target);
                Logger:Debug({"饼干切割机寻找target",valid})
                if valid then
                    if target.components.walkableplatform then
                        -- 遍历玩家
                        for _,v in pairs(target.components.walkableplatform.players_on_platform) do
                            if v and v:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                                return false
                            end
                        end
                    end
                end
                return valid
            end
            local setResult = Upvalue:Set(cookiecutter.fn,"findtargetcheck",newFindtargetcheck)
            Logger:Debug({"设置结果",setResult})
        end
    end]]
    -- 周围存在恶魔护照 饼干切割器就什么都不干
    local function findTryToBoardBoat(self,value)
        if value.findTryToBoardBoated then -- 已加载过,避免重复
            return
        end
        if value.children ~= nil and type(value.children) == "table" then
            for k1,v1 in ipairs(value.children) do
                if type(v1) == "table" then
                    findTryToBoardBoat(self,v1)
                end
            end
        elseif value.name ~= nil and value.name == "TryToBoard" then
            -- value 即 TryToBoard action
            local old_action = value.action
            value.action = function(...)
                if self.inst and self.inst.evilPassPortNear then
                    -- 周围存在恶魔护照,不做任何事
                    return
                end
                return old_action(...)
            end
            value.findTryToBoardBoated = true
        end
    end
    AddBrainPostInit("cookiecutterbrain", function(self)
        for k, v in ipairs(self.bt.root.children) do
            if type(v) == "table" then
                findTryToBoardBoat(self,v)
            end
        end
    end)
end

-- 去除敌对攻击(也包括兔人肉食仇恨攻击等等,很多),可能会引起其它问题,需要观察
-- 目前发现: 敌对攻击(玩家和怪物),兔人肉食仇恨,缀食者主动仇恨,暴动猴子,地龙(worm),影怪
--           远古哨兵蜈蚣(archive_centipede), 海象不会主动攻击
do
    AddComponentPostInit("combat",function(self)
        local oldCanTarget = self.CanTarget
        function self:CanTarget(target,...)
            -- if条件:不是猎犬 或  (建筑生成物（猎犬丘 生成的狼）  或 非boss生成物)
            -- 目的: 定时来攻击的猎犬，boss生成物可以攻击恶魔护照持有者. 建筑生成物不可以攻击持有者
            if not self.inst:HasTag("hound") or
                    -- 凡是通过childspawner组件生成的子实体，子实体都有homeseeker组件
                    (self.inst.components.homeseeker ~= nil  or self.inst.components.follower == nil)
            then
                if target and target:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)  then
                    return false
                end
            end
            return oldCanTarget(self,target,...)
        end
    end)
end

-- 靠近杀人蜂 不会出现杀人蜂
do
    AddPrefabPostInit("wasphive",function(inst)
        if inst.components.playerprox then
            local fn = inst.components.playerprox.onnear
            local fnWrap = function(inst,player,...)
                Logger:Debug({"onnear包装函数执行",player:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)})
                if player and player:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                    -- do nothing
                else
                    fn(inst,player,...)
                end
            end
            inst.components.playerprox:SetOnPlayerNear(fnWrap)
        end
    end)
end

-- 靠近蜘蛛巢穴不会出现蜘蛛
do
    local function changeSpider(prefab,source)
        AddPrefabPostInit(prefab,function(inst)
            if TheWorld.ismastersim then -- 服务器
                local listeners = inst.event_listening["creepactivate"]
                if listeners then
                    local listener_fns = listeners[inst]
                    local fn = nil
                    for i = #listener_fns, 1, -1 do
                        if debug.getinfo(listener_fns[i]).source == source then
                            fn = listener_fns[i]
                            break
                        end
                    end
                    if fn ~= nil then -- 已找到对应fn
                        inst:RemoveEventCallback("creepactivate",fn)
                        local function SpawnInvestigators(inst, data)
                            local target = data ~= nil and data.target  or nil
                            -- 目标是玩家 且拥有恶魔护照标签
                            if target  and target:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG) then
                                -- do nothing
                            else
                                fn(inst, data)
                            end
                        end
                        inst:ListenForEvent("creepactivate",SpawnInvestigators)
                    end
                end
            end
        end)
    end

    local spiders ={
        spiderden = "scripts/prefabs/spiderden.lua",-- 蜘蛛巢穴
        spiderhole = "scripts/prefabs/spiderhole.lua",--洞穴蜘蛛巢穴/蛛网岩
        dropperweb = "scripts/prefabs/dropperweb.lua",--穴居悬蛛
        moonspiderden = "scripts/prefabs/moonspiderden.lua",-- 破碎蜘蛛洞/月亮上的蜘蛛
    }

    for k,v in pairs(spiders) do
        changeSpider(k,v)
    end
end

-- 攻击杀人蜂,蜘蛛不会使巢穴放出其它生物来攻击
-- 新的问题 如果蜂巢被打 也是调用该方法 导致蜂巢被打无动作
-- 蜘蛛巢被打有动作 ，因为是在spiderden中自己实现的
-- 经过考量，蜘蛛不太好实现，还是全部去除
-- 改为：保证杀人蜂巢被打 会放出杀人蜂，仅实现杀人蜂被打不会放出杀人蜂,
--       蜘蛛被攻击使用shareTarget共享仇恨,这个已修改
do
--[[AddComponentPostInit("childspawner",function(self)
    local oldReleaseAllChildren = self.ReleaseAllChildren
    function self:ReleaseAllChildren(attacker,...)
        if attacker and  attacker:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)  then
            return {} -- ReleaseAllChildren函数返回 children_released，这里返回空table
        end
        return oldReleaseAllChildren(self,attacker,...)
    end
end)]]
    local function changeOnAttacked(prefab,source)
        AddPrefabPostInit(prefab,function(inst)
            if TheWorld.ismastersim then -- 服务器
                local listeners = inst.event_listening["attacked"]
                if listeners then
                    local listener_fns = listeners[inst]
                    local fn = nil
                    for i = #listener_fns, 1, -1 do
                        if debug.getinfo(listener_fns[i]).source == source then
                            fn = listener_fns[i]
                            break
                        end
                    end
                    if fn ~= nil then -- 已找到对应fn
                        inst:RemoveEventCallback("attacked",fn)
                        local function OnAttacked(inst, data)
                            local attacker = data ~= nil and data.attacker  or nil
                            -- 目标拥有恶魔护照标签,只设置被攻击目标的仇恨
                            if attacker and attacker:HasTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
                                and inst.components.combat -- 保险起见 判断是否为nil
                            then
                                inst.components.combat:SetTarget(attacker)
                            else
                                fn(inst, data)
                            end
                        end
                        inst:ListenForEvent("attacked",OnAttacked)
                    end
                end
            end
        end)
    end
    local onAttackedPrefabs ={
        bee = "scripts/brains/beecommon.lua",-- 蜜蜂
        killerbee = "scripts/brains/beecommon.lua",-- 杀人蜂
    }

    for k,v in pairs(onAttackedPrefabs) do
        changeOnAttacked(k,v)
    end
end