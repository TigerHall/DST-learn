--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_building_magic_potion_cabinet"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_tree_ring_counter.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_ferris_wheel.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_gift_display_rack.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_accordion.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_dreampkin_hut.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_grid_cabinet.zip"),
        Asset("ANIM", "anim/tbat_building_magic_potion_cabinet_puffcap_stand.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_mpc_tree_ring_counter"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_tree_ring_counter",
            build = "tbat_building_magic_potion_cabinet_tree_ring_counter",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_tree_ring_counter.xml",
            image = "tbat_building_magic_potion_cabinet_tree_ring_counter",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.tree_ring_counter"),        --- 切名字用的
            name_color = "pink",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_tree_ring_counter",
                build = "tbat_building_magic_potion_cabinet_tree_ring_counter",
                anim = "test",
                scale = 0.2,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_tree_ring_counter.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_tree_ring_counter")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_tree_ring_counter")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 4,
                display_item_ground_type = true,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_ferris_wheel"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_ferris_wheel",
            build = "tbat_building_magic_potion_cabinet_ferris_wheel",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_ferris_wheel.xml",
            image = "tbat_building_magic_potion_cabinet_ferris_wheel",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.ferris_wheel"),        --- 切名字用的
            name_color = "pink",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_ferris_wheel",
                build = "tbat_building_magic_potion_cabinet_ferris_wheel",
                anim = "test",
                scale = 0.15,
                offset = Vector3(0, -50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_ferris_wheel.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_ferris_wheel")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_ferris_wheel")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 5,
                display_item_ground_type = true,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_gift_display_rack"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_gift_display_rack",
            build = "tbat_building_magic_potion_cabinet_gift_display_rack",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_gift_display_rack.xml",
            image = "tbat_building_magic_potion_cabinet_gift_display_rack",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.gift_display_rack"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_gift_display_rack",
                build = "tbat_building_magic_potion_cabinet_gift_display_rack",
                anim = "test",
                scale = 0.25,
                offset = Vector3(0, -10, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_gift_display_rack.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_gift_display_rack")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_gift_display_rack")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 3,
                display_item_ground_type = true,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_accordion"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_accordion",
            build = "tbat_building_magic_potion_cabinet_accordion",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_accordion.xml",
            image = "tbat_building_magic_potion_cabinet_accordion",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.accordion"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_accordion",
                build = "tbat_building_magic_potion_cabinet_accordion",
                anim = "test",
                scale = 0.25,
                offset = Vector3(0, -10, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_accordion.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_accordion")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_accordion")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 6,
                display_item_ground_type = false,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_dreampkin_hut"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_dreampkin_hut",
            build = "tbat_building_magic_potion_cabinet_dreampkin_hut",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_dreampkin_hut.xml",
            image = "tbat_building_magic_potion_cabinet_dreampkin_hut",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.dreampkin_hut"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_dreampkin_hut",
                build = "tbat_building_magic_potion_cabinet_dreampkin_hut",
                anim = "test",
                scale = 0.25,
                offset = Vector3(0, -10, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_dreampkin_hut.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_dreampkin_hut")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_dreampkin_hut")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 2,
                display_item_ground_type = true,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_grid_cabinet"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_grid_cabinet",
            build = "tbat_building_magic_potion_cabinet_grid_cabinet",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_grid_cabinet.xml",
            image = "tbat_building_magic_potion_cabinet_grid_cabinet",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.grid_cabinet"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_grid_cabinet",
                build = "tbat_building_magic_potion_cabinet_grid_cabinet",
                anim = "test",
                scale = 0.4,
                offset = Vector3(0, -10, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_grid_cabinet.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_grid_cabinet")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_grid_cabinet")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 10,
                display_item_ground_type = false,  --- 显示物品还是图标
            --------------------------------------------
        },
        ["tbat_mpc_puffcap_stand"] = {                    --- 
            bank = "tbat_building_magic_potion_cabinet_puffcap_stand",
            build = "tbat_building_magic_potion_cabinet_puffcap_stand",
            atlas = "images/map_icons/tbat_building_magic_potion_cabinet_puffcap_stand.xml",
            image = "tbat_building_magic_potion_cabinet_puffcap_stand",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.puffcap_stand"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_magic_potion_cabinet_puffcap_stand",
                build = "tbat_building_magic_potion_cabinet_puffcap_stand",
                anim = "test",
                scale = 0.3,
                offset = Vector3(0, -10, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_magic_potion_cabinet_puffcap_stand.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_magic_potion_cabinet_puffcap_stand")
                inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet_puffcap_stand")
                inst.AnimState:PlayAnimation("test",true)
            end,
            --------------------------------------------
            --- 参数集
                max_slot = 4,
                display_item_ground_type = true,  --- 显示物品还是图标
            --------------------------------------------
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    -- TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","tbat_mpc_tree_ring_counter")
    -- TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","tbat_mpc_ferris_wheel")
    for skin_name, v in pairs(skins_data) do
        TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies",skin_name)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return assets