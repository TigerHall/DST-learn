-- 远古守护者加强，生命值增加6000，碰撞石柱进入晕眩状态或被攻击一定次数后生成爬行梦魇梦魇尖喙暗影触手协助战斗
-- 远古守护者阵亡后会在远古大门的CD时间后重置远古，期间击败远古织影者提前重置远古
TUNING.MINOTAUR_HEALTH = TUNING.MINOTAUR_HEALTH + 6000
local bigshadowtentacleexist = 1
local function SpawnDevilPlant(inst, pos)
    if inst:HasTag("swc2hm") or inst:IsAsleep() then return end
    if not inst.plantsnumber2hm then inst.plantsnumber2hm = #(TUNING.DEVILPLANTS2HM) end
    local homepos = inst.components.knownlocations and inst.components.knownlocations:GetLocation("home")
    local pt = pos or homepos or inst:GetPosition()
    local theta
    if not pos then
        local angle = inst:GetAngleToPoint(pt)
        if homepos and angle then angle = -angle end
        local iscave = TheWorld:HasTag("cave")
        local newpt
        for i = 1, 15, 1 do
            local radius = math.random(homepos and iscave and 20 or 5, iscave and 36 or 25) + math.random()
            theta = (angle + GetRandomWithVariance(0, 90)) * DEGREES
            local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
            newpt = pt + offset
            if TheWorld.Map:IsPassableAtPoint(newpt.x, 0, newpt.z, false, true) and
                #TheSim:FindEntities(newpt.x, 0, newpt.z, bigshadowtentacleexist > 1 and 0.5 or 1, {"devil_plant2hm"}, {"player"}) <= 0 then
                pt = newpt
                break
            end
            if i == 15 then return end
        end
    elseif #TheSim:FindEntities(pos.x, 0, pos.z, bigshadowtentacleexist > 1 and 0.5 or 1, {"devil_plant2hm"}, {"player"}) > 0 then
        return
    end
    local prefabname = TUNING.DEVILPLANTS2HM[math.random(inst.plantsnumber2hm)]
    local plant = SpawnPrefab(prefabname)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    if theta then plant.Transform:SetRotation(theta / DEGREES - 180) end
end

local function OnCollisionStun(inst)
    if inst:HasTag("swc2hm") or inst:IsAsleep() then return end
    if not inst.summoncdtask2hm and inst.components.health and not inst.components.health:IsDead() then
        local dangerphase = inst.components.health:GetPercent() < 0.6
        inst.summoncdtask2hm = inst:DoTaskInTime(dangerphase and 4 or 13, function() inst.summoncdtask2hm = nil end)
        inst.attackedindex2hm = math.clamp(inst.attackedindex2hm - (dangerphase and 8 or 15), 0, 15)
        -- 头破血流
        if inst.SpawnBigBloodDrop then
            if dangerphase or math.random() < 0.75 then inst:SpawnBigBloodDrop() end
            if math.random() < (dangerphase and 0.75 or 0.5) then inst:SpawnBigBloodDrop() end
            if math.random() < (dangerphase and 0.5 or 0.25) then inst:SpawnBigBloodDrop() end
        end
        -- 头昏脑涨,残血时:0.5,0.75,1,冷却4秒,非残血时:0.3,0.45,0.6,0.75,0.9,冷却13秒
        local chance = dangerphase and 0.25 or 0.15
        for index = 2, dangerphase and 4 or 6 do if math.random() < index * chance then SpawnDevilPlant(inst) end end
    end
end
local function OnAttacked(inst)
    if not inst.attacked2hm then inst.attacked2hm = true end
    if inst:HasTag("swc2hm") or inst:IsAsleep() then return end
    if not inst.refreshcd2hm and inst.summoncdtask2hm and inst.components.health and not inst.components.health:IsDead() and inst.components.health:GetPercent() <
        0.6 then
        inst.summoncdtask2hm:Cancel()
        inst.refreshcd2hm = true
        bigshadowtentacleexist = 3
        inst.summoncdtask2hm = nil
        inst.attackedindex2hm = 0
        SpawnMonster2hm(inst.components.combat.target or inst, "crawlingnightmare", nil, nil, true)
        SpawnMonster2hm(inst.components.combat.target or inst, "nightmarebeak", nil, nil, true)
        SpawnMonster2hm(inst.components.combat.target or inst, "oceanhorror2hm", nil, nil, true)
        -- 2025.7.25 melon:增加潜伏暗影
        SpawnMonster2hm(inst.components.combat.target or inst, "ruinsnightmare", nil, nil, true)
    end
    inst.attackedindex2hm = inst.attackedindex2hm + 1
    if not inst.summoncdtask2hm and inst.attackedindex2hm >= 15 then OnCollisionStun(inst, true) end
end
local function ondeath(inst)
    if inst:HasTag("swc2hm") then return end
    if TheWorld:HasTag("cave") and TheWorld.components.worldsettingstimer and TheWorld.components.worldsettingstimer:TimerExists("mod_minotaur_resurrect") and
        not TheWorld.components.worldsettingstimer:ActiveTimerExists("mod_minotaur_resurrect") then
        TheWorld.components.worldsettingstimer:StartTimer("mod_minotaur_resurrect", TUNING.ATRIUM_GATE_COOLDOWN)
    end
    bigshadowtentacleexist = 1
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 100, {"devil_plant2hm"}, {"player"})
    if #ents > 0 then for index, ent in ipairs(ents) do ent:DoTaskInTime(math.random(10, 30), ent.KillPlant or ent.Remove) end end
end

-- 脱战后恢复状态
local function delayonentitysleep(inst)
    inst.sleeptask2hm = nil
    if not inst:HasTag("swc2hm") then bigshadowtentacleexist = 1 end
    if inst.components.health and not inst.components.health:IsDead() then
        if TUNING.DSTU then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, 0, z)
            if inst.sg then inst.sg:GoToState("idle") end
        elseif inst.attacked2hm then
            inst.attacked2hm = nil
            inst.components.health:DoDelta(inst.components.health.maxhealth * 0.05, nil, nil, true)
        end
    end
end
local function onentitysleep(inst) if not inst.sleeptask2hm then inst.sleeptask2hm = inst:DoTaskInTime(3, delayonentitysleep) end end
local function onentitywake(inst)
    if inst:IsAsleep() then return end
    if inst.components.health and not inst.components.health:IsDead() and not inst:HasTag("swc2hm") then
        bigshadowtentacleexist = inst.refreshcd2hm and 3 or 2
    end
    if inst.sleeptask2hm then
        inst.sleeptask2hm:Cancel()
        inst.sleeptask2hm = nil
    end
end
local function minotaurOnLoad(inst, data) if data then inst.attacked2hm = data.attacked2hm end end
local function minotaurOnSave(inst, data) data.attacked2hm = inst.attacked2hm end
AddPrefabPostInit("minotaur", function(inst)
    if not TheWorld.ismastersim then return end
    inst.attackedindex2hm = 0
    inst.chargecount = 0
    inst:ListenForEvent("blocked", OnAttacked)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("collision_stun", OnCollisionStun)
    inst:ListenForEvent("death", ondeath)
    inst:ListenForEvent("entitysleep", onentitysleep)
    inst:ListenForEvent("entitywake", onentitywake)
    inst:DoTaskInTime(0, onentitywake)
    -- 2025.10.4 melon:回档后不重复出影怪
    SetOnLoad(inst, minotaurOnLoad)
	SetOnSave(inst, minotaurOnSave)
end)
-- 石虾会被BOSS破防了
local function onrockyattacked(inst, data)
    if data and data.attacker and data.attacker:IsValid() and data.attacker:HasTag("epic") and inst.sg and inst.sg.currentstate and inst.sg.currentstate.name ==
        "shield" and not inst.components.health:IsDead() then inst.sg:GoToState("shield_end") end
end
AddPrefabPostInit("rocky", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("attacked", onrockyattacked)
end)

-- 回城时直接释放技能
AddStategraphPostInit("minotaur", function(sg)
    if TUNING.DSTU and sg.states.arena_return_pre and sg.states.arena_return_pre.ontimeout then
        local ontimeout = sg.states.arena_return_pre.ontimeout
        sg.states.arena_return_pre.ontimeout = function(inst, ...)
            ontimeout(inst, ...)
            if not inst:HasTag("swc2hm") and not inst.sg.statemem.minotaurhome2hm then
                inst.sg.statemem.minotaurhome2hm = true
                if inst.components.health and not inst.components.health:IsDead() and inst.attacked2hm then
                    inst.attacked2hm = nil
                    inst.components.health:DoDelta(inst.components.health.maxhealth * 0.1)
                end
                if inst.summoncdtask2hm then
                    inst.summoncdtask2hm = nil
                    local dangerphase = inst.components.health:GetPercent() < 0.6
                    inst.attackedindex2hm = math.clamp(inst.attackedindex2hm - (dangerphase and 8 or 15), 0, 15)
                end
                SpawnDevilPlant(inst, inst:GetPosition())
                OnCollisionStun(inst)
            end
        end
    end
end)

-- 犀牛20天复活
local function ontimer(inst, data) if data and data.name == "mod_minotaur_resurrect" then inst:PushEvent("resetruins") end end
local function onresetruins(inst)
    if inst.components.worldsettingstimer and inst.components.worldsettingstimer:ActiveTimerExists("mod_minotaur_resurrect") then
        inst.components.worldsettingstimer:StopTimer("mod_minotaur_resurrect")
    end
end
AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim or not inst:HasTag("cave") or not inst.components.worldsettingstimer then return inst end
    inst.components.worldsettingstimer:AddTimer("mod_minotaur_resurrect", TUNING.ATRIUM_GATE_COOLDOWN, true)
    inst:ListenForEvent("timerdone", ontimer)
    inst:ListenForEvent("resetruins", onresetruins)
end)

-- 禁用海星
local function cleatstarfishtrap(inst) if inst.components.workable then inst.components.workable:WorkedBy(inst, 1) end end
AddPrefabPostInit("trap_starfish", function(inst)
    if not TheWorld.ismastersim or not TheWorld:HasTag("cave") then return inst end
    inst:DoTaskInTime(0, cleatstarfishtrap)
end)

-- 触手协助作战
local function shadowtentacleshouldKeepTarget(inst, target)
    return target ~= nil and target:IsValid() and target.entity:IsVisible() and target.components.health ~= nil and not target.components.health:IsDead() and
               target:IsNear(inst, TUNING.TENTACLE_STOPATTACK_DIST) and (target:HasTag("player") or not (target.sg and target.sg:HasStateTag("hiding")))
end
local function onbigshadowtentacleremove(inst)
    if bigshadowtentacleexist == 1 then return end
    local flower_evil = SpawnPrefab("flower_evil")
    flower_evil.persists = false
    flower_evil.Transform:SetPosition(inst.Transform:GetWorldPosition())
    flower_evil:DoTaskInTime(120, flower_evil.Remove)
end
AddPrefabPostInit("bigshadowtentacle", function(inst)
    if not TheWorld.ismastersim then return end
    if bigshadowtentacleexist ~= 1 then inst.components.combat:SetKeepTargetFunction(shadowtentacleshouldKeepTarget) end
    inst:ListenForEvent("onremove", onbigshadowtentacleremove)
end)
AddStategraphPostInit("bigshadowtentacle", function(sg)
    sg.states.attack_post.events.animover.fn = function(inst, ...)
        if inst.AnimState:AnimDone() then
            inst.existindex2hm = (inst.existindex2hm or 0) + 1
            if inst.existindex2hm >= bigshadowtentacleexist then
                inst:Remove()
            else
                inst.sg:GoToState("arrive")
            end
        end
    end
end)

-- 恶魔植物诱惑采集
local forcepickstate = State {
    name = "forcepick2hm",
    tags = {"doing", "busy", "nodangle", "nopredict"},
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.components.inventory:Hide()
        inst:PushEvent("ms_closepopups")
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end

        inst.sg:SetTimeout(math.random() + 1.5)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
        if not (inst.weremode and inst.weremode:value() ~= 0) then
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end
    end,
    ontimeout = function(inst)
        local tent = SpawnPrefab("bigshadowtentacle")
        tent.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tent:PushEvent("arrive")
        if inst.forcepicktarget2hm and inst.forcepicktarget2hm.components and inst.forcepicktarget2hm.components.pickable then
            inst.forcepicktarget2hm.components.pickable:Pick(inst)
            inst.forcepicktarget2hm = nil
        end
        inst.SoundEmitter:KillSound("make")
        if not (inst.weremode and inst.weremode:value() ~= 0) then inst.AnimState:PlayAnimation("build_pst") end
        inst.sg:GoToState("idle")
    end,
    onexit = function(inst)
        inst.SoundEmitter:KillSound("make")
        inst.components.inventory:Show()
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(true)
            inst.components.playercontroller:Enable(true)
        end
    end
}
AddStategraphState("wilson", forcepickstate)
local function forcepickdevilplant2hm(inst, target)
    inst.forcepicktarget2hm = target
    if not inst.sg:HasStateTag("dead") then
        inst.sg:GoToState("forcepick2hm")
    end
end
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst.forcepickdevilplant2hm = forcepickdevilplant2hm
end)

-- 传送魔杖不能卡BUG
AddPrefabPostInit("telestaff", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.spellcaster and inst.components.spellcaster.spell then
        local spell = inst.components.spellcaster.spell
        inst.components.spellcaster.spell = function(inst, target, pos, caster, ...)
            if caster and caster:IsValid() and TheWorld:HasTag("cave") then
                TheWorld:PushEvent("ms_miniquake", {rad = 3, num = 5, duration = 1.5, target = caster})
            end
            if target and target:IsValid() and not target:HasTag("player") and target.components.combat then
                target.components.combat:SuggestTarget(caster)
            end
            return spell(inst, target, pos, caster, ...)
        end
    end
end)
-- 远古宝箱限制收益,只能拿特定数目的道具
local function sayminotaurchesttext(inst, itemlimit2hm)
	inst.sayminotaurchesttexttask2hm = nil
	if inst.components.talker then
	local desc = itemlimit2hm and
				((TUNING.isCh2hm and "你可以从这个箱子里拿走" or "You can get ") .. itemlimit2hm ..
					(TUNING.isCh2hm and "个道具" or " items form the chest.")) or
				(TUNING.isCh2hm and "箱子的道具拿走限制已经解除了" or "The chest's items limit now stop.")
	inst.components.talker:Say(desc, nil, true)
	end
end
local function minotaurchestonopen(inst, data)
	if inst.itemlimit2hm and inst.components.inspectable and data and data.doer and data.doer:IsValid() and data.doer:HasTag("player") and
	data.doer.components.talker then
	local desc, text_filter_context, original_author = inst.components.inspectable:GetDescription(data.doer)
	desc = (TUNING.isCh2hm and "你可以从这个箱子里拿走" or "You can get ") .. inst.itemlimit2hm ..
		   (TUNING.isCh2hm and "个道具" or " items form the chest.")
	if desc ~= nil then data.doer.components.talker:Say(desc, nil, true, nil, nil, nil, text_filter_context, original_author) end
	end
end
local minotaurchestinit
local function minotaurchestprocess(inst, limit, recordslots)
	if inst.itemlimit2hm ~= nil or not inst.components.container then return end
	inst.itemlimit2hm = limit
	if limit == nil then
	--远古地形给3个奖励，非远古只给2个
	local x, y, z = inst.Transform:GetWorldPosition()
	local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, 0, z, "Nightmare")
		if node ~= nil then
			inst.itemlimit2hm = 3
		else
			inst.itemlimit2hm = 2
		end
	end
	inst.limitfn2hm = function(item)
		if inst.recorditems2hm and inst.recorditems2hm[item] then
			inst.itemlimit2hm = inst.itemlimit2hm - 1
			inst.recorditems2hm[item] = nil
			if item:IsValid() then
				inst:RemoveEventCallback("onremove", inst.limitfn2hm, item)
				inst:RemoveEventCallback("ondropped", inst.limitfn2hm, item)
				inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, item)
				inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, item)
			end
			if inst.itemlimit2hm <= 0 then
				inst.itemlimit2hm = nil
			for v, value in pairs(inst.recorditems2hm) do
			if v and v:IsValid() and value then
				inst:RemoveEventCallback("onremove", inst.limitfn2hm, v)
				inst:RemoveEventCallback("ondropped", inst.limitfn2hm, v)
				inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, v)
				inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, v)
				v:DoTaskInTime(0, v.Remove)
			end
			end
			inst.limitfn2hm = nil
			inst.recorditems2hm = nil
			inst:RemoveEventCallback("onopen", minotaurchestonopen)
			SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
			if TheNet:IsServerPaused() then TheNet:SetServerPaused(false) end
			end
			if inst.components.container and inst.components.container:IsOpen() then
			local player = FindClosestPlayerToInst(inst, 10, true)
			if player then
				if player.sayminotaurchesttexttask2hm then
					player.sayminotaurchesttexttask2hm:Cancel()
					player.sayminotaurchesttexttask2hm = nil
				end
				if not (inst.components.workable and inst.components.workable.workleft <= 0) then
					player.sayminotaurchesttexttask2hm = player:DoTaskInTime(0, sayminotaurchesttext, inst.itemlimit2hm)
				end
			end
			end
		end
	end
	local total = 0
	inst.recorditems2hm = {}
	for i = 1, inst.components.container.numslots do
	local v = inst.components.container.slots[i]
		if (recordslots == nil or table.contains(recordslots, i)) and v ~= nil and v:IsValid() and v.components.inventoryitem then
			inst.recorditems2hm[v] = true
			inst:ListenForEvent("onremove", inst.limitfn2hm, v)
			inst:ListenForEvent("ondropped", inst.limitfn2hm, v)
			inst:ListenForEvent("onputininventory", inst.limitfn2hm, v)
			inst:ListenForEvent("stacksizechange", inst.limitfn2hm, v)
			total = total + 1
		end
	end
	if total == 0 or total <= inst.itemlimit2hm then
	inst.itemlimit2hm = nil
	for v, value in pairs(inst.recorditems2hm) do
		if v and v:IsValid() and value then
			inst:RemoveEventCallback("onremove", inst.limitfn2hm, v)
			inst:RemoveEventCallback("ondropped", inst.limitfn2hm, v)
			inst:RemoveEventCallback("onputininventory", inst.limitfn2hm, v)
			inst:RemoveEventCallback("stacksizechange", inst.limitfn2hm, v)
		end
	end
	inst.recorditems2hm = nil
	inst.limitfn2hm = nil
	return
	end
	inst:ListenForEvent("onopen", minotaurchestonopen)
end
local function minotaurchestOnLoad(inst, data)
	if data and data.itemlimit2hm then inst:DoTaskInTime(0, minotaurchestprocess, data.itemlimit2hm, data.recordslots2hm) end
end
local function minotaurchestOnSave(inst, data)
	data.itemlimit2hm = inst.itemlimit2hm
	if inst.itemlimit2hm and inst.recorditems2hm then
		data.recordslots2hm = {}
		for i = 1, inst.components.container.numslots do
			local v = inst.components.container.slots[i]
			if v and inst.recorditems2hm[v] then table.insert(data.recordslots2hm, i) end
		end
	end
end
AddPrefabPostInit("minotaurchest", function(inst)
	if not TheWorld.ismastersim then return end
	SetOnLoad(inst, minotaurchestOnLoad)
	SetOnSave(inst, minotaurchestOnSave)
	if minotaurchestinit then inst:DoTaskInTime(0, minotaurchestprocess) end
end)
AddPrefabPostInit("minotaurchestspawner", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.task and inst.task.fn then
        local fn = inst.task.fn
        inst.task.fn = function(...)
         minotaurchestinit = true
            fn(...)
            minotaurchestinit = nil
        end
    end
end)
