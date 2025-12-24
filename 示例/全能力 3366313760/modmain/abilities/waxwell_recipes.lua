AddGamePostInit(function()
    -- for _, d in pairs(STRINGS.CHARACTERS) do
    --     if d.ANNOUNCE_EQUIP_SHADOWLEVEL_T1 == "only_used_by_waxwell" then
    --         d.ANNOUNCE_EQUIP_SHADOWLEVEL_T1 = STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_EQUIP_SHADOWLEVEL_T1
    --     end
    --     if d.ANNOUNCE_EQUIP_SHADOWLEVEL_T2 == "only_used_by_waxwell" then
    --         d.ANNOUNCE_EQUIP_SHADOWLEVEL_T2 = STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_EQUIP_SHADOWLEVEL_T2
    --     end
    --     if d.ANNOUNCE_EQUIP_SHADOWLEVEL_T3 == "only_used_by_waxwell" then
    --         d.ANNOUNCE_EQUIP_SHADOWLEVEL_T3 = STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_EQUIP_SHADOWLEVEL_T3
    --     end
    --     if d.ANNOUNCE_EQUIP_SHADOWLEVEL_T4 == "only_used_by_waxwell" then
    --         d.ANNOUNCE_EQUIP_SHADOWLEVEL_T4 = STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_EQUIP_SHADOWLEVEL_T4
    --     end
    --     if d.ANNOUNCE_SHADOWLEVEL_ITEM == "only_used_by_waxwell" then
    --         d.ANNOUNCE_SHADOWLEVEL_ITEM = STRINGS.CHARACTERS.WAXWELL.ANNOUNCE_SHADOWLEVEL_ITEM
    --     end
    --     if d.DESCRIBE.WAXWELLJOURNAL and d.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL == "only_used_by_waxwell" then
    --         d.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL = STRINGS.CHARACTERS.WAXWELL.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL
    --     end


    --     for k, v in pairs(d.ACTIONFAIL.CASTAOE) do
    --         if v == "only_used_by_waxwell" then
    --             d.ACTIONFAIL.CASTAOE[k] = STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.CASTAOE[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.CAST_SPELLBOOK) do
    --         if v == "only_used_by_waxwell" then
    --             d.ACTIONFAIL.CAST_SPELLBOOK[k] = STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.CAST_SPELLBOOK[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.OPEN_CRAFTING) do
    --         if v == "only_used_by_waxwell" then
    --             d.ACTIONFAIL.OPEN_CRAFTING[k] = STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.OPEN_CRAFTING[k]
    --         end
    --     end
    -- end
    AAB_ReplaceCharacterLines("waxwell")
end)
----------------------------------------------------------------------------------------------------

local Utils = require("aab_utils/utils")
local player_common_extensions = require("prefabs/player_common_extensions")
Utils.FnDecorator(player_common_extensions, "GivePlayerStartingItems", function(inst)
    if inst.components.inventory and inst.prefab ~= "waxwell" then
        inst.components.inventory.ignoresound = true
        inst.components.inventory:GiveItem(SpawnPrefab("waxwelljournal"))
        inst.components.inventory.ignoresound = false
    end
end)

----------------------------------------------------------------------------------------------------

local function KillPet(pet)
    if pet.components.health:IsInvincible() then
        --reschedule
        pet._killtask = pet:DoTaskInTime(.5, KillPet)
    else
        pet.components.health:Kill()
    end
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            --if not inst.components.builder.freebuildmode then
            inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
            --end
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
            pet.components.skinner:CopySkinsFromPlayer(inst)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
        return nil, true
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not inst.is_snapshot_user_session and pet.sg ~= nil then
            pet.sg:GoToState("quickdespawn")
        else
            pet:Remove()
        end
        return nil, true
    end
end

----------------------------------------------------------------------------------------------------

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") and v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function OnBecameGhost(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            inst:RemoveEventCallback("onremove", inst._onpetlost, v)
            inst.components.sanity:RemoveSanityPenalty(v)
            if v._killtask == nil then
                v._killtask = v:DoTaskInTime(math.random(), KillPet)
            end
        end
    end
    if not GetGameModeProperty("no_sanity") then
        inst.components.sanity.ignore = false
        inst.components.sanity:SetPercent(.5, true)
        inst.components.sanity.ignore = true
    end
end

local function ForceDespawnShadowMinions(inst)
    local todespawn = {}
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            table.insert(todespawn, v)
        end
    end
    for i, v in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(v)
    end
end

local function OnDespawn(inst, migrationdata)
    if migrationdata ~= nil then
        ForceDespawnShadowMinions(inst)
    end
end

local function DoAnnounceShadowLevel(inst, params, item)
    params.task = nil

    if inst.components.health:IsDead() or inst:HasTag("playerghost") then
        return
    end

    local level = item:IsValid() and item.components.shadowlevel ~= nil and item.components.shadowlevel:GetCurrentLevel() or 0
    if level <= 0 or
        not (item.components.equippable ~= nil and item.components.equippable:IsEquipped()) or
        not (item.components.inventoryitem ~= nil and item.components.inventoryitem:IsHeldBy(inst))
    then
        return
    end

    level = math.min(4, level)

    local t = GetTime()
    if t < (params.levels[level] or -math.huge) + 600 then
        --Suppress announcements until haven't worn anything this level in over 10min.
        --Note that timer starts from last unequipped.
        params.levels[level] = t
        return
    end

    if inst.sg:HasStateTag("talking") or (level <= params.level and t < params.time + 3) then
        --busy talking, or announced equal or higher level less than 3 seconds ago
        return
    end

    params.time = t
    params.level = level
    params.levels[level] = t

    --For searching:
    --ANNOUNCE_EQUIP_SHADOWLEVEL_T1
    --ANNOUNCE_EQUIP_SHADOWLEVEL_T2
    --ANNOUNCE_EQUIP_SHADOWLEVEL_T3
    --ANNOUNCE_EQUIP_SHADOWLEVEL_T4
    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EQUIP_SHADOWLEVEL_T" .. tostring(level)))
end

local function OnEquip(inst, data)
    if data ~= nil and data.item ~= nil and data.item.components.shadowlevel ~= nil then
        --default level ignoring fuel
        local level = data.item.components.shadowlevel.level
        if level > 0 then
            local params = inst._announceshadowlevel
            if params.task ~= nil then
                params.task:Cancel()
            end
            local t = GetTime()
            if t > inst.spawntime then
                params.task = inst:DoTaskInTime(.5, DoAnnounceShadowLevel, params, data.item)
            else
                --Just spawned, suppress announcements
                params.task = nil
                params.levels[math.min(4, level)] = GetTime()
            end
        end
    end
end

local function OnUnequip(inst, data)
    if data ~= nil and data.item ~= nil and data.item.components.shadowlevel ~= nil then
        --default level ignoring fuel
        local level = data.item.components.shadowlevel.level
        if level > 0 then
            inst._announceshadowlevel.levels[math.min(4, level)] = GetTime()
        end
    end
end

AddPlayerPostInit(function(inst)
    if inst.prefab == "waxwell" then return end

    inst:AddTag("magician") --使用高礼帽
    inst:AddTag("shadowmagic")

    if not TheWorld.ismastersim then return end

    inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + 6)
    Utils.FnDecorator(inst.components.petleash, "onspawnfn", OnSpawnPet)
    Utils.FnDecorator(inst.components.petleash, "ondespawnfn", OnDespawnPet)

    inst._onpetlost = function(pet) inst.components.sanity:RemoveSanityPenalty(pet) end

    inst:AddComponent("magician")
    inst:DoTaskInTime(0, function()
        inst.components.magician:StopUsing() --需要在inventory初始化好后执行
    end)

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("ms_playerreroll", ForceDespawnShadowMinions)

    --Shadow level announcements
    inst:ListenForEvent("equip", OnEquip)
    inst:ListenForEvent("unequip", OnUnequip)
    inst._announceshadowlevel =
    {
        task = nil,
        time = -math.huge,
        level = 0,
        levels = {},
    }

    Utils.FnDecorator(inst, "OnDespawn", OnDespawn)

    inst:AddComponent("aab_waxwell")
end)
