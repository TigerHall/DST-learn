--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_cute_animal_wooden_figurines"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_cute_animal_wooden_figurines.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local building_skin_data = {}
    local item_skin_data = {}
    for i = 2, 3, 1 do
        building_skin_data["tbat_building_cute_animal_wooden_figurines_"..i] = {
            bank = "tbat_building_cute_animal_wooden_figurines",
            build = "tbat_building_cute_animal_wooden_figurines",
            atlas = "images/inventoryimages/tbat_building_cute_animal_wooden_figurines_"..i..".xml",
            image = "tbat_building_cute_animal_wooden_figurines_"..i,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin_"..i),        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            type = i,
            placed_skin_name = "tbat_building_cute_animal_wooden_figurines_kit_"..i,  --- 放置出来的皮肤名字。
            skin_link = "tbat_building_cute_animal_wooden_figurines_kit_"..i,  --- 放置出来的皮肤名字。
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("type"..i)
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.AnimState:PlayAnimation("type1")
            end,
        }
        item_skin_data["tbat_building_cute_animal_wooden_figurines_kit_"..i] = {
            bank = "tbat_building_cute_animal_wooden_figurines",
            build = "tbat_building_cute_animal_wooden_figurines",
            atlas = "images/inventoryimages/tbat_building_cute_animal_wooden_figurines_"..i..".xml",
            image = "tbat_building_cute_animal_wooden_figurines_"..i,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin_"..i),        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            type = i,
            placed_skin_name = "tbat_building_cute_animal_wooden_figurines_"..i,  --- 放置出来的皮肤名字。
            skin_link = "tbat_building_cute_animal_wooden_figurines_"..i,
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("type"..i)
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.AnimState:PlayAnimation("type1")
            end,
            placer_fn = function(inst)
                inst.AnimState:PlayAnimation("type"..i)                
            end
        }
    end
    TBAT.SKIN:DATA_INIT(building_skin_data,this_prefab)
    TBAT.SKIN:DATA_INIT(item_skin_data,this_prefab.."_kit")
    for i = 2, 3, 1 do
        TBAT.SKIN:AddForDefaultUnlock("tbat_building_cute_animal_wooden_figurines_kit_"..i)        
    end
    TBAT.SKIN:SetDefaultSkinName(building_skin_data,this_prefab,TBAT:GetString2(this_prefab,"skin_1"))
    TBAT.SKIN:SetDefaultSkinName(item_skin_data,this_prefab,TBAT:GetString2(this_prefab,"skin_1"))
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function onhammered(inst, worker)
        if worker and worker:HasTag("player") then
            local x,y,z = inst.Transform:GetWorldPosition()
            local item = SpawnPrefab(this_prefab.."_kit")
            item.Transform:SetPosition(x,0,z)
            Launch(item, worker,0.3)
            inst.components.tbat_com_skin_data:OnDeployItem(item,worker)
            inst:Remove()
        else
            inst.components.workable:SetWorkLeft(1)
        end
    end
    local function onhit(inst, worker)
        if worker and worker:HasTag("player") then

        else
            inst.components.workable:SetWorkLeft(1)
        end
    end
    local function building()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_cute_animal_wooden_figurines","tbat_building_cute_animal_wooden_figurines")
        inst.AnimState:PlayAnimation("type1",true)
        inst:AddTag("structure")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------------
        --- 拆除模块
            inst:AddComponent("lootdropper")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(onhammered)
            inst.components.workable:SetOnWorkCallback(onhit)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- kit
    local function on_deploy(inst, pt, deployer)
        local new_inst = SpawnPrefab(this_prefab)
        new_inst.Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.tbat_com_skin_data:OnDeployItem(new_inst,deployer)
        inst.components.stackable:Get():Remove()
    end
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_cute_animal_wooden_figurines","tbat_building_cute_animal_wooden_figurines")
        inst.AnimState:PlayAnimation("type1",true)
        inst.AnimState:SetScale(0.5,0.5,0.5)
        inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            inst:AddComponent("stackable")
        --------------------------------------------------------------------
        ---
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_building_cute_animal_wooden_figurines_1","images/inventoryimages/tbat_building_cute_animal_wooden_figurines_1.xml")
        --------------------------------------------------------------------
        --- 
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
            inst.components.deployable.ondeploy = on_deploy
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building, assets),
        Prefab(this_prefab.."_kit", item_fn, assets),
        MakePlacer(this_prefab.."_kit_placer",this_prefab,this_prefab, "type1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

