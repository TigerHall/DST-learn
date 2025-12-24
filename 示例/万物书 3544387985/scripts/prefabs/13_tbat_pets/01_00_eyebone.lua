--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    【注意】对于宠物来说，骨眼就是房子。

]]---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local BASE_PREFAB = "tbat_pet_eyebone"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/cane.zip"),
        Asset("ANIM", "anim/swap_cane.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onsave fn
    local on_save_fn = function(com)
        if com.inst.pet and com.inst.pet:IsValid() then
            com:Set("record",com.inst.pet:GetSaveRecord())
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function GetPet(inst)
        for temp, v in pairs(inst.components.leader.followers) do
            if temp and temp:IsValid() then
                return temp
            end
        end
        return nil
    end
    local function init_0(inst)
        -----------------------------------------------------
        --- 检查和重新生成。
            local pet = GetPet(inst)
            if pet == nil and PrefabExists(inst.pet_prefab) then
                local record = inst.components.tbat_data:Get("record")
                if record then
                    pet = SpawnSaveRecord(record)
                else                
                    pet = SpawnPrefab(inst.pet_prefab)
                end
                pet.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        -----------------------------------------------------
            if pet == nil then
                print("宠物不存在，移除骨眼",inst)
                inst:Remove()
                return
            end
        -----------------------------------------------------
        --- 相互链接
            inst.pet = pet
            inst.components.leader:AddFollower(pet)
            pet.eyebone = inst
            inst:ListenForEvent("death",function()
                inst:RemoveAllEventCallbacks()
                inst:Remove()
                -- print("宠物死亡、骨眼移除")
            end,pet)
            pet:ListenForEvent("onremove",function()
                print("骨眼被意外情况移除，移除宠物",inst)
                pet:RemoveAllEventCallbacks()
                SpawnPrefab("spawn_fx_medium").Transform:SetPosition(pet.Transform:GetWorldPosition())
                pet:Remove()
            end,inst)
            inst:ListenForEvent("onremove",function()
                if pet.go_home_flag then
                    return
                end
                print("宠物被意外情况移除，移除骨眼")
                pet:RemoveAllEventCallbacks()                
                inst:RemoveAllEventCallbacks()
                inst:Remove()
            end,pet)
        -----------------------------------------------------
        --- 特殊情况下移除
            inst:ListenForEvent("on_landed",function()
                if inst.components.inventoryitem.owner == nil then
                    print("骨眼意外落地，移除",inst)
                    inst:Remove()
                end
            end)
            inst:DoPeriodicTask(3,function()
                local owner = inst.components.inventoryitem:GetGrandOwner()
                if owner and owner:HasOneOfTags({"player","tbat_pet_eyebone_box"}) or TBAT.DEBUGGING then
                    --- 
                else
                    print("宠物骨眼不再特定的容器里，移除",inst)
                    inst:Remove()
                end
            end)
            pet:DoPeriodicTask(3,function()
                local following_player = pet.GetFollowingPlayer and pet:GetFollowingPlayer()
                if following_player then
                    pet:AddTag("following_player")
                else
                    pet:RemoveTag("following_player")
                end
                --- 宠物在某些极端情况下被剥夺走领导权，则移除。
                if pet.components.follower:GetLeader() ~= inst then
                    print("宠物被剥夺走领导权,骨眼移除，宠物移除",inst,pet)
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
        --- 距离检查
            local following_max_dist_sq = 30*30            
            inst:DoPeriodicTask(3,function()
                local following_player = pet.GetFollowingPlayer and pet:GetFollowingPlayer()
                if following_player and following_player:IsValid() and pet and pet:IsValid() then
                    if following_player:GetDistanceSqToInst(pet) > following_max_dist_sq then
                        pet.Transform:SetPosition(following_player.Transform:GetWorldPosition())
                    end
                end
            end)
        -----------------------------------------------------
        --- 项圈debuff
            if PrefabExists(inst.debuff_prefab) then
                pet:AddDebuff(inst.debuff_prefab,inst.debuff_prefab)
            end
        -----------------------------------------------------
        --- 监听战斗事件
            pet:ListenForEvent("player_battle_with",function(_,target)
                if pet.components.combat then
                    pet.components.combat:SuggestTarget(target)
                end
                pet:PushEvent("following_player_battle_with",target)
            end,inst)
        -----------------------------------------------------
        --- 监听蜗牛炼丹炉事件
            pet:ListenForEvent("tbat_com_mushroom_snail_cauldron.Started",function(_,_table)
                pet:PushEvent("tbat_com_mushroom_snail_cauldron.Started",_table)
            end,inst)
            pet:ListenForEvent("tbat_container_mushroom_snail_cauldron.open",function(_,_table)
                pet:PushEvent("tbat_container_mushroom_snail_cauldron.open",_table)
            end,inst)
            pet:ListenForEvent("tbat_container_mushroom_snail_cauldron.close",function(_,_table)
                pet:PushEvent("tbat_container_mushroom_snail_cauldron.close",_table)
            end,inst)
        -----------------------------------------------------
        --- 回房子机制
            if pet.components.homeseeker then
                pet.components.homeseeker:SetHome(inst)
            end
        -----------------------------------------------------
        --- 宠物回家。
            pet:ListenForEvent("onwenthome",function()
                on_save_fn(inst.components.tbat_data)
                pet.go_home_flag = true
                pet:Remove()
                -- print("fake error 宠物回家，实体删除。")
            end,inst)
        -----------------------------------------------------
        --- 改名字
            local new_name = TBAT:GetString2(pet.prefab,"name_pet")
            if new_name and pet.components.named then
                pet.components.named:SetName(new_name)
            end
        -----------------------------------------------------
        --- 领养
            pet:ListenForEvent("tbat_event.pet_follow_target",function(pet,call_back_cmd_table)
                local doer = call_back_cmd_table.doer
                local eyebone_owner = inst.components.inventoryitem:GetGrandOwner()
                if eyebone_owner == doer then
                    --- 自己的
                    call_back_cmd_table.succeed = false
                    doer.components.tbat_com_action_fail_reason:Inser_Fail_Talk_Str(TBAT:GetString2(BASE_PREFAB,"owner_is_player"))
                    return
                end
                if eyebone_owner and eyebone_owner:HasTag("player") then
                    ---- 已经有主了。
                    call_back_cmd_table.succeed = false
                    doer.components.tbat_com_action_fail_reason:Inser_Fail_Talk_Str(TBAT:GetString2(BASE_PREFAB,"has_owner"))
                    return
                end
                local building =  eyebone_owner.components.container and eyebone_owner
                local backpack = doer.TBAT_Get_Pet_Eyebone_Backpack and doer:TBAT_Get_Pet_Eyebone_Backpack()
                if building and backpack then
                    local has_the_same_pet = false
                    backpack.components.container:ForEachItem(function(item)
                        if item and item.prefab == inst.prefab then
                            has_the_same_pet = true
                        end
                    end)
                    if not has_the_same_pet then
                        -- building.components.container:DropItem(inst)
                        building:PushEvent("special_drop_item",inst)
                        backpack:PushEvent("special_give_item",inst)
                        -- backpack.components.container:GiveItem(inst)
                        inst:PushEvent("RestartBrain")
                        call_back_cmd_table.succeed = true
                        return
                    else
                        call_back_cmd_table.succeed = false
                        doer.components.tbat_com_action_fail_reason:Inser_Fail_Talk_Str(TBAT:GetString2(BASE_PREFAB,"has_same_pet"))
                    end
                end
            end)
        -----------------------------------------------------
        --- 
            pet:ListenForEvent("RestartBrain",function()
                pet:StopBrain()
                pet:RestartBrain()
            end,inst)
        -----------------------------------------------------
        --- tag
            pet:AddTag("pet")
            pet:AddTag("companion")
        -----------------------------------------------------
        --- 其他挂载函数。
            if inst.pet_fn then
                inst.pet_fn(pet)
            end
        -----------------------------------------------------
    end
    local function home_release_child(inst)
        if inst.pet and inst.pet:IsValid() then
            return
        end
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner:HasTag("player") then
            return
        end
        -- print("宠物离家，从新生成实体")
        init_0(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 各种辅助检查。
    local function remove_0_task(inst)
        if TBAT.DEBUGGING then
            return
        end
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner == nil then
            inst:Remove()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 通用
    local function common_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst:AddTag("tbat_pet_eyebone")
        inst:AddTag("nosteal")
        inst.AnimState:SetBank("eyebone")
        inst.AnimState:SetBuild("chester_eyebone_build")
        inst.AnimState:PlayAnimation("dead", true)
        inst.entity:SetPristine()
        -----------------------------------------------------
        -----------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        -----------------------------------------------------
        --- 通用
            inst:AddComponent("tbat_data")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:ChangeImageName("chester_eyebone")
            inst:AddComponent("inspectable")
            inst:AddComponent("leader")
            -- inst:AddComponent("spawner")
            -- inst.components.spawner.GoHome = function(self,child)
            --     print("66666666666666666")
            --     return true
            -- end
            MakeHauntableLaunch(inst)
        -----------------------------------------------------
        --- 自定义、初始化
            inst.GetPet = GetPet
            inst:DoTaskInTime(0,remove_0_task)
            inst:DoTaskInTime(0,init_0)
            inst.components.tbat_data:AddOnSaveFn(on_save_fn)
            inst:ListenForEvent("release_child",home_release_child)
        -----------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 不同类型
    local all_eyebone_data = {
        ------------------------------------------------------------------------------------
        --- 梅雪族长
            {
                
                name = "snow_plum_chieftain",
                pet_prefab = "tbat_animal_snow_plum_chieftain",
                debuff_prefab = "tbat_pet_collar_for_snow_plum_chieftain",
                eyebone_fn = function(inst)                            
                            inst:WatchWorldState("phase",function()
                                inst:DoTaskInTime(1,function()
                                    if not TheWorld.state.isday then
                                        inst:PushEvent("release_child")
                                    end
                                end)
                            end)
                end,
                pet_fn = function(inst)      
                            inst.need_to_go_home = function(inst)
                                if TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                                    return true
                                end
                                return false
                            end
                end
            },
        ------------------------------------------------------------------------------------
        --- 桂花猫猫
            {                
                name = "osmanthus_cat",
                pet_prefab = "tbat_animal_osmanthus_cat",
                debuff_prefab = "tbat_pet_collar_for_osmanthus_cat",
                eyebone_fn = function(inst)                            
                            inst:WatchWorldState("phase",function()
                                inst:DoTaskInTime(1,function()
                                    if TheWorld.state.isday then
                                        inst:PushEvent("release_child")
                                    end
                                end)
                            end)
                end,
                pet_fn = function(inst)
                            inst.need_to_go_home = function(inst)
                                if not TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                                    return true
                                end
                                return false
                            end
                end
            },
        ------------------------------------------------------------------------------------
        --- 枫叶松鼠
            {                
                name = "maple_squirrel",
                pet_prefab = "tbat_animal_maple_squirrel",
                debuff_prefab = "tbat_pet_collar_for_maple_squirrel",
                eyebone_fn = function(inst)                            
                            inst:WatchWorldState("phase",function()
                                inst:DoTaskInTime(1,function()
                                    if TheWorld.state.isday then
                                        inst:PushEvent("release_child")
                                    end
                                end)
                            end)
                end,
                pet_fn = function(inst)
                            inst.need_to_go_home = function(inst)
                                if not TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                                    return true
                                end
                                return false
                            end
                end
            },
        ------------------------------------------------------------------------------------
        --- 蘑菇蜗牛
            {                
                name = "mushroom_snail",
                pet_prefab = "tbat_animal_mushroom_snail",
                debuff_prefab = "tbat_pet_collar_for_mushroom_snail",
                eyebone_fn = function(inst)                            
                            -- inst:WatchWorldState("phase",function()
                            --     inst:DoTaskInTime(1,function()
                            --         if TheWorld.state.isday then
                            --             inst:PushEvent("release_child")
                            --         end
                            --     end)
                            -- end)
                end,
                pet_fn = function(inst)
                            -- inst.need_to_go_home = function(inst)
                            --     if not TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                            --         return true
                            --     end
                            --     return false
                            -- end
                end
            },
        ------------------------------------------------------------------------------------
        --- 薰衣草猫猫
            {                
                name = "lavender_kitty",
                pet_prefab = "tbat_pet_lavender_kitty",
                debuff_prefab = "tbat_pet_collar_for_lavender_kitty",
                eyebone_fn = function(inst)                            
                            -- inst:WatchWorldState("phase",function()
                            --     inst:DoTaskInTime(1,function()
                            --         if TheWorld.state.isday then
                            --             inst:PushEvent("release_child")
                            --         end
                            --     end)
                            -- end)
                end,
                pet_fn = function(inst)
                            -- inst.need_to_go_home = function(inst)
                            --     if not TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                            --         return true
                            --     end
                            --     return false
                            -- end
                end
            },
        ------------------------------------------------------------------------------------
        --- 帽子鳐鱼
            {                
                name = "stinkray",
                pet_prefab = "tbat_animal_stinkray",
                debuff_prefab = "tbat_pet_collar_for_stinkray",
                eyebone_fn = function(inst)                            
                            -- inst:WatchWorldState("phase",function()
                            --     inst:DoTaskInTime(1,function()
                            --         if TheWorld.state.isday then
                            --             inst:PushEvent("release_child")
                            --         end
                            --     end)
                            -- end)
                end,
                pet_fn = function(inst)
                            -- inst.need_to_go_home = function(inst)
                            --     if not TheWorld.state.isday and inst.GetPetHouse and inst:GetPetHouse() then
                            --         return true
                            --     end
                            --     return false
                            -- end
                end
            },
        ------------------------------------------------------------------------------------
    }
    local ret = {}
    for k, data in pairs(all_eyebone_data) do
        local ret_prefab = BASE_PREFAB.."_"..data.name
        local function fn()
            local inst = common_fn()
            inst.name = TBAT:GetString2(BASE_PREFAB,"name")
            inst.pet_prefab = data.pet_prefab
            inst.debuff_prefab = data.debuff_prefab
            inst:AddTag(ret_prefab)
            if not TheWorld.ismastersim then
                return inst
            end
            if data.eyebone_fn then
                data.eyebone_fn(inst)
            end
            inst.pet_fn = data.pet_fn
            return inst
        end
        table.insert(ret, Prefab(ret_prefab, fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)
