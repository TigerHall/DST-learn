------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    宠物项圈 - 薰衣草猫猫

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
        --- 按钮事件
            local item_searching = false
            local next_search_time = 4
            inst:ListenForEvent("open_button_clicked",function(_,data)
                local player = LookupPlayerInstByUserID(data.userid)
                local following_player = target.GetFollowingPlayer and target:GetFollowingPlayer()
                if player == following_player then
                    item_searching = true
                    next_search_time = 0.25
                end
                -- print("open_button_clicked")
                inst:PushEvent("update_searching_type")
            end,target)
            inst:ListenForEvent("close_button_clicked",function(_,data)
                local player = LookupPlayerInstByUserID(data.userid)
                local following_player = target.GetFollowingPlayer and target:GetFollowingPlayer()
                if player == following_player then
                    item_searching = false
                    next_search_time = 4
                end
                -- print("close button clicked")
                inst:PushEvent("update_searching_type")
            end,target)
        ---------------------------------------------------------------------
        --- 拾取物品
            local function search_and_pick_item(owner)
                if owner:HasTag("playerghost") then
                    return
                end
                local item = FindPickupableItem(owner, 10, false)
                if item == nil then
                    return
                end
                -----------------------------------------------------
                --- 寻找容器
                    local target_container = nil
                    if not owner.components.inventory:IsFull() then
                        target_container = owner.components.inventory
                    end
                    if target_container == nil then
                        for eq_slot, equippment in pairs(owner.components.inventory.equipslots) do
                            if equippment and equippment.components.container and not equippment.components.container:IsFull() then
                                if equippment.components.container:CanTakeItemInSlot(item) then
                                    target_container = equippment.components.container
                                    break
                                end
                            end
                        end
                    end
                -----------------------------------------------------
                ---
                    if target_container then
                        local x,y,z = item.Transform:GetWorldPosition()
                        SpawnPrefab("statue_transition_2").Transform:SetPosition(x,y,z)
                        target_container:GiveItem(item)
                    end
                -----------------------------------------------------
            end
        ---------------------------------------------------------------------
        --- update fn
            inst:ListenForEvent("update_searching_type",function()
                if item_searching then
                    local following_player = target.GetFollowingPlayer and target:GetFollowingPlayer()
                    if following_player and following_player:HasTag("player") then 
                        target:AddTag("item_searching")
                        search_and_pick_item(following_player)
                        inst:PushEvent("start_searching_task")
                    else
                        target:RemoveTag("item_searching")
                        inst:PushEvent("stop_searching_task")
                    end
                else
                    target:RemoveTag("item_searching")
                    inst:PushEvent("stop_searching_task")
                end            
            end)
        ---------------------------------------------------------------------
        --- task
            inst:ListenForEvent("start_searching_task",function()
                if inst._____searching_task then
                    return
                end
                inst._____searching_task = inst:DoTaskInTime(next_search_time,function()
                    inst._____searching_task = nil
                    inst:PushEvent("update_searching_type")
                end)
            end)
            inst:ListenForEvent("stop_searching_task",function()
                if inst._____searching_task then
                    inst._____searching_task:Cancel()
                    inst._____searching_task = nil
                end
            end)
        ---------------------------------------------------------------------
        --- 上潮湿值buff
            inst:DoPeriodicTask(3,function()
                local following_player = target.GetFollowingPlayer and target:GetFollowingPlayer()
                if following_player and not following_player:HasTag("playerghost") then
                    local debuff_name = "tbat_debuff_of_lavender_kitty_player_moisture"
                    following_player:AddDebuff(debuff_name,debuff_name)
                    local debuff_inst = following_player:GetDebuff(debuff_name)
                    if debuff_inst then
                        debuff_inst.pet = target
                        -- print("moisture_debuff_add")
                    else
                        -- print("moisture_debuff_add_fail")
                    end
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
--- 项圈buff
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
-- 额外潮湿值屏蔽BUFF
    local function extra_moisture_OnAttached(inst,player)
        --- 绑定父物体
        inst.entity:SetParent(player.entity)
        inst.Transform:SetPosition(0,0,0)
        inst:DoTaskInTime(0,function()
            if player.components.moisture then
                player.components.moisture:AddRateBonus(inst, -2, "fast_drying") -- XXX 是干燥率增益值，可以调整(下降是负数)
                player.components.moisture.waterproofnessmodifiers:SetModifier(inst, 1.0, "full_waterproof") -- 当 waterproofmult >= 1 时，_GetMoistureRateAssumingRain() 函数会返回0，意味着雨水不会增加潮湿值。
            end
        end)
        inst:DoPeriodicTask(3,function()
            local pet = inst.pet
            if pet and pet:IsValid() 
                and pet.GetFollowingPlayer and pet:GetFollowingPlayer() == player
                then
                    -- print("tbat_debuff_of_lavender_kitty_player_moisture")
            else
                -- print("防雨buff 没检测到猫")
                inst:Remove()
            end
        end)        
    end
    local function extra_moisture_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(extra_moisture_OnAttached)
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_pet_collar_for_lavender_kitty", collar_fn),
    Prefab("tbat_debuff_of_lavender_kitty_player_moisture", extra_moisture_fn)