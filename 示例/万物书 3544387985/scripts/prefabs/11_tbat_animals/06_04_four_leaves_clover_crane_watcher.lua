------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
---
    local pet_prefab = "tbat_animal_four_leaves_clover_crane"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function main_logic(inst)
        -----------------------------------------------------
        ---
            local target = inst.target
        -----------------------------------------------------
        ---
            local function get_following_pet()
                for pet, v in pairs(target.components.leader.followers) do
                    if pet and pet:IsValid() and pet.prefab == pet_prefab then
                        return pet
                    end
                end
                return nil
            end
        -----------------------------------------------------
        --- 储存数据
            local function save_data_to_com()
                local pet = get_following_pet()
                if pet then
                    local record = pet:GetSaveRecord()
                    -- local record_str = json.encode(record)
                    inst.components.tbat_data:Set("pet_record",record)
                    -- print("fake error save pet record:",json.encode(record))
                    -- local remain_time = pet.components.tbat_data:Get("timer")
                    -- print("fake error 剩余时间（save)",remain_time)
                end
            end
            inst.components.tbat_data:AddOnSaveFn(save_data_to_com)
        -----------------------------------------------------
        --- 宠物离开的时候，debuff 跟着移除
            inst:ListenForEvent("tbat_animal_four_leaves_clover_crane.leave",function()
                inst:Remove()
            end,target)
        -----------------------------------------------------
        --- 初始化加载的时候检查
            inst:DoTaskInTime(1,function()
                local pet = get_following_pet()
                if pet then

                    return
                end
                local record = inst.components.tbat_data:Get("pet_record")
                if record then
                    -- print("record",json.encode(record))
                    local pet = SpawnSaveRecord(record)
                    pet.Transform:SetPosition(target.Transform:GetWorldPosition())
                    target.components.leader:AddFollower(pet)
                    -- pet:PushEvent("start_following_player",{
                    --     doer = target,
                    -- })
                    local remain_time = inst.components.tbat_data:Get("timer")
                    -- print("fake error (初始化）剩余时间",remain_time)
                    pet.components.tbat_data:Set("timer",remain_time)
                    pet:PushEvent("start_following_timer")
                else
                    print("ERROR : 没有找到宠物 存档")
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
        ---
            inst:DoTaskInTime(3,function()
                local pet = get_following_pet()
                if pet then
                    inst:ListenForEvent("following_timer_update",function(_,time)
                        local time = pet.components.tbat_data:Add("timer",0)
                        -- print("储存时间",time)
                        inst.components.tbat_data:Set("timer",time)
                        if time%10 == 0 then
                            save_data_to_com()
                        end
                    end,pet)
                else
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
            inst.target = target
        -----------------------------------------------------
        ---
            inst:DoTaskInTime(1,main_logic)
        -----------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function OnSave(inst,data)
        -- inst:PushEvent("pet_onsave")
    end
------------------------------------------------------------------------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("tbat_data")
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
    -- inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.OnSave = OnSave
    return inst
end

return Prefab("tbat_animal_four_leaves_clover_crane_watcher_buff_for_player", fn)
