--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_red_spider_lily_rocking_chair"
    local default_anim_speed = 0.7
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_red_spider_lily_rocking_chair.zip"),
        Asset("ANIM", "anim/tbat_building_red_spider_lily_rocking_chair_2.zip"),
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_building_red_spider_lily_rocking_chair_2"] = {                    --- 
            bank = "tbat_building_red_spider_lily_rocking_chair_2",
            build = "tbat_building_red_spider_lily_rocking_chair_2",
            atlas = "images/map_icons/tbat_building_red_spider_lily_rocking_chair.xml",
            image = "tbat_building_red_spider_lily_rocking_chair",  -- 不需要 .tex
            name = "ANIM-2",        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.AnimState:SetDeltaTimeMultiplier(default_anim_speed)
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.AnimState:SetDeltaTimeMultiplier(default_anim_speed)                
            end
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_building_red_spider_lily_rocking_chair_2")
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- sitting event
    local function player_on_set_event(inst,doer)
        --------------------------------------------------------------------
        --- 动画控制
            inst.AnimState:PlayAnimation("swing_pre")
            inst.AnimState:PushAnimation("swing_loop", true)
        --------------------------------------------------------------------
        --- san 控制
            if doer.components.sanity then
                if inst.__sanity_task then
                    inst.__sanity_task:Cancel()
                end
                inst.__sanity_task = doer:DoPeriodicTask(1,function()
                    doer.components.sanity:DoDelta(3,true)
                end)
            end
        --------------------------------------------------------------------
        --- 血量控制
            if doer.components.health then
                if inst.__health_task then
                    inst.__health_task:Cancel()
                end
                inst.__health_task = doer:DoPeriodicTask(1,function()
                    doer.components.health:DoDelta(1,true)
                end)
            end
        --------------------------------------------------------------------
    end
    local function player_stop_sitting_event(inst,doer)
        --------------------------------------------------------------------
        --- 动画控制
            inst.AnimState:PlayAnimation("idle",true)
        --------------------------------------------------------------------
        --- san 控制
            if inst.__sanity_task then
                inst.__sanity_task:Cancel()
                inst.__sanity_task = nil
            end
        --------------------------------------------------------------------
        --- 血量控制
            if inst.__health_task then
                inst.__health_task:Cancel()
                inst.__health_task = nil
            end
        --------------------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_red_spider_lily_rocking_chair.tex")

        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_red_spider_lily_rocking_chair","tbat_building_red_spider_lily_rocking_chair")
        -- inst.AnimState:SetBank("tbat_building_red_spider_lily_rocking_chair")
        -- inst.AnimState:SetBuild("tbat_building_red_spider_lily_rocking_chair")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:SetDeltaTimeMultiplier(default_anim_speed)
        inst.AnimState:OverrideSymbol("slot","tbat_building_red_spider_lily_rocking_chair","empty")
        inst:AddTag("tbat_building_red_spider_lily_rocking_chair")
        inst:AddTag("structure")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 秋千核心模块
            TBAT.MODULES:Swing_Install(inst)
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        --------------------------------------------------------------------
        ---
            inst:ListenForEvent("player_sit_on",player_on_set_event)
            inst:ListenForEvent("player_stop_sitting",player_stop_sitting_event)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:OverrideSymbol("slot","tbat_building_red_spider_lily_rocking_chair","empty")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

