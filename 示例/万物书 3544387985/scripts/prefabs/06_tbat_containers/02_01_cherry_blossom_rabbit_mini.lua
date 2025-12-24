--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    樱花兔兔
    制作：樱花原木*8 樱花瓣*8
    【完成】检索台词：哼，我可是春末的旅行者～！
    【完成】一阶段：制作出来后是可以随身携带5*5的返鲜储物道具，无限堆叠，可以右键放置到地面上。月圆之夜的时候给予放置在地上的樱花兔兔一个{蒲公英猫猫花朵}可以升级为二阶段
    【完成】二阶段：升级到二阶段的樱花兔兔不能再被拿起，变为16*6的储物空间，无限堆叠，返鲜且能全图收集空间内有的材料
    【完成】ui底部有两个按键【关闭】【存入】上面耳朵有一个樱花形态的按键【整理】
    【完成】【关闭】：点击可以关闭箱子
    【完成】【存入】：点击可以将物品栏与背包里和箱子里相同的物资一键存入（箱子里没有的物资不会被放入）
    【完成】【整理】：一个樱花形态的按键（画师应该有标注）点击可以一键整理箱子
    【完成】注：全图收集在配置里需增加选项（100码范围收集和全图两种）
    【完成】敲击9下 樱花兔兔才会被拆毁 ，被敲击时不会掉出物资，被拆毁时箱内物资才会掉落。此建筑无碰撞体积。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_cherry_blossom_rabbit_mini"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_cherry_blossom_rabbit_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_cherry_blossom_rabbit_slot.xml"),

        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_icecream.zip"),

        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_colourful_feather.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_dream_blue.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_flower_bud.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_lemon_yellow.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_moon_white.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_orange.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_pink_strawberry.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_purple_wind.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_skyblue.zip"),
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit_labubu_white_cherry.zip"),

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["cb_rabbit_mini_icecream"] = {                    --- 
            bank = "tbat_container_cherry_blossom_rabbit_icecream",
            build = "tbat_container_cherry_blossom_rabbit_icecream",
            atlas = "images/map_icons/tbat_container_cherry_blossom_rabbit_icecream.xml",
            image = "tbat_container_cherry_blossom_rabbit_icecream",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.icecream"),        --- 切名字用的
            name_color = "pink2",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_container_cherry_blossom_rabbit_icecream",
                build = "tbat_container_cherry_blossom_rabbit_icecream",
                anim = "idle_1",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            },
            skin_link = "tbat_container_cherry_blossom_rabbit_icecream"
        },
    }
    ------------------------------------------------------------------------------------------------------------------------
    --- 拉布布 系列
        local labubu_data = {
            ["labubu_colourful_feather"]   =     "拉布布 : 彩羽",
            ["labubu_skyblue"]             =     "拉布布 : 碧蓝",
            ["labubu_pink_strawberry"]     =     "拉布布 : 粉莓",
            ["labubu_flower_bud"]          =     "拉布布 : 花苞",
            ["labubu_orange"]              =     "拉布布 : 橘暖",
            ["labubu_white_cherry"]        =     "拉布布 : 棉樱",
            ["labubu_lemon_yellow"]        =     "拉布布 : 柠光",
            ["labubu_dream_blue"]          =     "拉布布 : 蔚梦",
            ["labubu_moon_white"]          =     "拉布布 : 月白",
            ["labubu_purple_wind"]         =     "拉布布 : 紫岚",
        }
        for index, _ in pairs(labubu_data) do
            local skin_bank_build = "tbat_container_cherry_blossom_rabbit_"..index
            local skin_name_index = "cbr_mini_"..index
            skins_data[skin_name_index] = {                    --- 
                bank = skin_bank_build,
                build = skin_bank_build,
                atlas = "images/map_icons/"..skin_bank_build..".xml",
                image = skin_bank_build,  -- 不需要 .tex
                name = TBAT:GetString2(this_prefab,"skin."..index),        --- 切名字用的
                name_color = "blue",
                unlock_announce_data = { -- 解锁提示
                    bank = skin_bank_build,
                    build = skin_bank_build,
                    anim = "idle_1",
                    scale = 0.3,
                    offset = Vector3(0, 0, 0)
                },
                skin_link = "tbat_container_cherry_blossom_rabbit_"..index,
                server_fn = function(inst)
                    inst.MiniMapEntity:SetIcon(skin_bank_build..".tex")
                end,
                server_switch_out_fn = function(inst)
                    inst.MiniMapEntity:SetIcon("tbat_container_cherry_blossom_rabbit_mini.tex")
                end,
            }
            TBAT.SKIN.SKIN_PACK:Pack("pack_labubu_mystery_box",skin_name_index)
        end
    ------------------------------------------------------------------------------------------------------------------------
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","cb_rabbit_mini_icecream")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 动画特效
    local function create_petal_fx(parent)
        if TheNet:IsDedicated() then
            return
        end
        if not TBAT.CONFIG.CHERRY_BLOSSOM_RABBIT_PETAL_FX then
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
                inst.AnimState:OverrideSymbol("fff"..v,"tbat_container_cherry_blossom_rabbit","fx_needle")
            end
            inst.AnimState:OverrideSymbol("needle","tbat_container_cherry_blossom_rabbit","fx_petail")
            inst.AnimState:PlayAnimation("chop",true)
            inst.AnimState:SetTime(math.random(14)/10)
        else
            local layers = {"","2","3","4","5","6","7","13","14"}
            for k, v in pairs(layers) do
                inst.AnimState:OverrideSymbol("fff"..v,"tbat_container_cherry_blossom_rabbit","fx_petail")
            end
            inst.AnimState:OverrideSymbol("needle","tbat_container_cherry_blossom_rabbit","fx_needle")
            inst.AnimState:PlayAnimation("fall",true)
            inst.AnimState:SetTime(math.random(20)/10)
        end

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    local container_install_fn = require("prefabs/06_tbat_containers/02_01_mini_container")
    local container_hud_hook_fn = require("prefabs/06_tbat_containers/02_02_mini_container_hud_hook")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 可交互
    local workable_com_install = require("prefabs/06_tbat_containers/02_03_mini_workable_install")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁
    local destory_com_install = require("prefabs/06_tbat_containers/02_04_destory_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 升级
    local level_up_logic_install = require("prefabs/06_tbat_containers/02_05_rabbit_level_up_com")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 接近、远离
    local function onfar(inst)
        inst.AnimState:PlayAnimation("idle_1",true)
    end
    local function onnear(inst)
        inst.AnimState:PlayAnimation("near_1",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onbuild、deploy
    local function OnBuilt(inst,builder)
        if builder and builder.components.talker then
            builder.components.talker:Say(TBAT:GetString2(this_prefab,"onbuild_talk"))
        end
    end
    local function on_deploy(inst, pt, deployer)
        deployer.components.inventory:DropItem(inst)
        deployer.components.inventory:DropActiveItem()
        inst.Transform:SetPosition(pt.x,1,pt.z)
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
        inst.MiniMapEntity:SetIcon("tbat_container_cherry_blossom_rabbit_mini.tex")

        MakeInventoryPhysics(inst)

        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_container_cherry_blossom_rabbit","tbat_container_cherry_blossom_rabbit")
        -- inst.AnimState:SetBank("tbat_container_cherry_blossom_rabbit")
        -- inst.AnimState:SetBuild("tbat_container_cherry_blossom_rabbit")
        inst.AnimState:PlayAnimation("idle_1",true)

        inst:AddTag("waterproofer")
        inst:AddTag("usedeploystring")


        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})


        inst.entity:SetPristine()
        ------------------------------------------------------------
        ---
            container_install_fn(inst)
            container_hud_hook_fn(inst)
            workable_com_install(inst)
            create_petal_fx(inst)
            destory_com_install(inst)
            level_up_logic_install(inst)
        ------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end

        ------------------------------------------------------------
        --- 皮肤
            inst:AddComponent("tbat_com_skin_data")
        ------------------------------------------------------------
        --- 接近、远离
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetDist(3,4)
            inst.components.playerprox:SetOnPlayerNear(onnear)
            inst.components.playerprox:SetOnPlayerFar(onfar)
        ------------------------------------------------------------
        --- 防水
            inst:AddComponent("waterproofer")
        ------------------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(-0.1)
        ------------------------------------------------------------
        --- 常用组件
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_container_cherry_blossom_rabbit_mini","images/map_icons/tbat_container_cherry_blossom_rabbit_mini.xml")
            -- inst.components.inventoryitem.cangoincontainer = false
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------
        --- 部署
            inst:AddComponent("deployable")
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable.ondeploy = on_deploy
        ------------------------------------------------------------
        ---
            inst.OnBuilt = OnBuilt
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle_1",true)
        create_petal_fx(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    MakePlacer(this_prefab.."_placer","tbat_container_cherry_blossom_rabbit","tbat_container_cherry_blossom_rabbit", "idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

