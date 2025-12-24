--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    小小鹤草箱

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_little_crane_bird"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_little_crane_bird.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_little_crane_bird.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_little_crane_bird_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_little_crane_bird_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语图标
    TBAT.FNS:AddChatIconData(this_prefab,{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_little_crane_bird",
            build = "tbat_chat_icon_little_crane_bird",
            anim = "idle",
            time = 3,
        },  
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    local container_install_fn = require("prefabs/06_tbat_containers/08_02_little_crane_container_install")
    local container_hud_hook_fn = require("prefabs/06_tbat_containers/08_03_01_little_crane_hud_hooker")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 功能函数
    local main_logic_fn = require("prefabs/06_tbat_containers/08_04_little_crane_main_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Whisper
    local function WhisperTo(inst,player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = "tbat_container_little_crane_bird" ,
            sender_name = TBAT:GetString2("tbat_container_little_crane_bird","name"),
            s_colour = {178/255,188/255,85/255},
            message = str,
            m_colour = {254/255,249/255,231/255},
        })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_container_little_crane_bird.tex")
        inst.AnimState:SetBank("tbat_container_little_crane_bird")
        inst.AnimState:SetBuild("tbat_container_little_crane_bird")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:SetTime(5*math.random())
        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")
        inst:AddTag(this_prefab)
        inst.entity:SetPristine()
        ------------------------------------------------------------
        --- 模块安装
            container_install_fn(inst)
            container_hud_hook_fn(inst)
            inst.WhisperTo = WhisperTo
        ------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------
        --- 常用组件
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------
        --- 
            main_logic_fn(inst)
        ------------------------------------------------------------
        --- 摧毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,9)
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:Pause()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

