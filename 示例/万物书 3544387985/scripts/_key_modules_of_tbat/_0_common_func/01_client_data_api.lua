--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 底层读写API
    local data_sheet_index = "tbat_client_side_data" -- 存档数据表索引(文件名)
    local function GetData(index,default)
        local data = {}
        TheSim:GetPersistentString(data_sheet_index, function(load_success, str_data)
            if load_success and str_data then
                local crash_flag,temp_data = pcall(json.decode,str_data)
                if crash_flag then
                    data = temp_data
                end
            end
        end)
        return data[index] or default
    end
    local function SetData(index,value)
        local data = {}
        TheSim:GetPersistentString(data_sheet_index, function(load_success, str_data)
            if load_success and str_data then
                local crash_flag,temp_data = pcall(json.decode,str_data)
                if crash_flag then
                    data = temp_data
                end
            end
        end)
        data[index] = value
        local str = json.encode(data)
        TheSim:SetPersistentString(data_sheet_index, str, false, function()
            print("info tbat_client_side_data SAVED!")
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  客户端数据API
    TBAT.ClientSideData = Class()
    function TBAT.ClientSideData:Set(index,value)
        SetData(index,value)
    end
    function TBAT.ClientSideData:Get(index,default)
        return GetData(index,default)
    end
    ---- 最原始的存档文件
    function TBAT.ClientSideData:PlayerSet(index,value)
        local index_id = ThePlayer and ThePlayer.userid or "no_player"
        local player_data_table = self:Get(index_id,{})
        player_data_table[index] = value
        self:Set(index_id,player_data_table)
    end
    function TBAT.ClientSideData:PlayerGet(index,default)
        local index_id = ThePlayer and ThePlayer.userid or "no_player"
        local player_data_table = self:Get(index_id,{})
        return player_data_table[index] or default
    end
    
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 自由表格读写API
    TBAT.FreeClientSideData = Class()
    function TBAT.FreeClientSideData:Set(sheet,index,value)
        if not (type(sheet) == "string" and type(index) == "string") then
            print("error in TBAT.FreeClientSideData:Set(sheet,index,value)")
            return
        end
        local data = {}
        TheSim:GetPersistentString(sheet, function(load_success, str_data)
            if load_success and str_data then
                local crash_flag,temp_data = pcall(json.decode,str_data)
                if crash_flag then
                    data = temp_data
                end
            end
        end)
        data[index] = value
        local str = json.encode(data)
        TheSim:SetPersistentString(sheet, str, false, function()
            print("info "..sheet.." SAVED!")
        end)
    end
    function TBAT.FreeClientSideData:Get(sheet,index,default)
        if not (type(sheet) == "string" and type(index) == "string") then
            print("error in TBAT.FreeClientSideData:Get(sheet,index,default)")
            return nil
        end
        local data = {}
        TheSim:GetPersistentString(sheet, function(load_success, str_data)
            if load_success and str_data then
                local crash_flag,temp_data = pcall(json.decode,str_data)
                if crash_flag then
                    data = temp_data
                end
            end
        end)
        return data[index] or default
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------