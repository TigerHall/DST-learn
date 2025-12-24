local INSPIRATION_BATTLESONG_DEFS = require("prefabs/battlesongdefs")
local Utils = require("aab_utils/utils")

----------------------------------------------------------------------------------------------------

AddGamePostInit(function()
    -- for _, d in pairs(STRINGS.CHARACTERS) do
    --     if d.ANNOUNCE_BATTLESONG_INSTANT_PANIC_BUFF == "only_used_by_wathgrithr" then
    --         d.ANNOUNCE_BATTLESONG_INSTANT_PANIC_BUFF = STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_BATTLESONG_INSTANT_PANIC_BUFF
    --     end
    --     if d.ANNOUNCE_BATTLESONG_INSTANT_REVIVE_BUFF == "only_used_by_wathgrithr" then
    --         d.ANNOUNCE_BATTLESONG_INSTANT_REVIVE_BUFF = STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_BATTLESONG_INSTANT_REVIVE_BUFF
    --     end
    --     if d.ANNOUNCE_BATTLESONG_INSTANT_TAUNT_BUFF == "only_used_by_wathgrithr" then
    --         d.ANNOUNCE_BATTLESONG_INSTANT_TAUNT_BUFF = STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_BATTLESONG_INSTANT_TAUNT_BUFF
    --     end
    --     if d.ANNOUNCE_NOINSPIRATION == "only_used_by_wathgrithr" then
    --         d.ANNOUNCE_NOINSPIRATION = STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_NOINSPIRATION
    --     end
    --     if d.ANNOUNCE_NOTSKILLEDENOUGH == "only_used_by_wathgrithr" then
    --         d.ANNOUNCE_NOTSKILLEDENOUGH = STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_NOTSKILLEDENOUGH
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.SING_FAIL) do
    --         if v == "only_used_by_wathgrithr" then
    --             d.ACTIONFAIL.SING_FAIL[k] = STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.SING_FAIL[k]
    --         end
    --     end
    -- end
    AAB_ReplaceCharacterLines("wathgrithr")
end)

----------------------------------------------------------------------------------------------------

local function IsValidVictim(victim)
    return victim ~= nil
        and victim.components.health ~= nil
        and victim.components.combat ~= nil
        and not ((victim:HasTag("prey") and not victim:HasTag("hostile")) or
            victim:HasAnyTag(NON_LIFEFORM_TARGET_TAGS) or
            victim:HasTag("companion")
        )
end

local function GetInspiration(inst)
    if inst.components.singinginspiration ~= nil then
        return inst.components.singinginspiration:GetPercent()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentinspiration:value() / TUNING.INSPIRATION_MAX
    else
        return 0
    end
end

local function GetInspirationSong(inst, slot)
    if inst.components.singinginspiration ~= nil then
        return inst.components.singinginspiration:GetActiveSong(slot)
    elseif inst.player_classified ~= nil then
        return INSPIRATION_BATTLESONG_DEFS.GetBattleSongDefFromNetID(inst.player_classified.inspirationsongs[slot] ~= nil and inst.player_classified.inspirationsongs[slot]:value() or
            0)
    else
        return nil
    end
end

local function CalcAvailableSlotsForInspiration(inst, inspiration_precent)
    inspiration_precent = inspiration_precent or GetInspiration(inst)

    local slots_available = 0
    for i = #TUNING.BATTLESONG_THRESHOLDS, 1, -1 do
        if inspiration_precent > TUNING.BATTLESONG_THRESHOLDS[i] then
            slots_available = i
            break
        end
    end
    return slots_available
end

-------------------------------------------------------------------------------------------------------

local function PlayRidingMusic(inst)
    inst:PushEvent("playrideofthevalkyrie")
end

local function OnRidingDirty(inst)
    if ThePlayer == nil or ThePlayer ~= inst then
        return
    end

    if inst.replica.rider ~= nil and
        inst.replica.rider:IsRiding()
    then
        if inst._play_riding_music_task == nil then
            inst._play_riding_music_task = inst:DoPeriodicTask(0.5, PlayRidingMusic)
        end
    elseif inst._play_riding_music_task ~= nil then
        inst._play_riding_music_task:Cancel()
        inst._play_riding_music_task = nil
    end
end

AAB_ActivateSkills("wathgrithr")

AddPlayerPostInit(function(inst)
    if inst.prefab == "wathgrithr" or inst._riding_music then return end

    inst:AddTag("battlesinger")
    inst:AddTag("valkyrie")

    -- Didn't want to make singinginspiration a networked component
    inst.GetInspiration = GetInspiration
    inst.GetInspirationSong = GetInspirationSong
    inst.CalcAvailableSlotsForInspiration = CalcAvailableSlotsForInspiration

    -- For forcing it while already riding.
    inst._riding_music = net_event(inst.GUID, "wathgrithr._riding_music")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("isridingdirty", OnRidingDirty)
        inst:ListenForEvent("wathgrithr._riding_music", OnRidingDirty)
    end

    if not TheWorld.ismastersim then return end



    inst.IsValidVictim = IsValidVictim
    if not inst.components.singinginspiration then
        inst:AddComponent("singinginspiration")
    end
    inst.components.singinginspiration:SetCalcAvailableSlotsForInspirationFn(CalcAvailableSlotsForInspiration)
    inst.components.singinginspiration:SetValidVictimFn(inst.IsValidVictim)
end)
