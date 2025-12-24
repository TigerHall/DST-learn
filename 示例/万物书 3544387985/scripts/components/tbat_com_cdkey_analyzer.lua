----------------------------------------------------------------------------------------------------------------------------------
--[[

    cdkey 解析器

]]--
----------------------------------------------------------------------------------------------------------------------------------
---
    -- 手动实现按位异或（bxor）
    local function bxor(a, b)
        local result = 0
        local bit = 1
        while a > 0 or b > 0 do
            local bitA = a % 2
            local bitB = b % 2
            if bitA ~= bitB then
                result = result + bit
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            bit = bit * 2
        end
        return result
    end
    -- 字符集和密钥
    local chars = "KLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    local key = 0x13
    local char_to_index = {}
    -- 构建字符到索引的映射
    for i = 1, #chars do
        char_to_index[string.byte(chars, i)] = i - 1
    end
    -- 解码函数
    local function _decode(encoded)
        local result = {}
        for i = 1, #encoded, 2 do
            local c1 = string.byte(encoded, i)
            local c2 = string.byte(encoded, i + 1)
            local v1 = char_to_index[c1]
            local v2 = char_to_index[c2]
            if v1 == nil or v2 == nil then
                print("Invalid character in encoded string")
                return nil
            end
            local byte = v1 * 94 + v2
            byte = bxor(byte, key) % 256  -- 使用自定义 bxor 替代 ~
            table.insert(result, string.char(byte))
        end
        return table.concat(result)
    end

    local function decode_with_userid(userid, encoded)
        local decoded = _decode(encoded)
        if not decoded then return nil end
        local parts = {}
        for part in string.gmatch(decoded, "([^:]+)") do
            table.insert(parts, part)
        end
        if parts[2] ~= userid then
            print("Invalid userid in CDKEY")
            return nil
        end
        return parts[3]
    end

----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_cdkey_analyzer = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
    self.TempTable = {}
    self._onload_fns = {}
    self._onsave_fns = {}
    ----------------------------------------------------------------------------
    ---- 来自输入框
        inst:ListenForEvent("tbat_event.cdkey_input",function(inst,cdkey)
            self:InputCDKEY(cdkey)
        end)
        inst:ListenForEvent("tbat_event.cdkey_input_debug",function(inst,_table)
            local userid = _table.userid
            local cdkey = _table.cdkey
            local ret = decode_with_userid(userid,cdkey)
            print("[TBAT DEBUG]CDKEY 解析结果:",ret)
            TheNet:Announce("[TBAT]CDKEY 测试解析结果:  "..ret)
        end)
    ----------------------------------------------------------------------------
    ---
        inst:DoTaskInTime(1,function()
            self:Init()
        end)
    ----------------------------------------------------------------------------
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
---
    local function refresh_skins_index_with_valid(data)  --- 洗掉改名的
        local new_table = {}
        for temp_skin_name,flag in ipairs(data) do
            if TBAT.SKIN.SKINS_DATA_SKINS[temp_skin_name] or PrefabExists(temp_skin_name) then
                new_table[temp_skin_name] = flag
            end
        end
        return new_table
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_cdkey_analyzer:InputCDKEY(cdkey)
        local inst = self.inst
        local flag ,skin_name = pcall(decode_with_userid,inst.userid,cdkey)
        if not flag or type(skin_name) ~= "string" then
            return
        end
        local need_2_sync_skin_data = false
        local cdkey_unlock_result = nil
        if TBAT.DEBUGGING then
            print("[TBAT]CDKEY 解析结果:",skin_name)
        end
        if PrefabExists(skin_name) then
            --- chracter skin
            need_2_sync_skin_data = true
            cdkey_unlock_result = skin_name
            if TBAT.DEBUGGING then
                TheNet:Announce("TBAT : 检测到解锁的皮肤和物品代码一致,"..skin_name)
                print("[TBAT]CDKEY skin name is the same of prefab name:",skin_name)
            end
        elseif TBAT.SKIN.SKINS_DATA_SKINS[skin_name] then
            --- item/building skin
            need_2_sync_skin_data = true
            if not inst.components.tbat_com_skins_controller:HasSkin(skin_name) then
                inst.components.tbat_com_skins_controller:UnlockSkin(skin_name)
            end
            cdkey_unlock_result = skin_name
        elseif TBAT.SKIN.SKIN_PACK:IsPack(skin_name) then
            local pack_data = TBAT.SKIN.SKIN_PACK:GetPacked(skin_name)
            need_2_sync_skin_data = true
            cdkey_unlock_result = {}
            for _,temp_skin_name in ipairs(pack_data) do
                if not inst.components.tbat_com_skins_controller:HasSkin(temp_skin_name) then
                    inst.components.tbat_com_skins_controller:UnlockSkin(temp_skin_name)
                end
                table.insert(cdkey_unlock_result,temp_skin_name)
            end
        end
        if need_2_sync_skin_data then
            if type(cdkey_unlock_result) == "string" then
                ------------------------------------------------------------------------------------
                --- 解锁单个皮肤
                    local annouce_data = {
                        skin_name = skin_name,
                        is_player_skin = PrefabExists(skin_name),
                    }
                    local annouce_data_zipped = TBAT.FNS:ZipJsonStr(json.encode(annouce_data))
                    inst.components.tbat_com_rpc_event:PushEvent("tbat_event.skin_unlock_announce",annouce_data_zipped)
                    inst.components.tbat_com_client_side_data:GetByCallback("unlocked_skins",function(inst,data)
                        data = data or {}
                        if not data[skin_name] then
                            data[skin_name] = true
                        end
                        data = refresh_skins_index_with_valid(data)
                        inst.components.tbat_com_client_side_data:Set("unlocked_skins",data)
                        inst.components.tbat_com_cdkey_analyzer:Set("unlocked_skins",data)
                        -- inst.components.tbat_com_rpc_event:PushEvent("tbat_event.inspect_hud_force_close")
                        -- inst:DoTaskInTime(1,function()
                        --     inst.components.tbat_com_rpc_event:PushEvent("tbat_event.refresh_cdkey_page")                    
                        -- end)
                    end)
                ------------------------------------------------------------------------------------
            elseif type(cdkey_unlock_result) == "table" then
                ------------------------------------------------------------------------------------
                --- 解锁皮肤包声明
                    local annouce_data = {
                        skin_name = skin_name,
                        is_pack = true,
                        list = cdkey_unlock_result,
                    }
                    local annouce_data_zipped = TBAT.FNS:ZipJsonStr(json.encode(annouce_data))
                    inst.components.tbat_com_rpc_event:PushEvent("tbat_event.skin_unlock_announce",annouce_data_zipped)
                ------------------------------------------------------------------------------------
                --- 同步数据
                    inst.components.tbat_com_client_side_data:GetByCallback("unlocked_skins",function(inst,data)
                        data = data or {}
                        for _,temp_skin_name in ipairs(cdkey_unlock_result) do
                            if not data[temp_skin_name] then
                                data[temp_skin_name] = true
                            end
                        end
                        data = refresh_skins_index_with_valid(data)
                        inst.components.tbat_com_client_side_data:Set("unlocked_skins",data)
                        inst.components.tbat_com_cdkey_analyzer:Set("unlocked_skins",data)                        
                    end)
                ------------------------------------------------------------------------------------
            end                            
        end
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_cdkey_analyzer:UnlockSkin(skin_name)
        local skin_data = self:Get("unlocked_skins",{})
        skin_data[skin_name] = true
        self:Set("unlocked_skins",skin_data)
    end
    function tbat_com_cdkey_analyzer:IsSkinUnlocked(skin_name)
        local skin_data = self:Get("unlocked_skins",{})
        return skin_data[skin_name] or false
    end
    function tbat_com_cdkey_analyzer:Init()
        self.inst.components.tbat_com_client_side_data:GetByCallback("unlocked_skins",function(inst,data)
            data = data or {}
            local skin_data = self:Get("unlocked_skins",{})
            for skin_name, v in pairs(skin_data) do
                data[skin_name] = true
            end
            for skin_name, v in pairs(data) do
                skin_data[skin_name] = true
            end
            skin_data = refresh_skins_index_with_valid(skin_data)
            self:Set("unlocked_skins",skin_data)
            inst.components.tbat_com_client_side_data:Set("unlocked_skins",skin_data)
            ----------------------------------------------------
            --- 初始化解锁prefab皮肤
                for skin_name, v in pairs(skin_data) do
                    if PrefabExists(skin_name) then
                        --- chracter skin
                    elseif TBAT.SKIN.SKINS_DATA_SKINS[skin_name] then
                        --- item/building skin
                        if not inst.components.tbat_com_skins_controller:HasSkin(skin_name) then
                            inst.components.tbat_com_skins_controller:UnlockSkin(skin_name)
                        end
                    end
                end
            ----------------------------------------------------
        end)
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_cdkey_analyzer:DebugDecode(userid,cdkey)
        return decode_with_userid(userid,cdkey)
    end
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_cdkey_analyzer:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_cdkey_analyzer:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_cdkey_analyzer:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_cdkey_analyzer:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存

    function tbat_com_cdkey_analyzer:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return default
    end
    function tbat_com_cdkey_analyzer:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_com_cdkey_analyzer:Add(index,num,min,max)
        if index then
            if max == nil and min == nil then
                self.DataTable[index] = (self.DataTable[index] or 0) + ( num or 0 )
                return self.DataTable[index]
            elseif type(max) == "number" and type(min) == "number" then
                self.DataTable[index] = math.clamp( (self.DataTable[index] or 0) + ( num or 0 ) , min , max )
                return self.DataTable[index]
            end                    
        end
        return 0
    end
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_cdkey_analyzer:OnSave()
        self:ActiveOnSaveFns()
        local data =
        {
            DataTable = self.DataTable
        }
        return next(data) ~= nil and data or nil
    end

    function tbat_com_cdkey_analyzer:OnLoad(data)
        if data.DataTable then
            self.DataTable = data.DataTable
        end
        self:ActiveOnLoadFns()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_cdkey_analyzer







