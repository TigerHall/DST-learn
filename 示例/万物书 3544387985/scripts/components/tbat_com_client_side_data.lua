----------------------------------------------------------------------------------------------------------------------------------
--[[

    用来 服务器调取 玩家 客户端这边的数据储存API

    用法： 
        tbat_com_client_side_data:GetByCallback(index,callback_fn)
        callback_fn = function(inst,data)    end

        tbat_com_client_side_data:Set(index,value)


]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_client_side_data = Class(function(self, inst)
    self.inst = inst

    self.task_id = 0

    self.tasks = {}

    inst:ListenForEvent("tbat_com_client_side_data.answer_server_ask_data",function(_,cmd)
        local task_id = cmd.task_id
        local data_str = TBAT.FNS:UnzipJsonStr(cmd.data_str)
        local ret_data = json.decode(data_str)
        if ret_data == "nil" then --- 处理 nil 的问题
            ret_data = nil
        end
        if self.tasks[task_id] then
            self.tasks[task_id](self.inst,ret_data)
            self.tasks[task_id] = nil
        end
    end)

    inst:ListenForEvent("tbat_com_client_side_data.answer_server_ask_sheet_data",function(_,cmd)
        local task_id = cmd.task_id
        local data_str = TBAT.FNS:UnzipJsonStr(cmd.data_str)
        local ret_data = json.decode(data_str)
        if ret_data == "nil" then --- 处理 nil 的问题
            ret_data = nil
        end
        if self.tasks[task_id] then
            self.tasks[task_id](self.inst,ret_data)
            self.tasks[task_id] = nil
        end
    end)

end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
-- RPC
    function tbat_com_client_side_data:GetRPC()
        return self.inst.components.tbat_com_rpc_event
    end
    function tbat_com_client_side_data:GetTaskID()
        self.task_id = self.task_id + 1
        return tostring(self.task_id)
    end
------------------------------------------------------------------------------------------------------------------------------
-- Get / Set
    function tbat_com_client_side_data:GetByCallback(index,callback_fn)
        local task_id = self:GetTaskID()
        self.tasks[task_id] = callback_fn
        self:GetRPC():PushEvent("tbat_com_client_side_data.server_ask_data",{
            task_id = task_id,
            index = index,
        })
    end
    function tbat_com_client_side_data:Set(index,value)
        value = value or "nil" -- 处理nil的问题
        self:GetRPC():PushEvent("tbat_com_client_side_data.server_set_data",{
            index = index,
            value_str = json.encode(value),
        })
    end
------------------------------------------------------------------------------------------------------------------------------
--- Sheet API
    function tbat_com_client_side_data:SheetGetByCallback(sheet,index,callback_fn)
        local task_id = self:GetTaskID()
        self.tasks[task_id] = callback_fn
        self:GetRPC():PushEvent("tbat_com_client_side_data.server_ask_sheet_data",{
            task_id = task_id,
            sheet = sheet,
            index = index,                        
        })
    end
    function tbat_com_client_side_data:SheetSet(sheet,index,value)
        value = value or "nil"
        self:GetRPC():PushEvent("tbat_com_client_side_data.server_set_sheet_data",{
            sheet = sheet,
            index = index,
            value_str = json.encode(value),
        })
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_client_side_data







