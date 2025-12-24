--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    花喵小石子

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_resource_kitty_stone"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_resource_kitty_stone.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local building_skin_data = {}
    local item_skin_data = {}
    for i = 2, 5, 1 do
        building_skin_data["tbat_resource_kitty_stone_"..i] = {
            bank = "tbat_resource_kitty_stone",
            build = "tbat_resource_kitty_stone",
            atlas = "images/inventoryimages/tbat_resource_kitty_stone_"..i..".xml",
            image = "tbat_resource_kitty_stone_"..i,  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin_"..i),        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("idle"..i,true)
            end,
            placer_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("idle"..i,true)
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.AnimState:PlayAnimation("idle1",true)
            end,
        }
        item_skin_data["tbat_resource_kitty_stone_item_"..i] = {
            bank = "tbat_resource_kitty_stone",
            build = "tbat_resource_kitty_stone",
            atlas = "images/inventoryimages/tbat_resource_kitty_stone_"..i..".xml",
            image = "tbat_resource_kitty_stone_"..i,
            name = TBAT:GetString2(this_prefab,"skin_"..i),
            name_color = {255/255,255/255,255/255,1},
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("idle"..i,true)
            end,
            placer_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:PlayAnimation("idle"..i,true)
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.AnimState:PlayAnimation("idle1",true)
            end,
            placed_skin_name = "tbat_resource_kitty_stone_"..i,
            skin_link = "tbat_resource_kitty_stone_"..i,
        }
    end
    TBAT.SKIN:DATA_INIT(building_skin_data,this_prefab)
    TBAT.SKIN:DATA_INIT(item_skin_data,this_prefab.."_item")
    for i = 2, 5, 1 do
        -- TBAT.SKIN:AddForDefaultUnlock("tbat_resource_kitty_stone_"..i)
        TBAT.SKIN:AddForDefaultUnlock("tbat_resource_kitty_stone_item_"..i)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local workable_cmd = {
        action = ACTIONS.DIG,
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_resource_kitty_stone","tbat_resource_kitty_stone")
        inst.AnimState:PlayAnimation("idle1",true)
        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")
        inst:AddTag(this_prefab)
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
        --- 
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,1,workable_cmd)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品
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
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_resource_kitty_stone","tbat_resource_kitty_stone")
        inst.AnimState:PlayAnimation("idle1",true)
        inst:AddTag("usedeploystring")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        ---
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        --------------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------------
        --- 
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_resource_kitty_stone","images/inventoryimages/tbat_resource_kitty_stone.xml")
        --------------------------------------------------------------------
        ---
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TBAT.PARAM.STACK_60()
        --------------------------------------------------------------------
        --- 放置
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
            inst.components.deployable.ondeploy = on_deploy
        --------------------------------------------------------------------
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building, assets),
    Prefab(this_prefab.."_item", item_fn, assets),
        MakePlacer(this_prefab.."_item_placer",this_prefab,this_prefab,"idle1",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

