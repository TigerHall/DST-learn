--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local assets = {
        Asset("ANIM", "anim/tbat_turf_carpet_cat_claw_2skins.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local this_prefab = "tbat_turf_carpet_cat_claw"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["carpet_claw_dreamweave_rug"] = {                    --- 
            bank = "tbat_turf_carpet_cat_claw_2skins",
            build = "tbat_turf_carpet_cat_claw_2skins",
            atlas = "images/map_icons/tbat_turf_carpet_cat_claw_dreamweave_rug.xml",
            image = "tbat_turf_carpet_cat_claw_dreamweave_rug",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.dreamweave_rug"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_cat_claw_2skins",
                build = "tbat_turf_carpet_cat_claw_2skins",
                anim = "idle1",
                scale = 0.2,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_cat_claw_dreamweave_rug.tex")
                inst.AnimState:PlayAnimation("idle1",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_cat_claw_2skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_cat_claw_2skins")
                inst.AnimState:PlayAnimation("idle1",true)
            end
        },
        ["carpet_claw_petglyph_platform"] = {                    --- 
            bank = "tbat_turf_carpet_cat_claw_2skins",
            build = "tbat_turf_carpet_cat_claw_2skins",
            atlas = "images/map_icons/tbat_turf_carpet_cat_claw_petglyph_platform.xml",
            image = "tbat_turf_carpet_cat_claw_petglyph_platform",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.petglyph_platform"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_cat_claw_2skins",
                build = "tbat_turf_carpet_cat_claw_2skins",
                anim = "idle2",
                scale = 0.2,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_cat_claw_petglyph_platform.tex")
                inst.AnimState:PlayAnimation("idle2",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_cat_claw_2skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_cat_claw_2skins")
                inst.AnimState:PlayAnimation("idle2",true)
            end
        },
    }    
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","carpet_claw_dreamweave_rug")
    TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","carpet_claw_petglyph_platform")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return assets