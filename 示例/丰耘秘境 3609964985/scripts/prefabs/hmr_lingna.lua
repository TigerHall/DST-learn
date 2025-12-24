local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.HMR_LINGNA
end
local prefabs = FlattenTree(start_inv, true)

local function onbecamehuman(inst)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "hmr_lingna_speed_mod", 1)
end

local function onbecameghost(inst)
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "hmr_lingna_speed_mod")
end

local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

local common_postinit = function(inst)
	-- inst.MiniMapEntity:SetIcon( "esctemplate.tex" )
end

local master_postinit = function(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.soundsname = "willow"

	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"

	inst.components.health:SetMaxHealth(TUNING.ESCTEMPLATE_HEALTH)
	inst.components.hunger:SetMax(TUNING.ESCTEMPLATE_HUNGER)
	inst.components.sanity:SetMax(TUNING.ESCTEMPLATE_SANITY)

    inst.components.combat.damagemultiplier = 1

	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE

	inst.OnLoad = onload
    inst.OnNewSpawn = onload
end

local default_skin_data = {
    base_prefab = "esctemplate",
    type = "base",
    assets = {
        Asset( "ANIM", "anim/esctemplate.zip" ),
        Asset( "ANIM", "anim/ghost_esctemplate_build.zip" ),
    },
    skins = {
        normal_skin = "esctemplate",
        ghost_skin = "ghost_esctemplate_build",
    },
    skin_tags = {"ESCTEMPLATE", "CHARACTER", "BASE"},
    build_name_override = "esctemplate",
    rarity = "Character",
}

return MakePlayerCharacter("hmr_lingna", prefabs, assets, common_postinit, master_postinit, prefabs),
    CreatePrefabSkin("hmr_lingna_none", default_skin_data)
