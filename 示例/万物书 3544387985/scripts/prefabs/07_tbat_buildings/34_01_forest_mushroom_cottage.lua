--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_forest_mushroom_cottage"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_forest_mushroom_cottage.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 灯光控制
    local function light_on(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        local fx = inst:SpawnChild("minerhatlight")
        fx.Light:SetFalloff(0.4)
        fx.Light:SetIntensity(.9)
        fx.Light:SetRadius(1.5)
        fx.Light:SetColour(150 / 255, 255 / 255, 150 / 255)
        inst.light_fx = fx
    end
    local function light_off(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        inst.light_fx = nil
    end
    local function light_checker(inst)
        if not TheWorld.state.isday or TheWorld:HasTag("cave") then
            light_on(inst)
        else
            light_off(inst)
        end
    end
    local function light_checker_delay(inst)
        inst:DoTaskInTime(5,light_checker)
    end
    local function light_install(inst)
        light_checker_delay(inst)
        inst:WatchWorldState("phase",light_checker_delay)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 通用
    local function common_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_forest_mushroom_cottage.tex")
        MakeObstaclePhysics(inst, 1.5)
        inst.AnimState:SetBank("tbat_building_forest_mushroom_cottage")
        inst.AnimState:SetBuild("tbat_building_forest_mushroom_cottage")
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("structure")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        light_install(inst)
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 野生的房子
    ------------------------------------------------------------------------
    --- 物品接受升级
        local acceptable_com_install = require("prefabs/07_tbat_buildings/34_02_wild_house_shop")
    ------------------------------------------------------------------------
    --- 生成动物
        local cat_prefab = "tbat_animal_mushroom_snail"
        local function add_cat_events(inst,cat)
            if cat:HasTag("house_event_inited_finish") then
                return
            end
            cat:AddTag("house_event_inited_finish")
            cat:DoPeriodicTask(1,function()
                if cat.components.follower:GetLeader() ~= inst then
                    cat.components.health:Kill()
                end
            end)
            local function restar_timer()
                inst.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)            
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
    --- 临时指示器，用来给策划布景
        local function temp_tile_indicator_install(inst)
            local points = {}
            for y = -4, 4, 1 do
                for x = -4, 4, 1 do
                    local pt = Vector3(x*4,0,y*4)
                    table.insert(points,pt)
                end
            end
            local mid_pt = Vector3(inst.Transform:GetWorldPosition())
            for k, offset_pt in pairs(points) do
                SpawnPrefab("tbat_sfx_tile_outline"):PushEvent("Set",{
                    pt = mid_pt + offset_pt,
                })
            end
        end
        local function tile_mid_checker(inst)
            local x,y,z = inst.Transform:GetWorldPosition()
            x,y,z = TBAT.MAP:GetTileCenterPoint(x,y,z)
            inst.Transform:SetPosition(x,y,z)
        end
    ------------------------------------------------------------------------
    --- 野外房子本体
        local function wild_house()
            local inst = common_fn()
            inst:AddTag(this_prefab.."_wild")
            -- inst:AddTag("tbat_room_anchor_fantasy_island")--- 临时
            acceptable_com_install(inst)
            ---------------------------------------
            ----
                -- if not TheNet:IsDedicated() then
                --     inst:DoTaskInTime(3,temp_tile_indicator_install)
                -- end
            ---------------------------------------
            ----
                if TheWorld.ismastersim then
                    inst:DoTaskInTime(0,tile_mid_checker)
                end
            ---------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
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
            return inst
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 建造出来的
    local function build_house()
        local inst = common_fn()
        TBAT.PET_MODULES:PetHouseComInstall(inst,"tbat_pet_eyebone_mushroom_snail")
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local function placer_postinit_fn(inst)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, build_house, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
        Prefab(this_prefab.."_wild", wild_house, assets)

