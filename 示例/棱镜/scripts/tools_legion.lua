
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --为了不暴露局部变量，单独装一起
local SpDamageUtil = require("components/spdamageutil")
local easing = require("easing")

--[ 各种常用标签 ]--

pas.CombineTags = function(tags1, tags2)
    if tags2 ~= nil then
        for _, v in pairs(tags2) do
            table.insert(tags1, v)
        end
    end
    return tags1
end
fns.TagsCombat1 = function(othertags) --普通的攻击标签
    return pas.CombineTags({
        "INLIMBO", "NOCLICK", "notarget", "noattack", "playerghost" --"invisible"
    }, othertags)
end
fns.TagsCombat2 = function(othertags) --建筑友好的攻击标签
    return pas.CombineTags({
        "INLIMBO", "NOCLICK", "notarget", "noattack", "playerghost", --"invisible"
        "wall", "structure", "balloon"
    }, othertags)
end
fns.TagsCombat3 = function(othertags) --建筑与伙伴都友好的攻击标签
    return pas.CombineTags({
        "INLIMBO", "NOCLICK", "notarget", "noattack", "playerghost", --"invisible"
        "wall", "structure", "balloon",
        "companion", "glommer", "friendlyfruitfly", "abigail", "shadowminion"
    }, othertags)
end
fns.TagsSiving = function(othertags) --子圭系列的窃血标签
    return pas.CombineTags({
        "INLIMBO", "NOCLICK", "notarget", "noattack", "playerghost", --"invisible"
        "wall", "structure", "balloon",
        "shadowminion", "ghost", --"shadow"
        "angry_when_rowed" --水獭掠夺者窝点 会有的标签，因为这个东西没有以上别的标签，所以只能用这个
    }, othertags)
end
fns.TagsWorkable1 = function(othertags) --常见的可砍、挖、砸、凿标签(不包含“捕捉”)
    return pas.CombineTags({
        "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" --"NET_workable"
    }, othertags)
end
fns.TagsWorkable2 = function(othertags) --常见的可砍、挖、砸、凿标签，以及战斗标签
    return pas.CombineTags({
        "_combat",
        "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" --"NET_workable"
    }, othertags)
end

--[ 判断是否能攻击 ]--

pas.IsMyFollower = function(inst, ent)
    if ent.components.follower ~= nil then
        local leader = ent.components.follower:GetLeader()
        if leader ~= nil then
            if leader == inst then
                return true
            end
            if leader.components.inventoryitem ~= nil then --leader 是个物品
                leader = leader.components.inventoryitem:GetGrandOwner()
                return leader == inst
            end
        end
    -- elseif inst.components.leader ~= nil then --follower 和 leader 组件是配对的，所以不需要再判断这个组件
    --     if inst.components.leader:IsFollower(ent) then
    --         return true
    --     end
    end
    return false
end
fns.IsPlayerFollower = function(ent)
    if ent.components.follower ~= nil then
        local leader = ent.components.follower:GetLeader()
        if leader ~= nil then
            if leader:HasTag("player") then
                return true
            end
            if leader.components.inventoryitem ~= nil then --leader 是个物品
                leader = leader.components.inventoryitem:GetGrandOwner()
                return leader ~= nil and leader:HasTag("player")
            end
        end
    end
    return false
end
pas.IsEnemyPre = function(ent)
    if ent.components.combat == nil or ent:HasTag("playerghost") or
        ent.components.health == nil or ent.components.health:IsDead()
    then
        return true
    end
    if ent.sg ~= nil and (ent.sg:HasStateTag("flight") or ent.sg:HasStateTag("invisible")) then
        return true
    end
end
fns.IsEnemy_me = function(inst, ent) --是否为 inst 的当前敌人
    if pas.IsEnemyPre(ent) then return false end
    if inst == nil then return true end

    local ent_target = ent.components.combat.target
    if ent_target == inst then --仇视自己，肯定是敌人
        return true
    end

    -- local inst_cpt = inst.components.combat
    -- if inst_cpt ~= nil and inst_cpt.lastattacker == ent then
    --     --部分生物的攻击是另类的，无法以 combat.target 来识别
    --     if inst_cpt.lastwasattackedtime == nil or (GetTime()-inst_cpt.lastwasattackedtime)<=5 then
    --         return true
    --     end
    -- end

    local team_threat
    if ent.components.teamattacker ~= nil and ent.components.teamattacker.teamleader ~= nil then
        team_threat = ent.components.teamattacker.teamleader.threat
        if team_threat == inst then --被团队仇视，肯定是敌人。主要是蝙蝠、企鹅在用这个机制
            return true
        end
    end
    if pas.IsMyFollower(inst, ent) then --ent 跟随着我，就不要攻击了，防止后面逻辑引起跟随者内战
        return false
    end
    if ent_target ~= nil and pas.IsMyFollower(inst, ent_target) then --ent 想攻击我的跟随者，打它！
        return true
    end
    if team_threat ~= nil and pas.IsMyFollower(inst, team_threat) then --ent 想攻击我的跟随者，打它！
        return true
    end
    return false
end
fns.IsEnemy_player = function(inst, ent) --是否为 全体玩家 的当前敌人
    if pas.IsEnemyPre(ent) then return false end
    -- if inst == nil then return true end

    local ent_target = ent.components.combat.target
    if ent_target ~= nil and ent_target:HasTag("player") then --仇视玩家，肯定是敌人
        return true
    end

    local team_threat
    if ent.components.teamattacker ~= nil and ent.components.teamattacker.teamleader ~= nil then
        team_threat = ent.components.teamattacker.teamleader.threat
        if team_threat ~= nil and team_threat:HasTag("player") then --团队仇视玩家，肯定是敌人。主要是蝙蝠、企鹅在用这个机制
            return true
        end
    end

    if fns.IsPlayerFollower(ent) then --ent 跟随着玩家，就不要攻击了，防止后面逻辑引起跟随者内战
        return false
    end
    if ent_target ~= nil and fns.IsPlayerFollower(ent_target) then --ent 想攻击玩家的跟随者，打它！
        return true
    end
    if team_threat ~= nil and fns.IsPlayerFollower(team_threat) then --ent 想攻击玩家的跟随者，打它！
        return true
    end
    return false
end
fns.MaybeEnemy_me = function(inst, ent, playerside) --是否为 inst 的潜在或当前敌人
    if pas.IsEnemyPre(ent) then return false end
    if inst == nil then return true end

    local ent_target = ent.components.combat.target
    if ent_target == nil then
        if pas.IsMyFollower(inst, ent) then --ent 跟随着我，就不攻击
            return false
        end
        --玩家立场时，不攻击驯化的对象(毕竟对于非玩家inst来说，驯化与否关系不大，只有玩家才关心这个)
        if playerside and ent.components.domesticatable ~= nil and ent.components.domesticatable:IsDomesticated() then
            return false
        end
    else
        if ent_target == inst then --仇视自己，肯定是敌人
            return true
        end
        if pas.IsMyFollower(inst, ent) then --ent 跟随着我，就不攻击
            return false
        end
        if playerside and ent.components.domesticatable ~= nil and ent.components.domesticatable:IsDomesticated() then
            return pas.IsMyFollower(inst, ent_target) --ent 想攻击我的跟随者，打它！
        end
    end
    return true
end
fns.MaybeEnemy_player = function(inst, ent, playerside) --是否为 全体玩家 的潜在或当前敌人
    if pas.IsEnemyPre(ent) then return false end

    local ent_target = ent.components.combat.target
    if ent_target == nil then
        if fns.IsPlayerFollower(ent) then --ent 跟随着玩家，就不攻击
            return false
        end
        --不攻击驯化的对象
        if ent.components.domesticatable ~= nil and ent.components.domesticatable:IsDomesticated() then
            return false
        end
    else
        if ent_target:HasTag("player") then --仇视玩家，肯定是敌人
            return true
        end
        if fns.IsPlayerFollower(ent) then --ent 跟随着玩家，就不攻击
            return false
        end
        if ent.components.domesticatable ~= nil and ent.components.domesticatable:IsDomesticated() then
            return fns.IsPlayerFollower(ent_target) --ent 想攻击玩家的跟随者，打它！
        end
    end
    return true
end

--[ 判定 attacker 对于 target 的攻击力 ]--
--目前官方没有这样的单独计算 对象A 对于 对象B 能打出的伤害的单独逻辑，所以这里专门写个逻辑，需要不定期更新官方的逻辑

fns.CalcDamage = function(attacker, target, weapon, projectile, stimuli, damage, spdamage, pushevent)
    -- if weapon == nil then --这里不关注武器来源
    --     weapon = attacker.components.combat:GetWeapon()
    -- end
    local weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
    if stimuli == nil then
        if weapon_cmp ~= nil then
            if weapon_cmp.overridestimulifn ~= nil then
                stimuli = weapon_cmp.overridestimulifn(weapon, attacker, target)
            end
            if stimuli == nil and weapon_cmp.stimuli == "electric" then
				stimuli = "electric"
			end
        end
        if stimuli == nil and attacker.components.electricattacks ~= nil then
            stimuli = "electric"
        end
    end

    if pushevent then
        attacker:PushEvent("onattackother", { target = target, weapon = weapon, projectile = projectile, stimuli = stimuli })
    end

    local multiplier = 1
    if  (
            stimuli == "electric" or
            (weapon_cmp ~= nil and weapon_cmp.stimuli == "electric")
        ) and not (
            target:HasTag("electricdamageimmune") or
            (target.components.inventory ~= nil and target.components.inventory:IsInsulated())
        )
    then
        local elec_mult = weapon_cmp ~= nil and weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
        local elec_wet_mult = weapon_cmp ~= nil and weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT
        multiplier = elec_mult + elec_wet_mult * (
            target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or
            (target:GetIsWet() and 1 or 0)
        )
    end

    local dmg, spdmg
    if damage == nil and spdamage == nil then --使用公用机制(获取 attacker 或 weapon 自己的数值)
        dmg, spdmg = attacker.components.combat:CalcDamage(target, weapon, multiplier)
        return dmg, spdmg, stimuli
    end

    --使用这次专门的数值，就不需要去获取武器或者攻击者本身的攻击力数据了
    if target:HasTag("alwaysblock") then
        return 0, nil, stimuli
    end
    dmg = damage or 0
    if spdamage ~= nil then --由于 spdamage 是个表，我不想改动传参数据，所以这里新产生一个表
        spdmg = SpDamageUtil.MergeSpDamage({}, spdamage)
    end
    local self = attacker.components.combat
    local basemultiplier = self.damagemultiplier
    local externaldamagemultipliers = self.externaldamagemultipliers
    local damagetypemult = 1
    local bonus = self.damagebonus
    local playermultiplier = target ~= nil and (target:HasTag("player") or target:HasTag("player_damagescale"))
    local pvpmultiplier = playermultiplier and attacker:HasTag("player") and self.pvp_damagemod or 1
    local mount = nil

    if weapon ~= nil then
        playermultiplier = 1
		if attacker.components.damagetypebonus ~= nil then
			damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
		end
        spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
    else
        playermultiplier = playermultiplier and self.playerdamagepercent or 1
        if attacker.components.rider ~= nil and attacker.components.rider:IsRiding() then
            mount = attacker.components.rider:GetMount()
            if mount ~= nil and mount.components.combat ~= nil then
                basemultiplier = mount.components.combat.damagemultiplier
                externaldamagemultipliers = mount.components.combat.externaldamagemultipliers
                bonus = mount.components.combat.damagebonus
				if mount.components.damagetypebonus ~= nil then
					damagetypemult = mount.components.damagetypebonus:GetBonus(target)
				end
				spdmg = SpDamageUtil.CollectSpDamage(mount, spdmg)
			else
				if attacker.components.damagetypebonus ~= nil then
					damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
				end
				spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
            end

            local saddle = attacker.components.rider:GetSaddle()
            if saddle ~= nil and saddle.components.saddler ~= nil then
                dmg = dmg + saddle.components.saddler:GetBonusDamage()
				if saddle.components.damagetypebonus ~= nil then
					damagetypemult = damagetypemult * saddle.components.damagetypebonus:GetBonus(target)
				end
				spdmg = SpDamageUtil.CollectSpDamage(saddle, spdmg)
            end
		else
			if attacker.components.damagetypebonus ~= nil then
				damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
			end
			spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
        end
    end

	dmg = dmg
        * (basemultiplier or 1)
        * externaldamagemultipliers:Get()
		* damagetypemult
        * (multiplier or 1)
        * playermultiplier
        * pvpmultiplier
		* (self.customdamagemultfn ~= nil and self.customdamagemultfn(attacker, target, weapon, multiplier, mount) or 1)
        + (bonus or 0)

    if spdmg ~= nil then
        multiplier = damagetypemult * pvpmultiplier
        -- if self.customspdamagemultfn then --看了官方的注释，到底用不用，我也不清楚了。先不用吧
        --     multiplier = multiplier * (self.customspdamagemultfn(attacker, target, weapon, multiplier, mount) or 1)
        -- end
        if multiplier ~= 1 then
            spdmg = SpDamageUtil.ApplyMult(spdmg, multiplier)
        end
    end
    return dmg, spdmg, stimuli
end

--[ 催眠 ]--

pas.DoSingleSleep = function(v, data)
    if
        (data.fn_valid == nil or data.fn_valid(v, data)) and
        not (v.components.freezable ~= nil and v.components.freezable:IsFrozen()) and
        not (v.components.pinnable ~= nil and v.components.pinnable:IsStuck()) and
        not (v.components.fossilizable ~= nil and v.components.fossilizable:IsFossilized())
    then
        local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil
        if mount ~= nil then
            mount:PushEvent("ridersleep", { sleepiness = data.lvl, sleeptime = data.time })
        end
        if data.fn_do ~= nil then
            data.fn_do(v, data)
        end
        if not data.noyawn and v:HasTag("player") then
            v:PushEvent("yawn", { grogginess = data.lvl, knockoutduration = data.time })
        elseif v.components.sleeper ~= nil then
            v.components.sleeper:AddSleepiness(data.lvl, data.time)
        elseif v.components.grogginess ~= nil then
            v.components.grogginess:AddGrogginess(data.lvl, data.time)
        else
            v:PushEvent("knockedout")
        end
        return true
    end
    return false
end
fns.DoAreaSleep = function(data)
    if data.x == nil and data.doer ~= nil then
        data.x, data.y, data.z = data.doer.Transform:GetWorldPosition()
    end
    if data.tagscant == nil then
        data.tagscant = fns.TagsCombat1() --"FX", "DECOR" 不是很懂为什么官方要加这两个
    end
    if data.tagsone == nil then
        data.tagsone = { "sleeper", "player" }
    end

    local countsleeper = 0
    local ents = TheSim:FindEntities(data.x, data.y, data.z, data.range, nil, data.tagscant, data.tagsone)
    for _, v in ipairs(ents) do
        if pas.DoSingleSleep(v, data) then
            countsleeper = countsleeper + 1
        end
    end

    if countsleeper > 0 then
        return true
    else
        return false, "NOSLEEPTARGETS"
    end
end

--[ 积雪监听(仅prefab定义时使用) ]--

pas.OnSnowCoveredChagned = function(inst, covered)
    if covered then
        -- inst.AnimState:ShowSymbol("snow")
        inst.AnimState:OverrideSymbol("snow", "snow_legion", "snow")
    else
        inst.AnimState:OverrideSymbol("snow", "snow_legion", "emptysnow")
        -- inst.AnimState:HideSymbol("snow")
    end
end
-- fns.MakeSnowCovered_comm = function(inst)
--     inst.AnimState:OverrideSymbol("snow", "snow_legion", "snow") --动画制作中，需要添加“snow”的通道
--     -- inst:AddTag("SnowCovered") --该标签会使得自己在下雪停雪时自动显示和隐藏snow通道
--     -- inst.AnimState:Hide("snow") --没办法，做动画时，会忘记设置贴图名字，导致这个代码没法用
-- end
fns.MakeSnowCovered_serv = function(inst)
    inst:WatchWorldState("issnowcovered", pas.OnSnowCoveredChagned)
    pas.OnSnowCoveredChagned(inst, TheWorld.state.issnowcovered)
end

--[ 让动画播放进度随机 ]--

fns.RandomAnimFrame = function(inst)
    -- inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength()) --这个方式其实也行的
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
end

--[ 光照监听 ]--

fns.IsTooDarkToGrow = function(inst)
    --Tip：洞穴里 isnight 必定为true，isday 和 isdusk 必定为false
    --如果想判定洞穴的真实时间段，只能用 iscaveday、iscavedusk、iscavenight
	if TheWorld.state.isnight then --黑暗时判定是否有光源来帮助生长
		local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, TUNING.DAYLIGHT_SEARCH_RANGE, { "daylight", "lightsource" })
		for _, v in ipairs(ents) do
			local lightrad = v.Light:GetCalculatedRadius() * 0.7
			if v:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
				return false
			end
		end
		return true
	end
	return false
end
fns.IsTooBrightToGrow = function(inst)
    --Tip：洞穴里 isnight 必定为true，isday 和 isdusk 必定为false
    --如果想判定洞穴的真实时间段，只能用 iscaveday、iscavedusk、iscavenight
	if not TheWorld.state.isday then --非白天判定是否有光源来阻碍生长
		local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, TUNING.DAYLIGHT_SEARCH_RANGE,
            { "daylight", "lightsource" }, { "not2bright_l" })
		for _, v in ipairs(ents) do
			local lightrad = v.Light:GetCalculatedRadius() * 0.7
			if v:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
				return true
			end
		end
		return false
	end
	return true
end

--[ 植株寻求保护 ]--

fns.CallPlantDefender = function(inst, target, noone)
	if target ~= nil and (noone or not target:HasAnyTag("plantkin", "self_fertilizable")) then
        inst:RemoveTag("farm_plant_defender") --其实是杂草才需要去除这个标签
        local x, y, z = inst.Transform:GetWorldPosition()
        local defenders = TheSim:FindEntities(x, y, z, TUNING.FARM_PLANT_DEFENDER_SEARCH_DIST, { "farm_plant_defender" })
        for _, defender in ipairs(defenders) do
            if defender.components.burnable == nil or not defender.components.burnable.burning then
                defender:PushEvent("defend_farm_plant", {source = inst, target = target})
                break
            end
        end
    end
end

--[ 计算最终位置 ]--

fns.GetCalculatedPos = function(x, y, z, radius, theta)
    local rad = radius or math.random() * 3
    local the = theta or math.random() * 2 * PI
    return x + rad * math.cos(the), y, z - rad * math.sin(the)
end

--[ 垂直掉落一个物品 ]--

fns.FallingItem = function(itemname, x, y, z, hitrange, hitdamage, fallingtime, fn_start, fn_doing, fn_end)
	local item = SpawnPrefab(itemname)
	if item ~= nil then
        if fallingtime == nil then fallingtime = 5 * FRAMES end

		item.Transform:SetPosition(x, y, z) --这里的y就得是下落前起始高度
		item.fallingpos = item:GetPosition()
		item.fallingpos.y = 0
		if item.components.inventoryitem ~= nil then
			item.components.inventoryitem.canbepickedup = false
		end

        if fn_start ~= nil then fn_start(item) end

		item.fallingtask = item:DoPeriodicTask(
            FRAMES,
            function(inst, startpos, starttime)
                local t = math.max(0, GetTime() - starttime)
                local pos = startpos + (inst.fallingpos - startpos) * easing.inOutQuad(t, 0, 1, fallingtime)
                if t < fallingtime and pos.y > 0 then
                    inst.Transform:SetPosition(pos:Get())
                    if fn_doing ~= nil then fn_doing(inst) end
                else
                    inst.Physics:Teleport(inst.fallingpos:Get())
                    inst.fallingtask:Cancel()
                    inst.fallingtask = nil
                    inst.fallingpos = nil
                    if inst.components.inventoryitem ~= nil then
                        inst.components.inventoryitem.canbepickedup = true
                    end
                    if hitrange ~= nil then
                        local someone = FindEntity(inst, hitrange, function(target)
                            if
                                target.components.health ~= nil and not target.components.health:IsDead() and
                                target.components.combat ~= nil and target.components.combat:CanBeAttacked()
                            then
                                return true
                            end
                            return false
                        end, { "_combat", "_health" }, fns.TagsCombat1(), nil)
                        if someone ~= nil then
                            someone.components.combat:GetAttacked(inst, hitdamage)
                        end
                    end
                    if inst.components.stackable ~= nil then --自动堆叠
                        inst:PushEvent("l_autostack")
                    end
                    if fn_end ~= nil then fn_end(inst) end
                end
            end,
            0, item:GetPosition(), GetTime()
        )
    end
end

--[ sg：sg中卸下装备的重物 ]--

fns.ForceStopHeavyLifting = function(inst)
    if inst.components.inventory:IsHeavyLifting() then
        inst.components.inventory:DropItem(
            inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end
end

--[ 无视防御的攻击 ]--

pas.GetResist_l = function(self, attacker, weapon, ...)
    local mult = 1
    if self.all_legion_v ~= nil then
        mult = self.all_legion_v
        if self.inst.legiontag_undefended == 1 then
            if mult < 1 then --大于1 是代表增伤。这里需要忽略的是减伤
                mult = 1
            end
        end
    end
    if self.GetResist_legion ~= nil then
        local mult2 = self.GetResist_legion(self, attacker, weapon, ...)
        if self.inst.legiontag_undefended == 1 then
            if mult2 < 1 then --大于1 是代表增伤。这里需要忽略的是减伤
                mult2 = 1
            end
        end
        mult = mult * mult2
    end
    return mult
end
pas.inventory_ApplyDamage_l = function(self, damage, attacker, weapon, spdamage, ...)
    if self.inst.legiontag_undefended == 1 then --虽然其中可能会有增伤机制，但太复杂了，不好改，直接原样返回吧
        return damage, spdamage
    end
    if self.ApplyDamage_legion ~= nil then
        return self.ApplyDamage_legion(self, damage, attacker, weapon, spdamage, ...)
    end
    return damage, spdamage
end
pas.combat_mult_RecalculateModifier_l = function(inst)
    local m = inst._base
    for source, src_params in pairs(inst._modifiers) do
        for k, v in pairs(src_params.modifiers) do --externaldamagetakenmultipliers 用的乘法，所以这里只考虑乘法的情况
            if v > 1 then --大于1 是代表增伤。这里需要忽略的是减伤
                m = inst._fn(m, v)
            end
        end
    end
    inst._modifier_legion = m
end
pas.combat_mult_Get_l = function(self, ...)
    if self.inst.legiontag_undefended == 1 then
        return self._modifier_legion or 1
    end
    if self.Get_legion ~= nil then
        return self.Get_legion(self, ...)
    end
    return 1
end
pas.combat_mult_SetModifier_l = function(self, ...)
    if self.SetModifier_legion ~= nil then
        self.SetModifier_legion(self, ...)
    end
    pas.combat_mult_RecalculateModifier_l(self)
end
pas.combat_mult_RemoveModifier_l = function(self, ...)
    if self.RemoveModifier_legion ~= nil then
        self.RemoveModifier_legion(self, ...)
    end
    pas.combat_mult_RecalculateModifier_l(self)
end
pas.combat_GetAttacked_l = function(self, ...)
    local notblocked
    if self.GetAttacked_legion ~= nil then
        notblocked = self.GetAttacked_legion(self, ...)
    end
    if self.inst.legiontag_undefended == 1 then
        self.inst.legiontag_undefended = 0
    end
    return notblocked
end
pas.health_DoDelta_l = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    if self.DoDelta_legion ~= nil then
        if self.inst.legiontag_undefended == 1 then
            ignore_invincible = true
            ignore_absorb = true
        end
        return self.DoDelta_legion(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end
    return amount
end
pas.health_DoDelta_player = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    if self.DoDelta_legion ~= nil then
        if self.inst.legiontag_undefended == 1 then
            -- ignore_invincible = true --对于玩家，无敌是有效的
            ignore_absorb = true
        end
        return self.DoDelta_legion(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end
    return amount
end
pas.health_IsInvincible_l = function(self, ...)
    if self.inst.legiontag_undefended == 1 then
        return self.inst.sg and self.inst.sg:HasStateTag("temp_invincible")
    end
    if self.IsInvincible_legion ~= nil then
        return self.IsInvincible_legion(self, ...)
    end
end
pas.planarentity_AbsorbDamage_l = function(self, damage, attacker, weapon, spdmg, ...)
    if self.AbsorbDamage_legion == nil then
        return damage, spdmg
    end
    if self.inst.legiontag_undefended == 1 then
        local damage2, spdamage2 = self.AbsorbDamage_legion(self, damage, attacker, weapon, spdmg, ...)
        if damage2 < damage then --如果最终值小于之前的值，说明有减免，那就不准减免
            return damage, spdamage2
        else --兼容别的mod的逻辑
            return damage2, spdamage2
        end
    end
    return self.AbsorbDamage_legion(self, damage, attacker, weapon, spdmg, ...)
end
fns.UndefendedATK = function(inst, data) --无视防御的攻击需要提前对受击者做一些操作
    if data == nil or data.target == nil then
        return
    end
    local target = data.target

    if  target.legiontag_ban_undefended or --其他mod兼容：这个变量能防止被破防攻击
        target.prefab == "laozi" --无法伤害神话书说里的太上老君
    then
        return
    end

    if target.legiontag_undefended == nil then
        --修改物品栏护甲机制
        if target.components.inventory ~= nil and target.components.inventory.ApplyDamage_legion == nil then
            target.components.inventory.ApplyDamage_legion = target.components.inventory.ApplyDamage
            target.components.inventory.ApplyDamage = pas.inventory_ApplyDamage_l
        end

        --修改战斗机制
        if target.components.combat ~= nil then
            local combat = target.components.combat
            local mult = combat.externaldamagetakenmultipliers
            mult.Get_legion = mult.Get
            mult.Get = pas.combat_mult_Get_l
            mult.SetModifier_legion = mult.SetModifier
            mult.SetModifier = pas.combat_mult_SetModifier_l
            mult.RemoveModifier_legion = mult.RemoveModifier
            mult.RemoveModifier = pas.combat_mult_RemoveModifier_l
            pas.combat_mult_RecalculateModifier_l(mult) --主动更新一次
            if combat.GetAttacked_legion == nil then
                combat.GetAttacked_legion = combat.GetAttacked
                combat.GetAttacked = pas.combat_GetAttacked_l
            end
        end

        --修改生命机制
        local healthcpt = target.components.health
        if healthcpt ~= nil then
            if healthcpt.DoDelta_legion == nil then
                healthcpt.DoDelta_legion = healthcpt.DoDelta
                if target:HasTag("player") then
                    healthcpt.DoDelta = pas.health_DoDelta_player
                else
                    healthcpt.DoDelta = pas.health_DoDelta_l
                end
            end
            if healthcpt.IsInvincible_legion == nil and not target:HasTag("player") then
                healthcpt.IsInvincible_legion = healthcpt.IsInvincible
                healthcpt.IsInvincible = pas.health_IsInvincible_l
            end
        end

        --修改位面实体机制
        if target.components.planarentity ~= nil and target.components.planarentity.AbsorbDamage_legion == nil then
            target.components.planarentity.AbsorbDamage_legion = target.components.planarentity.AbsorbDamage
            target.components.planarentity.AbsorbDamage = pas.planarentity_AbsorbDamage_l
        end

        --修改防御的标签系数机制
        if target.components.damagetyperesist ~= nil and target.components.damagetyperesist.GetResist_legion == nil then
            target.components.damagetyperesist.GetResist_legion = target.components.damagetyperesist.GetResist
            target.components.damagetyperesist.GetResist = pas.GetResist_l
        end
    end
    target.legiontag_undefended = 1
end

--[ 兼容性标签管理 ]--

fns.AddTag = function(inst, tagname, key)
    if inst.tags_l == nil then
        inst.tags_l = {}
    end
    if inst.tags_l[tagname] == nil then
        inst.tags_l[tagname] = {}
    end
    inst.tags_l[tagname][key] = true
    inst:AddTag(tagname)
end
fns.RemoveTag = function(inst, tagname, key)
    if inst.tags_l ~= nil then
        if inst.tags_l[tagname] ~= nil then
            inst.tags_l[tagname][key] = nil
            for k, v in pairs(inst.tags_l[tagname]) do
                if v == true then --如果还有 key 为true，那就不能删除这个标签
                    return
                end
            end
            inst.tags_l[tagname] = nil --没有 key 是true了，直接做空
        end
    end
    inst:RemoveTag(tagname)
end

--[ 兼容性数值管理 ]--
--ent不一定会是prefab，可能也是个组件或者表

fns.AddEntValue = function(ent, key, key2, valuedeal, value)
    if ent[key] == nil then
        ent[key] = {}
    end
    ent[key][key2] = value
    if valuedeal ~= nil then
        local res
        if valuedeal == 1 then --加法
            res = 0 --加法基础为0
            for _, v in pairs(ent[key]) do
                res = res + v
            end
            ent[key.."_v"] = res ~= 0 and res or nil
        else --乘法
            res = 1 --乘法基础为1
            for _, v in pairs(ent[key]) do
                res = res * v
            end
            ent[key.."_v"] = res ~= 1 and res or nil
        end
    end
end
fns.RemoveEntValue = function(ent, key, key2, valuedeal)
    if ent[key] == nil then
        ent[key.."_v"] = nil
        return
    end
    ent[key][key2] = nil
    if valuedeal == nil then
        for _, v in pairs(ent[key]) do
            if v then
                return
            end
        end
        ent[key] = nil
    else
        local res
        local hasit = false
        if valuedeal == 1 then --加法
            res = 0 --加法基础为0
            for _, v in pairs(ent[key]) do
                res = res + v
                hasit = true
            end
            ent[key.."_v"] = res ~= 0 and res or nil
        else --乘法
            res = 1 --乘法基础为1
            for _, v in pairs(ent[key]) do
                res = res * v
                hasit = true
            end
            ent[key.."_v"] = res ~= 1 and res or nil
        end
        if not hasit then
            ent[key] = nil
        end
    end
end

--[ 生成堆叠的物品 ]--

fns.SpawnStackDrop = function(name, num, pos, doer, items, sets)
    local item = SpawnPrefab(name)
	if item == nil then
		item = SpawnPrefab(sets and sets.overname or "siving_rocks")
	end
	if item ~= nil then
		if num > 1 and item.components.stackable ~= nil then
			local maxsize = item.components.stackable.maxsize
			if num <= maxsize then
				item.components.stackable:SetStackSize(num)
				num = 0
			else
				item.components.stackable:SetStackSize(maxsize)
				num = num - maxsize
			end
		else
			num = num - 1
        end

		if items ~= nil then
			table.insert(items, item)
		end
        if sets ~= nil and sets.pos_y ~= nil then --有时候，给予一个初始高度，能使得掉落过程更加自然
            item.Transform:SetPosition(pos.x, pos.y + sets.pos_y, pos.z)
        else
            item.Transform:SetPosition(pos:Get())
        end
        if item.components.inventoryitem ~= nil then
			if doer ~= nil and doer.components.inventory ~= nil then
				doer.components.inventory:GiveItem(item, nil, pos)
			else
				if item:HasTag("heavy") then --巨大作物不知道为啥不能弹射，可能是和别的物体碰撞了，就失效了
					local x, y, z = fns.GetCalculatedPos(pos.x, pos.y, pos.z, 0.5+1.8*math.random())
					item.Transform:SetPosition(x, y, z)
				else
					item.components.inventoryitem:OnDropped(true)
				end
			end
        end

        if sets ~= nil then
            if not sets.noevent then
                item:PushEvent("on_loot_dropped", { dropper = sets.dropper }) --这个本身就会触发自动叠加
                if sets.dropper ~= nil then
                    sets.dropper:PushEvent("loot_prefab_spawned", { loot = item })
                end
            elseif sets.stackevent then --额外触发自动叠加
                item:PushEvent("l_autostack")
            end
        end

		if num >= 1 then
			fns.SpawnStackDrop(name, num, pos, doer, items, sets)
		end
	end
end

--[ 装备通用函数 ]--

fns.hat_on = function(owner, buildname, foldername) --遮住头顶部的帽子样式
    if buildname == nil then
        owner.AnimState:ClearOverrideSymbol("swap_hat")
    else
        owner.AnimState:OverrideSymbol("swap_hat", buildname, foldername)
    end
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
end
fns.hat_on_opentop = function(owner, buildname, foldername) --完全开放式的帽子样式
    if buildname == nil then
        owner.AnimState:ClearOverrideSymbol("swap_hat")
    else
        owner.AnimState:OverrideSymbol("swap_hat", buildname, foldername)
    end
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAT_NOHELM")
    owner.AnimState:Hide("HEAD_HAT_HELM")
end
fns.hat_off = function(inst, owner) --inst参数虽然没用，但是可以摆阵型，对齐参数
    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
    if owner.components.skinner ~= nil then
        owner.components.skinner.base_change_cb = owner.old_base_change_cb
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
end
fns.hat_on_fullhead = function(owner, buildname, foldername) --遮住整个头部的帽子样式
    if owner:HasTag("player") then
        owner.AnimState:OverrideSymbol("headbase_hat", buildname, foldername)

        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Show("HEAD_HAT_HELM")

        owner.AnimState:HideSymbol("face")
        owner.AnimState:HideSymbol("swap_face")
        owner.AnimState:HideSymbol("beard")
        owner.AnimState:HideSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(true)
    else
        owner.AnimState:OverrideSymbol("swap_hat", buildname, foldername)

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
    end
end
fns.hat_off_fullhead = function(inst, owner) --inst参数虽然没用，但是可以摆阵型，对齐参数
    fns.hat_off(inst, owner)
    if owner:HasTag("player") then
        owner.AnimState:ShowSymbol("face")
        owner.AnimState:ShowSymbol("swap_face")
        owner.AnimState:ShowSymbol("beard")
        owner.AnimState:ShowSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(false)
    end
end
fns.hand_on = function(owner, build, symbol) --简单的手持物
    owner.AnimState:OverrideSymbol("swap_object", build, symbol)
    owner.AnimState:Show("ARM_carry") --显示持物手
    owner.AnimState:Hide("ARM_normal") --隐藏普通的手
end
fns.hand_off = function(inst, owner) --inst参数虽然没用，但是可以摆阵型，对齐参数
    -- owner.AnimState:ClearOverrideSymbol("swap_object") --之所以不需要，因为卸下装备动画还需要贴图显示出来
    owner.AnimState:Hide("ARM_carry") --隐藏持物手
    owner.AnimState:Show("ARM_normal") --显示普通的手
end
fns.hand_on_shield = function(owner, build, symbol) --盾牌式的手持物
    owner.AnimState:OverrideSymbol("lantern_overlay", build, symbol)
    owner.AnimState:OverrideSymbol("swap_shield", build, symbol)
    owner.AnimState:Show("LANTERN_OVERLAY")
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:HideSymbol("swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end
fns.hand_off_shield = function(inst, owner) --inst参数虽然没用，但是可以摆阵型，对齐参数
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:ClearOverrideSymbol("swap_shield")
    owner.AnimState:Hide("LANTERN_OVERLAY")
    owner.AnimState:ShowSymbol("swap_object")
end

--[ 耐久为0不会消失的可修复装备 ]--

pas.OnRepaired = function(inst, item, doer, now)
	if inst.components.equippable == nil then
        if inst.foreverequip_l.fn_setequippable ~= nil then
            inst.foreverequip_l.fn_setequippable(inst)
        end
        if inst.foreverequip_l.anim ~= nil then
            inst.AnimState:PlayAnimation(inst.foreverequip_l.anim, inst.foreverequip_l.isloop)
        end
		-- inst.components.floater:SetSwapData(SWAP_DATA)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end
pas.OnBroken = function(inst) --损坏后会把装备卸下并丢进玩家物品栏
    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
    if inst.foreverequip_l.fn_broken ~= nil then
        inst.foreverequip_l.fn_broken(inst)
    else
        if inst.components.equippable ~= nil then
            inst:RemoveComponent("equippable")
            if inst.foreverequip_l.anim_broken ~= nil then
                inst.AnimState:PlayAnimation(inst.foreverequip_l.anim_broken, inst.foreverequip_l.isloop_broken)
            end
            -- inst.components.floater:SetSwapData(SWAP_DATA_BROKEN)
            inst:AddTag("broken") --这个标签会让名称显示加入“损坏”前缀
            inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM" --改为统一的损坏描述
        end
    end
end
fns.MakeNoLossRepairableEquipment = function(inst, data)
    inst.foreverequip_l = data
    if inst.foreverequip_l.fn_repaired == nil then
        inst.foreverequip_l.fn_repaired = pas.OnRepaired
    end
	if inst.components.armor ~= nil then
        if inst.components.armor.SetKeepOnFinished == nil then --有的mod替换了这个组件，导致没兼容官方的新函数
            inst.components.armor.keeponfinished = true
        else
            inst.components.armor:SetKeepOnFinished(true)
        end
		inst.components.armor:SetOnFinished(pas.OnBroken)
	elseif inst.components.finiteuses ~= nil then
		inst.components.finiteuses:SetOnFinished(pas.OnBroken)
	elseif inst.components.fueled ~= nil then
		inst.components.fueled:SetDepletedFn(pas.OnBroken)
	end
end

--[ 全能攻击系数的管理(普通和特殊) ]--

pas.GetBonus_l = function(self, target, ...)
    local mult = self.all_legion_v or 1
    if self.GetBonus_legion ~= nil then
        mult = mult * self.GetBonus_legion(self, target, ...)
    end
    return mult
end
fns.AddBonusAll = function(inst, key, value)
    if inst.components.damagetypebonus == nil then --通过这个组件能使得系数效果能同时应用给普攻和特攻
        inst:AddComponent("damagetypebonus")
    end
    local cpt = inst.components.damagetypebonus
    if cpt.GetBonus_legion == nil then
        cpt.GetBonus_legion = cpt.GetBonus
        cpt.GetBonus = pas.GetBonus_l
    end
    fns.AddEntValue(cpt, "all_legion", key, 2, value) --乘法系数
end
fns.RemoveBonusAll = function(inst, key)
    if inst.components.damagetypebonus ~= nil then
        fns.RemoveEntValue(inst.components.damagetypebonus, "all_legion", key, 2)
    end
end

--[ 全能防御系数的管理(普通和特殊) ]--

fns.AddResistAll = function(inst, key, value)
    if inst.components.damagetyperesist == nil then --通过这个组件能使得防御效果能同时应用给普防和特防
        inst:AddComponent("damagetyperesist")
    end
    local cpt = inst.components.damagetyperesist
    if cpt.GetResist_legion == nil then
        cpt.GetResist_legion = cpt.GetResist
        cpt.GetResist = pas.GetResist_l
    end
    fns.AddEntValue(cpt, "all_legion", key, 2, value) --乘法系数
end
fns.RemoveResistAll = function(inst, key)
    if inst.components.damagetyperesist ~= nil then
        fns.RemoveEntValue(inst.components.damagetyperesist, "all_legion", key, 2)
    end
end

--[ 一些数学运算 ]--

fns.Floor_s = function(value) --修正过的 math.floor() 逻辑
    --Tip：此逻辑是为了让 math.floor() 逻辑更精准。
    --因为有时候math.floor(正整数M)的结果会比正整数M居然还小1，按理来说，结果就应该与正整数M相等才对，
    --之所以觉得是正整数，因为 print() 后是个整数，但靠判断语句又是小于正整数"M"这个值的
    --如果原值+0.000001会跳到下一个整数位去，那说明也挺接近的，忽略此误差
    return math.floor(value + 0.000001)
end
fns.ODPoint = function(value, plus) --截取小数点
    if value == 0 or not value then
        return 0
    end
    if value < 0 then
        value = fns.Floor_s( math.abs(value)*plus )
        return -value/plus
    else
        value = fns.Floor_s(value*plus)
	    return value/plus
    end
end

--[ 计算补满一个值的所需最大最合适的数量。比如修复、充能的消耗之类的 ]--

fns.ComputCost = function(valuenow, valuemax, value, item)
    if valuenow >= valuemax then
        return 0
    end
    local need = (valuemax - valuenow) / value
    value = math.ceil(need)
    if need ~= value then --说明不整除
        need = value
        if need > 1 then --最后一次很可能会比较浪费，所以不主动填满
            need = need - 1
        end
    end
    if item ~= nil then
        if item.components.stackable ~= nil then
            local stack = item.components.stackable:StackSize() or 1
            if need > stack then
                need = stack
            end
            item.components.stackable:Get(need):Remove()
        else
            need = 1
            item:Remove()
        end
    end
    return need
end

--[ 名称中显示更多细节 ]--

pas.NameDetailFn = function(inst)
	return inst.mouseinfo_l.str
end
fns.InitMouseInfo = function(inst, fn_dealdata, fn_getdata, limitedtime)
    if CONFIGS_LEGION.MOUSEINFO == nil or CONFIGS_LEGION.MOUSEINFO <= 0 then
        return
    end
	inst.mouseinfo_l = {
		--【客户端】
		limitedtime = limitedtime, --对于一些数据量太多的，可以选择限制更新频率
		lasttime = nil, --上次获取时间
		fn_dealdata = fn_dealdata, --将数据转化成展示用的字符串
		str = nil, --展示字符串
		dd = nil, --原始数据
		--【服务器】
		fn_getdata = fn_getdata --获取展示需要的数据
	}
    -- if not TheNet:IsDedicated() then
    --     inst.mouseinfo_l.str = inst.mouseinfo_l.fn_dealdata(inst, {})
    -- end
    inst.legion_namedetail = pas.NameDetailFn
end
fns.SendMouseInfoRPC = function(player, target, newdd, isfixed, newtime)
    if target.mouseinfo_l ~= nil and player.userid ~= nil then
        if newtime then
            player.mouseinfo_ls_time = GetTime()
        end
        local dd = { dd = newdd }
        if isfixed then
            dd.fixed = true
        end
        local success, res = pcall(function() return json.encode(dd) end)
        if success then
            SendModRPCToClient(GetClientModRPC("LegionMsg", "MouseInfo"), player.userid, res, target)
            return true
        end
    end
end

--[ 监听父实体的变化 ]--

pas.OnOwnerChange = function(inst, changefn)
    local newowners = {}
    local owner = inst
    while owner.components.inventoryitem ~= nil do
        newowners[owner] = true

        if inst._owners_l[owner] then
            inst._owners_l[owner] = nil
        else
            inst:ListenForEvent("onputininventory", inst._onownerchange, owner)
            inst:ListenForEvent("ondropped", inst._onownerchange, owner)
        end

        local nextowner = owner.components.inventoryitem.owner
        if nextowner == nil then
            break
        end

        owner = nextowner
    end
    for k, _ in pairs(inst._owners_l) do --还在 _owners_l 里的实体就说明不是 inst 的父实体了
        if k:IsValid() then
            inst:RemoveEventCallback("onputininventory", inst._onownerchange, k)
            inst:RemoveEventCallback("ondropped", inst._onownerchange, k)
        end
    end
    inst._owners_l = newowners

    if changefn ~= nil then --此时的 owner 就是最外层的父实体
        changefn(inst, owner, newowners)
    end

	-- if owner:HasTag("pocketdimension_container") or owner:HasTag("buried") then
	-- 	inst._light.entity:SetParent(inst.entity)
	-- 	if not inst._light:IsInLimbo() then
	-- 		inst._light:RemoveFromScene()
	-- 	end
	-- else
	-- 	inst._light.entity:SetParent(owner.entity)
	-- 	if inst._light:IsInLimbo() then
	-- 		inst._light:ReturnToScene()
	-- 	end
	-- end
end
fns.ListenOwnerChange = function(inst, changefn, removefn)
    inst._owners_l = {}
    inst._onownerchange = function() pas.OnOwnerChange(inst, changefn) end
    pas.OnOwnerChange(inst, changefn)
    if removefn ~= nil then
        inst:ListenForEvent("onremove", removefn)
    end
end

--[ 打蜡相关 ]--

pas.DoWax = function(inst, doer, waxitem)
    if inst.legionfn_wax ~= nil then
        return inst.legionfn_wax(inst, doer, waxitem, true)
    end
end
fns.SetSprayWaxable = function(inst, waxfn, waxfn2) --设置为可暗影打蜡
    local waxable = inst:AddComponent("waxable") --使用这个组件是为了兼容官方原本的打蜡逻辑
    if waxfn == nil then
        waxable:SetWaxfn(pas.DoWax)
    else
        waxable:SetWaxfn(waxfn)
    end
    waxable:SetNeedsSpray()
    inst.legionfn_wax = waxfn2
end

pas.OnEndFade = function(inst)
    inst._multcolor_l = nil
    if inst.legion_colourtweener then
        inst:RemoveComponent("colourtweener")
    end
end
pas.DoRevertMultColor = function(inst)
    inst.components.colourtweener:StartTween(inst._multcolor_l or {1, 1, 1, 1}, 1.5, pas.OnEndFade)
end
pas.RevertMultColor = function(inst)
    inst:DoTaskInTime(0.7, pas.DoRevertMultColor)
end
pas.DoOnWaxedFade = function(inst, pos)
    if pos ~= nil then
        local fx = SpawnPrefab("beeswax_spray_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(pos.x, 0, pos.z)
        end
    end

    if inst.components.colourtweener == nil then
        inst.legion_colourtweener = true
        inst:AddComponent("colourtweener")
    end
    inst._multcolor_l = { inst.AnimState:GetMultColour() }
    inst.components.colourtweener:StartTween({0.2, 0.2, 0.2, 1}, 0.8, pas.RevertMultColor)
end
fns.InheritWaxed = function(oldobj, newobj) --复制并继承打蜡数据
    local dd
    if oldobj._dd_wax ~= nil then
        dd = shallowcopy(oldobj._dd_wax)
    else
        dd = {}
    end
    if oldobj.components.skinedlegion ~= nil then
        if oldobj.components.skinedlegion.skin ~= nil then
            dd.skin = oldobj.components.skinedlegion.skin
            dd.userid = oldobj.components.skinedlegion.userid
        else
            dd.skin = nil
            dd.userid = nil
        end
    end
    if newobj.fn_dowax ~= nil then
        newobj.fn_dowax(newobj, dd)
    else
        newobj._dd_wax = dd
    end
end
fns.WaxObject = function(inst, doer, waxitem, name, dd, right)
    local waxed = SpawnPrefab(name)
    if waxed == nil then return false end
    if dd == nil then dd = {} end
    if dd.multcolor == nil then
        dd.multcolor = { inst.AnimState:GetMultColour() }
    end
    if dd.skin == nil then
        if inst.components.skinedlegion ~= nil and inst.components.skinedlegion.skin ~= nil then
            dd.skin = inst.components.skinedlegion.skin
            dd.userid = inst.components.skinedlegion.userid
        end
    end
    if dd.frame == nil then
        dd.frame = inst.AnimState:GetCurrentAnimationFrame()
    end
    if waxed.fn_dowax ~= nil then
        waxed.fn_dowax(waxed, dd)
    else
        waxed._dd_wax = dd
    end
    if waxed:HasTag("rotatableobject") and inst:HasTag("rotatableobject") then --保持旋转角度
        waxed.Transform:SetRotation(inst.Transform:GetRotation())
    end

    local pos = inst:GetPosition()
    if right then
        if inst.legionfn_waxremove ~= nil then
            inst.legionfn_waxremove(inst, doer)
        elseif inst.components.workable ~= nil then
            inst.components.workable:Destroy(doer)
        else
            inst:Remove()
        end
    end
    waxed.Transform:SetPosition(pos:Get())

    pas.DoOnWaxedFade(waxed, pos)
    if not right then
        if waxed.components.inventoryitem ~= nil then
			waxed.components.inventoryitem:OnDropped(true)
        end
    end

    return true
end
fns.WaxWaxedObject = function(inst, doer, waxitem) --兼容棱镜的逻辑
    local item = inst.dug_prefab
    if item == nil and inst.components.inventoryitem ~= nil then
        item = inst.prefab
    end
    if item ~= nil then
        item = SpawnPrefab(item)
        if item ~= nil then
            fns.InheritWaxed(inst, item)
            local pos = inst:GetPosition()
            item.Transform:SetPosition(pos:Get())
            pas.DoOnWaxedFade(item, pos)
            if item.components.inventoryitem ~= nil then
                item.components.inventoryitem:OnDropped(true)
            end
            return true
        end
    end
end
fns.WaxWaxedObject2 = function(inst, doer, waxitem) --兼容官方的逻辑
    local item
    if inst.dug_prefab ~= nil then --说明是植物实体
        local itemname = FunctionOrValue(inst.dug_prefab, inst)
        if Prefabs[itemname] ~= nil then --就算有这个数据，不代表有这种prefab
            item = SpawnPrefab(itemname)
        end
    elseif inst.components.inventoryitem ~= nil then --说明是挖起来的实体
        item = SpawnPrefab(inst.prefab)
    end
    if item ~= nil then
        if item.CopySaveData ~= nil then
            item:CopySaveData(inst)
        end
        local pos = inst:GetPosition()
        item.Transform:SetPosition(pos:Get())
        pas.DoOnWaxedFade(item, pos)
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:OnDropped(true)
        end
        return true
    end
end

--[ 好事多蘑相关 ]--

fns.PushLuckyEvent = function(inst, dd) --非消耗型的实体发送幸运计算事件，消耗型的就别用该函数了
    if dd == nil then
        dd = { inst = inst }
    else
        dd.inst = inst
    end
    TheWorld:PushEvent("legion_luckydo", dd)
    inst.legion_luckdoers = nil --记得清理数据
    inst.legiontag_luckdone = nil
    inst.legion_luckcheck = nil
end

--[ 砍树的声音 ]--

fns.PlayChopSound = function(tree, worker)
    if not (worker ~= nil and worker:HasTag("playerghost")) then
        tree.SoundEmitter:PlaySound(
            worker ~= nil and worker:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end
end

--[ 生成placer需要的客户端实体 ]--

fns.CreatePlacerPart = function(bank, build, anim)
    local inst = CreateEntity()
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:SetPercent(anim, 0) --placer需要的是暂停的动画

    return inst
end

--[ 涂改细节 需要的一些逻辑 ]--

fns.GetExceptRandomNumber = function(startnum, endnum, nownum) --获取一个与当前数字不同的随机数字
    local res = {}
    for i = startnum, endnum, 1 do
        if i ~= nownum then
            table.insert(res, i)
        end
    end
    return res[math.random(#res)]
end
fns.GetNextCycleNumber = function(startnum, endnum, nownum) --按顺序获取下一个数字，到底了则从第一个重新开始
    if nownum >= endnum then
        nownum = startnum
    else
        nownum = nownum + 1
    end
    return nownum
end
fns.GetExceptRandomString = function(strs, nowstr) --获取一个与当前字符串不同的随机字符串
    local res = {}
    for _, v in pairs(strs) do
        if v ~= nowstr then
            table.insert(res, v)
        end
    end
    return res[math.random(#res)]
end
fns.GetNextCycleString = function(strs, nowstr) --按顺序获取下一个字符串，到底了则从第一个重新开始
    local firststr, getit
    for _, v in pairs(strs) do
        if firststr == nil then
            firststr = v
        end
        if getit then
            return v
        elseif v == nowstr then
            getit = true
        end
    end
    return firststr
end

-- local TOOLS_L = require("tools_legion")
return fns
