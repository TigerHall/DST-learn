--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 交互
    local function workable_test_fn(inst,doer,right_click)
        if right_click and inst:HasTag("pet") and not inst:HasTag("following_player") then
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        local call_back_table = {
            doer = doer,
            succeed = false,
        }
        inst:PushEvent("tbat_event.pet_follow_target",call_back_table)
        return call_back_table.succeed
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("start_follow_player",TBAT:GetString2("tbat_building_pet_house_common","start_follow_player"))
        replica_com:SetSGAction("dolongaction")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- following
    local function GetFollowingPlayer(inst)
        local leader = inst.components.follower:GetLeader()
        if leader then
            if leader:HasTag("player") then
                return leader
            end
            if leader.components.inventoryitem then
                local owner = leader.components.inventoryitem:GetGrandOwner()
                if owner and owner:HasTag("player") then
                    return owner
                end
            end
        end
        return nil
    end
    local function GetPetHouse(inst)
        local leader = inst.components.follower:GetLeader()
        if leader and leader:IsValid() then
            if leader:HasTag("tbat_pet_eyebone_box") then
                return leader
            end
            local owner = leader.components.inventoryitem and leader.components.inventoryitem:GetGrandOwner()
            if owner and owner:IsValid() and owner:HasTag("tbat_pet_eyebone_box") then
                return owner
            end
        end
        return nil
    end
    local function GetEyeBone(inst)
        local leader = inst.components.follower:GetLeader()
        if leader and leader:IsValid() and leader:HasTag("tbat_pet_eyebone") then
            return leader
        end
        return nil
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    workable_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst.GetFollowingPlayer = GetFollowingPlayer
    inst.GetPetHouse = GetPetHouse
    inst.GetEyeBone = GetEyeBone
end