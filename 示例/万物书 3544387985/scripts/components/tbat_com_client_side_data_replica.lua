----------------------------------------------------------------------------------------------------------------------------------
--[[

    用来 服务器调取 玩家 客户端这边的数据储存API

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_client_side_data = Class(function(self, inst)
    self.inst = inst
    TBAT:ReplicaTagRemove(inst,"tbat_com_client_side_data")

    if not TheNet:IsDedicated() then

        inst:ListenForEvent("tbat_com_client_side_data.server_ask_data",function(_,cmd)
            local task_id = cmd.task_id
            local index = cmd.index
            local ret_data = self:Get(index)

            local cmd_data = {
                task_id = task_id,
                data_str = TBAT.FNS:ZipJsonStr(json.encode(ret_data)),
            }
            self:GetRPC():PushEvent("tbat_com_client_side_data.answer_server_ask_data",cmd_data)

        end)

        inst:ListenForEvent("tbat_com_client_side_data.server_set_data",function(_,cmd)
            local index = cmd.index
            local value_str = cmd.value_str
            local value = json.decode(value_str)
            self:Set(index,value)
        end)

        ------------------------------------------------------------------------------
        --- sheet
            inst:ListenForEvent("tbat_com_client_side_data.server_ask_sheet_data",function(_,cmd)
                local task_id = cmd.task_id
                local sheet = cmd.sheet
                local index = cmd.index
                local ret_data = self:SheetGet(sheet,index)
                local cmd_data = {
                    task_id = task_id,
                    data_str = TBAT.FNS:ZipJsonStr(json.encode(ret_data)),                    
                }
                self:GetRPC():PushEvent("tbat_com_client_side_data.answer_server_ask_sheet_data",cmd_data)
            end)
            inst:ListenForEvent("tbat_com_client_side_data.server_set_sheet_data",function(_,cmd)
                local sheet = cmd.sheet
                local index = cmd.index
                local value_str = cmd.value_str
                local value = json.decode(value_str)
                self:SheetSet(sheet,index,value)
            end)
        ------------------------------------------------------------------------------

    end
end)
------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_com_client_side_data:GetRPC()
        return self.inst.replica._.tbat_com_rpc_event
    end
------------------------------------------------------------------------------------------------------------------------------
-- Get / Set
    function tbat_com_client_side_data:Get(index)
        -- if TBAT:ArchiveHasCave() and TheWorld.ismastersim then
        --     print("Error in tbat_com_client_side_data replica Get")
        --     return nil
        -- end
        if not TheNet:IsDedicated() then
            return TBAT.ClientSideData:PlayerGet(index)
        end
        return nil
    end
    function tbat_com_client_side_data:GetByCallback(index,callback_fn)
        if TheWorld.ismastersim then
            self.inst.components.tbat_com_client_side_data:GetByCallback(index,callback_fn)
            return
        end
        local data = self:Get(index)
        if data == "nil" then -- 处理nil的问题
            data = nil
        end
        callback_fn(self.inst,data)
    end
    function tbat_com_client_side_data:Set(index,value)
        if not TheNet:IsDedicated() then
            TBAT.ClientSideData:PlayerSet(index,value)
            return
        end
        if TheWorld.ismastersim then
            self.inst.components.tbat_com_client_side_data:Set(index,value)
            return
        end
    end

------------------------------------------------------------------------------------------------------------------------------
--- sheet Get / Set
    function tbat_com_client_side_data:SheetGet(sheet,index,default)
        return TBAT.FreeClientSideData:Get(sheet,index,default)
    end
    function tbat_com_client_side_data:SheetSet(sheet,index,value)
        TBAT.FreeClientSideData:Set(sheet,index,value)
    end
    function tbat_com_client_side_data:SheetGetByCallback(sheet,index,callback_fn)
        local data = TBAT.FreeClientSideData:Get(sheet,index)
        callback_fn(self.inst,data)
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_client_side_data







