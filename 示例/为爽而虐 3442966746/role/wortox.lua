local wortox_soul_common = require("prefabs/wortox_soul_common")
local wortox = require("prefabs/wortox")

-- 技能树文本改动
local SkillTreeDefs = require("prefabs/skilltree_defs")
if SkillTreeDefs.SKILLTREE_DEFS["wortox"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_panflute_playing.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_PANFLUTE_PLAYING_DESC ..
        (TUNING.isCh2hm and "\n感受到吹奏冲动后，吹奏排箫消耗的耐久减半。" or
        "\nPan Flutes will lose half durability one time when feeling this urge to play.")
    SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_panflute_soulcaller.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_PANFLUTE_SOULCALLER_DESC ..
        (TUNING.isCh2hm and "\n附近每有1个玩家，你就会召唤2个灵魂。" or
        "\nYou will summon 2 souls for each player nearby when playing the Pan Flute.")
    SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_panflute_forget.desc = 
        TUNING.isCh2hm and "\n吹奏排箫时，会让附近的生物被催眠的时间延长一倍。" or
        "\nYou will put nearby creatures to sleep for double the time when playing the Pan Flute."
end


--妥协开启时改为仅基础血量高于100的生物掉落灵魂
if TUNING.DSTU and TUNING.DSTU.WORTOXCHANGES then
    AddPrefabPostInitAny(function(inst)
        if not TheWorld.ismastersim then return end

        if inst.components.health ~= nil and not inst.components.health:IsDead() and 
            (inst.components.health.maxhealth <= 100 or inst:HasTag("abigail")) then

            if not inst:HasTag("soulless") then inst:AddTag("soulless") end

        elseif inst.components.health == nil then

            -- 处理没有血量组件的生物
            if inst.components.murderable ~= nil and not inst:HasTag("soulless") then
                inst:AddTag("soulless")
            end
            
        end

    end)
end

--沃托克斯技能树改动

--灵魂罐解锁需要远古科技；强抢袋解锁需要完整远古科技

--排箫分支改动
AddPrefabPostInit("panflute", function(inst)
    if not TheWorld.ismastersim then return end
    -- 即兴演奏技能消耗排箫耐久减半
    local function UseModifier(uses, action, doer, target, item)
        item.panflute_wortox_forget_debuff = nil
        if item.panflute_shouldfiniteuses_stopuse then
            item.panflute_shouldfiniteuses_stopuse = nil
            return 0.5
        end
        return uses
    end
    inst.components.finiteuses:SetModifyUseConsumption(UseModifier)    
    --悦耳牧歌召唤的灵魂数量受范围内玩家数量影响，每个玩家召唤2个灵魂。
    local function SummonSoul(musician, x, y, z)
        local soulfx = SpawnPrefab("wortox_soul_spawn_fx")
        soulfx.Transform:SetPosition(x, y, z)
        local soul = SpawnPrefab("wortox_soul_spawn")
        soul._soulsource = musician
        soul.Transform:SetPosition(x, y, z)
        soul:Setup(nil)
    end 
    local function DoSoulSummon(musician)
        local x, y, z = musician.Transform:GetWorldPosition()
        local spawnradius_max = TUNING.WORTOX_SOULSTEALER_RANGE - 0.1 -- Small fudge factor to keep it in range if the player does not move.
        local spawnradius_min = spawnradius_max * 0.5
        local spawnradius_max_sq = spawnradius_max * spawnradius_max
        local spawnradius_min_sq = spawnradius_min * spawnradius_min
        --设置灵魂数量
        local soul_count = #GLOBAL.FindPlayersInRange(x, y, z, spawnradius_max*2, true) * 2
        for i = 0, soul_count - 1 do
            -- Doughnut shape distribution.
            local radiusrand = math.random()
            local radiussq = radiusrand * spawnradius_max_sq + (1 - radiusrand) * spawnradius_min_sq
            local radius = math.sqrt(radiussq)
            local angle = math.random() * TWOPI
            local dx, dz = math.cos(angle) * radius, math.sin(angle) * radius
            musician:DoTaskInTime(i * 0.1 + math.random() * 0.05, SummonSoul, x + dx, y, z + dz)
        end
    end
    local OnFinishedPlaying = function(inst, musician)
        local skilltreeupdater = musician.components.skilltreeupdater
        if skilltreeupdater then
            if skilltreeupdater:IsActivated("wortox_panflute_soulcaller") then
                musician:DoTaskInTime(52 * FRAMES, DoSoulSummon) -- NOTES(JBK): Keep FRAMES in sync with SGwilson. [PFSSTS]
            end
        end
    end
    inst.components.instrument:SetOnFinishedPlayingFn(OnFinishedPlaying)        
    -- 悦耳牧歌点亮时不催眠队友,迷魂曲点亮时催眠时间延长一倍
    local function HearPanFlute(inst, musician, instrument)
        local sleeptime2hm = (musician.components.skilltreeupdater and musician.components.skilltreeupdater:IsActivated("wortox_panflute_forget") )
                            and instrument.panflute_sleeptime * 2 or instrument.panflute_sleeptime
        if musician.components.skilltreeupdater and musician.components.skilltreeupdater:IsActivated("wortox_panflute_soulcaller") then
                if inst ~= musician and (not inst:HasTag("player")) and
                    not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) and
                    not (inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck()) and
                    not (inst.components.fossilizable ~= nil and inst.components.fossilizable:IsFossilized()) then
                    local mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
                    if mount ~= nil then
                        mount:PushEvent("ridersleep", { sleepiness = 10, sleeptime = sleeptime2hm })
                    end
                    if inst.components.farmplanttendable ~= nil then
                        inst.components.farmplanttendable:TendTo(musician)
                    elseif inst.components.sleeper ~= nil then
                        inst.components.sleeper:AddSleepiness(10, sleeptime2hm)
                        --移除原迷魂曲取消生物仇恨效果
                        -- if inst.components.sleeper:IsAsleep() then
                        --     if instrument.panflute_wortox_forget_debuff and inst.components.combat then
                        --     inst:AddDebuff("wortox_forget_debuff", "wortox_forget_debuff", {toforget = musician})
                        --     end
                        -- end
                    elseif inst.components.grogginess ~= nil then
                        inst.components.grogginess:AddGrogginess(10, instrument.panflute_sleeptime)
                    else
                        inst:PushEvent("knockedout")
                    end
                end
        else
            if inst ~= musician and
                (TheNet:GetPVPEnabled() or not inst:HasTag("player")) and
                not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) and
                not (inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck()) and
                not (inst.components.fossilizable ~= nil and inst.components.fossilizable:IsFossilized()) then
                local mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
                if mount ~= nil then
                    mount:PushEvent("ridersleep", { sleepiness = 10, sleeptime2hm })
                end
                if inst.components.farmplanttendable ~= nil then
                    inst.components.farmplanttendable:TendTo(musician)
                elseif inst.components.sleeper ~= nil then
                    inst.components.sleeper:AddSleepiness(10, sleeptime2hm)
                    -- if inst.components.sleeper:IsAsleep() then
                    --     if instrument.panflute_wortox_forget_debuff and inst.components.combat then
                    --     inst:AddDebuff("wortox_forget_debuff", "wortox_forget_debuff", {toforget = musician})
                    --     end
                    -- end
                elseif inst.components.grogginess ~= nil then
                    inst.components.grogginess:AddGrogginess(10, sleeptime2hm)
                else
                    inst:PushEvent("knockedout")
                end
            end
        end
    end
    inst.components.instrument:SetOnHeardFn(HearPanFlute)
end)    





