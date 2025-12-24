--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数表
    local this_prefab = "tbat_turf_water_lily_cat"
    local DIG_PLAYER_CHECK_RADIUS = 3   --- 检查玩家半径
    local DIG_DISTANCE = 3.2            --- 挖掘距离
    local PICK_DISTANCE = 1             --- 采摘距离
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable install
    local function show_digging_indicator(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if inst.dig_fx and inst.dig_fx:IsValid() then
            inst.dig_fx.time = 0
            local players = TheSim:FindEntities(x,0,z,DIG_PLAYER_CHECK_RADIUS,{"player"},{"playerghost"})            
            local color = {0/255,255/255,0/255}
            if #players > 0 then
                color = {255/255,0/255,0/255}
            end
            inst.dig_fx.AnimState:SetAddColour(color[1],color[2],color[3], 0)
            inst.dig_fx.AnimState:SetMultColour(color[1],color[2],color[3], 1)
        else
            local fx = SpawnPrefab("tbat_sfx_tile_outline")
            fx:PushEvent("Set",{pt = Vector3(x,0,z),})
            local color = {255/255,0/255,0/255}
            fx.AnimState:SetAddColour(color[1],color[2],color[3], 0)
            fx.AnimState:SetMultColour(color[1],color[2],color[3], 1)
            fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            fx.AnimState:SetFinalOffset(1)
            fx.AnimState:SetSortOrder(1)
            inst.dig_fx = fx
            inst.dig_fx.remove_task = inst.dig_fx:DoPeriodicTask(0.1,function(fx)
                fx.time = (fx.time or 0) + 0.1
                if fx.time > 0.2 then
                    fx:Remove()
                end
            end)
        end
    end
    local function is_digging(inst,doer)
        local weapon = doer.replica.combat:GetWeapon()
        if weapon then
            local has_fork = string.find(weapon.prefab, "fork") ~= nil
            if has_fork then
                return true
            end
        end
        return false
    end
    local function workable_test_fn(inst,doer,right_click)
        local replica_com = inst.replica._.tbat_com_workable
        if inst:HasTag("has_fruit") and inst:HasTag("dig_block") then
            replica_com:SetSGAction("dolongaction")
            replica_com:SetDistance(PICK_DISTANCE)
            replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICK.GENERIC)
            return true
        end
        if not inst:HasTag("dig_block") and is_digging(inst,doer) then
            replica_com:SetSGAction("tbat_sg_predig")
            replica_com:SetDistance(DIG_DISTANCE)
            replica_com:SetText(this_prefab,STRINGS.ACTIONS.TERRAFORM)
            if not TheNet:IsDedicated() then
                show_digging_indicator(inst)
            end
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        if inst:HasTag("has_fruit") and inst:HasTag("dig_block") then
            inst.components.growable:SetStage(1)
            inst:PushEvent("start_growing")
            doer.components.inventory:GiveItem(SpawnPrefab("tbat_turf_water_lily_cat_leaf"))
            return true
        end
        if not inst:HasTag("dig_block") and is_digging(inst,doer) then
            local x,y,z = inst.Transform:GetWorldPosition()
            local players = TheSim:FindEntities(x,0,z,DIG_PLAYER_CHECK_RADIUS,{"player"},{"playerghost"})
            if #players > 0 then
                return false,"dig_faild"
            else
                local callback = {}
                inst:PushEvent("remove_plant",callback)
                if callback.success then
                    doer.components.inventory:GiveItem(SpawnPrefab("tbat_turf_water_lily_cat_seed"))
                    return true
                else
                    return false,"dig_faild_cd"    
                end
            end
        end
        return false
    end
    local function workable_init_actions_fn(inst,doer,actions,right_click) -- 清除其他交互动作
        if not right_click then
            local new_actions = {}
            for k, v in pairs(actions) do
                if v ~= ACTIONS.LOOKAT then
                    table.insert(new_actions, v)
                end
                actions[k] = nil
            end
            if #new_actions > 0 then
                for k, v in pairs(new_actions) do
                    table.insert(actions, v)
                end
            end
        end
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        -- replica_com:SetText("6666","7777")
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICK.GENERIC)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetInitActionsFn(workable_init_actions_fn)
        replica_com:SetDistance(PICK_DISTANCE)
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
--- item accept
    local wild_accept_item_prefab = "tbat_plant_coconut_cat_fruit"
    local type_switch_item_prefab = "tbat_turf_water_lily_cat_leaf"
    local function acceptable_test_fn(inst,item,doer,right_click)
        if not inst:HasTag("dig_block") and item.prefab == type_switch_item_prefab and not inst:HasTag("type_switched") then
            inst.replica.tbat_com_acceptable:SetText(this_prefab,STRINGS.CHARACTERS.WARLY.ACTIONFAIL.ACTIVATE.KITCOON_HIDEANDSEEK_NOT_ENOUGH_HIDERS)
            return true
        end
        if inst:HasTag("dig_block") and inst:HasTag("grow_blocking") and item.prefab == wild_accept_item_prefab then
            inst.replica.tbat_com_acceptable:SetText(this_prefab,"    "..STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TALK_TO_PLANTS[1])
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)        
        if inst:HasTag("dig_block") and item.prefab == wild_accept_item_prefab then
            --- 野生的则允许成长
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
            inst:PushEvent("start_growing")
            return true
        end
        if not inst:HasTag("dig_block") and item.prefab == type_switch_item_prefab then
            --- 移植的则直接切换到二阶段  and inst:HasTag("grow_blocking")
            item.components.stackable:Get():Remove()
            inst.components.growable:SetStage(2)
            inst:PushEvent("stop_growing")
            inst:AddTag("type_switched")
            return true
        end
        return false
    end
    local function type_switch_on_save(com)
        if com.inst:HasTag("type_switched") then
            com:Set("type_switched",true)
        end
    end
    local function type_switch_on_load(com)
        if com:Get("type_switched") then
            com.inst:AddTag("type_switched")
        end
    end
    local function acceptable_replica_init(inst,replica_com)
        -- replica_com:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.GENERIC.." "..STRINGS.UI.CRAFTING.RECIPEACTION.GROW)
        -- replica_com:SetText(this_prefab,"    "..STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TALK_TO_PLANTS[1])
        replica_com:SetText(this_prefab,STRINGS.CHARACTERS.WARLY.ACTIONFAIL.ACTIVATE.KITCOON_HIDEANDSEEK_NOT_ENOUGH_HIDERS)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)

        inst.components.tbat_data:AddOnLoadFn(type_switch_on_load)
        inst.components.tbat_data:AddOnSaveFn(type_switch_on_save)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- dig block
    local function dig_block_event(inst,flag)
        if flag then
            inst:AddTag("dig_block")
            inst.components.tbat_data:Set("dig_block",true)
        else
            inst:RemoveTag("dig_block")
            inst.components.tbat_data:Set("dig_block",false)
        end
    end
    local function dig_onload_checker(com)
        local flag = com:Get("dig_block",false)
        dig_block_event(com.inst,flag)
    end
    local function dig_block_event_install(inst)
        inst:ListenForEvent("dig_block",dig_block_event)
        inst.components.tbat_data:AddOnLoadFn(dig_onload_checker)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- plant event
    -------------------------------------------------------------------
    --- 短期内地皮连续移除，会导致崩溃，必须做一个CD控制器。
        local dig_timer = nil
        local dig_count = 0
        local dig_count_max = 1
        local function create_dig_cd_timer(time)
            if dig_timer and dig_timer:IsValid() then
                dig_timer:Remove()
            end
            dig_timer = CreateEntity()
            dig_timer:DoTaskInTime(time or 15,function()
                -- print("可以继续挖了")
                dig_timer:Remove()
            end)
        end
        local function can_be_dig()
            if dig_timer and dig_timer:IsValid() then                
                return false
            end
            dig_count = dig_count + 1
            if dig_count >= dig_count_max then
                dig_count = 0
                create_dig_cd_timer(math.random(2,5))
            end
            return true
        end
    -------------------------------------------------------------------
    --- 种植、移除
        local function can_be_planted(x,y,z)
            -- if TBAT.__can_be_planted then
            --     return TBAT.__can_be_planted(x,y,z)
            -- end
            local center_pt = Vector3(TBAT.MAP:GetTileCenterPoint(x,y,z))
            local points = TBAT.FNS:GetSurroundPoints({
                target = center_pt,
                range = 3,
                num = 10
            })
            for i,pt in ipairs(points) do
                if TheWorld.Map:GetPlatformAtPoint(pt.x,0,pt.z) then
                    return false
                end
            end
            if TheWorld.Map:CanDeployDockAtPoint(center_pt, nil, nil) then
                return true
            end
            -- print("Cannot deploy boat at", x,y,z)
            return false
        end
        local function on_plant_start_grow(inst)
            inst.components.growable:SetStage(1)
            inst:PushEvent("start_growing")
        end
        local function on_plant_stop_grow(inst)
            inst.components.growable:SetStage(1)
            inst:PushEvent("stop_growing")
        end
        local function plant_event_fn(inst,cmd)  --- 种植的时候，记录和删除原始地皮
            --------------------------------------------------------------------------
            --- 参数表
                local target_tile_index = string.upper("tbat_turf_water_lily_cat")
                local pt = cmd.pt
                local stop_grow = cmd.stop_grow
                local dig_block = cmd.dig_block or false
                local only_test = cmd.only_test or false
                local x,y,z = pt.x,0,pt.z
                local tile_type = TBAT.MAP:GetTileIndexAtPoint(x,y,z)
            --------------------------------------------------------------------------
            --- 位置检查、回调、CD
                if tile_type == target_tile_index 
                        or not TheWorld.Map:IsOceanTileAtPoint(x,y,z)
                        or not can_be_planted(x,y,z)
                    then            
                        inst:Remove()
                        cmd.success = false
                    return
                end
                cmd.success = true
                if only_test then
                    inst:Remove()
                    return
                end
                create_dig_cd_timer(10)
            --------------------------------------------------------------------------
            --- 种植
                inst.components.tbat_data:Set("tile_type",tile_type)
                x,y,z = TBAT.MAP:GetTileCenterPoint(x,y,z)
                inst.Transform:SetPosition(x,0,z)        
                TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,target_tile_index)
                if not stop_grow then
                    inst:DoTaskInTime(0,on_plant_start_grow)
                else
                    inst:DoTaskInTime(0,on_plant_stop_grow)
                end
            --------------------------------------------------------------------------
            -- 挖掘
                inst:PushEvent("dig_block",dig_block)
            --------------------------------------------------------------------------
        end
        local function remove_event(inst,callback)  --- 移除恢复
            -------------------------------------------------
            --- 不允许连续挖掘，会导致存档崩溃。
                if not can_be_dig() then
                    callback.success = false
                    return
                else
                    callback.success = true                
                end
            -------------------------------------------------
            --- 挖掘并恢复原始状态
                local tile_type = inst.components.tbat_data:Get("tile_type")
                local current_tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())
                -- print("tile_type66666666+++",tile_type,WORLD_TILES[string.upper("tbat_turf_water_lily_cat")])
                if tile_type and current_tile == WORLD_TILES[string.upper("tbat_turf_water_lily_cat")] then
                    local x,y,z = inst.Transform:GetWorldPosition()
                    -- TheWorld:DoTaskInTime(0,function()
                    -- end)
                    TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,tile_type)
                end
                inst:PushEvent("destory_remove")                
            -------------------------------------------------
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长。
    local function grow_time_by_step(inst,step)
        if TBAT.DEBUGGING then
            return 1.5*TUNING.TOTAL_DAY_TIME
        end
        return 3*TUNING.TOTAL_DAY_TIME
    end
    local growable_stages = {
        {
            name = "step1",     --- 阶段1  刚种下的时候
            time = function(inst) return grow_time_by_step(inst,1) end,
            fn = function(inst)                                                 -- SetStage 的时候执行
                inst:RemoveTag("has_fruit")
                inst:PushEvent("show_cats",false)
            end,      
            growfn = function(inst)
                inst:RemoveTag("has_fruit")
                inst:PushEvent("show_cats",false)
            end,                                                        -- DoGrowth 的时候执行（时间到了）
        },
        {
            name = "step2",     --- 阶段2
            time = function(inst) return grow_time_by_step(inst,2) end,
            fn = function(inst)
                inst:AddTag("has_fruit")
                inst:PushEvent("show_cats",true)
                inst.components.growable:StopGrowing()
            end,
            growfn = function(inst)
                inst:AddTag("has_fruit")
                inst:PushEvent("show_cats",true)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                inst.components.growable:StopGrowing()
            end,
        },            
    }
    local function block_grow_onload(com_or_inst)
        local inst = com_or_inst.inst or com_or_inst
        if inst.components.tbat_data:Get("grow_blocking") == true then
            inst:PushEvent("stop_growing")
        else
            inst:PushEvent("start_growing")
        end
        if inst.components.growable:GetStage() == 2 then
            inst.components.growable:StopGrowing()            
        end
    end
    local function stop_grow_event_insternal(inst)
        inst.components.tbat_data:Set("grow_blocking", true)
        inst.components.growable:StopGrowing()
        inst:AddTag("grow_blocking")
        -- print("stop_grow_event_insternal",inst)
    end
    local function stop_grow_event(inst)
        stop_grow_event_insternal(inst)
    end
    local function allow_grow_event_insternal(inst)
        inst.components.tbat_data:Set("grow_blocking", false)
        inst.components.growable:StartGrowing()
        inst:RemoveTag("grow_blocking")
        -- print("allow_grow_event_insternal",inst)
    end
    local function allow_grow_event(inst)
        allow_grow_event_insternal(inst)
    end
    local function grow_com_install(inst)

        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(1)
        inst.components.growable.loopstages = false
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        -- inst.components.growable:StopGrowing()
        inst.components.growable.magicgrowable = false

        -- inst:AddComponent("simplemagicgrower")  --- 魔法书
        -- inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        inst:DoTaskInTime(0,block_grow_onload)
        inst.components.tbat_data:AddOnLoadFn(block_grow_onload)
        inst:ListenForEvent("stop_growing",stop_grow_event)
        inst:ListenForEvent("start_growing",allow_grow_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检查函数
    local function inspectable_fn(inst,viewer)
        if inst:HasTag("dig_block") then
            return TBAT:GetString2(this_prefab,"wild_inspect_str")
        end
        return TBAT:GetString2(this_prefab,"inspect_str")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 最终函数
    return function(inst)
        -------------------------------------------------
        --- 可交互
            workable_install(inst)
            acceptable_com_install(inst)
        -------------------------------------------------
        if not TheWorld.ismastersim then
            return
        end
        -------------------------------------------------
        --- 屏蔽dig
            dig_block_event_install(inst)
        -------------------------------------------------
        --- 生长
            grow_com_install(inst)
        -------------------------------------------------
        --- 交互失败
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("dig_faild",TBAT:GetString2(this_prefab,"dig_faild"))
            inst.components.tbat_com_action_fail_reason:Add_Reason("dig_faild_cd",TBAT:GetString2(this_prefab,"dig_faild_cd"))
        -------------------------------------------------
        --- 种植、挖除事件
            inst:ListenForEvent("deploy",plant_event_fn)
            inst:ListenForEvent("remove_plant",remove_event)
        -------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
            inst.components.inspectable.getspecialdescription = inspectable_fn
        -------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------