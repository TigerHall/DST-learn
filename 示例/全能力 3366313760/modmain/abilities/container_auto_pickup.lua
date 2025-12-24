TUNING.AAB_CONTAINER_AUTO_PICKUP = GetModConfigData("container_auto_pickup")
table.insert(PrefabFiles, "aab_polly_rogers")

----------------------------------------------------------------------------------------------------

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.container then
        inst:AddComponent("aab_container_auto_pickup")
    end
end)

----------------------------------------------------------------------------------------------------
AddStategraphActionHandler("polly_rogers", ActionHandler(ACTIONS.STORE, "give"))

-- 修复科雷的bug，鸟被冻住后就动不了了
AddStategraphPostInit("polly_rogers", function(sg)
    sg.states["hit"].events["animover"].fn = function(inst)
        if inst.AnimState:AnimDone() then --科雷把这里错加了一个false
            inst.sg.statemem.stayonground = true
            inst.sg:GoToState("idle_ground")
        end
    end
end)

----------------------------------------------------------------------------------------------------

AAB_AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if right and inst.prefab == "goldnugget" and target.replica.container then
        table.insert(actions, ACTIONS.AAB_CONTAINER_AUTO_PICKUP)
    end
end)

STRINGS.ACTIONS.AAB_CONTAINER_AUTO_PICKUP = {
    GENERIC = "开启自动拾取",
    CLOSE = "关闭自动拾取"
}

local Constructor = require("aab_utils/constructor")
Constructor.AddAction({ priority = 5 }, "AAB_CONTAINER_AUTO_PICKUP", function(act)
    return act.target:HasTag("aab_container_auto_pickup") and "CLOSE" or nil
end, function(act)
    if act.target and act.target.components.aab_container_auto_pickup then
        act.target.components.aab_container_auto_pickup:SetEnable(not act.target:HasTag("aab_container_auto_pickup"))
        act.invobject.components.stackable:Get():Remove()
        return true
    end
end, "dolongaction", "dolongaction")
