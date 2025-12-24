------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function init_task(inst)
        ---------------------------------------------------------------------
        --- 骨眼检查
            local target = inst.target
            if target.components.follower:GetLeader() == nil then
                target:Remove()
                return
            end
        ---------------------------------------------------------------------
        --- 伤害、减伤。
            target.components.health.maxhealth = 800
		    target.components.combat:SetDefaultDamage(45)
            local old_health_delta_fn = target.components.health.DoDelta
            target.components.health.DoDelta = function(self, amount,...)
                if amount < 0 then
                    amount = amount*0.1
                end
                return old_health_delta_fn(self, amount,...)
            end
        ---------------------------------------------------------------------
        --- 清除掉落列表
		    target.components.lootdropper:SetChanceLootTable(nil)            
        ---------------------------------------------------------------------
        --- 由于 怪物 有 inventory 组件，所有的喂食都相当于 给怪物 东西，怪物自己吃身上的。
            target:ListenForEvent("trade", function(_, data)
                local giver = data.giver
                local item = data.item
                if target.components.eater:CanEat(item) then
                    local food,feeder = item,giver
                    -- print("[tbat] 宠物吃了东西",food,feeder ~= nil and "有喂食者" or "无喂食者",feeder)
                    if feeder and feeder:HasTag("player") then
                        target:PushEvent("feed_by_player",{food=food,feeder=feeder})
                    end
                end
            end)
        ---------------------------------------------------------------------
        --- 套buff
            target:ListenForEvent("feed_by_player",function(_,data)
                local player = data.feeder
                local food = data.food
                if food and food.prefab == "tbat_food_raw_meat" then
                    local debuff_prefab = "tbat_debuff_snow_plum_chieftain_feed_buff"
                    player:AddDebuff(debuff_prefab,debuff_prefab)
                    target:AddDebuff(debuff_prefab,debuff_prefab)
                end
            end)
        ---------------------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- buff 挂载相关
    local function OnDetached(inst) -- 被外部命令。默认情况下，内部的onremove不会执行，需要自己手动添加event

    end
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
        -----------------------------------------------------
        ---
            inst.target = target
            inst:DoTaskInTime(0,init_task)
        -----------------------------------------------------
    end
    local function ExtendDebuff(inst)  --- 添加同一索引的时候执行

    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function collar_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
        -- inst.components.debuff:SetDetachedFn(inst.Remove)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(ExtendDebuff)
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
-- 食物buff
    local function food_OnAttached(inst,target)
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
        -----------------------------------------------------
        ---
        -----------------------------------------------------
        --- timer
            inst.timer = inst.timer or 0
            inst:DoPeriodicTask(1,function()
                inst.timer = inst.timer + 1
                if inst.timer > 240 then
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
        ---
            if target:HasTag("player") then
                if target.components.freezable then
                    inst:DoPeriodicTask(1,function()
                        target.components.freezable.coldness = 0
                        if target.components.freezable:IsFrozen() then
                            target.components.freezable:Unfreeze()
                        end
                    end)
                end
                -- print("玩家获得 冰冻免疫buff",target)
            elseif target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier(inst,1.5)
                -- print("宠物获得伤害提升buff")
            end
        -----------------------------------------------------
        --- 两个都不被冻
            inst:ListenForEvent("freeze",function()
                if target.components.freezable and target.components.freezable:IsFrozen() then
                    target.components.freezable:Unfreeze()
                end
            end,target)
        -----------------------------------------------------
    end
    local function food_ExtendDebuff(inst)
        inst.timer = 0
        local target = inst.entity:GetParent()
        -- print("BUFF 时间重置",target)
    end
    local function feed_buff(inst)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(food_OnAttached)
        inst.components.debuff.keepondespawn = false -- 是否保持debuff 到下次登陆
        inst.components.debuff:SetExtendedFn(food_ExtendDebuff)
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_pet_collar_for_snow_plum_chieftain", collar_fn),
    Prefab("tbat_debuff_snow_plum_chieftain_feed_buff",feed_buff)
