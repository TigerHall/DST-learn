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
            target.components.health.maxhealth = 280
		    target.components.combat:SetDefaultDamage(15)
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

            end)
        ---------------------------------------------------------------------
        ---
            target:ListenForEvent("following_player_battle_with",function()
                target.components.combat:DropTarget(false)
                target.components.combat.target = nil
                target:PushEvent("following_player_in_danger_talk")
            end)
        ---------------------------------------------------------------------
        ---
            target:DoPeriodicTask(0.5,function()
                local following_player = target.GetFollowingPlayer and target:GetFollowingPlayer()
                inst.mult_inst = inst.mult_inst and inst.mult_inst:IsValid() and inst.mult_inst or CreateEntity()
                if following_player then
                    if following_player.components.health then
                       following_player.components.health.externalfiredamagemultipliers:SetModifier(inst.mult_inst,0) 
                    end
                else
                    inst.mult_inst:Remove()
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
-- 
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_pet_collar_for_maple_squirrel", collar_fn)
