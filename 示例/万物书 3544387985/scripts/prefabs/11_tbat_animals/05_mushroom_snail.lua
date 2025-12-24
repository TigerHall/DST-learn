--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 素材
    local assets =
    {
        Asset("ANIM", "anim/tbat_animal_mushroom_snail.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_mushroom_snail.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数表
    local SLEEP_DIST_FROMHOME = 1
    local SLEEP_DIST_FROMTHREAT = 20
    local MAX_CHASEAWAY_DIST = 40
    local MAX_TARGET_SHARES = 5
    local SHARE_TARGET_DIST = 40
    local SPAWN_SLIME_VALUE = 6
    local brain = require "brains/06_tbat_animal_mushroom_snail_brain"
    local this_prefab = "tbat_animal_mushroom_snail"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落物
    SetSharedLootTable(this_prefab,
    {
        {"tbat_plant_fluorescent_mushroom_item",             1.00},
        {"tbat_plant_fluorescent_mushroom_item",             1.00},
        {"tbat_plant_fluorescent_moss_item",             1.00},
        {"tbat_plant_fluorescent_moss_item",             1.00},
        {"tbat_sensangu_item", TBAT.DEBUGGING and 1.00 or 0.1 },
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 攻击相关
    local function KeepTarget(inst, target)
        -- if not target:IsValid() then
        --     return false
        -- end
        -- local homePos = inst.components.knownlocations:GetLocation("home")
        -- return homePos ~= nil and target:GetDistanceSqToPoint(homePos) < MAX_CHASEAWAY_DIST * MAX_CHASEAWAY_DIST
        return false
    end

    local function IsSlurtle(dude)
        return dude:HasTag(this_prefab)
    end

    local function Snurtle_OnAttacked(inst, data)
        local attacker = data ~= nil and data.attacker or nil
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsSlurtle, MAX_TARGET_SHARES)
        if attacker and attacker:IsValid() and inst.RememberAttacker then
            inst:RememberAttacker(attacker)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 缩壳相关
    local function RememberAttacker(inst,attacker,time_offset)
        inst.___last_attackers = inst.___last_attackers or {}
        inst.___last_attackers[attacker] = GetTime() + (time_offset or 0)
    end
    local function target_is_death(target)
        if target:HasTag("playerghost") then
            return true
        end
        if target.components.health and target.components.health:IsDead() then
            return true
        end
        return false
    end
    local function IsNearAttackers(inst)
        inst.___last_attackers = inst.___last_attackers or {}
        local new_table = {}
        local is_near_flag = false
        for attacker,time in pairs(inst.___last_attackers) do
            if attacker and attacker:IsValid() then
                if inst:GetDistanceSqToInst(attacker) <= 16     --- 范围接近
                    and  GetTime() - time <= 120                 --- XX 秒内
                    and not target_is_death(attacker)
                    then
                        is_near_flag = true
                end
                new_table[attacker] = time
            end
        end
        inst.___last_attackers = new_table
        return is_near_flag
    end
    local function inventory_damga_shell_fn(inst,damage, attacker, weapon, spdamage)
        -- print("inventory_damga_shell_fn",inst,damage, attacker, weapon, spdamage)
        RememberAttacker(inst,attacker)
        if inst:HasTag("shell") then
            ----------------------------------------------------------------------
            --- 反伤
                local attackrange = inst.components.combat.attackrange
                if attacker and attacker:IsValid() 
                    and attacker.components.combat
                    and attacker.components.health and not attacker.components.health:IsDead()
                    and inst:GetDistanceSqToInst(attacker) <= attackrange*attackrange
                    then
                        if not attacker:HasTag("player") then
                            damage = 35
                        end
                        inst._Reflect_Damage_Target = attacker
                        attacker.components.combat:GetAttacked(inst,damage,nil,nil,spdamage)
                        inst._Reflect_Damage_Target = nil
                end
            ----------------------------------------------------------------------
            ---- 家养的缩壳后受伤永远0
                if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) then
                    return 0,{}
                end
            ----------------------------------------------------------------------
            return 1,{}
        end
        return damage,spdamage
    end
    local function killed_event_fn(inst,_table)
        local killed_target = _table and _table.victim
        if killed_target and killed_target.userid and inst._Reflect_Damage_Target == killed_target then
            inst:WhisperTo(killed_target,TBAT:GetString2(this_prefab,"reflect_damage_announce"))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生物相关
    local function OnEatElement(inst, food)
        -- local value = food.components.edible.hungervalue
        -- inst.stomach = inst.stomach + value
        -- if inst.stomach >= SPAWN_SLIME_VALUE then
        --     local stacksize = 0
        --     while inst.stomach >= SPAWN_SLIME_VALUE do
        --         inst.stomach = inst.stomach - SPAWN_SLIME_VALUE
        --         stacksize = stacksize + 1
        --     end
        --     local slime = SpawnPrefab("slurtleslime")
        --     slime.Transform:SetPosition(inst.Transform:GetWorldPosition())
        --     slime.components.stackable:SetStackSize(stacksize or 1)
        -- end
    end

    local function OnInit(inst)
        -- inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    end
    local function CustomOnHaunt(inst,doer)
        -- inst.components.periodicspawner:TrySpawn()
        local str_table = TBAT:GetString2(this_prefab,"ghost_on_haunt") or {}
        if #str_table > 0 then
            local str = str_table[math.random(#str_table)]
            inst:WhisperTo(doer,str)
        end
        return true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语相关
    --- 密语图标
    TBAT.FNS:AddChatIconData(this_prefab,{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_mushroom_snail",
            build = "tbat_chat_icon_mushroom_snail",
            anim = "idle",
            time = 3,
        },  
    })
    --- 密语API
    local function WhisperTo(inst,player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = this_prefab ,
            sender_name = TBAT:GetString2(this_prefab,"name"),
            s_colour = {252/255,246/255,231/255},
            message = str,
            m_colour = {255/255,186/255,181/255},
        })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- plant_spawn_install
    local function plant_spawn_install(inst)
        TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(inst,TBAT.DEBUGGING and 20 or 120,function()
            ----------------------------------------------------------------------------------------
            ---- 前置检查
                if inst.GetFollowingPlayer and inst:GetFollowingPlayer() then
                    return
                end
                local leader = inst.components.follower:GetLeader()
                if not (leader and leader:IsValid()) then
                    return
                end
                local x,y,z = leader.Transform:GetWorldPosition()
            ----------------------------------------------------------------------------------------
            ---- 寻找附近
                local plants = TheSim:FindEntities(x,0, z, 16, {"fluorescent_plant"})
                if #plants > 20 then
                    return
                end
            ----------------------------------------------------------------------------------------
            ---- 目标生成物
                local plants = {"tbat_plant_fluorescent_moss","tbat_plant_fluorescent_mushroom"}
                local ret_plant_prefab = plants[math.random(#plants)]
            ----------------------------------------------------------------------------------------
            ---- 生成坐标
                local target_spawn_pos = nil
                if inst:IsAsleep() then --- 加载范围外。
                    local radius = 16
                    local all_points = {}
                    local test_plant = SpawnPrefab(ret_plant_prefab)
                    while radius > 1 do
                        local points = TBAT.FNS:GetSurroundPoints({
                            target = leader,
                            range = radius,
                            num = radius*10
                        })
                        local pt = points[math.random(1,#points)]
                        if TheWorld.Map:CanDeployAtPoint(pt,inst) then
                            table.insert(all_points,pt)
                        end
                        radius = radius - 0.5
                    end
                    test_plant:Remove()
                    local pt = all_points[math.random(1,#all_points)]
                    target_spawn_pos = pt
                else
                    target_spawn_pos = Vector3(inst.Transform:GetWorldPosition())
                end
            ----------------------------------------------------------------------------------------
            --- 生成植物
                SpawnPrefab(ret_plant_prefab).Transform:SetPosition(target_spawn_pos.x,0,target_spawn_pos.z)                
            ----------------------------------------------------------------------------------------
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 本体
    local function animal_fn()
        --------------------------------------------------------------------------------------------------------
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddDynamicShadow()
            inst.entity:AddNetwork()
            inst.DynamicShadow:SetSize(2, 1.5)
            inst.Transform:SetFourFaced()
            MakeCharacterPhysics(inst, 50, .5)
            -- inst.AnimState:SetBank("snurtle")
            inst.AnimState:SetBank("slurtle")
            inst.AnimState:SetBuild(this_prefab)
        --------------------------------------------------------------------------------------------------------
            -- inst:AddTag("cavedweller")
            inst:AddTag("animal")
            -- inst:AddTag("explosive")
            inst:AddTag(this_prefab)
        --------------------------------------------------------------------------------------------------------
            inst.entity:SetPristine()
        --------------------------------------------------------------------------------------------------------
        --- API
            inst.WhisperTo = WhisperTo
            workable_com_install(inst)
        --------------------------------------------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        --------------------------------------------------------------------------------------------------------
        --- API
            inst.RememberAttacker = RememberAttacker
            inst.IsNearAttackers = IsNearAttackers
        --------------------------------------------------------------------------------------------------------
        --- 马达
            inst:AddComponent("locomotor")
            inst.components.locomotor.walkspeed = 3
            inst.components.locomotor.runspeed = 5
        --------------------------------------------------------------------------------------------------------
        --- SG
            inst:SetStateGraph("SGslurtle")
        --------------------------------------------------------------------------------------------------------
        --- 吃东西
            inst:AddComponent("eater")
            inst.components.eater:SetDiet({ FOODTYPE.ELEMENTAL }, { FOODTYPE.ELEMENTAL })
            inst.components.eater:SetOnEatFn(OnEatElement)
        --------------------------------------------------------------------------------------------------------
        --- 掉落物
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetChanceLootTable(this_prefab)
        --------------------------------------------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------------------------------------------
        --- 坐标
            inst:AddComponent("knownlocations")
        --------------------------------------------------------------------------------------------------------
        --- 背包
            inst:AddComponent("inventory")
            inst.components.tbat_com_inventory_custom_apply_damage:AddBeforeApplyDamageFn(inst,inventory_damga_shell_fn)
        --------------------------------------------------------------------------------------------------------
        --- 可燃、可冻、作祟、恐慌
            MakeMediumFreezableCharacter(inst, "shell")
            MakeMediumBurnableCharacter(inst, "shell")
            MakeHauntablePanic(inst)
            AddHauntableCustomReaction(inst, CustomOnHaunt, true, false, true)
        --------------------------------------------------------------------------------------------------------
        --- 简易饥饿值
            inst.stomach = 0
            inst.lastmeal = 0  -- brain 里用的
        --------------------------------------------------------------------------------------------------------
        --- 战斗、血量
            inst:AddComponent("combat")
            inst.components.combat.hiteffectsymbol = "shell"
            inst.components.combat:SetKeepTargetFunction(KeepTarget)
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(300)
            inst:ListenForEvent("attacked", Snurtle_OnAttacked)
            inst:ListenForEvent("killed", killed_event_fn)
        --------------------------------------------------------------------------------------------------------
        --- 跟随
            inst:AddComponent("follower")
        --------------------------------------------------------------------------------------------------------
        --- 脑子
            inst:SetBrain(brain)
        --------------------------------------------------------------------------------------------------------
        --- 初始化
            inst:DoTaskInTime(0, OnInit)
            plant_spawn_install(inst)
        --------------------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, animal_fn, assets)
