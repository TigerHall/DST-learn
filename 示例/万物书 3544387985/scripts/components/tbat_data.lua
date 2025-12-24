----------------------------------------------------------------------------------------------------------------------------------
--[[

     通用数据储存库，用来储存各种 【文本】数据

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_data = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
    self.TempTable = {}
    self._onload_fns = {}
    self._onsave_fns = {}

    self._on_post_init_fns = {}
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
--- copy data
    function tbat_data:CopyDataFromInst(target)
        if target and target.components.tbat_data then
            self.DataTable = deepcopy(target.components.tbat_data.DataTable)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_data:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_data:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_data:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_data:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_data:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return nil or default
    end
    function tbat_data:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_data:Add(index,num,min,max)
        if index then
            if min and max then
                local ret = (self.DataTable[index] or 0) + ( num or 0 )
                ret = math.clamp(ret,min,max)
                self.DataTable[index] = ret
                return ret
            else
                self.DataTable[index] = (self.DataTable[index] or 0) + ( num or 0 )
                return self.DataTable[index]
            end
        end
        return 0
    end
------------------------------------------------------------------------------------------------------------------------------
--- 在 DoTaskInTime 0 之前，world 创建完成之后。只有玩家自身、TheWorld起作用
    function tbat_data:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_data:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_data:OnSave()
        self:ActiveOnSaveFns()
        local data =
        {
            -- DataTable = self.DataTable
        }
        -------------------------------------
        --
            for k, v in pairs(self.DataTable) do
                data[k] = v
            end
        -------------------------------------
        return next(data) ~= nil and data or nil
    end

    function tbat_data:OnLoad(data)
        -- if data.DataTable then
        --     self.DataTable = data.DataTable
        -- end
        -------------------------------------
        ---
            data = data or {}
            for k, v in pairs(data) do
                self.DataTable[k] = v
            end
        -------------------------------------
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_data







