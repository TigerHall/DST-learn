local HTimingContainer = Class(function(self, inst)
    self.inst = inst
    self.onbreakfn = nil
    self.targettime = nil
    self.breaktime = TUNING.TOTAL_DAY_TIME * 2
end)

function HTimingContainer:SetBreakTime(breaktime)
    self.breaktime = breaktime
end

function HTimingContainer:SetOnBreakFn(fn)
    self.onbreakfn = fn
end

function HTimingContainer:SetOnBreakFx(fx)
    self.onbreakfx = fx
end

local function StartBreakTask(self)
    self.breaktask = self.inst:DoTaskInTime(self.breaktime, function()
        self.inst:PushEvent("onbreak")
        if self.onbreakfn then
            self.onbreakfn(self.inst)
        end
        if self.onbreakfx then
            local fx = SpawnPrefab(self.onbreakfx)
            if fx then
                fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            end
        end
    end)
end

function HTimingContainer:StartBreak()
    self.targettime = GetTime() + self.breaktime
    StartBreakTask(self)
end

-- 保存状态
function HTimingContainer:OnSave()
    local data = {}
    if self.targettime then
        data.targettime = self.targettime - GetTime()
    end
    return next(data) ~= nil and data or nil
end

-- 加载状态
function HTimingContainer:OnLoad(data)
    if data and data.targettime then
        self.targettime = GetTime() + data.targettime
        StartBreakTask(self)
    end
end

return HTimingContainer