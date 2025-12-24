table.insert(PrefabFiles, "aab_rabbithole_placer")

table.insert(Assets, Asset("ATLAS", "images/inventoryimages/rabbithole.xml"))
RegisterInventoryItemAtlas("images/inventoryimages/rabbithole.xml", "rabbithole.tex")

----------------------------------------------------------------------------------------------------

STRINGS.RECIPE_DESC.RABBITHOLE = STRINGS.CHARACTERS.GENERIC.DESCRIBE.RABBITHOLE.GENERIC

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.AAB_CATCH_RABBIT = {
    NOT_RABBIT = AAB_L("There may not be a rabbit in it.", "里面可能没有兔子。"),
}
----------------------------------------------------------------------------------------------------

AAB_AddCharacterRecipe("aab_rabbithole", { Ig("rabbit", 2) }, {
    product = "rabbithole",
    placer = "aab_rabbithole_placer",
    min_spacing = 1
})



----------------------------------------------------------------------------------------------------
local function OnBuilt(inst, data)
    inst.components.spawner:ReleaseChild()
end

local function GoHomeAfter(retTab, self)
    if retTab[1] then
        self.inst:AddTag("aab_occupied")
    end
    return retTab
end

local function ReleaseChildAfter(retTab, self)
    if retTab[1] then
        self.inst:RemoveTag("aab_occupied")
    end
    return retTab
end

local Utils = require("aab_utils/utils")
AddPrefabPostInit("rabbithole", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onbuilt", OnBuilt)

    Utils.FnDecorator(inst.components.spawner, "GoHome", nil, GoHomeAfter)
    Utils.FnDecorator(inst.components.spawner, "ReleaseChild", nil, ReleaseChildAfter)
end)


----------------------------------------------------------------------------------------------------

local Constructor = require("aab_utils/constructor")

Constructor.AddAction({}, "AAB_CATCH_RABBIT", AAB_L("Catch", "抓取"), function(act)
    if act.target and act.target.components.spawner
        and act.target.components.spawner:IsOccupied()
        and act.target.components.spawner:ReleaseChild()
    then
        local child = act.target.components.spawner.child
        act.doer.components.inventory:GiveItem(child)
        return true
    end

    return false, "NOT_RABBIT"
end, "domediumaction", "domediumaction")

AAB_AddComponentAction("SCENE", "spawner", function(inst, doer, actions, right)
    if right and inst.prefab == "rabbithole" then
        table.insert(actions, ACTIONS.AAB_CATCH_RABBIT)
    end
end)


----------------------------------------------------------------------------------------------------

-- 兼容行为队列学
AddComponentPostInit("actionqueuer", function()
    -- pcall(AddActionQueuerAction, "allclick", "AAB_CATCH_RABBIT", true)
    pcall(AddActionQueuerAction, "rightclick", "AAB_CATCH_RABBIT", function(target)
        --不加判断的话会一直待着一个洞薅的
        return target:HasTag("aab_occupied")
    end)
end)
