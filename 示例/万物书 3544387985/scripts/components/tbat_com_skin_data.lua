-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    API:
        
        com:SetCurrent(skin_name)   -- 配置当前皮肤


]]--
-----------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetReplica(self)
        return self.inst.replica.tbat_com_skin_data or self.inst.replica._.tbat_com_skin_data
    end
-----------------------------------------------------------------------------------------------------------------------------------------
local tbat_com_skin_data = Class(function(self, inst)
    self.inst = inst
    inst:AddTag("tbat_com_skin_data")

    self.DataTable = {}
    self.TempTable = {}
    self._onload_fns = {}
    self._onsave_fns = {}
    self._on_post_init_fns = {}


end,
nil,
{

})
-----------------------------------------------------------------------------------------------------------------------------------------
---- 配置皮肤
    function tbat_com_skin_data:SetCurrent(skin_name,doer)
        skin_name = skin_name or "nil"
        -- print("tbat_com_skin_data SetCurrent",self.inst,skin_name)
        local all_skin_data = TBAT.SKIN:GET_ALL_SKINS_DATA()
        local skin_data = all_skin_data[skin_name]
        local clear_skin = false
        if type(skin_data) ~= "table" or skin_data.prefab_name ~= self.inst.prefab then
            clear_skin  = true
            skin_name = nil
        end
                ----------------------------------------------------------------------------------
                --- 
                    local last_skin_name = self:GetCurrent()
                    local last_skin_data = all_skin_data[last_skin_name] or {}
                ----------------------------------------------------------------------------------
                if skin_name and type(skin_data) == "table"  then            
                    ----------------------------------------------------------------------------------
                    local temp_data = skin_data

                    self:Set("current_skin",skin_name)
                    self:SetReplicaSkinName(skin_name)
                    self.inst.skinname = skin_name  --- stackable 无法叠堆在一起使用的

                    if self.inst.AnimState then
                        self.inst.AnimState:SetBank(temp_data.bank)
                        self.inst.AnimState:SetBuild(temp_data.build)
                    end
                    
                    if self.inst.components.inventoryitem and temp_data.image then
                        self.inst.components.inventoryitem.imagename = temp_data.image
                        self.inst.components.inventoryitem.atlasname = temp_data.atlas
                    end

                    if temp_data.name and self.inst.components.named then
                        self.inst.components.named:SetName(temp_data.name)
                    end
                    --- 触发皮肤切换,执行切换走旧皮肤的fn
                    if last_skin_name ~= skin_name and type(last_skin_data.server_switch_out_fn) == "function" then
                        last_skin_data.server_switch_out_fn(self.inst)
                    end
                    --- 触发皮肤切换,执行新皮肤的fn
                    if type(temp_data.server_fn) == "function" then
                        temp_data.server_fn(self.inst)
                    end

                else        ----------------------------------------------------------------------------------
                    self:Set("current_skin",skin_name)
                    self:SetReplicaSkinName(skin_name)
                    self.inst.skinname = skin_name  --- stackable 无法叠堆在一起使用的

                    local temp_default_data = self.inst.__tbat_skin_default_data
                    if temp_default_data then
                        if self.inst.AnimState and temp_default_data.bank and temp_default_data.build then
                            self.inst.AnimState:SetBank(temp_default_data.bank)
                            self.inst.AnimState:SetBuild(temp_default_data.build)
                        end
                    end

                    if self.inst.components.inventoryitem then
                        self.inst.components.inventoryitem:TBATRest()
                    end
                    if self.inst.components.named then
                        self.inst.components.named:TBATRest()
                    end

                    self:Reseted()
                    --- 触发皮肤切换,执行切换走旧皮肤的fn
                    if last_skin_name ~= skin_name and type(last_skin_data.server_switch_out_fn) == "function" then
                        last_skin_data.server_switch_out_fn(self.inst)
                    end
                    ----------------------------------------------------------------------------------
                end   

                self.inst:PushEvent("tbat_com_skin_data.skin_change",{
                    skin_name = self:GetCurrent(),
                    skin = self:GetCurrent(),
                    doer = doer,
                    last_skin_name = last_skin_name,
                })



    end
    function tbat_com_skin_data:GetCurrent() -- 获取当前皮肤
        return self:Get("current_skin")
    end
    function tbat_com_skin_data:SetRestFn(fn)
        self.__reset_fn = fn
    end
    function tbat_com_skin_data:Reseted()    -- 被重置为默认的时候调用
        if self.__reset_fn then
            self.__reset_fn(self.inst)
        end
    end

    function tbat_com_skin_data:GetCurrentData()  -- 获取当前皮肤的完整数据表
        local current = self:GetCurrent()
        if current == nil then
            return nil
        end
        return TBAT.SKIN.SKINS_DATA_SKINS[current]
    end
    function tbat_com_skin_data:SetReplicaSkinName(skin_name)
        local replica_com = GetReplica(self)
        if replica_com then
            replica_com:SetSkin(tostring(skin_name))
        end
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- 镜像处理
    function tbat_com_skin_data:SetCanMirror()
        self.inst:AddTag("tbat_tag.can_mirror")
    end
    function tbat_com_skin_data:CanMirror()
        return self.inst:HasTag("tbat_tag.can_mirror")
    end

    function tbat_com_skin_data:DoMirror()
        if self:CanMirror() then
            local old_flag = self:Get("skin_mirror") or false
            local new_flag = not old_flag
            -- self.DataTable.__Mirror_flag = new_flag
            self:Set("skin_mirror",new_flag)
            self:SkinAPI__Mirror_Check_For_Onload()
        end
    end

    function tbat_com_skin_data:SkinAPI__Mirror_Check_For_Onload()
        if self:CanMirror() then
            local current_flag = self:Get("skin_mirror") or false
            if self.inst.AnimState then
                if current_flag == true then
                    self.inst.AnimState:SetScale(-1,1,1)
                else
                    self.inst.AnimState:SetScale(1,1,1)
                end
            end
        end
    end
-----------------------------------------------------------------------------------------------------------------------------------------
---  给种植类/围栏 等物品使用的
    function tbat_com_skin_data:OnDeployItem(target_inst,doer)
        if target_inst.components.tbat_com_skin_data then
            local skin_data = self:GetCurrentData()
            if skin_data and skin_data.placed_skin_name then
                target_inst.components.tbat_com_skin_data:SetCurrent(skin_data.placed_skin_name,doer)
            end
        end
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- 刚刚换了皮肤，配置特效
    function tbat_com_skin_data:OnReskin(doer,skin_name)
        if self.over_active_reskin_fn then
            self.over_active_reskin_fn(self.inst,doer,skin_name)
            return
        end
        local color = {
            Vector3(255,0,0),
            Vector3(0,255,0),
            Vector3(0,0,255),
            Vector3(255,255,0),
            Vector3(255,0,255),
            Vector3(0,255,255),
            Vector3(255,255,255),
        }
        local pt = Vector3(self.inst.Transform:GetWorldPosition())
        SpawnPrefab("tbat_sfx_knowledge_flash"):PushEvent("Set",{
            pt = Vector3(pt.x,0,pt.z),
            color = color[math.random(#color)],
            sound = "terraria1/skins/spectrepaintbrush"
        })
    end
    function tbat_com_skin_data:SetOverActiveReskinFn(fn)
        self.over_active_reskin_fn = fn
    end
-----------------------------------------------------------------------------------------------------------------------------------------















-----------------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_skin_data:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_skin_data:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_skin_data:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_skin_data:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_skin_data:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return nil or default
    end
    function tbat_com_skin_data:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_com_skin_data:Add(index,num,min,max)
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
    function tbat_com_skin_data:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_skin_data:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_skin_data:OnSave()
        self:ActiveOnSaveFns()
        local data =
        {
            DataTable = self.DataTable
        }
        return next(data) ~= nil and data or nil
    end

    function tbat_com_skin_data:OnLoad(data)
        if data.DataTable then
            self.DataTable = data.DataTable
        end
        self:ActiveOnLoadFns()
        self:SkinAPI__Mirror_Check_For_Onload()
        local skin_name = self:GetCurrent()
        self:SetCurrent(skin_name)
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_skin_data