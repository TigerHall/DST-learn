----------------------------------------------------------------------------------------------------------------------------------
--[[

    RPC 信道

]]--
----------------------------------------------------------------------------------------------------------------------------------
---
    local task_id = 0
    local function GetTaskID()
        task_id = task_id + 1
        return "task_id_"..task_id
    end
    local ALL_TASK = {}
    local actived_events = {}
    local succeed_callback_fns = {}
    local timeout_callback_fns = {}
----------------------------------------------------------------------------------------------------------------------------------
--- 所有RPC锁
    local RPC_LOCK_1 = false
    local RPC_LOCK_2 = false
    local RPC_LOCK_3 = false
    local RPC_LOCK_4 = false
    local RPC_LOCK_5 = false

    local RPC_FINISH_LOCK_1 = false
    local RPC_FINISH_LOCK_2 = false
    local RPC_FINISH_LOCK_3 = false
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_rpc_event = Class(function(self, inst)
    self.inst = inst

    self.timeout = 2

end)
------------------------------------------------------------------------------------------------------------------------------
--- pushevent
    function tbat_com_rpc_event:PushEvent(event_name,_temp_data,target_inst,succeed_callback,timeout_callback)
        -- print("tbat_com_rpc_event:PushEvent",event_name)
        target_inst = target_inst or self.inst
        -------------------------------------------------------
        --- 客户端即服务端
            if ThePlayer and ThePlayer == self.inst and TheWorld.ismastersim and not TheNet:IsDedicated() then
                self.inst:DoTaskInTime(0.1,function()
                    target_inst:PushEvent(event_name,_temp_data)
                    if succeed_callback then
                        succeed_callback()
                    end
                end)                
                -- print("在客户端、直接触发事件")
                return
            end
        -------------------------------------------------------
        local task_id = GetTaskID()
        _temp_data = _temp_data or {}

        local rpc_data = {
            task_id = task_id,
            event_name = event_name,
            data_str = json.encode(_temp_data),
        }
        local json_str = json.encode(rpc_data)

        self:RPC_Send(target_inst,json_str,task_id)
        succeed_callback_fns[task_id] = succeed_callback
        timeout_callback_fns[task_id] = timeout_callback
    end
------------------------------------------------------------------------------------------------------------------------------
--- rpc send
    function tbat_com_rpc_event:RPC_Send(target_inst,data_str,task_id)
        -- print("RPC_Send",data_str)
        if self.inst.userid == nil then
            print("Error in tbat_com_rpc_event : wrong target",self.inst)
            return
        end
        local function start_timeout_task()
            -- print("RPC-Server timeout task id start",task_id,data_str)
            ALL_TASK[task_id] = self.inst:DoTaskInTime(self.timeout,function()
                -- print("warning : server side tbat_com_rpc_event:RPC_Send timeout")
                ALL_TASK[task_id] = nil
                self:RPC_Send(target_inst,data_str,task_id)
                if timeout_callback_fns[task_id] then
                    timeout_callback_fns[task_id]()
                    timeout_callback_fns[task_id] = nil
                end
            end)
        end

        if not RPC_LOCK_1 then
            RPC_LOCK_1 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.1"],self.inst.userid,self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_LOCK_1 = false
            end)
            start_timeout_task()
            return
        elseif not RPC_LOCK_2 then
            RPC_LOCK_2 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.2"],self.inst.userid,self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_LOCK_2 = false
            end)
            start_timeout_task()
            return
        elseif not RPC_LOCK_3 then
            RPC_LOCK_3 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.3"],self.inst.userid,self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_LOCK_3 = false
            start_timeout_task()
            return
        end)
        elseif not RPC_LOCK_4 then
            RPC_LOCK_4 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.4"],self.inst.userid,self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_LOCK_4 = false
            end)
            start_timeout_task()
            return
        elseif not RPC_LOCK_5 then
            RPC_LOCK_5 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.5"],self.inst.userid,self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_LOCK_5 = false
            end)
            start_timeout_task()
            return
        else
            self.inst:DoTaskInTime(2*FRAMES,function()
                self:RPC_Send(target_inst,data_str,task_id)
            end)
        end

    end
    function tbat_com_rpc_event:CancelTimeout(task_id)
        if ALL_TASK[task_id] then
            ALL_TASK[task_id]:Cancel()
        end
        ALL_TASK[task_id] = nil
        -- print("RPC-Server Event : Send succeed",task_id)
        if succeed_callback_fns[task_id] then
            succeed_callback_fns[task_id]()
            succeed_callback_fns[task_id] = nil
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- AcitveEventFromClient
    function tbat_com_rpc_event:Send_Event_Finished(task_id)
        if type(task_id) ~= "string" then
            return
        end
        if not RPC_FINISH_LOCK_1 then
            RPC_FINISH_LOCK_1 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.cancel_timeout.1"],self.inst.userid,self.inst,task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_FINISH_LOCK_1 = false
            end)
        elseif not RPC_FINISH_LOCK_2 then
            RPC_FINISH_LOCK_2 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.cancel_timeout.2"],self.inst.userid,self.inst,task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_FINISH_LOCK_2 = false
            end)
        elseif not RPC_FINISH_LOCK_3 then
            RPC_FINISH_LOCK_3 = true
            SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client.cancel_timeout.3"],self.inst.userid,self.inst,task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                RPC_FINISH_LOCK_3 = false
            end)
        else
            self.inst:DoTaskInTime(2*FRAMES,function()
                self:Send_Event_Finished(task_id)
            end)
        end        
    end
    function tbat_com_rpc_event:AcitveEventFromClient(data_str,tar_inst)
        local data = json.decode(data_str)
        data.event_data = json.decode(data.data_str)
        -- print("tbat_com_rpc_event:AcitveEventFromClient",data_str,tar_inst)
        local task_id = data.task_id
        local event_name = data.event_name
        if actived_events[task_id] == nil then
            tar_inst:PushEvent(event_name,data.event_data)
        end
        self:Send_Event_Finished(task_id)
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_rpc_event:BroadcastEvent(event_name,event_data,target_inst)
        if self.inst ~= TheWorld then
            print(" TBAT ERROR IN tbat_com_rpc_event:BroadcastEvent",self.inst,event_name,target_inst)
            return
        end
        for k, player in pairs(AllPlayers) do
            player.components.tbat_com_rpc_event:PushEvent(event_name,event_data,target_inst)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_rpc_event







