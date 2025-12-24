-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    API :

        com:HasSkin(skin_name,prefab)  
            input   : skin_name, prefab or nil
            output  : true/false
            注意：prefab 为nil的时候，需要自动补全。

        com:SetSelecting(prefab,skin)
            通过RPC上传当前placer选择的皮肤数据
            数据格式 {  prefab = prefab, skin = skin }


]]--
-----------------------------------------------------------------------------------------------------------------------------------------
local tbat_com_skins_controller = Class(function(self, inst)
    self.inst = inst
    TBAT:ReplicaTagRemove(inst,"tbat_com_skins_controller")
    -- self.DataTable.unlocked_skins = {
    --     [prefab] = {skin_name_1,skin_name_2,skin_name_3}
    -- } 

    self.sync_index = 0

    self.unlocked_skins = {}
    self.unlocked_skins_ids = {}

    inst:ListenForEvent("tbat_com_skins_controller.sync2client",function(inst,data)
        -----------------------------------------------------------------
        --- 
            local sync_index = data and data.sync_index or 0
            if sync_index < self.sync_index then
                print("error : tbat_com_skins_controller_replica :  得到了超时的数据")
                return
            end
            self.sync_index = sync_index
        -----------------------------------------------------------------
        --- 获取一个表格并生成多个表、然后把参数配置到对应位置
            local unlocked_skins_json_str = data and data.skins_data_json_str
            local flag,unlocked_skin_data = pcall(json.decode,unlocked_skins_json_str)
            if flag and type(data) == "table" then                
                self:SetSyncUnlockedData(unlocked_skin_data)
            else
                print("error : tbat_com_skins_controller replica 解析失败")
            end
        -----------------------------------------------------------------
        self:RefreshHUD()
    end)

end)
-----------------------------------------------------------------------------------------------------------------------------------------
--- SetRPCData
    function tbat_com_skins_controller:SetSelecting(prefab,skin)
        local rpc = self.inst.replica.tbat_com_rpc_event
        if rpc then
            rpc:PushEvent("tbat_com_skins_controller.SetSelecting",{
                prefab = prefab,
                skin = skin,
            })
        end
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- RefreshHUD
    function tbat_com_skins_controller:RefreshHUD()
        pcall(function()
            -- inst.HUD.controls --> controls.lua
            -- inst.HUD.controls.craftingmenu -->  craftingmenu_hud.lua 
            -- inst.HUD.controls.craftingmenu.craftingmenu  --> craftingmenu_widget.lua
            -- inst.HUD.controls.craftingmenu.craftingmenu.details_root  --> craftingmenu_details.lua
            -- inst.HUD.controls.craftingmenu.craftingmenu.details_root.skins_spinner  --> craftingmenu_skinselector.lua

            self.inst.HUD.controls.craftingmenu.craftingmenu:Initialize()    --- 初始化 制作栏

            -- self.inst.HUD.controls.craftingmenu.craftingmenu.details_root:refresh()    --- 单个物品的详情页
            
        end)
    end
-----------------------------------------------------------------------------------------------------------------------------------------
---- sync 处理同步来的数据
    function tbat_com_skins_controller:SetSyncUnlockedData(data)
            -- self.DataTable.unlocked_skins = {
            --     [prefab] = {skin_name_1,skin_name_2,skin_name_3}
            -- } 
            -- self.DataTable.unlocked_skins_ids = {
            --     [prefab] = {
            --         [skin_name_1] = 1,
            --         [skin_name_2] = 2,
            --         [skin_name_3] = 3,
            --     }            
            -- }
            -- PREFAB_SKINS[prefab_name] = self.TempData.____PREFAB_SKINS[prefab_name]
            -- PREFAB_SKINS_IDS[prefab_name] = self.TempData.____PREFAB_SKINS_IDS[prefab_name]


        self.unlocked_skins = data
        for prefab, skins in pairs(data) do
            PREFAB_SKINS[prefab] = data[prefab]
            local ids = {}
            for index, skin_name in pairs(skins) do
                ids[skin_name] = index
                -- print("client unlock skin",prefab,skin_name,index)
            end
            self.unlocked_skins_ids[prefab] = ids
            PREFAB_SKINS_IDS[prefab] = ids
            
        end        
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- HasSkin
    function tbat_com_skins_controller:GetPrefabBySkin(skin_name)
        local all_skin_data,all_skin_data_ids = TBAT.SKIN:GET_ALL_SKINS_DATA()
        local skin_data = all_skin_data[tostring(skin_name)]
        if type(skin_data) == "table" then
            local prefab_name = skin_data.prefab_name
            if prefab_name == nil then
                print("error tbat_com_skins_controller_replica:GetPrefabBySkin",skin_name) 
            end
            return prefab_name,skin_data
        end
    end
    function tbat_com_skins_controller:HasSkin(skin_name,prefab)
        self.unlocked_skins = self.unlocked_skins or {}
        prefab = prefab or self:GetPrefabBySkin(skin_name) or "nil"
        local unlocked_prefab_skin_data = self.unlocked_skins[prefab] or {}
        for i, v in ipairs(unlocked_prefab_skin_data) do
            if v == skin_name then
                return true
            end
        end
        return false
    end
-----------------------------------------------------------------------------------------------------------------------------------------
return tbat_com_skins_controller