--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    翠羽鸟收集箱
    配方：翠羽鸟的羽毛*1 水母祈愿牌*1
    【完成】检索台词：乘着风为你衔来万物
    【完成】设定内容：一个可以全图捡垃圾的6*6格箱子建筑。（如同桌面清理大师的功能，可以全图把掉落的物资捡回来
    【完成】箱子拥有两个按键，收集和删除。每删除一个物品累计一点经验值，满1万点【完成】经验值升级二阶段。升级后，删除将变为拆解
    【完成】收集：全图拾取世界的掉落物
    【完成】删除：一键删除箱子内有的所有东西
    【完成】拆解：一键分解箱子内所有东西，拆解的物品会掉落在地上
    【完成】（注：拆解功能可以在设置里禁用）
    【完成】敲击9下 翠羽鸟收集箱才会被拆毁 ，被敲击时不会掉出物资，被拆毁时箱内物资才会掉落。此建筑无碰撞体积。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_emerald_feathered_bird_collection_chest"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_emerald_feathered_bird_collection_chest.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_emerald_feathered_bird_collection_chest_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_emerald_feathered_bird_collection_chest_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 动画特效
    local function create_eyes_fx(parent)
        if TheNet:IsDedicated() then
            return
        end
        parent.AnimState:OverrideSymbol("eye","tbat_container_emerald_feathered_bird_collection_chest","empty")
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("tbat_container_emerald_feathered_bird_collection_chest")
        inst.AnimState:SetBuild("tbat_container_emerald_feathered_bird_collection_chest")
        inst.AnimState:PlayAnimation("eye",true)
        inst.AnimState:SetTime(1.5*math.random())
        inst.AnimState:SetDeltaTimeMultiplier(0.5)
        inst.entity:SetParent(parent.entity)
        inst.entity:AddFollower()
        inst.Follower:FollowSymbol(parent.GUID, "eye",  0, 0, 0,true)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    local container_install_fn = require("prefabs/06_tbat_containers/04_02_container_install")
    local container_hud_hook_fn = require("prefabs/06_tbat_containers/04_03_container_hud_hook")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁
    local destory_com_install = require("prefabs/06_tbat_containers/02_04_destory_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主要逻辑
    local main_logic_install = require("prefabs/06_tbat_containers/04_04_main_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onbuild
    local function OnBuilt(inst,builder)
        if builder and builder.components.talker then
            builder.components.talker:Say(TBAT:GetString2(this_prefab,"onbuild_talk"))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- exp
    local function SetExp(inst,exp)
        if TheWorld.ismastersim then
            inst.__exp:set(exp)
        end
    end
    local function GetExp(inst)
        return inst.__exp:value()
    end
    local function ExpDelta(inst,value)
        local current = inst:GetExp()
        local ret = math.max(0,current+value)
        inst:SetExp(ret)
        inst:PushEvent("exp_changed",{
            new = ret,
            old = current,
        })
    end
    local function ExpOnSave(com)
        com:Set("exp",com.inst:GetExp())
    end
    local function ExpOnLoad(com)
        local exp = com:Get("exp",0)
        com.inst:SetExp(exp)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- type
    local ALLOW_DECONSTRUC = TBAT.CONFIG.EFBCC_ALLOW_DECONSTRUCT
    local function GetType(inst)
        if inst:HasTag("lv2") and ALLOW_DECONSTRUC then
            return 2
        end
        return 1
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
        inst.MiniMapEntity:SetIcon("tbat_container_emerald_feathered_bird_collection_chest.tex")

        inst:SetDeploySmartRadius(0.5)

        inst.AnimState:SetBank("tbat_container_emerald_feathered_bird_collection_chest")
        inst.AnimState:SetBuild("tbat_container_emerald_feathered_bird_collection_chest")
        inst.AnimState:PlayAnimation("idle",true)

        inst:AddTag("structure")
        inst:AddTag("tbat_container_emerald_feathered_bird_collection_chest")

        ------------------------------------------------------------
        --- exp net
            inst.__exp = net_uint(inst.GUID, "exp","exp_update")
            inst.__exp:set(0)
            inst.SetExp = SetExp
            inst.GetExp = GetExp
            inst.ExpDelta = ExpDelta
            inst.max_exp = 10000
        ------------------------------------------------------------
            inst.GetType = GetType        
        ------------------------------------------------------------

        inst.entity:SetPristine()
        ------------------------------------------------------------
        ---
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
        ------------------------------------------------------------
        --- exp save
            if TheWorld.ismastersim then
                inst.components.tbat_data:AddOnSaveFn(ExpOnSave)
                inst.components.tbat_data:AddOnLoadFn(ExpOnLoad)
            end
        ------------------------------------------------------------
        ---
            container_install_fn(inst)
            container_hud_hook_fn(inst)
            create_eyes_fx(inst)
            destory_com_install(inst)
            main_logic_install(inst)
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
            inst.OnBuilt = OnBuilt
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
        create_eyes_fx(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

