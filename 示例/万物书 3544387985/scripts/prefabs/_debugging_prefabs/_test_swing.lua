--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    -- local inst = TheSim:FindFirstEntityWithTag("tbat_debug_swing")
    -- -- inst.AnimState:ClearOverrideSymbol("slot")
    -- -- inst.AnimState:ClearAllOverrideSymbols()
    -- inst.AnimState:OverrideSymbol("slot","tbat_debug_swing","empty")
    -- if inst.player then
    --     inst.player:Remove()
    -- end
    -- local player = SpawnPrefab("shadowworker")
    -- player.entity:SetParent(inst.entity)
    -- player.entity:AddFollower()
    -- -- player.Follower:FollowSymbol(inst.GUID, "slot",0,80,0,true)
    -- player.Follower:FollowSymbol(inst.GUID, "slot",0,22,0,true)
    -- -- player.Transform:SetTwoFaced()
    -- player.sg:Stop()
    -- player:StopBrain()

    -- if player.components.skinner == nil then
    --     player:AddComponent("skinner")
    -- end
    -- player.components.skinner:CopySkinsFromPlayer(ThePlayer)
    -- player.AnimState:SetMultColour(1,1,1,1)

    -- local sit_type = 1
    -- if  sit_type == 1 then
    --     player.Transform:SetNoFaced()
    --     local bank = "wilson_sit_nofaced"
    --     player.AnimState:SetBankAndPlayAnimation(bank, "sit_loop_pre")
    --     player.AnimState:PushAnimation("sit"..tostring(math.random(2)).."_loop")
    -- else
    --     player.Transform:SetNoFaced()
    --     -- local bank = "wilson_sit"
    --     local bank = "wilson_sit_nofaced"

    --     player.AnimState:SetBankAndPlayAnimation(bank, "sit"..tostring(math.random(2)).."_loop", true)
    -- end


    -- inst.player = player








    local player = ThePlayer
        -- if player.Follower == nil then
        --     player.entity:AddFollower()
        -- end
        -- player.Follower:FollowSymbol(inst.GUID, "slot",0,22,0,true)
        -- player.Transform:SetPosition(x,y,z)

        -- player.Transform:SetRotation(90)
        player.Follower:StopFollowing()

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_debug_swing"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_debug_swing.zip"),
    }
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
            chair_set.Follower:FollowSymbol(inst.GUID, "slot",-30,10,0,true)
            inst.chair_set = chair_set
        --------------------------------------------------------------------
        --- 虚拟玩家去坐位置
            doer.components.playercontroller:DoAction(BufferedAction(doer,chair_set, ACTIONS.SITON))
            doer.components.playercontroller:Enable(false)
            doer.components.inventory:Hide()
        --------------------------------------------------------------------
        --- 下发控制事件
            TBAT.FNS:RPC_PushEvent(doer,"player_enter_sit",nil,inst)            
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
            local function leave_set(remove)
                doer.components.playercontroller:Enable(true)
                doer.Follower:StopFollowing()
                doer.components.inventory:Show()
                doer:RemoveTag("debugnoattack")
                doer:RemoveTag("NOCLICK")
                if remove then
                    chair_set:Remove()
                end
            end            
            chair_set:ListenForEvent("newstate",function(_,_table)
                local current_state = _table and _table.statename
                if sit_on_sg[current_state] then                    
                    doer.Follower:FollowSymbol(chair_set.GUID, "slot",0,0,0,true)
                elseif sit_off_sg[current_state] then
                    leave_set(true)
                end
            end,doer)
            chair_set:DoPeriodicTask(0.5,function()
                if doer.sg:HasStateTag("idle") then
                    leave_set(true)
                end
            end)
            chair_set:ListenForEvent("player_cmd_leave",function()
                leave_set(false)
                doer.sg:GoToState("stop_sitting")
                chair_set:Remove()
            end,inst)
        --------------------------------------------------------------------
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.SITON)
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
    local function client_event_install(inst)
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
        inst:ListenForEvent("player_enter_sit",function()
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
        end)
        inst:ListenForEvent("player_cmd_leave.client", function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"player_cmd_leave",nil,inst)    --- 下发控制事件            
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_debug_swing")
        inst.AnimState:SetBuild("tbat_debug_swing")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:OverrideSymbol("slot","tbat_debug_swing","empty")
        inst:AddTag("tbat_debug_swing")
        inst.entity:SetPristine()
        workable_install(inst)
        if not TheNet:IsDedicated() then
            client_event_install(inst)
        end
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
