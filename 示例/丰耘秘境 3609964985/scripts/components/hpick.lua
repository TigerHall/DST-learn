local Hpick = Class(function(self, inst)
    self.inst = inst
    self.canbepicked = false        -- 可采摘
    self.canbetransplanted = false  -- 可移植
    self.product = nil              -- 产品
    self.onpickedfn = nil           -- 采摘回调
    self.ontransplanted = nil       -- 移植回调

    self.currentstage = nil
    self.onstageupfn = nil
    self.stages = {}
    self.maxstage = 1
    self.picknum = 0
    self.addpicknum = false

    self.picksound = nil

    self.task = nil

    self.targettime = nil
    self.starttime = nil

end)

--设置可采摘
function Hpick:SetCanBePicked(canbepicked)
    self.canbepicked = canbepicked
end

-- 设置采摘时的回调函数
function Hpick:SetOnPickedFn(fn)
    self.onpickedfn = fn
end

-- 设置升级时的回调函数
function Hpick:SetOnStageUpFn(fn)
    self.onstageupfn = fn
end

-- 设置当前阶段
function Hpick:SetStage(stage)
    self.currentstage = stage
end

-- 获取当前阶段
function Hpick:GetStage()
    return self.currentstage
end

-- 获取还需采摘多少次进入下一阶段
function Hpick:GetPickNum()
    return self.stages[self.currentstage].picknum - self.picknum
end

-- -- 升级
-- function Hpick:UpGradeStage()
--     if self.picknum >= self.stages[self.currentstage].picknum then
--         if self.currentstage < #self.stages then
--             self.currentstage = self.currentstage + 1
--             if self.onstageupfn ~= nil then
--                 self.onstageupfn(self.currentstage)
--             end
--             self.picknum = 0
--         end
--     end
-- end

-- 增加当前已采摘次数
function Hpick:AddPickNum(num)
    for i = 1,num do
        self.picknum = self.picknum + 1
        self:UpGradeStage()
    end
end

-- 获取当前阶段到下一阶段的总时间
function Hpick:GetStageTime(stage)
    return self.stages[stage].time
end

-- 获取当前阶段到下一阶段所需要的时间
function Hpick:GetCurrentGrowTime()
    if self.task ~= nil then
        return self.targettime - GetTime()
    else
        return 0
    end
end

-- 开始生长
function Hpick:StartGrow()
    local timetogrow = self:GetStageTime(self.currentstage)
    if timetogrow ~= -1 then
        if self.task ~= nil then
            self.task:Cancel()
        end

        self.starttime = GetTime()
        if self.targettime == nil then
            self.targettime = self.starttime + timetogrow
        end

        self.task = self.inst:DoTaskInTime(timetogrow, function()
            if self.canbepicked == false then
                self.canbepicked = true
            end
            if not self.inst:HasTag("pickable") then
                self.inst:AddTag("pickable")
            end
            if not self.inst:HasTag("hpickable") then
                self.inst:AddTag("hpickable")
            end
            if self.task ~= nil then
                self.task:Cancel()
                self.task = nil
            end
            self.starttime = nil
            self.targettime = nil
        end)
    end
end

-- 停止生长
function Hpick:StopGrow()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

-- 添加阶段
function Hpick:AddStage(stagein,timein,picknumin,productsin)
    self.stages[stagein] = {
        stage = stagein,
        time = timein,
        picknum = picknumin,
        products = productsin
    }
    if stagein > self.maxstage then
        self.maxstage = stagein
    end
end

-- 掉落产物
function Hpick:DropProduct(stage,picker)
    if self.stages[stage] ~= nil then
        for k,v in pairs(self.stages[stage].products) do
            if v[1] ~= nil then
                if v[2] >= math.random() then
                    picker.components.inventory:GiveItem(SpawnPrefab(v[1]),1)
                end
            end
        end
    end
end

-- 升级
function Hpick:UpGradeStage()
    if self.currentstage < self.maxstage then
        if self.addpicknum == true then
            self.addpicknum = false
            self.stages[1].picknum = self.stages[1].picknum + math.random(5,7)
        elseif self.picknum >= self.stages[self.currentstage].picknum then
            self.currentstage = self.currentstage + 1
            self.picknum = 0
            if self.onstageupfn ~= nil then
                self.onstageupfn(self.currentstage)
            end
        end
    end
end

-- 设置采摘函数
function Hpick:Pick(picker)
    if self.canbepicked == true then
        if self.picksound ~= nil then
            picker.SoundEmitter:PlaySound(self.picksound)
        end
        self.inst:RemoveTag("pickable")
        self.inst:RemoveTag("hpickable")
        self.canbepicked = false
        self:DropProduct(self.currentstage,picker)
        if self.onpickedfn ~= nil then
            self.onpickedfn(self.inst,picker)
        end
        self.picknum = self.picknum + 1
        self:UpGradeStage()
    end
end

-- 设置采摘声音
function Hpick:SetSound(sound)
    self.picksound = sound
end

-- 保存状态
function Hpick:OnSave()
    local data =
    {
        canbepicked         = self.canbepicked and true,
        canbetransplanted   = self.canbetransplanted and true,
        currentstage        = self.currentstage,
        stages              = self.stages,
        maxstage            = self.maxstage,
        picknum             = self.picknum,
        addpicknum          = self.addpicknum or nil,
    }
    if self.targettime ~= nil then
        if self.targettime > GetTime() then
            data.targettime = self.targettime - GetTime()
        end
    end

    return next(data) ~= nil and data or nil
end

-- 加载状态
function Hpick:OnLoad(data)
    self.canbepicked        = data.canbepicked
    self.canbetransplanted  = data.canbetransplanted
    self.currentstage       = data.currentstage
    self.stages             = data.stages
    self.maxstage           = data.maxstage
    self.picknum            = data.picknum
    self.addpicknum         = data.addpicknum or nil
    if data.targettime ~= nil then
        self.targettime = GetTime() + data.targettime
    end
end

return Hpick