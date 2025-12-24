local SPLASH_DAMAGE = GetModConfigData("splash_damage")

local ATTACK_MUST_TAGS = { "_health", "_combat" }
local ATTACK_CANT_TAGS = { "player", "INLIMBO", "companion" }

local function OnAttacked(inst, data)
    if data and data.attacker and data.attacker:HasTag("player") and data.damage and not data.attacker._aab_splash_damage then
        data.attacker._aab_splash_damage = true --防止递归
        local x, y, z = inst.Transform:GetWorldPosition()
        for _, v in ipairs(TheSim:FindEntities(x, y, z, 4, ATTACK_MUST_TAGS, ATTACK_CANT_TAGS)) do
            if v.prefab == inst.prefab and data.attacker.components.combat:CanTarget(v) then
                v.components.combat:GetAttacked(data.attacker, data.damage * SPLASH_DAMAGE, data.weapon, data.stimuli, data.spdamage)
            end
        end
        data.attacker._aab_splash_damage = nil
    end
end

AddComponentPostInit("combat", function(self, inst)
    if not inst:HasTag("player") then
        inst:RemoveEventCallback("attacked", OnAttacked)
        inst:ListenForEvent("attacked", OnAttacked)
    end
end)
