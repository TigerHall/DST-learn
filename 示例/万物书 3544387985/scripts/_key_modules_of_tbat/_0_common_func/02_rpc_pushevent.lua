

function TBAT.FNS:RPC_PushEvent(player_or_userid,event_name,data,target_inst,succeed_callback,timeout_callback)
    if TheWorld.ismastersim then
        ----------------------------------------------------------------------------------------------------
        --- 服务端，寻找目标玩家。
            local player = nil
            if type(player_or_userid) == "string" then
                player = LookupPlayerInstByUserID(player_or_userid)
            elseif type(player_or_userid) == "table" then
                player = player_or_userid
            end
            if player == nil then
                print("error TBAT.FNS:RPC_PushEvent master : player is nil",player_or_userid,event_name)
                return
            end
            player.components.tbat_com_rpc_event:PushEvent(event_name,data,target_inst,succeed_callback,timeout_callback)
        ----------------------------------------------------------------------------------------------------
    else
        ----------------------------------------------------------------------------------------------------
        --- 客户端，缺省到ThePlayer
            local player = nil
            if ThePlayer then
                if type(player_or_userid) == "string" and ThePlayer.userid == player_or_userid then
                    player = ThePlayer
                elseif ThePlayer ==  player_or_userid then
                    player = ThePlayer
                elseif player_or_userid == nil then
                    player = ThePlayer
                end
            end
            if player == nil then
                print("error TBAT.FNS:RPC_PushEvent not master:",player_or_userid,event_name)
                return
            end
            player.replica.tbat_com_rpc_event:PushEvent(event_name,data,target_inst,succeed_callback,timeout_callback)
        ----------------------------------------------------------------------------------------------------
    end
end
function TBAT.FNS:RPCPushEvent(...)
    self:RPC_PushEvent(...)
end