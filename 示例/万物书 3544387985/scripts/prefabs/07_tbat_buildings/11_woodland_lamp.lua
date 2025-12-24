--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_woodland_lamp"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_woodland_lamp.zip"),
        Asset("ANIM", "anim/tbat_building_woodland_lamp_starwish.zip"),
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_lamp_starwish"] = {                    --- 
            bank = "tbat_building_woodland_lamp_starwish",
            build = "tbat_building_woodland_lamp_starwish",
            atlas = "images/map_icons/tbat_building_woodland_lamp_starwish.xml",
            image = "tbat_building_woodland_lamp_starwish",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.starwish"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_woodland_lamp_starwish",
                build = "tbat_building_woodland_lamp_starwish",
                anim = "idle",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_turf_carpet_pink_fur_hello_kitty.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_woodland_lamp.tex")
            end,
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_lamp_starwish")
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- light
    local function light_on(inst)
        if inst.fx then
            inst.fx:Remove()
        end
        inst.fx = inst:SpawnChild("minerhatlight")
        inst.AnimState:Show("LIGHT")
    end
    local function light_off(inst)
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        inst.AnimState:Hide("LIGHT")
    end
    local function light_check(inst)
        if TheWorld:HasTag("cave") or not TheWorld.state.isday then
            light_on(inst)
        else
            light_off(inst)
        end
    end
    local function light_check_delay(inst)
        inst:DoTaskInTime(5,light_check)
    end
    local function light_module_install(inst)
        light_check_delay(inst)
        inst:WatchWorldState("phase",light_check_delay)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_woodland_lamp.tex")

        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_woodland_lamp","tbat_building_woodland_lamp")
        -- inst.AnimState:SetBank("tbat_building_woodland_lamp")
        -- inst.AnimState:SetBuild("tbat_building_woodland_lamp")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:SetTime(4*math.random())
        inst.AnimState:Hide("LIGHT")
        inst:AddTag("tbat_building_woodland_lamp")
        inst:AddTag("structure")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        --------------------------------------------------------------------
        --- 组件
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------------
        --- 名字
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5)
        --------------------------------------------------------------------
        ---
            light_module_install(inst)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:Hide("LIGHT")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

