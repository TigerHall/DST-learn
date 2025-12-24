--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_resources_memory_crystal_ore_core"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_resources_memory_crystal_ore_core.zip"),
        Asset("ANIM", "anim/tbat_resources_memory_crystal_ore.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:Show("SHADOW")
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- deploy
    local function ondeploy(inst, pt, deployer)
        SpawnPrefab("tbat_resources_memory_crystal_ore_1").Transform:SetPosition(pt.x,0,pt.z)
        inst.components.stackable:Get():Remove()
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
        inst.AnimState:SetBank("tbat_resources_memory_crystal_ore_core")
        inst.AnimState:SetBuild("tbat_resources_memory_crystal_ore_core")
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("usedeploystring")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        ---------------------------------------------------------
        --- 物品
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_resources_memory_crystal_ore_core","images/map_icons/tbat_resources_memory_crystal_ore_core.xml")
        ---------------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize =  TBAT.PARAM.STACK_20()
        ---------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        ---------------------------------------------------------
        --- 影子
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        ---------------------------------------------------------
        ---
            inst:AddComponent("deployable")
            inst.components.deployable.ondeploy = ondeploy
            -- inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
            -- inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
        ---------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local function placer_postinit_fn(inst)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer", "tbat_resources_memory_crystal_ore", "tbat_resources_memory_crystal_ore", "stage_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

