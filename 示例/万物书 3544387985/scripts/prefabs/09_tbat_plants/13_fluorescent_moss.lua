--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_fluorescent_moss"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_fluorescent_moss.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local type_num = 1
    local function get_type_num()
        if not TBAT.DEBUGGING then
            return math.random(1,4)
        end
        local num = type_num
        type_num = type_num + 1
        if type_num > 4 then
            type_num = 1
        end
        return num
    end
    local light_data = {
        {206/255,254/255,228/255},  -- 206,254,228
        {217/255,201/255,169/255},  -- 217,201,169
        {186/255,209/255,163/255},  -- 186,209,163
        {148/255,214/255,181/255},  -- 148,214,181
    }
    local function light_init(inst)
        local type_num = inst.components.tbat_data:Get("type") or get_type_num()
        inst.Light:SetColour(unpack(light_data[type_num]))
        inst.AnimState:PlayAnimation("idle"..type_num,true)
        inst.AnimState:SetTime(3*math.random())
        inst.components.tbat_data:Set("type",type_num)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 挖掘
    local function onhammered(inst, worker)
        inst.components.lootdropper:SpawnLootPrefab(this_prefab.."_item")
        inst:Remove() 
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 植物本体
    local function plant_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_plant_fluorescent_moss")
        inst.AnimState:SetBuild("tbat_plant_fluorescent_moss")
        inst.AnimState:PlayAnimation("idle1",true)
        inst.AnimState:SetRayTestOnBB(true)
        inst:SetDeploySmartRadius(0)
        inst.entity:AddLight()
        inst.Light:SetFalloff(0.85)
        inst.Light:SetIntensity(.75)
        inst.Light:SetRadius(0.5)
        inst.Light:SetColour(178 / 255, 102 / 255, 255 / 255)
        inst:AddTag("fluorescent_plant")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst:DoTaskInTime(0,light_init)
        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)
        return inst
    end
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
--- 种植
    local function DeploySpacingRadius(...)
        return 0
    end
    local function inventoryitem_replica_init(inst,replica_com)
        replica_com.DeploySpacingRadius = DeploySpacingRadius
    end
    local function ondeploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        SpawnPrefab(this_prefab).Transform:SetPosition(pt.x,0,pt.z)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_plant_fluorescent_moss")
        inst.AnimState:SetBuild("tbat_plant_fluorescent_moss")
        inst.AnimState:PlayAnimation("item")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        ------------------------------------------------------------------------------------------
        --- 客户端
            inst:ListenForEvent("TBAT_OnEntityReplicated.inventoryitem",inventoryitem_replica_init)
        ------------------------------------------------------------------------------------------
        --- 服务器端
            if not TheWorld.ismastersim then
                return inst
            end
        ------------------------------------------------------------------------------------------
        --- 图标和检查
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_fluorescent_moss_item","images/inventoryimages/tbat_plant_fluorescent_moss_item.xml")
        ------------------------------------------------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize =  TBAT.PARAM.STACK_40()
        ------------------------------------------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------------------------
        --- 落水影子
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        ------------------------------------------------------------------------------------------
        --- 种植组件
            inst:AddComponent("deployable")                
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        ------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, plant_fn, assets),
    Prefab(this_prefab.."_item", item_fn, assets),
    MakePlacer(this_prefab.."_item_placer",this_prefab,this_prefab, "item", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

