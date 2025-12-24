--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    四叶草鹤雕像

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_four_leaves_clover_crane_lv1"
    ---- 需求
    local REQUIRE_PREFAB = "tbat_material_emerald_feather"
    local REQUIRE_MAX = 5
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_four_leaves_clover_crane_lv1.zip"),
        Asset("ANIM", "anim/tbat_building_four_leaves_clover_crane_lv2.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 灯光+特效
    local function StartLight(inst)
        inst._startlighttask = nil
        inst.Light:Enable(true)
        if inst._staffstar == nil then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
    end
    local function StartFX(inst)
        if inst._fxfront == nil or inst._fxback == nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            y = y - 0.5
            if inst._fxpulse ~= nil then
                inst._fxpulse:Remove()
            end
            inst._fxpulse = SpawnPrefab("positronpulse")
            inst._fxpulse.Transform:SetPosition(x, y, z)

            if inst._fxfront ~= nil then
                inst._fxfront:Remove()
            end
            inst._fxfront = SpawnPrefab("positronbeam_front")
            inst._fxfront.Transform:SetPosition(x, y, z)

            if inst._fxback ~= nil then
                inst._fxback:Remove()
            end
            inst._fxback = SpawnPrefab("positronbeam_back")
            inst._fxback.Transform:SetPosition(x, y, z)
            -- inst._fxback:ListenForEvent("onremove",function()
            --     inst:PushEvent("start_building_swtich")
            -- end)
            if inst._startlighttask ~= nil then
                inst._startlighttask:Cancel()
            end
            inst._startlighttask = inst:DoTaskInTime(3 * FRAMES, StartLight)
        end
        if inst._stoplighttask ~= nil then
            inst._stoplighttask:Cancel()
            inst._stoplighttask = nil
        end
    end    
    local function StopLight(inst)
        inst._stoplighttask = nil
        inst.Light:Enable(false)
        if inst._staffstar == nil then
            inst.AnimState:ClearBloomEffectHandle()
        end
    end
    local function StopFX(inst)
        if inst._fxpulse ~= nil then
            inst._fxpulse:KillFX()
            inst._fxpulse = nil
        end
        if inst._fxfront ~= nil or inst._fxback ~= nil then
            if inst._fxback ~= nil then
                inst._fxfront:KillFX()
                inst._fxfront = nil
            end
            if inst._fxback ~= nil then
                inst._fxback:KillFX()
                inst._fxback = nil
            end
            if inst._stoplighttask ~= nil then
                inst._stoplighttask:Cancel()
            end
            inst._stoplighttask = inst:DoTaskInTime(9 * FRAMES, StopLight)
        end
        if inst._startlighttask ~= nil then
            inst._startlighttask:Cancel()
            inst._startlighttask = nil
        end
    end
    local function start_light_and_fx(inst)
        StartLight(inst)
        StartFX(inst)
    end
    local function stop_light_and_fx(inst)
        StopLight(inst)
        StopFX(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 升级
    local function start_level_up_task(inst)
        inst:AddTag("NOCLICK")
        inst:PushEvent("start_light")
        inst:DoTaskInTime(10,function()
            inst:PushEvent("stop_light")
            SpawnPrefab("halloween_moonpuff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:PushEvent("start_building_swtich")
        end)
    end
    local function building_swtich(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        inst:Remove()
        local new_building = SpawnPrefab("tbat_building_four_leaves_clover_crane_lv2")
        new_building.Transform:SetPosition(x,y,z)
        new_building:PushEvent("force_spawn_child")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)
        if item.prefab == REQUIRE_PREFAB then
            return true
        end
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 时间检查
            if not (TheWorld.state.isnight and TheWorld.state.isfullmoon) then
                return false,"not_full_moon_night"
            end
        --------------------------------------------------
        -- 前置检查、重新触发升级任务
            local current_num = inst.components.tbat_data:Add("item",0)
            if current_num >= REQUIRE_MAX then
                inst:PushEvent("start_level_up_task")
                return false
            end
        --------------------------------------------------
        -- 物品消耗
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            end
        --------------------------------------------------
        --- 
            local current_num = inst.components.tbat_data:Add("item",1,0,REQUIRE_MAX)
            inst.__accepted_num:set(current_num)
        --------------------------------------------------
        ---
            if current_num >= REQUIRE_MAX then
                inst:PushEvent("start_level_up_task")
            end
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.UPGRADE.GENERIC)
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
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onload
    local function init(inst)
        local current_num = inst.components.tbat_data:Add("item",0)
        inst.__accepted_num:set(current_num + 0.1)
        if current_num >= REQUIRE_MAX then
            inst:PushEvent("start_level_up_task")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 名字显示
    local function name_update_fn(inst)
        local building_name = TBAT:GetString2(this_prefab,"name")
        -- local item_name = TBAT:GetString2(REQUIRE_PREFAB,"name")
        local current_num = math.floor(inst.__accepted_num:value())
        local display_str = "\n"..building_name.."\n"
        -- display_str = display_str..item_name.." : "
        display_str = display_str..TBAT:GetString2(this_prefab,"accept_info")
        display_str = display_str .."  :  "..current_num .. " / " .. REQUIRE_MAX
        inst.name = display_str
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁
    local destroy_fn = function(inst,worker)
        -- --- 范围内有玩家没学会，则掉蓝图。
        -- local x,y,z = inst.Transform:GetWorldPosition()
        -- local ents = TheSim:FindEntities(x, 0, z, 20,{"player"})
        -- for k, player in pairs(ents) do
        --     if player and player.components.builder and not player.components.builder:KnowsRecipe(this_prefab) then
        --         inst.components.lootdropper:SpawnLootPrefab("tbat_building_four_leaves_clover_crane_lv1_blueprint2")
        --     end
        -- end
        --- 补充掉落原始物品
        for i = 1, 5, 1 do
            inst.components.lootdropper:SpawnLootPrefab("tbat_material_four_leaves_clover_feather")            
        end
    end
    local destroy_cmd = {
        onfinished = destroy_fn,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building_fn()
        ----------------------------------------------------------
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddNetwork()
            MakeObstaclePhysics(inst, 0.5)
        ----------------------------------------------------------
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            inst.AnimState:SetBank(this_prefab)
            inst.AnimState:SetBuild(this_prefab)
            inst.AnimState:PlayAnimation("idle")
            inst:AddTag("structure")
        ----------------------------------------------------------
        --- 灯光
            inst.entity:AddLight()
            inst.Light:SetRadius(2)
            inst.Light:SetIntensity(.75)
            inst.Light:SetFalloff(.75)
            inst.Light:SetColour(128 / 255, 128 / 255, 255 / 255)
            inst.Light:Enable(false)
        ----------------------------------------------------------
        --- net 
            inst.__accepted_num = net_float(inst.GUID,"__accepted_num","__accepted_num_update")
        ----------------------------------------------------------
            inst.entity:SetPristine()
        ----------------------------------------------------------
        --- 物品接受
            acceptable_com_install(inst)            
        ----------------------------------------------------------
        --- 名字客制化EVENT
            if not TheNet:IsDedicated() then
                inst:ListenForEvent("__accepted_num_update",name_update_fn)
            end
        ----------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ----------------------------------------------------------
        --- 数据储存
            inst:AddComponent("tbat_data")
        ----------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")
        ----------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ----------------------------------------------------------
        --- 可拆毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,20,destroy_cmd)
        ----------------------------------------------------------
        --- 初始化
            inst:DoTaskInTime(0,init)
        ----------------------------------------------------------
        ---
            inst:ListenForEvent("start_light",start_light_and_fx)
            inst:ListenForEvent("stop_light",stop_light_and_fx)
            inst:ListenForEvent("start_level_up_task",start_level_up_task)
            inst:ListenForEvent("start_building_swtich",building_swtich)
        ----------------------------------------------------------
        --- 交互失败            
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("not_full_moon_night",TBAT:GetString2(this_prefab,"not_full_moon_night"))
        ----------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

