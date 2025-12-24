--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_osmanthus_cat_pet_house"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_osmanthus_cat_pet_house.zip"),
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
        fx.Light:SetRadius(0.9)
        fx.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
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
        inst.MiniMapEntity:SetIcon("tbat_building_osmanthus_cat_pet_house.tex")
        MakeObstaclePhysics(inst, .5)
        inst.AnimState:SetBank("tbat_building_osmanthus_cat_pet_house")
        inst.AnimState:SetBuild("tbat_building_osmanthus_cat_pet_house")
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
    local cat_prefab = "tbat_animal_osmanthus_cat"
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
        cat:ListenForEvent("death",function()
            inst.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)
        end)
    end
    local function spawn_cat(inst)
        if inst.components.leader:IsBeingFollowedBy(cat_prefab) or inst.components.timer:TimerExists("respawn_cat") then
            return
        end
        local cat = SpawnPrefab(cat_prefab)
        cat.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.components.leader:AddFollower(cat)
        add_cat_events(inst,cat)
    end
    local function cat_onload_checker(inst)
        for cat, v in pairs(inst.components.leader.followers) do
            if cat and cat:IsValid() then
                add_cat_events(inst,cat)
            end
        end
    end
    local function respawn_timer_event(inst,data)
        if data and data.name == "respawn_cat" then
            spawn_cat(inst)
        end
    end
    --------------------------------------------------------------------
    --- 回san光环
        local fallofffn = function()
            return 1
        end
        local aurafn = function()
            return 3
        end
        local function sanityaura_com_install(inst)
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.fallofffn = fallofffn
            inst.components.sanityaura.aurafn = aurafn
        end    
    --------------------------------------------------------------------
    --- 野生房子生成桂花矮树
        local osmanthus_bush_spawn_radius = 10
        local function get_bush_spawn_point(inst)
            local test_radius = osmanthus_bush_spawn_radius
            local ret_points = {}
            local kit_item = SpawnPrefab("tbat_plant_osmanthus_bush_kit")
            while test_radius > 3 do
                local temp_points = TBAT.FNS:GetSurroundPoints({
                    target = inst,
                    range = test_radius,
                    num = test_radius * 8,
                })
                for i, pt in ipairs(temp_points) do 
                    if TheWorld.Map:CanDeployPlantAtPoint(pt,kit_item) then
                        table.insert(ret_points,pt)
                    end
                end
                test_radius = test_radius - 1
            end
            kit_item:Remove()
            if #ret_points == 0 then
                return nil
            end
            return ret_points[math.random(1,#ret_points)]
        end
        local function osmanthus_bush_spawn_fn(inst)
            local x,y,z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, 0, z,osmanthus_bush_spawn_radius, {"tbat_plant_osmanthus_bush"})
            if #ents > 0 then
                return
            end
            local pt = get_bush_spawn_point(inst)
            if pt then
                SpawnPrefab("tbat_plant_osmanthus_bush").Transform:SetPosition(pt:Get())
            end
        end
        local function osmanthus_bush_spawn_daily_tast(inst)
            if TheWorld.state.cycles%20 == 0 then
                osmanthus_bush_spawn_fn(inst)
            end
        end
        local function osmanthus_bush_spawner_for_init(inst)
            if not inst.components.tbat_data:Get("bush_spawned") then
                osmanthus_bush_spawn_fn(inst)
                inst.components.tbat_data:Set("bush_spawned",true)
            end
        end
    --------------------------------------------------------------------
    local function wild_house()
        local inst = common_fn()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst:AddComponent("leader")
        inst:DoTaskInTime(1,spawn_cat)
        inst:DoTaskInTime(1,cat_onload_checker)
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone",respawn_timer_event)
        sanityaura_com_install(inst)
        ---- 野生桂花树
        inst:DoTaskInTime(1,osmanthus_bush_spawner_for_init)
        inst:WatchWorldState("cycles",osmanthus_bush_spawn_daily_tast)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 建造出来的
    local function build_house()
        local inst = common_fn()
        TBAT.PET_MODULES:PetHouseComInstall(inst,"tbat_pet_eyebone_osmanthus_cat")
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

