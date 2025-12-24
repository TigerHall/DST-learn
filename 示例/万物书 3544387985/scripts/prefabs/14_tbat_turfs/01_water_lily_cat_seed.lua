----------------------------------------------------------------------------------------------------------------------------------------------------
--[[


        local plant = SpawnPrefab("tbat_turf_water_lily_cat")
        local cmd_table = { 
            pt = Vector3(x,0,z),
            stop_grow = true,       --- 屏蔽生长（移植）
            dig_block = true,       --- 屏蔽挖掘(野生)
            only_test = false,       --- 只进行位置检测。不留下植物。

            success = false,         --- 回调
        }
        plant:PushEvent("deploy",cmd_table)

]]--
----------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local assets =
    {
        Asset("ANIM", "anim/tbat_turf_water_lily_cat_seed.zip"),
    }
----------------------------------------------------------------------------------------------------------------------------------------------------
--- 
----------------------------------------------------------------------------------------------------------------------------------------------------
--- test
    local function CLIENT_CanDeployDockKit(inst, pt, mouseover, deployer, rotation)
        local x, y, z = pt:Get()
        local center_pt = Vector3(TBAT.MAP:GetTileCenterPoint(x,y,z))
        return TheWorld.Map:CanDeployDockAtPoint(center_pt, inst, mouseover)
    end

    local function on_deploy(inst, pt, deployer)
        local prefab = inst.prefab
        local x,y,z = pt.x,0,pt.z
        SpawnPrefab("halloween_moonpuff").Transform:SetPosition(x,0,z)
        local plant = SpawnPrefab("tbat_turf_water_lily_cat")
        local cmd_table = { 
            pt = Vector3(x,0,z),
            stop_grow = true,
        }
        plant:PushEvent("deploy",cmd_table)
        if cmd_table.success then
            -- print("seed success")
        else
            -- print("seed fail")
            SpawnPrefab(prefab).Transform:SetPosition(x,0,z)
        end
        inst.components.stackable:Get():Remove()
    end

    local function kit_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_turf_water_lily_cat_seed")
        inst.AnimState:SetBuild("tbat_turf_water_lily_cat_seed")
        inst.AnimState:PlayAnimation("idle2")


        MakeInventoryFloatable(inst)


        inst:AddTag("groundtile")
        inst:AddTag("deploykititem")
        inst:AddTag("usedeployspacingasoffset")
        inst:AddTag("tbat_turf_water_lily_cat_seed")
        inst:AddTag("waterproofer")

        inst._custom_candeploy_fn = CLIENT_CanDeployDockKit -- for DEPLOYMODE.CUSTOM
        
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        -------------------------------------------------------
        inst:AddComponent("inspectable")

        -------------------------------------------------------
        inst:AddComponent("inventoryitem")
        inst:AddComponent("waterproofer")

        -------------------------------------------------------
        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        inst.components.deployable:SetUseGridPlacer(true)
        inst.components.deployable.ondeploy = on_deploy

        -------------------------------------------------------
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        return inst
    end
----------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品
    local function leaf_item_in_ocean(inst)
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetSortOrder(0)
        inst.AnimState:SetFloatParams(0, 0, 1)
        local floater = inst.components.floater
        if floater then
            floater:SetVerticalOffset(0)
            floater:SetScale({0.7,1,1})
        end
    end
    local function leaf_item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst:DoTaskInTime(0,leaf_item_in_ocean)
        end
    end
    local function leaf_item()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_turf_water_lily_cat_seed")
        inst.AnimState:SetBuild("tbat_turf_water_lily_cat_seed")
        inst.AnimState:PlayAnimation("idle1")

        MakeInventoryFloatable(inst, "med", 0.05, {1,1,1})

        inst:AddTag("tbat_turf_water_lily_cat_leaf")
        inst:AddTag("waterproofer")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -------------------------------------------------------
            inst:AddComponent("inspectable")
        -------------------------------------------------------
            inst:AddComponent("inventoryitem")
        -------------------------------------------------------
            inst:AddComponent("waterproofer")
        -------------------------------------------------------
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
        -------------------------------------------------------
            inst:ListenForEvent("on_landed",leaf_item_onland_event)
        -------------------------------------------------------
        --- 必须拥有这个，地板码头那边才能接受物品
            inst:AddComponent("repairer")
            inst.components.repairer.repairmaterial = MATERIALS.WOOD
            inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH
        -------------------------------------------------------
        return inst
    end
----------------------------------------------------------------------------------------------------------------------------------------------------



return Prefab("tbat_turf_water_lily_cat_seed", kit_fn, assets),
    Prefab("tbat_turf_water_lily_cat_leaf", leaf_item, assets)

