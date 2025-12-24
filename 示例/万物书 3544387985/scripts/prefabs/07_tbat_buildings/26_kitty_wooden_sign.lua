--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    喵喵小木牌

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_kitty_wooden_sign"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_kitty_wooden_sign.zip"),
        Asset("ANIM", "anim/tbat_building_kitty_wooden_sign_sp_info.zip"),  -- 额外牌子信息
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 文字图层数据
    local all_info_data = {
        [1] = {
            pt = Vector3(-15,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "storage_area",
        },
        [2] = {
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "technology_area",
        },
        [3] = {
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "villa",
        },
        [4] = {
            pt = Vector3(-10,-335,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "zoo",
        },
        [5] = {
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "tourist_area",
        },
        [6] = {
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "fantasy_island",
        },
        [7] = {
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "exhibition_hall",
        },
        [8] = {
            pt = Vector3(-10,-350,0),
            build = "tbat_building_kitty_wooden_sign",
            layer = "plantation",
        },
        [9] = {
            --- 隐藏款 ： 花花的
            pt = Vector3(-10,-340,0),
            build = "tbat_building_kitty_wooden_sign",
            bank = "tbat_building_kitty_wooden_sign",
            anim = "huahua",
            hidden = true,
        },
        [10] = {
            --- 隐藏款 ： 阿茗的小屋
            pt = Vector3(-10,-345,0),
            build = "tbat_building_kitty_wooden_sign_sp_info",
            bank = "tbat_building_kitty_wooden_sign_sp_info",
            anim = "am",
            hidden = true,
        },
        [11] = {
            --- 隐藏款 ： 阿瑶的小屋
            pt = Vector3(-10,-348,0),
            build = "tbat_building_kitty_wooden_sign_sp_info",
            bank = "tbat_building_kitty_wooden_sign_sp_info",
            anim = "ay",
            hidden = true,
        },
        [12] = {
            --- 隐藏款 ： 等秋零的小屋
            pt = Vector3(-10,-338,0),
            build = "tbat_building_kitty_wooden_sign_sp_info",
            bank = "tbat_building_kitty_wooden_sign_sp_info",
            anim = "dql",
            hidden = true,
        },
        [13] = {
            --- 隐藏款 ： 芙蕾雅的小屋
            pt = Vector3(-10,-337,0),
            build = "tbat_building_kitty_wooden_sign_sp_info",
            bank = "tbat_building_kitty_wooden_sign_sp_info",
            anim = "fly",
            hidden = true,
        },
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local building_skin_data = {}
    for i = 2, #all_info_data, 1 do
        local this_skin_index = "tbat_building_kitty_wooden_sign_"..i
        building_skin_data[this_skin_index] = {
            bank = "tbat_building_kitty_wooden_sign",
            build = "tbat_building_kitty_wooden_sign",
            atlas = "images/inventoryimages/tbat_building_kitty_wooden_sign.xml",
            image = "tbat_building_kitty_wooden_sign",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin_"..i),        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst:PushEvent("InfoSet",all_info_data[i])
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst:PushEvent("InfoReset")
            end,
        }
        -----------------------------------------------------------------------------------
        --- 给解锁提示用
            if all_info_data[i].hidden then
                building_skin_data[this_skin_index].unlock_announce_data = { -- 解锁提示
                    bank = "tbat_building_kitty_wooden_sign",
                    build = "tbat_building_kitty_wooden_sign",
                    anim = "idle",
                    scale = 0.3,
                    offset = Vector3(0,-20,0),
                    fn = function(anim,root)
                        local UIAnim = require "widgets/uianim"
                        local ex_anim = anim:AddChild(UIAnim())
                        ex_anim:GetAnimState():SetBank(all_info_data[i].bank)
                        ex_anim:GetAnimState():SetBuild(all_info_data[i].build)
                        ex_anim:GetAnimState():PlayAnimation(all_info_data[i].anim,true)
                        local offset_pt = (all_info_data[i].pt or Vector3(0,0,0) )
                        ex_anim:SetPosition(offset_pt.x,-offset_pt.y,offset_pt.z)
                    end
                }
                building_skin_data[this_skin_index].name_color = "red"
                -- if TBAT.DEBUGGING then
                --     TBAT.SKIN.SKIN_PACK:Pack("tbat_building_kitty_wooden_sign_owners",this_skin_index)
                -- end
            end
        -----------------------------------------------------------------------------------
    end
    TBAT.SKIN:DATA_INIT(building_skin_data,this_prefab)
    for i = 2, 8, 1 do
        TBAT.SKIN:AddForDefaultUnlock("tbat_building_kitty_wooden_sign_"..i)        
    end
    TBAT.SKIN:SetDefaultSkinName(building_skin_data,this_prefab,TBAT:GetString2(this_prefab,"skin_1"))
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_kitty_wooden_sign","tbat_building_kitty_wooden_sign")
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")
        inst:AddTag(this_prefab)
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 挂载点，方便其他语言的MOD进来修改。
            inst.all_info_data = all_info_data
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------------
        --- 
            TBAT.MODULES:SignWithTextAnimLayerInstall(inst,all_info_data[1])
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        -- inst.AnimState:HideSymbol("text")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

