--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_hedgehog_cactus_pot"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_hedgehog_cactus.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item accept
    local function acceptable_test_fn(inst,item,doer,right_click)
        if not inst:IsOnOcean(false) and item.prefab == "tbat_plant_hedgehog_cactus_seed"
            and not inst.replica.inventoryitem:IsGrandOwner(doer)
        then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        if inst.components.inventoryitem.owner then
            return false
        end
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:RemoveComponent("inventoryitem")
        inst.AnimState:PlayAnimation("sprout",false)
        local x,y,z = inst.Transform:GetWorldPosition()
        inst:ListenForEvent("animover",function()
            inst:Remove()
            local plant = SpawnPrefab("tbat_plant_hedgehog_cactus")
            plant.Transform:SetPosition(x,y,z)            
        end)
        item.components.stackable:Get():Remove()
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PLANTSOIL)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function on_deploy(inst, pt, deployer)
        local prefab = inst.prefab
        local x,y,z = pt.x,0,pt.z
        SpawnPrefab(prefab).Transform:SetPosition(x,y,z)
        inst:Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
        else
            inst.AnimState:Show("SHADOW")    
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 种植盆子
    local function item_pot_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_plant_hedgehog_cactus")
        inst.AnimState:SetBuild("tbat_plant_hedgehog_cactus")
        inst.AnimState:PlayAnimation("item_pot")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})

        inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        ------------------------------------------------------------------------------
        ---
            acceptable_com_install(inst)
        ------------------------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_hedgehog_cactus_pot","images/inventoryimages/tbat_plant_hedgehog_cactus_pot.xml")
        ------------------------------------------------------------------------------
        ---
            MakeHauntableLaunch(inst)
            inst:ListenForEvent("on_landed",item_onland_event)
        ------------------------------------------------------------------------------
        --- 
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable.ondeploy = on_deploy
        ------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("item_pot")
        local fx = inst:SpawnChild("tbat_sfx_dotted_circle_client")
        fx:PushEvent("Set",{ radius = 30 })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_plant_hedgehog_cactus_pot", item_pot_fn, assets),
    MakePlacer("tbat_plant_hedgehog_cactus_pot_placer","tbat_plant_hedgehog_cactus","tbat_plant_hedgehog_cactus", "item_pot", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

