--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    梅影装饰花丛

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_plum_blossom_bush"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_plum_blossom_bush.zip"),
        Asset("ANIM", "anim/tbat_plant_plum_blossom_bush_flower_thickets.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {

    }
    local flower_thickets_cmd = {
        ["dreambloom"] = {
            ["name"] = "绮梦花丛",
            color = "purple",
        },
        ["mistbloom"] = {
            ["name"] = "云雾花丛",
            color = "purple",
        },
        ["mosswhisper"] = {
            ["name"] = "绿语苔丛",
            color = "purple",
        },
        ["bunnysleep_orchid"] = {
            ["name"] = "兔眠花丛",
            color = "green",
        },
        ["warm_rose"] = {
            ["name"] = "暖樱玫瑰丛",
            color = "purple",
            fx = "tbat_plant_plum_blossom_bush_rose_skin_fx",
        },
        ["spark_rose"] = {
            ["name"] = "星火玫瑰丛",
            color = "purple",
            fx = "tbat_plant_plum_blossom_bush_rose_skin_fx",
        },
        ["luminmist_rose"] = {
            ["name"] = "云光玫瑰丛",
            color = "purple",
            fx = "tbat_plant_plum_blossom_bush_rose_skin_fx",
        },
        ["frostberry_rose"] = {
            ["name"] = "莓霜玫瑰丛",
            color = "purple",
            fx = "tbat_plant_plum_blossom_bush_rose_skin_fx",
        },
        ["stellar_rose"] = {
            ["name"] = "星辰玫瑰丛",
            color = "purple",
            fx = "tbat_plant_plum_blossom_bush_rose_skin_fx",
        },
    }
    for index,data_cmd in pairs(flower_thickets_cmd) do
        local this_skin_index = "tbat_pb_bush_"..index
        local image_atlas = "images/map_icons/tbat_plant_plum_blossom_bush_"..index..".xml"
        local image = "tbat_plant_plum_blossom_bush_"..index
        skins_data[this_skin_index] = {
            bank = "tbat_plant_plum_blossom_bush_flower_thickets",
            build = "tbat_plant_plum_blossom_bush_flower_thickets",
            atlas = image_atlas,
            image = image,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin."..index),        --- 切名字用的
            name_color = data_cmd.color or "green",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_plant_plum_blossom_bush_flower_thickets",
                build = "tbat_plant_plum_blossom_bush_flower_thickets",
                anim = index,
                scale = 0.3,
                offset = Vector3(0, 50, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon(image..".tex")
                inst.AnimState:PlayAnimation(index,true)
                inst.AnimState:SetTime(5*math.random())
                if data_cmd.fx then
                    inst.__fx = inst:SpawnChild(data_cmd.fx)
                end
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
                if inst.__fx and inst.__fx:IsValid() then
                    inst.__fx:Remove()
                    inst.__fx = nil
                end
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_plant_plum_blossom_bush_flower_thickets")
                inst.AnimState:SetBuild("tbat_plant_plum_blossom_bush_flower_thickets")
                inst.AnimState:PlayAnimation(index,true)
            end
        }
        if data_cmd.fx then
            TBAT.SKIN.SKIN_PACK:Pack("pack_rose_thicket",this_skin_index)
        end
        if index == "bunnysleep_orchid" then
            TBAT.SKIN.SKIN_PACK:Pack("pack_gifts",this_skin_index)
        else            
            TBAT.SKIN.SKIN_PACK:Pack("pack_green_fields_in_full_bloom",this_skin_index)
        end
    end
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_pb_bush_bunnysleep_orchid")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local workable_cmd = {
        action = ACTIONS.DIG,
        fx = false,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_plant_plum_blossom_bush","tbat_plant_plum_blossom_bush")
        -- inst.AnimState:SetBank("tbat_plant_plum_blossom_bush")
        -- inst.AnimState:SetBuild("tbat_plant_plum_blossom_bush")
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")
        inst:AddTag(this_prefab)
        inst.AnimState:SetTime(5*math.random())
        ------------------------------------------
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        ---
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,1,workable_cmd)
        ------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

