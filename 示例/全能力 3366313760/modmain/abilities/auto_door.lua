STRINGS.ACTIONS.AAB_SET_AUTO_DOOR = {
    GENERIC = AAB_L("Open Auto Door", "开启自动门"),
    CLOSE = AAB_L("Close Auto Door", "关闭自动门")
}

----------------------------------------------------------------------------------------------------

local Constructor = require("aab_utils/constructor")
Constructor.AddAction({ priority = 11 }, "AAB_SET_AUTO_DOOR", function(act)
    return act.target:HasTag("aab_auto_door") and "CLOSE" or nil
end, function(act)
    local target = act.target
    if target and target.components.aab_auto_door then
        if target:HasTag("aab_auto_door") then
            target.components.aab_auto_door:SetEnable(false)
        else
            target.components.aab_auto_door:SetEnable(true)
        end

        if target.SoundEmitter then
            target.SoundEmitter:PlaySound("dontstarve/common/together/gate/close")
        end

        return true
    end
end, "domediumaction", "domediumaction")

AAB_AddComponentAction("SCENE", "activatable", function(inst, doer, actions, right)
    if right
        and inst:HasTag("door")
        and inst:HasTag("inactive")
        and not (inst:HasTag("smolder") or inst:HasTag("fire"))
    then
        table.insert(actions, ACTIONS.AAB_SET_AUTO_DOOR)
    end
end)

----------------------------------------------------------------------------------------------------


AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst:HasTag("door") then
        inst:AddComponent("aab_auto_door")
    end
end)
