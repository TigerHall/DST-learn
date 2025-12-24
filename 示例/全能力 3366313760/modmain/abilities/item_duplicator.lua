local ITEM_DUPLICATOR = GetModConfigData("item_duplicator")

table.insert(PrefabFiles, "aab_item_duplicator")


STRINGS.NAMES.AAB_ITEM_DUPLICATOR = AAB_L("Item duplicator", "物品复制机")
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_ITEM_DUPLICATOR = AAB_L("It holds deep secrets.", "它藏有深深的秘密。")
STRINGS.RECIPE_DESC.AAB_ITEM_DUPLICATOR = AAB_L("creating something out of nothing", "无中生有。")


STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.BUILD.AAB_MAX_COUNT = AAB_L("We've reached our limit.", "已经达到数量上限了。")
----------------------------------------------------------------------------------------------------
local params = require("containers").params

params.aab_item_duplicator =
{
    widget =
    {
        slotpos = {
            Vector3(-2, 18, 0),
        },
        animbank = "ui_alterguardianhat_1x1",
        animbuild = "ui_alterguardianhat_1x1",
        pos = Vector3(0, 160, 0),
    },
    type = "chest",
}

function params.aab_item_duplicator.itemtestfn(container, item, slot)
    return item.replica.stackable
end

----------------------------------------------------------------------------------------------------

AAB_AddCharacterRecipe("aab_item_duplicator", { Ig("gears", 4), Ig("transistor", 4), Ig("purplegem", 2) }, {
    placer = "aab_item_duplicator_placer",
    canbuild = function()
        if ITEM_DUPLICATOR == -1 then return true end

        local count = 0
        for k, v in pairs(TheWorld._aab_item_duplicators or {}) do
            if k:IsValid() then
                count = count + 1
            else
                TheWorld._aab_item_duplicators[k] = nil --清除一下无效对象
            end
        end

        return count < ITEM_DUPLICATOR, "AAB_MAX_COUNT"
    end
})

----------------------------------------------------------------------------------------------------

AddPrefabPostInit("aab_item_duplicator", function(inst)
    if not TheWorld.ismastersim then return end

    TheWorld._aab_item_duplicators = TheWorld._aab_item_duplicators or {}
    TheWorld._aab_item_duplicators[inst] = true
end)
