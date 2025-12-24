STRINGS.NAMES.AAB_SUPERBUNDLE = "建筑包裹"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_SUPERBUNDLE = "我应该可以找个地方放置它。"

table.insert(PrefabFiles, "aab_superbundle")

----------------------------------------------------------------------------------------------------

local Constructor = require("aab_utils/constructor")

Constructor.AddAction({ priority = 11 }, "AAB_SUPER_PACK", AAB_L("Pack", "打包"), function(act)
    act.invobject.components.stackable:Get():Remove()
    local ent = SpawnPrefab("aab_superbundle")
    ent:Setup(act.target)
    act.doer.components.inventory:GiveItem(ent)

    return true
end, "dolongaction", "dolongaction")

AAB_AddComponentAction("USEITEM", "bundlemaker", function(inst, doer, target, actions, right)
    if inst.prefab == "bundlewrap" and not target:HasTag("player") then --不要打包队友
        table.insert(actions, ACTIONS.AAB_SUPER_PACK)
    end
end)
