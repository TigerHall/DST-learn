--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local assets = {
        Asset("ANIM", "anim/tbat_wall_skin_strawberry_cream_cake.zip"),
        Asset("ANIM", "anim/tbat_wall_skin_coral_reef.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_wall_prefab = "wall_tbat_osmanthus_stone"
    local this_wall_item_prefab = "wall_tbat_osmanthus_stone_item"
    local common_bank = "wall"   --- 通常的墙的 bank

    -- TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_carpet_hello_kitty")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 墙皮肤
    local building_skins_data = {
        -----------------------------------------------------------------------------------
        --- 草莓奶油蛋糕
            ["tbat_wall_skin_strawberry_cream_cake"] = {
                bank = common_bank,
                build = "tbat_wall_skin_strawberry_cream_cake",
                unlock_announce_skip = true,
            },
        -----------------------------------------------------------------------------------
        --- 星贝珊瑚礁柱
            ["tbat_wall_skin_coral_reef"] = {
                bank = common_bank,
                build = "tbat_wall_skin_coral_reef",
                unlock_announce_skip = true,
            },
        -----------------------------------------------------------------------------------
    }
    TBAT.SKIN:DATA_INIT(building_skins_data,this_wall_prefab)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品的皮肤
    local item_skins_data = {
        -----------------------------------------------------------------------------------
        --- 草莓奶油蛋糕
            ["tbat_wall_strawberry_cream_cake"] = {
                bank = common_bank,
                build = "tbat_wall_skin_strawberry_cream_cake",
                atlas = "images/map_icons/tbat_wall_skin_strawberry_cream_cake.xml",
                image = "tbat_wall_skin_strawberry_cream_cake",  -- 不需要 .tex
                name = TBAT:GetString2(this_wall_item_prefab,"skin.strawberry_cream_cake"),        --- 切名字用的
                name_color = "pink",
                skin_link = "tbat_wall_skin_strawberry_cream_cake" ,        -- 链路解锁
                placed_skin_name = "tbat_wall_skin_strawberry_cream_cake" , -- deploy 用的
                unlock_announce_data = { -- 解锁提示
                    bank = common_bank,
                    build = "tbat_wall_skin_strawberry_cream_cake",
                    anim = "idle",
                    scale = 0.6,
                    offset = Vector3(0, 30, 0),
                },
                placer_fn = function(inst)
                    inst.AnimState:SetBank(common_bank)
                    inst.AnimState:SetBuild("tbat_wall_skin_strawberry_cream_cake")
                end
            },
        -----------------------------------------------------------------------------------
        --- 星贝珊瑚礁柱
            ["tbat_wall_coral_reef"] = {
                bank = common_bank,
                build = "tbat_wall_skin_coral_reef",
                atlas = "images/map_icons/tbat_wall_skin_coral_reef.xml",
                image = "tbat_wall_skin_coral_reef",  -- 不需要 .tex
                name = TBAT:GetString2(this_wall_item_prefab,"skin.coral_reef"),        --- 切名字用的
                name_color = "pink",
                skin_link = "tbat_wall_skin_coral_reef" ,        -- 链路解锁
                placed_skin_name = "tbat_wall_skin_coral_reef" , -- deploy 用的
                unlock_announce_data = { -- 解锁提示
                    bank = common_bank,
                    build = "tbat_wall_skin_coral_reef",
                    anim = "idle",
                    scale = 0.6,
                    offset = Vector3(0, 30, 0),
                },
                placer_fn = function(inst)
                    inst.AnimState:SetBank(common_bank)
                    inst.AnimState:SetBuild("tbat_wall_skin_coral_reef")
                end
            },
        -----------------------------------------------------------------------------------
    }
    TBAT.SKIN:DATA_INIT(item_skins_data,this_wall_item_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_wall_strawberry_cream_cake")
    TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","tbat_wall_coral_reef")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return assets