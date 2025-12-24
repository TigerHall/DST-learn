--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    往玩家身上挂的 components 存在 replica 模块的时候，会往玩家身上挂一个 tag。

    这个严重影响了玩家的tag占用。

    本模块用于处理这些情况，致力于减少 tag 的占用。

    该API 用于 replica 文件的头部。 玩家自身一旦初始化完成，则往服务器发送信号。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local cmd_table = {
    -- [inst.GUID] = {
    --     event_fn = nil,
    --     targets_com = {},
    --     client_task = nil,
    -- }
}

local function start_remove_in_server_fn(inst)
    inst:RemoveEventCallback("tbat_event.ReplicaTagRemove",cmd_table[inst.GUID].event_fn)
    local need_to_remove_coms = cmd_table[inst.GUID].targets_com or {}
    for com_name, v in pairs(need_to_remove_coms) do
        local target_tag = "_"..com_name
        inst:TBATAddTag(target_tag)
        inst:RemoveTag(target_tag)
        if TBAT.DEBUGGING then
            print("[TBAT] TBAT:ReplicaTagRemove ",inst,target_tag)
        end
    end
    cmd_table[inst.GUID] = nil
end

function TBAT:ReplicaTagRemove(inst,com_name)
    com_name = string.lower(com_name)
    ---------------------------------------------------
    --- 服务端、添加监听器，和记录要移除哪些
        if TheWorld.ismastersim then
            cmd_table[inst.GUID] = cmd_table[inst.GUID] or {}
            cmd_table[inst.GUID].targets_com = cmd_table[inst.GUID].targets_com or {}
            cmd_table[inst.GUID].targets_com[com_name] = true
            if cmd_table[inst.GUID].event_fn == nil then
                cmd_table[inst.GUID].event_fn = start_remove_in_server_fn
                inst:ListenForEvent("tbat_event.ReplicaTagRemove",start_remove_in_server_fn)
            end
        end
    ---------------------------------------------------
    if not TheNet:IsDedicated() then
        cmd_table[inst.GUID] = cmd_table[inst.GUID] or {}
        if cmd_table[inst.GUID].client_task == nil then
            cmd_table[inst.GUID].client_task = inst:DoPeriodicTask(FRAMES, function()
                local rpc_replia = inst.replica.tbat_com_rpc_event or inst.replica._.tbat_com_rpc_event
                if rpc_replia == nil then
                    return
                end
                rpc_replia:PushEvent("tbat_event.ReplicaTagRemove")
                cmd_table[inst.GUID].client_task:Cancel()
                cmd_table[inst.GUID].client_task = nil
            end)
        end
    end
    ---------------------------------------------------
end