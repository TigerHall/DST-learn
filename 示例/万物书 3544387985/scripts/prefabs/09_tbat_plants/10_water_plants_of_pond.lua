--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    池边水草

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_water_plants_of_pond"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_water_plants_of_pond.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local building_skin_data = {}
    for i = 2, 7, 1 do
        building_skin_data["tbat_plant_water_plants_of_pond_"..i] = {
            bank = "tbat_plant_water_plants_of_pond",
            build = "tbat_plant_water_plants_of_pond",
            atlas = "images/inventoryimages/tbat_plant_water_plants_of_pond_"..i..".xml",
            image = "tbat_plant_water_plants_of_pond_"..i,  -- 不需要 .tex
            name = STRINGS.UI.CRAFTING.DEFAULT,        --- 切名字用的
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
    end
    TBAT.SKIN:DATA_INIT(building_skin_data,this_prefab)
    for i = 2, 7, 1 do
        TBAT.SKIN:AddForDefaultUnlock("tbat_plant_water_plants_of_pond_"..i)
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
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_plant_water_plants_of_pond","tbat_plant_water_plants_of_pond")
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
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle1",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

