----------------------------------------------------------------------------------------------------------------------------------
--[[

    特别的计时器。用来处理某些机制 超出加载范围外 还需要继续运行的。

    本模块会增加游戏整体负担。慎用

    数据结构

    timers = {
        [inst] = {
            fn = function(inst,...)
            end,
            update_time = 1,        --- 定时周期
            current_time = 0,       --- 计时
            args = {...},           --- 额外参数
        }，
    }

    使用说明： tbat_com_special_timer_for_theworld:AddTimer(inst,update_time,fn,...)
    


]]--
----------------------------------------------------------------------------------------------------------------------------------
---
    local TIME_UPDATE_PARAM = 0.1       --- 本计时器的初始UPDATE精度。 0.1秒
    local TIME_UPDATE_PARAM_FIX_DELTA = 0.01       --- 步长。如果当前循环时间超过预期，则调整更新间隔
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_special_timer_for_theworld = Class(function(self, inst)
    self.inst = inst

    self.timers = {}

    self.last_update_time = nil
    self.update_interval = TIME_UPDATE_PARAM -- 初始化更新间隔

    self.__update_task_fn = function()
        -- 执行具体的更新逻辑
        self:Update()
        --------------------------------------------------------------------
        --- 更新间隔调整。游戏太卡的话，把这个增加。
            -- local current_time = GetTime()
            local current_time = os.clock()
            self.last_update_time = self.last_update_time or current_time
            local this_update_time = current_time - self.last_update_time
            -- 如果当前循环时间超过预期，则调整更新间隔
            if this_update_time > self.update_interval + TIME_UPDATE_PARAM_FIX_DELTA then
                self.update_interval = math.min(self.update_interval + TIME_UPDATE_PARAM_FIX_DELTA,1)
                -- if TBAT.DEBUGGING then
                --     print(string.format("Warning form com tbat_com_special_timer_for_theworld: Timer busy and update interval adjusted to %.2f seconds", self.update_interval))
                -- end
                self.__update_task:Cancel()
                self.__update_task = self.inst:DoPeriodicTask(self.update_interval, self.__update_task_fn)
            end
            self.last_update_time = current_time
        --------------------------------------------------------------------
    end
    -- 初始任务调度。延迟一下，避免初始阶段的卡顿造成的错误跳转。
    -- inst:DoTaskInTime(8,function()
    --     self.__update_task = self.inst:DoPeriodicTask(self.update_interval, self.__update_task_fn)
    -- end)
    TheWorld:ListenForEvent("serverpauseddirty",function()
        if not self.__theworld_is_ready then
            return
        end
        
        self.last_update_time = nil
        --- 服务器经过暂停，则重置计时器
        self.update_interval = TIME_UPDATE_PARAM -- 初始化更新间隔
        if self.__update_task then
            self.__update_task:Cancel()
        end
        self.__update_task = self.inst:DoPeriodicTask(self.update_interval, self.__update_task_fn)
        -- print("serverpauseddirty and reset timer last_update_time",self.update_interval)
    end)

    self.one_time_timers = {}   -- 一次性执行函数
    self.__theworld_is_ready = false
    TheWorld:ListenForEvent("ms_registermigrationportal",function()
        self.__theworld_is_ready = true
        TheWorld:DoTaskInTime(3,function()
            -- self:DoAllOneTimeTimers()
            if self.__update_task == nil then
                self.__update_task = self.inst:DoPeriodicTask(self.update_interval, self.__update_task_fn)
                print("info tbat_com_special_timer_for_theworld start")
            end
        end)
    end)

end)
------------------------------------------------------------------------------------------------------------------------------
-- 添加一次性执行函数。用于下一个计时器周期立马执行。通常用于加载范围外的inst的OnPostInited
    function tbat_com_special_timer_for_theworld:AddOneTimeTimer(fn,...)
        local data = {
            fn = fn,
            args = {...},
        }
        table.insert(self.one_time_timers,data)
    end
    function tbat_com_special_timer_for_theworld:DoAllOneTimeTimers()
        --[[
            【笔记】加载范围外搞事太容易导致初始化阶段闪退了。
        ]]--
        if #self.one_time_timers == 0 then
            return
        end
        if not self.__theworld_is_ready then
            return
        end
        for k, data in pairs(self.one_time_timers) do
            -- pcall(data.fn,unpack(data.args))
            data.fn(unpack(data.args))
        end
        self.one_time_timers = {}
    end
------------------------------------------------------------------------------------------------------------------------------
-- 添加周期性计时器
    function tbat_com_special_timer_for_theworld:AddTimer(inst,update_time,fn,...)
        if not (inst and inst:IsValid() and type(fn) == "function") then
            return
        end
        update_time = update_time or 1
        local args = {...}
        self.timers[inst] = {
            fn = fn,
            update_time = update_time,
            current_time = update_time,
            -- args = {...},
        }
        if #args > 0 then
            self.timers[inst].args = args
        end
    end
    function tbat_com_special_timer_for_theworld:SetTimer(...)
        self:AddTimer(...)
    end
    function tbat_com_special_timer_for_theworld:RemoveTimer(inst)
        local new_table = {}
        for k, v in pairs(self.timers) do
            if k ~= inst then
                new_table[k] = v
            end
        end
        self.timers = new_table
    end
------------------------------------------------------------------------------------------------------------------------------
--- 更新函数
    function tbat_com_special_timer_for_theworld:Update()
        self:DoAllOneTimeTimers() -- 在下一次更新的时候运行一次性函数。
        local need_2_remove_flag = false
        for inst, data in pairs(self.timers) do
            if inst:IsValid() then
                data.current_time = data.current_time - self.update_interval
                if data.current_time <= 0 then
                    data.fn(inst,data.args and unpack(data.args))
                    data.current_time = data.update_time
                end
            else
                need_2_remove_flag = true
            end
        end
        if need_2_remove_flag then
            self:RemoveInvalidTimer()
        end
    end
    function tbat_com_special_timer_for_theworld:RemoveInvalidTimer()
        local new_table = {}
        for inst, data in pairs(self.timers) do
            if inst:IsValid() then
                new_table[inst] = data
            end
        end
        self.timers = new_table
    end
------------------------------------------------------------------------------------------------------------------------------
---  LongUpdate 长更新函数
    function tbat_com_special_timer_for_theworld:LongUpdate(dt)
        --- dt 单位 秒
        -- print("++++++ _special_timer_for_theworld LongUpdate ",dt)
        if type(dt) == "number" then
            local update_num = dt/self.update_interval
            for i = 1, update_num do
                self:Update()
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_special_timer_for_theworld







