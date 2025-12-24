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
local tbat_com_rpc_event = Class(function(self, inst)
    self.inst = inst
    TBAT:ReplicaTagRemove(inst,"tbat_com_rpc_event")
    self.timeout = 2
end)
------------------------------------------------------------------------------------------------------------------------------
--- pushevent
    function tbat_com_rpc_event:PushEvent(event_name,_temp_data,target_inst,succeed_callback,timeout_callback)
        if self.inst.userid == nil then
            return
        end
        target_inst = target_inst or self.inst
        -------------------------------------------------------
        --- 客户端即服务端。没有洞穴的存档。
            if TheWorld.ismastersim then
                target_inst:DoTaskInTime(0.1,function()
                    target_inst:PushEvent(event_name,_temp_data)
                    if succeed_callback then
                        succeed_callback()
                    end
                end)
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
        
        local function start_timeout_task()
            -- print("RPC-Client timeout task id start",task_id,data_str)
            ALL_TASK[task_id] = self.inst:DoTaskInTime(self.timeout,function()
                -- print("warning : client side tbat_com_rpc_event:RPC_Send timeout")
                ALL_TASK[task_id] = nil
                self:RPC_Send(target_inst,data_str,task_id)
                if timeout_callback_fns[task_id] then
                    timeout_callback_fns[task_id]()
                    timeout_callback_fns[task_id] = nil
                end
            end)
        end

        if not self._lock_1 then
            self._lock_1 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.1"],self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                self._lock_1 = false
            end)
            start_timeout_task()
            return
        elseif not self._lock_2 then
            self._lock_2 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.2"],self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                self._lock_2 = false
            end)
            start_timeout_task()
            return
        elseif not self._lock_3 then
            self._lock_3 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.3"],self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                self._lock_3 = false
            end)
            start_timeout_task()
            return
        elseif not self._lock_4 then
            self._lock_4 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.4"],self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                self._lock_4 = false
            end)
            start_timeout_task()
            return
        elseif not self._lock_5 then
            self._lock_5 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.5"],self.inst,data_str,target_inst)
            self.inst:DoTaskInTime(FRAMES,function()
                self._lock_5 = false
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
        -- print("RPC-Client Event : Send succeed",task_id)
        if succeed_callback_fns[task_id] then
            succeed_callback_fns[task_id]()
            succeed_callback_fns[task_id] = nil
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- 激活event
    function tbat_com_rpc_event:Send_Event_Finished(task_id)
        if type(task_id) ~= "string" then
            return
        end
        if not self._finish_lock_1 then
            self._finish_lock_1 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.cancel_timeout.1"],task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                self._finish_lock_1 = false
            end)
        elseif not self._finish_lock_2 then
            self._finish_lock_2 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.cancel_timeout.2"],task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                self._finish_lock_2 = false
            end)
        elseif not self._finish_lock_3 then
            self._finish_lock_3 = true
            SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server.cancel_timeout.3"],task_id)
            self.inst:DoTaskInTime(FRAMES,function()
                self._finish_lock_3 = false
            end)
        else
            self.inst:DoTaskInTime(2*FRAMES,function()
                self:Send_Event_Finished(task_id)
            end)
        end
        
    end
    function tbat_com_rpc_event:AcitveEventFromServer(data_str,tar_inst)
        -- print("tbat_com_rpc_event_replica:AcitveEventFromServer",data_str)
        local data = json.decode(data_str)
        data.event_data = json.decode(data.data_str)
        local task_id = data.task_id
        local event_name = data.event_name
        if actived_events[task_id] == nil then
            tar_inst:PushEvent(event_name,data.event_data)
            actived_events[task_id] = true
        end
        self:Send_Event_Finished(task_id)
    end
------------------------------------------------------------------------------------------------------------------------------
--- OnPostInit 。套 API 给 玩家自身
    function tbat_com_rpc_event:OnPostInit()
        if self.__api_installed then
            return
        end
        self.__api_installed = true

        self.inst.TBAT_PushEvent = function(inst,event_name,data,target_inst,succeed_callback,timeout_callback)
            if inst.components.tbat_com_rpc_event then
                inst.components.tbat_com_rpc_event:PushEvent(event_name,data,target_inst,succeed_callback,timeout_callback)
            else
                inst.replica.tbat_com_rpc_event:PushEvent(event_name,data,target_inst,succeed_callback,timeout_callback)
            end
        end

    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_rpc_event







