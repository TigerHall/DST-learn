--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    花语云梦灯

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_lamp_moon_with_clouds"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_lamp_moon_with_clouds.zip"),
        Asset("ANIM", "anim/tbat_building_lamp_moon_with_clouds_starwish.zip"),
        Asset("ANIM", "anim/tbat_building_lamp_moon_with_clouds_sleeping_kitty.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_lamp_moon_starwish"] = {                    --- 
            bank = "tbat_building_lamp_moon_with_clouds_starwish",
            build = "tbat_building_lamp_moon_with_clouds_starwish",
            atlas = "images/map_icons/tbat_building_lamp_moon_with_clouds_starwish.xml",
            image = "tbat_building_lamp_moon_with_clouds_starwish",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.starwish"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_lamp_moon_with_clouds_starwish",
                build = "tbat_building_lamp_moon_with_clouds_starwish",
                anim = "idle",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_lamp_moon_with_clouds_starwish.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
        },
        ["tbat_lamp_moon_sleeping_kitty"] = {                    --- 
            bank = "tbat_building_lamp_moon_with_clouds_sleeping_kitty",
            build = "tbat_building_lamp_moon_with_clouds_sleeping_kitty",
            atlas = "images/map_icons/tbat_building_lamp_moon_with_clouds_sleeping_kitty.xml",
            image = "tbat_building_lamp_moon_with_clouds_sleeping_kitty",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.starwish"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_lamp_moon_with_clouds_sleeping_kitty",
                build = "tbat_building_lamp_moon_with_clouds_sleeping_kitty",
                anim = "idle",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_lamp_moon_with_clouds_sleeping_kitty.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_lamp_moon_starwish")
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_lamp_moon_sleeping_kitty")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- light controller
    local function light_swtich_fn(inst)
        if TheWorld:HasTag("cave") or not TheWorld.state.isday then
            inst.Light:Enable(true)
            inst.AnimState:ShowSymbol("light")
        else
            inst.Light:Enable(false)
            inst.AnimState:HideSymbol("light")
        end
    end
    local function light_update_fn(inst)
        inst:DoTaskInTime(5,light_swtich_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnBuilt(inst,doer)
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable_cmd
    local workable_cmd = {
        block_remove = true,
        onfinished = function(inst,worker)
            inst.Light:Enable(false)
            inst.AnimState:HideSymbol("light")
            inst.AnimState:PlayAnimation("remove")
            inst:ListenForEvent("animover",inst.Remove)
        end,
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
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_lamp_moon_with_clouds","tbat_building_lamp_moon_with_clouds")
        -- inst.AnimState:SetBank("tbat_building_lamp_moon_with_clouds")
        -- inst.AnimState:SetBuild("tbat_building_lamp_moon_with_clouds")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:HideSymbol("light")
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        ------------------------------------------
        ---
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(2, 0.3)
        ------------------------------------------
        ---
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.85)
            inst.Light:SetIntensity(.75)
            inst.Light:SetRadius(1)
            inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
            inst.Light:Enable(false)
        ------------------------------------------
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        ---
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5,workable_cmd)
        ------------------------------------------
        ---
            light_update_fn(inst)
            inst:WatchWorldState("phase",light_update_fn)
            inst:WatchWorldState("cycles",light_update_fn)
        ------------------------------------------
        ---
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
        ------------------------------------------
        ---
            inst.OnBuilt = OnBuilt
        ------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:HideSymbol("light")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

