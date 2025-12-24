--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    四叶草鹤

    地里出来的动画： emerge

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets=
    {
        Asset("ANIM", "anim/peagawk_basic.zip"),
        Asset("ANIM", "anim/peagawk_actions.zip"),
        Asset("ANIM", "anim/peagawk_charge.zip"),
        Asset("ANIM", "anim/peagawk_build.zip"),
        Asset("ANIM", "anim/peagawk_prism_build.zip"),

        Asset("ANIM", "anim/tbat_animal_four_leaves_clover_crane.zip"),
        Asset("SOUND", "sound/perd.fsb"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数表
    local this_prefab = "tbat_animal_four_leaves_clover_crane"
    local MAX_FOLLOWING_PLAYER_TIME = 3*480


    local brain = require "brains/07_tbat_animal_four_leaves_clover_crane_brain"
    require "stategraphs/SGtbat_animal_four_leaves_clover_crane"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 击杀掉落
    local loot = 
    {
        -- "drumstick",
        -- "drumstick",
        -- "peagawkfeather",
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 记忆攻击者
    local function RememberAttacker(inst,attacker,time_offset)
        if attacker == nil then
            return
        end
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
        RememberAttacker(inst,attacker)
        return 0,{}
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 初始化
    local function init(inst)
        inst:AddDebuff("tbat_animal_four_leaves_clover_crane_buff","tbat_animal_four_leaves_clover_crane_buff")
        local leader = inst.components.follower:GetLeader()
        if leader and leader:HasTag("player") then
            inst:PushEvent("start_following_timer")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 跟随玩家计时器
    local function start_following_player_timer(inst)
        if inst:HasTag("timer_working") then
            return
        end
        inst:AddTag("timer_working")
        if inst.components.tbat_data:Add("timer",0) == 0 then
            inst.components.tbat_data:Set("timer",MAX_FOLLOWING_PLAYER_TIME)
            -- print("+++ 鹤跟随时间初始化")
        end
        inst:DoPeriodicTask(1,function()
            local time = inst.components.tbat_data:Add("timer",-1)
            inst.__net_timer:set(time)
            inst:PushEvent("following_timer_update",time)
            if time <= 0 then
                inst:PushEvent("on_leave")
            end
        end)
        ---- 上标记
        inst:AddTag("companion")
        local leader = inst.components.follower:GetLeader()
        if leader and leader:HasTag("player") then
            inst:AddTag(leader.userid)
        end
    end
    local function start_following_player_fn(inst)
        inst.components.tbat_data:Set("timer",MAX_FOLLOWING_PLAYER_TIME)
        inst.__net_timer:set(MAX_FOLLOWING_PLAYER_TIME)
    end
    local function GetRemainFollowingTime(inst)
        return inst.components.tbat_data:Add("timer",0)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- name update
    local function time_display_fx(remain_time)
        -- 计算分钟和秒（四舍五入到整秒）
        local minutes = math.floor(remain_time / 60)
        local seconds = remain_time - minutes * 60
        seconds = math.floor(seconds + 0.5)  -- 四舍五入
        -- 处理秒进位（例如 59.5 秒 → 60 秒 → 进位到分钟）
        if seconds >= 60 then
            minutes = minutes + 1
            seconds = 0
        end
        -- 格式化秒为两位（不足两位补零）
        local seconds_str = string.format("%02d", seconds)
        -- 拼接最终字符串（包含中文括号）
        local display_time = "" .. minutes .. " : " .. seconds_str .. ""
        return display_time
    end
    local function name_update_fn(inst)
        local origin_name = TBAT:GetString2(this_prefab,"name")
        local display_str = " \n"
        display_str = display_str .. origin_name .. "\n"
        local remain_time = inst.__net_timer:value()
        local display_time = time_display_fx(remain_time)
        display_str = display_str .. display_time
        inst.name = display_str        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local item_accept_com_install = require "prefabs/11_tbat_animals/06_02_four_leaves_clover_crane_item_accept_com"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 本体
    local function animal_fn()
        --------------------------------------------------------------
        --- 基础模块鹤 tag
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize( 1.5, .75 )
            inst.Transform:SetFourFaced()
            inst.entity:AddNetwork()        
            MakeCharacterPhysics(inst, 50, .5)
            inst.AnimState:SetBank("peagawk")
            inst.AnimState:SetBuild("tbat_animal_four_leaves_clover_crane")
            inst.AnimState:Hide("hat")
            inst:AddTag("character")
            inst:AddTag("berrythief")
            inst:AddTag("smallcreature")
            inst:AddTag(this_prefab)
        --------------------------------------------------------------
        --- 预设定型
            inst.entity:SetPristine()
        --------------------------------------------------------------
        --- API
            inst.RememberAttacker = RememberAttacker
            inst.IsNearAttackers = IsNearAttackers
            inst.GetRemainFollowingTime = GetRemainFollowingTime
        --------------------------------------------------------------
        --- 物品接受
            item_accept_com_install(inst)
        --------------------------------------------------------------
        --- net
            inst.__net_timer = net_float(inst.GUID, "__net_timer","net_timer_update")
            if not TheNet:IsDedicated() then
                inst:ListenForEvent("net_timer_update",name_update_fn)
            end
        --------------------------------------------------------------
        --- ismastersim
            if not TheWorld.ismastersim then
                return inst
            end
        --------------------------------------------------------------
        --- 数据
            inst:AddComponent("tbat_data")
            inst:ListenForEvent("start_following_timer",start_following_player_timer)
            inst:ListenForEvent("start_following_player",start_following_player_fn)
        --------------------------------------------------------------
        --- 跟随
            inst:AddComponent("follower")
        --------------------------------------------------------------
        --- 吃东西
            inst:AddComponent("eater")
            inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
        --------------------------------------------------------------
        --- 催眠醒来
            inst:AddComponent("sleeper")
            inst.components.sleeper:SetWakeTest( function() return true end)    --always wake up if we're asleep
        --------------------------------------------------------------
        --- 战斗+血量
            inst:AddComponent("combat")
            inst.components.combat.hiteffectsymbol = "pig_torso"
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(6666)
            inst.components.health:SetMinHealth(666)
            inst.components.combat:SetDefaultDamage(0)
            inst.components.combat:SetAttackPeriod(6)
        --------------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetLoot(loot)
        --------------------------------------------------------------  
        --- 默认背包
            inst:AddComponent("inventory")
            inst.components.tbat_com_inventory_custom_apply_damage:AddBeforeApplyDamageFn(inst,inventory_damga_shell_fn)
        --------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------
        --- 行走控制器
            inst:AddComponent("locomotor")
            inst.components.locomotor.runspeed = 9
            inst.components.locomotor.walkspeed = 4
        --------------------------------------------------------------
        --- AI 和 SG
            inst:SetBrain(brain)
            inst:SetStateGraph("SGtbat_animal_four_leaves_clover_crane")
        --------------------------------------------------------------
        --- 可燃、可冰冻
            MakeMediumBurnableCharacter(inst, "pig_torso")
            MakeMediumFreezableCharacter(inst, "pig_torso")
        --------------------------------------------------------------
        --- 初始化
            inst:DoTaskInTime(1,init)
        --------------------------------------------------------------
        --- SG初始化
            inst.sg:GoToState("idle")
        --------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, animal_fn, assets)