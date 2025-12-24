--- 简单的周期任务组件，休眠后会暂停苏醒时再启动；可以控制任务开关
local SimplePeriodTask = Class(function(self, inst)
    self.inst = inst
    self.tasks = {}

    self.turnonfn = nil
    self.turnofffn = nil
end)

function SimplePeriodTask:OnRemoveFromEntity()
    for name, _ in pairs(self.tasks) do
        self:Cancel(name)
    end
end

function SimplePeriodTask:DoPeriodicTask(name, time, fn, initialdelay, ...)
    name = name or "" --默认名
    if self.tasks[name] then
        self:Cancel(name)
    end

    self.tasks[name] = {
        task = not self.inst:IsAsleep() and self.inst:DoPeriodicTask(time, fn, initialdelay, ...) or nil,
        time = time,
        fn = fn,
        initialdelay = initialdelay,
        data = { ... },
        on = true
    }
end

function SimplePeriodTask:Cancel(name)
    local d = self.tasks[name]
    if d then
        if d.task then
            d.task:Cancel()
        end
        self.tasks[name] = nil
    end
end

local function TurnOn(self, d, name)
    d.task = self.inst:DoPeriodicTask(d.time, d.fn, d.initialdelay, unpack(d.data))
    if self.turnonfn then
        self.turnonfn(self.inst, name)
    end
end

local function TurnOff(self, d, name)
    if d.task then
        d.task:Cancel()
        d.task = nil
    end
    if self.turnofffn then
        self.turnofffn(self.inst, name)
    end
end

function SimplePeriodTask:OnEntityWake()
    for name, d in pairs(self.tasks) do
        if d.on then
            TurnOn(self, d, name)
        end
    end
end

function SimplePeriodTask:OnEntitySleep()
    for name, d in pairs(self.tasks) do
        TurnOff(self, d, name)
    end
end

function SimplePeriodTask:TaskExists(name)
    return self.tasks[name] ~= nil
end

function SimplePeriodTask:TurnOn(name)
    local d = self.tasks[name]
    if d then
        d.on = true
        if not d.task then
            TurnOn(self, d, name)
        end
    end
end

function SimplePeriodTask:TurnOff(name)
    local d = self.tasks[name]
    if d then
        d.on = false
        TurnOff(self, d, name)
    end
end

return SimplePeriodTask
