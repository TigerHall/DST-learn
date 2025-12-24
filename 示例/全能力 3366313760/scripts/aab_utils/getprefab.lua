--@author: 绯世行
--欢迎其他开发者直接使用，但是强烈谴责搬用代码后对搬用代码加密的行为！
--使用案例及最新版：https://n77a3mjegs.feishu.cn/docx/K9bUdpb5Qo85j2xo8XkcOsU1nuh?from=from_copylink

local FN = {}

local _source = debug.getinfo(1, 'S').source
local KEY = "_" .. _source:match(".*scripts[/\\](.*)%.lua"):gsub("[/\\]", "_") .. "_"

local Utils = require(_source:match(".*scripts[/\\](.*[/\\])") .. "utils")
local Shapes = require(_source:match(".*scripts[/\\](.*[/\\])") .. "shapes")
local Timer = require(_source:match(".*scripts[/\\](.*[/\\])") .. "timer")

local DEBUG_MODE = BRANCH == "dev"

---隐藏，停止一切活动，来自inventoryitem
function FN.Hide(inst)
    inst:RemoveFromScene()
    if inst.Transform then
        inst.Transform:SetPosition(0, 0, 0)
    end
    if inst.components.brain then
        BrainManager:Hibernate(inst)
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:KillAllSounds()
    end
end

---显示，来自inventoryitem，与Hide配套使用
function FN.Show(inst)
    inst:ReturnToScene()
    if inst.components.brain then
        BrainManager:Wake(self.inst)
    end
end

local ATTACK_ONEOF_TAGS = { "monster", "hostile" }

---攻击对象检测，会攻击monster标签生物和当前仇恨对象，不会误伤其他单位
function FN.PlayerTargetTest(inst, target, force)
    if (target:HasTag("player") and not TheNet:GetPVPEnabled())
        or (inst.components.combat and (not inst.components.combat:CanTarget(target) or inst.components.combat:IsAlly(target)))
    then
        return false
    end

    local t = target.components.combat.target
    local l = target.components.follower and target.components.follower:GetLeader()

    return (force and target:HasOneOfTags(ATTACK_ONEOF_TAGS) and not (l and l:HasTag("player")))
        or t and (
            t == inst                                                                                       --敌人想攻击自己
            or t:HasTag("player")                                                                           --敌人想攻击玩家
            or (t:HasTag("companion") and not (t.components.combat and t.components.combat.target == inst)) --敌人想攻击友方单位，但是如果友方单位想攻击自己就不用管了
        )
        or false
end

---卸下装备的重物
function FN.ForceStopHeavyLifting(inst)
    if inst.components.inventory and inst.components.inventory:IsHeavyLifting() then
        inst.components.inventory:DropItem(inst.components.inventory:Unequip(EQUIPSLOTS.BODY), true, true)
    end
end

---自定义爆炸对象，改编自explosive.lua
---@param data table|nil {attacker, explosiveDamage, planarDamage, workDamage, range, MUST_TAGS, CANT_TAGS,findFn,containDock,skipCameraFlash,lightOnExplode}
---{攻击者，爆炸伤害，位面伤害，工作伤害，爆炸范围，MUST_TAGS，CANT_TAGS，校验函数，是否影响甲板，是否跳过画面闪烁，是否点燃对象}
function FN.GetBombExplode(pos, data)
    local world = TheWorld
    local x, y, z = pos.x, pos.y, pos.z
    local attacker = Utils.GetVal(data, "attacker", TheWorld)        --攻击者
    local totaldamage = Utils.GetVal(data, "explosiveDamage", 200)   --爆炸伤害
    local spdmg = { planar = Utils.GetVal(data, "planarDamage", 0) } --位面伤害
    local workDamage = Utils.GetVal(data, "workDamage", 10)          --工作伤害
    local range = Utils.GetVal(data, "range", 3)                     --爆炸范围
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS")                --MUST_TAGS
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS", { "INLIMBO" }) --CANT_TAGS
    local findFn = Utils.GetVal(data, "findFn")                      --校验函数
    local containDock = Utils.GetVal(data, "containDock")            --是否影响甲板
    local cameraFlash = Utils.GetVal(data, "cameraFlash")            --画面闪烁，一般爆炸效果有的
    local lightOnExplode = Utils.GetVal(data, "lightOnExplode")      --是否点燃对象
    local onAttackOther = Utils.GetVal(data, "onAttackOther")        --攻击后回调

    --画面闪烁
    if cameraFlash then
        for i, v in ipairs(AllPlayers) do
            local distSq = attacker ~= TheWorld and v:GetDistanceSqToInst(attacker) or 0
            local k = math.max(0, math.min(1, distSq / 400))
            local intensity = k * 0.75 * (k - 2) + 0.75 --easing.outQuad(k, 1, -1, 1)
            if intensity > 0 then
                v:ScreenFlash(intensity)
                v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 2)
            end
        end
    end

    if containDock then
        if world.components.dockmanager ~= nil then
            world.components.dockmanager:DamageDockAtPoint(x, y, z, totaldamage)
        end
    end

    local ents = TheSim:FindEntities(x, y, z, range, MUST_TAGS, CANT_TAGS)
    for i, v in ipairs(ents) do
        if not v:IsInLimbo() and v:IsValid() and (not findFn or findFn(v)) then
            --工作
            if workDamage > 0 and v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                v.components.workable:WorkedBy(attacker, workDamage)
            end

            --Recheck valid after work
            if not v:IsInLimbo() and v:IsValid() then
                --点燃
                if lightOnExplode and
                    v.components.fueled == nil and
                    v.components.burnable ~= nil and
                    not v.components.burnable:IsBurning() and
                    not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end

                if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
                    local dmg = totaldamage
                    if v.components.explosiveresist ~= nil then
                        dmg = dmg * (1 - v.components.explosiveresist:GetResistance())
                        v.components.explosiveresist:OnExplosiveDamage(dmg, attacker)
                    end

                    --V2C: still passing self.inst instead of attacker here, so we don't
                    --     use attacker for calculating damage mods.
                    v.components.combat:GetAttacked(attacker, dmg, nil, nil, spdmg) -- NOTES(JBK): The component combat might remove itself in the GetAttacked callback!
                    if onAttackOther then
                        onAttackOther(attacker, v)
                    end

                    if attacker ~= world and v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) and v:IsValid() then
                        if attacker:IsValid() then
                            v.components.combat:SuggestTarget(attacker)
                        else
                            attacker = nil
                        end
                    end
                end

                v:PushEvent("explosion", { explosive = world })
            end
        end
    end

    world:PushEvent("explosion", { damage = totaldamage })
end

---单位是否可以被恐惧
function FN.CanPanic(target)
    if target.components.hauntable ~= nil and target.components.hauntable.panicable or target.has_nightmare_state then
        return true
    end
end

-- TODO boss的专属恐惧组件epicscare，也许可以研究一下，不过可能没法恐惧boss
---恐惧逻辑代码，来自panic.lua，这里是专门针对没有hauntable组件的单位让其强行逃窜，在onfinish中已经重新启动brain，因此在Cancel任务后不需要手动再调用brain:Start
---@param data {time}
---@return table 返回结束恐惧的Periodic对象
function FN.ForcePanicCreature(inst, data)
    if not (inst and inst.components.locomotor) then return end
    local time = Utils.GetVal(data, "time", 12)

    if inst.brain then
        inst.brain:Stop()
    end

    local t = inst:DoTaskInTime(time, function(ins, task)
        task:Cancel()
    end, inst:DoPeriodicTask(.25 + math.random() * .25, function()
        inst.components.locomotor:RunInDirection(math.random() * 360)
    end, 0))
    t.onfinish = function(task, success, arg)
        -- cancel了也要恢复
        if inst.brain then
            inst.brain:Start()
        end
    end

    return t
end

---恐惧周围单位，来自暗影秘典，默认只有有hauntable组件的生物会被恐惧
---@param targets table 要排除的对象表，键为对象
---@param data {radius, MUST_TAGS, NO_TAGS, ONE_OF_TAGS, panicTime,speedMulKey, speedMul,noPanicTargetFn}
---{半径，必须标签，禁止标签，任意之一标签，恐惧时间，恐惧移速倍率影响的key，被恐惧后的移速倍率，对不能被恐惧对象的处理 返回true就记录targets表中}
function FN.TryTrapTarget(inst, targets, data)
    local TARGET_RADIUS = Utils.GetVal(data, "radius", 6)
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS")
    local NO_TAGS = Utils.GetVal(data, "NO_TAGS",
        { "epic", "notraptrigger", "ghost", "player", "INLIMBO", "flight", "invisible", "notarget" })
    local ONE_OF_TAGS = Utils.GetVal(data, "ONE_OF_TAGS", { "monster", "character", "animal", "smallcreature" })
    local panicTime = Utils.GetVal(data, "panicTime", 12)
    local speedMul = Utils.GetVal(data, "speedMul", 2 / 3)
    local noPanicTargetFn = Utils.GetVal(data, "noPanicTargetFn")
    local validFn = Utils.GetVal(data, "validFn")

    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, TARGET_RADIUS, MUST_TAGS, NO_TAGS, ONE_OF_TAGS)) do
        if not (targets and targets[v])
            and not (v.components.health ~= nil and v.components.health:IsDead())
            and v.entity:IsVisible()
            and (not validFn or validFn(inst, v))
        then
            if FN.CanPanic(v) then
                local speedMulKey = inst.prefab .. v.prefab
                if data then
                    speedMulKey = data.speedMulKey or speedMulKey
                end

                if targets then
                    targets[v] = true
                end

                local x1, y1, z1 = v.Transform:GetWorldPosition()
                local fx = SpawnPrefab("shadow_despawn")
                local platform = v:GetCurrentPlatform()
                if platform ~= nil then
                    fx.entity:SetParent(platform.entity)
                    fx.Transform:SetPosition(platform.entity:WorldToLocalSpace(x1, y1, z1))
                    fx:ListenForEvent("onremove", function()
                        fx.Transform:SetPosition(fx.Transform:GetWorldPosition())
                        fx.entity:SetParent(nil)
                    end, platform)
                else
                    fx.Transform:SetPosition(x1, y1, z1)
                end
                if v.has_nightmare_state then
                    v:PushEvent("ms_forcenightmarestate",
                        { duration = TUNING.SHADOW_TRAP_NIGHTMARE_TIME + math.random() })
                end
                if not (v.sg ~= nil and v.sg:HasStateTag("noattack")) then
                    v:PushEvent("attacked", { attacker = nil, damage = 0 })
                end
                if not v.has_nightmare_state and v.components.hauntable ~= nil and v.components.hauntable.panicable then
                    v.components.hauntable:Panic(panicTime)
                    if v.components.locomotor ~= nil then
                        if v._shadow_trap_task ~= nil then
                            v._shadow_trap_task:Cancel()
                        else
                            v._shadow_trap_fx = SpawnPrefab("shadow_trap_debuff_fx")
                            v._shadow_trap_fx.entity:SetParent(v.entity)
                            v._shadow_trap_fx:OnSetTarget(v)
                        end
                        v._shadow_trap_task = v:DoTaskInTime(panicTime, function(target)
                            target._shadow_trap_task = nil
                            target._shadow_trap_fx:KillFX()
                            target._shadow_trap_fx = nil
                            if target.components.locomotor ~= nil then
                                target.components.locomotor:RemoveExternalSpeedMultiplier(target, speedMulKey)
                            end
                        end)
                        v.components.locomotor:SetExternalSpeedMultiplier(v, speedMulKey, speedMul)
                    end
                end
            else
                --不能被恐惧的
                if noPanicTargetFn and data.noPanicTargetFn(v) then
                    if targets then
                        targets[v] = true
                    end
                end
            end
        end
    end
end

local function UpdateRepel(inst, x, z, creatures, radius)
    local REPEL_RADIUS_SQ = radius * radius
    for i = #creatures, 1, -1 do
        local v = creatures[i]
        if not (v.inst:IsValid() and v.inst.entity:IsVisible()) then
            table.remove(creatures, i)
        elseif v.speed == nil then
            local distsq = v.inst:GetDistanceSqToPoint(x, 0, z)
            if distsq < REPEL_RADIUS_SQ then
                if distsq > 0 then
                    v.inst:ForceFacePoint(x, 0, z)
                end
                local k = .5 * distsq / REPEL_RADIUS_SQ - 1
                v.speed = 25 * k
                v.dspeed = 2
                v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
            end
        else
            v.speed = v.speed + v.dspeed
            if v.speed < 0 then
                local x1, y1, z1 = v.inst.Transform:GetWorldPosition()
                if x1 ~= x or z1 ~= z then
                    v.inst:ForceFacePoint(x, 0, z)
                end
                v.dspeed = v.dspeed + .25
                v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
            else
                v.inst.Physics:ClearMotorVelOverride()
                v.inst.Physics:Stop()
                table.remove(creatures, i)
            end
        end
    end
end

local function TimeoutRepel(inst, creatures, task)
    if task then
        task:Cancel()
    end
    for i, v in ipairs(creatures) do
        if v.speed ~= nil then
            v.inst.Physics:ClearMotorVelOverride()
            v.inst.Physics:Stop()
        end
    end
end

---击退其他单位，来自暗影编织者的护盾特效stalker_shield.lua
---@param data{pos, radius, MUST_TAGS, CANT_TAGS, damage}
function FN.StartRepel(inst, data)
    local pos = Utils.GetVal(data, "pos", inst:GetPosition())
    local radius = Utils.GetVal(data, "radius", 3)
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS", { "locomotor" })
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS", { "fossil", "shadow", "playerghost", "INLIMBO" })
    local damage = Utils.GetVal(data, "damage", 10)

    local creatures = {}
    for i, v in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, radius, MUST_TAGS, CANT_TAGS)) do
        if v:IsValid() and v.entity:IsVisible() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v:HasTag("player") then
                v:PushEvent("repelled", { repeller = inst, radius = radius })
            elseif v.components.combat ~= nil then
                v.components.combat:GetAttacked(inst, damage)
                if v.Physics ~= nil then
                    table.insert(creatures, { inst = v })
                end
            end
        end
    end

    if #creatures > 0 then
        --先开启定时任务，直接把返回值作为参数传入，很简洁的写法
        inst:DoTaskInTime(10 * FRAMES, TimeoutRepel, creatures,
            inst:DoPeriodicTask(0, UpdateRepel, nil, pos.x, pos.z, creatures, radius))
    end
end

---判断是否可以嘲讽对象，来自变大的伯尼bernie_big.lua，默认会嘲讽暗影生物和攻击玩家和玩家盟友的单位
---@param data table {isContainAll, isContainShadowCreature, isContainCompanion}
function FN.IsTauntable(inst, target, data)
    if not (target.components.health ~= nil and target.components.health:IsDead())
        and target.components.combat ~= nil
        and not target.components.combat:TargetIs(inst)
        and target.components.combat:CanTarget(inst) then
        local isContainAll = Utils.GetVal(data, "isContainAll", false)
        local isContainShadowCreature = Utils.GetVal(data, "isContainShadowCreature", true)
        local isContainCompanion = Utils.GetVal(data, "isContainCompanion", true)

        return isContainAll
            or (isContainShadowCreature and target:HasTag("shadowcreature"))
            or (isContainCompanion and target.components.combat:HasTarget() and (target.components.combat.target:HasTag("player") or
                (target.components.combat.target:HasTag("companion") and target.components.combat.target.prefab ~= inst.prefab)))
    end

    return false
end

---嘲讽周围敌人，来自变大的伯尼bernie_big.lua，因此默认会嘲讽暗影生物和攻击玩家和玩家盟友的单位
---@param data table {radius, MUST_TAGS, CANT_TAGS, isTauntable}
function FN.TauntCreatures(inst, data)
    if not inst.components.health:IsDead() then
        local radius = Utils.GetVal(data, "radius", 16)
        local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS", { "_combat", "locomotor" })
        local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS", { "INLIMBO", "player", "companion", "epic", "notaunt" })
        local isTauntable = Utils.GetVal(data, "isTauntable", FN.IsTauntable)

        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, MUST_TAGS, CANT_TAGS)) do
            if isTauntable(inst, v) then
                v.components.combat:SetTarget(inst)
            end
        end
    end
end

---攻击对象检测，这个是用于所有单位的通用检测，对于特殊对象无法处理
function FN.TargetTestForAll(inst, target)
    if not inst.components.combat or not inst.components.combat:CanTarget(target) then
        return false
    end

    local ll = inst.components.follower and inst.components.follower.leader
    local tt = target.components.combat and target.components.combat.target
    local tl = target.components.follower and target.components.follower.leader

    return
        ll ~= target and tl ~= inst                                --非主仆
        and (tt == inst                                            --有仇恨
            or inst:HasTag("monster") ~= target:HasTag("monster")) --类别不同
end

---扇形攻击，来自熊大SGbearger.lua
---@param data table {dist, radius, heavymult, mult, forcelanded, targets, arc, MUST_TAGS, CANT_TAGS, MAX_SIDE_TOSS_STR}
function FN.DoArcAttack(inst, data)
    local dist = Utils.GetVal(data, "dist", 0) --最短攻击距离，小于这个值的敌人打不到
    local radius = Utils.GetVal(data, "radius", 6)
    local heavymult = Utils.GetVal(data, "heavymult", 1)
    local mult = Utils.GetVal(data, "mult", 1)
    local isKnockback = Utils.GetVal(data, "isKnockback")
    local forcelanded = Utils.GetVal(data, "forcelanded")
    local targets = Utils.GetVal(data, "targets")
    local ARC = Utils.GetVal(data, "arc", 90) * DEGREES --degrees to each side
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS", { "_combat" })
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS", { "INLIMBO", "flight", "invisible", "notarget", "noattack" })
    local MAX_SIDE_TOSS_STR = Utils.GetVal(data, "MAX_SIDE_TOSS_STR", 0.8)
    local validfn = Utils.GetVal(data, "validfn")
    local AOE_RANGE_PADDING = 3

    if inst.components.combat then
        inst.components.combat.ignorehitrange = true
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst:GetRotation() * DEGREES
    local x0, z0
    if dist ~= 0 then
        if dist > 0 and ((mult ~= nil and mult > 1) or (heavymult ~= nil and heavymult > 1)) then
            x0, z0 = x, z
        end
        x = x + dist * math.cos(rot)
        z = z - dist * math.sin(rot)
    end
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, MUST_TAGS, CANT_TAGS)) do
        if v ~= inst and not (targets ~= nil and targets[v]) and v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead())
            and (not validfn or validfn(inst, v)) then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC and inst.components.combat:CanTarget(v) then
                inst.components.combat:DoAttack(v)
                if mult ~= nil then
                    local strengthmult = (v.components.inventory ~= nil and v.components.inventory:ArmorHasTag("heavyarmor") or v:HasTag("heavybody")) and
                        heavymult or mult
                    if strengthmult > MAX_SIDE_TOSS_STR and x0 ~= nil then
                        --Don't toss as far to the side for frontal attacks
                        dx = x1 - x0
                        dz = z1 - z0
                        if dx ~= 0 or dz ~= 0 then
                            local rot1 = math.atan2(-dz, dx) + PI
                            local k = math.max(0, math.cos(math.min(PI, DiffAngleRad(rot1, rot) * 2)))
                            strengthmult = MAX_SIDE_TOSS_STR + (strengthmult - MAX_SIDE_TOSS_STR) * k * k
                        end
                    end
                    if isKnockback then
                        v:PushEvent("knockback",
                            {
                                knocker = inst,
                                radius = radius + dist,
                                strengthmult = strengthmult,
                                forcelanded =
                                    forcelanded
                            })
                    end
                end
                if targets ~= nil then
                    targets[v] = true
                end
            end
        end
    end
    if inst.components.combat then
        inst.components.combat.ignorehitrange = false
    end
end

---一个简单的aoe攻击，来自combat的DoAreaAttack，可以攻击指定区域的敌人，而不是玩家所在位置，伤害受武器和伤害倍率影响
---@param inst Entity 攻击对象，需要有combat组件
---@param pos Vector3 攻击位置，必填，如果不需要指定位置可以调用combat的DoAreaAttack
---@param data table|nil 配置项
---@return integer number 被攻击到的单位数量
function FN.DoAOEAttack(inst, pos, data)
    local damage = Utils.GetVal(data, "damage") --直接指明伤害，不再根据武器计算
    local range = Utils.GetVal(data, "range", 4)
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS", { "_combat" })
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS",
        { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" })
    local ONE_OF_TAGS = Utils.GetVal(data, "ONE_OF_TAGS")
    local validfn = Utils.GetVal(data, "validfn")
    local stimuli = Utils.GetVal(data, "stimuli")
    local weapon = Utils.GetVal(data, "weapon")

    if weapon == nil then
        weapon = inst.components.combat:GetWeapon()
    end
    if stimuli == nil then
        if weapon ~= nil and weapon.components.weapon ~= nil and weapon.components.weapon.overridestimulifn ~= nil then
            stimuli = weapon.components.weapon.overridestimulifn(weapon, self.inst, targ)
        end
        if stimuli == nil and inst.components.electricattacks ~= nil then
            stimuli = "electric"
        end
    end

    local hitcount = 0
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, range, MUST_TAGS, CANT_TAGS, ONE_OF_TAGS)
    for _, ent in ipairs(ents) do
        if ent ~= inst and inst.components.combat:IsValidTarget(ent) and
            (validfn == nil or validfn(ent, inst)) then
            inst:PushEvent("onareaattackother", { target = ent, weapon = weapon, stimuli = stimuli })
            local dmg, spdmg = inst.components.combat:CalcDamage(ent, weapon)
            dmg = damage or dmg --位面伤害就不清除了
            ent.components.combat:GetAttacked(inst, dmg, weapon, stimuli, spdmg)
            hitcount = hitcount + 1
        end
    end
    return hitcount
end

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k .. "_workable")
end

local COLLAPSIBLE_WORK_AND_DIG_ACTIONS = shallowcopy(COLLAPSIBLE_WORK_ACTIONS)
local COLLAPSIBLE_DIG_TAGS = shallowcopy(COLLAPSIBLE_TAGS)
COLLAPSIBLE_WORK_AND_DIG_ACTIONS["DIG"] = true
table.insert(COLLAPSIBLE_DIG_TAGS, "pickable")
table.insert(COLLAPSIBLE_DIG_TAGS, "DIG_workable")
local NON_COLLAPSIBLE_TAGS = { "FX", --[["NOCLICK",]] "DECOR", "INLIMBO" }

---范围工作，来自大霜鲨SGsharkboi.lua
---@param inst Entity
---@param dig boolean 是否执行挖掘操作
---@param dist number 与inst位置的距离，用于确定效果区域的中心。
---@param radius number 效果区域的半径。
---@param arc number 效果区域的角度范围，用于确定一个扇形区域。
---@param targets table 一个表，用于记录已经处理过的目标。
function FN.DoAOEWork(inst, dig, dist, radius, arc, targets)
    local actions = dig and COLLAPSIBLE_WORK_AND_DIG_ACTIONS or COLLAPSIBLE_WORK_ACTIONS
    local x, y, z = inst.Transform:GetWorldPosition()
    local arcx, cos_theta, sin_theta
    if dist ~= 0 then
        local theta = inst.Transform:GetRotation() * DEGREES
        cos_theta = math.cos(theta)
        sin_theta = math.sin(theta)
        x = x + dist * cos_theta
        z = z - dist * sin_theta
    end
    if arc then
        if cos_theta == nil then
            local theta = inst.Transform:GetRotation() * DEGREES
            cos_theta = math.cos(theta)
            sin_theta = math.sin(theta)
        end
        --min-x for testing points converted to local space
        arcx = x + math.cos(arc / 2 * DEGREES) * radius
    end
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + 0.5, nil, NON_COLLAPSIBLE_TAGS, dig and COLLAPSIBLE_DIG_TAGS or COLLAPSIBLE_TAGS)) do
        if not (targets and targets[v]) and v:IsValid() and not v:IsInLimbo() then
            local inrange = true
            if arcx then
                --convert to local space x, and test against arcx
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                inrange = x + cos_theta * (x1 - x) - sin_theta * (z1 - z) > arcx
            end
            if inrange then
                local isworkable = false
                if v.components.workable then
                    local work_action = v.components.workable:GetWorkAction()
                    --V2C: nil action for NPC_workable (e.g. campfires)
                    --     allow digging spawners (e.g. rabbithole)
                    isworkable = (
                        (work_action == nil and v:HasTag("NPC_workable")) or
                        (v.components.workable:CanBeWorked() and work_action and actions[work_action.id])
                    )
                end
                if isworkable then
                    v.components.workable:Destroy(inst)
                    if dig and v:IsValid() and v:HasTag("stump") then
                        v:Remove()
                    end
                    if targets then
                        targets[v] = true
                    end
                elseif dig and v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                    if product ~= nil and num > 0 then
                        for i = 1, num do
                            SpawnPrefab(product).Transform:SetPosition(x1, 0, z1)
                        end
                    end
                    if targets then
                        targets[v] = true
                    end
                end
            end
        end
    end
end

---单位缩放动画，Transform缩放
function FN.AnimateScale(inst, total_time, start_scale, end_scale, refresh)
    local task
    local start_time = GetTime()
    task = inst:DoPeriodicTask(refresh ~= nil and refresh or 0.05, function()
        local percent = (GetTime() - start_time) / total_time
        if percent > 1 then
            inst.Transform:SetScale(end_scale, end_scale, end_scale)
            task:Cancel()
            return
        end
        local scale = (1 - percent) * start_scale + percent * end_scale
        inst.Transform:SetScale(scale, scale, scale)
    end)
end

---不同ErodeCB，这个是反转腐蚀的过程，就是一个动画渐出的过程，生成的物体可以先调用inst.AnimState:SetErosionParams(1, 0.1, 1.0)让其隐身，然后调用该函数慢慢浮现
function FN.AntiErodeCB(inst, time, cb)
    local time_to_erode = time or 1
    local tick_time = TheSim:GetTickTime()

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(1 - erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end
        inst.AnimState:SetErosionParams(0, 0, 0)
        if cb ~= nil then
            cb(inst)
        end
    end)
end

---查找附近对inst有仇恨的对象
function FN.FindHostileEntity(inst, data)
    local range = Utils.GetVal(data, "range", 12)
    local checkFn = Utils.GetVal(data, "checkFn")

    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y, z, range)) do
        if v.components.combat and v.components.combat.target == inst and (not checkFn or checkFn(v)) then
            return v
        end
    end
end

--TODO 现在还无法识别地图等其他界面的点击行为，还需要添加施法所需最短距离，我还不知道TheCamera影响的是不是所有玩家的屏幕
---创建指示器，来自reticule.lua，可以鼠标指向，也可角色朝向决定，由鼠标点击触发，目标位置鼠标点击位置
---注意该方法客机调用，一般需要在executeFn中发送rpc，把坐标发给主机处理
---@param data table {reticulePrefab, pingPrefab, mouseEnabled, reticuleFollowMouse, isRight, mouseTargetFn, targetFn, spellMinDis}
---@return function endFn 结束函数
function FN.CreateAoeTargeting(inst, executeFn, data)
    --虽然我很想用已有组件，但是指示器显示条件诸多，代码也复杂，aoetargeting就要求是被玩家持有的装备才行
    --r:AddComponent("aoetargeting")

    local reticulePrefab = Utils.GetVal(data, "reticulePrefab", "reticule")      --跟随鼠标移动的指示器
    local pingPrefab = Utils.GetVal(data, "pingPrefab")                          --鼠标点击后指示器动画
    local mouseEnabled = Utils.GetVal(data, "mouseEnabled", false)
    local reticuleFollowMouse = Utils.GetVal(data, "reticuleFollowMouse", false) --指示器是否跟随鼠标移动
    local reticuleRotate = Utils.GetVal(data, "reticuleRotate", true)            --指示器是否旋转
    local isRight = Utils.GetVal(data, "isRight")                                --是否右键触发
    local mouseTargetFn = Utils.GetVal(data, "mouseTargetFn")                    --根据鼠标位置决定目标位置
    local targetFn = Utils.GetVal(data, "targetFn")                              --非鼠标时返回目标位置
    local spellMinDisSq = Utils.GetVal(data, "spellMinDis")                      --施法所需最短距离
    if spellMinDisSq ~= nil then
        spellMinDisSq = spellMinDisSq * spellMinDisSq
    else
        spellMinDisSq = math.huge
    end

    local targetpos
    local r = SpawnPrefab(reticulePrefab)

    local function UpdateRotate()
        if reticuleRotate then
            r:ForceFacePoint(targetpos:Get())
        end
    end
    local UpdatePosition = function(dt)
        if reticuleFollowMouse then
            r.Transform:SetPosition(targetpos:Get())
        else
            r.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
    local endFn = function()
        if r.followhandler ~= nil then
            r.followhandler:Remove()
            r.followhandler = nil
        end
        if r.mouseButtonHandler ~= nil then
            r.mouseButtonHandler:Remove()
            r.mouseButtonHandler = nil
        end
        TheCamera:RemoveListener(r, UpdatePosition)
        r:Remove()
    end

    local function clickFn(button, down, x, y)
        if (isRight and button == MOUSEBUTTON_RIGHT or button == MOUSEBUTTON_LEFT) and down then
            -- 检测距离是否足够
            local disSq = inst:GetDistanceSqToPoint(targetpos:Get())
            if disSq >= spellMinDisSq then
                local pos = inst:GetPosition()
                local dx, dz = targetpos.x - pos.x, targetpos.z - pos.z
                local dis, minDis = math.sqrt(disSq), math.sqrt(spellMinDisSq)
                local posOff = Vector3(dx / dis * minDis, 0, dz / dis * minDis)
                -- TOODO 让角色一直走到施法位置再施法，这个方法不行，走走停停的，参考源码
                inst.components.locomotor:GoToPoint(pos + posOff, nil, true)
                -- inst.components.locomotor:RunInDirection(inst:GetRotation()) --这个会一直跑
            else
                if pingPrefab then
                    FN.GetPrefab(pingPrefab, { pos = r:GetPosition(), rotation = r.Transform:GetRotation() })
                end
                executeFn(targetpos)
            end
        end
        endFn()
    end

    if mouseEnabled and not TheInput:ControllerAttached() then
        r.followhandler = TheInput:AddMoveHandler(function(x, y)
            local x1, y1, z1 = TheSim:ProjectScreenPos(x, y)
            local pos = x1 ~= nil and y1 ~= nil and z1 ~= nil and Vector3(x1, y1, z1) or nil
            if mouseTargetFn ~= nil then
                targetpos = mouseTargetFn(self.inst, pos)
            else
                targetpos = pos
            end
            UpdateRotate()
        end)
        local pos = TheInput:GetWorldPosition()
        if mouseTargetFn ~= nil then
            targetpos = mouseTargetFn(self.inst, pos)
        else
            targetpos = pos
        end
    else
        if targetFn ~= nil then
            targetpos = targetFn(self.inst)
        end
    end
    UpdatePosition()
    UpdateRotate()
    --DoPeriodicTask都没这个平滑
    TheCamera:AddListener(r, UpdatePosition)
    r.mouseButtonHandler = TheInput:AddMouseButtonHandler(clickFn);

    return endFn
end

---屏幕调色和摄像头抖动，来自天体的特效moonpulse.lua
--local function StartMoonPulsePostFX()
--    PostProcessor:EnablePostProcessEffect(PostProcessorEffects.MoonPulse, true);
--    PostProcessor:EnablePostProcessEffect(PostProcessorEffects.MoonPulseGrading, true);
--    PostProcessor:SetMoonPulseParams(0, 0, 0, 0);
--    PostProcessor:SetMoonPulseGradingParams(0, 0, 0, 0);
--    local cur = GetTimeReal();
--    ThePlayer:DoTaskInTime(4, function(inst, task)
--        task:Cancel();
--        PostProcessor:EnablePostProcessEffect(PostProcessorEffects.MoonPulse, false);
--        PostProcessor:EnablePostProcessEffect(PostProcessorEffects.MoonPulseGrading, false);
--    end, ThePlayer:DoPeriodicTask(0.1, function(inst)
--        local r = (GetTimeReal() - cur) / 1000 / 4;
--        PostProcessor:SetMoonPulseParams(0, 0, r, r);
--        PostProcessor:SetMoonPulseGradingParams(0, 0, r, r);
--    end));
--end

------------------------------------------------------------------------------------------------------

---创建光源预制体heatrocklight
---@param data table|nil {radius, falloff, intensity, colour, enable}
function FN.GetHeatRockLight(data)
    local fx = SpawnPrefab("heatrocklight")
    if data then
        if data.radius then
            fx.Light:SetRadius(data.radius)
        end
        if data.falloff then
            fx.Light:SetFalloff(data.falloff)
        end
        if data.intensity then
            fx.Light:SetIntensity(data.intensity)
        end
        if data.colour then
            fx.Light:SetColour(unpack(data.colour))
        end
        if data.enable then
            fx.Light:Enable(data.enable)
        end
    end

    return fx
end

-- shadow_pillar的禁锢时长计算
local function CalcTargetDuration(target)
    return target ~= nil and (
        (target:HasTag("epic") and TUNING.SHADOW_PILLAR_DURATION_BOSS) or
        (target:HasTag("player") and TUNING.SHADOW_PILLAR_DURATION_PLAYER)
    ) or TUNING.SHADOW_PILLAR_DURATION
end

---禁锢敌人（没有特效），来自暗影秘典的禁锢技能shadow_pillar.lua，困住 24 秒无法移动。其中Boss生物只会被困 12 秒，（开启pvp下的）玩家被困 6 秒
---@param data table|nil {time}
---@return duration number 单位的实际禁锢时长
function FN.ImprisonTarget(target, data)
    local time = Utils.GetVal(data, "time") --延长禁锢时间

    local padding = (target:HasTag("epic") and 1) or (target:HasTag("smallcreature") and 0) or .75
    local radius = math.max(1, target:GetPhysicsRadius(0) + padding) --这个只是用来让屏幕抖动的
    local platform = target:GetCurrentPlatform()
    local x, y, z = target.Transform:GetWorldPosition()
    if time == nil then
        local circ = PI2 * radius
        local num = math.floor(circ / 1.4 + .5) --原本是计算柱子的数量，这里用不到
        local period = 1 / num
        time = (num - 1) * period
    end

    local ent = SpawnPrefab("shadow_pillar_target") --不可见实体，但是有禁锢效果
    ent.Transform:SetPosition(x, 0, z)
    ent:SetDelay(time)                              --this just extends lifetime, spell still takes effect right away
    ent:SetTarget(target, radius, platform ~= nil)
    return CalcTargetDuration(target)
end

---单位潮湿函数，具有灭火、降温、添加潮湿功能，来自wateryprotection.lua
---@param target Entity
---@param data table|nil {witherprotectiontime, extinguishheatpercent, addcoldness, temperaturereduction, addwetness}
function FN.MakeExtinguishAndCool(target, data)
    local witherprotectiontime = Utils.GetVal(data, "witherprotectiontime", 0)   --植物枯萎
    local extinguishheatpercent = Utils.GetVal(data, "extinguishheatpercent", 0) --灭火
    local addcoldness = Utils.GetVal(data, "addcoldness", 0)                     --冻结
    local temperaturereduction = Utils.GetVal(data, "temperaturereduction", 0)   --降温
    local addwetness = Utils.GetVal(data, "addwetness", 0)                       --潮湿度
    local applywetnesstoitems = Utils.GetVal(data, "applywetnesstoitems")        --是否允许物品潮湿

    if target.components.burnable ~= nil then
        if witherprotectiontime > 0 and target.components.witherable ~= nil then
            target.components.witherable:Protect(witherprotectiontime)
        end
        if extinguishheatpercent then
            if target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering() then
                target.components.burnable:Extinguish(true, extinguishheatpercent)
            end
        end
    end
    if addcoldness > 0 and target.components.freezable ~= nil then
        target.components.freezable:AddColdness(addcoldness)
    end
    if temperaturereduction > 0 and target.components.temperature ~= nil then
        target.components.temperature:SetTemperature(target.components.temperature:GetCurrent() - temperaturereduction)
    end
    if addwetness > 0 then
        if target.components.moisture ~= nil then
            local waterproofness = target.components.moisture:GetWaterproofness()
            target.components.moisture:DoDelta(addwetness * (1 - waterproofness))
        elseif applywetnesstoitems and target.components.inventoryitem ~= nil then
            target.components.inventoryitem:AddMoisture(addwetness)
        end
    end
end

---潮湿函数，具有灭火、降温、添加潮湿、农田浇水功能，来自wateryprotection.lua
---@param pos Vector3
---@param data table|nil {range, MUST_TAGS, CANT_TAGS, witherprotectiontime, extinguishheatpercent, addcoldness, temperaturereduction, addwetness, onspreadprotectionfn}
function FN.ExtinguishAndCoolEntities(pos, data)
    local range = Utils.GetVal(data, "range", 4)
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS")
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS", { "FX", "DECOR", "INLIMBO", "burnt" })
    local addwetness = Utils.GetVal(data, "addwetness", 0)
    local onspreadprotectionfn = Utils.GetVal(data, "onspreadprotectionfn")

    for _, v in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, range, MUST_TAGS, CANT_TAGS)) do
        FN.MakeExtinguishAndCool(v, data)

        if onspreadprotectionfn then
            onspreadprotectionfn(v)
        end
    end

    if addwetness and TheWorld.components.farming_manager ~= nil then
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(pos.x, pos.y, pos.z, addwetness)
    end
end

---向目标发射物品或是直接给予目标物品，基于LaunchAt
---@param prefab Entity|string 要发射的对象或预制体名
---@param launcher Entity 发射源
---@param data table|nil
function FN.ReturnMaterial(prefab, launcher, data)
    local count = Utils.GetVal(data, "count", 1)                      --数量
    local isStack = Utils.GetVal(data, "isStack")                     --是否堆叠成一个物品发射
    local target = Utils.GetVal(data, "target")                       --目标
    local isGiveTarget = Utils.GetVal(data, "isGiveTarget")           --是否取消发射，直接给予目标
    local speedmult = Utils.GetVal(data, "speedmult")                 --速度
    local startheight = Utils.GetVal(data, "startheight")             --初始高度
    local startradius = Utils.GetVal(data, "startradius")             --初始半径
    local randomangleoffset = Utils.GetVal(data, "randomangleoffset") --发射角

    local name, drop
    if type(prefab) == "string" then
        name = prefab
        drop = SpawnPrefab(name)
    else
        name = prefab.prefab --不做检验
        drop = prefab
    end

    assert(name and drop, "Make sure the prefab is entity or prefab name")

    local inventory = target and target.components.inventory
    isGiveTarget = isGiveTarget and inventory ~= nil
    local drops = {}
    table.insert(drops, drop)
    if (isStack or isGiveTarget) and drop.components.stackable then
        local maxsize = drop.components.stackable.maxsize
        drop.components.stackable:SetStackSize(math.min(count, maxsize))
        count = count - maxsize

        while count > 0 do
            drop = SpawnPrefab(name)
            drop.components.stackable:SetStackSize(math.min(count, maxsize))
            table.insert(drops, drop)
            count = count - maxsize
        end
    else
        for i = 1, count - 1 do
            table.insert(drops, SpawnPrefab(name))
        end
    end

    for _, v in ipairs(drops) do
        if isGiveTarget and target then
            target.components.inventory:GiveItem(v)
        else
            LaunchAt(v, launcher, target, speedmult, startheight, startradius, randomangleoffset)
        end
    end
end

local SLOWDOWN_MUST_TAGS = { "locomotor" }
local SLOWDOWN_CANT_TAGS = { "player", "flying", "playerghost", "INLIMBO" }
local function SlowDownOnUpdate(inst, x, y, z, radius, speedPenalty)
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, SLOWDOWN_MUST_TAGS, SLOWDOWN_CANT_TAGS)) do
        local is_follower = v.components.follower ~= nil and v.components.follower.leader ~= nil and
            v.components.follower.leader:HasTag("player")
        if v.components.locomotor ~= nil and not is_follower then
            v.components.locomotor:PushTempGroundSpeedMultiplier(speedPenalty, WORLD_TILES.MUD)
        end
    end
end

---减速周围单位，来自克服蛛形纲恐惧症book_web_ground，逻辑也可用于加速
---@param inst Entity 任务执行者
---@param data  table|nil
---@return task Task
function FN.SlowDownEntities(inst, data)
    local pos = Utils.GetVal(data, "pos", inst:GetPosition()) --减速位置
    local radius = Utils.GetVal(data, "radius", 6)            --半径
    local time = Utils.GetVal(data, "time")                   --持续时间，默认为nil，即一直进行
    local speedPenalty = Utils.GetVal(data, "speedPenalty", 0.25)

    local task = inst:DoPeriodicTask(0, SlowDownOnUpdate, nil, pos.x, pos.y, pos.z, radius, speedPenalty)
    SlowDownOnUpdate(inst, pos.x, pos.y, pos.z, radius, speedPenalty)
    if time then
        inst:DoTaskInTime(time, function() task:Cancel() end)
    end

    return task
end

---荆棘护甲的反伤特效
function FN.SpawnBrambleFx(owner, data)
    local damage = Utils.GetVal(data, "damage")               --伤害，默认22.6
    local range = Utils.GetVal(data, "range")                 --攻击范围，默认.75
    local ignore = Utils.GetVal(data, "ignore")               --攻击忽视对象，要求为一个对象组成的表，owner默认加入该表
    local canhitplayers = Utils.GetVal(data, "canhitplayers") --是否可以攻击玩家，默认攻击玩家，如果owner是玩家并且是非PVP模式下则不攻击玩家

    local ar = SpawnPrefab("bramblefx_armor")
    ar:SetFXOwner(owner)

    ar.damage = damage or ar.damage
    ar.range = range or ar.range
    if canhitplayers ~= nil then ar.canhitplayers = canhitplayers end

    if ignore then
        for _, v in ipairs(ignore) do
            ar.ignore[v] = true
        end
    end
    return ar
end

---装备耐久为0不消失，使装备可用材料填充耐久，来自standardcomponents.lua，不过我不想添加forgerepairable组件，顺便兼容perishable
function FN.MakeForgeRepairable(inst, material, onbroken, onrepaired)
    local function _onbroken(inst)
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem.owner
            if owner ~= nil and owner.components.inventory ~= nil then
                local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
                if item ~= nil then
                    owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
                end
            end
        end

        -- 腐烂后这个剩余时间可能是一个负数
        if inst.components.perishable then
            inst.components.perishable.perishremainingtime = 0
        end

        if onbroken ~= nil then
            onbroken(inst)
        end
    end

    --V2C: asserts to prevent overwriting callbacks already setup by the prefab

    if inst.components.armor ~= nil then
        assert(not (DEBUG_MODE and inst.components.armor.onfinished ~= nil))
        inst.components.armor:SetKeepOnFinished(true)
        inst.components.armor:SetOnFinished(_onbroken)
    elseif inst.components.finiteuses ~= nil then
        assert(not (DEBUG_MODE and inst.components.finiteuses.onfinished ~= nil))
        inst.components.finiteuses:SetOnFinished(_onbroken)
    elseif inst.components.fueled ~= nil then
        assert(not (DEBUG_MODE and inst.components.fueled.depleted ~= nil))
        inst.components.fueled:SetDepletedFn(_onbroken)
    elseif inst.components.perishable ~= nil then
        inst.components.perishable.onperishreplacement = nil --不会生成腐烂物
        inst.components.perishable:SetOnPerishFn(_onbroken)
    end

    if material then
        inst:AddComponent("forgerepairable")
        inst.components.forgerepairable:SetRepairMaterial(material)
        inst.components.forgerepairable:SetOnRepaired(onrepaired)
    end
end

local function onhammered(inst)
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

---设置无掉落物
function FN.SetNoLoot(inst, isSetWorkable)
    if isSetWorkable and inst.components.workable then
        inst.components.workable:SetOnFinishCallback(onhammered)
    end
    if inst.components.lootdropper then
        inst.components.lootdropper:SetLoot(nil)
        inst.components.lootdropper:SetChanceLootTable(nil)
    end
end

local function RemoveListener(t, event, inst, fn)
    if t then
        local listeners = t[event]
        if listeners then
            local listener_fns = listeners[inst]
            if listener_fns then
                if type(fn) == "function" then -- 执行原方法
                    RemoveByValue(listener_fns, fn)
                    if next(listener_fns) == nil then
                        listeners[inst] = nil
                    end
                else
                    listeners[inst] = nil --移除对该事件的所有监听回调
                end
            end
            if next(listeners) == nil then
                t[event] = nil
            end
        end
    end
end

---在原RemoveEventCallback基础上做一些加强：
---1. 如果不指定fn，则移除对监听源的该事件的所有监听回调
function FN.RemoveEventCallback(inst, event, fn, source)
    source = source or inst

    RemoveListener(source.event_listeners, event, inst, fn)
    RemoveListener(inst.event_listening, event, source, fn)
end

--- 获取指定对象的指定事件的所有回调函数
function FN.GetAllCallbackByName(inst, name)
    local callbacks = {}

    if inst.event_listeners then
        for ins, fns in pairs(inst.event_listeners[name]) do
            ConcatArrays(callbacks, fns)
        end
    end

    return callbacks
end

--- 修改指定对象的指定事件的所有监听回调函数
function FN.UpdateAllCallbackByName(inst, name, getCallbackFn)
    local cbs = inst.event_listeners and inst.event_listeners[name]
    for ins, fns in pairs(cbs or {}) do
        cbs[ins] = getCallbackFn(ins, fns)
    end
end

local function DefaultCheckFn(v)
    return not (v.components.locomotor or (v.components.inventoryitem and not v:HasTag("heavy")))
end

local TITLE_CHECK_CANT_TAGS = { "FX" }
local function CheckPlacePos(spawnPos, entRadius, checkFn)
    if TheWorld.Map:IsAboveGroundAtPoint(spawnPos:Get()) then
        for _, v in ipairs(TheSim:FindEntities(spawnPos.x, spawnPos.y, spawnPos.z, entRadius, nil, TITLE_CHECK_CANT_TAGS)) do
            if not checkFn(v) then
                return false
            end
        end
        return true
    end
    return false
end


---查找给定位置附近可放置的位置，首先以给定点为圆心查找firstCount次，如果找到就返回，如果找不到就矩形范围从上往下、从左往右查找
---@param pos Vector3 查找中心
---@param minDis number 圆的最小半径或矩形的最小半长
---@param maxDis number 圆的最大半径或矩形的最大半长
---@param entRadius number|nil 预制体需要的半径，一般是物理半径，默认0.5
---@param firstCount number|nil 绕圆心查找的次数，默认5次
---@param checkFn function|nil 校验函数，如果新位置有其他对象，对其进行检验，如果为false则表示该点不行，默认是禁止存在没有移动组件或重物品
function FN.FindPlaceablePos(pos, minDis, maxDis, entRadius, firstCount, checkFn)
    assert(maxDis > 0 and (not entRadius or entRadius > 0), "maxDis > 0 and (not entRadius or entRadius > 0)")

    entRadius = entRadius or 0.5
    firstCount = firstCount or 5
    checkFn = checkFn or DefaultCheckFn

    local spawnPos
    -- 先随机
    for _ = 1, firstCount do
        spawnPos = Shapes.GetRandomLocation(pos, minDis, maxDis)
        if CheckPlacePos(spawnPos, entRadius, checkFn) then
            return spawnPos
        end
    end

    -- 矩形搜索，比较简单的方式，从左上角开始查找，就不判断障碍物的最大X和Z了

    local minX, minZ = pos.x - maxDis, pos.z - maxDis
    local maxX, maxZ = pos.x + maxDis, pos.z + maxDis
    local curX, curZ = minX, minZ
    while true do
        spawnPos = Vector3(curX, 0, curZ) + pos
        if CheckPlacePos(spawnPos, entRadius, checkFn) then
            return spawnPos
        end

        curX = curX + entRadius * 2
        if curX > maxX then
            curX = minX
            curZ = curZ + entRadius * 2
        end
        if curZ > maxZ then
            return
        end
    end
end

---切斯特眼骨在附近生成切斯特的逻辑代码，使用了FindWalkableOffset
function FN.GetSpawnPoint(pos, radius, attempts)
    radius = radius or 30
    attempts = attempts and attempts / 2 or 6 --对半分

    local theta = math.random() * 2 * PI
    local offset = FindWalkableOffset(pos, theta, radius, attempts, true)
    if not offset then
        --每次失败后取对角会好点
        offset = FindWalkableOffset(pos, ReduceAngleRad(theta + PI), radius, attempts, true)
    end

    return offset ~= nil and (pos + offset) or nil
end

---以所给位置所在地皮为圆心，更换一片圆形区域的地皮
---@param pos Vector3 作为圆心的位置，不需要是地皮中心
---@param radius number 半径，以地皮为单位
---@param tile number 要更换的地皮
---@param isContainOcean boolean|nil 是否把海洋也换成指定地皮
---@param edgeRandom number|nil 边缘随机性，在边缘位置多换一块的概率，这里只会多换，不会少换
function FN.SpawnRoundTile(pos, radius, tile, isContainOcean, edgeRandom)
    edgeRandom = edgeRandom or 0

    local x, z = TheWorld.Map:GetTileCoordsAtPoint(pos:Get())
    local baseX = x - radius - 1
    local baseZ = z - radius - 1

    local disSq = radius * radius
    local disSq2 = (radius + 1) * (radius + 1)
    local len = radius * 2 + 1
    for i = 1, len do
        local newX = baseX + i
        for j = 1, len do
            local newZ = baseZ + j
            if isContainOcean or TileGroupManager:IsLandTile(TheWorld.Map:GetTile(newX, newZ)) then
                local sq = VecUtil_DistSq(newX, newZ, x, z)
                if sq <= disSq or (edgeRandom ~= 0 and sq <= disSq2 and math.random() < edgeRandom) then
                    TheWorld.Map:SetTile(newX, newZ, tile)
                end
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
---遗忘entitytracker记录的所有实体
function FN.EntityTrackerForgetAllEntity(self)
    for name, _ in pairs(self.entities) do
        self:ForgetEntity(name)
    end
end

--- 获取指定位置耕地地皮的湿度
local _overlaygrid, _moisturegrid
function FN.FarmingManagerGetMoisture(x, y, z)
    if not TheWorld.components.farming_manager then
        return 0
    end
    if not _overlaygrid then
        _overlaygrid = Utils.ChainFindUpvalue(TheWorld.components.farming_manager.GetDebugString, "_overlaygrid")
        _moisturegrid = Utils.ChainFindUpvalue(TheWorld.components.farming_manager.GetDebugString, "_moisturegrid")
    end
    -- 这里我不会判断是否读取到了，如果失败说明该更新代码了

    local index = _overlaygrid:GetIndex(TheWorld.Map:GetTileCoordsAtPoint(x, y, z))
    local nutrients_overlay = _overlaygrid:GetDataAtIndex(index) --if the tile is not used for farming then there is no need to track the moisture

    return nutrients_overlay and _moisturegrid:GetDataAtIndex(index) or 0
end

--- 获取指定位置耕地地皮的营养值
function FN.FarmingManagerGetNutrients(x, y, z)
    if not TheWorld.components.farming_manager then
        return 0, 0, 0
    end

    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    return TheWorld.components.farming_manager:GetTileNutrients(tile_x, tile_z)
end

--- 获取两个对象之间默认的行动距离
---@param doer Entity
---@param target Entity|nil
function FN.GetActionRadius(doer, target)
    return .5 + (doer and doer:GetPhysicsRadius(0) or 0) + (target and target:GetPhysicsRadius(0) or 0)
end

----------------------------------------------------------------------------------------------------
local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

---模拟父单位生成子的单位，设置子单位的坐标，来自猪人房生成猪人的逻辑
function FN.ReleaseChild(child, parent, data)
    local overridespawnlocation = Utils.GetVal(data, "overridespawnlocation")
    local spawnInWater = Utils.GetVal(data, "spawnInWater", false)
    local spawnOnBoats = Utils.GetVal(data, "spawnOnBoats", false)

    local x, y, z = parent.Transform:GetWorldPosition()
    y = 0

    if overridespawnlocation then
        x, y, z = overridespawnlocation(parent)
    else
        local rad = .5 + parent:GetPhysicsRadius(0) + child:GetPhysicsRadius(0)
        local start_angle = math.random() * 2 * PI

        local offset = FindWalkableOffset(Vector3(x, 0, z), start_angle, rad, 8, false, true, NoHoles, spawnInWater,
            spawnOnBoats)
        if offset == nil then
            -- well it's gotta go somewhere!
            x = x + rad * math.cos(start_angle)
            z = z - rad * math.sin(start_angle)
        else
            x = x + offset.x
            z = z + offset.z
        end
    end
    if child.Physics ~= nil then
        child.Physics:Teleport(x, y, z)
    else
        child.Transform:SetPosition(x, y, z)
    end
end

---杀死该单位
function FN.DefaultKill(inst, isContainFollower)
    if not inst:IsValid()
        or (inst.components.health and inst.components.health:IsDead()) then
        return
    end

    if isContainFollower and inst.components.leader then
        for k, _ in pairs(self.followers) do
            FN.Kill(k)
        end
    end

    if inst.entity:IsVisible() then
        if inst.components.health then
            inst.components.health:Kill()
        else
            SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:Remove()
        end
    else
        inst:Remove()
    end
end

function FN.SetPosition(inst, x, y, z)
    if type(x) == "table" then
        x, y, z = x:Get()
    end

    if inst.Physics ~= nil then
        inst.Physics:Teleport(x, y, z)
    else
        inst.Transform:SetPosition(x, y, z)
    end
end

local function FollowerSort(a, b)
    -- Better than bubble!
    local ap = a.components.follower:GetLoyaltyPercent()
    local bp = b.components.follower:GetLoyaltyPercent()
    if ap == bp then
        return a.GUID < b.GUID
    end
    return ap < bp
end

---根据优先级获取周围其他生物，用于一个道具同时雇佣多个生物，参考沃特雇佣鱼人逻辑
---@param inst Entity
---@param data data|nil {radius,maxcount,MUST_TAGS,CANT_TAGS,ONE_OF_TAGS,checkFN}
function FN.GetOtherEnts(inst, data)
    local radius = Utils.GetVal(data, "radius", 16)        --雇佣范围
    local maxcount = Utils.GetVal(data, "maxcount", 6) - 1 --雇佣的最多数量，不用考虑已经inst，函数中会减一
    local MUST_TAGS = Utils.GetVal(data, "MUST_TAGS")
    local CANT_TAGS = Utils.GetVal(data, "CANT_TAGS")
    local ONE_OF_TAGS = Utils.GetVal(data, "ONE_OF_TAGS")
    local checkFn = Utils.GetVal(data, "checkFn")

    local ents_highpriority = {}
    local ents_lowpriority = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, ent in ipairs(TheSim:FindEntities(x, y, z, radius, MUST_TAGS, CANT_TAGS, ONE_OF_TAGS)) do
        if ent ~= inst and not ent.components.health:IsDead() and (not checkFn or checkFn(inst, ent)) then
            local follower = ent.components.follower
            if follower then
                -- No leader or about to lose loyalty is high priority.
                if follower.leader == nil or follower:GetLoyaltyPercent() < TUNING.MERM_LOW_LOYALTY_WARNING_PERCENT then
                    table.insert(ents_highpriority, ent)
                else
                    table.insert(ents_lowpriority, ent)
                end
            end
        end
    end

    table.sort(ents_highpriority, FollowerSort)
    table.sort(ents_lowpriority, FollowerSort)

    local ents_valid = {}
    local ents_count = 0
    for _, hound in ipairs(ents_highpriority) do
        if ents_count >= maxcount then
            break
        end
        ents_count = ents_count + 1
        table.insert(ents_valid, hound)
    end
    if ents_count < maxcount then
        for _, hound in ipairs(ents_lowpriority) do
            if ents_count >= maxcount then
                break
            end
            ents_count = ents_count + 1
            table.insert(ents_valid, hound)
        end
    end

    return ents_valid
end

----------------------------------------------------------------------------------------------------
local function IsDefenceEquip(inst)
    return inst.components.equippable
        and (inst.components.armor or inst.components.planardefense)
end

local CHECK_ITEM_FN = {}

-- 手持
CHECK_ITEM_FN.hands = function(inst)
    return inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS
end
-- 头部
CHECK_ITEM_FN.head = function(inst)
    return inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HEAD
end
-- 武器
CHECK_ITEM_FN.weapon = function(inst)
    return inst.components.weapon
end
-- 护甲
CHECK_ITEM_FN.armor = function(inst)
    return IsDefenceEquip(inst) and inst.components.equippable.equipslot == EQUIPSLOTS.BODY
end
-- 头盔
CHECK_ITEM_FN.helmet = function(inst)
    return IsDefenceEquip(inst) and inst.components.equippable.equipslot == EQUIPSLOTS.HEAD
end
-- 可食用
CHECK_ITEM_FN.canEat = function(inst, doer)
    return doer.components.eater and doer.components.eater:CanEat(inst)
end
CHECK_ITEM_FN.canEatNotHealth = function(inst, doer)
    return CHECK_ITEM_FN.canEat(inst, doer) and inst.components.edible:GetHealth(doer) <= 0
end
-- healer回血组件
CHECK_ITEM_FN.healer = function(inst)
    return inst.components.healer
end
-- 可回血，包含回血组件和料理
CHECK_ITEM_FN.heal = function(inst, doer)
    return CHECK_ITEM_FN.healer(inst) or
        (CHECK_ITEM_FN.canEat(inst, doer) and inst.components.edible:GetHealth(doer) > 0)
end


---获取容器中指定类型的物品
---@param inst Entity 容器
---@param type string 物品类型
---@param isRemove boolean|nil 是否从容器中取出物品
---@return Entity|nil item 物品
---@return integer|nil index 物品所在容器的槽
function FN.GetContainerFirstItemByType(inst, type, isRemove, wholestack)
    local self = inst.components.container
    local checkFn = CHECK_ITEM_FN[type]
    if not self or not checkFn then return end

    for i = 1, self.numslots do
        local item = self.slots[i]
        if item ~= nil and checkFn(item, inst) then
            if isRemove then
                if not item.components.stackable or wholestack then
                    return self:RemoveItemBySlot(i)
                else
                    return self:RemoveItem(item, false)
                end
            else
                return item, i
            end
        end
    end
end

function FN.GetAllContainerItem(inst, type, isRemove)
    local items = {}
    local self = inst.components.container
    local checkFn = CHECK_ITEM_FN[type]
    if not self or not checkFn then return end

    for i = 1, self.numslots do
        local item = self.slots[i]
        if item ~= nil and item:IsValid() and checkFn(item, inst) then
            if isRemove then
                table.insert(items, self:RemoveItemBySlot(i))
            else
                table.insert(items, { item, i })
            end
        end
    end
    return items
end

--- 提高血量上限，血量百分比不变
function FN.SetMaxHealth(inst, maxHealth)
    local health = inst.components.health
    local per = health:GetPercent()
    health.maxhealth = maxHealth
    if health.currenthealth > 0 then --玩家有可能死亡
        health.currenthealth = per * maxHealth
    end
    health:ForceUpdateHUD(true) --handles capping health at max with penalty
end

--- 获取一个
function FN.GetOne(inst)
    return inst.components.stackable and inst.components.stackable:Get() or inst
end

---spawner组件刚开始不会主动生成child，需要手动生成一下
function FN.SpawnerInitSpawnChild(inst)
    if inst.components.spawner.child == nil
        and not inst.components.spawner:IsSpawnPending() then
        local child = SpawnPrefab(inst.components.spawner.childname)
        if child ~= nil then
            inst.components.spawner:TakeOwnership(child)
            inst.components.spawner:GoHome(child)
            inst.components.spawner:ReleaseChild()
        end
    end
end

---spawner组件生成的子单位离开加载范围时直接回家，建议放在entitysleep监听回调中处理
---@param inst any
---@param maxDis any
---@param checkFn any
function FN.EntitySleepGoHome(inst, maxDis, checkFn)
    maxDis = maxDis or 20
    local disSq = maxDis * maxDis

    local home = inst.components.homeseeker and inst.components.homeseeker:GetHome()
    if not home                                                           --必须有家
        or home.components.spawner:IsOccupied()
        or (inst.components.follower and inst.components.follower.leader) --必须没有leader
        or inst:GetDistanceSqToInst(home) <= disSq                        --必须在允许范围外
        or (checkFn and not checkFn(inst, home))
    then
        return
    end

    home.components.spawner:GoHome(inst)
    home.components.spawner:ReleaseChild()
end

--- 生成简单特效并移除对象
function FN.FxAndRemove(inst, material, isBig)
    local fx = SpawnPrefab(isBig and "collapse_big" or "collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial(material or "wood")
    inst:Remove()
end

--- 获取容器中从前往后的第一个物品
function FN.GetContainerFirstItem(self)
    for i = 1, self.numslots do
        if self.slots[i] then
            return self.slots[i]
        end
    end
end

local function CheckSpawnedLoot(loot)
    if loot.components.inventoryitem ~= nil then
        loot.components.inventoryitem:TryToSink()
    else
        local lootx, looty, lootz = loot.Transform:GetWorldPosition()
        if ShouldEntitySink(loot, true) or TheWorld.Map:IsPointNearHole(Vector3(lootx, 0, lootz)) then
            SinkEntity(loot)
        end
    end
end

--- 分解法杖生成分解物逻辑
function FN.SpawnLootPrefab(inst, lootprefab)
    if lootprefab == nil then return end

    local loot = SpawnPrefab(lootprefab)
    if loot == nil then return end

    local x, y, z = inst.Transform:GetWorldPosition()

    if loot.Physics ~= nil then
        local angle = math.random() * 2 * PI
        loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))

        if inst.Physics ~= nil then
            local len = loot:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0)
            x = x + math.cos(angle) * len
            z = z + math.sin(angle) * len
        end

        loot:DoTaskInTime(1, CheckSpawnedLoot)
    end

    loot.Transform:SetPosition(x, y, z)
    loot:PushEvent("on_loot_dropped", { dropper = inst })

    return loot
end

--- 卸下一个对象的所有东西，来自分解魔杖
function FN.DischargePrefab(target)
    if target.components.inventory ~= nil then
        target.components.inventory:DropEverything()
    end

    if target.components.container ~= nil then
        target.components.container:DropEverything()
    end

    if target.components.spawner ~= nil and target.components.spawner:IsOccupied() then
        target.components.spawner:ReleaseChild()
    end

    if target.components.occupiable ~= nil and target.components.occupiable:IsOccupied() then
        local item = target.components.occupiable:Harvest()
        if item ~= nil then
            item.Transform:SetPosition(target.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped()
        end
    end

    if target.components.trap ~= nil then
        target.components.trap:Harvest()
    end

    if target.components.dryer ~= nil then
        target.components.dryer:DropItem()
    end

    if target.components.harvestable ~= nil then
        target.components.harvestable:Harvest()
    end

    if target.components.stewer ~= nil then
        target.components.stewer:Harvest()
    end

    if target.components.constructionsite ~= nil then
        target.components.constructionsite:DropAllMaterials()
    end

    if target.components.inventoryitemholder ~= nil then
        target.components.inventoryitemholder:TakeItem()
    end
end

--- 在原版函数基础上加一个可以判断的函数checkFn
function FN.FindClosestPlayerInRangeSq(x, y, z, rangesq, isalive, checkFn)
    local closestPlayer = nil
    for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= IsEntityDeadOrGhost(v))
            and (checkFn == nil or checkFn(v))
            and v.entity:IsVisible() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestPlayer = v
            end
        end
    end
    return closestPlayer, closestPlayer ~= nil and rangesq or nil
end

--- 在原版函数的基础上，支持inst为一个Vector3类型，并且不排除死亡对象，返回找到的对象，距离
---@param inst Entity|Vector3
---@param radius number
---@param ignoreheight boolean|nil
---@param musttags table|nil
---@param canttags table|nil
---@param mustoneoftags table|nil
---@param fn function|nil
function FN.FindClosestEntity(inst, radius, ignoreheight, musttags, canttags, mustoneoftags, fn)
    local isEntity = inst and not inst.IsVector3
    if not inst or (isEntity and not inst:IsValid()) then
        return
    end

    local x, y, z
    if isEntity then
        x, y, z = inst.Transform:GetWorldPosition()
    else
        x, y, z = inst:Get()
    end

    local ents = TheSim:FindEntities(x, ignoreheight and 0 or y, z, radius, musttags, canttags, mustoneoftags)
    local closestEntity = nil
    local rangesq = radius * radius
    for i, v in ipairs(ents) do
        if (not isEntity or v ~= inst)
            -- and (not IsEntityDeadOrGhost(v))
            and v.entity:IsVisible()
            and (not fn or fn(v, inst)) then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestEntity = v
            end
        end
    end
    return closestEntity, closestEntity ~= nil and rangesq or nil
end

--- 通过userid在AllPlayers中查找玩家
function FN.GetPlayerById(userid)
    for _, player in ipairs(AllPlayers) do
        if player.userid == userid then
            return player
        end
    end
end

--- 是否处于战斗状态
--- @param inst Entity
--- @param combatTimeout number|nil 战斗超时时间，默认为6，该时间判断角色是否处于战斗状态
function FN.IsInCombat(inst, combatTimeout)
    local combat = inst.components.combat
    if not combat then return false end

    combatTimeout = combatTimeout or 6

    local timeout_time = GetTime() - combatTimeout
    if not combat.laststartattacktime or combat.laststartattacktime ~= 0 then --把刚进游戏的情况排除掉
        local attack_time = math.max(combat.laststartattacktime or 0, combat.lastdoattacktime or 0)
        if attack_time > timeout_time then
            return true
        end
    end


    if combat.lastwasattackedtime ~= 0 and combat.lastwasattackedtime > timeout_time then --这个值不会为nil
        if combat.lastattacker ~= nil and combat.lastattacker.components.combat == nil then
            return false
        end
        return true
    end

    return false
end

--- 判断单位是否死亡或正在死亡
--- 好像比IsEntityDeadOrGhost更好点，用IsEntityDeadOrGhost判断有时候还是会有"Left death state."的崩溃，我怀疑是有mod在玩家在death的
--- 状态下给玩家回血导致health:IsDead返回了false，判断玩家没有死，后来就调用了GoToState
function FN.IsEntityDeadOrGhost(player)
    return IsEntityDeadOrGhost(player)
        or (player.sg and player.sg:HasStateTag("dead"))
end

local function DelayRemove(inst)
    inst:DoTaskInTime(0, inst.Remove)
end

local function OnUnequipped(inst, data)
    if data.owner and data.owner:IsValid() and inst.isNotFinite then
        local slot = inst.components.equippable.equipslot
        data.owner:DoTaskInTime(0, function(owner)
            if not owner.components.inventory:GetEquippedItem(slot) then
                FN.TempEquip(owner, inst.prefab, slot, true)
            end
        end)
    end
    if inst:IsValid() then
        DelayRemove(inst)
    end
end

local function OnEquipRemove(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if owner and owner:IsValid() and inst.components.equippable and inst.components.equippable:IsEquipped() then
        OnUnequipped(inst, { owner = owner })
    end
end

local function AfterRemove(retTab, self)
    self.inst:Remove()
end

local function DelayAfterRemove(retTab, self)
    self.inst:DoTaskInTime(0, self.inst.Remove)
end

local function SetUsesAfter(retTab, self)
    if self.current <= 0 then
        self.inst:Remove()
    end
end

local function DoDeltaAfter(retTab, self)
    if self.currentfuel <= 0 then
        self.inst:Remove()
    end
end

--- 设置一个物品为临时物品，不保存、脱离加载删除、无掉落
function FN.SetItemTemp(inst, isNotLoot)
    inst.persists = false

    if not inst.components.vanish_on_sleep then
        inst:AddComponent("vanish_on_sleep")
    end

    if isNotLoot then
        FN.SetNoLoot(inst, true)
    end

    inst:ListenForEvent("on_landed", inst.Remove)
end

--- 临时装备某个装备
--- 如果设置isNotFinite为true后单位这个装备槽就不会为空，如果不希望再持有可以先获取装备槽装备，然后设置isNotFinite变量为nil
---@param inst Entity 装备者
---@param prefab string 想装备的武器名
---@param slot EQUIPSLOTS 装备槽
---@param isNotFinite boolean|nil 是否无限耐久，如果为true当耐久耗尽或持有者卸下时会再生成一把
function FN.TempEquip(inst, prefab, slot, isNotFinite)
    local item = inst.components.inventory:GetEquippedItem(slot)
    if item and item.prefab == prefab then
        return item
    end

    item = SpawnPrefab(prefab)
    FN.SetItemTemp(item, true)

    item.components.inventoryitem:SetOnDroppedFn(item.Remove)
    if item.components.perishable then
        Utils.FnDecorator(item.components.perishable, "Perish", nil, AfterRemove)
        if item.components.perishable.onperishreplacement then
            Utils.FnDecorator(item.components.perishable, "onreplacedfn", nil, DelayAfterRemove)
        end
    end
    if item.components.armor then
        item.components.armor:SetKeepOnFinished(false)
    end
    if item.components.finiteuses then
        Utils.FnDecorator(item.components.finiteuses, "SetUses", nil, SetUsesAfter)
    end
    if item.components.fueled then
        Utils.FnDecorator(item.components.fueled, "DoDelta", nil, DoDeltaAfter)
    end

    if isNotFinite then
        item.isNotFinite = true
        item:ListenForEvent("unequipped", OnUnequipped)
        item:ListenForEvent("onremove", OnEquipRemove)
    else
        item:ListenForEvent("unequipped", DelayRemove)
    end

    inst.components.inventory:Equip(item)

    return item
end

--- 强制给予对象某个物品，如果已经满了会把手持物品掉落再给予
function FN.ForceGiveItem(inst, item)
    if not item.components.inventoryitem
        or not item.components.inventoryitem.cangoincontainer
    then
        return false
    end

    local self = inst.components.inventory
    if self:GiveItem(item) then
        return true
    end

    if self.activeitem then
        self:DropItem(self.activeitem, true, true)
        self:SetActiveItem(nil)
    end
    if self:GiveItem(item) then
        return true
    end

    -- 如果是可以拾取的道具应该不会到达这里
    return false
end

--- 通过预制件名查找对象
function FN.FindEntitiesByName(x, y, z, radius, name)
    local ents = {}
    for _, v in ipairs(TheSim:FindEntities(x, y, z, radius)) do
        if v.prefab == name then
            table.insert(ents, v)
        end
    end
    return ents
end

--- 获取rpc内的执行函数
function FN.GetModRPCFn(namespace, name)
    local id = MOD_RPC[namespace] and MOD_RPC[namespace][name]
    id = id and id.id
    return id and MOD_RPC_HANDLERS[namespace][id] or nil
end

--- 获取距离限制下的攻击目标
function FN.GetNearTarget(inst, raidus)
    raidus = raidus or 8
    local target = inst.components.combat.target
    if target and target:IsValid() and not IsEntityDead(target) and inst:IsNear(target, raidus) then
        return target
    end
end

local FIND_CLOSEST_KEY = KEY .. "tempDisSq"
local function SortByDis(a, b)
    return a[FIND_CLOSEST_KEY] < b[FIND_CLOSEST_KEY]
end

---按照离所给坐标的距离从小到大进行排序
function FN.SortEntsByDis(ents, centterPos)
    for _, v in ipairs(ents) do
        v[FIND_CLOSEST_KEY] = distsq(v:GetPosition(), centterPos)
    end

    table.sort(ents, SortByDis)

    for _, v in ipairs(ents) do
        v[FIND_CLOSEST_KEY] = nil
    end

    return ents
end

---FindEntities的增强，在此基础上按照离所给坐标的距离从小到大进行排序
function FN.FindClosestEntities(x, y, z, radius, musttags, canttags, mustoneoftags, centterPos)
    local ents = TheSim:FindEntities(x, y, z, radius, musttags, canttags, mustoneoftags)
    if #ents <= 1 then return ents end

    centterPos = centterPos or Vector3(x, y, z)
    return FN.SortEntsByDis(ents, centterPos)
end

---在一个对象表中查找里所给坐标最近的对象
---@param ents table 对象表
---@param pos Vector3 要查找的点
---@return Entity|nil ent 离所给点最近的对象
---@return number|nil rangesq 距离的平方
function FN.FindClosestEnt(ents, pos)
    local closestEnt = nil
    local rangesq = math.huge
    for i, v in ipairs(ents) do
        local distsq = distsq(v:GetPosition(), pos)
        if distsq < rangesq then
            rangesq = distsq
            closestEnt = v
        end
    end
    return closestEnt, closestEnt ~= nil and rangesq or nil
end

function FN.GetDistance(inst, target)
    return math.sqrt(inst:GetDistanceSqToInst(target))
end

function FN.GetValidEnts(ents)
    local res = {}
    for _, v in ipairs(ents) do
        if v:IsValid() then
            table.insert(res, v)
        end
    end
    return res
end

local function OnPickup(inst)
    inst:DoTaskInTime(0, function()
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner
            and owner.components.inventory
            and ((inst[KEY .. "pick_name"] and owner.prefab ~= inst[KEY .. "pick_name"])
                or (inst[KEY .. "pick_tag"] and not owner:HasTag(inst[KEY .. "pick_tag"])))
        then
            owner.components.inventory:DropItem(inst)
            local say = inst[KEY .. "pick_say"]
            if say then
                owner:DoTaskInTime(0.5, function(owner)
                    if owner.components.talker then
                        owner.components.talker:Say(FunctionOrValue(say, owner))
                    end
                end)
            end
        end
    end)
end

---限制某个装备是否能被捡起
---@param inst Entity
---@param restrictedtag string|nil
---@param restrictedname string|nil
---@param say string|function|nil
function FN.SetRestrictPick(inst, restrictedtag, restrictedname, say)
    inst[KEY .. "pick_tag"] = restrictedtag
    inst[KEY .. "pick_name"] = restrictedname
    inst[KEY .. "pick_say"] = say
    inst:ListenForEvent("onpickup", OnPickup)
end

local ATTACK_ONEOF1_TAGS = { "_combat" }
local ATTACK_ONEOF2_TAGS = { "_combat", "CHOP_workable", "MINE_workable" }
local ATTACK_ONEOF3_TAGS = { "_combat", "CHOP_workable", "MINE_workable", "HAMMER_workable" }
local ATTACK_ONEOF4_TAGS = { "_combat", "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable" }
local ATTACK_CANT_TAGS = { "player", "companion", "INLIMBO", "notarget", "noattack", "invisible" }
---查找玩家可以攻击的目标
---@param attacker Entity|nil 攻击者
---@param radius number 查找半径
---@param pos Vector3|nil 查找坐标，默认攻击者所在位置
---@param force boolean|nil 攻击目标是否包括中立单位，默认不攻击中立单位
---@param work_level number|boolean|nil 是否可以工作，工作等级，包括砍、挖、锤、凿
---@return table targets
function FN.GetPlayerAttackTarget(attacker, radius, pos, force, work_level)
    local targets = {}
    pos = pos or attacker and attacker:GetPosition()
    -- if attacker then --如果是DoAttack，那需要为true，如果是GetAttacked，怕下面取消了会影响函数外的DoAttack，应该手动添加和移除
    --     attacker.components.combat.ignorehitrange = true
    -- end
    local oneof_tags = work_level == 4 and ATTACK_ONEOF4_TAGS
        or work_level == 3 and ATTACK_ONEOF3_TAGS
        or work_level and ATTACK_ONEOF2_TAGS
        or ATTACK_ONEOF1_TAGS

    for _, v in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, radius, nil, ATTACK_CANT_TAGS, oneof_tags)) do
        if v.entity:IsVisible()
            and (((attacker and FN.PlayerTargetTest(attacker, v, force)) or (not attacker and v.components.combat:CanBeAttacked()))
                or (v.components.workable and v.components.workable:CanBeWorked())) then
            table.insert(targets, v)
        end
    end
    -- if attacker then
    --     attacker.components.combat.ignorehitrange = false
    -- end
    return targets
end

---添加掉落物，用于单位死亡时调用，如果有lootdropper会在死亡的state里同其他掉落物一起生成，否则立即生成
---@param inst Entity
---@param loots table 掉落物表
function FN.DeathSpawnLoot(inst, loots)
    if inst.components.lootdropper then
        local loot = inst.components.lootdropper.loot
        if not loot then
            loot = {}
            inst.components.lootdropper.loot = loot
        end
        ConcatArrays(loot, loots)
    else
        -- 如果没有lootdropper组件就得提前掉落了
        for _, v in ipairs(loots) do
            local item = SpawnPrefab(v)
            item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if item.components.inventoryitem then
                item.components.inventoryitem:OnDropped()
            end
            item:PushEvent("on_loot_dropped", { dropper = inst })
        end
    end
end

local SOILMUST = { "soil" }
local SOILMUSTNOT = { "merm_soil_blocker", "farm_debris", "NOBLOCK" }
--- 获取所给坐标所在地皮3*3耕地的所有可生成土坑的坐标
function FN.GetSoilPoses(pos)
    local poses = {}
    local x, _, z = TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z)
    if TheWorld.Map:GetTileAtPoint(x, 0, z) == WORLD_TILES.FARMING_SOIL then
        local dist = 4 / 3
        for dx = -dist, dist, dist do
            for dz = -dist, dist, dist do
                if #TheSim:FindEntities(x + dx, 0, z + dz, 0.21, SOILMUST, SOILMUSTNOT) < 1
                    and TheWorld.Map:CanTillSoilAtPoint(x + dx, 0, z + dz)
                then
                    table.insert(Vector3(x + dx - 0.02 + math.random() * 0.04, 0, z + dz - 0.02 + math.random() * 0.04))
                end
            end
        end
    end
    return poses
end

local PICKUP_MUST_TAGS =
{
    "_inventoryitem"
}

local PICKUP_CANT_TAGS =
{
    "INLIMBO", "NOCLICK", "irreplaceable", "knockbackdelayinteraction",
    "event_trigger", "mineactive", "catchable", "fire", "spider", "cursed",
    "heavy", "outofreach", "storagerobot"
}

---判断某个物品是否可以捡起，用于npc捡东西
---@param picker Entity
---@param item Entity
function FN.IsPickUpItem(picker, item, checktag)
    return (not checktag or (checktag:HasTags(PICKUP_MUST_TAGS) and not checktag:HasOneOfTags(PICKUP_CANT_TAGS)))
        and item.components.inventoryitem
        and item.components.inventoryitem.canbepickedup
        and item.components.inventoryitem.cangoincontainer
        and not item.components.inventoryitem:IsHeld()
        and item:IsOnPassablePoint()
        and item:GetCurrentPlatform() == picker:GetCurrentPlatform()
        and (not item.components.bait or not item.components.bait.trap)
        and not item.components.trap
end

---遍历brain所有节点，如果函数返回true则不再继续遍历
---@param root BehaviourNode|nil
---@param fn function
function FN.ForeachBrainNode(self, fn, root)
    root = root or self.bt.root
    for i, v in ipairs(root.children) do
        if fn(self, v, i) then
            return true
        end
        if v.children then
            if FN.ForeachBrainNode(self, fn, v) then
                return true
            end
        end
    end

    return false
end

----------------------------------------------------------------------------------------------------
-- 简易cd记录

local function ClearTag(inst, key)
    inst[key] = nil
end

function FN.StartCD(inst, key, time, ignoretimer)
    if not ignoretimer and inst.components.timer then
        inst.components.timer:StartTimer(key, time)
    else
        key = KEY .. "_cd_" .. key
        if not inst[key] then
            inst[key] = inst:DoTaskInTime(time, ClearTag, key)
        end
    end
end

function FN.CDExists(inst, key)
    return inst.components.timer and inst.components.timer:TimerExists(key)
        or inst[KEY .. "_cd_" .. key]
end

function FN.StopCD(inst, key)
    if inst.components.timer then
        inst.components.timer:StopTimer(key)
    end
    key = KEY .. "_cd_" .. key
    if inst[key] then
        inst[key]:Cancel()
        inst[key] = nil
    end
end

return FN
