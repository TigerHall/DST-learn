--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    四叶草鹤雕像

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_four_leaves_clover_crane_lv2"
    local pet_prefab = "tbat_animal_four_leaves_clover_crane"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_four_leaves_clover_crane_lv1.zip"),
        Asset("ANIM", "anim/tbat_building_four_leaves_clover_crane_lv2.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_building_four_leaves_clover_crane.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语相关
    --- 密语图标
    TBAT.FNS:AddChatIconData(this_prefab,{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_building_four_leaves_clover_crane",
            build = "tbat_chat_icon_building_four_leaves_clover_crane",
            anim = "lv2",
        },  
    })
    --- 密语API
    local function WhisperTo(inst,player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = this_prefab ,
            sender_name = TBAT:GetString2(this_prefab,"name"),
            s_colour = {158/255,187/255,98/255},
            message = str,
            m_colour = {252/255,246/255,231/255},
        })
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
        for i = 1, 10, 1 do
            inst.components.lootdropper:SpawnLootPrefab("tbat_material_four_leaves_clover_feather")            
        end
    end
    local destroy_cmd = {
        onfinished = destroy_fn,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 触摸奖励
    -- 必定掉落四叶草鹤羽毛*1，5%概率掉落小小鹤草箱蓝图，5%概率掉落四叶草鹤雕像蓝图
    local function touch_succeed_fn(inst,doer)
        TBAT.FNS:GiveItemByPrefab(doer,"tbat_material_four_leaves_clover_feather",1)
        if math.random(10000)/10000 <= 0.05 or TBAT.DEBUGGING then
            TBAT.FNS:GiveItemByPrefab(doer,"tbat_building_four_leaves_clover_crane_lv1_blueprint2",1)
        end
        if math.random(10000)/10000 <= 0.05 or TBAT.DEBUGGING then
            TBAT.FNS:GiveItemByPrefab(doer,"tbat_container_little_crane_bird_blueprint2",1)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 触摸跟随

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 玩家触摸
    local function workable_test_fn(inst,doer,right_click)
        return right_click
    end
    local function workable_on_work_fn(inst,doer)
        ----------------------------------------------------------------------------
        --- 同一天检查
            local player_toch_day = doer.components.tbat_data_to_world:Get("building_four_leaves_clover_crane_touch_day")
            if player_toch_day == TheWorld.state.cycles then
                return false,"touch_same_day"
            end
            doer.components.tbat_data_to_world:Set("building_four_leaves_clover_crane_touch_day",TheWorld.state.cycles)
        ----------------------------------------------------------------------------
        --- 如果玩家 【没有】宠物跟随
            if inst.components.leader:CountFollowers(pet_prefab) > 0 then
                if doer and doer.components.leader:CountFollowers(pet_prefab) == 0 then
                    local all_followers = inst.components.leader.followers
                    local temp_table = {}
                    for pet, flag in pairs(all_followers) do
                        if pet:IsValid() then
                            table.insert(temp_table,pet)
                        end
                    end
                    if #temp_table > 0 then
                        local pet = temp_table[math.random(#temp_table)]
                        inst.components.leader:RemoveFollower(pet)
                        doer.components.leader:AddFollower(pet)
                        SpawnPrefab("halloween_moonpuff").Transform:SetPosition(doer.Transform:GetWorldPosition())
                        --- 通知跟随
                        pet:PushEvent("start_following_player",{
                            doer = doer,
                            building = inst,
                        })
                        inst:WhisperTo(doer,TBAT:GetString2(this_prefab,"touch_succeed_announce"))
                        return false,"take_care_pet"
                    end
                end
            end
        ----------------------------------------------------------------------------
        ---
            touch_succeed_fn(inst,doer)
            inst:WhisperTo(doer,TBAT:GetString2(this_prefab,"touch_succeed_announce"))
        ----------------------------------------------------------------------------
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,TBAT:GetString2(this_prefab,"touch_action"))
        replica_com:SetSGAction("give")
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
--- 创建鹤
    local function spawn_child_event(inst)
        if inst.components.leader:CountFollowers(pet_prefab) < 3 then
            local x,y,z = inst.Transform:GetWorldPosition()
            local pet = SpawnPrefab(pet_prefab)
            pet.Transform:SetPosition(x,1,z)
            SpawnPrefab("halloween_moonpuff").Transform:SetPosition(x,y,z)
            inst.components.leader:AddFollower(pet)            
        end
    end
    local function spawn_child_task(inst)
        spawn_child_event(inst)
    end
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
            inst:AddTag(this_prefab)
        ----------------------------------------------------------
        --- 定型
            inst.entity:SetPristine()
        ----------------------------------------------------------
        --- 触摸
            workable_install(inst)
            inst.WhisperTo = WhisperTo
        ----------------------------------------------------------
        --- ismastersim
            if not TheWorld.ismastersim then
                return inst
            end
        ----------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")            
        ----------------------------------------------------------
        --- 领导者
            inst:AddComponent("leader")
            inst:WatchWorldState("cycles",spawn_child_task)
            inst:ListenForEvent("force_spawn_child",spawn_child_event)
        ----------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ----------------------------------------------------------
        --- 可拆毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5,destroy_cmd)
        ----------------------------------------------------------
        --- 交互失败            
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("touch_same_day",TBAT:GetString2(this_prefab,"touch_same_day"))
            inst.components.tbat_com_action_fail_reason:Add_Reason("take_care_pet",TBAT:GetString2(this_prefab,"take_care_pet"))
        ----------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets)