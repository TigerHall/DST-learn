------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    tbat_pet_lavender_kitty

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets=
    {
        Asset("ANIM", "anim/tbat_pet_lavender_kitty.zip"),
        Asset("ANIM", "anim/tbat_pet_lavender_kitty_ui.zip"),
    }
------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_pet_lavender_kitty"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local brain = require("brains/08_tbat_pet_lavender_kitty_brain")
    require "stategraphs/SGtbat_pet_lavender_kitty"

    local WAKE_TO_FOLLOW_DISTANCE = 4
    local SLEEP_NEAR_LEADER_DISTANCE = 2.5
    local SCARRY_WAKEUP_DIST = 6
    local KITTEN_SCALE = 0.7 * 1.5

------------------------------------------------------------------------------------------------------------------------------------------------
--- 睡觉

    local function ShouldWakeUp(inst)
        return DefaultWakeTest(inst) or (inst.components.follower.leader ~= nil and not inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
    end

    local function ShouldSleep(inst)
        return DefaultSleepTest(inst) and (inst.components.follower.leader == nil or inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
    end

------------------------------------------------------------------------------------------------------------------------------------------------
    local function GetPeepChance(inst)
        return 0
    end

    local function IsPlayful(inst)
        return true
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 招募 workable_install
    local workable_com_install = require("prefabs/11_tbat_animals/00_pet_workable_com_install")
------------------------------------------------------------------------------------------------------------------------------------------------
--- 捡东西
    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO","nosteal","irreplaceable","nonpotatable"}
    local pick_target_list = {
        ["log"] = true,  -- 木头
        ["cutgrass"] = true,  -- 草
        ["rocks"] = true,  -- 石头
        ["goldnugget"] = true,  -- 金子
        ["seeds"] = true,  -- 普通种子
        ["carrot_seeds"] = true,  -- 胡萝卜种子
        ["corn_seeds"] = true,  -- 玉米种子
        ["potato_seeds"] = true,  -- 土豆种子
        ["tomato_seeds"] = true,  -- 番茄种子
        ["asparagus_seeds"] = true,  -- 芦笋种子
        ["eggplant_seeds"] = true,  -- 茄子种子
        ["pumkin_seeds"] = true,  -- 南瓜种子（注：原文为 "pumkin_seeds"，按文件内容保留）
        ["watermelon_seeds"] = true,  -- 西瓜种子
        ["dragonfruit_seeds"] = true,  -- 火龙果种子
        ["durian_seeds"] = true,  -- 榴莲种子
        ["garlic_seeds"] = true,  -- 大蒜种子
        ["onion_seeds"] = true,  -- 洋葱种子
        ["pepper_seeds"] = true,  -- 辣椒种子
        ["pomegranate_seeds"] = true,  -- 石榴种子
        ["poop"] = true,  -- 粪便
        ["spoiled_food"] = true,  -- 腐烂物
        ["twigs"] = true,  -- 树枝
        ["flint"] = true,  -- 燧石
        ["berries"] = true,  -- 浆果
        ["stinger"] = true,  -- 蜂刺
        ["tbat_material_dandelion_umbrella"] = true,  -- 蒲公英猫猫花朵
        ["tbat_plant_dandycat_kit"] = true,  -- 蒲公英猫猫植株
        ["tbat_material_mirage_wood"] = true,  -- 幻源木
    }
    local function FindPickableItem(inst)
        local mid_inst = nil
        local leader = inst.components.follower:GetLeader()
        mid_inst = leader and leader:IsValid() and leader or inst

        local target = FindEntity(mid_inst, 16, function(item)
            if not pick_target_list[item.prefab] then
                return false
            end
            if not item:IsOnValidGround() then
                return false
            end
            if item.components.inventoryitem == nil then
                return false
            end
            if item.components.inventoryitem.owner ~= nil then
                return false
            end
            if item.components.container then
                return false
            end
            if item.components.equippable then
                return false
            end
            if item.sg or item.brainfn then
                return false
            end
            if TBAT.DEFINITION:IsImportantItem(item) then
                return false
            end
            return true
        end, nil, notags)
        -- print("寻找到目标",target)
        return target
    end
    local function DoPick(inst,item)
        -- print("kitty pick",item)
        --------------------------------------------------------
        --- 动作执行期间，有其他高位把东西拿走了
            if not item:IsValid() then
                return
            end
            if item.components.inventoryitem.owner ~= nil then
                return
            end
        --------------------------------------------------------
        local picknum = 1
        if item.components.stackable then
            picknum = item.components.stackable:StackSize()
        end
        local prefab = item.prefab
        item:Remove()
        --------------------------------------------------------
        -- 通知房子
            local leader = inst.components.follower:GetLeader()
            if leader and leader:IsValid() and leader:HasTag("tbat_pet_eyebone") then
                local house = leader.components.inventoryitem:GetGrandOwner()
                if house and house:IsValid() then
                    house:PushEvent("pet_pick",{
                        prefab = prefab,
                        num = picknum,
                        pet = inst,
                    })
                end
            end
        --------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- ui 相关的函数
    local function ui_com_install(inst)
        local fn = require("prefabs/11_tbat_animals/07_02_lavender_kitty_ui_installer")
        fn(inst)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_com_install(inst)
        local fn = require("prefabs/11_tbat_animals/07_03_lavender_kitty_acceptable_com")
        fn(inst)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 宠物本体
    local function pet_fn()
        -------------------------------------------------------------------
        -- 基础组件
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddDynamicShadow()
            inst.entity:AddNetwork()

            inst.Transform:SetSixFaced()
            inst.Transform:SetScale(KITTEN_SCALE, KITTEN_SCALE, KITTEN_SCALE)
            inst.AnimState:SetBank("kitcoon")
            inst.AnimState:SetBuild(this_prefab)
            inst.AnimState:PlayAnimation("idle_loop")
            inst.DynamicShadow:SetSize(1, .33)
            MakeCharacterPhysics(inst, 1, .5)
            inst.Physics:SetDontRemoveOnSleep(true) -- critters dont really go do entitysleep as it triggers a teleport to near the owner, so no point in hitting the physics engine.
        -------------------------------------------------------------------
        --- tag
            -- inst:AddTag("kitcoon")
            inst:AddTag("companion")
            inst:AddTag("notraptrigger")
            inst:AddTag("noauradamage")
            inst:AddTag("NOBLOCK")
            inst:AddTag(this_prefab)
        -------------------------------------------------------------------
        --- 
            inst.entity:SetPristine()
        -------------------------------------------------------------------
        --- 用来辅助实现UI传递目标
            ui_com_install(inst)
        -------------------------------------------------------------------
        --- 物品接受
            acceptable_com_install(inst)
        -------------------------------------------------------------------
        --- 拾取组件
            inst.FindPickableItem = FindPickableItem
            inst.DoPick = DoPick
        -------------------------------------------------------------------
        --- 领养组件
            workable_com_install(inst)
        -------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        -------------------------------------------------------------------
        --- 检查
		    inst:AddComponent("inspectable")
        -------------------------------------------------------------------
        --- 跟随
            inst:AddComponent("follower")
        -------------------------------------------------------------------
        --- 追踪
            inst:AddComponent("entitytracker")
        -------------------------------------------------------------------
        --- 数据
		    inst:AddComponent("tbat_data")
            inst:AddComponent("inventory")
        -------------------------------------------------------------------
        --- 游戏
		    -- inst:AddComponent("kitcoon")
        -------------------------------------------------------------------
        --- 名字
		    inst:AddComponent("named")
        -------------------------------------------------------------------
        --- 计时器
            inst:AddComponent("timer")
            -- inst:ListenForEvent("timerdone", OnTimerDone)
        -------------------------------------------------------------------
        --- 入睡
            inst:AddComponent("sleeper")
            inst.components.sleeper:SetResistance(3)
            inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
            inst.components.sleeper:SetSleepTest(ShouldSleep)
            inst.components.sleeper:SetWakeTest(ShouldWakeUp)
        -------------------------------------------------------------------
        --- 行走
            inst:AddComponent("locomotor")
            inst.components.locomotor:SetTriggersCreep(false)
            inst.components.locomotor.softstop = true
            inst.components.locomotor.walkspeed = TUNING.KITCOON_WALK_SPEED / KITTEN_SCALE
            inst.components.locomotor.runspeed = TUNING.KITCOON_RUN_SPEED / KITTEN_SCALE
            inst.components.locomotor:SetAllowPlatformHopping(true)
        -------------------------------------------------------------------
        --- 跳船
            inst:AddComponent("embarker")
            inst.components.embarker.embark_speed = inst.components.locomotor.walkspeed + 2
            inst:AddComponent("drownable")    
        -------------------------------------------------------------------
        --- AI + SG
            inst:SetBrain(brain)
            inst:SetStateGraph("SGtbat_pet_lavender_kitty")
        -------------------------------------------------------------------
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, pet_fn,assets)
