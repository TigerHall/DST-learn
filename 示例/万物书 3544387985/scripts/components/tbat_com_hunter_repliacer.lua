----------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_hunter_repliacer = Class(function(self, inst)
    self.inst = inst

    -------------------------------------------------
    --- 
        self.DataTable = {}
        self.TempTable = {}
        self._onload_fns = {}
        self._onsave_fns = {}
        self._on_post_init_fns = {}
    -------------------------------------------------
    ---
        self.replacer = {}
        self.___inst_on_remove_fn = function(tempInst)
            self:RemoveReplacerFn(tempInst)
        end
    -------------------------------------------------
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
-- 广播附近的玩家。
    function tbat_com_hunter_repliacer:SpawnDirtAt(dir_inst)
        local x,y,z = dir_inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z,TUNING.HUNT_SPAWN_DIST*2, {"player"})
        for k, v in pairs(ents) do
            v:PushEvent("tbat_com_hunter_repliacer.spawned_dir",dir_inst)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- replace_fn
    function tbat_com_hunter_repliacer:AddReplacerFn(inst,fn)
        if self.replacer[inst] == nil then
            self.replacer[inst] = fn
            inst:ListenForEvent("onremove",self.___inst_on_remove_fn)
        end
    end
    function tbat_com_hunter_repliacer:RemoveReplacerFn(inst)
        local new_table = {}
        for k, v in pairs(self.replacer) do
            if k ~= inst then
                new_table[k] = v
            end
        end
        self.replacer = new_table
        inst:RemoveEventCallback("onremove",self.___inst_on_remove_fn)
    end
------------------------------------------------------------------------------------------------------------------------------
---    
    function tbat_com_hunter_repliacer:GetReplaceMonster(origin_monster_prefab)
        -- return "tbat_animal_snow_plum_chieftain"
        local new_prefab = origin_monster_prefab
        for tempInst, fn in pairs(self.replacer) do
            if tempInst and tempInst:IsValid() then
                new_prefab = fn(tempInst,origin_monster_prefab) or origin_monster_prefab
            end
        end
        return new_prefab
    end
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------


































































------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_hunter_repliacer:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_hunter_repliacer:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_hunter_repliacer:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_hunter_repliacer:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_hunter_repliacer:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return nil or default
    end
    function tbat_com_hunter_repliacer:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_com_hunter_repliacer:Add(index,num,min,max)
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
    function tbat_com_hunter_repliacer:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_hunter_repliacer:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_hunter_repliacer:OnSave()
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

    function tbat_com_hunter_repliacer:OnLoad(data)
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
return tbat_com_hunter_repliacer







