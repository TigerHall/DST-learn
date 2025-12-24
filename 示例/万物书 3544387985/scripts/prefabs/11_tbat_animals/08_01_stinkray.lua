------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    帽子鳐鱼

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets=
    {
        Asset("ANIM", "anim/stinkray.zip"),
        Asset("ANIM", "anim/tbat_animal_stinkray.zip"),
        -- Asset("SOUND", "sound/bat.fsb"),
    }
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local this_prefab = "tbat_animal_stinkray"
    local poision_debuff_prefab = "tbat_debuff_stinkray_poison"

    local brain = require "brains/09_tbat_animal_stinkray_brain"
    require "stategraphs/SGtbat_animal_stinkray"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数组

    local SHARE_TARGET_DIST = 30        -- 分享攻击者半径

    local STINKRAY_DAMAGE = 20          -- 伤害
    local STINKRAY_HEALTH = 360         -- 血量
    local STINKRAY_ATTACK_PERIOD = 3    -- 攻击间隔时间
    local STINKRAY_ATTACK_DIST = 3      -- 攻击半径
    
    local STINKRAY_WALK_SPEED = 5   -- 行走速度 （潜水行走）
    local STINKRAY_RUN_SPEED = 7    -- 跑路速度 （飞行行走）

    local STINKRAY_SCALE_FLYING = 1.05      --- 缩放尺寸（飞行）
    local STINKRAY_SCALE_WATER = 1.00       --- 缩放尺寸（水）
------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落物
    SetSharedLootTable(this_prefab,
    {
        {"tbat_item_crystal_bubble",             1.00},
        {"tbat_item_crystal_bubble",             1.00},
        {"tbat_eq_ray_fish_hat_blueprint2", TBAT.DEBUGGING and 1.00 or 0.1 },
        {"tbat_building_reef_lighthouse_blueprint2", TBAT.DEBUGGING and 1.00 or 0.1 },
    })
------------------------------------------------------------------------------------------------------------------------------------------------
--- 战斗
    local RETARGET_TAGS = {"_health"}
    local RETARGET_NO_TAGS = {"INLIMBO", "notarget", "invisible","companion" }
    local attack_target_prefabs = {
        ["cookiecutter"] = true,  -- 饼干切割机
        ["squid"] = true,  -- 鱿鱼
        ["shark"] = true,  -- 岩石大白鲨
    }
    local function Retarget(inst)
        local target = inst.components.combat.target
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst
        --- 跟着玩家的时候
		if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
			local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
			if following_player == target then
				return
			end
			--- 非野生处理（同是家养、禁止打架）
			if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
				return
			end
            --- 处理超出范围外的追杀
            if mid_inst:GetDistanceSqToInst(target) > SHARE_TARGET_DIST*SHARE_TARGET_DIST then
                return
            end            
			return target
		end
        --- 之前的追杀对象重新进入范围
            local last_keeped_target = inst.____last_keeped_target
            if last_keeped_target and last_keeped_target:IsValid()
                and last_keeped_target.components.health and not last_keeped_target.components.health:IsDead()
                and inst.components.combat:CanTarget(last_keeped_target)
                and not last_keeped_target:HasOneOfTags(RETARGET_NO_TAGS)
                then
                return last_keeped_target
            end
        ---- 搜索需要主动攻击的
        local target = FindEntity(mid_inst, SHARE_TARGET_DIST,
			function(guy)
				-- 战斗目标检查
				if not inst.components.combat:CanTarget(guy) then
					return false
				end
				--- 怪物玩家处理
				if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and guy:HasTag("player") then
					return false
				end
				--- 非野生处理（同是家养、禁止打架）
                if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(guy) then
                    return false
                end
				return attack_target_prefabs[guy.prefab] == true
			end,
			RETARGET_TAGS,
			RETARGET_NO_TAGS
		)
        return target
    end

    local function KeepTarget(inst, target)
		--- 非野生处理（同是家养、禁止打架）
		if not TBAT.PET_MODULES:ThisIsWildAnimal(inst) and not TBAT.PET_MODULES:ThisIsWildAnimal(target) then
			return false
		end
        --- 处理超出范围外的追杀
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst
        if mid_inst:GetDistanceSqToInst(target) > SHARE_TARGET_DIST*SHARE_TARGET_DIST then
            return false
        end        
		local can_target = inst.components.combat:CanTarget(target)
        if can_target then
            inst.____last_keeped_target = target
        end
        return can_target
    end

    local function OnAttacked(inst, data)
        local attacker = data and data.attacker
        if not (attacker and attacker:IsValid()) then
            return
        end
		if attacker.prefab == inst.prefab then
			return
		end
        
		inst.components.combat:SetTarget(attacker)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST, {this_prefab})
		for k, v in pairs(ents) do
			v.components.combat:SuggestTarget(attacker)
		end

        attacker:AddDebuff(poision_debuff_prefab,poision_debuff_prefab)
    end

    local function OnHitOtherFn(inst,data)
        local target = data and data.target
        if not (target and target:IsValid()) then
            return
        end
        target:AddDebuff(poision_debuff_prefab,poision_debuff_prefab)
        if TBAT.PET_MODULES:IsFollowingPlayer(inst) then
            target:PushEvent("set_override_stinkray_poison_damage",-3)
            --- AOE
            local x, y, z = target.Transform:GetWorldPosition()
            local BOUNCE_MUST_TAGS = { "_combat" }
            local BOUNCE_NO_TAGS = {this_prefab,"INLIMBO", "wall", "notarget", "player", "companion", "flight", "invisible", "noattack", "hiding" }
            local ents = TheSim:FindEntities(x, y, z, 4, BOUNCE_MUST_TAGS, BOUNCE_NO_TAGS)
            for k, aoe_target in pairs(ents) do
                if not TBAT.PET_MODULES:IsFollowingPlayer(aoe_target) then
                    aoe_target:AddDebuff(poision_debuff_prefab,poision_debuff_prefab)
                    aoe_target:PushEvent("set_override_stinkray_poison_damage",-3)
                end
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 状态切换
    local function SetLocoState(inst, state)
        -- to make sg "gotofly" or "gotoswim"
        -- state = "fly" or "swim"
        inst.LocoState = string.lower(state)
        if state == "fly" then
            MakeFlyingCharacterPhysics(inst, 1, .5)
            inst.components.locomotor:SetShouldRun(true)
        else
            MakeFlyingCharacterPhysics(inst, 1, .5)
            inst.components.locomotor:SetShouldRun(false)
        end
    end
    local function IsLocoState(inst, state)
        return inst.LocoState == string.lower(state)
    end
    local function IsFlying(inst)
        return inst:IsLocoState("fly")
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 睡眠  屏蔽睡眠
    local function ShouldSleep(inst)
        return false
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 判定海洋
    local function IsOceanAtPoint(x_or_vect,_y,_z)
        local x,y,z = x_or_vect,_y,_z
        if type(x_or_vect) == "table" then
            x,y,z = x_or_vect.x,x_or_vect.y,x_or_vect.z
        end
        if TheWorld.Map:IsOceanTileAtPoint(x,y,z) and TheWorld.Map:IsOceanAtPoint(x,y,z,false) then
            return true
        end
        return false
    end
    local function IsInOceanTile(inst)
        return IsOceanAtPoint(inst.Transform:GetWorldPosition())
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- should fly fn 用于强制切状态（在SG里）
    local function ShouldFly(inst)
        ---------------------------------------------------
        --- 战斗中
            local target = inst.components.combat.target
            if target and target:IsValid() then
                return true
            end
        ---------------------------------------------------
        ---
            if inst.__target_going_point and not IsOceanAtPoint(inst.__target_going_point) then
                return true                
            end 
        ---------------------------------------------------
        return false
        ---------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- locomotor hooker
    local function hook_locomotor(inst)
        local old_GoToPoint = inst.components.locomotor.GoToPoint
        inst.components.locomotor.GoToPoint = function(self,pt, bufferedaction, run, overridedest,...)
            local target_point = pt or bufferedaction and bufferedaction.GetActionPoint and bufferedaction:GetActionPoint()
            if type(target_point) == "table" and target_point.x and target_point.z then
                inst.__target_going_point = target_point
                if not IsOceanAtPoint(target_point) then
                    run = true
                end
            end
            old_GoToPoint(self,pt, bufferedaction, run, overridedest,...)
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- freeze 被冻处理动画
    local function freeze_event_fn(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if IsOceanAtPoint(x,y,z) then
            inst.AnimState:ShowSymbol("ripple3_cutout")
        else
            inst.AnimState:HideSymbol("ripple3_cutout")
            ---------------------------------------------------
            --- 以下这段用来处理 在地面上冰冻的时候，动画暂停
                local tempInst = CreateEntity()
                tempInst.entity:AddTransform()
                tempInst.entity:SetParent(inst.entity)
                local paused = false
                tempInst:ListenForEvent("newstate",function(_,data)
                    if data and data.statename == "frozen" then
                        inst.AnimState:Pause()
                        paused = true
                    elseif paused then                        
                        tempInst:Remove()
                        inst.AnimState:Resume()
                    end
                end,inst)
            ---------------------------------------------------
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---  inventory 伤害处理 + 物品拾取处理
    local function inventory_damga_shell_fn(inst,damage, attacker, weapon, spdamage)
        -- print("inventory_damga_shell_fn",inst,damage, attacker, weapon, spdamage)
        -------------------------------------------------------------------
        --- 潜水的基本免疫所有伤害
            if not IsFlying(inst) then
                return 0.1,{}
            end
        -------------------------------------------------------------------
        --- 野生的不变
            if TBAT.PET_MODULES:ThisIsWildAnimal(inst) then
                return damage,spdamage
            end
        -------------------------------------------------------------------
        --- 驯养的帽子鳐鱼数值如上，额外附加90%的位面伤害防御，50%的普通防御
            damage = damage*0.1
            if type(spdamage) == "table" then
                for i,v in pairs(spdamage) do
                    spdamage[i] = v*0.1
                end
            end
        -------------------------------------------------------------------
        return damage,spdamage
    end
    local function hook_inventory_com(inst)
        inst.components.inventory.__tbat_old_GiveItem = inst.components.inventory.GiveItem
        inst.components.inventory.GiveItem = function(self,...)
            local ret = {self:__tbat_old_GiveItem(...)}
            -------------------------------------------------------
            --- 通知需要刷新。
                if self.__event_task then
                    self.__event_task:Cancel()
                end
                self.__event_task = inst:DoTaskInTime(0.1,function(inst)
                    inst:PushEvent("tbat_inventory_item_got")
                    self.__event_task = nil
                end)
            -------------------------------------------------------
            return unpack(ret)
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集藤壶
    local function waterplant_harvest_com_install(inst)
        inst:ListenForEvent("tbat_inventory_item_got",function(inst)
            inst.components.inventory:ForEachItem(function(item)
                if item then
                    local record = item:GetSaveRecord()
                    local tags,tags_idx = TBAT.FNS:GetAllTags(item)
                    local prefab = item.prefab
                    item:Remove()
                    -- local player = inst:GetNearestPlayer()
                    -- player.components.inventory:GiveItem(SpawnSaveRecord(record))
                    inst:PushEvent("need_2_trans_item",{
                        prefab = prefab,
                        record = record,
                        tags = tags,
                        tags_idx = tags_idx,
                    })
                end
            end)
        end)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集渔网
    local function OceanTrawlerPick(inst,target)
        target.components.container:ForEachItem(function(item)            
            if item then
                local record = item:GetSaveRecord()
                item:Remove()
                inst.components.inventory:GiveItem(SpawnSaveRecord(record))
            end
        end)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 动物本体
    local function animal_fn()
        -------------------------------------------------------------------
        -- 实体
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddNetwork()
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize( 1.75, .6 )
            inst.DynamicShadow:Enable(false)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.Transform:SetNoFaced()
            MakeFlyingCharacterPhysics(inst, 1, .5)
            inst.AnimState:SetBank("stinkray")
            inst.AnimState:SetBuild("tbat_animal_stinkray")
        -------------------------------------------------------------------
        --- 参数
            inst.scale_flying = STINKRAY_SCALE_FLYING
            inst.scale_water = STINKRAY_SCALE_WATER
            inst.Transform:SetScale(inst.scale_water, inst.scale_water, inst.scale_water)
        -------------------------------------------------------------------
        --- tags
            inst:AddTag("aquatic")
            -- inst:AddTag("monster")
            -- inst:AddTag("hostile")
            inst:AddTag("stungray")
            inst:AddTag("scarytoprey")
            inst:AddTag("flying")
            inst:AddTag("NOBLOCK")
            inst:AddTag("plantkin") --- 采集藤壶不被打
            inst:AddTag(this_prefab)
        -------------------------------------------------------------------
        --- 预生成
            inst.entity:SetPristine()
        -------------------------------------------------------------------
        --- 招募
            workable_com_install(inst)
        -------------------------------------------------------------------
        --- ismastersim
            if not TheWorld.ismastersim then
                return inst
            end	
        -------------------------------------------------------------------
        --- API
            inst.IsInOceanTile = IsInOceanTile          --- 所在的地皮是否是海洋
            inst.ShouldFly = ShouldFly                  --- 是否应该进入飞行状态
            inst.IsFlying = IsFlying                    --- 是否在飞行状态
            inst.OceanTrawlerPick = OceanTrawlerPick    --- 采集渔网
            waterplant_harvest_com_install(inst)        --- 采集藤壶
        -------------------------------------------------------------------
        --- 马达
            inst:AddComponent("locomotor")
            inst.components.locomotor:SetSlowMultiplier( 1 )
            inst.components.locomotor:SetTriggersCreep(false)
            inst.components.locomotor.pathcaps = { ignorecreep = true }
            inst.components.locomotor.walkspeed = STINKRAY_WALK_SPEED   --- 潜水移动速度
            inst.components.locomotor.runspeed = STINKRAY_RUN_SPEED     --- 飞行移动速度
            inst.components.locomotor.directdrive = true  --- 无视地形，直接过去（不自动走陆地）
            hook_locomotor(inst)
            -- -- locomote 的行动调试
            -- inst.components.locomotor.pusheventwithdirection = true
            -- inst:ListenForEvent("locomote",function(...)
            --     if TBAT.___test_locomote_fn then
            --         TBAT.___test_locomote_fn(...)
            --     end
            -- end)
            -- inst:ListenForEvent("newstate",function(_,data)
            --     print("enter state",data and data.statename)
            -- end)
        -------------------------------------------------------------------
        --- follow
            inst:AddComponent("follower")
        -------------------------------------------------------------------
        --- 吃
            inst:AddComponent("eater")
            inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
            inst.components.eater:SetCanEatHorrible()
            inst.components.eater.strongstomach = true -- can eat monster meat!
        -------------------------------------------------------------------
        --- 睡眠
            inst:AddComponent("sleeper")
            inst.components.sleeper:SetSleepTest(ShouldSleep)
        -------------------------------------------------------------------
        --- 战斗
            inst:AddComponent("combat")
            inst.components.combat.hiteffectsymbol = "bat_body"
            inst.components.combat:SetAttackPeriod(STINKRAY_ATTACK_PERIOD)
            inst.components.combat:SetRange(STINKRAY_ATTACK_DIST)
            inst.components.combat:SetRetargetFunction(3, Retarget)
            inst.components.combat:SetKeepTargetFunction(KeepTarget)
            inst.components.combat:SetDefaultDamage(STINKRAY_DAMAGE)
            inst:ListenForEvent("attacked", OnAttacked)
            inst:ListenForEvent("onhitother", OnHitOtherFn)
        -------------------------------------------------------------------
        --- 生命
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(STINKRAY_HEALTH)
        -------------------------------------------------------------------
        --- 掉落物
            inst:AddComponent("lootdropper")
            inst.components.lootdropper:SetChanceLootTable(this_prefab)
        -------------------------------------------------------------------
        --- 背包
            inst:AddComponent("inventory")
            inst.components.inventory.maxslots = 15
            inst.components.tbat_com_inventory_custom_apply_damage:AddBeforeApplyDamageFn(inst,inventory_damga_shell_fn)
            hook_inventory_com(inst)
        -------------------------------------------------------------------
        --- 观察
            inst:AddComponent("inspectable")
        -------------------------------------------------------------------
        --- 位置记忆器
            inst:AddComponent("knownlocations")
        -------------------------------------------------------------------
        --- 可燃、可冻结
            MakeMediumBurnableCharacter(inst, "ray_face")
            MakeMediumFreezableCharacter(inst, "ray_face")
            inst:ListenForEvent("freeze", freeze_event_fn)
        -------------------------------------------------------------------
        --- 状态切换器
            SetLocoState(inst, "swim")
            inst.SetLocoState = SetLocoState
            inst.IsLocoState = IsLocoState
        -------------------------------------------------------------------
        --- SG + AI
            inst:SetStateGraph("SGtbat_animal_stinkray")
            inst:SetBrain(brain)
        -------------------------------------------------------------------
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, animal_fn, assets)
