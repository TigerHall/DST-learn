----------------------------------------------------------------------------------------------------------------------------------
--[[

    岛屿分阶段装饰器。

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_fantasy_island_anchor_decorator = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
    self.TempTable = {}
    self._onload_fns = {}
    self._onsave_fns = {}

    self._on_post_init_fns = {}
    self.inst:DoTaskInTime(0,function()
        self:Start()
    end)
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_fantasy_island_anchor_decorator:Start()
        ---------------------------------------------------------------------------------------
        --- 如果在海里，延迟进行装修。
            local x,y,z = self.inst.Transform:GetWorldPosition()
            if TheWorld.Map:IsOceanAtPoint(x,y,z) then
                self.inst:DoTaskInTime(1,function()
                    self:Start()
                end)
                return
            end
        ---------------------------------------------------------------------------------------

        local all_tasks = TBAT.MAP:GetAnchorDecorateTasks(self.inst.prefab)
        local start_time = os.clock()
        local x,y,z = self.inst.Transform:GetWorldPosition()
        for index, data in pairs(all_tasks) do
            -- print("temp_task",task)
            local task = data and data.task
            local fn = data and data.fn
            if task and fn and not self:Get(task) then
                self:Set(task, true)
                fn(x,0,z)
                print("执行幻想岛屿装修任务",self.inst.prefab,task)
            end
        end
        local end_time = os.clock()
        local cost_time = end_time - start_time
        print(string.format("幻想岛屿区域 装修 "..self.inst.prefab.." 创建耗时 : %.4f 秒", cost_time))
    end
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------















































------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_com_fantasy_island_anchor_decorator:GetWorldDataIndex()
        local index = "tbat_com_fantasy_island_anchor_decorator."..tostring(self.inst.prefab)
        return index
    end
    function tbat_com_fantasy_island_anchor_decorator:GetDataTable()
        return TheWorld.components.tbat_data:Get(self:GetWorldDataIndex(),{})
    end
    function tbat_com_fantasy_island_anchor_decorator:SetDataTable(data)
        TheWorld.components.tbat_data:Set(self:GetWorldDataIndex(),data)
    end
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_fantasy_island_anchor_decorator:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_fantasy_island_anchor_decorator:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_fantasy_island_anchor_decorator:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_fantasy_island_anchor_decorator:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_fantasy_island_anchor_decorator:Get(index,default)
        if index then
            return self:GetDataTable()[index] or default
        end
        return nil or default
    end
    function tbat_com_fantasy_island_anchor_decorator:Set(index,theData)
        if index then
            local _table = self:GetDataTable()
            _table[index] = theData
            self:SetDataTable(_table)
        end
    end

    function tbat_com_fantasy_island_anchor_decorator:Add(index,num,min,max)
        if index then
            local _table = self:GetDataTable()
            if min and max then
                local ret = (_table[index] or 0) + ( num or 0 )
                ret = math.clamp(ret,min,max)
                _table[index] = ret
                self:SetDataTable(_table)
                return ret
            else
                _table[index] = (_table[index] or 0) + ( num or 0 )
                self:SetDataTable(_table)
                return _table[index]
            end
        end
        return 0
    end
------------------------------------------------------------------------------------------------------------------------------
--- 在 DoTaskInTime 0 之前，world 创建完成之后
    function tbat_com_fantasy_island_anchor_decorator:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_fantasy_island_anchor_decorator:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_fantasy_island_anchor_decorator:OnSave()
        self:ActiveOnSaveFns()
        local data =
        {
            -- DataTable = self:GetDataTable()
        }
        local _data_table = self:GetDataTable()
        for k, v in pairs(_data_table) do
            data[k] = v
        end
        return next(data) ~= nil and data or nil
    end

    function tbat_com_fantasy_island_anchor_decorator:OnLoad(data)
        self.inited = true
        -- if data.DataTable then
        --     self:SetDataTable(data.DataTable)
        -- end
        data = data or {}
        self:SetDataTable(data)
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_fantasy_island_anchor_decorator


