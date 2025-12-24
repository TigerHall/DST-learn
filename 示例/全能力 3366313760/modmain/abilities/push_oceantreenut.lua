local Constructor = require("aab_utils/constructor")

local function Move(inst, targetpos)
    local pos = inst:GetPosition()
    local isocean = TheWorld.Map:IsOceanAtPoint(pos.x, 0, pos.z)
    if inst.components.inventoryitem.owner
        or isocean
        or distsq(pos, targetpos) <= 0.1
        or inst._aab_count >= 50 then
        inst._aab_count = nil
        if inst._aab_movetask then
            inst._aab_movetask:Cancel()
            inst._aab_movetask = nil
        end
        if isocean then
            SpawnAt("waterstreak_burst", inst)
        else
            -- 如果没掉水里再改回来
            inst.components.submersible.force_no_repositioning = false
        end
        return
    end

    local rot = inst:GetAngleToPoint(targetpos:Get()) * DEGREES
    local nextpos = pos + Vector3(0.01 * math.cos(rot), 0, -0.01 * math.sin(rot)) --z轴需要反过来
    inst.Physics:Teleport(nextpos.x, nextpos.y, nextpos.z)
    inst._aab_count = inst._aab_count + 1
end

Constructor.AddAction({}, "AAB_PUSH_OCEANTREENUT", AAB_L("Push", "推"), function(act)
    local target = act.target
    if target._aab_movetask then
        return true
    end

    local pos = target:GetPosition()
    local rot = act.doer:GetAngleToPoint(pos:Get()) * DEGREES
    local targetpos = pos + Vector3(math.cos(rot), 0, -math.sin(rot)) --z轴需要反过来
    target.components.submersible.force_no_repositioning = true
    target.components.submersible:MakeSunken(pos.x, pos.z, true, true)

    target._aab_count = 0
    target._aab_movetask = target:DoPeriodicTask(0, Move, 0, targetpos)

    return true
end, "give", "give")

AAB_AddComponentAction("SCENE", "heavyobstaclephysics", function(inst, doer, actions, right)
    if inst.prefab == "oceantreenut" then
        table.insert(actions, ACTIONS.AAB_PUSH_OCEANTREENUT)
    end
end)
