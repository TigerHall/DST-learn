local Utils = require("aab_utils/utils")

local RETARGET_CANT_TAGS

AddPrefabPostInit("tallbird", function(inst)
    if not TheWorld.ismastersim then return end

    if not RETARGET_CANT_TAGS then
        RETARGET_CANT_TAGS = Utils.ChainFindUpvalue(inst.components.combat.targetfn, "RETARGET_CANT_TAGS")
        if RETARGET_CANT_TAGS then
            table.insert(RETARGET_CANT_TAGS, "player")
        end
    end
end)

----------------------------------------------------------------------------------------------------

local function OnPickedBefore(inst, picker, ...)
    return nil, false, { inst, nil, ... } --把采集者去掉，别攻击玩家
end

AddPrefabPostInit("tallbirdnest", function(inst)
    if not TheWorld.ismastersim then return end

    Utils.FnDecorator(inst.components.pickable, "onpickedfn", OnPickedBefore)
end)
