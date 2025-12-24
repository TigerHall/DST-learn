--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    发光的路灯花

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_green_campanula_with_cat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_green_campanula_with_cat.zip"),
    }
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
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")
        inst.AnimState:SetBank("tbat_building_green_campanula_with_cat")
        inst.AnimState:SetBuild("tbat_building_green_campanula_with_cat")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:HideSymbol("light")
        MakeObstaclePhysics(inst, 0.1)
        inst:SetDeploySmartRadius(1) --recipe min_spacing/2
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        ------------------------------------------
        ---
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.85)
            inst.Light:SetIntensity(.75)
            inst.Light:SetRadius(5.5)
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
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        ------------------------------------------
        ---
            light_update_fn(inst)
            inst:WatchWorldState("phase",light_update_fn)
            inst:WatchWorldState("cycles",light_update_fn)
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

