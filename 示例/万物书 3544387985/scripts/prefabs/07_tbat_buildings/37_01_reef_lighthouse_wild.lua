
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    野外的礁石灯塔

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_reef_lighthouse_wild"
    local cat_prefab = "tbat_animal_stinkray"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_reef_lighthouse.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- water fx 水花特效
    local function create_water_fx(inst)
        -- size : small  med  large
        local size = "med"
        local scale = {1.2,1,1}
        local anim_speed = 0.5
        inst.front_fx = SpawnPrefab("float_fx_front")
        inst.front_fx.AnimState:PlayAnimation("idle_front_" .. size, true)
        inst.front_fx.entity:SetParent(inst.entity)
        inst.front_fx.Transform:SetScale(unpack(scale))
        inst.front_fx.AnimState:SetDeltaTimeMultiplier(anim_speed)
        inst.back_fx = SpawnPrefab("float_fx_back")
        inst.back_fx.AnimState:PlayAnimation("idle_back_" .. size, true)
        inst.back_fx.entity:SetParent(inst.entity)
        inst.back_fx.Transform:SetScale(unpack(scale))
        inst.back_fx.AnimState:SetDeltaTimeMultiplier(anim_speed)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- light
    local function light_on(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        inst.light_fx = inst:SpawnChild("minerhatlight")
        inst.AnimState:Show("LIGHT")
    end
    local function light_off(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
            inst.light_fx = nil
        end
        inst.AnimState:Hide("LIGHT")
    end
    local function light_check(inst)
        if TheWorld:HasTag("cave") or not TheWorld.state.isday then
            light_on(inst)
        else
            light_off(inst)
        end
    end
    local function light_check_delay(inst)
        inst:DoTaskInTime(5,light_check)
    end
    local function light_module_install(inst)
        light_check_delay(inst)
        inst:WatchWorldState("phase",light_check_delay)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 宠物相关
    ------------------------------------------------------------------------
    --- 宠物
        local function add_cat_events(inst,cat)
            if cat:HasTag("house_event_inited_finish") then
                return
            end
            cat.house = inst
            cat:AddTag("house_event_inited_finish")
            cat.__default_check_task = cat:DoPeriodicTask(1,function()
                if cat.components.follower:GetLeader() ~= cat.house then
                    -- cat.components.health:Kill()
                    local x,y,z = cat.Transform:GetWorldPosition()
                    SpawnPrefab("spawn_fx_tiny").Transform:SetPosition(x,y,z)
                    cat:Remove()
                end
            end)
            local function restar_timer()
                cat.__default_check_task:Cancel()
                cat.house.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)                
            end
            cat:ListenForEvent("death",restar_timer)
        end
        local function spawn_cat(inst)
            if inst.components.leader:IsBeingFollowedBy(cat_prefab) or inst.components.timer:TimerExists("respawn_cat") then
                return nil
            end
            local cat = nil
            local cat_record = inst.components.tbat_data:Get("cat_record")
            if cat_record then
                cat = SpawnSaveRecord(cat_record)
                inst.components.tbat_data:Set("cat_record",nil)
            else
                cat = SpawnPrefab(cat_prefab)
            end
            cat.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.components.leader:AddFollower(cat)
            add_cat_events(inst,cat)
            inst.components.timer:StopTimer("respawn_cat")
            return cat
        end
        local function force_spawn_cat(inst)
            inst.components.timer:StopTimer("respawn_cat")
            spawn_cat(inst)
        end
        local function cat_onload_checker(inst)
            for cat, v in pairs(inst.components.leader.followers) do
                if cat and cat:IsValid() then
                    add_cat_events(inst,cat)
                end
            end
        end
    ------------------------------------------------------------------------
    --- 计时器到时间
        local function respawn_timer_event(inst,data)
            if data and data.name == "respawn_cat" then
                spawn_cat(inst)
            end
        end
    ------------------------------------------------------------------------
    --- 被陷阱抓
        local function follower_trapped(inst)
            inst.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)
        end
    ------------------------------------------------------------------------
    --- 回家后触发
        local function onwenthome(inst,data) --- 回家后储存数据，并清除实体。
            local doer = data and data.doer
            if doer then
                local save_record = doer:GetSaveRecord()
                inst.components.tbat_data:Set("cat_record",save_record)
            end
        end
    ------------------------------------------------------------------------
    local function Pet_Com_install(inst)
        inst:AddComponent("tbat_data")
        inst:AddComponent("leader")
        inst:DoTaskInTime(1,spawn_cat)
        inst:DoTaskInTime(1,cat_onload_checker)
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone",respawn_timer_event)
        inst:ListenForEvent("follower_trapped",follower_trapped)        --- 来自 动物 那边。
        inst:ListenForEvent("onwenthome",onwenthome)                    --- 触发回家。
        inst:WatchWorldState("cycles",spawn_cat)
        inst:ListenForEvent("force_spawn_cat",force_spawn_cat)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_reef_lighthouse.tex")
        MakeObstaclePhysics(inst, .8)
        inst.AnimState:SetBank("tbat_building_reef_lighthouse")
        inst.AnimState:SetBuild("tbat_building_reef_lighthouse")
        inst.AnimState:PlayAnimation("idle_water",true)
        inst.AnimState:Hide("LIGHT")
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        inst.entity:SetPristine()
        if not TheNet:IsDedicated() then
            create_water_fx(inst)
        end
        if not TheWorld.ismastersim then
            return inst
        end
        --------------------------------------------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------------------------------------------------
        --- 宠物相关
            Pet_Com_install(inst)
        --------------------------------------------------------------------------------------------------------
        --- 灯光
            light_module_install(inst)
        --------------------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets)