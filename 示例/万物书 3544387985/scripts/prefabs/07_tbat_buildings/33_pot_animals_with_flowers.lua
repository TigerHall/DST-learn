--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    萌宠装饰盆栽

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_pot_animals_with_flowers"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_pot_animals_with_flowers.zip"),
        Asset("ANIM", "anim/tbat_building_pot_skins.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {}
    local pack_skins = {
        ["verdant_grove"] = {
            ["name"] = "翠意绿植",
            ["color"] = "purple",
            ["pack"] = {"pack_green_fields_in_full_bloom"}
        },
        ["bunny_cart"] = {
            ["name"] = "花车萌趣",
            ["color"] = "purple",
            ["pack"] = {"pack_green_fields_in_full_bloom"}
        },
        ["dreambloom_vase"] = {
            ["name"] = "紫梦花瓶",
            ["color"] = "purple",
            ["pack"] = {"pack_green_fields_in_full_bloom"}
        },
        ["foxglean_basket"] = {
            ["name"] = "狐趣果篮",
            ["color"] = "green",
            ["pack"] = {"pack_gifts"}
        },
        ["lavendream"] = {
            ["name"] = "紫韵小花",
            ["color"] = "purple",
            ["pack"] = {"pack_green_fields_in_full_bloom"}
        },
        ["cloudlamb_vase"] = {
            ["name"] = "羊咩云花",
            ["color"] = "purple",
            ["pack"] = {"pack_green_fields_in_full_bloom"}
        },
    }
    for index, data_cmd in pairs(pack_skins) do
        local this_skin_index = "tbat_pot_"..index
        local image_atlas = "images/map_icons/tbat_building_pot_"..index..".xml"
        local image = "tbat_building_pot_"..index
        skins_data[this_skin_index] = {                    --- 
            bank = "tbat_building_pot_skins",
            build = "tbat_building_pot_skins",
            atlas = image_atlas,
            image = image,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin."..index),        --- 切名字用的
            name_color = data_cmd.color or "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_pot_skins",
                build = "tbat_building_pot_skins",
                anim = index,
                scale = 0.4,
                offset = Vector3(0, -20, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon(image..".tex")
                inst.AnimState:PlayAnimation(index,true)
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:PlayAnimation("idle",true)
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_pot_skins")
                inst.AnimState:SetBuild("tbat_building_pot_skins")
                inst.AnimState:PlayAnimation(index,true)
            end
        }
        if type(data_cmd.pack) == "table" then
            for k, pack_name in pairs(data_cmd.pack) do
                TBAT.SKIN.SKIN_PACK:Pack(pack_name,this_skin_index)
            end
        end
    end
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_pot_foxglean_basket")
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
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_pot_animals_with_flowers","tbat_building_pot_animals_with_flowers")
        -- inst.AnimState:SetBank("tbat_building_pot_animals_with_flowers")
        -- inst.AnimState:SetBuild("tbat_building_pot_animals_with_flowers")
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        ------------------------------------------
        ---
        ------------------------------------------
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        ---
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
            MakeHauntableLaunch(inst)
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
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

