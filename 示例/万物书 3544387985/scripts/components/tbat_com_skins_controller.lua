-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    数据储存在 TheWorld 上，用来彻底解决 角色重选、洞穴穿越 等数据同步问题

    API:
        
        com:GetSkinSelecting()  
            -- 玩家正在选择的皮肤。通过RPC
            返回 ： prefab,skin

        com:HasSkin(skin_name,prefab)  -- 玩家是否有某个皮肤
            input  : skin_name,prefab or nil
            output : true/false
            注意：prefab为缺省的时候，自动扫描补全


]]--
-----------------------------------------------------------------------------------------------------------------------------------------

local tbat_com_skins_controller = Class(function(self, inst)
    self.inst = inst

    self._debug_data_table = {}



    self._onload_fns = {}
    self._onsave_fns = {}
    self._on_post_init_fns = {}


    self.client_prefab_selecting = nil
    self.client_skin_selecting = nil
    inst:ListenForEvent("tbat_com_skins_controller.SetSelecting",function(_,data)
        self.client_prefab_selecting = data and data.prefab
        self.client_skin_selecting = data and data.skin
    end)
    inst:DoTaskInTime(1,function()
        self:Sync2Client()
    end)

end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
--- 数据表的操作
    function tbat_com_skins_controller:GetUnlockedSkinsData()
        --[[
            ---- 这么配置 两个表格，是为了可以正常 上下切换皮肤
            self.DataTable.unlocked_skins = {
                [prefab] = {skin_name_1,skin_name_2,skin_name_3}
            } 
            self.DataTable.unlocked_skins_ids = {
                [prefab] = {
                    [skin_name_1] = 1,
                    [skin_name_2] = 2,
                    [skin_name_3] = 3,
                }            
            }

        ]]--
        return self:Get("unlocked_skins",{}),self:Get("unlocked_skins_ids",{})
    end
    function tbat_com_skins_controller:SetUnlockedData(prefab, skin_name)
        -- 参数类型检查
        if type(prefab) ~= "string" or type(skin_name) ~= "string" then
            return
        end

        -- 获取已解锁皮肤数据
        local skins, skins_ids = self:GetUnlockedSkinsData()
        
        -- 如果该 prefab 尚未初始化，则创建空表
        skins_ids[prefab] = skins_ids[prefab] or {}
        skins[prefab] = skins[prefab] or {}

        -- 检查皮肤是否已存在，避免重复添加
        if skins_ids[prefab][skin_name] then
            return  -- 已存在，无需重复操作
        end

        -- 添加新皮肤到列表末尾（保持顺序）
        table.insert(skins[prefab], skin_name)

        -- 重新生成索引表（按顺序分配索引，从1开始）
        local new_ids = {}
        for i, name in ipairs(skins[prefab]) do
            new_ids[name] = i
        end

        -- 更新数据
        skins_ids[prefab] = new_ids
        self:Set("unlocked_skins", skins)
        self:Set("unlocked_skins_ids", skins_ids)

        self:Sync2Client()
    end
    function tbat_com_skins_controller:RemoveSkinFromPlayer(skin_name, prefab_name)
        -- 参数校验
        if type(skin_name) ~= "string" then
            return
        end
        -- 获取皮肤所属的 prefab（如果未传入）
        if not self:HasSkin(skin_name, prefab_name) then
            return
        end
        -- 如果未指定 prefab_name，则根据 skin_name 推断
        if not prefab_name then
            prefab_name = self:GetPrefabBySkin(skin_name)
            if not prefab_name then
                return
            end
        end
        -- 获取皮肤数据
        local skins, skins_ids = self:GetUnlockedSkinsData()
        local skin_list = skins[prefab_name]
        local skin_ids = skins_ids[prefab_name]
        -- 确保 skin_name 存在于该 prefab 的皮肤列表中
        if not skin_ids[skin_name] then
            return
        end
        -- 创建新的皮肤列表（移除目标皮肤）
        local new_skin_list = {}
        for _, name in ipairs(skin_list) do
            if name ~= skin_name then
                table.insert(new_skin_list, name)
            end
        end
        -- 如果新列表为空，则移除该 prefab 的键
        if #new_skin_list == 0 then
            skins[prefab_name] = nil
            skins_ids[prefab_name] = nil
        else
            -- 更新皮肤列表和索引表
            skins[prefab_name] = new_skin_list
            -- 重新生成索引表（按顺序分配索引，从1开始）
            local new_ids = {}
            for i, name in ipairs(new_skin_list) do
                new_ids[name] = i
            end
            skins_ids[prefab_name] = new_ids
        end
        -- 同步数据到客户端
        self:Set("unlocked_skins", skins)
        self:Set("unlocked_skins_ids", skins_ids)
        self:Sync2Client()
    end
    function tbat_com_skins_controller:GetUnlockedDataByPrefab(prefab)
        local unlocked_skins,unlocked_skins_ids = self:GetUnlockedSkinsData()
        if unlocked_skins[prefab] and unlocked_skins_ids[prefab] then
            return unlocked_skins[prefab],unlocked_skins_ids[prefab]
        end
        return nil,nil
    end
------------------------------------------------------------------------------------------------------------------------------
--- 其他一些测试函数
    function tbat_com_skins_controller:GetAllUnlockedSkinsByPrefab(prefab)
        local new_table = {}
        local skins = self:GetUnlockedDataByPrefab(prefab)
        if skins == nil then
            return new_table
        end
        for k,v in pairs(skins) do
            table.insert(new_table,v)
        end
        return new_table
    end
    function tbat_com_skins_controller:GetAllUnlockedSkins()
        local skins_data = self:GetUnlockedSkinsData()
        local new_table = {}
        for prefab, tmp_data in pairs(skins_data) do
            for k, skin_name in pairs(tmp_data) do
                table.insert(new_table,skin_name)
            end
        end
        return new_table
    end
    function tbat_com_skins_controller:GetAllUnlockedSkinsWithPrefab()
        -- 得到的格式：
        -- unlocked_skins = {
        --     [prefab] = {skin_name_1,skin_name_2,skin_name_3}
        -- } 
        local skins_data = self:GetUnlockedSkinsData()
        local new_table = {}
        for prefab, tmp_data in pairs(skins_data) do
            new_table[prefab] = {}
            for k, skin_name in pairs(tmp_data) do
                table.insert(new_table[prefab],skin_name)
            end
        end
        return new_table
    end
------------------------------------------------------------------------------------------------------------------------------
--- 数据同步
    function tbat_com_skins_controller:Sync2Client()
        if self.___sync_task then
            self.___sync_task:Cancel()
        end
        self.___sync_task = self.inst:DoTaskInTime(math.random(),function()
            -- print("tbat_com_skins_controller:Sync2Client start ")
            self.___sync_task = nil
            local rpc_com = self.inst.components.tbat_com_rpc_event
            if rpc_com == nil then
                print("error : tbat_com_skins_controller  :  rpc_com is nil")
                return
            end
            -----------------------------------------------------------------
            ---
                local unlocked_skins,unlocked_skins_ids = self:GetUnlockedSkinsData()
                self.sync_index = (self.sync_index or 0) + 1
                rpc_com:PushEvent("tbat_com_skins_controller.sync2client",{
                    sync_index = self.sync_index, -- 唯一标识符，用来判断是否是同一个同步请求，避免重发覆盖掉。
                    skins_data_json_str = json.encode(unlocked_skins),
                    
                })
            ----------------------------------------------------------------- 
        end)
    end
    function tbat_com_skins_controller:GetSkinSelecting()
        return self.client_prefab_selecting,self.client_skin_selecting
    end
------------------------------------------------------------------------------------------------------------------------------
--- 获取皮肤数据
    function tbat_com_skins_controller:GetPrefabBySkin(skin_name)
        local all_skin_data,all_skin_data_ids = TBAT.SKIN:GET_ALL_SKINS_DATA()
        local skin_data = all_skin_data[tostring(skin_name)]
        if type(skin_data) == "table" then
            local prefab_name = skin_data.prefab_name
            if prefab_name == nil then
                print("error tbat_com_skins_controller:GetPrefabBySkin",skin_name) 
            end
            return prefab_name,skin_data
        end
    end
    function tbat_com_skins_controller:HasSkin(skin_name,prefab)
        if type(skin_name) ~= "string" then
            return false
        end
        if type(prefab) ~= "string" then
            prefab = self:GetPrefabBySkin(skin_name)
        end
        local prefab_unlocked_data,prefab_unlocked_data_ids = self:GetUnlockedDataByPrefab(prefab)
        if prefab_unlocked_data_ids and prefab_unlocked_data_ids[skin_name] then
            return true
        end
        return false
    end
------------------------------------------------------------------------------------------------------------------------------
--- 解锁操作
    function tbat_com_skins_controller:____Unlock_Skin(cmd_table_or_skin_name)   ----- 解锁皮肤。做多态输入
        -- cmd_table_or_skin_name 可以是皮肤名字
        -- _cmd_table = {
        --     ["prefab_A"] = {"skin_A","skin_B"},
        --     ["prefab_B"] = {"skin_C","Skin_D"},
        --     ["prefab_C"] = "skin_E",
        -- }
        if type(cmd_table_or_skin_name) == "string" then
            --------------------------------------------------------------------------
            --- 皮肤包索引
                local is_pack_index,skins_list = TBAT.SKIN.SKIN_PACK:IsPack(cmd_table_or_skin_name)
                if is_pack_index then
                    for k,skin_name in pairs(skins_list) do
                        self:____Unlock_Skin(skin_name)
                    end
                    return
                end
            --------------------------------------------------------------------------
            --- 单个皮肤解锁
                local prefab_name = self:GetPrefabBySkin(cmd_table_or_skin_name)
                self:SetUnlockedData(prefab_name,cmd_table_or_skin_name)
            --------------------------------------------------------------------------
            --- 处理链接的皮肤
                local skin_data = TBAT.SKIN.SKINS_DATA_SKINS[cmd_table_or_skin_name] or {}
                if skin_data.skin_link and not self:HasSkin(skin_data.skin_link,prefab_name) then
                    self:UnlockSkin(skin_data.skin_link)
                end
            --------------------------------------------------------------------------
            return
        elseif type(cmd_table_or_skin_name) ~= "table" then
            return
        end
        local cmd_table = cmd_table_or_skin_name
        --------------------------------------------------------------------------------------------
        ---- 连携解锁 skin_link 检查和延迟执行
            local need_2_link_unlock_cmd_table = {}
            local need_2_link_unlock_flag = false

            local all_skins_cmd_tables = TBAT.SKIN:GET_ALL_SKINS_DATA() or {}    
            for prefab_name, skin_list_or_str in pairs(cmd_table) do
                if type(skin_list_or_str) == "table" then
                    for k, skin_name in pairs(skin_list_or_str) do
                        local skin_cmd_table = all_skins_cmd_tables[skin_name] or {}
                        if skin_cmd_table.skin_link then
                                    -- print("error : skin link check++",skin_cmd_table.skin_link)
                                    local linked_prefab_name,linked_skin_data = self:GetPrefabBySkin(skin_cmd_table.skin_link)
                                    local linked_skin_name = skin_cmd_table.skin_link
                                    -- print("error : ",linked_prefab_name,linked_skin_name,self:Has_Skin(linked_skin_name,linked_prefab_name))
                                    if not self:HasSkin(linked_skin_name,linked_prefab_name) then
                                        need_2_link_unlock_flag = true
                                        need_2_link_unlock_cmd_table[linked_prefab_name] = need_2_link_unlock_cmd_table[linked_prefab_name] or {}
                                        table.insert(need_2_link_unlock_cmd_table[linked_prefab_name],linked_skin_name)
                                        if TBAT.DEBUGGING then
                                            print("linked unlock",linked_prefab_name,linked_skin_name)
                                        end
                                    end
                        end
                    end
                end
            end

            if need_2_link_unlock_flag then ---- 链路解锁
                self:UnlockSkin(need_2_link_unlock_cmd_table)
            end

        --------------------------------------------------------------------------------------------
        ----- 插入已解锁表格
            for prefab_name, skin_list_or_str in pairs(cmd_table) do
                if type(prefab_name) == "string" then
                    if type(skin_list_or_str) == "table" then
                        for k, skin_name in pairs(skin_list_or_str) do
                            self:SetUnlockedData(prefab_name,skin_name)
                        end
                    elseif type(skin_list_or_str) == "string" then
                        self:SetUnlockedData(prefab_name,skin_list_or_str)
                    end
                            
                end
            end
        --------------------------------------------------------------------------------------------
        ---- 同步数据去客户端和TheWorld
            self:Sync2Client()
        --------------------------------------------------------------------------------------------
    end
    function tbat_com_skins_controller:UnlockSkin(cmd_table)   ------ 延迟一丢丢，避免初始化的时候造成问题。
        self.inst:DoTaskInTime(0.2,function()
            self:____Unlock_Skin(cmd_table)
        end)
    end
------------------------------------------------------------------------------------------------------------------------------
--- 给皮肤切换工具调用
    -- 获取下一个已解锁皮肤（从当前皮肤往后切换）
    function tbat_com_skins_controller:GetNextSkinByCurrent(prefab_name, current_skin)
        local prefab_skin_data, prefab_skin_data_ids = self:GetUnlockedDataByPrefab(prefab_name)        
        if not prefab_skin_data then
            return nil
        end

        local current_index_num = 0
        if current_skin == nil then
            current_index_num = 0
        else
            current_index_num = prefab_skin_data_ids[current_skin] or 1
        end

        local next_index_num = current_index_num + 1

        -- 如果下一个索引超出了皮肤列表范围，返回 nil 和 0（表示默认皮肤）
        if next_index_num > #prefab_skin_data then
            return nil, 0
        else
            return prefab_skin_data[next_index_num], next_index_num
        end
    end

    -- 获取上一个已解锁皮肤（从当前皮肤往前切换）
    function tbat_com_skins_controller:GetPrevSkinByCurrent(prefab, current_skin)
        local prefab_skin_data, prefab_skin_data_ids = self:GetUnlockedDataByPrefab(prefab)
        if not prefab_skin_data then
            return nil
        end
        local current_index_num
        if current_skin == nil then
            -- 当前是默认皮肤（无皮肤），索引为最后一个皮肤之后（用于切换到最后一个皮肤）
            current_index_num = #prefab_skin_data + 1
        else
            -- 获取当前皮肤的索引
            current_index_num = prefab_skin_data_ids[current_skin] or 0
        end
        if current_index_num == nil then
            return nil
        end
        -- 如果当前是默认皮肤（索引超出范围），则返回最后一个皮肤
        if current_index_num > #prefab_skin_data then
            return prefab_skin_data[#prefab_skin_data], #prefab_skin_data
        end
        -- 如果当前是第一个皮肤，返回 nil 和索引 1
        if current_index_num == 1 then
            return nil, 1
        end
        -- 否则返回上一个皮肤
        local prev_index_num = current_index_num - 1
        return prefab_skin_data[prev_index_num], prev_index_num
    end

    function tbat_com_skins_controller:ReskinTarget(target_inst,prev_flag)  --- 给扫把调用
        if target_inst == nil or not target_inst:HasTag("tbat_com_skin_data") then
            return
        end
        local prefab_name = target_inst.prefab
        local current_skin = target_inst.components.tbat_com_skin_data:GetCurrent()
        local next_skin = nil
        if prev_flag then
            next_skin = self:GetPrevSkinByCurrent(prefab_name,current_skin)
        else
            next_skin = self:GetNextSkinByCurrent(prefab_name,current_skin)
        end
        -- print("info :配置目标切换皮肤：",tostring(current_skin).." -> "..tostring(next_skin))
        if next_skin ~= current_skin then
            target_inst.components.tbat_com_skin_data:SetCurrent(next_skin,self.inst)
            target_inst.components.tbat_com_skin_data:OnReskin(self.inst,next_skin)
            
            ----- 发送个event
            target_inst:PushEvent("tbat_event.next_skin",{
                skin_name = next_skin,
                last_skin_name = current_skin,
                doer = self.inst
            })
        end
    end
------------------------------------------------------------------------------------------------------------------------------

















------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_skins_controller:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_skins_controller:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_skins_controller:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_skins_controller:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
---- 同步绑定去TheWorld
    function tbat_com_skins_controller:GetWorldDataIndex()
        local index = "tbat_com_skins_controller.player."..tostring(self.inst.userid)
        return index
    end
    function tbat_com_skins_controller:GetDataTable()
        if TBAT.DEBUGGING then
            return self._debug_data_table
        end
        return TheWorld.components.tbat_data:Get(self:GetWorldDataIndex(),{})
    end
    function tbat_com_skins_controller:SetDataTable(data)
        if TBAT.DEBUGGING then
            self._debug_data_table = data
            return
        end
        TheWorld.components.tbat_data:Set(self:GetWorldDataIndex(),data)
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_skins_controller:Get(index,default)
        if index then
            return self:GetDataTable()[index] or default
        end
        return nil or default
    end
    function tbat_com_skins_controller:Set(index,theData)
        if index then
            local _table = self:GetDataTable()
            _table[index] = theData
            self:SetDataTable(_table)
        end
    end

    function tbat_com_skins_controller:Add(index,num,min,max)
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
    function tbat_com_skins_controller:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
        self:Sync2Client()
    end
    function tbat_com_skins_controller:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- 官方调取的OnSave/OnLoad
    function tbat_com_skins_controller:OnSave()
        self:ActiveOnSaveFns()
        local data =
        {
            -- DataTable = self:GetDataTable(),
            -- _debug_data_table = self._debug_data_table
        }
        -------------------------------------
        -- 
            local _table = self:GetDataTable()
            for k, v in pairs(_table) do
                data[k] = v
            end
        -------------------------------------
        return next(data) ~= nil and data or nil
    end

    function tbat_com_skins_controller:OnLoad(data)
        -- self.inited = true
        -- if data.DataTable then
        --     self:SetDataTable(data.DataTable)
        -- end
        -- if data._debug_data_table then
        --     self._debug_data_table = data._debug_data_table
        -- end
        data  = data or {}
        self:SetDataTable(data)
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_skins_controller
