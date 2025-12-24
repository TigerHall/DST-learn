local Utils = require("aab_utils/utils")

AddGamePostInit(function()
    AAB_ReplaceCharacterLines("wendy")
end)

AAB_ActivateSkills("wendy")

----------------------------------------------------------------------------------------------------

local player_common_extensions = require("prefabs/player_common_extensions")
Utils.FnDecorator(player_common_extensions, "GivePlayerStartingItems", function(inst)
    if inst.components.inventory and inst.prefab ~= "wendy" then
        inst.components.inventory.ignoresound = true
        inst.components.inventory:GiveItem(SpawnPrefab("abigail_flower"))
        inst.components.inventory.ignoresound = false
    end
end)

----------------------------------------------------------------------------------------------------

local function OnBondLevelDirty(inst)
    if inst.HUD ~= nil then
        local bond_level = inst._bondlevel:value()
        for i = 0, 3 do
            if i ~= 1 then
                inst:SetClientSideInventoryImageOverrideFlag("bondlevel" .. i, i == bond_level)
            end
        end
        if not inst:HasTag("playerghost") then
            if bond_level > 1 then
                if inst.HUD.wendyflowerover ~= nil then
                    inst.HUD.wendyflowerover:Play(bond_level)
                end
            end
        end
    end
end

local function OnPlayerDeactivated(inst)
    inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
    if not TheWorld.ismastersim then
        inst:RemoveEventCallback("_bondleveldirty", OnBondLevelDirty)
    end
end

local function OnClientPetSkinChanged(inst)
    if inst.HUD ~= nil and inst.HUD.wendyflowerover ~= nil then
        local skinname = TheInventory:LookupSkinname(inst.components.pethealthbar._petskin:value())
        inst.HUD.wendyflowerover:SetSkin(skinname)
    end
end

local WendyFlowerOver = require("widgets/wendyflowerover")
local function OnPlayerActivated(inst)
    if inst == ThePlayer then
        if inst.HUD.wendyflowerover == nil and inst.components.pethealthbar ~= nil then
            inst.HUD.wendyflowerover = inst.HUD.overlayroot:AddChild(WendyFlowerOver(inst))
            inst.HUD.wendyflowerover:MoveToBack()
            OnClientPetSkinChanged(inst)
        end
        inst:ListenForEvent("onremove", OnPlayerDeactivated)
        if not TheWorld.ismastersim then
            inst:ListenForEvent("_bondleveldirty", OnBondLevelDirty)
        end
        OnBondLevelDirty(inst)
    end
end

local function RefreshFlowerTooltip(inst)
    if inst == ThePlayer then
        inst:PushEvent("inventoryitem_updatespecifictooltip", { prefab = "abigail_flower" })
    end
end

--------------------------------------------------------------------------


local function OnDespawn(inst)
    local abigail = inst.components.ghostlybond.ghost
    if abigail ~= nil and abigail.sg ~= nil and not abigail.inlimbo then
        if not abigail.sg:HasStateTag("dissipate") then
            abigail.sg:GoToState("dissipate")
        end
        abigail:DoTaskInTime(25 * FRAMES, abigail.Remove)
    end
end

local function OnReroll(inst)
    -- This is its own function in case OnDespawn above changes that requires workarounds for seamlessswap to not interfere.
    OnDespawn(inst)
end

local function ondeath(inst)
    inst.components.ghostlybond:Recall()
    inst.components.ghostlybond:PauseBonding()
end

local function onresurrection(inst)
    inst.components.ghostlybond:SetBondLevel(1)
    inst.components.ghostlybond:ResumeBonding()
end

local function ghostlybond_onlevelchange(inst, ghost, level, prev_level, isloading)
    inst._bondlevel:set(level)

    if not isloading and inst.components.talker ~= nil and level > 1 then
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_GHOSTLYBOND_LEVELUP", "LEVEL" .. tostring(level)))
        OnBondLevelDirty(inst)
    end
end

local function ghostlybond_onsummon(inst, ghost)
    if inst.components.sanity ~= nil and inst.migration == nil then
        inst.components.sanity:DoDelta(TUNING.SANITY_MED)
    end
end

local function ghostlybond_onrecall(inst, ghost, was_killed)
    if inst.migration == nil then
        if inst.components.sanity ~= nil then
            inst.components.sanity:DoDelta(was_killed and (-TUNING.SANITY_MED * 2) or -TUNING.SANITY_MED)
        end

        if inst.components.talker ~= nil then
            inst.components.talker:Say(GetString(inst, was_killed and "ANNOUNCE_ABIGAIL_DEATH" or "ANNOUNCE_ABIGAIL_RETRIEVE"))
        end
    end

    inst.components.ghostlybond.ghost.sg:GoToState("dissipate")
end

local function ghostlybond_onsummoncomplete(inst, ghost)
    inst.refreshflowertooltip:push()
end

local function ghostlybond_changebehaviour(inst, ghost)
    -- todo: toggle abigail between defensive and offensive
    if ghost.is_defensive then
        ghost:BecomeAggressive()
    else
        ghost:BecomeDefensive()
    end
    inst.refreshflowertooltip:push()

    return true
end

local function update_sisturn_state(inst, is_active)
    if inst.components.ghostlybond ~= nil then
        if is_active == nil then
            is_active = TheWorld.components.sisturnregistry ~= nil and TheWorld.components.sisturnregistry:IsActive()
        end
        inst.components.ghostlybond:SetBondTimeMultiplier("sisturn", is_active and TUNING.ABIGAIL_BOND_LEVELUP_TIME_MULT or nil)
    end
end

local function testForSanityAuraBuff(inst, oldlist)
    local newlist = {}

    -- IF ACTIVE SISTURN, COLLECT NEARBY PLAYERS
    if TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry:IsActive() then
        local px, py, pz = inst.Transform:GetWorldPosition()
        newlist = FindPlayersInRange(px, py, pz, 25, true)
    end

    -- SETUP PLAYERS THAT ARE NEW TO THE POLL
    for _, player in ipairs(newlist) do
        local newplayer = true
        for _, previousplayer in ipairs(oldlist) do
            if player == previousplayer then
                newplayer = false
            end
        end

        if newplayer then
            if player.components.sanity then
                local fx = SpawnPrefab("wendy_sanityaura_buff_on_fx")
                player.SoundEmitter:PlaySound("meta5/wendy/sisturn_sanity_buff")
                player:AddChild(fx)
                player.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.WENDYSKILL_SISTURN_SANITY_MODIFYER, "wendyskill" .. inst.GUID)
            end
        end
    end

    -- REMOVE PLAYERS NOW MISSING
    for _, player in ipairs(oldlist) do
        if player.components.sanity then
            local quit = true
            for _, newplayer in ipairs(newlist) do
                if player == newplayer then
                    quit = false
                    break
                end
            end
            if quit then
                local fx = SpawnPrefab("wendy_sanityaura_buff_off_fx")
                player.SoundEmitter:PlaySound("meta5/wendy/sisturn_sanity_buff_pst")
                player:AddChild(fx)
                player.components.sanity.neg_aura_modifiers:RemoveModifier(inst, "wendyskill" .. inst.GUID)
            end
        end
    end

    return newlist
end

AddPlayerPostInit(function(inst)
    if inst.prefab == "wendy" or inst._bondlevel or inst.refreshflowertooltip then return end

    inst:AddTag("ghostlyfriend")
    inst:AddTag("elixirbrewer")

    if not inst.components.pethealthbar then
        inst:AddComponent("pethealthbar")
    end

    inst._bondlevel = net_tinybyte(inst.GUID, "wendy._bondlevel", "_bondleveldirty")
    inst.refreshflowertooltip = net_event(inst.GUID, "refreshflowertooltip")

    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
    inst:ListenForEvent("clientpetskindirty", OnClientPetSkinChanged)
    inst:ListenForEvent("refreshflowertooltip", RefreshFlowerTooltip)

    if not TheWorld.ismastersim then return end

    if not inst.components.sanityauraadjuster then
        inst:AddComponent("sanityauraadjuster")
    end
    inst.components.sanityauraadjuster:SetAdjustmentFn(testForSanityAuraBuff)

    if not inst.components.ghostlybond then
        inst:AddComponent("ghostlybond")
    end
    inst.components.ghostlybond.onbondlevelchangefn = ghostlybond_onlevelchange
    inst.components.ghostlybond.onsummonfn = ghostlybond_onsummon
    inst.components.ghostlybond.onrecallfn = ghostlybond_onrecall
    inst.components.ghostlybond.onsummoncompletefn = ghostlybond_onsummoncomplete
    inst.components.ghostlybond.changebehaviourfn = ghostlybond_changebehaviour
    inst.components.ghostlybond:Init("abigail", TUNING.ABIGAIL_BOND_LEVELUP_TIME)

    inst:ListenForEvent("death", ondeath)
    inst:ListenForEvent("ms_becameghost", ondeath)
    inst:ListenForEvent("ms_respawnedfromghost", onresurrection)
    inst:ListenForEvent("onsisturnstatechanged", function(world, data) update_sisturn_state(inst, data.is_active) end, TheWorld)
    update_sisturn_state(inst)

    inst:AddComponent("aab_smallghost")

    Utils.FnDecorator(inst, "OnDespawn", OnDespawn)
    inst:ListenForEvent("ms_playerreroll", OnReroll)
end)


----------------------------------------------------------------------------------------------------

local PetHealthBadge = require "widgets/pethealthbadge"
AddClassPostConstruct("widgets/statusdisplays", function(self)
    if not self.pethealthbadge then
        self.pethealthbadge = self:AddChild(PetHealthBadge(self.owner, { 254 / 255, 253 / 255, 237 / 255, 1 }, "status_abigail", { 35 / 255, 152 / 255, 156 / 255, 1 } ))
        self.pethealthbadge:SetPosition(self.column4, -100, 0)
        self.moisturemeter:SetPosition(self.column2, -100, 0)
    end
end)
