--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local assets = {
        Asset("ANIM", "anim/tbat_turf_carpet_pink_fur_3skins.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local this_prefab = "tbat_turf_carpet_pink_fur"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_carpet_cream_puff_bread"] = {                    --- 
            bank = "tbat_turf_carpet_pink_fur_3skins",
            build = "tbat_turf_carpet_pink_fur_3skins",
            atlas = "images/map_icons/tbat_turf_carpet_pink_fur_cream_puff_bread.xml",
            image = "tbat_turf_carpet_pink_fur_cream_puff_bread",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.cream_puff_bread"),        --- 切名字用的
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_pink_fur_3skins",
                build = "tbat_turf_carpet_pink_fur_3skins",
                anim = "idle1",
                scale = 0.3,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_pink_fur_cream_puff_bread.tex")
                inst.AnimState:PlayAnimation("idle1",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:PlayAnimation("idle1",true)
            end
        },
        ["tbat_carpet_taro_bread"] = {                    --- 
            bank = "tbat_turf_carpet_pink_fur_3skins",
            build = "tbat_turf_carpet_pink_fur_3skins",
            atlas = "images/map_icons/tbat_turf_carpet_pink_fur_taro_bread.xml",
            image = "tbat_turf_carpet_pink_fur_taro_bread",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.taro_bread"),        --- 切名字用的
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_pink_fur_3skins",
                build = "tbat_turf_carpet_pink_fur_3skins",
                anim = "idle2",
                scale = 0.3,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_pink_fur_taro_bread.tex")
                inst.AnimState:PlayAnimation("idle2",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:PlayAnimation("idle2",true)
            end
        },
        ["tbat_carpet_taro_bread_with_bell"] = {                    --- 
            bank = "tbat_turf_carpet_pink_fur_3skins",
            build = "tbat_turf_carpet_pink_fur_3skins",
            atlas = "images/map_icons/tbat_turf_carpet_pink_fur_taro_bread_with_bell.xml",
            image = "tbat_turf_carpet_pink_fur_taro_bread_with_bell",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.taro_bread_with_bell"),        --- 切名字用的
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_pink_fur_3skins",
                build = "tbat_turf_carpet_pink_fur_3skins",
                anim = "idle3",
                scale = 0.3,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_pink_fur_taro_bread_with_bell.tex")
                inst.AnimState:PlayAnimation("idle3",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:PlayAnimation("idle3",true)
            end
        },
        ["tbat_carpet_hello_kitty"] = {                    --- 
            bank = "tbat_turf_carpet_pink_fur_3skins",
            build = "tbat_turf_carpet_pink_fur_3skins",
            atlas = "images/map_icons/tbat_turf_carpet_pink_fur_hello_kitty.xml",
            image = "tbat_turf_carpet_pink_fur_hello_kitty",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.hello_kitty"),        --- 切名字用的
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_turf_carpet_pink_fur_3skins",
                build = "tbat_turf_carpet_pink_fur_3skins",
                anim = "kitty",
                scale = 0.3,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_pink_fur_hello_kitty.tex")
                inst.AnimState:PlayAnimation("kitty",true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:SetBuild("tbat_turf_carpet_pink_fur_3skins")
                inst.AnimState:PlayAnimation("kitty",true)
            end
        },
    }    
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_carpet_cream_puff_bread")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_carpet_taro_bread")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_carpet_taro_bread_with_bell")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_carpet_hello_kitty")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return assets