----------------------------------------------------------------------------------------------------------------------------------
--[[

    通用数据储存库，用来储存各种 【文本】数据

    挂载在玩家身上，把数据储存到 TheWorld 里。

    支持跨洞穴带走数据

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_data_to_world = Class(function(self, inst)
    self.inst = inst

    self._onload_fns = {}
    self._onsave_fns = {}

    self._on_post_init_fns = {}
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_data_to_world:GetWorldDataIndex()
        local index = "tbat_data_to_world.player."..tostring(self.inst.userid)
        return index
    end
    function tbat_data_to_world:GetDataTable()
        return TheWorld.components.tbat_data:Get(self:GetWorldDataIndex(),{})
    end
    function tbat_data_to_world:SetDataTable(data)
        TheWorld.components.tbat_data:Set(self:GetWorldDataIndex(),data)
    end
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_data_to_world:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_data_to_world:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_data_to_world:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_data_to_world:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_data_to_world:Get(index,default)
        if index then
            return self:GetDataTable()[index] or default
        end
        return nil or default
    end
    function tbat_data_to_world:Set(index,theData)
        if index then
            local _table = self:GetDataTable()
            _table[index] = theData
            self:SetDataTable(_table)
        end
    end

    function tbat_data_to_world:Add(index,num,min,max)
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
    function tbat_data_to_world:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_data_to_world:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_data_to_world:OnSave()
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

    function tbat_data_to_world:OnLoad(data)
        self.inited = true
        -- if data.DataTable then
        --     self:SetDataTable(data.DataTable)
        -- end
        data = data or {}
        self:SetDataTable(data)
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_data_to_world







