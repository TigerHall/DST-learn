-- 薇洛火焰抗性组件
-- 基于薇洛暗焰和月焰的伤害机制设计的抗性系统
-- 暗焰：5团暗影卷须，单体造成60物理伤害+90位面伤害
-- 月焰：5秒持续喷射，每0.33秒造成20物理伤害+30位面伤害
local FlameResist2hm = Class(function(self, inst)
    self.inst = inst
    self.resistance = 0          -- 当前抗性值 (0-0.4, 即0%-40%减免)
    self.maxresistance = 0.4     -- 最大抗性40% (原伤害的60%)
    self.resistperstep = 0.05    -- 每次受击增加5%抗性
    self.recoverdelay = 2        -- 2秒后开始恢复
    self.recoverpersecond = 0.05 -- 每秒恢复5%抗性
    self.delayremaining = 0      -- 剩余延迟时间
end)

function FlameResist2hm:OnFlameDamage(damage, src)
    if damage > 0 then
        -- 重置恢复延迟
        self.delayremaining = self.recoverdelay
        -- 增加抗性
        self:DoDelta(self.resistperstep)
    end
end

function FlameResist2hm:GetResistance()
    return self.resistance
end

function FlameResist2hm:DoDelta(delta)
    self:SetResistance(self.resistance + delta)
end

function FlameResist2hm:SetResistance(resistance)
    self.resistance = math.max(0, math.min(self.maxresistance, resistance))
    if self.resistance > 0 then
        self.inst:StartUpdatingComponent(self)
    else
        self.inst:StopUpdatingComponent(self)
        self.delayremaining = 0
    end
end

function FlameResist2hm:OnUpdate(dt)
    if self.delayremaining > 0 then
        -- 延迟期间不恢复
        self.delayremaining = self.delayremaining - dt
    else
        -- 开始恢复抗性
        self:DoDelta(-dt * self.recoverpersecond)
    end
end

function FlameResist2hm:OnSave()
    return self.resistance > 0.001 
        and { 
            resistance = self.resistance,
            delayremaining = self.delayremaining 
        }
        or nil
end

function FlameResist2hm:OnLoad(data)
    if data ~= nil then
        if data.resistance ~= nil then
            self:SetResistance(data.resistance)
        end
        if data.delayremaining ~= nil then
            self.delayremaining = data.delayremaining
        end
    end
end

function FlameResist2hm:GetDebugString()
    return string.format("Flame Resistance: %.1f%%, Delay: %.1fs", 
                        self.resistance * 100, self.delayremaining)
end

return FlameResist2hm
