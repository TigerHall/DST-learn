local function Heal(inst, dt)
    dt = dt or 10
    dt = dt * 0.2 --别太超模了

    if inst.components.fueled then
        inst.components.fueled:DoDelta(dt)
    end
    if inst.components.armor then
        inst.components.armor:Repair(dt)
    end
    if inst.components.perishable then
        inst.components.perishable.perishremainingtime = inst.components.perishable.perishremainingtime + dt
    end
    if inst.components.finiteuses then
        inst.components.finiteuses:Repair(dt)
    end
end

--- 缓慢恢复耐久
local FiniteusesHeal = Class(function(self, inst)
    self.inst = inst

    self.sleep_start = 0
    self.healtask = inst:DoPeriodicTask(10, Heal)
end)

function FiniteusesHeal:OnEntitySleep()
    if self.healtask then
        self.healtask:Cancel()
        self.healtask = nil
    end

    self.sleep_start = GetTime()
end

function FiniteusesHeal:OnEntityWake()
    if not self.healtask then
        self.healtask = self.inst:DoPeriodicTask(10, Heal)
    end
    Heal(self.inst, math.max(GetTime() - self.sleep_start, 0)) --保险起见
end

function FiniteusesHeal:OnSave()
    return {
        sleeptime = GetTime() - self.sleep_start
    }
end

function FiniteusesHeal:OnLoad(data)
    if not data then return end

    self.sleep_start = data.sleeptime and (GetTime() - data.sleeptime) or self.sleep_start
end

return FiniteusesHeal
