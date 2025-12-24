local function OnStartFollowing(inst, data)
    inst._aab_crazy = inst:HasTag("crazy")
    if data and data.leader and data.leader:HasTag("player") then
        inst:AddTag("crazy")
    end
end
local function OnStopFollowing(inst, data)
    if not inst._aab_crazy then
        inst:RemoveTag("crazy")
    end
end

AddComponentPostInit("follower", function(self, inst)
    inst:RemoveEventCallback("startfollowing", OnStartFollowing)
    inst:RemoveEventCallback("stopfollowing", OnStopFollowing)
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
end)
