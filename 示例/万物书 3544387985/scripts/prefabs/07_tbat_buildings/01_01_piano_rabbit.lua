--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_piano_rabbit"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_piano_rabbit.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_cherry_blossom_rabbit_hud.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_cherry_blossom_rabbit_hud.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 特效
    local function create_single_fx(parent)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.AnimState:SetBuild("tbat_building_piano_rabbit")
        inst.AnimState:SetBank("tbat_building_piano_rabbit")
        inst.entity:SetParent(parent.entity)
        inst.entity:AddFollower()
        table.insert(parent.sfx,inst)
        return inst
    end
    local function createFx(inst)
        -----------------------------------------------
        --- 特效
            inst.sfx = inst.sfx or {}
            for k, v in pairs(inst.sfx) do
                v:Remove()
            end
            inst.sfx = {}
        -----------------------------------------------
        --- 
            local build = "tbat_building_piano_rabbit"
        -----------------------------------------------
        --- 小兔子头
            for i = 1, 3, 1 do
                inst.AnimState:OverrideSymbol("rabbit"..i,build,"empty")
                local fx = create_single_fx(inst)
                fx.Follower:FollowSymbol(inst.GUID, "rabbit"..i,  0, 0, 0,true)
                fx.AnimState:PlayAnimation("rabbit"..i,true)
                fx.AnimState:SetTime(2*math.random())
            end
        -----------------------------------------------
        --- 星星
            for i = 1, 6, 1 do
                inst.AnimState:OverrideSymbol("star"..i,build,"empty")
                local fx = create_single_fx(inst)
                fx.Follower:FollowSymbol(inst.GUID, "star"..i,  0, 0, 0,true)
                fx.AnimState:OverrideSymbol("star1",build,"star"..i)
                fx.AnimState:PlayAnimation("star_"..math.random(2),true)
                fx.AnimState:SetTime(math.random())
                fx.AnimState:SetDeltaTimeMultiplier(0.5)
            end
        -----------------------------------------------
        --- 眼睛
            inst.AnimState:OverrideSymbol("eyes",build,"empty")
            local eyes = create_single_fx(inst)
            eyes.Follower:FollowSymbol(inst.GUID, "eyes",  0, 0, 0,true)
            eyes.AnimState:PlayAnimation("eye",true)
            eyes.AnimState:SetTime(math.random()*2)
            eyes.AnimState:SetDeltaTimeMultiplier(0.2)
        -----------------------------------------------
        --- 嘴巴
            inst.AnimState:OverrideSymbol("mouth",build,"empty")
            local mouth = create_single_fx(inst)
            mouth.Follower:FollowSymbol(inst.GUID, "mouth",  0, 0, 0,true)
            mouth.AnimState:PlayAnimation("mouth",true)
            mouth.AnimState:SetTime(math.random()*2)
            mouth.AnimState:SetDeltaTimeMultiplier(0.5)
        -----------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- data
    local type_data = require("prefabs/07_tbat_buildings/01_03_piano_type_data")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hud和逻辑
    local hud_install = require("prefabs/07_tbat_buildings/01_04_piano_hud_install")
    local type_logic_install = require("prefabs/07_tbat_buildings/01_05_piano_swtich_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拆毁
    local workable_install = require("prefabs/07_tbat_buildings/01_02_piano_destory_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 声音播放
    local function play_onbuild_sound(inst)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_building_piano_rabbit/onwork_"..math.random(3))        
    end
    local function item_on_build_event(inst,data)
        play_onbuild_sound(inst)
        inst:DoTaskInTime(1,play_onbuild_sound)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function common_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        -- MakeInventoryPhysics(inst)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_piano_rabbit.tex")

        inst.AnimState:SetBank("tbat_building_piano_rabbit")
        inst.AnimState:SetBuild("tbat_building_piano_rabbit")
        inst.AnimState:PlayAnimation("idle",true)

        inst:AddTag("structure")
        inst:AddTag("tbat_building_piano_rabbit")

        if not TheNet:IsDedicated() then
            createFx(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------
        --- 
            inst:ListenForEvent("builditem",item_on_build_event)
        ------------------------------------------------
        --- 功能组件
            workable_install(inst)        
        ------------------------------------------------
        --- 
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 建筑集群。
    local ret_prefabs = {}
    table.insert(ret_prefabs,Prefab(this_prefab, common_fn, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        createFx(inst)
        inst.AnimState:PlayAnimation("idle",true)
    end
    table.insert(ret_prefabs,   MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)    )
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 集群创建
    for type_index, data in pairs(type_data) do
        local new_prefab = this_prefab.."_"..type_index
        if data.init then
            data.init(new_prefab)
        end
        PROTOTYPER_DEFS[new_prefab] = PROTOTYPER_DEFS[type_index]
        local function fn()
            local inst = common_fn()

            ------------------------------------------------
            --- common_fn
                if data.common_fn then
                    data.common_fn(inst)
                end
            ------------------------------------------------
            --- 
                inst:AddTag(type_index)                
                inst.entity:SetPristine()
            ------------------------------------------------
            ---
                if TheWorld.ismastersim then
                    inst:AddComponent("tbat_data")
                end
                hud_install(inst)
                type_logic_install(inst)
            ------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            ------------------------------------------------
            --- master
                if data.master_fn then
                    data.master_fn(inst)
                end
            ------------------------------------------------
            return inst
        end
        TBAT:SetStringData(new_prefab,TBAT:GetStringData(this_prefab))
        table.insert( ret_prefabs , Prefab(new_prefab, fn))
    end
    TBAT:AllStringTableInit()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- return Prefab(this_prefab, common_fn, assets)
return unpack(ret_prefabs)
