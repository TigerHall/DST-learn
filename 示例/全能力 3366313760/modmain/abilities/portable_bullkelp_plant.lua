local Constructor = require("aab_utils/constructor")

local function ExtraPickupRange(doer, dest)
    if dest ~= nil then
        local target_x, target_y, target_z = dest:GetPoint()

        local is_on_water = TheWorld.Map:IsOceanTileAtPoint(target_x, 0, target_z) and not TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
        if is_on_water then
            return 0.75
        end
    end
    return 0
end

Constructor.AddAction({ priority = 5, extra_arrive_dist = ExtraPickupRange }, "AAB_PICKUP_BULLKELP_PLANT", AAB_L("Pickup", "拾取"), function(act)
    if act.target:HasTag("pickable") then
        act.target.components.pickable:Pick(act.doer)
    end
    act.doer.components.inventory:GiveItem(SpawnPrefab("bullkelp_root"))
    act.target:Remove()
    return true
end, "doshortaction", "doshortaction")


AAB_AddComponentAction("SCENE", "pickable", function(inst, doer, actions, right)
    if right and inst.prefab == "bullkelp_plant" then
        table.insert(actions, ACTIONS.AAB_PICKUP_BULLKELP_PLANT)
    end
end)

----------------------------------------------------------------------------------------------------

AddPrefabPostInit("bullkelp_plant", function(inst)
    inst:AddTag("NOBLOCK")
end)
