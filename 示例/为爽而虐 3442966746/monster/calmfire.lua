require "behaviours/panic"
local BrainCommon = require("brains/braincommon")
local ShouldTriggerPanic = BrainCommon.ShouldTriggerPanic
BrainCommon.ShouldTriggerPanic = function(inst)
    local result = ShouldTriggerPanic(inst)
    if result and inst.components.combat ~= nil and inst.components.combat.target ~= nil and inst.components.combat.defaultdamage > 0 then
        return GetTime() - inst.components.combat.lastwasattackedtime > inst.components.combat.min_attack_period * 2
    end
    return result
end
BrainCommon.PanicTrigger = function(inst) return WhileNode(function() return BrainCommon.ShouldTriggerPanic(inst) end, "PanicTrigger", Panic(inst)) end
