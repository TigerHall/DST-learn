------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local lucky_api = require "prefabs/11_tbat_animals/06_04_lucky_controller_api"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        ---
            local following_player = nil
        -----------------------------------------------------
        --- 只运行一次的。
            inst.on_following_player = function(target,doer)
                inst.on_following_player = nil

                lucky_api.on_following_player(target,doer)
                target:PushEvent("start_following_timer")
                inst.components.tbat_data:Set("userid",doer.userid)

                local fx = SpawnPrefab("tbat_sfx_ground_four_leaves_clover")
                fx.entity:SetParent(doer.entity)
                inst:ListenForEvent("onremove",function()
                    fx:Remove()
                end)
                local wathcer_debuff_prefab = "tbat_animal_four_leaves_clover_crane_watcher_buff_for_player"
                doer.components.tbat_com_debuffable:AddDebuff(wathcer_debuff_prefab,wathcer_debuff_prefab)
                -- doer.components.debuffable:AddDebuff(wathcer_debuff_prefab,wathcer_debuff_prefab)
            end
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
        -----------------------------------------------------
        --- 监听玩家开始跟随
            target:ListenForEvent("start_following_player",function(_,cmd_table)
                local doer = cmd_table.doer
                lucky_api.pet_start_following_player(target,doer)
                if inst.on_following_player then
                    inst.on_following_player(target,doer)
                    inst.on_following_player = nil
                end
            end)
        -----------------------------------------------------
        --- 处理onload
            target:DoTaskInTime(1,function()
                local leader = target.components.follower:GetLeader()
                if leader and leader:HasTag("player") then
                    lucky_api.pet_onload_pst_fn(target,leader)
                    if inst.on_following_player then
                        inst.on_following_player(target,leader)
                        inst.on_following_player = nil
                    end
                end
                -- print("fake error 6666 onload",leader)
            end)
        -----------------------------------------------------
        --- 跟随玩家计时器更新
            target:ListenForEvent("following_timer_update",function(_,time)
                local leader = target.components.follower:GetLeader()
                if leader and leader:HasTag("player") then
                    following_player = leader
                    lucky_api.pet_following_player_timer_update(target,leader,time)
                end
            end)
        -----------------------------------------------------
        --- 激发处理离开
            target:ListenForEvent("on_leave",function()
                local leader = target.components.follower:GetLeader() or following_player
                if leader and leader:HasTag("player") then
                    lucky_api.pet_on_leave_fn(target,leader)
                    leader:PushEvent("tbat_animal_four_leaves_clover_crane.leave")
                end
                if leader and leader.components.leader then
                    leader.components.leader:RemoveFollower(target)
                end
                local x,y,z = target.Transform:GetWorldPosition()
                SpawnPrefab("spawn_fx_medium_static").Transform:SetPosition(x,0,z)
                target:Remove()
            end)
        -----------------------------------------------------
        --- 定期检查，屏蔽不符合领养条件之外的额外领养渠道
            target:DoPeriodicTask(5,function()
                local leader = target.components.follower:GetLeader()
                if not ( leader and leader:IsValid() ) then
                    target:PushEvent("on_leave")
                    print("[TBAT][鹤]没跟随任何目标")
                    return
                end
                if leader:HasTag("player") then
                    local userid = inst.components.tbat_data:Get("userid")
                    if userid ~= leader.userid then
                        target:PushEvent("on_leave")
                        print("[TBAT][鹤]玩家ID不符合，移除。")
                        return
                    else
                        local following_num = leader.components.leader:CountFollowers(target.prefab)
                        if following_num > 1 then
                            target:PushEvent("on_leave")
                            print("[TBAT][鹤]超过1只跟随玩家")
                            return
                        end
                    end
                    return
                end
                if not leader:HasTag("tbat_building_four_leaves_clover_crane_lv2") then
                    target:PushEvent("on_leave")
                    print("[TBAT][鹤]没绑定建筑、移除")
                    return
                end
            end,math.random()*3)
        -----------------------------------------------------
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


    return inst
end

return Prefab("tbat_animal_four_leaves_clover_crane_buff", fn)
