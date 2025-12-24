local SpDamageUtil = require("components/spdamageutil")
local TOOLS_L = require("tools_legion")

local function oncanatk(self)
    if self.canatk then
        self.inst:AddTag("canshieldatk")
    else
        self.inst:RemoveTag("canshieldatk")
    end
end
local function DoShieldSound(doer, sound)
    if sound then
        doer.SoundEmitter:PlaySound(sound, nil, doer.hurtsoundvolume)
    end
end
local function ComputSpDamage(self, doer, spdamage)
    local resdamage = 0
    for sptype, dmg in pairs(spdamage) do
        local def = SpDamageUtil.GetSpDefenseForType(doer, sptype) --如果 doer 有对应的防御能力
        if def <= 0 then
            def = SpDamageUtil.GetSpDefenseForType(self.inst, sptype) --如果该盾有对应的防御能力
        end
        if def > 0 then
            resdamage = resdamage + dmg
            spdamage[sptype] = nil --挡下时，清除这个伤害
        end
    end
    return resdamage
end

local ShieldLegion = Class(function(self, inst)
    self.inst = inst
    self.canatk = true
    self.issuccess = false

    self.fxdata = {
        prefab = "shield_attack_l_fx",
        symbol = "lantern_overlay",
        offsetx = 10, offsety = 0
    }

    self.time = nil
    self.delta = 8 * FRAMES --FRAMES为0.033秒。并且举盾sg动画总时长为 13*FRAMES，最好小于这个值
    self.armormult_success = 1 --盾反成功时的损害系数

    -- self.shieldkey = nil
    self.time_charge = CONFIGS_LEGION.SHIELDRECHARGETIME --举盾的冷却时间
    self.time_change = CONFIGS_LEGION.SHIELDEXCHANGETIME --盾牌切换的冷却时间

    -- self.startfn = nil
    -- self.atkfn = nil
    -- self.atkstayingfn = nil
    -- self.atkfailfn = nil
    -- self.armortakedmgfn = nil
end,
nil,
{
    canatk = oncanatk
})

function ShieldLegion:CanAttack(doer) --只能在sg里用，不能用于平常的判断
    return self.canatk and self.time == nil and not self.inst:HasTag("broken")
end

function ShieldLegion:Equip(doer)
    local timenow = GetTime()
    local key = self.shieldkey or "shield"
    local timecool = 0
    if doer.legion_shieldtime == nil then
        doer.legion_shieldtime = {}
    end
    local timethat = doer.legion_shieldtime[key]
    if timethat == nil then --没在举盾冷却，那就是装备切换冷却
        timecool = self.time_change
    else
        timethat = timethat - timenow --计算出剩余冷却时间。大于0代表还在冷却中
        if timethat <= self.time_change then --进入装备切换冷却
            timecool = self.time_change
        else --还在举盾冷却
            timecool = timethat
        end
    end
    if timecool > 0 then
        if timecool == self.time_change then
            doer.legion_shieldtime[key] = timenow + timecool
        end
        if self.inst.components.rechargeable ~= nil then
            self.inst.components.rechargeable:Discharge(timecool)
        end
    else --如果玩家没有冷却，那就把当前盾牌的冷却清除了
        doer.legion_shieldtime[key] = nil
        if self.inst.components.rechargeable ~= nil then
            self.inst.components.rechargeable:SetPercent(1)
        end
    end
end

function ShieldLegion:StartAttack(doer)
    self.issuccess = false
    doer.shield_l_success = nil
    self.time = GetTime()
    if self.startfn ~= nil then
        self.startfn(self.inst, doer)
    end
end

function ShieldLegion:SetFollowedFx(target, data)
    if data == nil then
        return
    end
    local fx = SpawnPrefab(data.prefab)
    fx.entity:SetParent(target.entity)
    fx.entity:AddFollower()
    fx.Follower:FollowSymbol(target.GUID, data.symbol, data.offsetx or 0, data.offsety or 0, 0)
    return fx
end
function ShieldLegion:Counterattack(doer, attacker, data, radius, dmgmult)
    if
        attacker == nil or not attacker:IsValid() or attacker.components.combat == nil or
        attacker.components.health == nil or attacker.components.health:IsDead() or
        doer:GetDistanceSqToPoint(attacker.Transform:GetWorldPosition()) > radius*radius
    then
        return false
    end
    local dmg, spdmg, stimuli = TOOLS_L.CalcDamage(doer, attacker, self.inst, nil, nil, nil, nil, true)
    dmg = dmg * (dmgmult or 1) + ((data.damage + data.otherdamage) * 0.1)
    attacker.components.combat:GetAttacked(doer, dmg, self.inst, stimuli, spdmg)

    return true
end
function ShieldLegion:ArmorTakeDamage(doer, attacker, data)
    if self.armortakedmgfn ~= nil then
        self.armortakedmgfn(self.inst, doer, attacker, data)
    end
    if self.inst.components.armor ~= nil then
        local value = data.damage + data.otherdamage
        if value > 0 then
            if data.issuccess then
                value = value*self.armormult_success
            end
            self.inst.components.armor:TakeDamage(value)
        end
    end
end
function ShieldLegion:GetAttacked(doer, attacker, damage, weapon, spdamage, stimuli)
    if self.inst:HasTag("broken") then
        return false
    end

    local data = {
        damage = damage, --最终伤害
        otherdamage = 0, --挡下的特殊伤害总和
        spdamage = spdamage,
        weapon = weapon,
        stimuli = stimuli,
        -- israngedweapon = false,
        issuccess = false, --本次盾反是否成功
        isstay = false --是否为后续盾反
    }

    if self.issuccess then --一次sg的时间，盾反成功后完全无敌
        if doer.sg:HasStateTag("atk_shield") then --重新检查是否有效
            if stimuli ~= "darkness" then
                data.issuccess = true
            end
            data.isstay = true
        else --如果因为数据问题进入这里，就校正数据
            self:FinishAttack(doer)
        end
    elseif self.canatk and self.time ~= nil then
        if GetTime()-self.time <= self.delta and stimuli ~= "darkness" then --达成盾反条件
            data.issuccess = true
        else
            self:FinishAttack(doer)
        end
    end

    -- if --远程武器分为两类，一类是有projectile组件、一类是weapon组件中有projectile属性
    --     weapon ~= nil and (
    --         weapon.components.projectile ~= nil or
    --         weapon:HasTag("rangedweapon") or
    --         (weapon.components.weapon ~= nil and weapon.components.weapon.projectile ~= nil)
    --     )
    -- then
    --     data.israngedweapon = true
    -- end

    if data.issuccess then
        if spdamage ~= nil then
            data.otherdamage = ComputSpDamage(self, doer, spdamage)
        end
        if data.isstay then
            if self.atkstayingfn ~= nil and doer ~= attacker then --不能自己盾反自己
                self.atkstayingfn(self.inst, doer, attacker, data)
            end
        else
            if doer.sg:HasStateTag("atk_shield") then
                doer.sg:AddStateTag("nointerrupt") --防打断！这样本次sg后续被攻击不会进入被攻击sg
                doer.sg:AddStateTag("nosleep") --防催眠！
                doer.sg:AddStateTag("nofreeze") --防冻！
            end
            if self.atkfn ~= nil and doer ~= attacker then --不能自己盾反自己
                self.atkfn(self.inst, doer, attacker, data)
            end
            self.issuccess = true
            doer.shield_l_success = true --让玩家实体也能直接识别是否处于盾反成功中
        end
        if self._catkfxfn ~= nil then
            self._catkfxfn(self, doer)
        else
            self:SetFollowedFx(doer, self.fxdata) --盾保特效
        end
        DoShieldSound(doer, self.inst.hurtsoundoverride)
        self:ArmorTakeDamage(doer, attacker, data)
        return true
    -- elseif data.israngedweapon then --完全抵御远程攻击
    --     if spdamage ~= nil then
    --         data.otherdamage = ComputSpDamage(self, doer, spdamage)
    --     end
    --     DoShieldSound(doer, self.inst.hurtsoundoverride)
    --     self:ArmorTakeDamage(doer, attacker, data)
    --     return true
    else
        if self.atkfailfn ~= nil then
            self.atkfailfn(self.inst, doer, attacker, data)
        end
        return false
    end
end

function ShieldLegion:FinishAttack(doer, issgend)
    if self.time ~= nil then
        self.time = nil
        -- if self.resultfn ~= nil then
        --     self.resultfn(self.inst, doer)
        -- end
    end
    if self.issuccess then --只有成功盾反了，才会进入冷却
        if self.time_charge > 0 then
            if doer.legion_shieldtime == nil then
                doer.legion_shieldtime = {}
            end
            doer.legion_shieldtime[self.shieldkey or "shield"] = GetTime() + self.time_charge
            if self.inst.components.rechargeable ~= nil then
                self.inst.components.rechargeable:Discharge(self.time_charge)
            end
        end
        self.issuccess = false
    end
    doer.shield_l_success = nil
end

return ShieldLegion
