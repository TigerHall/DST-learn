--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_rough_cut_wood_sofa"
    local default_anim_speed = 1.2
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_rough_cut_wood_sofa.zip"),
        -- Asset("ANIM", "anim/tbat_building_rough_cut_wood_sofa_2.zip"),
        Asset("ANIM", "anim/tbat_building_rough_cut_wood_sofa_magic_broom.zip"),
        Asset("ANIM", "anim/tbat_building_rough_cut_wood_sofa_sunbloom.zip"),
        Asset("ANIM", "anim/tbat_building_rough_cut_wood_sofa_lemon_cookie.zip"),
    }
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_building_rough_cut_wood_sofa_2"] = {                    --- 
            bank = "tbat_building_rough_cut_wood_sofa",
            build = "tbat_building_rough_cut_wood_sofa",
            atlas = "images/map_icons/tbat_building_rough_cut_wood_sofa.xml",
            image = "tbat_building_rough_cut_wood_sofa",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.2"),        --- 切名字用的
            name_color = {255/255,255/255,255/255,1},
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.sitting_anim = "swing"
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.sitting_anim = nil
            end
        },
        ["tbat_wood_sofa_magic_broom"] = {                    --- 
            bank = "tbat_building_rough_cut_wood_sofa_magic_broom",
            build = "tbat_building_rough_cut_wood_sofa_magic_broom",
            atlas = "images/map_icons/tbat_building_rough_cut_wood_sofa_magic_broom.xml",
            image = "tbat_building_rough_cut_wood_sofa_magic_broom",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.magic_broom"),        --- 切名字用的
            name_color = "pink",
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.MiniMapEntity:SetIcon("tbat_building_rough_cut_wood_sofa_magic_broom.tex")
                inst.AnimState:PlayAnimation("idle",true)
                inst.AnimState:SetTime(10*math.random())
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_rough_cut_wood_sofa_magic_broom",
                build = "tbat_building_rough_cut_wood_sofa_magic_broom",
                anim = "idle",
                scale = 0.3,
                offset = Vector3(0, 0, 0),
                fn = function(icon_anim,slot)
                    icon_anim:GetAnimState():OverrideSymbol("slot","tbat_building_rough_cut_wood_sofa_magic_broom","empty")
                end
            },
        },
        ["tbat_wood_sofa_sunbloom"] = {                    --- 
            bank = "tbat_building_rough_cut_wood_sofa_sunbloom",
            build = "tbat_building_rough_cut_wood_sofa_sunbloom",
            atlas = "images/map_icons/tbat_building_rough_cut_wood_sofa_sunbloom.xml",
            image = "tbat_building_rough_cut_wood_sofa_sunbloom",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.sunbloom"),        --- 切名字用的
            name_color = "pink",
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.MiniMapEntity:SetIcon("tbat_building_rough_cut_wood_sofa_sunbloom.tex")
                inst.AnimState:PlayAnimation("idle",true)
                inst.AnimState:SetTime(5*math.random())
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_rough_cut_wood_sofa_sunbloom",
                build = "tbat_building_rough_cut_wood_sofa_sunbloom",
                anim = "idle",
                scale = 0.3,
                offset = Vector3(0, 0, 0),
                fn = function(icon_anim,slot)
                    icon_anim:GetAnimState():OverrideSymbol("slot","tbat_building_rough_cut_wood_sofa_sunbloom","empty")
                end
            },
        },
        ["tbat_wood_sofa_lemon_cookie"] = {                    --- 
            bank = "tbat_building_rough_cut_wood_sofa_lemon_cookie",
            build = "tbat_building_rough_cut_wood_sofa_lemon_cookie",
            atlas = "images/map_icons/tbat_building_rough_cut_wood_sofa_lemon_cookie.xml",
            image = "tbat_building_rough_cut_wood_sofa_lemon_cookie",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.lemon_cookie"),        --- 切名字用的
            name_color = "pink",
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.MiniMapEntity:SetIcon("tbat_building_rough_cut_wood_sofa_lemon_cookie.tex")
                inst.AnimState:PlayAnimation("idle",true)
                inst.AnimState:SetTime(3*math.random())
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_rough_cut_wood_sofa_lemon_cookie",
                build = "tbat_building_rough_cut_wood_sofa_lemon_cookie",
                anim = "idle",
                scale = 0.3,
                offset = Vector3(0, 0, 0),
                fn = function(icon_anim,slot)
                    icon_anim:GetAnimState():OverrideSymbol("slot","tbat_building_rough_cut_wood_sofa_lemon_cookie","empty")
                end
            },
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_building_rough_cut_wood_sofa_2")
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_wood_sofa_magic_broom")
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_wood_sofa_sunbloom")
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_wood_sofa_lemon_cookie")
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- sitting event
    local function player_on_set_event(inst,doer)
        --------------------------------------------------------------------
        --- 动画控制
            inst.AnimState:PlayAnimation(inst.sitting_anim or "idle",true)
        --------------------------------------------------------------------
    end
    local function player_stop_sitting_event(inst,doer)
        --------------------------------------------------------------------
        --- 动画控制
            inst.AnimState:PlayAnimation("idle",true)
        --------------------------------------------------------------------
        --- 玩家坐标重订
            local x,y,z = inst.Transform:GetWorldPosition()
            if x == nil then
                x,y,z = doer.Transform:GetWorldPosition()
            end
            doer.Transform:SetPosition(x,0,z)
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
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")

        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_rough_cut_wood_sofa","tbat_building_rough_cut_wood_sofa")
        -- inst.AnimState:SetBank("tbat_building_rough_cut_wood_sofa")
        -- inst.AnimState:SetBuild("tbat_building_rough_cut_wood_sofa")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:SetDeltaTimeMultiplier(default_anim_speed)
        inst.AnimState:OverrideSymbol("slot","tbat_building_rough_cut_wood_sofa","empty")
        inst:AddTag("tbat_building_rough_cut_wood_sofa")
        inst:AddTag("structure")
        inst.entity:SetPristine()
        --------------------------------------------------------------------
        --- 秋千核心模块
            -- TBAT.MODULES:Swing_Install(inst)
        --------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("inspectable")
            inst:AddComponent("named")
            inst:AddComponent("atbook_sofa")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
        --------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        --------------------------------------------------------------------
        ---
            -- inst:ListenForEvent("player_sit_on",player_on_set_event)
            -- inst:ListenForEvent("player_stop_sitting",player_stop_sitting_event)
                inst:ListenForEvent("ms_playerleft", function(world, player)
                    if inst.passenger == player and inst:HasTag("isusing") then
                        inst:RemoveTag("isusing")
                    end
                end, TheWorld)
        --------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:OverrideSymbol("slot","tbat_building_rough_cut_wood_sofa","empty")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

