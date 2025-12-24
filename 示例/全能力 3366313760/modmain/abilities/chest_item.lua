table.insert(PrefabFiles, "aab_chestplacers")

----------------------------------------------------------------------------------------------------

local function ondeploy(inst, pt, deployer)
    inst.Physics:Teleport(pt.x, 0, pt.z)
    inst.components.aab_portablechest:SetItem(false, deployer)
    if inst.components.container.infinitestacksize then
        --如果是升级后箱子不应该推送，因为没有place动画
        if inst.skin_place_sound then
            inst.SoundEmitter:PlaySound(inst.skin_place_sound)
        elseif inst.sounds and inst.sounds.built then
            inst.SoundEmitter:PlaySound(inst.sounds.built)
        end
    else
        inst:PushEvent("onbuilt", { builder = deployer, pos = pt })
    end
end

for _, v in ipairs({
    "treasurechest",
    "dragonflychest",
    "pandoraschest",
    "minotaurchest",
    "terrariumchest",
    "icebox",
    "saltbox"
}) do
    -- 因为默认是物品
    local recipe = AllRecipes[v]
    if recipe then
        recipe.placer = nil
        recipe.testfn = nil
    end

    AddPrefabPostInit(v, function(inst)
        MakeInventoryPhysics(inst)

        inst:AddTag("portableitem")

        if not TheWorld.ismastersim then return end

        inst:AddComponent("aab_portablechest")

        if not inst.components.inventoryitem then
            inst:AddComponent("inventoryitem")
        end
        inst.components.inventoryitem.canonlygoinpocket = true
        if v == "pandoraschest" or v == "minotaurchest" or v == "terrariumchest" then
            inst.components.inventoryitem.imagename = "treasurechest" --没有物品栏贴图
        end

        if not inst.components.deployable then
            inst:AddComponent("deployable")
        end
        inst.components.deployable.ondeploy = ondeploy
    end)
end


----------------------------------------------------------------------------------------------------
local Constructor = require("aab_utils/constructor")

Constructor.AddAction({}, "AAB_DISMANTLE_CHEST", AAB_L("Dismantle", "收回"), function(act)
    act.target.components.aab_portablechest:SetItem(true, act.doer)
    return true
end, "dolongaction", "dolongaction")

AAB_AddComponentAction("SCENE", "aab_portablechest", function(inst, doer, actions, right)
    if right and inst.replica.inventoryitem and not inst.replica.inventoryitem:CanBePickedUp(doer) then
        table.insert(actions, ACTIONS.AAB_DISMANTLE_CHEST)
    end
end)
