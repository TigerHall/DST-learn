--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    蒲公英猫猫的 核心逻辑

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- PARAM
    local MARK_RADIUS = 10
    local MARK_POINTS = 50
    local FLYING_SPEED = 0.7
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 单个飞行蒲公英。
    local function mark_hit_event(inst,doer)
        inst:PushEvent("random_update",{
            target = inst.plant and inst.plant:IsValid() and inst.plant or inst,
            radius = math.random(200,1000)/1000*MARK_RADIUS,
            num = MARK_POINTS
        })
    end
    local function seed_remove_event(inst)
        if inst.mark and inst.mark:IsValid() then
            inst.mark:Remove()
        end
    end
    local function mark_checker_task(inst)
        if inst.seed and inst.seed:IsValid() then

        else
            inst:Remove()
        end
    end
    local function spawn_flying_seed(inst)
        local mark = SpawnPrefab("tbat_plant_dandycat_mark")
        mark.plant = inst
        mark:PushEvent("random_update",{
            target = inst,
            radius = MARK_RADIUS,
            num = MARK_POINTS
        })
        mark:ListenForEvent("HitBy",mark_hit_event)
        local seed = SpawnPrefab("tbat_projectile_dandelion_umbrella")
        seed.Transform:SetPosition(inst.Transform:GetWorldPosition())
        seed:PushEvent("follow",{
            target = mark,
            speed = 3,
        })
        seed.mark = mark
        mark.seed = seed
        mark:DoPeriodicTask(3,mark_checker_task)
        seed:ListenForEvent("onremove",seed_remove_event)
        seed:ListenForEvent("plant_picked_by",function()
            seed:PushEvent("flyout")
        end,inst)
        seed:ListenForEvent("onremove",function()
            seed:PushEvent("flyout")
        end,inst)
        inst.flying_seeds = inst.flying_seeds or {}
        table.insert(inst.flying_seeds,seed)
    end
    local function flying_umbrella_logic(inst)
        inst:ListenForEvent("spawn_single_flying_seed",spawn_flying_seed)
        inst:ListenForEvent("stage_acitve",function(inst,num)
            if num == 2 or num == 3 then
                local max_num = 3
                local current_num = 0
                local need_spawn_num = 0
                local new_table = {}
                for k, v in pairs(inst.flying_seeds or new_table) do
                    if v and v:IsValid() then
                        current_num = current_num + 1
                        table.insert(new_table,v)
                    end
                end
                inst.flying_seeds = new_table
                need_spawn_num = max_num - current_num
                if need_spawn_num > 0 then
                    for i = 1, need_spawn_num, 1 do
                        inst:PushEvent("spawn_single_flying_seed")
                    end
                end
            end
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 伴生水母
    local function jellyfish_minhealth_event(inst)
        if inst.plant and inst.plant:IsValid() then
            inst.plant:PushEvent("jellyfish_death")
        end
    end
    local function spawn_jellyfish(inst)
        if inst.jellyfish and inst.jellyfish:IsValid() then
            return
        end
        local mark = SpawnPrefab("tbat_plant_dandycat_mark")
        mark.plant = inst
        mark:PushEvent("random_update",{
            target = inst,
            radius = MARK_RADIUS,
            num = MARK_POINTS
        })
        mark:ListenForEvent("HitBy",mark_hit_event)
        local jellyfish = SpawnPrefab("tbat_plant_jellyfish")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        -- jellyfish.Transform:SetPosition(inst.Transform:GetWorldPosition())
        jellyfish:PushEvent("flyin",pt)
        jellyfish:PushEvent("follow",{
            target = mark,
            speed = FLYING_SPEED,
        })
        jellyfish.mark = mark
        jellyfish.plant = inst
        jellyfish:ListenForEvent("onremove",seed_remove_event)
        mark.seed = jellyfish
        mark:DoPeriodicTask(3,mark_checker_task)
        jellyfish:ListenForEvent("onremove",function()
            jellyfish:PushEvent("flyout")
        end,inst)
        jellyfish:ListenForEvent("minhealth",jellyfish_minhealth_event)
        inst.jellyfish = jellyfish
    end

    local function jellyfish_init(com_or_inst)
        local inst = com_or_inst
        if com_or_inst.inst then
            inst = com_or_inst.inst
        end
        if inst.components.tbat_data:Get("transplanted") then
            return
        end
        inst:PushEvent("spawn_jellyfish")
    end
    local function jellyfish_death_event(inst)
        inst.components.timer:StartTimer("jellyfish_respawn", TBAT.DEBUGGING and 480 or 3*480)
        print("水母死亡，开始重生计时器",inst)
    end
    local function jellyfish_respawn_time_down_event(inst,cmd)
        if cmd and cmd.name == "jellyfish_respawn" then
            inst:PushEvent("spawn_jellyfish")
        end
    end
    local function item_get(inst,call_back)
        if inst.jellyfish and inst.jellyfish:IsValid() then
            return
        end
        call_back.succeed = true
        inst:PushEvent("spawn_jellyfish")
        inst.components.timer:StopTimer("jellyfish_respawn")
        inst.components.tbat_data:Set("transplanted",false)
    end
    local function spawn_jellyfish_logic(inst)
        -----------------------------------------------------------------
        --- 刷新事件
            inst:ListenForEvent("spawn_jellyfish",spawn_jellyfish)
        -----------------------------------------------------------------
        --- 初始化
            inst.components.tbat_data:AddOnLoadFn(jellyfish_init)
            inst:DoTaskInTime(0,jellyfish_init)
        -----------------------------------------------------------------
        --- 死亡重刷相关
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone",jellyfish_respawn_time_down_event)
        inst:ListenForEvent("jellyfish_death",jellyfish_death_event)
        -----------------------------------------------------------------
        --- 物品获得+回调
            inst:ListenForEvent("bottle_get",item_get)
        -----------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    -- inst:ListenForEvent("stage_acitve",function(inst,num)
    --     print("stage_acitve:",inst,num)
    -- end)
    -- inst:ListenForEvent("grow_to",function(inst,num)
    --     print("grow_to:",inst,num)
    -- end)

    flying_umbrella_logic(inst)
    spawn_jellyfish_logic(inst)
end