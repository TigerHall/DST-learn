--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    时光壁炉

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_time_fireplace"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_time_fireplace.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local building_skin_data = {}
    building_skin_data["tbat_building_time_fireplace_with_flower"] = {
        bank = "tbat_building_time_fireplace",
        build = "tbat_building_time_fireplace",
        atlas = "images/inventoryimages/tbat_building_time_fireplace_with_flower.xml",
        image = "tbat_building_time_fireplace_with_flower",  -- 不需要 .tex
        name = TBAT:GetString2(this_prefab,"skin_with_flower"),        --- 切名字用的
        name_color = {255/255,255/255,255/255,1},
        server_fn = function(inst) -- 切换到这个skin调用 。服务端
            inst.AnimState:PlayAnimation("idle_flower",true)
        end,
        placer_fn = function(inst) -- 切换到这个skin调用 。服务端
            inst.AnimState:PlayAnimation("idle_flower",true)
        end,
        server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
            inst.AnimState:PlayAnimation("idle",true)
        end,
    }
    TBAT.SKIN:DATA_INIT(building_skin_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_building_time_fireplace_with_flower")
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fire fx
    local function create_fire_fx(inst)
        inst._fire_fx = inst:SpawnChild("campfirefire")
        inst._fire_fx.entity:AddFollower()
        inst._fire_fx.Follower:FollowSymbol(inst.GUID, "slot", 0, 0, 0)
        local scale = 0.4
        inst._fire_fx.AnimState:SetScale(scale,scale*0.8)
        inst._fire_fx.components.firefx:SetLevel(2)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_time_fireplace","tbat_building_time_fireplace")
        inst.AnimState:PlayAnimation("idle",true)
        inst:SetDeploySmartRadius(1.25) --recipe min_spacing/2
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
            inst:AddComponent("cooker")
        --------------------------------------------------------------------
        --- 
            inst:AddComponent("burnable")
            --inst.components.burnable:SetFXLevel(2)
            inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0), "slot", true, nil, true)
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5)
        --------------------------------------------------------------------
        --- 放置模块
            inst:DoTaskInTime(1,create_fire_fx)
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
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

