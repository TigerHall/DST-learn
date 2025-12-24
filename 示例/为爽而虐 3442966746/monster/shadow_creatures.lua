-- ========================================
-- 暗影生物增强
-- 1. 爬行恐惧  crawlingshadow
-- 2. 恐怖尖喙  shadowbeak
-- 3. 寄生暗影  shadowleech
-- 4. 恐怖利爪  oceanshadow
-- 5. 潜伏梦魇  ruinsnightmare

-- ========================================
-- 爬行恐惧增强
if GetModConfigData("crawlingshadow") then
    
    TUNING.CRAWLINGHORROR_HEALTH = TUNING.TERRORBEAK_HEALTH

    -- 死亡时生成暗影囚笼
    local function PillarsSpellFn(inst)
        if inst.disabledeath2hm then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        local spell = SpawnPrefab("mod_hardmode_shadow_pillar_spell")
        spell.caster = inst
        local platform = TheWorld.Map:GetPlatformAtPoint(x, z)
        if platform ~= nil then
            spell.entity:SetParent(platform.entity)
            spell.Transform:SetPosition(platform.entity:WorldToLocalSpace(x, y, z))
        else
            spell.Transform:SetPosition(x, y, z)
        end
    end

    -- 回血时受击中断检测
    local function OnHelpAttacked(inst, data)
        if inst.helptask2hm then
            inst.readystophelptask2hm = 2
        end
    end

    -- 回血时的伤害过滤
    local function getattacked(inst, data)
        if inst.helptask2hm and inst.allmiss2hm and data and
            ((data.damage >= 34 and inst.helptask2hmindex > 0) or 
            (data.attacker and data.attacker:HasTag("player") and
                (data.weapon == nil or
                    (data.weapon.components.projectile == nil and 
                    (data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil))))) then
            inst.allmiss2hm = nil
        end
    end

    -- 爬行恐惧初始化
    local crawlings = {"crawlinghorror", "crawlingnightmare"}
    for _, crawling in ipairs(crawlings) do
        AddPrefabPostInit(crawling, function(inst)
            if not TheWorld.ismastersim then return end
            inst.canhelp2hm = true
            if not inst.components.timer then
                inst:AddComponent("timer")
            end
            inst:ListenForEvent("death", PillarsSpellFn)
            inst:ListenForEvent("getattacked2hm", getattacked)
            inst:ListenForEvent("attacked", OnHelpAttacked)
        end)
    end

    -- 特效函数
    local function showshieldfx(inst)
        local r, g, b, alpha = inst.AnimState:GetMultColour()
        local fx = SpawnPrefab("stalker_shield2hm")
        fx.AnimState:SetScale(-1.36, 1.36, 1.36)
        fx.AnimState:SetMultColour(r, g, b, alpha)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    local function showtransitionfx(inst, size)
        size = size or .5
        local fx = SpawnPrefab("statue_transition_2")
        fx.Transform:SetScale(size, size, size)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    -- 回血API
    local function helpone(inst, source, value)
        if inst.components.health and not inst.components.health:IsDead() then
            if not inst.undergroundmovetask2hm then
                showtransitionfx(inst, .8)
            end
            if inst.canhelp2hm and inst.components.timer then
                local isself = inst == source
                if not isself and inst.helptask2hm and not inst.readystophelptask2hm then
                    inst.readystophelptask2hm = 1
                end
                -- 回血CD计算
                local cd = (isself and inst.helptask2hmindex or ((source.helptask2hmindex or 0) - 10)) / 2 + 8
                if not inst.components.timer:TimerExists("healcd2hm") then
                    inst.components.timer:StartTimer("healcd2hm", cd)
                elseif inst.components.timer:GetTimeLeft("healcd2hm") < cd then
                    inst.components.timer:SetTimeLeft("healcd2hm", cd)
                end
            end
            inst.components.health:DoDelta(value)
        end
    end

    -- 遁地技能：破土而出
    local function stopundergroundtask(inst, doattack)
        if inst.components.health:IsDead() then
            inst:Remove()
            return
        end
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "shadowhelphealth2hm")
        if inst.undergroundmovetask2hm then
            inst.undergroundmovetask2hm:Cancel()
            inst.undergroundmovetask2hm = nil
        end
        if inst.undergroundstoptask2hm then
            inst.undergroundstoptask2hm:Cancel()
            inst.undergroundstoptask2hm = nil
        end
        if inst.attacktostopundergroundtask then
            inst:RemoveEventCallback("newstate", inst.attacktostopundergroundtask)
            inst.attacktostopundergroundtask = nil
        end
        inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "shadowhelphealth2hm")
        if inst.allmiss2hm then
            inst.allmiss2hm = nil
        end
        if doattack and inst.components.combat.target then
            inst.Transform:SetPosition(inst.components.combat.target.Transform:GetWorldPosition())
        end
        if inst.components.combat.target and inst:IsNear(inst.components.combat.target, 6) then
            PillarsSpellFn(inst)
        end
        inst.sg:GoToState("appear")
        inst:Show()
    end

    -- 遁地攻击监听
    local function attacktostopundergroundtask(inst, data)
        if data and data.statename == "attack" then
            inst:DoTaskInTime(0, stopundergroundtask, true)
        end
    end

    -- 遁地技能执行
    local function skillunderground(inst)
        if inst.components.health:IsDead() then
            inst:Remove()
            return
        end
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "shadowhelphealth2hm", 2)
        inst:Hide()
        inst.undergroundmovetask2hm = inst:DoPeriodicTask(15 * FRAMES, showtransitionfx)
        inst.undergroundstoptask2hm = inst:DoTaskInTime(3 + (4 - inst.helptask2hmindex) * 0.5, stopundergroundtask)
        inst.attacktostopundergroundtask = attacktostopundergroundtask
        inst:ListenForEvent("newstate", attacktostopundergroundtask)
    end

    -- 回血技能终止
    local function stophelpshadow(inst, attacked)
        if inst.components.combat.target and not attacked and inst.helptask2hmindex < 20 and 
        not inst.components.health:IsDead() and not inst.undergroundmovetask2hm and inst.components.timer then
            -- 洞穴或15秒内再次触发可遁地攻击
            if TheWorld:HasTag("cave") or inst.components.timer:TimerExists("undergroundattack2hm") then
                inst.helptask2hm:Cancel()
                inst.helptask2hm = nil
                inst.sg:GoToState("taunt")
                inst.sg:AddStateTag("attack")
                inst.AnimState:PlayAnimation("disappear")
                inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), skillunderground)
                return
            end
            inst.components.timer:StartTimer("undergroundattack2hm", 15)
        end
        inst.helptask2hm:Cancel()
        inst.helptask2hm = nil
        inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "shadowhelphealth2hm")
        if inst.allmiss2hm then
            inst.allmiss2hm = nil
        end
    end

    -- 回血条件检测
    local helptargettags = {"shadowcreature", "nightmarecreature", "shadowchesspiece"}
    local function canhelpshadow(inst, onlyinst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 20, nil, nil, helptargettags)
        
        -- 检查是否有其他影怪正在回血
        for index, ent in ipairs(ents) do
            if ent ~= inst and ent.helptask2hm and ent.helptask2hmindex and 
            ent.helptask2hmindex > 8 and ent.helptask2hmindex < 12 then
                return false, ents
            end
        end
        
        -- 检查是否有受伤的影怪
        for index, ent in ipairs(ents) do
            if ent.components.health and not ent.components.health:IsDead() and 
            ent.components.health:GetPercent() < (onlyinst and (1 - 0.2 / (1 - (ent.exchangetimes2hm or 0) * 0.0675)) or 1) and
            (ent == inst or not onlyinst or not ent.canhelp2hm or
                (ent.components.timer and ent.components.timer:TimerExists("healcd2hm") and not ent.helptask2hm)) then
                return true, ents
            end
        end
        return false, ents
    end

    -- 回血阶段执行
    local function helpshadow(inst)
        if inst.readystophelptask2hm then
            stophelpshadow(inst, inst.readystophelptask2hm == 2)
            inst.readystophelptask2hm = nil
            return
        end
        
        inst.helptask2hmindex = inst.helptask2hmindex + 1
        if inst.helptask2hmindex > 20 or inst.components.health:IsDead() then
            stophelpshadow(inst)
            return
        end
        
        showshieldfx(inst)
        local needhelp, ents = canhelpshadow(inst)
        if not needhelp then
            stophelpshadow(inst)
            return
        end
        
        -- 切换回血频率
        if inst.helptask2hmindex == 12 then
            inst.helptask2hm.period = 0.75
        end
        
        -- 群体回血阶段
        if inst.helptask2hmindex > 12 then
            local helpvalue = inst.components.health.maxhealth / 8
            for index, ent in ipairs(ents) do
                helpone(ent, inst, helpvalue)
            end
        else
            -- 自我回血阶段
            helpone(inst, inst, inst.components.health.maxhealth * 3 / (inst.helptask2hmindex < 3 and 16 or 48))
        end
    end

    -- 状态图修改：回血动画和触发
    AddStategraphPostInit("shadowcreature", function(sg)
        local idle = sg.states.idle.onenter
        sg.states.idle.onenter = function(inst, ...)
            if inst.canhelp2hm and not inst.undergroundmovetask2hm and 
            (inst.helptask2hm and not inst.readystophelptask2hm or
                (not inst.helptask2hm and inst.components.timer and 
                not inst.components.timer:TimerExists("healcd2hm") and 
                canhelpshadow(inst, true))) then
                inst.sg:GoToState("taunt")
                return
            end
            idle(inst, ...)
        end
        
        local taunt = sg.states.taunt.onenter
        sg.states.taunt.onenter = function(inst, ...)
            if inst.undergroundmovetask2hm then
                inst.sg:GoToState("idle")
                return
            elseif inst.canhelp2hm and not inst.helptask2hm and inst.components.timer and 
                not inst.components.timer:TimerExists("healcd2hm") and canhelpshadow(inst, true) then
                showshieldfx(inst)
                inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.01, "shadowhelphealth2hm")
                inst.helptask2hm = inst:DoPeriodicTask(0.5, helpshadow, 1)
                inst.allmiss2hm = true
                inst.helptask2hmindex = 0
            elseif inst.helptask2hm and inst.components.combat and inst.components.combat.target and 
                not inst:IsNear(inst.components.combat.target, 20) then
                -- 目标太远时传送靠近
                local x0, y0, z0 = inst.components.combat.target.Transform:GetWorldPosition()
                for k = 1, 4 do
                    local x = x0 + math.random() * 20 - 10
                    local z = z0 + math.random() * 20 - 10
                    if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
                        inst.Physics:Teleport(x, 0, z)
                        break
                    end
                end
            end
            taunt(inst, ...)
        end
    end)


    -- 影怪形态转换系统
    if GetModConfigData("crawlingshadow") and GetModConfigData("shadowbeak") then
        -- 转换条件判断
        local function cancrawlingexchange(inst)
            return inst.canexchange2hm and not inst.disableexchange2hm and 
                (inst.exchangetimes2hm or 0) < 4 and inst.components.combat.target and
                not inst.helptask2hm and
                ((inst.exchangetimes2hm or 0) > 0 or 
                    inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675))) and
                inst.components.timer and inst.components.timer:TimerExists("healcd2hm")
        end
        
        local function canbeakexchange(inst)
            return inst.canexchange2hm and not inst.disableexchange2hm and 
                (inst.exchangetimes2hm or 0) < 4 and inst.components.combat.target and
                not inst.hidetask2hm and 
                inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675)) and
                (inst.components.timer and inst.components.timer:TimerExists("shadowstrikecd2hm"))
        end
        
        local function canexchangeocean(inst)
            return inst.canexchange2hm and not inst.disableexchange2hm and 
                (inst.exchangetimes2hm or 0) < 4 and inst.components.combat.target and
                not inst.taunttask2hm and 
                inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675)) and
                (inst.components.timer and inst.components.timer:TimerExists("tauntcd2hm"))
        end
        
        local conditions = {
            terrorbeak = canbeakexchange,
            nightmarebeak = canbeakexchange,
            crawlinghorror = cancrawlingexchange,
            crawlingnightmare = cancrawlingexchange,
            oceanhorror2hm = canexchangeocean,
            oceanhorror = canexchangeocean
        }
        
        -- 转换触发条件
        local function onattacked(inst, data)
            if not inst.canexchange2hm and not inst.disableexchange2hm and data then
                if data.attacker and data.attacker:HasTag("player") and 
                data.attacker.components.locomotor and 
                data.attacker.components.locomotor:GetRunSpeed() >= 
                ((TheWorld:HasTag("cave") or inst:HasTag("nightmarecreature")) and 9 or 10.8) then
                    inst.canexchange2hm = true
                elseif data.damage and 
                    data.damage >= ((TheWorld:HasTag("cave") or inst:HasTag("nightmarecreature")) and 100 or 150) then
                    inst.canexchange2hm = true
                end
            end
        end
        
        for prefab, _ in pairs(conditions) do
            AddPrefabPostInit(prefab, function(inst)
                if not TheWorld.ismastersim then return end
                inst:ListenForEvent("attacked", onattacked)
            end)
        end
        
        AddStategraphPostInit("shadowcreature", function(sg)
            local idle = sg.states.idle.onenter
            sg.states.idle.onenter = function(inst, ...)
                if not inst.wantstodespawn and conditions[inst.prefab] and conditions[inst.prefab](inst) then
                    inst.sg:GoToState("exchange2hm")
                    return
                end
                idle(inst, ...)
            end
        end)
        
        -- 转换目标和距离配置
        local exchangetargets = {
            terrorbeak = "crawlinghorror",
            crawlinghorror = "terrorbeak",
            nightmarebeak = "crawlingnightmare",
            crawlingnightmare = "nightmarebeak",
            oceanhorror = "crawlinghorror",
            oceanhorror2hm = "crawlingnightmare"
        }
        
        local exchangeradius = {
            terrorbeak = 10,
            crawlinghorror = -5,
            nightmarebeak = 5,
            crawlingnightmare = -5,
            oceanhorror2hm = -10,
            oceanhorror = -10
        }
        
        -- 转换动画状态
        AddStategraphState("shadowcreature", State {
            name = "exchange2hm",
            tags = {"busy", "attack", "teleporting"},
            
            onenter = function(inst, playanim)
                inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.5, "shadowexchange2hm")
                inst.sg.statemem.max2hm = inst.components.health.maxdamagetakenperhit
                inst.components.health:SetMaxDamageTakenPerHit(50)
                
                local target = inst.components.combat.target
                if target and inst:IsNear(target, 6) then
                    local x, y, z = target.Transform:GetWorldPosition()
                    local sx, sy, sz = inst.Transform:GetWorldPosition()
                    local radius = -4
                    local theta = inst:GetAngleToPoint(Vector3(x, y, z)) * DEGREES
                    local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
                    sx = sx + offset.x
                    sy = sy + offset.y
                    sz = sz + offset.z
                    inst.Transform:SetPosition(sx, sy, sz)
                end
                
                SpawnPrefab("shadow_teleport_out2hm").Transform:SetPosition(inst.Transform:GetWorldPosition())
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("taunt", false)
                inst.AnimState:PushAnimation("disappear", false)
            end,
            
            timeline = {
                TimeEvent(40 * FRAMES, function(inst)
                    SpawnPrefab("shadow_teleport_out2hm").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end)
            },
            
            events = {
                EventHandler("animqueueover", function(inst)
                    if not inst.components.combat.target then
                        inst.sg:GoToState("idle")
                        return
                    end
                    
                    local newprefab = inst.exchangeprefab2hm or exchangetargets[inst.prefab] or inst.prefab
                    local target = inst.components.combat.target
                    local x, y, z = target.Transform:GetWorldPosition()
                    local sx, sy, sz = inst.Transform:GetWorldPosition()
                    local radius = exchangeradius[newprefab] or 0
                    local theta = inst:GetAngleToPoint(Vector3(x, y, z)) * DEGREES
                    sx = sx + radius * math.cos(theta)
                    sz = sz - radius * math.sin(theta)
                    
                    SpawnPrefab("shadow_teleport_in2hm").Transform:SetPosition(sx, sy, sz)
                    
                    local shadow = SpawnPrefab(newprefab)
                    shadow.canexchange2hm = true
                    shadow.exchangetimes2hm = (inst.exchangetimes2hm or 0) + 1
                    shadow.exchangeprefab2hm = inst.prefab
                    shadow.Transform:SetPosition(sx, sy, sz)
                    
                    local size = 1 - (shadow.exchangetimes2hm or 0) * 0.0675
                    shadow.AnimState:SetScale(size, size, size)
                    shadow.components.combat:SetTarget(target)
                    shadow.components.combat.attackrange = shadow.components.combat.attackrange * size * size
                    shadow.components.combat.externaldamagemultipliers:SetModifier(shadow, size, "exchange2hm")
                    shadow.components.locomotor:SetExternalSpeedMultiplier(shadow, "exchange2hm", size)
                    shadow.components.health.maxhealth = inst.components.health.maxhealth * size
                    shadow.components.health:SetVal(inst.components.health.currenthealth)
                    shadow.components.health:ForceUpdateHUD(true)
                    shadow.sg:GoToState("appear")
                    
                    TheWorld:PushEvent("ms_exchangeshadowcreature", {ent = inst, exchangedent = shadow})
                    inst:Remove()
                end)
            },
            
            onexit = function(inst)
                if inst:IsValid() then
                    inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "shadowexchange2hm")
                    inst.components.health:SetMaxDamageTakenPerHit(inst.sg.statemem.max2hm)
                end
            end
        })
    end

end 

-- ========================================
-- 恐怖尖喙增强
if GetModConfigData("shadowbeak") then

    -- 速度和攻速调整
    local speedup = GetModConfigData("extra_change") and GetModConfigData("notboss_speed") or 1
    local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("notboss_attackspeed") or 1
    if speedup < 1.45 then
        TUNING.TERRORBEAK_SPEED = TUNING.TERRORBEAK_SPEED * 1.45 / speedup
    end
    if attackspeedup < 1.33 then
        TUNING.TERRORBEAK_ATTACK_PERIOD = TUNING.TERRORBEAK_ATTACK_PERIOD * 3 / 4 * attackspeedup
    end

    -- 死亡时生成陷阱
    local function TrapSpellFn(inst)
        if inst.disabledeath2hm then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        local trap = SpawnPrefab("mod_hardmode_shadow_trap")
        trap.Transform:SetPosition(x, y, z)
        if TheWorld.Map:GetPlatformAtPoint(x, z) ~= nil then
            trap:RemoveTag("ignorewalkableplatforms")
        end
    end


    -- 伪装系统：玩家查找
    local maxrangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST * 4
    local function findnearplayer(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local rangesq = maxrangesq
        local closestPlayer
        for i, player in ipairs(AllPlayers) do
            if player and player:IsValid() and not IsEntityDeadOrGhost(player) and player.entity:IsVisible() and
                (player.components.sanity and player.components.sanity:IsInsanityMode() and 
                player.components.sanity:GetPercent() < 0.8 or inst:HasTag("nightmarecreature")) then
                local distsq = player:GetDistanceSqToPoint(x, y, z)
                if distsq < rangesq then
                    rangesq = distsq
                    closestPlayer = player
                end
            end
        end
        return closestPlayer, closestPlayer ~= nil and rangesq or nil
    end

    -- 伪装系统：停止伪装
    local function trystophidetask(inst)
        if inst.components.timer then
            local cd = inst.components.combat.target and (10 + (inst.hidetask2hmidx or 0) * 5) or 10
            if not inst.components.timer:TimerExists("hidecd2hm") then
                inst.components.timer:StartTimer("hidecd2hm", cd)
            elseif inst.components.timer:GetTimeLeft("hidecd2hm") < cd then
                inst.components.timer:SetTimeLeft("hidecd2hm", cd)
            end
        end
        if inst.hidetask2hm then
            if inst.hidetask2hm ~= true then
                inst.hidetask2hm:Cancel()
            end
            inst.hidetask2hm = nil
            inst:ReturnToScene()
            inst.hidetask2hmidx = nil
            if inst.components.health:IsDead() then
                inst.sg:GoToState("death")
            else
                inst.sg:GoToState(inst.wantstodespawn and "disappear" or "appear")
            end
        end
    end

    -- 伪装系统：随机移动
    local function randommoveinst(inst, moverange, shadowskittish, proxy, tryattack)
        local x, y, z = (proxy or inst).Transform:GetWorldPosition()
        local theta
        if tryattack and proxy then
            theta = proxy.Transform:GetRotation() * DEGREES + (math.random() * 0.5 - 0.25) * PI
        else
            theta = math.random() * 2 * PI
        end
        local range = proxy and moverange or math.random() * moverange
        x = x + range * math.cos(theta)
        z = z - range * math.sin(theta)
        inst.Transform:SetPosition(x, 0, z)
        if shadowskittish then
            shadowskittish.Transform:SetPosition(x, 0, z)
        end
    end

    -- 伪装系统：靠近目标
    local function goneartarget(inst, target, rangesq, shortrange, shadowskittish)
        local faraway = inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675))
        if faraway and (inst.hidetask2hmidx or 0) == 5 then
            if shadowskittish then
                shadowskittish.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst:DoTaskInTime(0, inst.Remove)
            return
        end
        
        local x, y, z = inst.Transform:GetWorldPosition()
        local theta = inst:GetAngleToPoint(target.Transform:GetWorldPosition()) * DEGREES
        
        if faraway then
            shortrange = -shortrange
        else
            local range = math.sqrt(rangesq)
            local leftrange = range - shortrange
            if leftrange < 0 then
                leftrange = math.clamp(leftrange, -TUNING.SHADOWCREATURE_TARGET_DIST / 2, -TUNING.SHADOWCREATURE_TARGET_DIST / 4)
                shortrange = range - leftrange
            elseif leftrange < TUNING.SHADOWCREATURE_TARGET_DIST / 2 then
                leftrange = math.clamp(leftrange, TUNING.SHADOWCREATURE_TARGET_DIST / 4, TUNING.SHADOWCREATURE_TARGET_DIST / 2)
                shortrange = range - leftrange
            elseif leftrange > TUNING.SHADOWCREATURE_TARGET_DIST then
                leftrange = TUNING.SHADOWCREATURE_TARGET_DIST
                shortrange = range - leftrange
            end
        end
        
        x = x + shortrange * math.cos(theta)
        z = z - shortrange * math.sin(theta)
        inst.Transform:SetPosition(x, 0, z)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        
        if shadowskittish then
            shadowskittish.Transform:SetPosition(x, 0, z)
            shadowskittish:ForceFacePoint(target.Transform:GetWorldPosition())
        end
    end

    -- 伪装系统：开始伪装技能
    local function trystarthidetask(inst, switchskittish, switchhide)
        -- 检查是否应该退出伪装
        if inst.wantstodespawn or inst.locktarget2hm or inst.components.health:IsDead() then
            trystophidetask(inst)
            return
        end
        
        -- 切换隐藏时的中断检查
        if inst.hidetask2hm and switchhide and 
        (inst.skittishnear2hm or 
            (inst.components.combat.target and not inst.components.combat.target:HasTag("player") and
            inst.components.combat.target:IsNear(inst, TUNING.SHADOWCREATURE_TARGET_DIST))) then
            inst.skittishnear2hm = nil
            trystophidetask(inst)
            return
        end
        
        -- 首次进入伪装
        if not inst.hidetask2hm then
            if inst.components.combat.target or 
            not (TheWorld:HasTag("cave") or TheWorld.state.isnight or inst:HasTag("nightmarecreature")) or
            (inst.components.timer and inst.components.timer:TimerExists("hidecd2hm")) then
                if switchskittish then
                    inst.sg:GoToState("appear")
                end
                return
            end
            
            inst:RemoveFromScene()
            if inst.Physics then
                inst.Physics:SetActive(true)
            end
            inst.hidetask2hm = inst:DoTaskInTime(0.25, trystarthidetask, true)
            
            if not inst.onskittish2hmremovefn then
                inst.onskittish2hmremovefn = function()
                    if inst:IsValid() then
                        inst:DoTaskInTime(0, trystarthidetask, nil, true)
                    end
                end
            end
        elseif switchskittish or switchhide then
            local player, rangesq
            if inst.components.combat.target then
                player = inst.components.combat.target
                rangesq = inst:GetDistanceSqToInst(player)
            elseif inst.spawnedforplayer and inst.spawnedforplayer:IsValid() then
                player = inst.spawnedforplayer
                rangesq = inst:GetDistanceSqToInst(player)
            else
                player, rangesq = findnearplayer(inst)
            end
            
            if switchskittish then
                -- 化形阶段
                if inst.hidetask2hm ~= true then
                    inst.hidetask2hm:Cancel()
                end
                if inst.hidetask2hmidx == nil or (inst.hidetask2hmidx < 5 and player and player:IsValid() and rangesq) then
                    inst.hidetask2hmidx = (inst.hidetask2hmidx or 0) + 1
                    inst.hidetask2hm = true
                    
                    local shadowskittish = SpawnPrefab("shadowskittish2hm")
                    shadowskittish.master2hm = inst
                    inst:ListenForEvent("onremove", inst.onskittish2hmremovefn, shadowskittish)
                    if inst:HasTag("nightmarecreature") then
                        shadowskittish:AddTag("nightmarecreaturefx2hm")
                    end
                    
                    if not inst.components.combat.target then
                        if inst.spawnedforplayer and inst.spawnedforplayer:IsValid() then
                            randommoveinst(inst, 15 - inst.hidetask2hmidx * 1.5, shadowskittish, inst.spawnedforplayer, math.random() < 0.5)
                        else
                            if shadowskittish.deathtask and shadowskittish.deathtask.fn then
                                local fn = shadowskittish.deathtask.fn
                                shadowskittish.deathtask:Cancel()
                                shadowskittish.deathtask = inst:DoTaskInTime(5 + 10 * math.random(), fn)
                            end
                            randommoveinst(inst, TUNING.SHADOWCREATURE_TARGET_DIST / 4, shadowskittish)
                        end
                    else
                        goneartarget(inst, inst.components.combat.target, rangesq, TUNING.SHADOWCREATURE_TARGET_DIST / 3, shadowskittish)
                    end
                    
                    local fx = SpawnPrefab("shadow_teleport_in2hm")
                    fx.Transform:SetPosition(shadowskittish.Transform:GetWorldPosition())
                    fx.Transform:SetScale(0.5, 0.5, 0.5)
                else
                    trystophidetask(inst)
                end
            elseif switchhide then
                -- 隐藏阶段
                if inst.hidetask2hm ~= true then
                    inst.hidetask2hm:Cancel()
                end
                if player and player:IsValid() and rangesq then
                    inst.hidetask2hm = inst:DoTaskInTime(0.25, trystarthidetask, true)
                else
                    trystophidetask(inst)
                end
            end
        elseif inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675)) then
            inst:DoTaskInTime(0, inst.Remove)
        end
    end

    local function waketrystarthidetask(inst)
        if GetTime() - inst.spawntime > 1 then
            trystarthidetask(inst)
        end
    end


    -- 尖喙初始化
    local beaks = {"terrorbeak", "nightmarebeak"}
    for _, beak in ipairs(beaks) do
        AddPrefabPostInit(beak, function(inst)
            if not TheWorld.ismastersim then return end
            inst.canlunge2hm = true
            if not inst.components.timer then
                inst:AddComponent("timer")
            end
            inst:ListenForEvent("death", TrapSpellFn)
            inst.followtosea = nil
            inst:ListenForEvent("entitywake", waketrystarthidetask)
            inst:ListenForEvent("droppedtarget", trystarthidetask)
        end)
    end

    -- 音效播放系统
    local function FinishExtendedSound(inst, soundid)
        inst.SoundEmitter:KillSound("sound_" .. tostring(soundid))
        inst.sg.mem.soundcache[soundid] = nil
        if inst.sg.statemem.readytoremove and next(inst.sg.mem.soundcache) == nil then
            inst:Remove()
        end
    end

    local function PlayExtendedSound(inst, soundname)
        if inst.sg.mem.soundcache == nil then
            inst.sg.mem.soundcache = {}
            inst.sg.mem.soundid = 0
        else
            inst.sg.mem.soundid = inst.sg.mem.soundid + 1
        end
        inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
        inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_" .. tostring(inst.sg.mem.soundid))
        inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
    end

    -- 冲刺技能：前置状态
    AddStategraphState("shadowcreature", State {
        name = "lunge_pre2hm",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            if target == nil then
                target = inst.components.combat.target
            end
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = target:GetPosition()
                inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
            else
                target = nil
                if inst.components.timer and not inst.components.timer:TimerExists("shadowstrikecd2hm") then
                    inst.components.timer:StartTimer("shadowstrikecd2hm", 1.5)
                end
                inst.sg.statemem.lunge = true
                inst.sg.mem.dosecondlunge2hm = nil
                inst.sg:GoToState("idle")
                return
            end
            
            local fx = SpawnPrefab(math.random() < .5 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx")
            local x, y, z = inst.Transform:GetWorldPosition()
            fx.Transform:SetPosition(x, y + 1.5, z)
            inst:StopBrain()
            inst.AnimState:PlayAnimation("disappear")
            PlayExtendedSound(inst, "taunt")
            
            if inst.sg.mem.dolonglunge2hm then
                inst.sg.mem.dosecondlunge2hm = true
                inst.components.combat:StartAttack()
            elseif not inst.sg.mem.dosecondlunge2hm and 
                math.random() < (0.25 + (inst.exchangetimes2hm or 0) * 0.125) then
                inst.sg.mem.longlungepre2hm = true
            else
                inst.sg.mem.longlungepre2hm = nil
                inst.components.combat:StartAttack()
            end
        end,
        
        onupdate = function(inst)
            if inst.sg.statemem.target ~= nil then
                if inst.sg.statemem.target:IsValid() then
                    inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
                else
                    inst.sg.statemem.target = nil
                end
            end
        end,
        
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.lunge = true
                    if inst.sg.mem.longlungepre2hm then
                        inst.sg.mem.dolonglunge2hm = true
                        inst.sg.mem.longlungepre2hm = nil
                        inst.sg:GoToState("lunge_pre2hm", inst.sg.statemem.target)
                    else
                        inst.sg:GoToState("lunge_loop2hm", {target = inst.sg.statemem.target, targetpos = inst.sg.statemem.targetpos})
                    end
                end
            end)
        },
        
        onexit = function(inst)
            if not inst.sg.statemem.lunge then
                inst.sg.mem.longlungepre2hm = nil
                inst.sg.mem.dosecondlunge2hm = nil
                inst.components.combat:CancelAttack()
                if inst.components.timer and not inst.components.timer:TimerExists("shadowstrikecd2hm") then
                    inst.components.timer:StartTimer("shadowstrikecd2hm", 1)
                end
                inst:RestartBrain()
            end
        end
    })


    -- 冲刺技能：执行状态
    AddStategraphState("shadowcreature", State {
        name = "lunge_loop2hm",
        tags = {"attack", "busy", "noattack", "temp_invincible"},
        
        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("disappear")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
            inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_shadow_med_sharp")
            PlayExtendedSound(inst, "attack_grunt")
            
            if inst.components.timer ~= nil then
                inst.components.timer:StopTimer("shadowstrikecd2hm")
                inst.components.timer:StartTimer("shadowstrikecd2hm", 12.5 + math.random() * 5)
            end
            
            inst.sg.mem.dosecondlunge2hm = not inst.sg.mem.dosecondlunge2hm
            
            if data ~= nil then
                if data.target ~= nil and data.target:IsValid() then
                    inst.sg.statemem.target = data.target
                    inst:ForceFacePoint(data.target.Transform:GetWorldPosition())
                elseif data.targetpos ~= nil then
                    inst:ForceFacePoint(data.targetpos)
                end
            end
            
            inst.sg.statemem.startpos = inst:GetPosition()
            inst.sg:SetTimeout(4 * FRAMES)
        end,
        
        ontimeout = function(inst)
            inst.Physics:SetMotorVelOverride(inst.sg.mem.dolonglunge2hm and 50 or 30, 0, 0)
            inst.sg.mem.dolonglunge2hm = nil
        end,
        
        onupdate = function(inst)
            if inst.sg.statemem.attackdone or not inst.sg.statemem.target then
                return
            end
            local target = inst.sg.statemem.target
            if not target:IsValid() then
                inst.sg.statemem.target = nil
            elseif inst:IsNear(target, TheWorld:HasTag("cave") and 2 or 1) then
                local fx = SpawnPrefab(math.random() < .5 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx")
                local x, y, z = target.Transform:GetWorldPosition()
                fx.Transform:SetPosition(x, y + 1.5, z)
                fx.Transform:SetRotation(inst.Transform:GetRotation())
                
                inst.components.combat.externaldamagemultipliers:SetModifier(inst, TheWorld:HasTag("cave") and 0.5 or 0.25, "shadowstrike")
                inst.components.combat:DoAttack(target)
                DropPlayerWeapon2hm(inst, target)
                inst.sg.statemem.attackdone = true
            end
        end,
        
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("appear")
                end
            end)
        },
        
        onexit = function(inst)
            inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "shadowstrike")
            if not inst.sg.mem.dosecondlunge2hm then
                inst.components.combat:SetRange(3)
            end
            inst:RestartBrain()
        end
    })


    -- 状态图修改：触发冲刺和伪装
    AddStategraphPostInit("shadowcreature", function(sg)
        local doattack = sg.events.doattack.fn
        sg.events.doattack.fn = function(inst, data, ...)
            if inst.canlunge2hm and ((inst.components.timer ~= nil and not inst.components.timer:TimerExists("shadowstrikecd2hm")) or inst.sg.mem.dosecondlunge2hm) then
                inst.sg:GoToState("lunge_pre2hm", data.target)
                return
            end
            return doattack(inst, data, ...)
        end
        
        sg.states.hit.tags.noattack = true
        
        local idle = sg.states.idle.onenter
        sg.states.idle.onenter = function(inst, ...)
            if inst.canlunge2hm and inst.components.timer and not inst.components.timer:TimerExists("shadowstrikecd2hm") then
                inst.components.combat:SetRange(TheWorld:HasTag("cave") and 10 or 5)
            end
            if inst.canlunge2hm and not inst.components.combat.target and not inst.helptask2hm and 
            not inst.locktarget2hm and not inst.wantstodespawn and
            not (inst.components.timer and inst.components.timer:TimerExists("hidecd2hm")) and
            (TheWorld:HasTag("cave") or TheWorld.state.isnight or inst:HasTag("nightmarecreature")) and 
            GetTime() - inst.spawntime > 1 then
                inst.sg:GoToState("taunt")
                inst.sg:AddStateTag("attack")
                inst.AnimState:PlayAnimation("disappear")
                inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), trystarthidetask, true)
            end
            idle(inst, ...)
        end
        
        local appear = sg.states.appear.onenter
        sg.states.appear.onenter = function(inst, ...)
            appear(inst, ...)
            if inst.canlunge2hm and not inst.components.combat.target and not inst.helptask2hm and 
            not inst.locktarget2hm and not inst.wantstodespawn and
            not (inst.components.timer and inst.components.timer:TimerExists("hidecd2hm")) and
            (TheWorld:HasTag("cave") or TheWorld.state.isnight or inst:HasTag("nightmarecreature")) and 
            GetTime() - inst.spawntime > 1 then
                inst:DoTaskInTime(0, trystarthidetask, true)
            end
        end
    end)


    -- 清除00坐标影怪
    local shadowmonster_todetect = {"crawlinghorror", "terrorbeak", "oceanhorror", "crawlingnightmare", "nightmarebeak"}
    local function removemonster00(inst)
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        if ix == 0 and iz == 0 then
            inst.wantstodespawn = true
        end
    end

    for _, monster in ipairs(shadowmonster_todetect) do
        AddPrefabPostInit(monster, function(inst)
            if not TheWorld.ismastersim then return end
            inst:DoTaskInTime(7, removemonster00)
        end)
    end

end 

-- ========================================
-- 寄生暗影增强
if GetModConfigData("shadowleech") then

    local speedup = GetModConfigData("extra_change") and GetModConfigData("notboss_speed") or 1

    -- 属性调整
    TUNING.SHADOW_LEECH_HEALTH = TUNING.SHADOW_LEECH_HEALTH * 2
    if speedup < 1.17 then
        TUNING.SHADOW_LEECH_RUNSPEED = TUNING.SHADOW_LEECH_RUNSPEED * 1.17 / speedup
    end

    -- 寄生暗影死亡回san
    local function onkilledbyother(inst, attacker)
        if attacker ~= nil and attacker.components.sanity ~= nil then
            attacker.components.sanity:DoDelta(TUNING.SANITY_SMALL)
        end
    end

    -- 杀死寄生暗影
    local function killleech(leech)
        if not leech.regen2hm and leech.components.lootdropper then
            leech.components.lootdropper:SetLoot()
            leech.components.lootdropper:SetChanceLootTable()
            leech.components.lootdropper.SpawnLootPrefab = nillootdropperSpawnLootPrefab
            leech.components.lootdropper.GenerateLoot = emptytablefn
            leech.components.lootdropper.DropLoot = emptytablefn
        end
        if leech.regen2hm then
            leech.regen2hm = nil
        end
        if leech.components.health and not leech.components.health:IsDead() then
            leech.components.health:Kill()
        end
    end

    -- 寄生暗影附着玩家
    local function AttachLeech(inst, leech, noreact)
        if inst:HasTag("playerghost") then
            killleech(leech)
            inst.leechattachindex2hm = 0
            return
        end
        
        inst.leechattachindex2hm = inst.leechattachindex2hm + 1
        inst:PushEvent("regenleech2hm")
        
        if inst.components.health then
            inst.components.health:DoDelta(-math.random(3, 8), false, "shadow_leech")
        end
        if inst.components.sanity then
            inst.components.sanity:DoDelta(-math.random(2, 5))
        end
        if inst.components.hunger then
            inst.components.hunger:DoDelta(-math.random(2, 5))
        end
        
        if inst.leechattachindex2hm >= 6 then
            inst.leechattachindex2hm = 0
            inst:PushEvent("knockback", {
                knocker = leech,
                radius = 3,
                strengthmult = (inst.components.inventory ~= nil and inst.components.inventory:ArmorHasTag("heavyarmor") or 
                            inst:HasTag("heavybody")) and 0.35 or 0.7,
                forcelanded = false
            })
        elseif inst.leechattachindex2hm % 2 == 1 then
            inst:PushEvent("attacked", {attacker = leech, damage = 0})
        end
        
        if not leech.regen2hm then
            leech.regen2hm = true
            if leech.components.lootdropper then
                leech.components.lootdropper:SetLoot()
                leech.components.lootdropper:SetChanceLootTable()
                leech.components.lootdropper.SpawnLootPrefab = nillootdropperSpawnLootPrefab
                leech.components.lootdropper.GenerateLoot = emptytablefn
                leech.components.lootdropper.DropLoot = emptytablefn
            end
            if leech.components.combat then
                leech.components.combat.onkilledbyother = nil
            end
            if not leech.regenfx2hm then
                leech.regenfx2hm = SpawnPrefab("tophat_shadow_fx")
                leech.regenfx2hm.entity:SetParent(leech.entity)
            end
        end
        return true
    end

    -- 寄生暗影移除监听
    local function onleechremove(leech)
        local inst = leech.target2hm
        if not (inst and inst:IsValid()) then return end
        for i = #inst.leechs2hm, 1, -1 do
            if inst.leechs2hm[i] == leech then
                table.remove(inst.leechs2hm, i)
                break
            end
        end
        if leech.regen2hm then
            inst:PushEvent("regenleech2hm")
        end
    end

    -- 寄生暗影锁定目标
    local function locktarget(inst)
        if inst.target2hm and inst.target2hm:IsValid() and inst.components.combat then
            inst.components.combat:SetTarget(inst.target2hm)
        end
    end

    -- 寄生暗影仇恨共享
    local function LeechShareTargetFn(dude)
        return dude.prefab ~= "shadow_leech" and dude:HasTag("shadowcreature") and not dude.components.health:IsDead()
    end

    local function OnLeechAttacked(inst, data)
        if data and data.attacker then
            inst.components.combat:ShareTarget(data.attacker, 30, LeechShareTargetFn, 1)
        end
        locktarget(inst)
    end

    -- 寄生暗影传送
    local function teleportleech(leech)
        local pos = leech.target2hm:GetPosition()
        local theta = math.random() * TWOPI
        local x, z = pos.x, pos.z
        for r = 16, 8, -1 do
            local offset = FindWalkableOffset(pos, theta, r + math.random(), 4, false, true)
            if offset ~= nil then
                x = x + offset.x
                z = z + offset.z
                break
            end
        end
        leech.Transform:SetPosition(x, 0, z)
        locktarget(leech)
    end

    local function onleechwake(leech)
        if leech.teleporttask2hm then
            leech.teleporttask2hm:Cancel()
            leech.teleporttask2hm = nil
        end
    end

    local function onleechsleep(leech)
        if leech.target2hm and leech.target2hm:IsValid() and not leech.teleporttask2hm then
            leech.teleporttask2hm = leech:DoTaskInTime(7, teleportleech)
        end
    end

    -- 寄生暗影生成条件检测
    local function canspawnleech(inst)
        -- 基础条件检查
        local can_spawn = inst.components.sanity:IsInsane() and 
                        not inst.components.health:IsDead() and 
                        not inst:HasOneOfTags({"sleeping", "shadowdominance", "playerghost"}) and
                        #inst.leechs2hm < (inst.maxleech2hm or 3) and 
                        inst:GetCurrentPlatform() == nil
        
        -- 检查附近Boss战
        if can_spawn then
            local x, y, z = inst.Transform:GetWorldPosition()
            local bosses = TheSim:FindEntities(x, y, z, 30, {"_combat"}, {"FX", "NOCLICK", "INLIMBO", "player"}, {"epic", "shadowchesspiece"})
            
            local function IsTargetingPlayer(boss)
                local target = boss.components.combat and boss.components.combat.target
                return target ~= nil and (target:HasTag("player") or target:HasTag("companion") or target:HasTag("abigail"))
            end
            
            for i, v in ipairs(bosses) do
                if IsTargetingPlayer(v) then
                    can_spawn = false
                    break
                end
            end  
        end
        
        return can_spawn
    end

    -- 吸引寄生暗影生成
    local function attractleechs(inst)
        inst.attractleechstask2hm = nil
        if not canspawnleech(inst) then return end
        
        local pos = inst:GetPosition()
        local theta = math.random() * TWOPI
        local x, z = pos.x, pos.z
        
        for i = 1, (inst.maxleech2hm or 3) - #inst.leechs2hm do
            local leech = SpawnPrefab("shadow_leech")
            leech.target2hm = inst
            leech:AddTag("attachplayer2hm")
            leech:AddTag("notaunt")
            leech.AnimState:SetMultColour(1, 1, 1, 0.25)
            leech.persists = false
            leech.OnEntitySleep = onleechsleep
            leech.OnEntityWake = onleechwake
            
            if leech.components.combat then
                leech.components.combat.onkilledbyother = onkilledbyother
                leech.components.combat:SetTarget(inst)
            end
            
            for r = 4, 2, -1 do
                local offset = FindWalkableOffset(pos, theta, r + math.random() * 0.5, 4, false, true)
                if offset ~= nil then
                    x = x + offset.x
                    z = z + offset.z
                    break
                end
            end
            
            leech.Transform:SetPosition(x, 0, z)
            leech:OnSpawnFor(inst, 0.4 + i * 0.3 + math.random() * 0.2)
            theta = theta + TWOPI / 3
            table.insert(inst.leechs2hm, leech)
            leech:ListenForEvent("attacked", OnLeechAttacked)
            leech:ListenForEvent("jump", locktarget)
            leech:ListenForEvent("newcombattarget", locktarget)
            leech:ListenForEvent("onremove", onleechremove)
        end
    end

    -- 重新生成寄生暗影
    local function regenleech(inst)
        if inst.attractleechstask2hm then
            inst.attractleechstask2hm:Cancel()
        end
        attractleechs(inst)
    end

    -- 掉理智触发
    local function inducedinsanity(inst, val)
        if not inst:HasTag("shadowdominance") and not inst.attractleechstask2hm and val and 
        canspawnleech(inst) and math.random() < (TheWorld:HasTag("cave") and 0.35 or 0.175) then
            inst.attractleechstask2hm = inst:DoTaskInTime(math.random(3, 10), attractleechs)
        end
    end

    -- 理智低于阈值时触发
    local function atinsane(inst)
        if inst.leechs2hm and not inst:HasTag("shadowdominance") and not inst.attractleechstask2hm and 
        canspawnleech(inst) and math.random() < (TheWorld:HasTag("cave") and 0.025 or 0.013) then
            inst.attractleechstask2hm = inst:DoTaskInTime(math.random(3, 10), attractleechs)
        end
    end

    -- 进入疯狂状态触发
    local function goinsane(inst)
        if inst.components.inventory then
            for k, v in pairs(EQUIPSLOTS) do
                local equip = inst.components.inventory:GetEquippedItem(v)
                if equip and equip:IsValid() and equip.prefab == "skeletonhat" then
                    return
                end
            end
        end
        if inst and math.random() < (TheWorld:HasTag("cave") and 0.1 or 0.05) and 
        canspawnleech(inst) and not inst.attractleechstask2hm then
            inst.attractleechstask2hm = inst:DoTaskInTime(math.random(3, 10), attractleechs)
        end
    end

    AddComponentPostInit("shadowcreaturespawner", function(self)
        local oldSpawnShadowCreature = self.SpawnShadowCreature
        self.SpawnShadowCreature = function(self, player, params, ...)
            atinsane(player)
            return oldSpawnShadowCreature(self, player, params, ...)
        end
    end)


    -- 移除所有寄生暗影
    local function removeleechs(inst)
        for index, leech in ipairs(inst.leechs2hm) do
            killleech(leech)
        end
    end

    local function sanitymodechanged(inst, data)
        if data and data.mode == SANITY_MODE_LUNACY then
            removeleechs(inst)
        end
    end

    -- 玩家初始化
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then return end
        if inst.AttachLeech then return end
        
        inst.leechs2hm = {}
        inst.leechattachindex2hm = 0
        inst.AttachLeech = AttachLeech
        inst:ListenForEvent("regenleech2hm", regenleech)
        
        inst:ListenForEvent("inducedinsanity", inducedinsanity)
        inst:ListenForEvent("goinsane", goinsane)
        
        inst:ListenForEvent("death", removeleechs)
        inst:ListenForEvent("ms_becameghost", removeleechs)
        inst:ListenForEvent("onremove", removeleechs)
        inst:ListenForEvent("sanitymodechanged", sanitymodechanged)
    end)

    -- 寄生暗影视觉效果
    local function CLIENT_ShadowLeech_HostileToPlayerTest(inst, player)
        local combat = inst.replica.combat
        if combat ~= nil and combat:GetTarget() == player then
            return true
        end
        local sanity = player.replica.sanity
        if sanity ~= nil and sanity:IsCrazy() then
            return true
        end
        return false
    end

    local function updateleech(inst)
        if inst:HasTag("attachplayer2hm") and not inst.HostileToPlayerTest then
            inst.HostileToPlayerTest = CLIENT_ShadowLeech_HostileToPlayerTest
            if inst.components.transparentonsanity then
                inst.components.transparentonsanity.most_alpha = .4
                inst.components.transparentonsanity.osc_amp = .25
                inst.components.transparentonsanity:ForceUpdate()
            end
        end
    end

    AddPrefabPostInit("shadow_leech", function(inst)
        if TheWorld.has_ocean then
            inst.Physics:ClearCollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.GROUND)
        end
        inst:DoTaskInTime(0, updateleech)
    end)

end 

-- ========================================
-- 恐怖利爪增强 
if GetModConfigData("oceanshadow") then

    TUNING.enableoceanhorror2hm = true
    TUNING.OCEANHORROR.DAMAGE = 30

    -- 速度和攻速调整
    local speedup = GetModConfigData("extra_change") and GetModConfigData("notboss_speed") or 1
    local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("notboss_attackspeed") or 1
    if speedup < 1.75 then
        TUNING.OCEANHORROR.SPEED = TUNING.OCEANHORROR.SPEED * 1.75 / speedup
    end
    if attackspeedup < 1.33 then
        TUNING.OCEANHORROR.ATTACK_PERIOD = TUNING.OCEANHORROR.ATTACK_PERIOD * 3 / 4 * attackspeedup
    end

    -- 恐怖利爪初始化
    local brain = require("brains/shadowcreaturebrain")
    AddPrefabPostInit("oceanhorror", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.timer then
            inst:AddComponent("timer")
        end
        if inst._update_task then
            inst._update_task:Cancel()
        end
        inst:SetBrain(brain)
        inst:SetStateGraph("SGshadowcreature")
        inst.cantaunt2hm = true
    end)


    -- 嘲讽技能系统
    local function stoptaunttask(inst, nearplayer)
        inst.taunttask2hm:Cancel()
        inst.taunttask2hm = nil
        inst.components.timer:StartTimer("tauntcd2hm", 6)
        if inst._ripples ~= nil and inst._ripples:IsValid() then
            inst._ripples.AnimState:SetScale(1, 1)
        end
    end

    local function checknearplayer(inst)
        local player = FindClosestPlayerToInst(inst, 1, true)
        if player and player:IsValid() and not (player.sg and player.sg:HasStateTag("knockout")) then
            local knocker = inst.src2hm and inst.src2hm:IsValid() and inst.src2hm or inst
            player:PushEvent("knockback", {
                knocker = knocker,
                radius = 3,
                strengthmult = (player.components.inventory ~= nil and player.components.inventory:ArmorHasTag("heavyarmor") or 
                            player:HasTag("heavybody")) and 0.7 or 1,
                forcelanded = true
            })
            if TheWorld.has_ocean then
                inst.targets2hm = inst.targets2hm or {}
                local boat = player:GetCurrentPlatform()
                if boat and boat:IsValid() and boat:HasTag("boat") and boat.components.boatphysics and not inst.targets2hm[boat] then
                    inst.targets2hm[boat] = true
                    local _x, _y, _z = knocker.Transform:GetWorldPosition()
                    local x, y, z = boat.Transform:GetWorldPosition()
                    local nx, nz = VecUtil_Normalize(_x - x, _z - z)
                    boat.components.boatphysics:ApplyRowForce(_x - x, _z - z, 1, 6)
                end
            end
        end
    end

    local function cantaunt(inst)
        return inst.components.health:GetPercent() < (1 - 0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675))
    end

    local WAKEANIMS = {"idle_loop_1", "idle_loop_2", "idle_loop_3"}
    local function dotaunttask(inst)
        inst.taunttask2hmindex = inst.taunttask2hmindex + 1
        if inst.taunttask2hmindex > 24 or inst.components.health:IsDead() or not cantaunt(inst) then
            stoptaunttask(inst)
            return
        end
        
        local player = FindClosestPlayerToInst(inst, 100, true)
        if player and player:IsValid() then
            local _x, _y, _z = inst.Transform:GetWorldPosition()
            local x, y, z = player.Transform:GetWorldPosition()
            local rotation = inst:GetAngleToPoint(x, y, z)
            local wake = SpawnPrefab("boatwaterfx2hm")
            wake.src2hm = inst
            local theta = rotation * DEGREES
            wake.Transform:SetPosition(_x + 2 * math.cos(theta), 0, _z - math.sin(theta))
            wake.Transform:SetRotation(rotation)
            wake.AnimState:SetMultColour(0, 0, 0, 0.5)
            inst.wakeanimidx2hm = (inst.wakeanimidx2hm + (math.random() > 0.5 and 1 or -1)) % #WAKEANIMS
            wake.AnimState:PlayAnimation(WAKEANIMS[inst.wakeanimidx2hm + 1])
            if wake.components.boattrailmover then
                local nx, nz = VecUtil_Normalize(_x - x, _z - z)
                wake.components.boattrailmover:Setup(nx, nz, 4, 0)
            end
            wake:DoPeriodicTask(FRAMES, checknearplayer)
        else
            stoptaunttask(inst)
        end
    end


    -- 状态图修改
    AddStategraphPostInit("shadowcreature", function(sg)
        local idle = sg.states.idle.onenter
        sg.states.idle.onenter = function(inst, ...)
            -- 击飞技能触发检查
            if inst.cantaunt2hm and (inst.taunttask2hm and inst.prefab == "oceanhorror" or
                (not inst.locktarget2hm and not inst.taunttask2hm and inst.components.timer and 
                not inst.components.timer:TimerExists("tauntcd2hm") and cantaunt(inst))) then
                inst.sg:GoToState("taunt")
                return
            -- 恐怖利爪形态转换（需要同时启用爬行恐惧和恐怖尖喙）
            elseif GetModConfigData("crawlingshadow") and GetModConfigData("shadowbeak") and inst.cantaunt2hm and not inst.taunttask2hm and not inst.wantstodespawn and 
                inst.components.combat.target and inst.components.combat.target:HasTag("player") then
                if inst.prefab == "oceanhorror" and not inst.disableexchange2hm and 
                inst.components.health:GetPercent() > (0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675)) then
                    local timeleft = inst.components.timer and inst.components.timer:GetTimeLeft("tauntcd2hm")
                    local replace = SpawnPrefab("oceanhorror2hm")
                    replace.simple2hm = true
                    replace.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    replace.Transform:SetRotation(inst.Transform:GetRotation())
                    replace.canexchange2hm = inst.canexchange2hm
                    replace.exchangetimes2hm = inst.exchangetimes2hm
                    replace.exchangeprefab2hm = "crawlinghorror"
                    replace.components.health:SetPercent(inst.components.health:GetPercent())
                    replace.components.combat:SetTarget(inst.components.combat.target)
                    if replace.components.timer and timeleft then
                        replace.components.timer:StartTimer("tauntcd2hm", timeleft)
                    end
                    replace.sg:GoToState("idle")
                    TheWorld:PushEvent("ms_exchangeshadowcreature", {ent = inst, exchangedent = replace})
                    inst:DoTaskInTime(0, inst.Remove)
                elseif TheWorld.has_ocean and not TheWorld:HasTag("cave") and inst.prefab == "oceanhorror2hm" and 
                    inst.simple2hm and
                    (not inst.components.combat.target or 
                        inst.components.health:GetPercent() <= (0.25 / (1 - (inst.exchangetimes2hm or 0) * 0.0675))) and
                    inst:IsOnOcean() then
                    local timeleft = inst.components.timer and inst.components.timer:GetTimeLeft("tauntcd2hm")
                    local replace = SpawnPrefab("oceanhorror")
                    replace.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    replace.Transform:SetRotation(inst.Transform:GetRotation())
                    replace.canexchange2hm = inst.canexchange2hm
                    replace.exchangetimes2hm = inst.exchangetimes2hm
                    replace.exchangeprefab2hm = "crawlinghorror"
                    replace.components.health:SetPercent(inst.components.health:GetPercent())
                    replace.components.combat:SetTarget(inst.components.combat.target)
                    if replace.components.timer and timeleft then
                        replace.components.timer:StartTimer("tauntcd2hm", timeleft)
                    end
                    replace.sg:GoToState("idle")
                    TheWorld:PushEvent("ms_exchangeshadowcreature", {ent = inst, exchangedent = replace})
                    inst:DoTaskInTime(0, inst.Remove)
                end
            end
            idle(inst, ...)
        end
        
        local attack = sg.states.attack.onenter
        sg.states.attack.onenter = function(inst, ...)
            if inst.cantaunt2hm and not inst.locktarget2hm and not inst.taunttask2hm and 
            inst.components.timer and not inst.components.timer:TimerExists("tauntcd2hm") and cantaunt(inst) then
                inst.sg:GoToState("taunt")
                return
            end
            attack(inst, ...)
        end
        
        local taunt = sg.states.taunt.onenter
        sg.states.taunt.onenter = function(inst, ...)
            if inst.cantaunt2hm and not inst.locktarget2hm and not inst.taunttask2hm and 
            inst.components.timer and not inst.components.timer:TimerExists("tauntcd2hm") and cantaunt(inst) then
                inst.taunttask2hmindex = 0
                inst.wakeanimidx2hm = 0
                inst.taunttask2hm = inst:DoPeriodicTask(8 * FRAMES, dotaunttask, 0.25)
                if inst._ripples ~= nil and inst._ripples:IsValid() then
                    inst._ripples.AnimState:SetScale(2, 2)
                end
            end
            taunt(inst, ...)
        end
        
        local hit = sg.states.hit.onenter
        sg.states.hit.onenter = function(inst, ...)
            if inst.taunttask2hm then
                stoptaunttask(inst)
            end
            hit(inst, ...)
        end
    end)

end 

-- ========================================
-- 潜伏梦魇增强
if GetModConfigData("ruinsnightmare") then
    
    -- 目标理智50%→0%时，移速1倍→2.5倍线性变化
    local function UpdateSpeedByTargetSanity2hm(inst)
        if not inst.components.locomotor then 
            return 
        end
        
        local target = inst.components.combat and inst.components.combat.target
        if not target or not target:IsValid() or not target.components.sanity then
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ruinsnightmare_sanity_speed2hm")
            return
        end
        
        local sanity_percent = target.components.sanity:GetPercent()
        
        if sanity_percent >= 0.5 then
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ruinsnightmare_sanity_speed2hm")
        else
            local speed_mult = 1 + (0.5 - sanity_percent) / 0.5 * 1.5
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "ruinsnightmare_sanity_speed2hm", speed_mult)
        end
    end
    
    local function OnNewTarget2hm(inst, data)
        UpdateSpeedByTargetSanity2hm(inst)
    end

    local function OnDropTarget2hm(inst, data)
        if inst.components.locomotor then
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ruinsnightmare_sanity_speed2hm")
        end
    end

    local function OnTargetSanityDelta2hm(target)
        if not target or not target:IsValid() or not target.components.sanity then
            return
        end
        
        -- 查找所有以该玩家为目标的潜伏梦魇
        local x, y, z = target.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 40, nil, {"INLIMBO"})
        for _, ent in ipairs(ents) do
            if ent.prefab == "ruinsnightmare" and ent.components.combat and ent.components.combat.target == target then
                UpdateSpeedByTargetSanity2hm(ent)
            end
        end
    end
    
    -- 监听理智变化
    local function StartListeningToTarget2hm(inst, target)
        if not target or not target:IsValid() or not target.components.sanity then 
            return 
        end

        if inst.sanity_listener_target2hm and inst.sanity_listener_target2hm:IsValid() then
            inst:RemoveEventCallback("sanitydelta", inst.sanity_delta_fn2hm, inst.sanity_listener_target2hm)
        end
   
        inst.sanity_listener_target2hm = target
        inst.sanity_delta_fn2hm = function() 
            OnTargetSanityDelta2hm(target)
        end
        inst:ListenForEvent("sanitydelta", inst.sanity_delta_fn2hm, target)
    end
    
    local function StopListeningToTarget2hm(inst)
        if inst.sanity_listener_target2hm and inst.sanity_listener_target2hm:IsValid() then
            inst:RemoveEventCallback("sanitydelta", inst.sanity_delta_fn2hm, inst.sanity_listener_target2hm)
        end
        inst.sanity_listener_target2hm = nil
    end

    local function OnNewTargetWrapper2hm(inst, data)
        OnNewTarget2hm(inst, data)
        if data and data.target then
            StartListeningToTarget2hm(inst, data.target)
        end
    end

    local function OnDropTargetWrapper2hm(inst, data)
        StopListeningToTarget2hm(inst)
        OnDropTarget2hm(inst, data)
    end

    AddPrefabPostInit("ruinsnightmare", function(inst)
        if not TheWorld.ismastersim then return end

        inst:ListenForEvent("newcombattarget", OnNewTargetWrapper2hm)
        inst:ListenForEvent("droppedtarget", OnDropTargetWrapper2hm)

        inst:ListenForEvent("onremove", function()
            StopListeningToTarget2hm(inst)
        end)
    end)
    
    -- 移动攻击
    AddStategraphPostInit("shadowcreature", function(sg)
        if not sg.states or not sg.states.attack then
            return
        end
        
        local old_attack_onenter = sg.states.attack.onenter
        sg.states.attack.onenter = function(inst, target, ...)
            if inst.prefab == "ruinsnightmare" then

                local was_moving = inst.sg and inst.sg.lasttags and inst.sg.lasttags["moving"] ~= nil
   
                if was_moving and inst.components.locomotor and target then
                    inst.ruinsnightmare_attack_moving2hm = true
                    inst.ruinsnightmare_attack_target2hm = target
                end
            end
            
            old_attack_onenter(inst, target, ...)
            
            if inst.prefab == "ruinsnightmare" and inst.ruinsnightmare_attack_moving2hm and inst.ruinsnightmare_attack_target2hm then
                if inst.ruinsnightmare_attack_target2hm:IsValid() then
                    inst:ForceFacePoint(inst.ruinsnightmare_attack_target2hm.Transform:GetWorldPosition())
                end
                inst.components.locomotor:WalkForward()
            end
        end

        if sg.states.attack.onexit then
            local old_attack_onexit = sg.states.attack.onexit
            sg.states.attack.onexit = function(inst, ...)
                if inst.prefab == "ruinsnightmare" then
                    inst.ruinsnightmare_attack_moving2hm = nil
                    inst.ruinsnightmare_attack_target2hm = nil
                end
                old_attack_onexit(inst, ...)
            end
        else
            sg.states.attack.onexit = function(inst)
                if inst.prefab == "ruinsnightmare" then
                    inst.ruinsnightmare_attack_moving2hm = nil
                    inst.ruinsnightmare_attack_target2hm = nil
                end
            end
        end
    end)
end

