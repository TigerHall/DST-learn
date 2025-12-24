--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_whisper_tome_squirrel_phonograph"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_squirrel_phonograph.zip"),
        Asset("ANIM", "anim/tbat_building_whisper_tome_spellwisp_desk.zip"),
        Asset("ANIM", "anim/tbat_building_whisper_tome_chirpwell.zip"),
        Asset("ANIM", "anim/tbat_building_whisper_tome_purr_oven.zip"),
        Asset("ANIM", "anim/tbat_building_whisper_tome_swirl_vanity.zip"),
        Asset("ANIM", "anim/tbat_building_whisper_tome_birdchime_clock.zip"),
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {}
    local all_skins_cmd = {
        ["spellwisp_desk"] = {
            name = "幽蓝巫术桌",
            color = "pink",
            bank_build = "tbat_building_whisper_tome_spellwisp_desk",
            anim_lengh = 6,
            packs = {"pack_warm_and_cozy_home"},
        },
        ["chirpwell"] = {
            name = "童趣水井亭",
            color = "pink",
            bank_build = "tbat_building_whisper_tome_chirpwell",
            packs = {"pack_warm_and_cozy_home"},
        },
        ["purr_oven"] = {
            name = "猫咪烘焙炉",
            color = "pink",
            bank_build = "tbat_building_whisper_tome_purr_oven",
            packs = {"pack_warm_and_cozy_home"},
        },
        ["swirl_vanity"] = {
            name = "芙蕾雅の小兔梳妆台",
            color = "red",
            anim_lengh = 5,
            annouce_scale = 0.35,
            bank_build = "tbat_building_whisper_tome_swirl_vanity",
        },
        ["birdchime_clock"] = {
            name = "鸟语时钟",
            color = "green",
            annouce_scale = 0.35,
            bank_build = "tbat_building_whisper_tome_birdchime_clock",
            packs = {"pack_gifts"},
        },
    }
    for index, data_cmd in pairs(all_skins_cmd) do
        local this_skin_index = "tbat_whisper_tome_"..index
        local bank_build = data_cmd.bank_build
        skins_data[this_skin_index] = {
            bank = bank_build,
            build = bank_build,
            atlas = "images/map_icons/"..bank_build..".xml",
            image = bank_build,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin."..index),        --- 切名字用的
            name_color = data_cmd.color or "green",
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.MiniMapEntity:SetIcon("tbat_building_whisper_tome_spellwisp_desk.tex")
                inst.AnimState:PlayAnimation("idle",true)
                if data_cmd.anim_lengh then
                    inst.AnimState:SetTime(data_cmd.anim_lengh*math.random())
                end
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            unlock_announce_data = { -- 解锁提示
                bank = bank_build,
                build = bank_build,
                anim = "idle",
                scale = data_cmd.annouce_scale or 0.25,
                offset = Vector3(0, -50, 0),
            },
            placer_fn = function(inst)
                inst.AnimState:SetBank(bank_build)
                inst.AnimState:SetBuild(bank_build)
                inst.AnimState:PlayAnimation("idle",true)
            end
        }
        if type(data_cmd.packs) == "table" then
            for k, pack_name in pairs(data_cmd.packs) do
                TBAT.SKIN.SKIN_PACK:Pack(pack_name,this_skin_index)
            end
        end
    end
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_whisper_tome_birdchime_clock")
    TBAT.SKIN:SetDefaultSkinName(skins_data,this_prefab,TBAT:GetString2(this_prefab,"skin.1"))
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")

        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_squirrel_phonograph","tbat_building_squirrel_phonograph")
        -- inst.AnimState:SetBank("tbat_building_squirrel_phonograph")
        -- inst.AnimState:SetBuild("tbat_building_squirrel_phonograph")
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag(this_prefab)
        inst:AddTag("structure")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer","tbat_building_squirrel_phonograph","tbat_building_squirrel_phonograph", "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

