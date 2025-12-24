local GetPrefab = require("aab_utils/getprefab")

local HEALTH_REGEN = GetModConfigData("health_regen") / 100

local function Heal(inst)
    if not GetPrefab.IsEntityDeadOrGhost(inst) then
        inst.components.health:DoDelta(HEALTH_REGEN, true, "debug_key") --兼容旺达
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:DoPeriodicTask(1, Heal)
end)
