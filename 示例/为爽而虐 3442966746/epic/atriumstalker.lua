local speedup = GetModConfigData("extra_change") and GetModConfigData("boss_speed") or 1
local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("boss_attackspeed") or 1
local atriumstalkermode = GetModConfigData("atriumstalker")

if attackspeedup < 2 then TUNING.STALKER_ATRIUM_ATTACK_PERIOD = TUNING.STALKER_ATRIUM_ATTACK_PERIOD / 2 * attackspeedup end
if speedup < 2 then TUNING.STALKER_SPEED = TUNING.STALKER_SPEED * 2 / speedup end

if atriumstalkermode ~= -2 then
    TUNING.STALKER_ATRIUM_HEALTH = TUNING.STALKER_ATRIUM_HEALTH * 2
    TUNING.STALKER_ATRIUM_PHASE2_HEALTH = TUNING.STALKER_ATRIUM_PHASE2_HEALTH * 2
    TUNING.STALKER_ABILITY_RETRY_CD = TUNING.STALKER_ABILITY_RETRY_CD / 2
    TUNING.STALKER_SNARE_CD = TUNING.STALKER_SNARE_CD / 2
    TUNING.STALKER_FIRST_SNARE_CD = TUNING.STALKER_FIRST_SNARE_CD / 2
    TUNING.STALKER_SPIKES_CD = TUNING.STALKER_SPIKES_CD / 2
    TUNING.STALKER_FIRST_SPIKES_CD = TUNING.STALKER_FIRST_SPIKES_CD / 2
    TUNING.STALKER_CHANNELERS_CD = TUNING.STALKER_CHANNELERS_CD / 2
    TUNING.STALKER_FIRST_CHANNELERS_CD = TUNING.STALKER_FIRST_CHANNELERS_CD / 2
    TUNING.STALKER_MINIONS_CD = TUNING.STALKER_MINIONS_CD / 2
    TUNING.STALKER_FIRST_MINIONS_CD = TUNING.STALKER_FIRST_MINIONS_CD / 2
    TUNING.STALKER_MINDCONTROL_CD = TUNING.STALKER_MINDCONTROL_CD / 2
    TUNING.STALKER_FIRST_MINDCONTROL_CD = TUNING.STALKER_FIRST_MINDCONTROL_CD / 2
end
TUNING.STALKER_FEAST_HEALING = TUNING.STALKER_FEAST_HEALING * 2

local hasstalker
local stalkers = {}
local function registerstalker(inst)
    table.insert(stalkers, inst)
    hasstalker = true
end
local function unregisterstalker(inst)
    for index, v in ipairs(inst.stalkerswc2hms) do
        if v and v:IsValid() and v.components.health and not v.components.health:IsDead() then v.components.health:Kill() end
    end
    for i = #stalkers, 1, -1 do
        if stalkers[i] == inst then
            table.remove(stalkers, i)
            break
        end
    end
    if #stalkers == 0 then hasstalker = nil end
end

-- 玩家脱战后释放回血技能；受到攻击时可以转化敌人的1名影分身为自己战斗，持续30秒每个单位限一次，可以转化
local function shadowprotectorattacked(inst)
    if not inst:HasDebuff("forcefield") and inst.components.health and not inst.components.health:IsDead() then
        if inst:AddDebuff("forcefield", "abigailforcefield") and inst.components.debuffable and inst.components.debuffable.debuffs and
            inst.components.debuffable.debuffs and inst.components.debuffable.debuffs.forcefield.inst then
            local fx = inst.components.debuffable.debuffs.forcefield.inst
            fx.AnimState:SetMultColour(0, 0, 0, 0.5)
        end
    end
end
local function getattacked(inst, data)
    if not inst:HasTag("swc2hm") and inst.components.health and not inst.components.health:IsDead() and inst.components.timer and inst.components.combat then
        if not inst.hasshield and atriumstalkermode ~= true and data and data.attacker and data.attacker:IsValid() and data.attacker.GUID then
            if not inst.swchangeswp2hms[data.attacker.GUID] then
                if data.attacker.prefab == inst.prefab then
                    inst.oncemiss2hm = true
                    return
                elseif data.attacker:HasTag("player") then
                    -- 受到玩家的攻击则召唤一个影分身攻击玩家
                    inst.swchangeswp2hms[data.attacker.GUID] = true
                    data.attacker:DoTaskInTime(240, function() if inst:IsValid() then inst.swchangeswp2hms[data.attacker.GUID] = nil end end)
                    local pet = SpawnPrefab("shadowprotector", nil, nil, data.attacker.userid)
                    if pet ~= nil then
                        pet.Physics:Teleport(data.attacker.Transform:GetWorldPosition())
                        if pet.components.skinner and not (data.attacker.components.health:IsDead() or data.attacker:HasTag("playerghost")) then
                            pet.components.skinner:CopySkinsFromPlayer(data.attacker)
                        end
                        if pet.components.timer then
                            pet.components.timer:StopTimer("obliviate")
                            pet.components.timer:StartTimer("obliviate", 240)
                        end
                        if pet.components.health then
                            pet.components.health:SetMaxHealth(data.attacker.components.health.maxhealth * 4)
                            pet:ListenForEvent("attacked", shadowprotectorattacked)
                        end
                        if pet.components.follower then pet.components.follower:SetLeader(inst) end
                        if pet.components.knownlocations then
                            pet.components.knownlocations:RememberLocation("spawn", (inst.components.entitytracker and
                                                                               inst.components.entitytracker:GetEntity("stargate") or pet):GetPosition(), true)
                        end
                        if pet.components.combat then
                            pet.components.combat:SetTarget(data.attacker)
                            pet.components.combat:SetRetargetFunction()
                            pet.components.combat:SetKeepTargetFunction()
                        end
                        pet.persists = false
                        pet.swp2hm = inst
                        table.insert(inst.stalkerswc2hms, pet)
                    end
                elseif data.attacker:HasTag("shadowminion") then
                    -- 受到老麦随从的攻击则概率招降则随从
                    inst.swchangeswp2hms[data.attacker.GUID] = true
                    if data.attacker.components.follower and data.attacker.components.combat and data.attacker.swp2hm == nil then
                        local leader = data.attacker.components.follower.leader
                        if leader and leader:IsValid() and math.random() < 0.5 then
                            data.attacker.components.follower:SetLeader(inst)
                            data.attacker.components.combat:SetTarget(leader)
                            data.attacker.components.combat:SetRetargetFunction()
                            data.attacker.components.combat:SetKeepTargetFunction()
                            data.attacker:PushEvent("transfercombattarget", leader)
                            data.attacker.swp2hm = inst
                            table.insert(inst.stalkerswc2hms, data.attacker)
                            inst.oncemiss2hm = true
                            SpawnPrefab("shadow_teleport_in2hm").Transform:SetPosition(data.attacker.Transform:GetWorldPosition())
                        end
                    end
                elseif data.attacker:HasTag("swc2hm") then
                    -- 受到影分身的攻击则概率招降此影分身
                    if data.attacker.swp2hm and data.attacker.swp2hm:IsValid() then
                        inst.swchangeswp2hms[data.attacker.GUID] = true
                        if math.random() < 0.5 then
                            if data.attacker.components.combat then
                                data.attacker.components.combat:SetTarget(data.attacker.swp2hm)
                                data.attacker.components.combat:SetRetargetFunction()
                                data.attacker.components.combat:SetKeepTargetFunction()
                                data.attacker:PushEvent("transfercombattarget", data.attacker.swp2hm)
                            end
                            data.attacker.changeswp2hm = data.attacker.swp2hm
                            data.attacker.swp2hm = inst
                            table.insert(inst.stalkerswc2hms, data.attacker)
                            inst.oncemiss2hm = true
                            if data.attacker.prefab == "bernie_big" and data.attacker._taunttask then
                                data.attacker._taunttask:Cancel()
                            elseif data.attacker.prefab == "abigail" and not data.attacker.is_defensive and data.attacker.BecomeAggressive then
                                data.attacker:BecomeAggressive()
                            end
                            SpawnPrefab("shadow_teleport_in2hm").Transform:SetPosition(data.attacker.Transform:GetWorldPosition())
                        end
                    end
                elseif data.attacker:HasTag("swp2hm") and data.attacker.components.childspawner2hm and
                    data.attacker.components.childspawner2hm.numchildrenoutside > 0 then
                    -- 受到有影分身本体的攻击则概率招降其的一个影分身
                    inst.swchangeswp2hms[data.attacker.GUID] = true
                    if math.random() < 0.25 then
                        for k, v in pairs(data.attacker.components.childspawner2hm.childrenoutside) do
                            if v:IsValid() and v.swp2hm and v.swp2hm == data.attacker and not v.isdead2hm and not v.changeswp2hm and
                                not inst.swchangeswp2hms[v.GUID] then
                                inst.swchangeswp2hms[v.GUID] = true
                                if v.components.combat then
                                    v.components.combat:SetTarget(data.attacker)
                                    v.components.combat:SetRetargetFunction()
                                    v.components.combat:SetKeepTargetFunction()
                                    v:PushEvent("transfercombattarget", data.attacker)
                                end
                                v.changeswp2hm = data.attacker
                                v.swp2hm = inst
                                table.insert(inst.stalkerswc2hms, v)
                                if v.prefab == "bernie_big" and v._taunttask then
                                    v._taunttask:Cancel()
                                elseif v.prefab == "abigail" and not v.is_defensive and v.BecomeAggressive then
                                    v:BecomeAggressive()
                                end
                                SpawnPrefab("shadow_teleport_in2hm").Transform:SetPosition(v.Transform:GetWorldPosition())
                                break
                            end
                        end
                    end
                end
            end
            if not inst.oncemiss2hm then
                for i = #inst.stalkerswc2hms, 1, -1 do
                    local v = inst.stalkerswc2hms[i]
                    if not v:IsValid() then
                        table.remove(inst.stalkerswc2hms, i)
                    elseif v.components.combat then
                        v.components.combat:SuggestTarget(data.attacker)
                    end
                end
            end
        end
        inst.getunknownattackedindex2hm = inst.components.combat.target and 0 or (inst.getunknownattackedindex2hm or 0) + 1
        if (inst.returntogate or (inst.getunknownattackedindex2hm or 0) >= 3) and inst.sg and not inst.sg:HasStateTag("busy") then
            inst.getunknownattackedindex2hm = 0
            if not inst.miniontask and not inst.minionpoints then
                inst.components.timer:StopTimer("minions_cd")
                inst.sg:GoToState("summon_minions_pre")
            elseif not inst.hasshield then
                inst.components.timer:StopTimer("channelers_cd")
                inst.sg:GoToState("summon_channelers_pre")
            end
        end
    end
end
AddStategraphPostInit("SGstalker", function(sg)
    local idle_gate = sg.states.idle_gate.onenter
    sg.states.idle_gate.onenter = function(inst, ...)
        if not inst:HasTag("swc2hm") and inst.components.health and not inst.components.health:IsDead() and inst.components.health:GetPercent() < 1 and
            inst.components.combat and not inst.components.combat.target and inst.components.timer then
            if not inst.miniontask and not inst.minionpoints then
                inst.components.timer:StopTimer("minions_cd")
                inst.sg:GoToState("summon_minions_pre")
                return
            elseif not inst.hasshield then
                inst.components.timer:StopTimer("channelers_cd")
                inst.sg:GoToState("summon_channelers_pre")
                return
            end
        end
        idle_gate(inst, ...)
    end
end)

-- 鬼手必须不同的击杀方式
local avoiddamageways = {}
local function OnSoldiersChanged(inst) if inst.components.commander and inst.components.commander:GetNumSoldiers() <= 0 then avoiddamageways = {} end end
local swp2hmSpawnSpikes
AddPrefabPostInit("stalker_atrium", function(inst)
    inst:AddTag("stageusher")
    inst:AddTag("toughworker")
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, registerstalker)
    inst:ListenForEvent("onremove", unregisterstalker)
    inst.swchangeswp2hms = {}
    inst.stalkerswc2hms = {}
    inst:ListenForEvent("getattacked2hm", getattacked)
    inst:ListenForEvent("soldierschanged", OnSoldiersChanged)
    local SpawnSpikes = inst.SpawnSpikes
    inst.SpawnSpikes = function(inst, ...)
        local GetEntity = inst.components.entitytracker and inst.components.entitytracker.GetEntity
        if inst.components.entitytracker and not inst:HasTag("swc2hm") then inst.components.entitytracker.GetEntity = nilfn end
        SpawnSpikes(inst, ...)
        if inst.components.entitytracker then inst.components.entitytracker.GetEntity = GetEntity end
    end
    local SpawnSnares = inst.SpawnSnares
    inst.SpawnSnares = function(inst, ...)
        swp2hmSpawnSpikes = not inst:HasTag("swc2hm")
        SpawnSnares(inst, ...)
    end
end)

-- 鬼手被同种玩家的同种武器攻击时触发无敌
local function onshadowchannelergetattacked2hm(inst, data)
    if not hasstalker then return end
    data = data or {}
    if avoiddamageways and data and not inst.oncemiss2hm then
        for i, v in ipairs(avoiddamageways) do
            if (v.attacker == data.attacker or
                (data.attacker and data.attacker:IsValid() and not data.attacker:HasTag("player") and v.attackerprefab == data.attacker.prefab)) and
                (v.weapon == data.weapon or (data.weapon and data.weapon:IsValid() and data.weapon.prefab == v.weaponprefab)) then
                inst.oncemiss2hm = true
                SpawnPrefab("shadow_shield" .. tostring(math.random(1, 3))).entity:SetParent(inst.entity)
                return
            end
        end
        local attackdata = {}
        if data.attacker and data.attacker:IsValid() then
            attackdata.attacker = data.attacker
            attackdata.attackerprefab = data.attacker.prefab
        end
        if data.weapon and data.weapon:IsValid() then
            attackdata.weapon = data.weapon
            attackdata.weaponprefab = data.weapon.prefab
        end
        table.insert(avoiddamageways, attackdata)
    end
end
AddPrefabPostInit("shadowchanneler", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("getattacked2hm", onshadowchannelergetattacked2hm)
end)

-- 坠落之刺技能会在消失后生成固定刺,且会以织影者为中心绽放
local function onfossilspike2remove(inst)
    if POPULATING or inst.disablefossil2hm or not hasstalker then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local spike = SpawnPrefab("fossilspike")
    spike.disablefossil2hm = true
    spike.Transform:SetPosition(x, 0, z)
    spike:RestartSpike(0, 12)
end
AddPrefabPostInit("fossilspike2", function(inst)
    if not TheWorld.ismastersim then return end
    if swp2hmSpawnSpikes then inst:ListenForEvent("onremove", onfossilspike2remove) end
end)

-- 固定尖刺技能6个会有1个出现随机缺口
local delaytoggle = 1
local lasttoggle = math.random(6)
local function clearspikeindex(inst)
    delaytoggle = 1
    lasttoggle = math.random(6)
    inst.clearspiketask2hm = nil
end
AddPrefabPostInit("fossilspike", function(inst)
    if not TheWorld.ismastersim then return end
    local RestartSpike = inst.RestartSpike
    inst.RestartSpike = function(inst, ...)
        if POPULATING or inst.disablefossil2hm or not hasstalker then return RestartSpike(inst, ...) end
        local stalker = stalkers[1]
        if stalker and stalker:IsValid() and not stalker.clearspiketask2hm then stalker.clearspiketask2hm = stalker:DoTaskInTime(0, clearspikeindex) end
        delaytoggle = delaytoggle + 1
        if delaytoggle >= 7 then
            delaytoggle = 1
            lasttoggle = math.random(6)
        end
        if delaytoggle ~= lasttoggle then return RestartSpike(inst, ...) end
        local x, y, z = inst.Transform:GetWorldPosition()
        inst:Remove()
        local spike = SpawnPrefab("fossilspike2")
        spike.disablefossil2hm = true
        spike.Transform:SetPosition(x, y, z)
        spike:RestartSpike(0)
    end
end)

if TUNING.DSTU then
    local function disablePhysics(inst) if inst.Physics and not TheWorld:HasTag("cave") then RemovePhysicsColliders(inst) end end
    AddPrefabPostInit("stalker_minion", disablePhysics)
    AddPrefabPostInit("stalker_minion1", disablePhysics)
    AddPrefabPostInit("stalker_minion2", disablePhysics)
end

-- 远古之门
local function handcatch(inst)
    if inst:IsValid() and inst._owner and inst._owner:IsValid() and inst._target and inst._target:IsValid() and inst:IsNear(inst._target, 1) and inst.owner2hm and
        inst.owner2hm:IsValid() then
        inst._destination_steps = 0
        SpawnPrefab("shadow_teleport_in2hm").Transform:SetPosition(inst._target.Transform:GetWorldPosition())
        inst._target:AddChild(SpawnPrefab("shadow_teleport_out2hm"))
        inst._target.Transform:SetPosition(inst.owner2hm.Transform:GetWorldPosition())
        inst._target:PushEvent("knockback", {
            knocker = inst._owner,
            radius = 3,
            strengthmult = (inst._target.components.inventory ~= nil and inst._target.components.inventory:ArmorHasTag("heavyarmor") or
                inst._target:HasTag("heavybody")) and 0.35 or 0.7,
            forcelanded = false
        })
    end
end
local function ongatefar2hm(inst, target)
    local stalker = inst.components.entitytracker and inst.components.entitytracker:GetEntity("stalker")
    if stalker and stalker:IsValid() and stalker.components.health and not stalker.components.health:IsDead() and target and target:IsValid() and
        target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") and
        not (inst.hand2hm and inst.hand2hm:IsValid()) then
        local ipos = inst:GetPosition()
        local tpos = target:GetPosition()
        local unit_target_vec = (tpos - ipos):GetNormalized()
        local hand = SpawnPrefab("stageusher_attackhand")
        hand.Physics:SetMotorVel(TUNING.STAGEUSHER_ATTACK_SPEED * 2, 0, 0)
        inst.hand2hm = hand
        hand.persists = false
        hand.Transform:SetPosition((ipos + unit_target_vec * 0.5):Get())
        hand:SetOwner(stalker)
        hand:SetCreepTarget(target)
        hand.owner2hm = inst
        if hand.components.updatelooper then hand.components.updatelooper:AddOnUpdateFn(handcatch) end
        if inst.on_hand_removed2hm == nil then inst.on_hand_removed2hm = function(hand) inst.hand2hm = nil end end
        inst:ListenForEvent("onremove", inst.on_hand_removed2hm, hand)
    end
end
AddPrefabPostInit("atrium_gate", function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.playerprox2hm then inst:AddComponent("playerprox2hm") end
    inst.components.playerprox2hm:SetTargetMode(inst.components.playerprox2hm.TargetModes.AllPlayers)
    inst.components.playerprox2hm:SetDist(10, 18)
    inst:ListenForEvent("onfar2hm", ongatefar2hm)
end)

