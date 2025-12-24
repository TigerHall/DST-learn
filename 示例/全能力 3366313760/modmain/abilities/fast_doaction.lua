local Utils = require("aab_utils/utils")

local function RemoveTagBefore(inst, tag)
    return nil, tag == "fastpicker" or tag == "fastbuilder"
end

AddPlayerPostInit(function(inst)
    inst:AddTag("fastbuilder")
    inst:AddTag("fastpicker")

    if not TheWorld.ismastersim then return end

    Utils.FnDecorator(inst, "RemoveTag", RemoveTagBefore)
end)

----------------------------------------------------------------------------------------------------

AddStategraphPostInit("wilson", function(sg)
    Utils.FnDecorator(sg.states["dolongaction"], "onenter", function(inst, timeout)
        return nil, false, { inst, math.min(timeout or 1, 0.5) }
    end)
end)

AddStategraphPostInit("wilson_client", function(sg)
    Utils.FnDecorator(sg.states["dolongaction"], "onenter", function(inst, timeout)
        return nil, false, { inst, math.min(timeout or 1, 0.5) }
    end)
end)
