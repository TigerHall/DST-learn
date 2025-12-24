--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    梨花猫猫
    制作：梨花树枝*8 梨花瓣*8
    【完成】检索台词：千树万树梨花开，通通都到我家来。
    【完成】初始一阶段：箱子类型建筑，无限堆叠16*6的容量储物空间。
    【完成】ui底部有两个按键【关闭】【存入】上面猫头附近有一个小猫头形态的按键【整理】
    【完成】【关闭】：点击可以关闭箱子
    【完成】【存入】：点击可以将物品栏与背包里和箱子里相同的物资一键存入（箱子里没有的物资不会被放入）
    【完成】【整理】：一个小猫头形态的按键（画师应该有标注）点击可以一键整理箱子
    月黑之夜的时候给予一个蒲公英猫猫花朵升级
    【完成】升级二阶段：周期性全图范围收集箱内物资
    【完成】注：全图收集在配置里需增加选项（30000码范围收集和全图两种）
    【完成】敲击9下 梨花猫猫才会被拆毁 ，被敲击时不会掉出物资，被拆毁时箱内物资【完成】才会掉落。此建筑无碰撞体积。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_pear_cat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_pear_cat.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_pear_cat_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_pear_cat_slot.xml"),

        Asset("ANIM", "anim/tbat_container_pear_cat_strawberry_jam.zip"),
        Asset("ANIM", "anim/tbat_container_pear_cat_pudding.zip"),

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_pc_strawberry_jam"] = {                    --- 
            bank = "tbat_container_pear_cat_strawberry_jam",
            build = "tbat_container_pear_cat_strawberry_jam",
            atlas = "images/map_icons/tbat_container_pear_cat_strawberry_jam.xml",
            image = "tbat_container_pear_cat_strawberry_jam",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.strawberry_jam"),        --- 切名字用的
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_container_pear_cat_strawberry_jam",
                build = "tbat_container_pear_cat_strawberry_jam",
                anim = "idle_2",
                scale = 0.3,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_container_pear_cat_strawberry_jam.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_container_pear_cat.tex")
            end,
        },
        ["tbat_pc_pudding"] = {                    --- 
            bank = "tbat_container_pear_cat_pudding",
            build = "tbat_container_pear_cat_pudding",
            atlas = "images/map_icons/tbat_container_pear_cat_pudding.xml",
            image = "tbat_container_pear_cat_pudding",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.pudding"),        --- 切名字用的
            name_color = "pink",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_container_pear_cat_pudding",
                build = "tbat_container_pear_cat_pudding",
                anim = "idle_1",
                scale = 0.4,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_container_pear_cat_pudding.tex")
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_container_pear_cat_pudding.tex")
            end,
        },
    }    
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_pc_strawberry_jam")
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_pc_pudding")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 动画特效
    local function create_petal_fx(parent)
        if TheNet:IsDedicated() then
            return
        end
        if not TBAT.CONFIG.PEAR_CAT_PETAL_FX then
            return
        end
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:SetParent(parent.entity)

        inst.AnimState:SetBank("tree_leaf_fx")
        inst.AnimState:SetBuild("tree_leaf_fx_yellow")

        local anim_type = 2

        if anim_type == 1 then
            local layers = {"","2","3","4","5","6","7","13","14"}
            for k, v in pairs(layers) do
                inst.AnimState:OverrideSymbol("fff"..v,"tbat_container_pear_cat","fx_needle")
            end
            inst.AnimState:OverrideSymbol("needle","tbat_container_pear_cat","fx_petail")
            inst.AnimState:PlayAnimation("chop",true)
            inst.AnimState:SetTime(math.random(14)/10)
        else
            local layers = {"","2","3","4","5","6","7","13","14"}
            for k, v in pairs(layers) do
                inst.AnimState:OverrideSymbol("fff"..v,"tbat_container_pear_cat","fx_petail")
            end
            inst.AnimState:OverrideSymbol("needle","tbat_container_pear_cat","fx_needle")
            inst.AnimState:PlayAnimation("fall",true)
            inst.AnimState:SetTime(math.random(20)/10)
        end

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 动画控制器
    local function PlayAnim(inst,name,flag)
        local anim_type = "1"
        if inst.components.tbat_data then
            anim_type = inst.components.tbat_data:Get("type","1")
        end
        inst.AnimState:PlayAnimation(name.."_"..anim_type,flag)
    end
    local function PushAnim(inst,name,flag)
        local anim_type = "1"
        if inst.components.tbat_data then
            anim_type = inst.components.tbat_data:Get("type","1")
        end
        inst.AnimState:PushAnimation(name.."_"..anim_type,flag)
    end
    local function init_anim(inst)
        inst:PlayAnim("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- level up event
    local function level_up_event(inst)
        if inst:HasTag("lv2") then
            return
        end
        if inst.components.container and inst.components.container:IsOpen() then
            inst.components.container:Close()
            inst:PlayAnim("close",false)
            inst.components.tbat_data:Set("type","2")
            inst.AnimState:PushAnimation("grow_1",false)
            inst:PushAnim("idle",true)
        else
            inst.components.tbat_data:Set("type","2")
            inst.AnimState:PlayAnimation("grow_1",false)
            inst:PushAnim("idle",true)
        end
        inst:AddTag("lv2")
        if inst.components.container then
            inst.components.container.canbeopened = false
            inst:DoTaskInTime(2,function()
                inst.components.container.canbeopened = true                
            end)
        end
    end
    local function level_onsave_fn(com)
        if com.inst:HasTag("lv2") then
            com:Set("lv2",true)
        end
    end
    local function level_onload_fn(com)
        if com:Get("lv2") then
            com.inst:AddTag("lv2")
        end
    end
    local function level_up_event_install(inst)
        inst:ListenForEvent("levelup",level_up_event)
        inst.components.tbat_data:AddOnSaveFn(level_onsave_fn)
        inst.components.tbat_data:AddOnLoadFn(level_onload_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- conatiner
    local container_install_fn = require("prefabs/06_tbat_containers/01_02_pear_cat_container")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- logic
    local logic_install_fn = require("prefabs/06_tbat_containers/01_03_pear_cat_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受 和 摧毁
    local item_accept_and_destory_com_install = require("prefabs/06_tbat_containers/01_04_pear_cat_item_accept_destory")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onbuild_event
    local function onbuild_event(inst,_table)
        local builder = _table and _table.builder
        if builder and builder.components.talker then
            builder.components.talker:Say(TBAT:GetString2(this_prefab,"onbuild_talk"))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function building_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        -- MakeObstaclePhysics(inst, 0)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_container_pear_cat.tex")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_container_pear_cat","tbat_container_pear_cat")
        -- inst.AnimState:SetBank("tbat_container_pear_cat")
        -- inst.AnimState:SetBuild("tbat_container_pear_cat")
        inst.AnimState:PlayAnimation("idle_1",true)

        inst:AddTag("structure")
        inst:AddTag("tbat_container_pear_cat")

        inst.entity:SetPristine()
        ---------------------------------------------------
        --- 动画控制器
            inst.PlayAnim = PlayAnim
            inst.PushAnim = PushAnim
        ---------------------------------------------------
        --- 数据
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
        ---------------------------------------------------
        ---
            create_petal_fx(inst)
            container_install_fn(inst)
            logic_install_fn(inst)
            item_accept_and_destory_com_install(inst)
        ---------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ---------------------------------------------------
        --- 皮肤
            inst:AddComponent("tbat_com_skin_data")
        ---------------------------------------------------
        --- 升级
            level_up_event_install(inst)
        ---------------------------------------------------
        --- 动画初始化
            inst:DoTaskInTime(0,init_anim)
        ---------------------------------------------------
        --- 基础模块
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ---------------------------------------------------
        ---
            inst:ListenForEvent("onbuilt",onbuild_event)
            
        ---------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle_1",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

