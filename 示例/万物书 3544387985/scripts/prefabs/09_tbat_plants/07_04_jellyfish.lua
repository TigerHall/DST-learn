--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    不做sg了，动画和行动控制 都搅合  在一起。做个简单的控制事件就行了。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_jellyfish"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_jellyfish.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 声音控制
    local function stop_walking_sound(inst)
        inst.SoundEmitter:KillSound("walk")        
    end
    local function play_walking_sound(inst)
        stop_walking_sound(inst)
        -- inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_plant_jellyfish/walk_"..math.random(2),"walk")
        inst.SoundEmitter:PlaySoundWithParams("tbat_sound_stage_1/tbat_plant_jellyfish/walk_"..math.random(2),{
            size = 0.5,
        })
        inst:DoTaskInTime(2,stop_walking_sound)
        -- print("play_walking_sound",inst)
    end    
    local function play_dance_sound(inst)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_plant_jellyfish/onwork_"..math.random(3))
        inst:DoTaskInTime(1.1,function()
            inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_plant_jellyfish/onwork_"..math.random(3))
        end)
    end
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 弹药、碰撞
    local function OnHit(inst, attacker, target)
        inst:PushEvent("OnHit",target)
        target:PushEvent("HitBy",inst)
        inst.pause_time = math.random(2,8)
        inst.AnimState:PlayAnimation("walk_pst",false)
        inst.AnimState:PushAnimation("idle",true)
        -- play_walking_sound(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- stop
    local function StopMoving(inst)
        inst.Physics:SetMotorVel(0,0,0)
        inst.Physics:Stop()
    end
    local function pause_fn(inst,num)
        inst.pause_time = num or 0
        StopMoving(inst)
        if inst.AnimState:IsCurrentAnimation("walk_loop") then
            inst.AnimState:PlayAnimation("walk_pst")
            inst.AnimState:PushAnimation("idle",true)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- start follow event 。移动控制相关。
    local function following_task(inst)
        if not inst.ready then
            inst:Remove()
            return
        end
        if inst:IsAsleep() then
            return
        end
        inst.pause_time = inst.pause_time or 0
        if inst.target and inst.target:IsValid() then
            if inst.pause_time <= 0 and not inst:HasTag("flying") and not inst:HasTag("working") then
                -----------------------------------------------------------------
                -- 移动控制
                    inst.components.projectile:Throw(inst,inst.target,inst.target)
                -----------------------------------------------------------------
                --- 动画控制
                    if inst.AnimState:IsCurrentAnimation("walk_loop") then
                        
                    else
                        inst.AnimState:PlayAnimation("walk_pre",false)
                        inst.AnimState:PushAnimation("walk_loop",true)
                        play_walking_sound(inst)
                    end
                -----------------------------------------------------------------
            else
                inst.pause_time = inst.pause_time - 1
            end
        else
            inst:Remove()
        end
    end
    local function start_following(inst,cmd)
        local target = cmd.target
        if target then
            inst.target = target
        end
        local speed = cmd.speed
        if speed then
            inst.components.projectile:SetSpeed(speed + math.random())
        end
        inst.ready = true
        following_task(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 激活部分事件和动画
    local function attacked_event(inst,_table)
        local old_health_value = _table and _table.old_health
        local new_health_value = _table and _table.val
        if old_health_value and new_health_value and old_health_value > new_health_value then
            StopMoving(inst)
            inst.AnimState:PlayAnimation("hit",false)
            inst.AnimState:PushAnimation("idle",true)
            inst.pause_time = 3
        end
    end
    local function minhealth_event(inst)
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("fx")
        inst:AddTag("working")
        StopMoving(inst)
        inst.AnimState:PlayAnimation("death",false)
        --- animqueueover
        inst:ListenForEvent("animover",function()
            inst.components.lootdropper:SpawnLootPrefab("tbat_material_wish_token")
            inst.components.lootdropper:SpawnLootPrefab("tbat_food_jellyfish")
            inst.AnimState:PlayAnimation("death_idle",false)
            inst:RemoveAllEventCallbacks()
            inst:ListenForEvent("animover",ErodeAway)
            -- ErodeAway(inst)
        end)
    end
    local function dance_fn(inst)
        StopMoving(inst)
        inst.pause_time = 5
        inst.AnimState:PlayAnimation("dance",false)
        inst.AnimState:PushAnimation("dance",false)
        inst.AnimState:PushAnimation("idle",true)
        play_dance_sound(inst)
    end
    local function some_anim_event_install(inst)
        inst:ListenForEvent("pre_health_setval",attacked_event)
        inst:ListenForEvent("death",minhealth_event)
        inst:ListenForEvent("dance",dance_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fly_in_event 。用来处理飞进来
    local function fly_in_animover_event(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if y <= 1 then
            inst.fly_in_task:Cancel()
            inst:RemoveTag("flying")
            inst.pause_time = 3
        end
        inst.Physics:SetMotorVel(0,-3,0)
    end
    local function fly_in_event(inst,pt)
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag("flying")
        inst.Transform:SetPosition(pt.x + math.random(-10,10)/10 , 20 , pt.z+math.random(-10,10)/10)
        inst.Physics:SetMotorVel(0,-3,0)
        inst.fly_in_task = inst:DoPeriodicTask(0.3,fly_in_animover_event)
        play_walking_sound(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fly out event 。用来处理飞走
    local function fly_out_event(inst)
        inst.AnimState:PlayAnimation("flyout",false)
        inst:ListenForEvent("animover",inst.Remove)
        inst:AddTag("flying")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("fx")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- talker install
    local TALLER_TALKER_OFFSET = Vector3(0, -700, 0)
    local DEFAULT_TALKER_OFFSET = Vector3(0, -500, 0)
    local function GetTalkerOffset(inst)
        -- local rider = inst.replica.rider
        -- return (rider ~= nil and rider:IsRiding() or inst:HasTag("playerghost"))
        --     and TALLER_TALKER_OFFSET
        --     or DEFAULT_TALKER_OFFSET
        return DEFAULT_TALKER_OFFSET
    end
    local function kill_talk_sound(inst)
        inst.SoundEmitter:KillSound("talk")
        inst.kill_talk_sound_task = nil
    end
    local function talker_event(inst,str_or_table)
        local str = nil
        if type(str_or_table) == "string" then
            str = str_or_table
        else
            str = str_or_table[math.random(#str_or_table)]
        end
        inst.components.talker:Say(str)
        -- inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_plant_jellyfish/onwork_"..math.random(3),"talk")        
        if inst.kill_talk_sound_task ~= nil then
            inst.kill_talk_sound_task:Cancel()
        end
        inst.kill_talk_sound_task = inst:DoTaskInTime(3,kill_talk_sound)
    end
    local function on_hit_talk(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z,12,{"player"})
        if #ents == 0 then
            inst:PushEvent("talk",TBAT:GetString2(inst.prefab,"random_talk"))
        end
    end
    local function talker_install(inst)
        inst:AddComponent("talker")
        inst.components.talker:SetOffsetFn(GetTalkerOffset)
        if TheWorld.ismastersim then
            inst:ListenForEvent("talk",talker_event)
            inst:ListenForEvent("OnHit",on_hit_talk)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- player close
    local function onnear(inst)
        local player = inst:GetNearestPlayer()
        if player then
            inst:ForceFacePoint(player.Transform:GetWorldPosition())
        end
        inst:PushEvent("talk",TBAT:GetString2(inst.prefab,"player_close"))
        inst:PushEvent("pause",6)
    end
    local function player_close_com_install(inst)
        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(3, 4)
        inst.components.playerprox:SetOnPlayerNear(onnear)
        -- inst.components.playerprox:SetOnPlayerFar(onfar)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 交易核心逻辑
    local main_logic_install = require("prefabs/09_tbat_plants/07_05_jellyfish_item_accept_com")   
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_plant_jellyfish")
        inst.AnimState:SetBuild("tbat_plant_jellyfish")
        inst.AnimState:PlayAnimation("idle",true)
        -- inst.AnimState:SetTime(1.5*math.random())
        -----------------------------------------------------------------
        --- 影子
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(1, 1)
        -----------------------------------------------------------------
        --- 物理参数配置
            MakeInventoryPhysics(inst)
            RemovePhysicsColliders(inst)
        -----------------------------------------------------------------
        --- tag
            inst:AddTag("projectile")
            inst:AddTag("companion")
            inst:AddTag("NOBLOCK")      -- 不会影响种植和放置
        -----------------------------------------------------------------
        ---
            inst.Transform:SetFourFaced()
        -----------------------------------------------------------------
            inst.entity:SetPristine()
        -----------------------------------------------------------------
            talker_install(inst)
            main_logic_install(inst)
        -----------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        -----------------------------------------------------------------
            inst:AddComponent("inspectable")
        -----------------------------------------------------------------
        --- 弹药系统
            -- inst:AddComponent("weapon")
            -- inst.components.weapon:SetDamage(0)
            inst:AddComponent("projectile")
            inst.components.projectile:SetSpeed(20)
            inst.components.projectile:SetHoming(false)
            inst.components.projectile:SetHitDist(1.5)
            inst.components.projectile:SetOnHitFn(OnHit)
        -----------------------------------------------------------------
        ---
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(600)
            inst.components.health:SetCurrentHealth(600)
            inst.components.health.nofadeout = true
            inst:AddComponent("combat")
        -----------------------------------------------------------------
        --- 简易的sg
            inst:ListenForEvent("follow",start_following)
            inst:DoPeriodicTask(1,following_task)
            inst:ListenForEvent("flyout",fly_out_event)
            inst:ListenForEvent("flyin",fly_in_event)
            some_anim_event_install(inst)
            inst:ListenForEvent("pause",pause_fn)
        -----------------------------------------------------------------
        --- 
            inst:AddComponent("lootdropper")
        -----------------------------------------------------------------
        ---
            player_close_com_install(inst)
        -----------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
