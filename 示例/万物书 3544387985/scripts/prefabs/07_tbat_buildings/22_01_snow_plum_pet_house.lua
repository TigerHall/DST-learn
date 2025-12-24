--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_snow_plum_pet_house"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_snow_plum_pet_house.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local scale = 1.2
    local function scale_fx(inst)
        inst.AnimState:SetScale(scale,scale,scale)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 灯光控制
    local function light_on(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        local fx = inst:SpawnChild("minerhatlight")
        fx.Light:SetFalloff(0.4)
        fx.Light:SetIntensity(.9)
        fx.Light:SetRadius(0.9)
        fx.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
        inst.light_fx = fx
    end
    local function light_off(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        inst.light_fx = nil
    end
    local function light_checker(inst)
        if not TheWorld.state.isday or TheWorld:HasTag("cave") then
            light_on(inst)
        else
            light_off(inst)
        end
    end
    local function light_checker_delay(inst)
        inst:DoTaskInTime(5,light_checker)
    end
    local function light_install(inst)
        light_checker_delay(inst)
        inst:WatchWorldState("phase",light_checker_delay)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_snow_plum_pet_house.tex")
        MakeObstaclePhysics(inst, .5)
        inst.AnimState:SetBank("tbat_building_snow_plum_pet_house")
        inst.AnimState:SetBuild("tbat_building_snow_plum_pet_house")
        inst.AnimState:PlayAnimation("idle")
        scale_fx(inst)
        inst:AddTag("structure")
        inst.entity:SetPristine()
        TBAT.PET_MODULES:PetHouseComInstall(inst,"tbat_pet_eyebone_snow_plum_chieftain")
        if not TheWorld.ismastersim then
            return inst
        end
        light_install(inst)
        inst:AddComponent("inspectable")

        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local function placer_postinit_fn(inst)
        scale_fx(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

