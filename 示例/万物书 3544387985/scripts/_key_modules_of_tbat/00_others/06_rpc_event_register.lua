--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    注册客户端 <---> 服务端来回传送数据的RPC管道


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




---------------------------------------------------------------------------------------------------------------------------------
---------- RPC 下发 event 事件
-- AddClientModRPCHandler("hutao_rpc_namespace","pushevent.server2client",function(inst,data)
--     -- print("pushevent.server2client")
--     if inst and data then
--         local _table = json.decode(data)
--         if _table and _table.event_name then
--             -- print(_table.event_name)
--             inst:PushEvent(_table.event_name,_table.cmd_table or {})        
--         end
--     end
-- end)
-- -- SendModRPCToClient(CLIENT_MOD_RPC["hutao_rpc_namespace"]["pushevent.server2client"],inst.userid,inst,json.encode(json_data))
-- -- 给 指定userid 的客户端发送RPC


-- ---------- RPC 上传 event 事件
-- AddModRPCHandler("hutao_rpc_namespace", "pushevent.client2server", function(player_inst,inst,event_name,data_json) ----- Register on the server
--     -- user in client : inst.replica.hutao_func:PushEvent("event_name",data)
--     -- 客户端回传 event 给 服务端,player_inst 为来源玩家客户端。
--     if inst and inst.PushEvent and event_name then
--         local data = nil
--         if data_json then
--             data = json.decode(data_json)
--         end
--         inst:PushEvent(event_name,data)
--     end
-- end)
-- -- SendModRPCToServer(MOD_RPC["hutao_rpc_namespace"]["pushevent.client2server"],self.inst,event_name,json.encode(data_table))

---------------------------------------------------------------------------------------------------------------------------------
---- 数据下发 . server to client
    local function pushevent_server2client(player_inst,data_str,tar_inst)
        local replica_com = player_inst.replica.tbat_com_rpc_event or player_inst.replica._.tbat_com_rpc_event
        replica_com:AcitveEventFromServer(data_str,tar_inst)
    end

    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.1",function(player_inst,data_str,tar_inst)
        pushevent_server2client(player_inst,data_str,tar_inst)
    end)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.2",function(player_inst,data_str,tar_inst)
        pushevent_server2client(player_inst,data_str,tar_inst)
    end)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.3",function(player_inst,data_str,tar_inst)
        pushevent_server2client(player_inst,data_str,tar_inst)
    end)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.4",function(player_inst,data_str,tar_inst)
        pushevent_server2client(player_inst,data_str,tar_inst)
    end)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.5",function(player_inst,data_str,tar_inst)
        pushevent_server2client(player_inst,data_str,tar_inst)
    end)

-- SendModRPCToClient(CLIENT_MOD_RPC["tbat_rpc_namespace"]["pushevent.server2client"],inst.userid,inst,json.encode(json_data))

    local function client_cancel_timeout(player_inst,task_id)
        local replica_com = player_inst.replica.tbat_com_rpc_event or player_inst.replica._.tbat_com_rpc_event
        replica_com:CancelTimeout(task_id)        
    end
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.cancel_timeout.1",client_cancel_timeout)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.cancel_timeout.2",client_cancel_timeout)
    AddClientModRPCHandler("tbat_rpc_namespace","pushevent.server2client.cancel_timeout.3",client_cancel_timeout)
---------------------------------------------------------------------------------------------------------------------------------
---- 数据上传

    local function pushevent_client2server(player_inst,data_str,tar_inst)
        player_inst.components.tbat_com_rpc_event:AcitveEventFromClient(data_str,tar_inst)
    end

    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.1", function(player_inst,inst,data_str,tar_inst) ----- Register on the server
        pushevent_client2server(player_inst,data_str,tar_inst)
    end)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.2", function(player_inst,inst,data_str,tar_inst) ----- Register on the server
        pushevent_client2server(player_inst,data_str,tar_inst)
    end)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.3", function(player_inst,inst,data_str,tar_inst) ----- Register on the server
        pushevent_client2server(player_inst,data_str,tar_inst)
    end)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.4", function(player_inst,inst,data_str,tar_inst) ----- Register on the server
        pushevent_client2server(player_inst,data_str,tar_inst)
    end)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.5", function(player_inst,inst,data_str,tar_inst) ----- Register on the server
        pushevent_client2server(player_inst,data_str,tar_inst)
    end)

-- -- SendModRPCToServer(MOD_RPC["tbat_rpc_namespace"]["pushevent.client2server"],self.inst,json.encode(data_table)，tar_inst)
    local function server_cancel_timeout(player_inst,task_id)
        player_inst.components.tbat_com_rpc_event:CancelTimeout(task_id)
    end
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.cancel_timeout.1",server_cancel_timeout)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.cancel_timeout.2",server_cancel_timeout)
    AddModRPCHandler("tbat_rpc_namespace", "pushevent.client2server.cancel_timeout.3",server_cancel_timeout)
---------------------------------------------------------------------------------------------------------------------------------
-- 测试
    if TBAT.DEBUGGING then
        

        local test_event_install = function(inst)
            inst:ListenForEvent("tbat_event.test_acitve_client",function(_,_table)
                print("test_acitve_client",inst)
                if _table then
                    print("+++++++++++++++++")
                    for k, v in pairs(_table) do
                        print(k,v)
                    end
                    print("+++++++++++++++++")
                end
            end)
            if not TheWorld.ismastersim then
                return
            end
            
            inst:ListenForEvent("tbat_event.test_acitve_server",function(_,_table)
                print("test_acitve_server",inst)
                if _table then
                    print("+++++++++++++++++")
                    for k, v in pairs(_table) do
                        print(k,v)
                    end
                    print("+++++++++++++++++")
                end
            end)
        end
        AddPlayerPostInit(test_event_install)
        AddPrefabPostInit("multiplayer_portal",test_event_install)
    end
---------------------------------------------------------------------------------------------------------------------------------
