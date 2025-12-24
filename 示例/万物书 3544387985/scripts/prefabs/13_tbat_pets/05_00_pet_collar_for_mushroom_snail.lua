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
        --- 清除掉落列表
		    target.components.lootdropper:SetChanceLootTable(nil)            
        ---------------------------------------------------------------------
        --- 炼丹炉相关回调
            target:ListenForEvent("tbat_com_mushroom_snail_cauldron.Started",function(_,cmd_table)
                if type(cmd_table) == "table" and type(cmd_table.stacksize) == "number" then
                    cmd_table.stacksize = cmd_table.stacksize * 2
                    print("双倍收获")
                    target:WhisperTo(cmd_table.doer,TBAT:GetString2(target.prefab,"double_announce"))
                end
            end)
        ---------------------------------------------------------------------
        --- 速度
            inst:DoPeriodicTask(3,function()
                if inst.GetFollowingPlayer and inst:GetFollowingPlayer() then
                    target.components.locomotor.walkspeed = 4
                    target.components.locomotor.runspeed = 6
                else
                    target.components.locomotor.walkspeed = 3
                    target.components.locomotor.runspeed = 5
                end
            end)
            
        ---------------------------------------------------------------------
        --- 交互
            target:ListenForEvent("tbat_container_mushroom_snail_cauldron.open",function(_,cmd_table)
                target:WhisperTo(cmd_table.doer,TBAT:GetString2(target.prefab,"pot.open"))
            end)
            target:ListenForEvent("tbat_container_mushroom_snail_cauldron.close",function(_,cmd_table)
                target:WhisperTo(cmd_table.doer,TBAT:GetString2(target.prefab,"pot.close"))
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
return Prefab("tbat_pet_collar_for_mushroom_snail", collar_fn)
