------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    宠物项圈 - 帽子鳐鱼

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function init_task(inst)
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 骨眼检查
            local pet = inst.target
            if pet.components.follower:GetLeader() == nil then
                pet:Remove()
                return
            end
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 清除掉落列表
		    pet.components.lootdropper:SetChanceLootTable(nil) 
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 跟着玩家，则玩家回san 。没跟着，则自己回血
            inst:DoPeriodicTask(1,function()
                local following_player,player = TBAT.PET_MODULES:IsFollowingPlayer(pet)
                if following_player then
                    if player and player.components.sanity and not player:HasTag("playerghost") then
                        player.components.sanity:DoDelta(0.2,true)
                    end
                else
                    pet.components.health:DoDelta(1)
                end
            end)
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 拾取的东西
            local function GetHouseBox(pet)
                local house = pet.GetPetHouse and pet:GetPetHouse()
                if house then
                    local visual_container = house.GetVisualContainer and house:GetVisualContainer()
                    if visual_container then
                        return visual_container
                    end 
                end
                return nil
            end
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 拾取藤壶
            local trans_target_prefab = "barnacle"
            inst:ListenForEvent("need_2_trans_item",function(_,data)
                local record = data.record
                if not data.prefab == trans_target_prefab then
                    return
                end
                ----------------------------------------------------------------------------------------------------------
                --- 如果正在跟着玩家，则把物品给玩家
                    local following_player,player = TBAT.PET_MODULES:IsFollowingPlayer(pet)
                    if following_player and player then
                        player.components.inventory:GiveItem(SpawnSaveRecord(record))
                        return
                    end
                ----------------------------------------------------------------------------------------------------------
                --- 如果是家养的，则把物品给家
                    local house_box = GetHouseBox(pet)
                    if house_box == nil then
                        return
                    end
                    local has_barnacle_in_box = false  -- 由于无限叠堆，需要提前检索有没有同类物品
                    house_box.components.container:ForEachItem(function(item)
                        if not has_barnacle_in_box and item and item.prefab == trans_target_prefab then
                            has_barnacle_in_box = true
                        end
                    end)
                    --- 有位置就放，没位置就自己回血。
                    if has_barnacle_in_box or not house_box.components.container:IsFull() then
                        house_box.components.container:GiveItem(SpawnSaveRecord(record))
                    else
                        pet.components.health:DoDelta(50)
                    end
                ----------------------------------------------------------------------------------------------------------
            end,pet)
        ----------------------------------------------------------------------------------------------------------------------------------------
        --- 拾取海鱼
            inst:ListenForEvent("need_2_trans_item",function(_,data)
                ----------------------------------------------------------------------------------------------------------
                --- 
                    if TBAT.PET_MODULES:IsFollowingPlayer(pet) then
                        return
                    end
                ----------------------------------------------------------------------------------------------------------
                --- 如果是家养的，则把物品给家
                    local tags_idx = data.tags_idx or {}
                    if not tags_idx["smalloceancreature"] then
                        return
                    end
                    local house_box = GetHouseBox(pet)
                    if house_box == nil then
                        return
                    end
                    --- 有位置就放鱼，没位置就自己回血。
                    local record = data.record
                    if not house_box.components.container:IsFull() then
                        house_box.components.container:GiveItem(SpawnSaveRecord(record))
                    else
                        pet.components.health:DoDelta(50)
                    end
                ----------------------------------------------------------------------------------------------------------
            end,pet)
        ----------------------------------------------------------------------------------------------------------------------------------------
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
return Prefab("tbat_pet_collar_for_stinkray", collar_fn)