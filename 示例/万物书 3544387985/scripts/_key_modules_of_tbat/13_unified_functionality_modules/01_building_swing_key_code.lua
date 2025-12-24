--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    秋千用的核心模块

    利用workable。具体示例在  scripts\prefabs\_debugging_prefabs\_test_swing.lua

    inst:PushEvent("player_stop_sitting",doer)    ---- 发送【玩家坐稳了】事件。

    inst:PushEvent("player_sit_on",doer)    ---- 发送【玩家坐稳了】事件。


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 交互并坐上去
    local function workable_test_fn(inst,doer,right_click)
        return true
    end
    local function workable_on_work_fn(inst,doer)
        if inst.chair_set and inst.chair_set:IsValid() then
            return true
        end
        --------------------------------------------------------------------
        --- 清除战斗目标
            local x,y,z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x,0, z, 40, {"_combat"})
            for k,tempInst in pairs(ents) do
                if tempInst.components.combat and tempInst.components.combat.target ~= nil then
                    tempInst.components.combat:DropTarget(false)
                    tempInst.components.combat:SetTarget(nil)
                end
            end
        --------------------------------------------------------------------
        ---
            if doer.Follower == nil then
                doer.entity:AddFollower()
            end
        --------------------------------------------------------------------
        --- 创建虚拟座椅
            local chair_set = SpawnPrefab("tbat_other_chair_set")
            chair_set.AnimState:OverrideSymbol("slot","tbat_other_chair_set","empty")
            chair_set.entity:SetParent(inst.entity)
            chair_set.entity:AddFollower()
            chair_set.Follower:FollowSymbol(inst.GUID, "slot",inst.chair_offset_x or -30,inst.chair_offset_y or 10,0,true)
            inst.chair_set = chair_set
        --------------------------------------------------------------------
        --- 虚拟玩家去坐位置
            doer.components.playercontroller:RemotePausePrediction(5)
            doer.Follower:FollowSymbol(chair_set.GUID, "slot",0,0,0,true)
            doer.components.playercontroller:DoAction(BufferedAction(doer,chair_set, ACTIONS.SITON))
            doer.components.playercontroller:Enable(false)
            doer.components.inventory:Hide()
            TBAT.FNS:RPC_PushEvent(doer,"player_sit_on.client",nil,chair_set)   -- 通知椅子
        --------------------------------------------------------------------
        --- 下发控制事件
            TBAT.FNS:RPC_PushEvent(doer,"player_enter_sit",nil,inst)
        --------------------------------------------------------------------
        --- 隐藏玩家影子
            doer.DynamicShadow:Enable(false)
        --------------------------------------------------------------------
        --- 状态检测 及离开事件操作。
            local sit_on_sg = {
                ["start_sitting"] = true,
                ["sit_jumpon"] = true,
                ["sitting"] = true,
            }
            local sit_off_sg = {
                ["stop_sitting"] = true,
                ["sit_jumpoff"] = true,
                ["stop_sitting_pst"] = true,
            }
            doer:AddTag("debugnoattack")
            doer:AddTag("NOCLICK")
            doer:AddTag("notarget")
            doer:AddTag("invisible")
            doer:AddTag("noattack")
            local function leave_set(remove)
                if not chair_set:IsValid() then
                    return
                end
                doer.components.playercontroller:Enable(true)
                doer.Follower:StopFollowing()
                doer.components.inventory:Show()
                doer:RemoveTag("debugnoattack")
                doer:RemoveTag("NOCLICK")
                doer:RemoveTag("notarget")
                doer:RemoveTag("invisible")
                doer:RemoveTag("noattack")
                if remove then
                    chair_set:Remove()
                end
                inst:PushEvent("player_stop_sitting",doer)    ---- 发送【玩家坐稳了】事件。
                TBAT.FNS:RPC_PushEvent(doer,"player_stop_sitting.client",nil,inst)
                doer.DynamicShadow:Enable(true) -- 恢复影子显示
            end
            chair_set:ListenForEvent("newstate",function(_,_table)
                local current_state = _table and _table.statename
                if sit_on_sg[current_state] then                    
                    doer.Follower:FollowSymbol(chair_set.GUID, "slot",0,0,0,true)
                    if current_state == "sitting" and not chair_set.on_set_flag then
                        inst:PushEvent("player_sit_on",doer)    ---- 发送【玩家坐稳了】事件。
                        TBAT.FNS:RPC_PushEvent(doer,"player_sit_on.client",nil,inst)    -- 通知本体
                        chair_set.on_set_flag = true
                    end
                elseif sit_off_sg[current_state] then
                    leave_set(true)
                end
            end,doer)
            chair_set:DoPeriodicTask(0.5,function()
                if doer.sg:HasStateTag("idle") then
                    leave_set(true)
                end
            end)
            chair_set:ListenForEvent("player_cmd_leave",function(_,_table)
                local down_vec = _table and _table.down_vec or Vector3(0,0,0)
                leave_set(false)
                doer.sg:GoToState("stop_sitting")
                local x,y,z = doer.Transform:GetWorldPosition()
                doer.components.playercontroller:RemotePausePrediction(5)
                doer.Transform:SetPosition(x+down_vec.x,y+down_vec.y,z+down_vec.z)
                chair_set:Remove()
            end,inst)
            inst:ListenForEvent("onremove",function()
                leave_set(false)
            end)
            inst:ListenForEvent("onremove",function()
                chair_set:Remove()
                inst:PushEvent("player_stop_sitting",doer)    ---- 发送【玩家坐稳了】事件。
            end,doer)
        --------------------------------------------------------------------
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_swing",STRINGS.ACTIONS.SITON)
        replica_com:SetSGAction("tbat_sg_empty_active")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- client event for hook key 。屏蔽玩家控制器后，监听键盘操作，然后上传离开信号。
    local function remove_all_handler(inst)
        inst.key_handlers = inst.key_handlers or {}
        for k, v in pairs(inst.key_handlers) do
            v:Remove()
        end
        inst.key_handlers = {}
    end
    local function add_handler(inst,handler)
        inst.key_handlers = inst.key_handlers or {}
        table.insert(inst.key_handlers,handler)
    end

    local function player_enter_sit_event(inst)
        remove_all_handler(inst)
        add_handler(inst,TheInput:AddKeyHandler(function(key, down)
            if down then
                if TheInput:IsControlPressed(CONTROL_MOVE_LEFT)
                    or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
                    or TheInput:IsControlPressed(CONTROL_MOVE_UP)
                    or TheInput:IsControlPressed(CONTROL_MOVE_DOWN)
                    then
                        -- print("You are moving!")
                        inst:PushEvent("player_cmd_leave.client")
                        remove_all_handler(inst)
                    end
            end
        end))
        -- inst:DoTaskInTime(3,function()
        --     add_handler(inst,TheInput:AddMouseButtonHandler(function()
        --         -- print("You are moving!")
        --         inst:PushEvent("player_cmd_leave.client")
        --         remove_all_handler(inst)
        --     end))
        -- end)
    end
    local function player_cmd_leave_client(inst)
        TBAT.FNS:RPC_PushEvent(ThePlayer,"player_cmd_leave",{
            down_vec = TheCamera:GetDownVec()
        },inst)    --- 上传控制事件        
    end
    local function client_event_install(inst)
        inst:ListenForEvent("player_enter_sit",player_enter_sit_event)
        inst:ListenForEvent("player_cmd_leave.client",player_cmd_leave_client)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 镜头锁定控制相关。
    -- local function remove_event(inst)
    --     TheCamera:SetTarget(TheFocalPoint) -- 镜头还原,不能设置ThePlayer        
    -- end
    -- local function unlock_camera_event(inst)
    --     TheCamera:SetTarget(TheFocalPoint) -- 镜头还原,不能设置ThePlayer
    --     inst:RemoveEventCallback("onremove",remove_event)
    -- end
    -- local function lock_camera_event(inst)
    --     TheCamera:SetTarget(inst)
    --     inst:ListenForEvent("onremove",remove_event)
    -- end
    -- local function chair_be_sitting_event(inst,chair)
    --     -- print("player sit on chair and lock camera",inst,chair)
    --     -- chair:ListenForEvent("onremove",remove_event)
    --     -- lock_camera_event(inst)
    -- end
    -- local function camera_controller_install(inst)
    --     local lock_config = TBAT.CONFIG.SWING_LOCK_CAMERA
    --     if not lock_config then
    --         return
    --     end
    --     -- inst:ListenForEvent("player_sit_on.client",lock_camera_event)
    --     -- inst:ListenForEvent("player_stop_sitting.client",unlock_camera_event)
    --     -- inst:ListenForEvent("player_sit_on_chair_be_sure.client",chair_be_sitting_event) -- 椅子推送来的事件。
    -- end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function TBAT.MODULES:Swing_Install(inst)
    workable_install(inst)
    if not TheNet:IsDedicated() then
        client_event_install(inst)
        -- camera_controller_install(inst)
    end
end