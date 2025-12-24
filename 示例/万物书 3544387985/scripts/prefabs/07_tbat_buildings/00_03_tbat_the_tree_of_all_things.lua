--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    万物之树

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_the_tree_of_all_things"
    local RADIUS = TBAT.PARAM.THE_TREE_OF_ALL_THINGS_RADIUS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_the_tree_of_all_things.zip"),
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_kit.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 所有特效
    local star_num = 12
    local pet_num = 29
    local cloud_num = 12
    local function create_single_fx(parent,layer)
        local inst = parent:SpawnChild(this_prefab.."_fx")
        inst.entity:AddFollower()
        inst.Follower:FollowSymbol(parent.GUID,layer,0,0,0,true)
        return inst
    end
    local function all_fx_init(inst)
        --------------------------------------------------------
        --- 云
            for i = 1, cloud_num, 1 do
                local layer = "cloud"..i
                inst.AnimState:OverrideSymbol(layer,this_prefab,"empty")
                local fx = create_single_fx(inst,layer)
                fx.AnimState:PlayAnimation("cloud",true)
                if i ~= 1 then
                    fx.AnimState:OverrideSymbol("cloud1",this_prefab,layer)
                end
                fx.AnimState:SetTime(4*math.random())
            end
        --------------------------------------------------------
        --- 星星
            for i = 1, star_num, 1 do
                inst.AnimState:OverrideSymbol("star"..i,this_prefab,"empty")
                local layer = "star"..i
                local fx = create_single_fx(inst,layer)
                fx.AnimState:PlayAnimation(layer,true)
                fx.AnimState:SetTime(4*math.random())
            end
        --------------------------------------------------------
        --- 宠物
            for i = 1, pet_num, 1 do
                inst.AnimState:OverrideSymbol("pet"..i,this_prefab,"empty")
                local layer = "pet"..i
                local fx = create_single_fx(inst,layer)
                fx.AnimState:PlayAnimation(layer,true)
                fx.AnimState:SetTime(4*math.random())
            end
        --------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建NPC 创建绑定的翠玉鸟
    local function CreateNPC(inst)
        -- local x,y,z = inst.Transform:GetWorldPosition()
        -- local npc = SpawnPrefab("tbat_npc_emerald_feather_bird")
        -- npc.Transform:SetPosition(x,y,z+10)
        -- npc:PushEvent("link",inst)
        local points = TBAT.FNS:GetSurroundPoints({
            target = inst,
            range = 12,
            num = 30
        })
        local test_num = 100
        while test_num > 0 do
            local pt = points[math.random(1,#points)]
            if TheWorld.Map:IsPassableAtPoint(pt.x,0,pt.z) and TheWorld.Map:IsAboveGroundAtPoint(pt.x,0,pt.z) then
                local npc = SpawnPrefab("tbat_npc_emerald_feather_bird")
                npc.Transform:SetPosition(pt.x,0,pt.z)
                npc:PushEvent("link",inst)
                return
            end
            test_num = test_num - 1
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- daily task
    local dust_avalable_points = {}
    local function GetDustSpawnPoints(num)
        if #dust_avalable_points >= num then
            return TBAT.FNS:GetRandomDiffrenceValuesFromTable(dust_avalable_points,num)
        end
        local radius = 7
        local delta_r = 1
        while radius > 2 do
            local points = TBAT.FNS:GetSurroundPoints({
                target = Vector3(0,0,0),
                range = radius,
                num = 5*radius
            })
            for k, v in pairs(points) do
                table.insert(dust_avalable_points,v)
            end
            radius = radius - delta_r
        end
        return TBAT.FNS:GetRandomDiffrenceValuesFromTable(dust_avalable_points,num)
    end
    local function daily_spawn_dust_task(inst)
        if inst.components.tbat_data:Get("build") then -- 非野生的不刷新。
            return
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local offset_points = GetDustSpawnPoints(TBAT.DEBUGGING and 3 or math.random(3))
        for i,offset in ipairs(offset_points) do
            local item = SpawnPrefab("tbat_material_starshard_dust")
            item.Transform:SetPosition(x+offset.x,25+math.random(-10,10),z+offset.z)
            -- print("生成星尘",item)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 藤条刷新控制器
    local function vines_spawner_install(inst)
        TheWorld:DoTaskInTime(1,function()
            if inst and inst:IsValid() and not inst.components.tbat_data:Get("build") then
                local fn = require("prefabs/07_tbat_buildings/00_05_main_tree_spawn_vines_logic")
                if type(fn) == "function" then
                    fn(inst)
                end
            end
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function create_hud_radius(inst)
        local tempInst = inst:SpawnChild("tbat_the_tree_of_all_things__area_fx")
        if not inst.components.tbat_data:Get("fireflies") then
            inst.components.tbat_data:Set("fireflies", true)
            tempInst:PushEvent("spawn_ground_fx")
        end
    end
    local function Set_Event(inst,cmd)
        inst.Transform:SetPosition(cmd.pt.x,0,cmd.pt.z)
        if cmd.wild then
            inst.components.tbat_data:Set("wild", true)
            inst.components.tbat_data:Set("build",false)
        else
            inst.components.tbat_data:Set("wild", false)
            inst.components.tbat_data:Set("build",true)
        end
    end
    local function main_init(inst)
        if inst.components.tbat_data:Get("wild") or not inst.components.tbat_data:Get("build") then
            inst:RemoveComponent("workable")
            CreateNPC(inst)
        end
    end
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 2)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_the_tree_of_all_things.tex")

        inst.AnimState:SetBank("tbat_the_tree_of_all_things")
        inst.AnimState:SetBuild("tbat_the_tree_of_all_things")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:HideSymbol("test")

        inst:AddTag("tbat_the_tree_of_all_things")
        inst:AddTag("lightningblocker")
        inst:AddTag("antlion_sinkhole_blocker")
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("tbat_data")
        inst:AddComponent("inspectable")

        inst:AddComponent("prototyper") ---- 靠近触发科技的交易系统
        -- inst.components.prototyper.onturnon = prototyper_onturnon
        -- inst.components.prototyper.onturnoff = prototyper_onturnoff
        -- inst.components.prototyper.onactivate = prototyper_onactivate
        inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES[string.upper(this_prefab)]

        inst:DoTaskInTime(0,create_hud_radius) -- HUD模块加载
        inst:DoTaskInTime(0,main_init)  --- 状态检查 ， 移植的可拆除
        all_fx_init(inst)   -- 小动物所有特效初始化
        inst:ListenForEvent("Set",Set_Event)
        --------------------------------------------------------------------
        --- 拆除功能
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        --------------------------------------------------------------------
        --- 每日刷星辰
        inst:WatchWorldState("cycles",daily_spawn_dust_task)
        --------------------------------------------------------------------
        --- 藤条
            vines_spawner_install(inst)
        --------------------------------------------------------------------
        --- 防雷
            inst:AddComponent("lightningblocker")
            inst.components.lightningblocker:SetBlockRange(RADIUS)
        --------------------------------------------------------------------
        --- 防止野火
            inst:AddComponent("tbat_com_wild_fire_blocker")
            inst.components.tbat_com_wild_fire_blocker:SetRadius(RADIUS)
        --------------------------------------------------------------------
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- fx
    local function fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_the_tree_of_all_things")
        inst.AnimState:SetBuild("tbat_the_tree_of_all_things")
        -- inst.AnimState:PlayAnimation("idle")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -- inst:AddComponent("inspectable")
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- item
    local function on_deploy(inst, pt, deployer)
        SpawnPrefab(this_prefab):PushEvent("Set",{pt = pt,wild = false})
        inst:Remove()
    end
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_the_tree_of_all_things_kit")
        inst.AnimState:SetBuild("tbat_the_tree_of_all_things_kit")
        inst.AnimState:PlayAnimation("idle",true)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst:AddTag("usedeploystring")
        -----------------------------------------------------------------
        --- 影子
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(2.5, 1)
        -----------------------------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------------------------------------------
        ---
        ------------------------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_the_tree_of_all_things","images/map_icons/tbat_the_tree_of_all_things.xml")
        ------------------------------------------------------------------------------
        ---
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------------
        --- 
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable.ondeploy = on_deploy
        ------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- placer
    local function create_debug_cycle(parent)
        local inst = parent:SpawnChild("tbat_sfx_dotted_circle_client")
        inst:PushEvent("Set",{
            radius = RADIUS,
        })
    end
    local function placer_postinit_fn(inst)
        all_fx_init(inst)
        create_debug_cycle(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        Prefab(this_prefab.."_fx", fx, assets),
        Prefab(this_prefab.."_kit", item_fn, assets),
        MakePlacer(this_prefab.."_kit_placer",this_prefab,this_prefab,"idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)
