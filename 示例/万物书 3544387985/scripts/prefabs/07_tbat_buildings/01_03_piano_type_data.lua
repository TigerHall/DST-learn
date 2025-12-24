--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    炼金引擎    researchlab2
    暗影操纵器  researchlab3
    制图桌      cartographydesk
    钓鱼容器      tacklestation
    智囊团      seafaring_prototyper
    
    远古科技      ancient_altar
    暗影术基座      shadow_forge
    辉煌铁匠铺      lunar_forge
    天体科技      moon_altar_astral

]]---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local atlas = "images/widgets/tbat_container_cherry_blossom_rabbit_hud.xml"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
return {
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 炼金引擎 researchlab2 
        ["researchlab2"] = {
            atlas = atlas,
            item = "nil",
            ["common_fn"] = function(inst)
                inst:AddTag("giftmachine")
                inst:AddTag("level2")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE
                inst:AddComponent("wardrobe")
                inst.components.wardrobe:SetCanUseAction(false) --also means NO wardrobe tag!
                inst.components.wardrobe:SetCanBeShared(true)
                inst.components.wardrobe:SetRange(TUNING.RESEARCH_MACHINE_DIST + .1)
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 暗影操纵器 researchlab3
        ["researchlab3"] = {
            atlas = atlas,
            item = "purplegem",
            ["common_fn"] = function(inst)
                inst:AddTag("level3")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 制图桌 cartographydesk
        ["cartographydesk"] = {
            atlas = atlas,
            item = "compass",
            ["common_fn"] = function(inst)
                inst:AddTag("papereraser")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("papereraser")
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.CARTOGRAPHYDESK
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 钓鱼容器 tacklestation
        ["tacklestation"] = {
            atlas = atlas,
            item = "oceanfishingrod",
            ["common_fn"] = function(inst)
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.FISHING
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 智囊团 seafaring_prototyper
        ["seafaring_prototyper"] = {
            atlas = atlas,
            item = "boat_item",
            ["common_fn"] = function(inst)
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.SEAFARING_STATION
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 远古科技 ancient_altar
        ["ancient_altar"] = {
            atlas = atlas,
            item = "ruins_bat",
            ["init"] = function(prefab)
                
            end,
            ["common_fn"] = function(inst)
                inst:AddTag("ancient_station")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH

            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 暗影术基座 shadow_forge
        ["shadow_forge"] = {
            atlas = atlas,
            item = "dreadstone",
            ["common_fn"] = function(inst)
                inst:AddTag("shadow_forge")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.SHADOW_FORGE

            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 辉煌铁匠铺 lunar_forge
        ["lunar_forge"] = {
            atlas = atlas,
            item = "purebrilliance",
            ["common_fn"] = function(inst)
                inst:AddTag("lunar_forge")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.LUNAR_FORGE
            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 天体科技 moon_altar_astral
        ["moon_altar_astral"] = {
            atlas = atlas,
            item = "moonglassaxe",
            ["common_fn"] = function(inst)
                inst:AddTag("celestial_station")
                --prototyper (from prototyper component) added to pristine state for optimization
                inst:AddTag("prototyper")
            end,
            ["master_fn"] = function(inst)
                inst:AddComponent("prototyper")
                inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOON_ALTAR_FULL

            end,
        },
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


}