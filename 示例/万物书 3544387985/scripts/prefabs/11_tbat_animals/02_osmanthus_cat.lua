--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    本猫有两套 home 系统。

    一套 给野生房子。 follower  跟随给 房子。
    一套给玩家建造房子。 follower 跟随给骨眼

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数组
    local this_prefab = "tbat_animal_osmanthus_cat"
    local brain = require("brains/03_tbat_animal_osmanthus_cat_brain")
    local DAMAGE = 36
    local MAX_HEALTH = 900
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets =
    {
        Asset("ANIM", "anim/catcoon_build.zip"),
        Asset("ANIM", "anim/catcoon_basic.zip"),
        Asset("ANIM", "anim/catcoon_actions.zip"),
        Asset("ANIM", "anim/tbat_animal_osmanthus_cat.zip"),
        Asset("SOUND", "sound/catcoon.fsb"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落物
    SetSharedLootTable(this_prefab,
    {
        {"tbat_material_osmanthus_wine",             1.00},
        {"tbat_food_raw_meat",             1.00},
        {"tbat_food_raw_meat",             1.00},
        {"tbat_material_osmanthus_ball",             TBAT.DEBUGGING and 1 or 0.3},
        {"tbat_building_osmanthus_cat_pet_house_blueprint2",             TBAT.DEBUGGING and 1 or 0.05},
        {"tbat_eq_furrycat_circlet_blueprint2",             TBAT.DEBUGGING and 1 or 0.1},
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 攻击、战斗  combat

    local function get_leader(inst)
		return inst.components.follower and inst.components.follower.leader or nil
	end
	local function get_player_leader(inst)
		local eyebone = get_leader(inst)
		if eyebone and eyebone.components.inventoryitem then
			return eyebone.components.inventoryitem:GetGrandOwner()
		end
		return nil
	end


    local function OnAttacked(inst, data)
        if inst.components.combat and not inst.components.combat.target then
            inst.sg:GoToState("hiss")
        end
        if inst.components.combat and get_player_leader(inst) ~= data.attacker then
            inst.components.combat:SetTarget(data.attacker)
        end
    end
    local RETARGET_TAGS = {"_health"}
    local RETARGET_NO_TAGS = {"INLIMBO", "notarget", "invisible","companion" }
    -- 检查目标是否有效（有健康组件且未死亡）
    local function IsValidTarget(target)
        return target and target.components.health and not target.components.health:IsDead()
    end
    -- 检查目标是否拥有指定预制体标签
    local function HasThisPrefab(target)
        return target:HasTag(this_prefab)
    end
    -- 检查两个实体是否是同领导者（安全处理nil）
    local function IsSameLeader(inst, target)
        local instLeader = get_leader(inst)
        local targetLeader = get_leader(target)
        return instLeader ~= nil and targetLeader ~= nil and instLeader == targetLeader
    end
    -- 检查是否是同一个实体（避免领导者指向自身）
    local function IsSameEntity(entityA, entityB)
        return entityA == entityB
    end
    -- 检查目标是否可作为战斗目标
    local function KeepTargetFn(inst, target)
        -- 基础有效性检查
        if not IsValidTarget(target) then
            return false
        end
        -- 特殊预制体目标规则（同类目标）
        if HasThisPrefab(target) then
            -- 排除同领导者（通过follower组件）
            if inst.components.follower and inst.components.follower:IsLeaderSame(target) then
                return false
            end            
            -- 排除inst的领导者指向target
            local instLeader = get_leader(inst)
            if instLeader and IsSameEntity(instLeader, target) then
                return false
            end            
            -- 排除玩家领导者指向target
            local playerLeader = get_player_leader(inst)
            if playerLeader and IsSameEntity(playerLeader, target) then
                return false
            end
            return true
        end
        -- 普通目标规则
        local instLeader = get_leader(inst)
        if instLeader and IsSameEntity(instLeader, target) then
            return false
        end        
        local playerLeader = get_player_leader(inst)
        if playerLeader and IsSameEntity(playerLeader, target) then
            return false
        end
        --- 怪物玩家处理
        if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and target:HasTag("player") then
            return false
        end
        --- 非野生处理（同是家养、禁止打架）
        if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
            return false
        end
        return true
    end
    -- 重定向目标过滤器
    local function RetargetFn(inst)
        -- 检查是否需要搜索目标（野生宠物不主动寻敌）
        local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
        local pet_house = inst.GetPetHouse and inst:GetPetHouse()
        if following_player == nil and pet_house == nil then
            return
        end
        return FindEntity(inst, 15,
            function(guy)
                -- 基础有效性检查
                if not IsValidTarget(guy) then
                    return false
                end
                -- 特殊预制体目标规则(同类目标)
                if HasThisPrefab(guy) then
                    -- 排除同领导者（通过follower组件）
                    if inst.components.follower and inst.components.follower:IsLeaderSame(guy) then
                        return false
                    end                    
                    -- 排除两个领导者都为nil的情况（原始逻辑）
                    local instLeader = get_leader(inst)
                    local guyLeader = get_leader(guy)
                    if instLeader == nil and guyLeader == nil then
                        return false
                    end                    
                    -- 战斗目标检查
                    local can_target = inst.components.combat:CanTarget(guy)
                    return can_target
                end
                -- 普通目标规则
                -- 检查目标类型
                if not (guy:HasTag("monster") or guy:HasTag("smallcreature")) then
                    return false
                end                
                -- 排除abigail目标（当inst有领导者时）
                local instLeader = get_leader(inst)
                if instLeader and guy:HasTag("abigail") then
                    return false
                end                
                -- 排除同领导者目标
                if inst.components.follower and inst.components.follower:IsLeaderSame(guy) then
                    return false
                end                
                -- 特殊处理cattoyairborne目标
                if guy:HasTag("cattoyairborne") then
                    return true
                end
                --- 怪物玩家处理
                if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and guy:HasTag("player") then
                    return false
                end
                --- 非野生处理（同是家养、禁止打架）
                if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(guy) then
                    return false
                end
                -- 普通战斗目标检查
                return inst.components.combat:CanTarget(guy)
            end,
            RETARGET_TAGS,
            RETARGET_NO_TAGS
        )
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 睡眠
    local function SleepTest(inst)
        if ( inst.components.follower and inst.components.follower.leader )
            or ( inst.components.combat and inst.components.combat.target )
            or inst.components.playerprox:IsPlayerClose()
            or TheWorld.state.israining and inst.components.rainimmunity == nil then
            return
        end
        if not inst.sg:HasStateTag("busy") and (not inst.last_wake_time or GetTime() - inst.last_wake_time >= inst.nap_interval) then
            inst.nap_length = math.random(TUNING.MIN_CATNAP_LENGTH, TUNING.MAX_CATNAP_LENGTH)
            inst.last_sleep_time = GetTime()
            return true
        end
    end

    local function WakeTest(inst)
        if not inst.last_sleep_time
            or GetTime() - inst.last_sleep_time >= inst.nap_length
            or TheWorld.state.israining and inst.components.rainimmunity == nil then
            inst.nap_interval = math.random(TUNING.MIN_CATNAP_INTERVAL, TUNING.MAX_CATNAP_INTERVAL)
            inst.last_wake_time = GetTime()
            return true
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function ShouldAcceptItem(inst, item)
        if item:HasTag("cattoy") or item:HasTag("catfood") or item:HasTag("cattoyairborne") then
            return true
        else
            return false
        end
    end

    local function OnGetItemFromPlayer(inst, giver, item)
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
        if inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/pickup")
        elseif giver.components.leader ~= nil then
            -- if giver.components.minigame_participator == nil then
            --     giver:PushEvent("makefriend")
            --     giver.components.leader:AddFollower(inst)
            -- end
            -- inst.last_hairball_time = GetTime()
            -- inst.hairball_friend_interval = math.random(2,4) -- Jumpstart the hairball timer (slot machine time!)
            -- inst.components.follower:AddLoyaltyTime(TUNING.CATCOON_LOYALTY_PER_ITEM)
            -- if not inst.sg:HasStateTag("busy") then
            --     inst:FacePoint(giver.Transform:GetWorldPosition())
            --     inst.sg:GoToState("pawground")
            -- end
        end
        item:Remove()
    end

    local function OnRefuseItem(inst, item)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/hiss_pre")
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        -- elseif not inst.sg:HasStateTag("busy") then
        -- 	inst.sg:GoToState("hiss")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 雨天相关的功能
    local function ApplyRaining(inst)
        -- inst._catcoonraintask = nil
        -- inst.raining = TheWorld.state.israining
    end

    local function ScheduleRaining(inst)
        -- if TheWorld.state.israining and inst.components.rainimmunity == nil and inst._catcoonraintask == nil then
        --     inst._catcoonraintask = inst:DoTaskInTime(math.random(2,6), ApplyRaining)
        -- end
    end

    local function OnIsRaining(inst, raining)
        -- if raining then
        --     inst:ScheduleRaining()
        -- end
    end
    local function OnRainImmunity(inst)
        -- if inst._catcoonraintask ~= nil then
        --     inst._catcoonraintask:Cancel()
        --     inst._catcoonraintask = nil
        -- end
        -- inst.raining = false
    end

    local function OnRainVulnerable(inst)
        -- inst:ScheduleRaining()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 回家
    local function OnWentHome(inst)
        local den = inst.components.homeseeker and inst.components.homeseeker.home or nil
        if den ~= nil and den.CacheItemsAtHome ~= nil then
            den:CacheItemsAtHome(inst)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 加载
    local function OnLoadPostPass(inst, newents, data)
        -- inst:ScheduleRaining()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主体
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()
        inst.DynamicShadow:SetSize(2,0.75)
        inst.Transform:SetFourFaced()
        MakeCharacterPhysics(inst, 1, 0.5)
        if TBAT.CONFIG.ANIMAL_PHYSICS_REMOVE then
			RemovePhysicsColliders(inst)
		end
        inst.AnimState:SetBank("catcoon")
        -- inst.AnimState:SetBuild("catcoon_build")
        inst.AnimState:SetBuild("tbat_animal_osmanthus_cat")
        inst.AnimState:PlayAnimation("idle_loop")
        inst:AddTag("smallcreature")
        inst:AddTag("animal")
        inst:AddTag(this_prefab)
        --trader (from trader component) added to pristine state for optimization
        inst:AddTag("trader")
        inst.entity:SetPristine()
        --------------------------------------------------------------
        --- 交互
            workable_com_install(inst)
        --------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        --------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------
        --- 战斗、血量
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(MAX_HEALTH)
            inst:AddComponent("combat")
            inst.components.combat:SetDefaultDamage(DAMAGE)
            inst.components.combat:SetRange(TUNING.CATCOON_ATTACK_RANGE)
            inst.components.combat:SetAttackPeriod(TUNING.CATCOON_ATTACK_PERIOD)
            inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
            inst.components.combat:SetRetargetFunction(3, RetargetFn)
            inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/catcoon/hurt")
            inst:ListenForEvent("attacked", OnAttacked)
            inst.components.combat.battlecryinterval = 20

        --------------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetChanceLootTable(this_prefab)
        --------------------------------------------------------------
        --- 跟随
            inst:AddComponent("follower")
            inst.components.follower.maxfollowtime = TUNING.CATCOON_LOYALTY_MAXTIME
        --------------------------------------------------------------
        --- 交易
            inst:AddComponent("trader")
            inst.components.trader:SetAcceptTest(ShouldAcceptItem)
            inst.components.trader.onaccept = OnGetItemFromPlayer
            inst.components.trader.onrefuse = OnRefuseItem
            inst.components.trader.deleteitemonaccept = false
            inst.components.trader.acceptnontradable = true
            inst.last_hairball_time = GetTime()
            inst.hairball_friend_interval = math.random(TUNING.MIN_HAIRBALL_FRIEND_INTERVAL, TUNING.MAX_HAIRBALL_FRIEND_INTERVAL)
            inst.hairball_neutral_interval = math.random(TUNING.MIN_HAIRBALL_NEUTRAL_INTERVAL, TUNING.MAX_HAIRBALL_NEUTRAL_INTERVAL)
        --------------------------------------------------------------
        --- 玩家接近
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetDist(3,4)
            inst.components.playerprox:SetOnPlayerNear(function(inst)
                if inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
            end)
        --------------------------------------------------------------
        --- 名字
			inst:AddComponent("named")
        --------------------------------------------------------------
        --- 睡觉相关
            inst:AddComponent("sleeper")
            --inst.components.sleeper:SetResistance(3)
            inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
            inst.last_sleep_time = nil
            inst.last_wake_time = GetTime()
            inst.nap_interval = math.random(TUNING.MIN_CATNAP_INTERVAL, TUNING.MAX_CATNAP_INTERVAL)
            inst.nap_length = math.random(TUNING.MIN_CATNAP_LENGTH, TUNING.MAX_CATNAP_LENGTH)
            inst.components.sleeper:SetWakeTest(WakeTest)
            inst.components.sleeper:SetSleepTest(SleepTest)
        --------------------------------------------------------------
        --- 行走控制器
            inst:AddComponent("locomotor")
            inst.components.locomotor.walkspeed = 3
            -- inst.components.locomotor.runspeed = 8  -- 没啥用
        --------------------------------------------------------------
        --- 拾取东西
            inst:AddComponent("inventory")
            inst.components.inventory.maxslots = 4
        --------------------------------------------------------------
        -- boat hopping 登船
            inst.components.locomotor:SetAllowPlatformHopping(true)
            inst:AddComponent("embarker")
            inst.components.embarker.embark_speed = inst.components.locomotor.walkspeed + 2
            inst:AddComponent("drownable")
        --------------------------------------------------------------
        --- 回家相关
            -- inst.force_onwenthome_message = true -- for onwenthome event
            -- inst:ListenForEvent("onwenthome", OnWentHome)
            inst:AddComponent("homeseeker")

        --------------------------------------------------------------
        --- 可燃、可被冰冻
            MakeSmallBurnableCharacter(inst, "catcoon_torso", Vector3(1,0,1))
            MakeSmallFreezableCharacter(inst)
        --------------------------------------------------------------
        --- 脑子和SG
            inst:SetBrain(brain)
            inst:SetStateGraph("SGcatcoon")
        --------------------------------------------------------------
        --- 雨天相关
            -- inst:WatchWorldState("israining", OnIsRaining)
            -- inst.ScheduleRaining = ScheduleRaining
            -- inst.OnLoadPostPass = OnLoadPostPass
        --------------------------------------------------------------
        --- 作祟恐惧
            MakeHauntablePanicAndIgnite(inst)
        --------------------------------------------------------------
        --- 雨天事件
            -- inst:ListenForEvent("gainrainimmunity", OnRainImmunity)
            -- inst:ListenForEvent("loserainimmunity", OnRainVulnerable)
        --------------------------------------------------------------
        --------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
