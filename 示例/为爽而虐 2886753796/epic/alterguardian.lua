local speedup = GetModConfigData("extra_change") and GetModConfigData("boss_speed") or 1
local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("boss_attackspeed") or 1
local alterguardianmode = GetModConfigData("alterguardian")
local NEWCONSTANT2HM = ModManager:GetMod("workshop-3191348907") -- 2025.10.24 melon:判断新界是否开启
if alterguardianmode == true then alterguardianmode = -3 end

if speedup < 2 then
    TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED * 2 / speedup
    TUNING.ALTERGUARDIAN_PHASE2_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE2_WALK_SPEED * 2 / speedup
    TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED = TUNING.ALTERGUARDIAN_PHASE3_WALK_SPEED * 2 / speedup
end
if attackspeedup < 2 then
    TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD / 2 * attackspeedup
    TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD / 2 * attackspeedup
    TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD = TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD / 2 * attackspeedup
end
if alterguardianmode ~= -4 then
    TUNING.ALTERGUARDIAN_PHASE1_HEALTH = TUNING.ALTERGUARDIAN_PHASE1_HEALTH * 2
    TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN / 2
    TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN / 2

    TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH = TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH * 2
    TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH = TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH * 2
    TUNING.ALTERGUARDIAN_PHASE2_SPINCD = TUNING.ALTERGUARDIAN_PHASE2_SPINCD / 2
    TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN = TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN / 2
    TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN / 2

    TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH = TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH * 2
    TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH = TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH * 2
    TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD = TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD / 2
    TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN = TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN / 2
end
TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT = TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT * 2
TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED = TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED * 2
TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME = TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME * 2
TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT = TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT * 2
TUNING.ALTERGUARDIAN_PHASE3_TRAP_WORKS = TUNING.ALTERGUARDIAN_PHASE3_TRAP_WORKS * 2
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE = TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE * 2
TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ = TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ + 225
TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST = TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST * 2

-- 可选启用
if alterguardianmode >= -1 then return end
require "physics"
require "behaviours/follow"

-- 可疑的石头需要高级敲矿
AddPrefabPostInit("rock_moon_shell", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.workable then inst.components.workable:SetRequiresToughWork(true) end
end)

-- 天体添加月亮科技和地图图标
local function addminimapicon(inst)
    if not inst.MiniMapEntity and not inst.icon2hm then
        local icon = SpawnPrefab("shadowchessicon2hm")
        if icon then
            icon:TrackEntity(inst)
            inst.icon2hm = icon
        end
    end
end
local function addprototyper(inst)
    if not inst.components.prototyper then
        inst:AddComponent("prototyper")
        inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOONORB_UPGRADED
    end
end
PROTOTYPER_DEFS.alterguardian_phase1 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase2 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3 = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3deadorb = PROTOTYPER_DEFS.moon_altar
PROTOTYPER_DEFS.alterguardian_phase3dead = PROTOTYPER_DEFS.moon_altar

-- 天体各阶段携带月亮风暴作战
local canusemoonstorm = GetModConfigData("moonisland")
local function processmoonstormnode(inst)
    if inst:HasTag("swc2hm") or not canusemoonstorm then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, 0, z)
    if TheWorld.net.components.moonstorms2hm then TheWorld.net.components.moonstorms2hm:AddNewMoonstormNode(node_index, x, y, z) end
end

-- 天体各阶段锁定季节,必须月亮风暴生效时才能锁定
-- alterguardianseason2hm代表锁定的季节,0为不锁定,1夏天2春天3冬天4秋天
-- 测试代码生效月亮风暴 TheWorld:PushEvent("ms_stormchanged",{stormtype=STORM_TYPES.MOONSTORM, setting=true})
TUNING.alterguardianseason2hm = 0
local function SetWorldSeason(season)
    TheWorld:PushEvent("ms_setseason", season)
    SendModRPCToShard(GetShardModRPC("MOD_HARDMODE", "ms_setseason_update"), nil, season)
end
local phaseseasons = {"summer", "spring", "winter", "autumn"}
local phaseprecipitations = {false, true, true}
local phasemoonstormlevels = {0.7, 0.8, 0.9}
local function trylockseason(inst)
    if not inst.alterguardianseason2hm or inst:HasTag("swc2hm") or (inst.alterguardianseason2hm < 4 and not TheWorld.state.isalterawake) or
        TUNING.alterguardianseason2hm > inst.alterguardianseason2hm or (inst.components.health and inst.components.health:IsDead()) or
        (inst.components.workable and inst.components.workable.workleft <= 0) then return end
    if TUNING.alterguardianseason2hm < inst.alterguardianseason2hm then TheWorld:PushEvent("delayrefreshseason2hm") end
    TUNING.alterguardianseason2hm = inst.alterguardianseason2hm
    local season = phaseseasons[TUNING.alterguardianseason2hm]
    if season and TheWorld.state.season ~= season then SetWorldSeason(season) end
    local precipitation = phaseprecipitations[TUNING.alterguardianseason2hm]
    if precipitation ~= nil and ((precipitation and TheWorld.state.precipitation == "none") or (not precipitation and TheWorld.state.precipitation ~= "none")) then
        TheWorld:PushEvent("ms_forceprecipitation", precipitation)
    end
    TUNING.moonstorm2hmlevel = phasemoonstormlevels[TUNING.alterguardianseason2hm]
    if TUNING.alterguardianseason2hm > 0 and TUNING.alterguardianseason2hm < 4 then processmoonstormnode(inst) end
end
local function addseasonlock(inst, idx, try)
    local canenbale = inst.alterguardianseason2hm == nil
    inst.alterguardianseason2hm = idx
    TUNING.alterguardianseason2hm = math.max(inst.alterguardianseason2hm, TUNING.alterguardianseason2hm)
    if canenbale then inst:WatchWorldState("cycles", trylockseason) end
    trylockseason(inst)
end

-----------------------------------------------------------------------------------------------------

-- 第一阶段地震流星,世界变成夏季-----------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
AddPrefabPostInit("alterguardian_phase1", function(inst)
    inst:AddTag("alterguardian2hm")
    inst:AddTag("toughworker")
    if not TheWorld.ismastersim then return end
    if inst.components.burnable then inst:RemoveComponent("burnable") end
    addminimapicon(inst)
    addprototyper(inst)
    addseasonlock(inst, 1)
    if not inst.components.meteorshower then inst:AddComponent("meteorshower") end
    -- if not TUNING.noalterguardianhat2hm and inst.components.lootdropper then inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00) end
    -- inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.75, "alterguardian2hm_phase1")
    -- inst.components.health:SetMaxDamageTakenPerHit(100)
end)
-- 天体仇灵兼容
AddPrefabPostInit("alterguardian_phase1_lunarrift", function(inst)
    inst:AddTag("toughworker")
    if not TheWorld.ismastersim then return end
    if inst.components.burnable then inst:RemoveComponent("burnable") end
    if not inst.components.meteorshower then inst:AddComponent("meteorshower") end
    -- if not TUNING.noalterguardianhat2hm and inst.components.lootdropper then inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00) end
    -- inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.75, "alterguardian2hm_phase1")
    -- inst.components.health:SetMaxDamageTakenPerHit(100)
end)
-- 风滚草攻击
local function makefiretumbleweeds(inst)
    if (inst:HasTag("swc2hm") and not inst.forcealterguardian2hm) or TheWorld.state.season ~= "summer" then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 30, true)
    local rangesq = math.huge
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) and v.userid then
            local px, py, pz = v.Transform:GetWorldPosition()
            local newtumbleweed = SpawnPrefab("mod_hardmode_tumbleweed")
            newtumbleweed.Transform:SetPosition(px - math.cos(newtumbleweed.angle) * 36, py, pz + math.sin(newtumbleweed.angle) * 36)
        end
    end
end
-- 环绕地震攻击
local function sinkholedelaychange(inst)
    -- 陷坑非持久且使用自定义的消失方式来消失，从而节约性能
    local eyeofterror_sinkhole = SpawnPrefab("eyeofterror_sinkhole")
    eyeofterror_sinkhole.Transform:SetPosition(inst.Transform:GetWorldPosition())
    eyeofterror_sinkhole:PushEvent("docollapse")
    eyeofterror_sinkhole.components.timer:SetTimeLeft("repair", 360)
    inst:Remove()
end
local SINKHOLD_BLOCKER_TAGS = {"antlion_sinkhole_blocker"}
local IsValidSinkholePosition_x, IsValidSinkholePosition_z
local function IsValidSinkholePosition(offset)
    local x1, z1 = IsValidSinkholePosition_x + offset.x, IsValidSinkholePosition_z + offset.z
    if #TheSim:FindEntities(x1, 0, z1, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 1.9, SINKHOLD_BLOCKER_TAGS) > 0 then return false end
    for dx = -1, 1 do
        for dz = -1, 1 do
            if not TheWorld.Map:IsPassableAtPoint(x1 + dx * TUNING.ANTLION_SINKHOLE.RADIUS / 2, 0, z1 + dz * TUNING.ANTLION_SINKHOLE.RADIUS / 2, false, true) then
                return false
            end
        end
    end
    return true
end
local function SpawnSinkhole(spawnpt)
    local x = GetRandomWithVariance(spawnpt.x, TUNING.ANTLION_SINKHOLE.RADIUS / 2)
    local z = GetRandomWithVariance(spawnpt.z, TUNING.ANTLION_SINKHOLE.RADIUS / 2)
    IsValidSinkholePosition_x = x
    IsValidSinkholePosition_z = z
    local offset = FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 1.8 + math.random(), 9, IsValidSinkholePosition) or
                       FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 2.9 + math.random(), 17, IsValidSinkholePosition) or
                       FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS / 2 * 3.9 + math.random(), 17, IsValidSinkholePosition) or
                       nil
    if offset ~= nil then
        local antlion_sinkhole = SpawnPrefab("antlion_sinkhole")
        antlion_sinkhole.persists = false
        antlion_sinkhole.Transform:SetPosition(x + offset.x, 0, z + offset.z)
        antlion_sinkhole:PushEvent("startcollapse")
        antlion_sinkhole:DoTaskInTime(3 + math.random(), sinkholedelaychange)
    end
end
local function dosinkholesattack(inst)
    if inst.components.combat.target then
        local pt = inst.components.combat.target:GetPosition()
        SpawnSinkhole(pt)
    end
end
local function doCircularsinkholesattack(inst, segments, radius, angle)
    if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    if TheWorld.components.dockmanager ~= nil then TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000) end
    local segmentangle = (segments > 0 and 360 / segments or 360)
    local start = angle or math.random(0, 360)
    for midangle = -start, 360 - start, segmentangle do
        local offset = Vector3(radius * math.cos(midangle), 0, -radius * math.sin(midangle))
        SpawnSinkhole(Vector3(x + offset.x, 0, z + offset.z))
    end
    dosinkholesattack(inst)
end
-- 流星攻击
local function doshadowmeteorattack(inst)
    if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 30, true)
    local rangesq = math.huge
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) then
            local meteor = SpawnPrefab("shadowmeteor")
            meteor.Transform:SetPosition(v.Transform:GetWorldPosition())
            meteor:SetSize("large", 1)
            meteor:SetPeripheral(false)
        end
    end
end
-- AddStategraphState("alterguardian_phase1",GiveJumpState())
AddStategraphPostInit("alterguardian_phase1", function(sg)
    local OnEnteridle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        OnEnteridle(inst, ...)
        trylockseason(inst)
    end
    -- 滚动开始和结束时产生火焰风滚草
    if sg.states.roll_start then
        local OnEnterroll_start = sg.states.roll_start.onenter
        sg.states.roll_start.onenter = function(inst, ...)
            makefiretumbleweeds(inst)
            OnEnterroll_start(inst, ...)
        end
    end
    -- 滚动更远更持久,海上时必定滚向最近的存活玩家
    local OnEnterroll = sg.states.roll.onenter
    sg.states.roll.onenter = function(inst, ...)
        if inst.components.combat and inst.components.combat.target then
            local tx, ty, tz = inst.components.combat.target.Transform:GetWorldPosition()
            inst.Transform:SetRotation(inst:GetAngleToPoint(tx, ty, tz))
        elseif inst:IsOnOcean() then
            local target = FindClosestPlayerToInst(inst, 10000, true)
            if target and target:IsValid() then
                local tx, ty, tz = target.Transform:GetWorldPosition()
                inst.Transform:SetRotation(inst:GetAngleToPoint(tx, ty, tz))
            end
        end
        OnEnterroll(inst, ...)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        local current_speed, y, z = inst.Physics:GetMotorVel()
        inst.Physics:SetMotorVelOverride(current_speed * 1.5, y, z)
        if inst.sg.mem._num_rolls > 4 and math.random() < 0.35 and inst.sg.mem._num_rolls then inst.sg.mem._num_rolls = inst.sg.mem._num_rolls + 1 end
    end
    -- 首次攻击到玩家也不会停下
    local rolltimout = sg.states.roll.ontimeout
    sg.states.roll.ontimeout = function(inst, ...)
        if (not inst:HasTag("swc2hm") or inst.forcealterguardian2hm) and inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
            inst.sg.statemem.hitplayer = nil
            inst.sg.mem._num_rolls = math.min(inst.sg.mem._num_rolls - 2, 4)
        end
        rolltimout(inst, ...)
    end
    local OnEnterroll_stop = sg.states.roll_stop.onenter
    sg.states.roll_stop.onenter = function(inst, ...)
        makefiretumbleweeds(inst)
        OnEnterroll_stop(inst, ...)
    end
    -- 砸地，产生环形AOE地震
    -- local OnEntertantrum_pre = sg.states.tantrum_pre.onenter
    -- sg.states.tantrum_pre.onenter = function(inst, ...) OnEntertantrum_pre(inst, ...) end
    local OnEntertantrum = sg.states.tantrum.onenter
    sg.states.tantrum.onenter = function(inst, ...)
        if inst.sg.mem.aoes_remaining == nil or inst.sg.mem.aoes_remaining == 0 then inst.aoessinkhole2hm = false end
        OnEntertantrum(inst, ...)
        if (inst:HasTag("swc2hm") or inst.prefab == "alterguardian_phase1_lunarrift") and not inst.forcealterguardian2hm then return end
        if inst.aoessinkhole2hm == false and inst.sg.mem.aoes_remaining then inst.aoessinkhole2hm = inst.sg.mem.aoes_remaining + 1 end
        -- if inst.aoessinkhole2hm and inst.sg.mem.aoes_remaining and (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining) % 2 == 1 then
        --     inst:DoTaskInTime(7 * FRAMES, doCircularsinkholesattack, 4 + (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining),
        --                       (4 + (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining)) * TUNING.ANTLION_SINKHOLE.RADIUS)
        -- end
    end
    AddStateTimeEvent2hm(sg.states.tantrum, 7 * FRAMES, function(inst)
         if (inst:HasTag("swc2hm") or inst.prefab == "alterguardian_phase1_lunarrift") and not inst.forcealterguardian2hm then return end
        if inst.aoessinkhole2hm and inst.sg.mem.aoes_remaining and (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining) % 2 == 1 then
            doCircularsinkholesattack(inst, 4 + (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining),
                                      (4 + (inst.aoessinkhole2hm - inst.sg.mem.aoes_remaining)) * TUNING.ANTLION_SINKHOLE.RADIUS)
        end
    end)
    -- local OnEntertantrum_pst = sg.states.tantrum_pst.onenter
    -- sg.states.tantrum_pst.onenter = function(inst, ...)
    --     OnEntertantrum_pst(inst, ...)
    -- end
    -- 护盾,流星雨
    local OnEntershield_pre = sg.states.shield_pre.onenter
    sg.states.shield_pre.onenter = function(inst, ...)
        OnEntershield_pre(inst, ...)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        inst.components.meteorshower:StopShower()
        inst.components.meteorshower:StartShower()
    end
    -- 进行一次定点流星砸击
    local OnEntershield_end = sg.states.shield_end.onenter
    sg.states.shield_end.onenter = function(inst, ...)
        OnEntershield_end(inst, ...)
        doshadowmeteorattack(inst)
    end
end)

-----------------------------------------------------------------------------------------------------

-- 第二阶段风雨雷电,世界变成春季-----------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------

-- 碰撞障碍攻击
local function ClearRecentlyCharged(inst, other) inst.recentlycharged[other] = nil end
local function OnDestroyOther(inst, other)
    if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() and other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
    end
end
local function OnPhase2Collide(inst, other)
    if other and other:IsValid() and other.prefab == "riceplant" and TUNING.DSTU and other.components.pickable and not inst.recentlycharged[other] then
        other.components.lootdropper:SpawnLootPrefab("rice")
        other.components.pickable:Pick()
        if other:IsValid() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
        return
    end
    if other ~= nil and other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() and other.components.workable.action ~=
        ACTIONS.NET and not inst.recentlycharged[other] then inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other) end
end
local function onphase2spawnothershadow(inst, child)
    child.forcealterguardian2hm = true
    child:AddTag("electricdamageimmune")
end
local function phase2addphase1shadow(inst)
    if inst:HasTag("swp2hm") and inst.components.childspawner2hm then
        inst.components.childspawner2hm:SetQueuedChildren({"alterguardian_phase1"}, true)
        inst.components.childspawner2hm:SetMaxChildren(inst.components.childspawner2hm.maxchildren + 1)
        inst.components.childspawner2hm:SetQueueSpawnedFn(onphase2spawnothershadow)
    end
end
local SPIKE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE
local spawn_spike_with_target
local phase2spiketrailtmptarget
AddPrefabPostInit("alterguardian_phase2", function(inst)
    inst:AddTag("alterguardian2hm")
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")
    inst:AddTag("tornado_nosucky")
    if not TheWorld.ismastersim then return end
    addminimapicon(inst)
    addprototyper(inst)
    addseasonlock(inst, 2)
    -- if not TUNING.noalterguardianhat2hm and inst.components.lootdropper then inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00) end
    -- inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.75, "alterguardian2hm_phase1")
    -- inst.components.health:SetMaxDamageTakenPerHit(150)
    if inst.GUID and not PhysicsCollisionCallbacks[inst.GUID] then
        inst.recentlycharged = {}
        inst.Physics:SetCollisionCallback(OnPhase2Collide)
    end
    if alterguardianmode >= -3 and TUNING.shadowworld2hm then inst.swp2hmfn = phase2addphase1shadow end
    if inst.DoSpikeAttack then
        if not spawn_spike_with_target then spawn_spike_with_target = getupvalue2hm(inst.DoSpikeAttack, "spawn_spike_with_target") end
        if spawn_spike_with_target then
            local DoSpikeAttack = inst.DoSpikeAttack
            inst.DoSpikeAttack = function(inst, ...)
                if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return DoSpikeAttack(inst, ...) end
                local targets = {}
                local ipos = inst:GetPosition()
                for _, p in ipairs(AllPlayers) do
                    if not p:HasTag("playerghost") and p.entity:IsVisible() and (p.components.health ~= nil and not p.components.health:IsDead()) and
                        p:GetDistanceSqToPoint(ipos:Get()) < SPIKE_DSQ then table.insert(targets, p) end
                end
                if IsTableEmpty(targets) then return DoSpikeAttack(inst, ...) end
                local DoTaskInTime = inst.DoTaskInTime
                inst.DoTaskInTime = function(inst, time, fn, ...)
                    if fn == spawn_spike_with_target and not IsTableEmpty(targets) then
                        local length = #targets
                        local target = table.remove(targets, length)
                        if target and target:IsValid() then
                            return DoTaskInTime(inst, time, function(...)
                                phase2spiketrailtmptarget = target
                                fn(...)
                                phase2spiketrailtmptarget = nil
                            end, ...)
                        end
                    end
                    return DoTaskInTime(inst, time, fn, ...)
                end
                DoSpikeAttack(inst, ...)
                inst.DoTaskInTime = DoTaskInTime
                inst.DoTaskInTime2hm = nil
            end
        end
    end
end)
-- 旋风攻击
local function gettornadospawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0, z1 + .15 * (z2 - z1)
end
local function dotornadoattack(inst)
    if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    if inst.components.combat and inst.components.combat.target and inst.components.combat.target:IsValid() then
        local v = inst.components.combat.target
        local x, y, z = inst.Transform:GetWorldPosition()
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < 45 * 45 and inst.components.combat:CanTarget(v) then
            local tornado = SpawnPrefab("tornado")
            tornado.WINDSTAFF_CASTER = inst.swp2hm or inst
            tornado.Transform:SetPosition(gettornadospawnlocation(inst, v))
            tornado.components.knownlocations:RememberLocation("target", v:GetPosition())
        end
    end
end
-- 玻璃刺围困攻击
local spikerotlist = {65, 90, 180}
local spiketimes = {0.75, 0.33, 0.33}
local function dospikesattack(inst)
    if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    local target = inst.components.combat.target
    if not target or not target:IsValid() or not target:IsNear(inst, 6) then return end
    if inst.components.timer then
        if inst.components.timer:TimerExists("spike_cd") then
            inst.components.timer:SetTimeLeft("spike_cd", TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN)
        else
            inst.components.timer:StartTimer("spike_cd", TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN)
        end
    end
    inst.spikeattacktype2hm = math.random() < 0.7 and 1 or math.random(2, 3)
    -- inst.spikeattacktype2hm 1 半包围 2 双竖线 3 双横线
    local rotoffset = spikerotlist[inst.spikeattacktype2hm] or 65
    local time = spiketimes[inst.spikeattacktype2hm] or 0.33
    local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
    local postarget = inst.spikeattacktype2hm ~= 1 and target or inst
    if not postarget then return end
    local x, y, z = postarget.Transform:GetWorldPosition()
    if TheWorld.components.dockmanager ~= nil then TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000) end
    if inst.spikeattacktype2hm ~= 2 then
        local spike0 = SpawnPrefab("alterguardian_phase2spiketrail")
        spike0.Transform:SetPosition(x, 0, z)
        spike0.Transform:SetRotation(angle)
        spike0:SetOwner(inst)
        if spike0._emerge_task and spike0._emerge_task.fn then
            local emerge = spike0._emerge_task.fn
            spike0._emerge_task:Cancel()
            spike0._emerge_task = spike0:DoTaskInTime(inst.spikeattacktype2hm == 1 and 1 or time, emerge)
        end
    end
    local spike1 = SpawnPrefab("alterguardian_phase2spiketrail")
    spike1.Transform:SetPosition(x, 0, z)
    spike1.Transform:SetRotation(angle - rotoffset)
    spike1:SetOwner(inst)
    if spike1._emerge_task and spike1._emerge_task.fn then
        local emerge = spike1._emerge_task.fn
        spike1._emerge_task:Cancel()
        spike1._emerge_task = spike1:DoTaskInTime(time, emerge)
    end
    if inst.spikeattacktype2hm ~= 3 then
        local spike2 = SpawnPrefab("alterguardian_phase2spiketrail")
        spike2.Transform:SetPosition(x, 0, z)
        spike2.Transform:SetRotation(angle + rotoffset)
        spike2:SetOwner(inst)
        if spike2._emerge_task and spike2._emerge_task.fn then
            local emerge = spike2._emerge_task.fn
            spike2._emerge_task:Cancel()
            spike2._emerge_task = spike2:DoTaskInTime(time, emerge)
        end
    end
end
-- 月亮风暴闪电攻击
local function spawnmoonstormlighting(inst, x, y, z)
    local spark = SpawnPrefab("moonstorm_lightning")
    spark.Transform:SetPosition(x, 0, z)
end
local function dolightingattack(inst)
    if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    local target = inst.components.combat.target
    if not (target and target:IsValid()) then return end
    local dist = math.clamp(inst:GetDistanceSqToInst(target), 1, 12)
    if dist > 900 then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, 10, 1 do
        local radius = 1 + i * 5
        if not (target and target:IsValid()) then return end
        local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition()) * DEGREES
        local offset = Vector3(radius * math.cos(angle), 0, radius * -math.sin(angle))
        inst:DoTaskInTime(5 * FRAMES * i, spawnmoonstormlighting, x + offset.x, y, z + offset.z)
    end
end
local _lightningexcludetags = {"playerghost", "INLIMBO", "lightningblocker"}
local function moonstormsendlighting(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, nil, _lightningexcludetags)
    for _, v in pairs(ents) do
        if v and v:IsValid() and v.prefab ~= "alterguardian_phase2" then
            v:PushEvent("lightningstrike")
            if v.components.playerlightningtarget then v.components.playerlightningtarget:DoStrike() end
        end
    end
end
local phase2islighting
AddPrefabPostInit("moonstorm_lightning", function(inst)
    if not TheWorld.ismastersim then return end
    if phase2islighting then inst:DoTaskInTime(0, moonstormsendlighting) end
end)
AddPrefabPostInit("moonstorm_glass", function(inst)
    if not TheWorld.ismastersim then return end
    if phase2islighting then
        if inst.components.lootdropper then inst.components.lootdropper:SetChanceLootTable() end
        if inst.components.timer and inst.components.timer:TimerExists("defusetime") then inst.components.timer:SetTimeLeft("defusetime", 1.5) end
    end
end)
-- 尖刺围墙会优先命中玩家
AddPrefabPostInit("alterguardian_phase2spiketrail", function(inst)
    if not TheWorld.ismastersim then return end
    local emerge
    if inst._emerge_task and inst._emerge_task.fn then
        emerge = inst._emerge_task.fn
        if phase2islighting then
            inst._emerge_task:Cancel()
            inst._emerge_task = inst:DoTaskInTime(2, emerge)
        end
    end
    if emerge and phase2spiketrailtmptarget and phase2spiketrailtmptarget:IsValid() then
        inst.target2hm = phase2spiketrailtmptarget
        if inst._watertest_task and inst._watertest_task.fn then
            local fn = inst._watertest_task.fn
            inst._watertest_task.fn = function(inst, ...)
                if not inst.startpos2hm then inst.startpos2hm = inst:GetPosition() end
                if inst.target2hm and inst.target2hm:IsValid() and
                    math.abs(
                        inst.target2hm:GetDistanceSqToPoint(inst.startpos2hm.x, 0, inst.startpos2hm.z) -
                            inst:GetDistanceSqToPoint(inst.startpos2hm.x, 0, inst.startpos2hm.z)) <= 2 then
                    emerge(inst)
                    if inst._watertest_task ~= nil then
                        inst._watertest_task:Cancel()
                        inst._watertest_task = nil
                    end
                    return
                end
                fn(inst, ...)
            end
        end
    end
end)
-- 妥协旋风攻击
local Advance_Full
local function umtornadoAdvance_Full(inst)
    if inst.Advance_Task ~= nil then inst.Advance_Task:Cancel() end
    inst.Advance_Task = nil
    inst.startmoving = true
    inst.AnimState:PlayAnimation("tornado_loop", true)
end
local function umtornadoInit(inst)
    inst.SoundEmitter:PlaySound("UCSounds/um_tornado/um_tornado_loop", "spinLoop")
    if not inst.is_full then
        inst.AnimState:PlayAnimation("tornado_pre")
        inst.Advance_Task = inst:ListenForEvent("animover", umtornadoAdvance_Full)
        inst.is_full = true
    else
        umtornadoAdvance_Full(inst)
    end
end
AddStategraphPostInit("alterguardian_phase2", function(sg)
    -- 海上优先使用旋转攻击
    local doattackfn = sg.events.doattack.fn
    sg.events.doattack.fn = function(inst, data, ...)
        if (not inst:IsOnValidGround() or not data.target:IsOnValidGround()) and not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) and data.target ~= nil and data.target:IsValid() then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)
            local attack_state = (not inst.components.timer:TimerExists("spin_cd") and dsq_to_target < TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE *
                                     TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * 2 and "spin_pre") or
                                     (not inst.components.timer:TimerExists("summon_cd") and "atk_summon") or
                                     (dsq_to_target < TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE * TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE and "atk_chop") or nil
            if attack_state ~= nil then
                inst.sg:GoToState(attack_state, data.target)
                return
            end
        end
        return doattackfn(inst, data, ...)
    end
    local OnEnteridle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        inst.spinattackindex2hm = 0 -- 旋转计次
        OnEnteridle(inst, ...)
        trylockseason(inst) -- 季节锁定
    end
    -- 连环闪电攻击
    local OnEnteratk_spike = sg.states.atk_spike.onenter
    sg.states.atk_spike.onenter = function(inst, ...)
        -- if not inst:HasTag("swc2hm") or inst.forcealterguardian2hm then
        --     phase2islighting = true
        --     inst:DoTaskInTime(32 * FRAMES, dolightingattack)
        -- end
        OnEnteratk_spike(inst, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.components.dockmanager ~= nil then TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000) end
    end
    AddStateTimeEvent2hm(sg.states.atk_spike, 32 * FRAMES, function(inst)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        phase2islighting = true
        dolightingattack(inst)
    end)
    local OnEnteratk_spike_pst = sg.states.atk_spike_pst.onenter
    sg.states.atk_spike_pst.onenter = function(inst, ...) OnEnteratk_spike_pst(inst, ...) end
    -- 连续旋转攻击，旋转后刷新某些技能的CD，旋转速度固定为22.5
    local OnEnterspin_pre = sg.states.spin_pre.onenter
    sg.states.spin_pre.onenter = function(inst, ...)
        OnEnterspin_pre(inst, ...)
        if not inst.umstormready2hm and TUNING.DSTU and TUNING.DSTU.STORMS and TheWorld.components.um_stormspawner and TheWorld.state.isspring and
            not NEWCONSTANT2HM and -- 2025.8.31 melon:加新界时不生成龙卷风
            not inst:HasTag("swc2hm") and (inst.umstorm2hm == nil or not inst.umstorm2hm:IsValid() or not inst:IsNear(inst.umstorm2hm, 100)) and math.random() <
            0.075 then
            inst.umstormready2hm = true
            if inst.components.rooted == nil then inst:AddComponent("rooted") end
            inst.components.rooted:AddSource(inst)
            inst.umstorm2hm = nil
        end
    end
    local OnEnterspin_loop = sg.states.spin_loop.onenter
    sg.states.spin_loop.onenter = function(inst, data, ...)
        if data and data.speed <= 30 then data.speed = math.max(data.speed, 15) * (2 - inst.components.health:GetPercent()) end
        -- if inst.umstormready2hm then data.speed = 0 end
        OnEnterspin_loop(inst, data, ...)
    end
    -- 旋转结束后生成玻璃刺围墙
    local OnEnterspin_pst = sg.states.spin_pst.onenter
    sg.states.spin_pst.onenter = function(inst, ...)
        if not inst:HasTag("swc2hm") or inst.forcealterguardian2hm then phase2islighting = nil end
        OnEnterspin_pst(inst, ...)
        -- 旋转结束后概率继续旋转，且必定释放一次三联旋转
        if inst.umstormready2hm and (inst.umstorm2hm == nil or not inst.umstorm2hm:IsValid() or not inst:IsNear(inst.umstorm2hm, 100)) then
            -- 召唤妥协旋风？
            local tornado = TheSim:FindFirstEntityWithTag("um_tornado")
            local force
            if tornado == nil then
                TheWorld:PushEvent("forcetornado")
                tornado = TheSim:FindFirstEntityWithTag("um_tornado")
                force = true
            end
            if tornado ~= nil and tornado:IsValid() and tornado.persists and (force or FindClosestPlayerToInst(tornado, 36, false) == nil) then
                tornado.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if tornado.startmoving and tornado.is_full then
                    tornado.is_full = false
                    umtornadoInit(tornado)
                end
                inst.umstorm2hm = tornado
            end
        else
            inst.spinattackindex2hm = (inst.spinattackindex2hm or 0) + 1
            if inst.spinattackthree2hm and inst.spinattackdouble2hm and math.random() < 0.033 then
                inst.spinattackdouble2hm = nil
                inst.spinattackthree2hm = nil
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then inst.components.timer:StopTimer("spin_cd") end
            elseif not inst.spinattackthree2hm and inst.spinattackdouble2hm and inst.spinattackindex2hm < 3 then
                inst.spinattackthree2hm = true
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then inst.components.timer:StopTimer("spin_cd") end
            elseif not inst.spinattackdouble2hm and math.random() > inst.components.health:GetPercent() and inst.spinattackindex2hm < 3 then
                inst.spinattackdouble2hm = true
                if inst.components.timer and inst.components.timer:TimerExists("spin_cd") then inst.components.timer:StopTimer("spin_cd") end
            elseif inst.components.timer then
                if inst.components.timer:TimerExists("spin_cd") and math.random() < 0.25 then
                    inst.components.timer:StopTimer("spin_cd")
                elseif inst.components.timer:TimerExists("summon_cd") then
                    inst.components.timer:StopTimer("summon_cd")
                end
            end
        end
    end
    AddStateTimeEvent2hm(sg.states.spin_pst, 11 * FRAMES, function(inst)
        if inst.umstormready2hm then
            inst.umstormready2hm = nil
            if inst.components.rooted then inst.components.rooted:RemoveSource(inst) end
        end
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        dospikesattack(inst)
    end)
    -- 召唤月影,旋风攻击
    local OnEnteratk_summon = sg.states.atk_summon.onenter
    sg.states.atk_summon.onenter = function(inst, ...)
        -- inst:DoTaskInTime(22 * FRAMES, dotornadoattack)
        OnEnteratk_summon(inst, ...)
        if inst.sg.mem.num_summons <= 0 and inst.components.timer and inst.components.timer:TimerExists("spike_cd") then
            inst.components.timer:StopTimer("spike_cd")
        end
    end
    AddStateTimeEvent2hm(sg.states.atk_summon, 22 * FRAMES, function(inst) dotornadoattack(inst) end)
end)

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- 第三阶段冰雪激光,世界变成冬季-----------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

-- 影子始终进攻模式
AddBrainPostInit("alterguardian_phase3brain", function(self)
    table.insert(self.bt.root.children, 2, Follow(self.inst, function()
        if self.inst:HasTag("swc2hm") then
            local target = self.inst.components.combat.target or
                               (self.inst.swp2hm and self.inst.swp2hm:IsValid() and self.inst.swp2hm.components.combat and
                                   self.inst.swp2hm.components.combat.target)
            if target and target:IsValid() and target:IsNear(self.inst, TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST) then return target end
        end
    end, math.max(6, TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE - 6), math.max(TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE - 2, 12),
                                                  math.max(14, TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE)))
end)
-- local function phase3processswc(inst) if inst:HasTag("swc2hm") and inst.components.knownlocations then inst.components.knownlocations.GetLocation = nilfn end end
-- 保护罩防御
local function cancelforcefieldcdtask(inst) inst.forcefieldcdtask2hm = nil end
AddPrefabPostInit("abigailforcefieldbuffed", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.debuff then
        local onattachedfn = inst.components.debuff.onattachedfn
        inst.components.debuff:SetAttachedFn(function(inst, target, ...)
            if onattachedfn then onattachedfn(inst, target, ...) end
            if inst.components.debuff.target and inst.components.debuff.target.prefab == "alterguardian_phase3" then
                inst.AnimState:SetScale(2, 2, 2)
                inst.AnimState:SetMultColour(1, 1, 1, 0.1)
            end
        end)
    end
end)
local function phase3ondeath(inst)
    addseasonlock(inst, 4, true)
    if TheWorld.state.precipitation ~= "none" then TheWorld:PushEvent("ms_forceprecipitation", false) end
    for _, v in ipairs(AllPlayers) do if v and v:HasTag("gestalt_possessable") then v:RemoveTag("gestalt_possessable") end end
end
local function onphase3spawnothershadow(inst, child)
    child.forcealterguardian2hm = true
    if child.components.freezable then child:RemoveComponent("freezable") end
end
-- 斥力场，击退敌人
local function cancelmoonpulsefxcd2hmtask(inst) inst.moonpulsefxcd2hmtask = nil end
local function cancelmoonpulsefx2hmtask(inst)
    inst.moonpulsefxcd2hmtask = inst:DoTaskInTime(2.5, cancelmoonpulsefxcd2hmtask)
    inst.moonpulsefx2hmtask = nil
end
local function phase3Vac2hm(inst)
    if not inst.moonpulsefxcd2hmtask then
        for index, player in ipairs(AllPlayers) do
            if not IsEntityDeadOrGhost(player) and not (player.sg and player.sg:HasStateTag("knockout")) and inst:GetDistanceSqToInst(player) <= 25 and
                Vector3(player.Physics:GetVelocity()):LengthSq() > 63 then
                if not inst.moonpulsefx2hmtask then
                    inst.moonpulsefx2hmtask = inst:DoTaskInTime(1.5, cancelmoonpulsefx2hmtask)
                    SpawnPrefab("moonpulse_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                player:PushEvent("knockback", {knocker = inst, radius = 5, forcelanded = false, propsmashed = true})
            end
        end
    end
end
local function phase3getattacked(inst, data)
    -- 攻击自己的敌人会被施加被虚影攻击的标记
    if data and data.target and not data.target:HasTag("gestalt_possessable") then data.target:AddTag("gestalt_possessable") end
    -- 远程攻击免疫防护罩
    if data and data.weapon and (data.weapon.components.projectile or (data.weapon.components.weapon and data.weapon.components.weapon.projectile)) and
        not inst.forcefieldcdtask2hm and not inst:HasDebuff("forcefield") and inst.components.combat and
        (not inst.components.combat.target or not inst:IsNear(inst.components.combat.target, 19.5)) then
        inst.forcefieldcdtask2hm = inst:DoTaskInTime(3, cancelforcefieldcdtask)
        inst:AddDebuff("forcefield", "abigailforcefieldbuffed")
    end
    -- -- 回血计数，需要足够多地攻击频率打断
    -- local currtime = GetTime()
    -- if not inst.dlidxcd2hm or currtime - inst.dlidxcd2hm >= TUNING.WILSON_ATTACK_PERIOD then
    --     inst.dlidxcd2hm = currtime
    --     inst.daylightidx2hm = math.max((inst.daylightidx2hm or 0) - 1, -10)
    -- end
end
-- 月灵不再攻击玩家鬼魂
AddPrefabPostInit("gestalt_guard", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.combat then
        local oldtargetfn = inst.components.combat.targetfn
        inst.components.combat.targetfn = function(inst)
            local target1, target2 = oldtargetfn(inst)
            if target1 and target1:HasTag("player") and (target1:HasTag("playerghost") or target1.components.health and target1.components.health:IsDead())  then
                target1 = nil
            end
            return target1, target2
        end
    end
end)
local function phase3onentitysleep(inst)
    if inst.vactask2hm then
        inst.vactask2hm:Cancel()
        inst.vactask2hm = nil
    end
end
local function phase3onentitywake(inst) if not inst.vactask2hm and not inst:HasTag("swc2hm") then inst.vactask2hm = inst:DoPeriodicTask(FRAMES, phase3Vac2hm) end end
local function swp2hmfn(inst)
    if alterguardianmode >= -3 and inst.components.childspawner2hm then
        inst.components.childspawner2hm:SetQueuedChildren({"alterguardian_phase2", "alterguardian_phase1"}, true)
        inst.components.childspawner2hm:SetMaxChildren(inst.components.childspawner2hm.maxchildren + 2)
        inst.components.childspawner2hm:SetQueueSpawnedFn(onphase3spawnothershadow)
    end
    inst:ListenForEvent("entitysleep", phase3onentitysleep)
    inst:ListenForEvent("entitywake", phase3onentitywake)
    if not inst:IsAsleep() then phase3onentitywake(inst) end
    if inst.components.combat and inst.components.combat.targetfn and inst.components.knownlocations then
        local targetfn = inst.components.combat.targetfn
        inst.components.combat:SetRetargetFunction(inst.components.combat.retargetperiod or 3, function(inst, ...)
            local GetLocation = inst.components.knownlocations.GetLocation
            inst.components.knownlocations.GetLocation = nilfn
            local target, f = targetfn(inst, ...)
            inst.components.knownlocations.GetLocation = GetLocation
            return target, f
        end)
    end
end
local function phase3KeepTarget(inst, target)
    if inst.components.combat:CanTarget(target) then
        if inst:HasTag("swc2hm") then return true end
        local x, y, z = inst.Transform:GetWorldPosition()
        if target:GetDistanceSqToPoint(x, y, z) < TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ then
            local newtarget = FindClosestPlayerInRange(x, y, z, 12, true)
            if newtarget == nil or newtarget == target then return true end
        end
    end
end
-- 冰岛地皮破坏时不生成冰块冰船也不删除特殊单位
local disableboaticetileremove
local function FastDestroyIceTiles(inst)
    if inst.destroyicetilestask2hm then
        inst.destroyicetilestask2hm:Cancel()
        inst.destroyicetilestask2hm = nil
    end
    local data = inst.components.persistent2hm.data.icetiles or {}
    disableboaticetileremove = true
    for i, pos in ipairs(data) do
        if pos and pos.x and pos.y then TheWorld.components.oceanicemanager:DamageIceAtTile(pos.x, pos.y, TUNING.OCEAN_ICE_HEALTH) end
    end
    disableboaticetileremove = nil
    inst.components.persistent2hm.data.icetiles = nil
end
local function DestroyIceTiles(inst, radius)
    if inst.destroyicetilestask2hm then
        inst.destroyicetilestask2hm:Cancel()
        inst.destroyicetilestask2hm = nil
    end
    local data = inst.components.persistent2hm.data.icetiles or {}
    if not IsTableEmpty(data) then
        radius = radius or 45
        local radiussq = radius * radius
        disableboaticetileremove = true
        for i, pos in ipairs(data) do
            if pos and pos.x and pos.y and inst:GetDistanceSqToPoint(TheWorld.Map:GetTileCenterPoint(pos.x, pos.y)) >= radiussq then
                TheWorld.components.oceanicemanager:DamageIceAtTile(pos.x, pos.y, TUNING.OCEAN_ICE_HEALTH)
            end
        end
        disableboaticetileremove = nil
        inst.destroyicetilestask2hm = inst:DoTaskInTime(1, DestroyIceTiles, radius - 5)
    end
end
local function delayremoveiceboat(inst)
    inst.components.boatphysics = nil
    inst.components.walkableplatform = nil
    inst:Remove()
end
AddComponentPostInit("oceanicemanager", function(self)
    local QueueDestroyForIceAtPoint = self.QueueDestroyForIceAtPoint
    local destroy_ice_at_point = getupvalue2hm(self.QueueDestroyForIceAtPoint, "destroy_ice_at_point")
    if destroy_ice_at_point ~= nil then
        self.QueueDestroyForIceAtPoint = function(self, x, y, z, data, ...)
            local DoTaskInTime = TheWorld.DoTaskInTime
            if disableboaticetileremove then
                data = data or {}
                data.silent = true
                TheWorld.DoTaskInTime = function(inst, time, fn, ...)
                    if fn == destroy_ice_at_point then
                        return DoTaskInTime(inst, time, function(world, dx, dz, oceanicemanager, ...)
                            local _DestroyEntity = GLOBAL.DestroyEntity
                            GLOBAL.DestroyEntity = nilfn
                            local _SpawnPrefab = GLOBAL.SpawnPrefab
                            GLOBAL.SpawnPrefab = function(prefab, ...)
                                if prefab == "boat_ice" then
                                    local entity = _SpawnPrefab("ice")
                                    entity.components.boatphysics = {ApplyRowForce = nilfn}
                                    entity.components.walkableplatform = {platform_radius = 0}
                                    entity:DoTaskInTime(0, delayremoveiceboat)
                                    return entity
                                elseif prefab == "ice" or prefab == "degrade_fx_ice" then
                                    local entity = _SpawnPrefab(prefab)
                                    entity:DoTaskInTime(0, entity.Remove)
                                    return entity
                                end
                                return _SpawnPrefab(prefab, ...)
                            end
                            oceanicemanager:DestroyIceAtPoint(dx, 0, dz)
                            GLOBAL.SpawnPrefab = _SpawnPrefab
                            GLOBAL.DestroyEntity = _DestroyEntity
                        end, ...)
                    end
                    return DoTaskInTime(inst, time, fn, ...)
                end
            end
            QueueDestroyForIceAtPoint(self, x, y, z, data, ...)
            TheWorld.DoTaskInTime = DoTaskInTime
        end
    end
end)
local function clearicetilescd2hmtask(inst) inst.icetilescd2hmtask = nil end
-- 三阶段加强
AddPrefabPostInit("alterguardian_phase3", function(inst)
    inst:AddTag("alterguardian2hm")
    inst:AddTag("toughworker")
    if not TheWorld.ismastersim then return end
    if inst.components.freezable then inst:RemoveComponent("freezable") end
    addminimapicon(inst)
    addprototyper(inst)
    addseasonlock(inst, 3)
    inst:ListenForEvent("getattacked2hm", phase3getattacked)
    inst:ListenForEvent("death", phase3ondeath)
    -- inst.swc2hmfn = phase3processswc
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    if TUNING.shadowworld2hm then
        inst.swp2hmfn = swp2hmfn
    else
        swp2hmfn(inst)
    end
    inst:ListenForEvent("onremove", FastDestroyIceTiles)
    inst:ListenForEvent("death", FastDestroyIceTiles)
    inst.destroyicetilestask2hm = inst:DoTaskInTime(30, DestroyIceTiles)
    inst.icetilescd2hmtask = inst:DoTaskInTime(60, clearicetilescd2hmtask)
    if inst.components.combat then inst.components.combat:SetKeepTargetFunction(phase3KeepTarget) end
    if not TUNING.noalterguardianhat2hm and inst.components.lootdropper then
        inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
        inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
    end
end)
-- 携带旧靴子可以免疫冰岛地皮
local function bootlegcancel(inst)
    local oldowner = inst.oldowner2hm
    inst.oldowner2hm = nil
    if oldowner and oldowner:IsValid() and oldowner.bootlegs2hm then
        for i = #oldowner.bootlegs2hm, 1, -1 do
            local bootleg = oldowner.bootlegs2hm[i]
            if bootleg == inst then
                table.remove(oldowner.bootlegs2hm, i)
                break
            end
        end
        if IsTableEmpty(oldowner.bootlegs2hm) and not oldowner:HasTag("playerghost") and not oldowner.components.slipperyfeet then
            oldowner:AddComponent("slipperyfeet")
            oldowner.bootlegs2hm = nil
        end
    end
end
local function bootlegupdate(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner == inst.oldowner2hm then return end
    bootlegcancel(inst)
    if owner and owner:IsValid() and owner:HasTag("player") and owner.components.slipperyfeet then
        inst.oldowner2hm = owner
        inst.oldowner2hm:RemoveComponent("slipperyfeet")
        owner.bootlegs2hm = owner.bootlegs2hm or {}
        table.insert(owner.bootlegs2hm, inst)
    end
end
local function delaybootlegupdate(inst) inst:DoTaskInTime(0, bootlegupdate) end
AddPrefabPostInit("bootleg", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onputininventory", delaybootlegupdate)
    inst:ListenForEvent("ondropped", delaybootlegupdate)
    inst:ListenForEvent("onremove", bootlegcancel)
end)
-- 冰岛领域
local ICE_AOE_TARGET_TAGS = {"_combat"}
local ICE_AOE_TARGET_CANT_TAGS = {"INLIMBO", "flight", "invisible", "playerghost", "lunar_aligned"}
local min_distance_from_entities = ((TILE_SCALE / 2) + 1.0) * 1.4142
local CUSTOM_DEPLOY_IGNORE_TAGS = {
    "NOBLOCK",
    "player",
    "FX",
    "INLIMBO",
    "DECOR",
    "ignorewalkableplatforms",
    "ignorewalkableplatformdrowning",
    "activeprojectile",
    "flying",
    "kelp",
    "_inventoryitem",
    "_health",
    "moonglass"
}
local function createareaicetiles(inst, straight)
    if inst:HasTag("swc2hm") then return end
    if TheWorld.components.oceanicemanager and inst.components.persistent2hm and not (inst.components.health and inst.components.health:IsDead()) then
        if inst.destroyicetilestask2hm then inst.destroyicetilestask2hm:Cancel() end
        inst.destroyicetilestask2hm = inst:DoTaskInTime(60, DestroyIceTiles)
        local data = inst.components.persistent2hm.data.icetiles or {}
        inst.components.persistent2hm.data.icetiles = data
        local _x, _y, _z = inst.Transform:GetWorldPosition()
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(_x, 0, _z)
        _x, _y, _z = TheWorld.Map:GetTileCenterPoint(tx, ty)
        local radius = 25
        for i = 0, radius, 4 do
            local function processice()
                for j = -i, i, 4 do
                    for k = -i, i, 4 do
                        if j * j + k * k <= 625 then
                            local x = _x + j
                            local z = _z + k
                            local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
                            local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
                            local canicetile
                            if tile == WORLD_TILES.OCEAN_ICE then
                                canicetile = false
                            elseif IsLandTile(tile) then
                                canicetile = true
                            else
                                canicetile = true
                                local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tile_x, tile_y))
                                if not IsTableEmpty(TheSim:FindEntities(center_pt.x, 0, center_pt.z, min_distance_from_entities, nil, CUSTOM_DEPLOY_IGNORE_TAGS)) then
                                    canicetile = false
                                end
                            end
                            if canicetile then
                                table.insert(data, {x = tile_x, y = tile_y})
                                TheWorld.components.oceanicemanager:CreateIceAtTile(tile_x, tile_y)
                            end
                        end
                    end
                end
            end
            if straight then
                processice()
            else
                inst:DoTaskInTime(i * 5 * FRAMES, processice)
            end
        end
    end
end
-- 冰火攻击，同时制造一条线的冰岛地皮
local function CreateIceTileAtPoint(inst, i, x, z, data, rot, targets)
    local fx = SpawnPrefab("warg_mutated_breath_fx")
    fx.Transform:SetPosition(x, 0, z)
    if i % 4 ~= 0 then return end
    -- 冰岛地皮
    local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    local canicetile
    if tile == WORLD_TILES.OCEAN_ICE then
        canicetile = false
    elseif IsLandTile(tile) then
        canicetile = true
    else
        canicetile = true
        local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tile_x, tile_y))
        if not IsTableEmpty(TheSim:FindEntities(center_pt.x, 0, center_pt.z, min_distance_from_entities, nil, CUSTOM_DEPLOY_IGNORE_TAGS)) then
            canicetile = false
        end
    end
    if canicetile then
        table.insert(data, {x = tile_x, y = tile_y})
        TheWorld.components.oceanicemanager:CreateIceAtTile(tile_x, tile_y)
    end
    -- 冰火伤害
    inst.components.combat.ignorehitrange = true
    inst.components.combat.ignoredamagereflect = true
    local ents = TheSim:FindEntities(x, 0, z, 3, ICE_AOE_TARGET_TAGS, ICE_AOE_TARGET_CANT_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and v ~= inst and not targets[v] and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            targets[v] = true
            -- Supercool
            if v.components.temperature ~= nil then
                local newtemp = math.max(v.components.temperature.mintemp, TUNING.MUTATED_WARG_COLDFIRE_TEMPERATURE)
                if newtemp < v.components.temperature:GetCurrent() then v.components.temperature:SetTemperature(newtemp) end
            end
            -- Hit
            if inst.components.combat:CanTarget(v) then inst.components.combat:DoAttack(v) end
            -- Freeze
            if v.components.freezable ~= nil then
                v.components.freezable:AddColdness(4)
                v.components.freezable:SpawnShatterFX()
            end
        end
    end
    inst.components.combat.ignorehitrange = false
    inst.components.combat.ignoredamagereflect = false
end
local function doiceattack(inst, rot)
    if inst:HasTag("swc2hm") then return end
    if TheWorld.components.oceanicemanager and inst.components.persistent2hm and not inst.icetilescd2hmtask then
        local data = inst.components.persistent2hm.data.icetiles or {}
        inst.components.persistent2hm.data.icetiles = data
        local radius = 50
        local targets = {}
        local x, y, z = inst.Transform:GetWorldPosition()
        local cosrot = math.cos(rot)
        local sinrot = math.sin(rot)
        for i = 0, radius, 2 do inst:DoTaskInTime(i * FRAMES / 2, CreateIceTileAtPoint, i, x + i * cosrot, z - i * sinrot, data, rot, targets) end
        if inst.destroyicetilestask2hm then inst.destroyicetilestask2hm:Cancel() end
        inst.destroyicetilestask2hm = inst:DoTaskInTime(60, DestroyIceTiles)
        inst.icetilescd2hmtask = inst:DoTaskInTime(50, clearicetilescd2hmtask)
    end
end
-- 大虚影攻击
local function killgestalt(inst) inst.components.health:Kill() end
local function ongestaltattack(inst)
    inst.attacktimes = (inst.attacktimes or 0) + 1
    if inst.attacktimes >= 2 then inst:DoTaskInTime(30 * FRAMES, killgestalt) end
end
local function dogestaltattack(inst)
    if inst._stop_task and TUNING.alterguardianseason2hm == 3 and TheWorld.state.isalterawake then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ent = SpawnPrefab("gestalt_guard")
        ent.AnimState:SetAddColour(5 / 255, 87 / 255, 255 / 255, 0.8)
        ent.Transform:SetPosition(x, 0, z)
        ent.persists = false
        ent.entity:SetCanSleep(false)
        ent:ListenForEvent("doattack", ongestaltattack)
        ent:DoTaskInTime(math.random(15, 45), killgestalt)
        if inst.find_attack_victim then
            local attack_target = inst:find_attack_victim()
            if attack_target ~= nil then ent.components.combat:SetTarget(attack_target) end
        end
    end
end
local function ongestaltprojanimover(inst)
    if TUNING.alterguardianseason2hm == 3 and TheWorld.state.isalterawake and
        (inst.AnimState:IsCurrentAnimation("emerge") or inst.AnimState:IsCurrentAnimation("attack")) then inst:DoTaskInTime(24 * FRAMES, dogestaltattack) end
end
AddPrefabPostInit("gestalt_alterguardian_projectile", function(inst)
    if not TheWorld.ismastersim then return end
    if TUNING.alterguardianseason2hm == 3 and TheWorld.state.isalterawake and math.random() < 0.5 then inst:ListenForEvent("animover", ongestaltprojanimover) end
end)
-- 环绕启迪陷阱攻击
SetSharedLootTable2hm("moonglass_trap", {{"moonglass", 0.05}})
local function spawnprotecttrap(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local trap = SpawnPrefab("alterguardian_phase3trap")
    trap.persists = false
    trap.components.lootdropper:SetChanceLootTable()
    trap.Transform:SetPosition(ix, iy, iz)
    trap.AnimState:SetScale(0.6, 0.6)
    inst:Remove()
end
local function dotrapattack(inst)
    if inst:HasTag("swc2hm") then return end
    local POINTS_ANGLEDIFF = PI / 18
    local RADIUS = math.sqrt(TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ)
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local angle = 0
    while angle < 2 * PI do
        local x = ix + RADIUS * math.cos(angle)
        local z = iz + RADIUS * math.sin(angle)
        local projectile = SpawnPrefab("alterguardian_phase3trapprojectile")
        projectile.Transform:SetPosition(x, 0, z)
        projectile.AnimState:SetScale(0.6, 0.6)
        projectile:SetGuardian(inst)
        angle = angle + POINTS_ANGLEDIFF
        if projectile.event_listeners and projectile.event_listeners.animover then
            for k, value in pairs(projectile.event_listeners.animover) do
                for index, fn in pairs(value) do
                    value[index] = spawnprotecttrap
                    break
                end
            end
        end
    end
end
local function onphase3trapprojectileremove(inst)
    if inst.components.lootdropper and inst.components.lootdropper.chanceloottable then
        local spell = SpawnPrefab("deer_ice_circle")
        if spell.TriggerFX then spell:DoTaskInTime(2, spell.TriggerFX) end
        spell.Transform:SetPosition(inst.Transform:GetWorldPosition())
        spell:DoTaskInTime(4, spell.KillFX)
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.components.dockmanager ~= nil then TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 1000) end
    end
end
AddPrefabPostInit("alterguardian_phase3trap", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onremove", onphase3trapprojectileremove)
end)
-- 激光攻击
local function laserattack(inst, enable, targets, skiptoss, skipscorch, x, z, first, target_pos)
    if enable then
        if first or not IsTableEmpty(FindPlayersInRangeSq(x, 0, z, 25, true)) then
            local fx = SpawnPrefab(first and "alterguardian_laserempty" or "alterguardian_laser")
            fx.caster = inst
            fx.Transform:SetPosition(x, 0, z)
            fx:Trigger(0, targets, skiptoss, skipscorch)
            if first then ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .2, target_pos or fx, 30) end
        end
    else
        SpawnPrefab("alterguardian_laserscorch").Transform:SetPosition(x, 0, z)
    end
end
-- ×形激光攻击
local Laser_NUM_STEPS = 10
local SECOND_BLAST_TIME = 22 * FRAMES
local function SpawnNewBeam(inst, target_pos, angleoffset)
    local BEGIN_STEP = Laser_NUM_STEPS / 2
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local angle = math.atan2(iz - target_pos.z, ix - target_pos.x)
    if angleoffset then angle = angle + angleoffset * DEGREES end
    local gx, gy, gz = target_pos:Get()
    gx = gx + BEGIN_STEP * math.cos(angle)
    gz = gz + BEGIN_STEP * math.sin(angle)
    local targets, skiptoss = {}, {}
    local sbtargets, sbskiptoss = {}, {}
    local x, z = nil, nil
    local delay = nil
    local i = -1
    while i < Laser_NUM_STEPS do
        i = i + 1
        delay = math.max(0, i - 1) * FRAMES
        x = gx - i * math.cos(angle)
        z = gz - i * math.sin(angle)
        local first = i == 0
        local x1, z1 = x, z
        inst:DoTaskInTime(delay, laserattack, nil, nil, nil, nil, x1, z1, first, target_pos)
        inst:DoTaskInTime(delay + SECOND_BLAST_TIME, laserattack, true, sbtargets, sbskiptoss, nil, x1, z1, first, target_pos)
        inst:DoTaskInTime(delay + SECOND_BLAST_TIME * 2, laserattack, true, targets, skiptoss, true, x1, z1, first, target_pos)
    end
    inst:DoTaskInTime(i * FRAMES, laserattack, nil, nil, nil, nil, x, z, nil, nil)
    inst:DoTaskInTime((i + 1) * FRAMES, laserattack, nil, nil, nil, nil, x, z, nil, nil)
end
local function dobeamlaserattack(inst)
    if inst:HasTag("swc2hm") then return end
    local target = inst.components.combat.target or FindClosestPlayerToInst(inst, 125, true)
    if target and target:IsValid() then
        local target_pos = target:GetPosition()
        SpawnNewBeam(inst, target_pos, 45)
        SpawnNewBeam(inst, target_pos, -45)
    end
end
-- 环形激光攻击
local function SpawnNewSweep(inst, target_pos, instposoverride)
    local SWEEP_ANGULAR_LENGTH = 360
    local BASE_SWEEP_DISTANCE = 8
    local gx, gy, gz = inst.Transform:GetWorldPosition()
    if instposoverride then
        gx = instposoverride.x
        gy = instposoverride.y
        gz = instposoverride.z
    end
    local angle = nil
    local dist = nil
    local angle_step_dir = (math.random() < 0.5 and 1 or -1)
    local x_dir = 1
    if target_pos == nil then
        angle = DEGREES * (inst.Transform:GetRotation() + (SWEEP_ANGULAR_LENGTH / 4))
        dist = BASE_SWEEP_DISTANCE
        x_dir = -1
    else
        angle = math.atan2(gz - target_pos.z, gx - target_pos.x) - (SWEEP_ANGULAR_LENGTH * DEGREES / 4)
        dist = math.max(math.sqrt(inst:GetDistanceSqToPoint(target_pos:Get())), 3)
    end
    local num_angle_steps = 40 + RoundBiasedDown((math.abs(dist) - BASE_SWEEP_DISTANCE) / 2) * 4
    local angle_step = (SWEEP_ANGULAR_LENGTH / num_angle_steps) * DEGREES
    local targets, skiptoss = {}, {}
    local sbtargets, sbskiptoss = {}, {}
    local x, z = nil, nil
    local delay = nil
    local i = -1
    while i < num_angle_steps do
        i = i + 1
        delay = math.max(0, i - 1) * FRAMES / 4
        x = gx - (x_dir * dist * math.cos(angle))
        z = gz - dist * math.sin(angle)
        angle = angle + (angle_step_dir * angle_step)
        local first = i == 0
        local x1, z1 = x, z
        inst:DoTaskInTime(delay, laserattack, nil, nil, nil, nil, x1, z1, first, target_pos)
        inst:DoTaskInTime(delay + SECOND_BLAST_TIME, laserattack, true, sbtargets, sbskiptoss, nil, x1, z1, first, target_pos)
        inst:DoTaskInTime(delay + SECOND_BLAST_TIME * 2, laserattack, true, targets, skiptoss, true, x1, z1, first, target_pos)
    end
    inst:DoTaskInTime(i * FRAMES, laserattack, nil, nil, nil, nil, x, z, nil, nil)
    inst:DoTaskInTime((i + 1) * FRAMES, laserattack, nil, nil, nil, nil, x, z, nil, nil)
end
local function dosweeplaserattack(inst)
    if inst:HasTag("swc2hm") then return end
    -- 一道到三道环形激光
    local target = inst.components.combat.target or FindClosestPlayerToInst(inst, 45, true)
    if target and target:IsValid() then
        local target_pos = target:GetPosition()
        SpawnNewSweep(inst, target_pos)
        local itot = target_pos - inst:GetPosition()
        if itot:LengthSq() > 0 then
            local itot_dir, itot_len = itot:GetNormalizedAndLength()
            SpawnNewSweep(inst, target_pos + (itot_dir * 4.5))
            if itot_len > 9 then SpawnNewSweep(inst, target_pos - (itot_dir * 4.5)) end
        end
    end
end
-- -- 回血攻击
-- local function dodaylightattack(inst)
--     if inst.components.health:IsDead() then return end
--     local x, y, z = inst.Transform:GetWorldPosition()
--     SpawnPrefab("moonpulse_fx").Transform:SetPosition(x, y, z)
--     local lights = TheSim:FindEntities(x, y, z, 8, {"daylight"})
--     for _, light in ipairs(lights) do
--         if light and light:IsValid() and light.prefab == "booklight" then
--             light:DoTaskInTime(0, light.Remove)
--             inst.components.health:SetPercent(inst.components.health:GetPercent() + 0.05)
--             return
--         end
--     end
--     local light = SpawnPrefab("booklight")
--     light.persists = false
--     light.Transform:SetPosition(x, y, z)
--     light:SetDuration(TUNING.TOTAL_DAY_TIME / 2)
--     local fx = SpawnPrefab("hotcold_fx")
--     fx.Transform:SetScale(2, 2, 2)
--     fx.AnimState:PlayAnimation("idle3")
--     fx.Transform:SetPosition(x, 0, z)
--     fx:ListenForEvent("animover", fx.Remove)
--     fx:DoTaskInTime(3, fx.Remove)
-- end
AddStategraphPostInit("alterguardian_phase3", function(sg)
    local OnEnteridle = sg.states.idle.onenter
    sg.states.idle.onenter = function(inst, ...)
        OnEnteridle(inst, ...)
        trylockseason(inst)
        for _, v in ipairs(AllPlayers) do if v and not v:HasTag("gestalt_possessable") then v:AddTag("gestalt_possessable") end end
    end
    local OnEnteratk_beam = sg.states.atk_beam.onenter
    sg.states.atk_beam.onenter = function(inst, ...)
        OnEnteratk_beam(inst, ...)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        if not inst.icetilescd2hmtask and inst.sg.statemem.target ~= nil and math.random() < 0.25 then
            SpawnPrefab("moonpulse_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.readydoiceattack2hm = true
        end
    end
    AddStateTimeEvent2hm(sg.states.atk_beam, 34 * FRAMES, function(inst)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        if inst.readydoiceattack2hm then
            inst.readydoiceattack2hm = nil
            local targetpos = inst.sg.statemem.target_pos
            if targetpos == nil then
                local player = FindClosestPlayerToInst(inst, 36, true)
                targetpos = player and player:GetPosition()
            end
            doiceattack(inst, (targetpos and inst:GetAngleToPoint(targetpos) or inst:GetRotation()) * DEGREES)
            inst.sg:GoToState("idle", true)
        end
    end)
    local OnEnteratk_summon_pre = sg.states.atk_summon_pre.onenter
    sg.states.atk_summon_pre.onenter = function(inst, ...)
        OnEnteratk_summon_pre(inst, ...)
        if inst.candeerice2hm then
            onphase3trapprojectileremove(inst)
        else
            inst.candeerice2hm = true
        end
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        createareaicetiles(inst)
        -- 环形激光攻击，这个攻击似乎很卡顿，考虑删除
        -- if inst:HasTag("swc2hm") then return end
        -- inst:DoTaskInTime(35 * FRAMES, dosweeplaserattack)
    end
    local OnExitatk_summon_pre = sg.states.atk_summon_pre.onexit
    sg.states.atk_summon_pre.onexit = function(inst, ...)
        if OnExitatk_summon_pre then OnExitatk_summon_pre(inst, ...) end
        if not inst.sg.statemem.loop_exit or (inst:HasTag("swc2hm") and not inst.forcealterguardian2hm) then return end
        dosweeplaserattack(inst)
    end
    -- AddStateTimeEvent2hm(sg.states.atk_summon_pre, 35 * FRAMES, function(inst)
    --     if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
    --     dosweeplaserattack(inst)
    -- end)
    -- local onenter_atk_summon_loop = sg.states.atk_summon_loop.onenter
    -- sg.states.atk_summon_loop.onenter = function(inst, ...)
    --     onenter_atk_summon_loop(inst, ...)
    --     if inst:HasTag("swc2hm") then return end
    --     if inst.sg.mem.summon_loops == 0 then dodaylightattack(inst) end
    --     inst.daylightidx2hm = (inst.daylightidx2hm or 0) + (inst.sg.mem.summon_loops == 0 and 5 or 1)
    --     if inst.daylightidx2hm >= 5 then
    --         inst.daylightidx2hm = inst.daylightidx2hm - 5
    --         dodaylightattack(inst)
    --     end
    -- end
    -- local OnEnteratk_summon_pst = sg.states.atk_summon_pst.onenter
    -- sg.states.atk_summon_pst.onenter = function(inst, ...)
    --     OnEnteratk_summon_pst(inst, ...)
    -- end
    -- local OnEnteratk_traps = sg.states.atk_traps.onenter
    -- sg.states.atk_traps.onenter = function(inst, ...)
    --     OnEnteratk_traps(inst, ...)
    --     if inst:HasTag("swc2hm") then
    --         inst:DoTaskInTime(35 * FRAMES, dobeamlaserattack)
    --     else
    --         inst:DoTaskInTime(69 * FRAMES, dotrapattack)
    --     end
    -- end
    AddStateTimeEvent2hm(sg.states.atk_traps, 35 * FRAMES, function(inst) if inst:HasTag("swc2hm") then dobeamlaserattack(inst) end end)
    AddStateTimeEvent2hm(sg.states.atk_traps, 69 * FRAMES, function(inst)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        dotrapattack(inst)
    end)
    local OnEnteratk_stab = sg.states.atk_stab.onenter
    sg.states.atk_stab.onenter = function(inst, ...)
        OnEnteratk_stab(inst, ...)
        if inst.candeerice2hm then
            inst.candeerice2hm = nil
            onphase3trapprojectileremove(inst)
        end
        -- if inst:HasTag("swc2hm") then return end
        -- inst:DoTaskInTime(35 * FRAMES, dobeamlaserattack)
    end
    AddStateTimeEvent2hm(sg.states.atk_stab, 35 * FRAMES, function(inst)
        if inst:HasTag("swc2hm") and not inst.forcealterguardian2hm then return end
        dobeamlaserattack(inst)
    end)
end)

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- 第四阶段安逸休闲,世界变成秋季-----------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

local function onphase3deadworkfinished(inst)
    if TUNING.alterguardianseason2hm > 0 then TheWorld:PushEvent("delayrefreshseason2hm") end
    TUNING.alterguardianseason2hm = 0
end
AddPrefabPostInit("alterguardian_phase3deadorb", function(inst)
    inst:AddTag("alterguardian2hm")
    if not TheWorld.ismastersim then return end
    addminimapicon(inst)
    addprototyper(inst)
    inst:DoTaskInTime(0, addseasonlock, 4, true)
end)
AddPrefabPostInit("alterguardian_phase3dead", function(inst)
    inst:AddTag("alterguardian2hm")
    if not TheWorld.ismastersim then return end
    addminimapicon(inst)
    addprototyper(inst)
    inst:DoTaskInTime(0, addseasonlock, 4, true)
    if inst.components.workable then inst.components.workable:SetRequiresToughWork(true) end
    inst:ListenForEvent("onremove", onphase3deadworkfinished)
    if inst.components.lootdropper and TUNING.noalterguardianhat2hm then
        inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
        inst.components.lootdropper:AddChanceLoot("alterguardianhat", 1.00)
    end
end)
