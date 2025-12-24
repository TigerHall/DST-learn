AddGamePostInit(function()
    -- for _, d in pairs(STRINGS.CHARACTERS) do
    --     d.DESCRIBE.WILLOW_EMBER = STRINGS.CHARACTERS.WILLOW.DESCRIBE.WILLOW_EMBER

    --     for k, v in pairs(d.ACTIONFAIL.CASTAOE) do
    --         if v == "only_used_by_willow" then
    --             d.ACTIONFAIL.CASTAOE[k] = STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.CASTAOE[k]
    --         end
    --     end
    -- end
    AAB_ReplaceCharacterLines("willow")
end)

----------------------------------------------------------------------------------------------------

local willow_ember_common

local function OnBecameGhost(inst)
    if inst._aab_willow_onentitydroplootfn ~= nil then
        inst:RemoveEventCallback("entity_droploot", inst._aab_willow_onentitydroplootfn, TheWorld)
        inst._aab_willow_onentitydroplootfn = nil
    end
    if inst._aab_willow_onentitydeathfn ~= nil then
        inst:RemoveEventCallback("entity_death", inst._aab_willow_onentitydeathfn, TheWorld)
        inst._aab_willow_onentitydeathfn = nil
    end
end

local function IsValidVictim(victim, explosive)
    return willow_ember_common.HasEmbers(victim) and (victim.components.health:IsDead() or explosive)
end

local function OnRestorEmber(victim)
    victim.noembertask = nil
end

local function OnEntityDropLoot(inst, data)
    local victim = data.inst
    if victim ~= nil and
        victim.noembertask == nil and
        victim:IsValid() and
        (victim == inst or
            (not inst.components.health:IsDead() and
                IsValidVictim(victim) and
                inst:IsNear(victim, TUNING.WILLOW_EMBERDROP_RANGE)
            )
        ) then
        --V2C: prevents multiple Willows in range from spawning multiple embers per corpse
        victim.noembertask = victim:DoTaskInTime(5, OnRestorEmber)
        willow_ember_common.SpawnEmbersAt(victim, willow_ember_common.GetNumEmbers(victim))
    end
end

local function OnEntityDeath(inst, data)
    if data.inst ~= nil then
        data.inst._embersource = data.afflicter                             -- Mark the victim.
        if (data.inst.components.lootdropper == nil or data.explosive) then -- NOTES(JBK): Explosive entities do not drop loot.
            OnEntityDropLoot(inst, data)
        end
    end
end

local function OnRespawnedFromGhost(inst)
    inst.components.freezable:SetResistance(3)

    if inst._aab_willow_onentitydroplootfn == nil then
        inst._aab_willow_onentitydroplootfn = function(src, data) OnEntityDropLoot(inst, data) end
        inst:ListenForEvent("entity_droploot", inst._aab_willow_onentitydroplootfn, TheWorld)
    end
    if inst._aab_willow_onentitydeathfn == nil then
        inst._aab_willow_onentitydeathfn = function(src, data) OnEntityDeath(inst, data) end
        inst:ListenForEvent("entity_death", inst._aab_willow_onentitydeathfn, TheWorld)
    end
end

local function TryToOnRespawnedFromGhost(inst)
    if not inst.components.health:IsDead() and not inst:HasTag("playerghost") then
        OnRespawnedFromGhost(inst)
    end
end

AAB_ActivateSkills("willow")


AddPlayerPostInit(function(inst)
    if inst.prefab == "willow" then return end

    inst:AddTag("pyromaniac")

    if not TheWorld.ismastersim then return end

    willow_ember_common = require("prefabs/willow_ember_common")

    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("ms_respawnedfromghost", OnRespawnedFromGhost)
    inst:DoTaskInTime(0, TryToOnRespawnedFromGhost) -- NOTES(JBK): Player loading in with zero health will still be alive here delay a frame to get loaded values.
    --    OnRespawnedFromGhost(inst)
end)
