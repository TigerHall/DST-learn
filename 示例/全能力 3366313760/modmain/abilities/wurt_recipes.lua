--[[
也许不该加这个能力，需要拷贝的代码太多了，以后维护多累啊

]]

local Utils = require("aab_utils/utils")

AAB_ActivateSkills("wurt")


table.insert(PrefabFiles, "aab_disguisehat")

STRINGS.NAMES.AAB_DISGUISEHAT = "伪装面具"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_DISGUISEHAT = "谁会对那种伪装信以为真？"
STRINGS.RECIPE_DESC.AAB_DISGUISEHAT = "这是用来骗猪的。"

AAB_AddCharacterRecipe("aab_disguisehat", { Ig("twigs", 2), Ig("pigskin", 1), Ig("beardhair", 1) }, nil, { "CHARACTER", "CLOTHING" })

----------------------------------------------------------------------------------------------------

local function perish_rate_multiplier_before(inst, item)
    return { TUNING.WURT_FISH_PRESERVER_RATE }, item ~= nil and item:HasTag("fish")
end

----------------------------------------------------------------------------------------------------

-- Merm King quest upgrades
local TRIDENT_BUFF_NAME, TRIDENT_BUFF_PREFAB = "mermkingtridentbuff", "mermking_buff_trident"
local function TryRoyalUpgradeTrident(inst, silent)
    if not TheWorld.components.mermkingmanager
        or not TheWorld.components.mermkingmanager:HasTridentAnywhere() then
        return
    end
    inst:AddDebuff(TRIDENT_BUFF_NAME, TRIDENT_BUFF_PREFAB)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            if follower.ismerm then
                follower:AddDebuff(TRIDENT_BUFF_NAME, TRIDENT_BUFF_PREFAB)
            end
        end
    end
end
local function TryRoyalDowngradeTrident(inst, silent)
    inst:RemoveDebuff(TRIDENT_BUFF_NAME)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            follower:RemoveDebuff(TRIDENT_BUFF_NAME)
        end
    end
end

local CROWN_BUFF_NAME, CROWN_BUFF_PREFAB = "mermkingcrownbuff", "mermking_buff_crown"
local function TryRoyalUpgradeCrown(inst, silent)
    if not TheWorld.components.mermkingmanager
        or not TheWorld.components.mermkingmanager:HasCrownAnywhere() then
        return
    end
    inst:AddDebuff(CROWN_BUFF_NAME, CROWN_BUFF_PREFAB)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            if follower.ismerm then
                follower:AddDebuff(CROWN_BUFF_NAME, CROWN_BUFF_PREFAB)
            end
        end
    end
end
local function TryRoyalDowngradeCrown(inst, silent)
    inst:RemoveDebuff(CROWN_BUFF_NAME)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            follower:RemoveDebuff(CROWN_BUFF_NAME)
        end
    end
end

local PAULDRON_BUFF_NAME, PAULDRON_BUFF_PREFAB = "mermkingpauldronbuff", "mermking_buff_pauldron"
local function TryRoyalUpgradePauldron(inst, silent)
    if not TheWorld.components.mermkingmanager
        or not TheWorld.components.mermkingmanager:HasPauldronAnywhere() then
        return
    end
    inst:AddDebuff(PAULDRON_BUFF_NAME, PAULDRON_BUFF_PREFAB)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            if follower.ismerm then
                follower:AddDebuff(PAULDRON_BUFF_NAME, PAULDRON_BUFF_PREFAB)
            end
        end
    end
end
local function TryRoyalDowngradePauldron(inst, silent)
    inst:RemoveDebuff(PAULDRON_BUFF_NAME)

    if inst.components.leader then
        for follower in pairs(inst.components.leader.followers) do
            follower:RemoveDebuff(PAULDRON_BUFF_NAME)
        end
    end
end

----------------------------------------------------------------------------------------------------
local function OnRespawnedFromGhost(inst)
    inst:RemoveEventCallback("ms_respawnedfromghost", inst._onrespawnedfromghost)
    inst._onrespawnedfromghost = nil

    inst:RefreshWetnessSkills()
end

local function OnAllegianceMarshTile(inst, ontile)
    if inst.components.moisture == nil then
        return
    end

    if ontile then
        inst.components.moisture:AddRateBonus(inst, TUNING.SKILLS.WURT.ALLEGIANCE_MARSHTILE_MOISTURE_RATE, "marsh_wetness")
    else
        inst.components.moisture:RemoveRateBonus(inst, "marsh_wetness")
    end
end

local NUM_SPLASH_FX = 3

local function RedirectDamageToMoisture(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if ignore_absorb or amount >= 0 or overtime or afflicter == nil then
        return amount
    end

    local moisture = inst.components.moisture:GetMoisture()

    local rate = TUNING.SKILLS.WURT.WETNESS_MOISTURE_ABSORBTION[2]
    local absorbtion = math.min(-amount, moisture / rate)

    inst.components.moisture:DoDelta(-absorbtion * rate)

    ---- FX -----

    local max_absorbtion = TUNING.MAX_WETNESS / rate
    local fx_size = math.ceil(Lerp(0, NUM_SPLASH_FX, absorbtion / max_absorbtion))

    local fx = SpawnPrefab("wurt_water_splash_" .. fx_size)

    if fx ~= nil then
        inst:AddChild(fx)
    end

    --------------

    --print(string.format("Trading %2.2f moisture for %2.2f life! Took %2.2f damage. Original damage was %2.2f.", absorbtion * rate, absorbtion, amount + absorbtion, amount))

    return amount + absorbtion
end

local function OnWetnessChanged(inst, data)
    local percent = inst.components.moisture:GetMoisturePercent()
    inst.components.sanity.externalmodifiers:SetModifier(inst, TUNING.SKILLS.WURT.WETNESS_SANITY_DAPPERNESS[2] * percent, "wetness_skill")

    local tuning = TUNING.SKILLS.WURT.WETNESS_MOISTURE_HEALING[2]
    inst.components.health:AddRegenSource(inst, tuning.amount * RoundToNearest(percent, .1), tuning.period, "wetness_skill")

    inst.components.health.deltamodifierfn = RedirectDamageToMoisture
end

local function RefreshWetnessSkills(inst)
    local is_dead = inst:HasTag("playerghost") or inst.components.health:IsDead()

    if inst._onrespawnedfromghost == nil and is_dead then
        inst._onrespawnedfromghost = OnRespawnedFromGhost

        inst:ListenForEvent("ms_respawnedfromghost", inst._onrespawnedfromghost)
    end

    if not is_dead then
        if inst._onmoisturedelta == nil then
            inst._onmoisturedelta = OnWetnessChanged

            inst:ListenForEvent("moisturedelta", inst._onmoisturedelta)
            inst:ListenForEvent("ms_becameghost", inst.RefreshWetnessSkills)

            inst._onmoisturedelta(inst)
        end
    elseif inst._onmoisturedelta ~= nil then
        inst:RemoveEventCallback("moisturedelta", inst._onmoisturedelta)
        inst:RemoveEventCallback("ms_becameghost", inst.RefreshWetnessSkills)

        inst._onmoisturedelta(inst)

        inst._onmoisturedelta = nil
    end

    local areaaware = inst.components.areaaware

    if areaaware == nil then
        return
    end

    -- The WORLD_TILES.LUNAR_MARSH watcher has already been started by all players.
    if not is_dead then
        if inst._onallegiancemarshtile == nil then
            inst._onallegiancemarshtile = OnAllegianceMarshTile
            inst.components.areaaware:StartWatchingTile(WORLD_TILES.SHADOW_MARSH)

            inst:ListenForEvent("on_LUNAR_MARSH_tile", inst._onallegiancemarshtile)
            inst:ListenForEvent("on_SHADOW_MARSH_tile", inst._onallegiancemarshtile)

            inst.components.areaaware:_ForceUpdate() -- Test for effects.
        end
    elseif inst._onallegiancemarshtile ~= nil then
        inst.components.areaaware:StopWatchingTile(WORLD_TILES.SHADOW_MARSH)

        inst:RemoveEventCallback("on_LUNAR_MARSH_tile", inst._onallegiancemarshtile)
        inst:RemoveEventCallback("on_SHADOW_MARSH_tile", inst._onallegiancemarshtile)

        inst._onallegiancemarshtile(inst, false) -- Remove effects.

        inst._onallegiancemarshtile = nil
    end
end

----------------------------------------------------------------------------------------------------
local function no_holes(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function OnAttackOther(inst, data)
    local victim = data.target
    if not victim then return end

    if math.random() > TUNING.WURT_TERRAFORMING_SHADOW_PROCCHANCE then
        local tile_type = inst:GetCurrentTileType()
        if tile_type == WORLD_TILES.SHADOW_MARSH then
            local pt = victim:GetPosition()
            local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, no_holes, false, true)
            if offset ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
                local tentacle = SpawnPrefab("shadowtentacle")
                if tentacle ~= nil then
                    tentacle.owner = inst
                    tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                    tentacle.components.combat:SetTarget(victim)
                end
            end
        end
    end
end

local function IsNonPlayerMerm(this)
    return this:HasTag("merm") and not this:HasTag("player")
end

local MAX_TARGET_SHARES = 8
local SHARE_TARGET_DIST = 20

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if attacker and inst.components.combat:CanTarget(attacker) then
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsNonPlayerMerm, MAX_TARGET_SHARES)
    end
end

local function TryMermKingUpgradesOnRespawn(inst)
    inst:TryTridentUpgrade()
    inst:TryCrownUpgrade()
    inst:TryPauldronUpgrade()
end

----------------------------------------------------------------------------------------------------

local WURT_PATHFINDER_TILES = {
    WORLD_TILES.MARSH,
    WORLD_TILES.SHADOW_MARSH,
    WORLD_TILES.LUNAR_MARSH,
}

local function RemovePathFinderSkill(inst)
    if inst.pathfindertask ~= nil then
        inst.pathfindertask:Cancel()
        inst.pathfindertask = nil
    end

    for player in pairs(inst.pathfinder_players) do
        inst.pathfinder_players[player] = nil
        player.wurt_pathfinders[inst.GUID] = nil

        if not next(player.wurt_pathfinders) then
            player.wurt_pathfinders = nil

            if player:IsValid() and player.components.locomotor ~= nil then
                for _, tile in ipairs(WURT_PATHFINDER_TILES) do
                    player.components.locomotor:SetFasterOnGroundTile(tile, false)
                end
            end
        end
    end
end

local function PathFinderScanForPlayers(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, 0, z, TUNING.WURT_PATHFINDER_RANGE, true)

    for _, player in ipairs(players) do
        if not player:HasTag("merm") then
            inst.pathfinder_players[player] = true

            if player.wurt_pathfinders == nil then
                player.wurt_pathfinders = {}

                for _, tile in ipairs(WURT_PATHFINDER_TILES) do
                    player.components.locomotor:SetFasterOnGroundTile(tile, true)
                end
            end

            if player.wurt_pathfinders[inst.GUID] == nil then
                player.wurt_pathfinders[inst.GUID] = true
            end
        end
    end

    for player in pairs(inst.pathfinder_players) do
        if not table.contains(players, player) then
            inst.pathfinder_players[player] = nil
            player.wurt_pathfinders[inst.GUID] = nil

            if not next(player.wurt_pathfinders) then
                player.wurt_pathfinders = nil

                if player:IsValid() and player.components.locomotor ~= nil then
                    for _, tile in ipairs(WURT_PATHFINDER_TILES) do
                        player.components.locomotor:SetFasterOnGroundTile(tile, false)
                    end
                end
            end
        end
    end
end

local function RefreshPathFinderSkill(inst)
    if inst.pathfindertask == nil then
        inst.pathfindertask = inst:DoPeriodicTask(1, inst.PathFinderScanForPlayers)
    end
end

----------------------------------------------------------------------------------------------------

local function additional_OnFollowerRemoved(inst, follower)
    if follower.ismerm then
        -- RemoveDebuff has checks built in if the buff isn't there!
        follower:RemoveDebuff(TRIDENT_BUFF_NAME)
        follower:RemoveDebuff(CROWN_BUFF_NAME)
        follower:RemoveDebuff(PAULDRON_BUFF_NAME)
    end

    if follower.ismerm and
        follower.components.health ~= nil and
        follower.components.health:IsDead()
    then
        follower.old_leader = inst

        follower:ListenForEvent("onremove", function() follower.old_leader = nil end, inst)
    end
end

local function additional_OnFollowerAdded(inst, follower)
    if follower.ismerm then
        local mermkingmanager = TheWorld.components.mermkingmanager
        if not mermkingmanager then return end

        if mermkingmanager:HasTridentAnywhere() then
            follower:AddDebuff(TRIDENT_BUFF_NAME, TRIDENT_BUFF_PREFAB)
        end
        if mermkingmanager:HasCrownAnywhere() then
            follower:AddDebuff(CROWN_BUFF_NAME, CROWN_BUFF_PREFAB)
        end
        if mermkingmanager:HasPauldronAnywhere() then
            follower:AddDebuff(PAULDRON_BUFF_NAME, PAULDRON_BUFF_PREFAB)
        end
    end
end


AddPlayerPostInit(function(inst)
    if inst.prefab == "wurt" then return end

    inst:AddTag("merm")
    inst:AddTag("merm_builder")
    inst:AddTag("playermerm")
    inst:AddTag("mermguard")
    inst:AddTag("mermfluent")
    inst:AddTag("stronggrip")

    if not TheWorld.ismastersim then return end

    if not inst.components.preserver then
        inst:AddComponent("preserver")
    end
    Utils.FnDecorator(inst.components.preserver, "perish_rate_multiplier", perish_rate_multiplier_before)

    inst.components.builder.mashturfcrafting_bonus = 2

    inst.additional_OnFollowerRemoved = additional_OnFollowerRemoved
    inst.additional_OnFollowerAdded = additional_OnFollowerAdded

    inst.pathfinder_players = {}
    inst.PathFinderScanForPlayers = PathFinderScanForPlayers
    inst.RefreshPathFinderSkill = RefreshPathFinderSkill

    inst.RefreshWetnessSkills = RefreshWetnessSkills
    inst.RemovePathFinderSkill = RemovePathFinderSkill

    inst.TryTridentUpgrade = TryRoyalUpgradeTrident
    inst.TryTridentDowngrade = TryRoyalDowngradeTrident
    inst.TryCrownUpgrade = TryRoyalUpgradeCrown
    inst.TryCrownDowngrade = TryRoyalDowngradeCrown
    inst.TryPauldronUpgrade = TryRoyalUpgradePauldron
    inst.TryPauldronDowngrade = TryRoyalDowngradePauldron

    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("ms_respawnedfromghost", TryMermKingUpgradesOnRespawn)
    inst:ListenForEvent("ms_playerreroll", inst.RemovePathFinderSkill)
end)

----------------------------------------------------------------------------------------------------

for _, v in ipairs({
    "merm",
    "mermguard",
    "merm_shadow",
    "mermguard_shadow",
    "merm_lunar",
    "mermguard_lunar"
}) do
    AddPrefabPostInit(v, function(inst)
        inst:AddTag("NOBLOCK") --鱼人影响建造太烦了
    end)
end

----------------------------------------------------------------------------------------------------

local function OnBuilt(inst, data)
    inst.components.childspawner:ReleaseAllChildren()
end

for _, v in ipairs({
    "mermhouse_crafted",
    "mermwatchtower"
}) do
    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        inst:ListenForEvent("onbuilt", OnBuilt)
    end)
end

----------------------------------------------------------------------------------------------------

-- 沃特可以同猪王交易，毕竟给玩家加了merm标签
local function AcceptTestBefore(inst, item, giver)
    if giver:HasTag("merm") then
        local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and
            item.components.tradable.halloweencandyvalue > 0
        return { item.components.tradable.goldvalue > 0 or is_event_item or item.prefab == "pig_token" }, true
    end
end

AddPrefabPostInit("pigking", function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.trader, "test", AcceptTestBefore)
end)
