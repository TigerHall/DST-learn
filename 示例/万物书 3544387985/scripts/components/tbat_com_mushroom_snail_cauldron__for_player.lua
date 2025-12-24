----------------------------------------------------------------------------------------------------------------------------------
--[[

    通用数据储存库，用来储存各种 【文本】数据

    挂载在玩家身上，把数据储存到 TheWorld 里。

    支持跨洞穴带走数据



]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_mushroom_snail_cauldron__for_player = Class(function(self, inst)
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
    function tbat_com_mushroom_snail_cauldron__for_player:SyncData()
        local all_data_table = self:GetDataTable()
        local str = json.encode(all_data_table)
        str = TBAT.FNS:ZipJsonStr(str)
        TBAT.FNS:RPC_PushEvent(self.inst,"tbat_com_mushroom_snail_cauldron__for_player",str,nil,nil,function()
            self:SyncData()    
        end)
    end
------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(product)
        return self:Get(product) == true
    end
    function tbat_com_mushroom_snail_cauldron__for_player:Unlock(product)
        if TBAT.MSC:GetRecipeData(product) then
            local has_recipe = self:HasRecipe(product)
            self:Set(product,true)
            self:SyncData()
            -----------------------------------------------------------
            --- 特效 + 声明
                if has_recipe == false then
                    --- 特效
                    local player = self.inst
                    local fx = SpawnPrefab(player.components.rider ~= nil and player.components.rider:IsRiding() and "fx_book_research_station_mount" or "fx_book_research_station")
                    fx.Transform:SetPosition(player.Transform:GetWorldPosition())
                    fx.Transform:SetRotation(player.Transform:GetRotation())
                    --- 私语
                    local pot_prefab= "tbat_container_mushroom_snail_cauldron"
                    local product_name = STRINGS.NAMES[string.upper(product)]
                    local str = TBAT:GetString2(pot_prefab,"unlock_info")
                    if str then
                        str = TBAT.FNS:ReplaceString(str,"{xxxx}",product_name)
                        TBAT.MSC:WhisperTo(player,str)
                    end
                    ---
                end
            -----------------------------------------------------------
        end
    end
    function tbat_com_mushroom_snail_cauldron__for_player:Lock(product)
        if TBAT.MSC:GetRecipeData(product) then
            self:Set(product,false)
            self:SyncData()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_com_mushroom_snail_cauldron__for_player:GetWorldDataIndex()
        local index = "tbat_com_mushroom_snail_cauldron__for_player.player."..tostring(self.inst.userid)
        return index
    end
    function tbat_com_mushroom_snail_cauldron__for_player:GetDataTable()
        return TheWorld.components.tbat_data:Get(self:GetWorldDataIndex(),{})
    end
    function tbat_com_mushroom_snail_cauldron__for_player:SetDataTable(data)
        TheWorld.components.tbat_data:Set(self:GetWorldDataIndex(),data)
    end
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_mushroom_snail_cauldron__for_player:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_mushroom_snail_cauldron__for_player:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_mushroom_snail_cauldron__for_player:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_mushroom_snail_cauldron__for_player:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_mushroom_snail_cauldron__for_player:Get(index,default)
        if index then
            return self:GetDataTable()[index] or default
        end
        return nil or default
    end
    function tbat_com_mushroom_snail_cauldron__for_player:Set(index,theData)
        if index then
            local _table = self:GetDataTable()
            _table[index] = theData
            self:SetDataTable(_table)
        end
    end

    function tbat_com_mushroom_snail_cauldron__for_player:Add(index,num,min,max)
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
    function tbat_com_mushroom_snail_cauldron__for_player:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_mushroom_snail_cauldron__for_player:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_mushroom_snail_cauldron__for_player:OnSave()
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

    function tbat_com_mushroom_snail_cauldron__for_player:OnLoad(data)
        self.inited = true
        -- if data.DataTable then
        --     self:SetDataTable(data.DataTable)
        -- end
        data = data or {}
        self:SetDataTable(data)
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_mushroom_snail_cauldron__for_player







