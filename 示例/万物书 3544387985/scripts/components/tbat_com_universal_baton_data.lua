----------------------------------------------------------------------------------------------------------------------------------
--[[

     通用数据储存库，用来储存各种 【文本】数据

]]--
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
---
    local function scale_data_onload(com)
        com:SaveOriginScale()
        local x,y,z = com:GetScale()
        com.inst.AnimState:SetScale(x,y,z)
    end
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_universal_baton_data = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
    self.TempTable = {}
    self._onload_fns = {}
    self._onsave_fns = {}

    self._on_post_init_fns = {}


    self:AddOnLoadFn(scale_data_onload)

    self.scale_max = 5
    self.scale_min = 0.35

end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_universal_baton_data:Mirror()
        local x,y,z = self:GetScale()
        self:SetScale(-x,y,z)
    end
    function tbat_com_universal_baton_data:ScaleDelta(value)
        local x,y,z = self:GetScale()

        local mirrored = x < 0 and -1 or 1
        x = math.abs(x)
        y = math.abs(y)
        z = math.abs(z or 1)

        x = math.clamp(x+value,self.scale_min,self.scale_max) * mirrored
        y = math.clamp(y+value,self.scale_min,self.scale_max)
        z = math.clamp(z+value,self.scale_min,self.scale_max)
        -- print("x,y,z:",x,y,z)
        self:SetScale(x,y,z)

    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_universal_baton_data:GetScale()
        local data = self:Get("scale")
        if data then
            return unpack(data)
        elseif self.inst.AnimState.GetScale ~= nil then
            return self.inst.AnimState:GetScale()
        end
        return 1,1,1
    end
    function tbat_com_universal_baton_data:SetScale(x,y,z)
        self:SaveOriginScale()
        self:Set("scale",{x,y,z})
        self.inst.AnimState:SetScale(x,y,z)
    end
    function tbat_com_universal_baton_data:ResetScale()
        local origin_data = self:Get("scale_origin")
        if origin_data then
            self:SetScale(unpack(origin_data))
        end
    end
    function tbat_com_universal_baton_data:SaveOriginScale()
        if self.inst.AnimState.GetScale == nil then
            return
        end
        if self:Get("scale_origin") == nil then
            self:Set("scale_origin",{self.inst.AnimState:GetScale()})
        end
    end
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_universal_baton_data:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_universal_baton_data:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_universal_baton_data:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_universal_baton_data:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_universal_baton_data:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return nil or default
    end
    function tbat_com_universal_baton_data:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_com_universal_baton_data:Add(index,num,min,max)
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
    function tbat_com_universal_baton_data:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_universal_baton_data:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_universal_baton_data:OnSave()
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

    function tbat_com_universal_baton_data:OnLoad(data)
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
return tbat_com_universal_baton_data







