--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_coconut_tree_seed"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_coconut_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function on_deploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        local tree = SpawnPrefab("tbat_plant_coconut_tree")
        tree.components.growable:SetStage(2)
        tree.Transform:SetPosition(pt.x,0,pt.z)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function _custom_candeploy_fn(inst, pt, mouseover, deployer, rot)
        return TheWorld.Map:CanDeployPlantAtPoint(pt,inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_plant_coconut_cat")
        inst.AnimState:SetBuild("tbat_plant_coconut_cat")
        inst.AnimState:PlayAnimation("stage_0",true)

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})

        inst.entity:SetPristine()

        inst._custom_candeploy_fn = _custom_candeploy_fn

        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_coconut_tree_seed","images/inventoryimages/tbat_plant_coconut_tree_seed.xml")
            MakeHauntableLaunch(inst)
        -----------------------------------------
        ---
            TBAT.FNS:ShadowInit(inst)
        -----------------------------------------
        ---
            inst:AddComponent("stackable")
        -----------------------------------------
        ---
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable.ondeploy = on_deploy
        -----------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        -- inst.AnimState:SetBank(name)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Prefab(this_prefab, fn, assets),
    MakePlacer(this_prefab.."_placer","tbat_plant_coconut_tree","tbat_plant_coconut_tree", "stage_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

