AddGamePostInit(function()
    -- for _, d in pairs(STRINGS.CHARACTERS) do
    --     if d.ANNOUNCE_CHARGE == "only_used_by_wx78" then
    --         d.ANNOUNCE_CHARGE = STRINGS.CHARACTERS.WX78.ANNOUNCE_CHARGE
    --     end
    --     if d.ANNOUNCE_DISCHARGE == "only_used_by_wx78" then
    --         d.ANNOUNCE_DISCHARGE = STRINGS.CHARACTERS.WX78.ANNOUNCE_DISCHARGE
    --     end
    --     if d.ANNOUNCE_NOSLEEPHASPERMANENTLIGHT == "only_used_by_wx78" then
    --         d.ANNOUNCE_NOSLEEPHASPERMANENTLIGHT = STRINGS.CHARACTERS.WX78.ANNOUNCE_NOSLEEPHASPERMANENTLIGHT
    --     end
    --     if d.ANNOUNCE_WX_SCANNER_FOUND_NO_DATA == "only_used_by_wx78" then
    --         d.ANNOUNCE_WX_SCANNER_FOUND_NO_DATA = STRINGS.CHARACTERS.WX78.ANNOUNCE_WX_SCANNER_FOUND_NO_DATA
    --     end
    --     if d.ANNOUNCE_WX_SCANNER_NEW_FOUND == "only_used_by_wx78" then
    --         d.ANNOUNCE_WX_SCANNER_NEW_FOUND = STRINGS.CHARACTERS.WX78.ANNOUNCE_WX_SCANNER_NEW_FOUND
    --     end

    --     for k, v in pairs(d.ACTIONFAIL.APPLYMODULE) do
    --         if v == "only_used_by_wx78" then
    --             d.ACTIONFAIL.APPLYMODULE[k] = STRINGS.CHARACTERS.WX78.ACTIONFAIL.APPLYMODULE[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.CHARGE_FROM) do
    --         if v == "only_used_by_wx78" then
    --             d.ACTIONFAIL.CHARGE_FROM[k] = STRINGS.CHARACTERS.WX78.ACTIONFAIL.CHARGE_FROM[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.REMOVEMODULES) do
    --         if v == "only_used_by_wx78" then
    --             d.ACTIONFAIL.REMOVEMODULES[k] = STRINGS.CHARACTERS.WX78.ACTIONFAIL.REMOVEMODULES[k]
    --         end
    --     end
    -- end

    AAB_ReplaceCharacterLines("wx78")
end)

----------------------------------------------------------------------------------------------------
local WX78MoistureMeter = require("widgets/wx78moisturemeter")

local CHARGEREGEN_TIMERNAME = "chargeregenupdate"
local MOISTURETRACK_TIMERNAME = "moisturetrackingupdate" --移除潮湿的负面效果
local HUNGERDRAIN_TIMERNAME = "hungerdraintick"
local HEATSTEAM_TIMERNAME = "heatsteam_tick"

----------------------------------------------------------------------------------------

local function CLIENT_GetEnergyLevel(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner.charge_level
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentenergylevel:value()
    else
        return 0
    end
end

local function get_plugged_module_indexes(inst)
    local upgrademodule_defindexes = {}
    for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
        table.insert(upgrademodule_defindexes, module._netid)
    end

    -- Fill out the rest of the table with 0s
    while #upgrademodule_defindexes < TUNING.WX78_MAXELECTRICCHARGE do
        table.insert(upgrademodule_defindexes, 0)
    end

    return upgrademodule_defindexes
end

local DEFAULT_ZEROS_MODULEDATA = { 0, 0, 0, 0, 0, 0 }
local function CLIENT_GetModulesData(inst)
    local data = nil

    if inst.components.upgrademoduleowner ~= nil then
        data = get_plugged_module_indexes(inst)
    elseif inst.player_classified ~= nil then
        data = {}
        for _, module_netvar in ipairs(inst.player_classified.upgrademodules) do
            table.insert(data, module_netvar:value())
        end
    else
        data = DEFAULT_ZEROS_MODULEDATA
    end

    return data
end

local WX78ModuleDefinitionFile = require("wx78_moduledefs")
local GetWX78ModuleByNetID = WX78ModuleDefinitionFile.GetModuleDefinitionFromNetID

local function CLIENT_CanUpgradeWithModule(inst, module_prefab)
    if module_prefab == nil then
        return false
    end

    local slots_inuse = (module_prefab._slots or 0)

    if inst.components.upgrademoduleowner ~= nil then
        for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
            local modslots = (module.components.upgrademodule ~= nil and module.components.upgrademodule.slots)
                or 0
            slots_inuse = slots_inuse + modslots
        end
    elseif inst.player_classified ~= nil then
        for _, module_netvar in ipairs(inst.player_classified.upgrademodules) do
            local module_definition = GetWX78ModuleByNetID(module_netvar:value())
            if module_definition ~= nil then
                slots_inuse = slots_inuse + module_definition.slots
            end
        end
    else
        return false
    end

    return (TUNING.WX78_MAXELECTRICCHARGE - slots_inuse) >= 0
end

local function CLIENT_CanRemoveModules(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner:NumModules() > 0
    elseif inst.player_classified ~= nil then
        -- Assume that, if the first module slot netvar is 0, we have no modules.
        return inst.player_classified.upgrademodules[1]:value() ~= 0
    else
        return false
    end
end

----------------------------------------------------------------------------------------

local function OnUpgradeModuleAdded(inst, moduleent)
    local slots_for_module = moduleent.components.upgrademodule.slots
    inst._chip_inuse = inst._chip_inuse + slots_for_module

    local upgrademodule_defindexes = get_plugged_module_indexes(inst)

    inst:PushEvent("upgrademodulesdirty", upgrademodule_defindexes)
    if inst.player_classified ~= nil then
        local newmodule_index = inst.components.upgrademoduleowner:NumModules()
        inst.player_classified.upgrademodules[newmodule_index]:set(moduleent._netid or 0)
    end
end

local function OnUpgradeModuleRemoved(inst, moduleent)
    inst._chip_inuse = inst._chip_inuse - moduleent.components.upgrademodule.slots

    -- If the module has 1 use left, it's about to be destroyed, so don't return it to the inventory.
    if moduleent.components.finiteuses == nil or moduleent.components.finiteuses:GetUses() > 1 then
        if moduleent.components.inventoryitem ~= nil and inst.components.inventory ~= nil then
            inst.components.inventory:GiveItem(moduleent, nil, inst:GetPosition())
        end
    end
end

local function OnOneUpgradeModulePopped(inst, moduleent)
    inst:PushEvent("upgrademodulesdirty", get_plugged_module_indexes(inst))
    if inst.player_classified ~= nil then
        -- This is a callback of the remove, so our current NumModules should be
        -- 1 lower than the index of the module that was just removed.
        local top_module_index = inst.components.upgrademoduleowner:NumModules() + 1
        inst.player_classified.upgrademodules[top_module_index]:set(0)
    end
end

local function OnAllUpgradeModulesRemoved(inst)
    SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

    inst:PushEvent("upgrademoduleowner_popallmodules")

    if inst.player_classified ~= nil then
        inst.player_classified.upgrademodules[1]:set(0)
        inst.player_classified.upgrademodules[2]:set(0)
        inst.player_classified.upgrademodules[3]:set(0)
        inst.player_classified.upgrademodules[4]:set(0)
        inst.player_classified.upgrademodules[5]:set(0)
        inst.player_classified.upgrademodules[6]:set(0)
    end
end

local function CanUseUpgradeModule(inst, moduleent)
    if (TUNING.WX78_MAXELECTRICCHARGE - inst._chip_inuse) < moduleent.components.upgrademodule.slots then
        return false, "NOTENOUGHSLOTS"
    else
        return true
    end
end

----------------------------------------------------------------------------------------

local function OnChargeFromBattery(inst, battery)
    if inst.components.upgrademoduleowner:ChargeIsMaxed() then
        return false, "CHARGE_FULL"
    end

    inst.components.health:DoDelta(TUNING.HEALING_SMALL, false, "lightning")
    inst.components.sanity:DoDelta(-TUNING.SANITY_SMALL)

    inst.components.upgrademoduleowner:AddCharge(1)

    if not inst.components.inventory:IsInsulated() then
        inst.sg:GoToState("electrocute")
    end

    return true
end

----------------------------------------------------------------------------------------

local function ModuleBasedPreserverRateFn(inst, item)
    return (inst._temperature_modulelean > 0 and TUNING.WX78_PERISH_HOTRATE)
        or (inst._temperature_modulelean < 0 and TUNING.WX78_PERISH_COLDRATE)
        or 1
end

----------------------------------------------------------------------------------------

local function GetThermicTemperatureFn(inst, observer)
    return inst._temperature_modulelean * TUNING.WX78_HEATERTEMPPERMODULE
end

---------------------------------------------------------------------------------------

local function OnBecameRobot(inst)
    --Override with overcharge light values
    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetIntensity(.9)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, TUNING.WX78_CHARGE_REGENTIME) --回复电量
    end
end

local function OnBecameGhost(inst)
    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)
end

local function OnDeath(inst)
    inst.components.upgrademoduleowner:PopAllModules()
    inst.components.upgrademoduleowner:SetChargeLevel(0)

    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
    inst.components.timer:StopTimer(CHARGEREGEN_TIMERNAME)

    if inst._gears_eaten > 0 then
        local dropgears = math.random(math.floor(inst._gears_eaten / 3), math.ceil(inst._gears_eaten / 2))
        local x, y, z = inst.Transform:GetWorldPosition()
        for i = 1, dropgears do
            local gear = SpawnPrefab("gears")
            if gear ~= nil then
                if gear.Physics ~= nil then
                    local speed = 2 + math.random()
                    local angle = math.random() * TWOPI
                    gear.Physics:Teleport(x, y + 1, z)
                    gear.Physics:SetVel(speed * math.cos(angle), speed * 3, speed * math.sin(angle))
                else
                    gear.Transform:SetPosition(x, y, z)
                end

                if gear.components.propagator ~= nil then
                    gear.components.propagator:Delay(5)
                end
            end
        end

        inst._gears_eaten = 0
    end
end

----------------------------------------------------------------------------------------
local function OnStartStarving(inst)
    inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

local function OnStopStarving(inst)
    inst.components.timer:StopTimer(HUNGERDRAIN_TIMERNAME)
end

local function on_hunger_drain_tick(inst)
    if inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
        inst.components.upgrademoduleowner:AddCharge(-1)

        SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

        inst.sg:GoToState("hit")
    end
    inst.components.timer:StartTimer(HUNGERDRAIN_TIMERNAME, TUNING.WX78_HUNGRYCHARGEDRAIN_TICKTIME)
end

----------------------------------------------------------------------------------------

local function do_chargeregen_update(inst)
    if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
        inst.components.upgrademoduleowner:AddCharge(1)
    end
    inst.components.timer:StartTimer(CHARGEREGEN_TIMERNAME, TUNING.WX78_CHARGE_REGENTIME) --回复电量
end

----------------------------------------------------------------------------------------
local HEATSTEAM_TICKRATE = 5
local function do_steam_fx(inst)
    local steam_fx = SpawnPrefab("wx78_heat_steam")
    steam_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    steam_fx.Transform:SetRotation(inst.Transform:GetRotation())

    inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE)
end

----------------------------------------------------------------------------------------

local function OnTimerFinished(inst, data)
    if data.name == HUNGERDRAIN_TIMERNAME then
        on_hunger_drain_tick(inst)
    elseif data.name == CHARGEREGEN_TIMERNAME then
        do_chargeregen_update(inst)
    elseif data.name == HEATSTEAM_TIMERNAME then
        do_steam_fx(inst)
    end
end

-- Negative is colder, positive is warmer
local function AddTemperatureModuleLeaning(inst, leaning_change)
    inst._temperature_modulelean = inst._temperature_modulelean + leaning_change

    if inst._temperature_modulelean > 0 then
        inst.components.heater:SetThermics(true, false)

        if not inst.components.timer:TimerExists(HEATSTEAM_TIMERNAME) then
            inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE, false, 0.5)
        end

        inst.components.frostybreather:ForceBreathOff()
    elseif inst._temperature_modulelean == 0 then
        inst.components.heater:SetThermics(false, false)

        inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)

        inst.components.frostybreather:ForceBreathOff()
    else
        inst.components.heater:SetThermics(false, true)

        inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)

        inst.components.frostybreather:ForceBreathOn()
    end
end

local NIGHTVISIONMODULE_GRUEIMMUNITY_NAME = "wxnightvisioncircuit"
local function SetForcedNightVision(inst, nightvision_on)
    inst._forced_nightvision:set(nightvision_on)

    if inst.components.playervision ~= nil then
        if nightvision_on then
            inst.components.playervision:PushForcedNightVision(inst)
        else
            inst.components.playervision:PopForcedNightVision(inst)
        end
    end

    -- The nightvision event might get consumed during save/loading,
    -- so push an extra custom immunity into the table.
    if nightvision_on then
        inst.components.grue:AddImmunity(NIGHTVISIONMODULE_GRUEIMMUNITY_NAME)
    else
        inst.components.grue:RemoveImmunity(NIGHTVISIONMODULE_GRUEIMMUNITY_NAME)
    end
end

local function OnForcedNightVisionDirty(inst)
    if inst.components.playervision ~= nil then
        if inst._forced_nightvision:value() then
            inst.components.playervision:PushForcedNightVision(inst)
        else
            inst.components.playervision:PopForcedNightVision(inst)
        end
    end
end

local function OnPlayerDeactivated(inst)
    inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
    if not TheNet:IsDedicated() then
        inst:RemoveEventCallback("forced_nightvision_dirty", OnForcedNightVisionDirty)
    end
end

local function OnPlayerActivated(inst)
    inst:ListenForEvent("onremove", OnPlayerDeactivated)
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("forced_nightvision_dirty", OnForcedNightVisionDirty)
        OnForcedNightVisionDirty(inst)
    end
end

----------------------------------------------------------------------------------------------------


AddPlayerPostInit(function(inst)
    if inst.prefab == "wx78" then return end

    inst:AddTag("batteryuser")        -- from batteryuser component
    inst:AddTag("upgrademoduleowner") -- from upgrademoduleowner component
    inst:AddTag("electricdamageimmune")
    inst:AddTag("chessfriend")

    if not TheNet:IsDedicated() then
        inst.CreateMoistureMeter = WX78MoistureMeter
    end

    inst._forced_nightvision = net_bool(inst.GUID, "wx78.forced_nightvision", "forced_nightvision_dirty")
    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

    ----------------------------------------------------------------
    -- For UI save/loading
    inst.GetEnergyLevel = CLIENT_GetEnergyLevel
    inst.GetModulesData = CLIENT_GetModulesData

    ----------------------------------------------------------------
    -- For actionfail tests
    inst.CanUpgradeWithModule = CLIENT_CanUpgradeWithModule
    inst.CanRemoveModules = CLIENT_CanRemoveModules

    if not TheWorld.ismastersim then return end

    inst._gears_eaten = 0
    inst._chip_inuse = 0
    inst._moisture_steps = 0
    inst._temperature_modulelean = 0   -- Positive if "hot", negative if "cold"; see wx78_moduledefs
    inst._num_frostybreath_modules = 0 -- So modules can activate WX's frostybreath outside of winter/low worldstate temperature

    if not inst.components.dataanalyzer then
        inst:AddComponent("dataanalyzer")
    end
    inst.components.dataanalyzer:StartDataRegen(TUNING.SEG_TIME)

    if not inst.components.upgrademoduleowner then
        inst:AddComponent("upgrademoduleowner")
    end
    inst.components.upgrademoduleowner.onmoduleadded = OnUpgradeModuleAdded
    inst.components.upgrademoduleowner.onmoduleremoved = OnUpgradeModuleRemoved
    inst.components.upgrademoduleowner.ononemodulepopped = OnOneUpgradeModulePopped
    inst.components.upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
    inst.components.upgrademoduleowner.canupgradefn = CanUseUpgradeModule
    inst.components.upgrademoduleowner:SetChargeLevel(3)

    if not inst.components.batteryuser then
        inst:AddComponent("batteryuser")
    end
    inst.components.batteryuser.onbatteryused = OnChargeFromBattery

    if not inst.components.preserver then
        inst:AddComponent("preserver")
    end
    inst.components.preserver:SetPerishRateMultiplier(ModuleBasedPreserverRateFn)


    if not inst.components.heater then
        inst:AddComponent("heater")
    end
    inst.components.heater:SetThermics(false, false)
    inst.components.heater.heatfn = GetThermicTemperatureFn

    inst:ListenForEvent("ms_respawnedfromghost", OnBecameRobot)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_playerreroll", OnDeath)
    inst:ListenForEvent("startstarving", OnStartStarving)
    inst:ListenForEvent("stopstarving", OnStopStarving)
    inst:ListenForEvent("timerdone", OnTimerFinished)

    OnBecameRobot(inst)

    ----------------------------------------------------------------
    inst.AddTemperatureModuleLeaning = AddTemperatureModuleLeaning
    inst.SetForcedNightVision = SetForcedNightVision

    ----------------------------------------------------------------

    inst:AddComponent("aab_wx78")
end)
