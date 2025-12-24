local Utils = require("aab_utils/utils")

TUNING.AAB_MY_PIG_HEALTH = 400
TUNING.AAB_MY_PIG_HEALTH_HEAL = 3

STRINGS.NAMES.AAB_MY_PIG = AAB_L("Pigman friend", "猪哥")
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_MY_PIG = AAB_L("Full of security.", "满满的安全感。")

STRINGS.ACTIONS.AAB_MY_PIG_SUMMON = {
    GENERIC = "召唤",
    UNSUMMON = "召回"
}

table.insert(PrefabFiles, "aab_my_pig")

AddReplicableComponent("aab_my_pig")

-- 注册可写，跟小木牌的一样就行
local writeables = require("writeables")
local homesign = writeables.GetLayout("homesign")
writeables.AddLayout("aab_my_pig", homesign)

----------------------------------------------------------------------------------------------------

local player_common_extensions = require("prefabs/player_common_extensions")
Utils.FnDecorator(player_common_extensions, "GivePlayerStartingItems", function(inst)
    if inst.components.inventory then
        inst.components.inventory.ignoresound = true
        inst.components.inventory:GiveItem(SpawnPrefab("pig_token"))
        inst.components.inventory.ignoresound = false
    end
end)

----------------------------------------------------------------------------------------------------

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:AddComponent("aab_my_pig")
end)

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.equippable then
        if not inst.components.tradable then
            inst:AddComponent("tradable") --我希望装备都可以给猪人
        end
    end
end)

----------------------------------------------------------------------------------------------------
local Constructor = require("aab_utils/constructor")
Constructor.AddAction({ mount_valid = true }, "AAB_MY_PIG_SUMMON", function(act)
    return act.doer.replica.aab_my_pig and act.doer.replica.aab_my_pig:GetPig() and "UNSUMMON" or nil
end, function(act)
    local pig = act.doer.components.aab_my_pig.pig
    if pig and pig:IsValid() then
        act.doer.components.aab_my_pig:Unsummon()
    else
        act.doer.components.aab_my_pig:Summon()
    end
    return true
end, "domediumaction", "domediumaction")

AAB_AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions, right)
    if inst.prefab == "pig_token" then
        table.insert(actions, ACTIONS.AAB_MY_PIG_SUMMON)
    end
end)


-- Constructor.AddAction({}, "AAB_MY_PIG_NAME", function(act)
--     return act.doer.replica.aab_my_pig and act.doer.replica.aab_my_pig:GetPig() and "UNSUMMON" or nil
-- end, function(act)
--     local pig = act.target
--     if pig and pig:IsValid() and not pig.components.writeable:IsWritten() and not act.target.components.writeable:IsBeingWritten() then
--         pig.components.writeable.text = nil --其实不写也行
--         pig.components.writeable:BeginWriting(act.doer)
--     end
--     return true
-- end, "domediumaction", "domediumaction")
AAB_AddComponentAction("USEITEM", "drawingtool", function(inst, doer, target, actions, right)
    if inst.prefab == "featherpencil" and target.prefab == "aab_my_pig"
        and target.aab_leader and target.aab_leader:value() == doer
    then
        table.insert(actions, ACTIONS.WRITE)
    end
end)

----------------------------------------------------------------------------------------------------

AddClassPostConstruct("widgets/hoverer", function(self)
    local OldSetString = self.text.SetString
    self.text.SetString = function(text, str)
        local target = TheInput:GetHUDEntityUnderMouse()
        target = (target and target.widget and target.widget.parent and target.widget.parent.item)
            or TheInput:GetWorldEntityUnderMouse()
        if not target or not target.replica or not target.components then return OldSetString(text, str) end --好像target有可能不是预制件

        -- 修改str
        if target.prefab == "aab_my_pig" and target.GetLevel then
            str = str .. AAB_L("\nLevel: ", "\n等级：") .. target:GetLevel()
        end

        return OldSetString(text, str)
    end
end)
