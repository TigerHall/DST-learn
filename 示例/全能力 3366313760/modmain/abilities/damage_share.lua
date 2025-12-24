local Utils = require("aab_utils/utils")
local DAMAGE_SHARE = GetModConfigData("damage_share") / 100

local function DoDeltaBefore(self, amount, ...)
    if amount >= 0 then return end

    local followers = {}
    local total_health = 0
    for k in pairs(self.inst.components.leader.followers) do
        if not IsEntityDead(k, true) then
            table.insert(followers, k)
            total_health = total_health + k.components.health.currenthealth
        end
    end
    if #followers <= 0 then return end --没有能分担伤害的随从

    local damage_share = amount * DAMAGE_SHARE
    for _, v in ipairs(followers) do
        local share = (v.components.health.currenthealth / total_health) * damage_share --血量越高的生物承受的伤害越高
        v.components.health:DoDelta(share, ...)
    end

    return nil, false, { self, amount - damage_share, ... }
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    Utils.FnDecorator(inst.components.health, "DoDelta", DoDeltaBefore)
end)
