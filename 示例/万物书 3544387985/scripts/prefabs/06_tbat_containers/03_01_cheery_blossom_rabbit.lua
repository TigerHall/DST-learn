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
    local this_prefab = "tbat_container_cherry_blossom_rabbit"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_cherry_blossom_rabbit.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_cherry_blossom_rabbit_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_cherry_blossom_rabbit_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_container_cherry_blossom_rabbit_icecream"] = {                    --- 
            bank = "tbat_container_cherry_blossom_rabbit_icecream",
            build = "tbat_container_cherry_blossom_rabbit_icecream",
            atlas = "images/map_icons/tbat_container_cherry_blossom_rabbit_icecream.xml",
            image = "tbat_container_cherry_blossom_rabbit_icecream",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"name"),        --- 切名字用的
            name_color = "pink2",
            unlock_announce_skip = true,
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
            local skin_name_index = "tbat_container_cherry_blossom_rabbit_"..index
            skins_data[skin_name_index] = {                    --- 
                bank = skin_bank_build,
                build = skin_bank_build,
                atlas = "images/map_icons/"..skin_bank_build..".xml",
                image = skin_bank_build,  -- 不需要 .tex
                name = TBAT:GetString2(this_prefab,"name"),        --- 切名字用的
                name_color = "blue",
                unlock_announce_skip = true,
                server_fn = function(inst)
                    inst.MiniMapEntity:SetIcon(skin_bank_build..".tex")
                end,
                server_switch_out_fn = function(inst)
                    inst.MiniMapEntity:SetIcon("tbat_container_cherry_blossom_rabbit_mini.tex")
                end,
            }
        end
    ------------------------------------------------------------------------------------------------------------------------
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_container_cherry_blossom_rabbit_icecream")
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
--- conatiner
    local container_install_fn = require("prefabs/06_tbat_containers/03_02_cheery_container")
    local container_widget_hook = require("prefabs/06_tbat_containers/03_03_container_hud_hook")
    local container_cook_logic_install = require("prefabs/06_tbat_containers/03_04_cook")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁
    local destory_com_install = require("prefabs/06_tbat_containers/02_04_destory_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 接近、远离
    local function onfar(inst)
        inst.AnimState:PlayAnimation("idle_2",true)
    end
    local function onnear(inst)
        inst.AnimState:PlayAnimation("near_2",true)
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
        inst.MiniMapEntity:SetIcon("tbat_container_cherry_blossom_rabbit.tex")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_container_cherry_blossom_rabbit","tbat_container_cherry_blossom_rabbit")
        -- inst.AnimState:SetBank("tbat_container_cherry_blossom_rabbit")
        -- inst.AnimState:SetBuild("tbat_container_cherry_blossom_rabbit")
        inst.AnimState:PlayAnimation("idle_2",true)

        inst:AddTag("structure")
        inst:AddTag("tbat_container_cherry_blossom_rabbit")
        inst:AddTag("waterproofer")

        inst.entity:SetPristine()
        ---------------------------------------------------
        --- 数据
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
        ---------------------------------------------------
        ---
            create_petal_fx(inst)
            container_install_fn(inst)
            container_widget_hook(inst)
            destory_com_install(inst)
            container_cook_logic_install(inst)
        ---------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ---------------------------------------------------
        --- 皮肤
            inst:AddComponent("tbat_com_skin_data")
        ---------------------------------------------------
        --- 基础模块
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ---------------------------------------------------
        --- 防水
            inst:AddComponent("waterproofer")
        ---------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(-0.1)
        ---------------------------------------------------
        --- 接近、远离
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetDist(3,4)
            inst.components.playerprox:SetOnPlayerNear(onnear)
            inst.components.playerprox:SetOnPlayerFar(onfar)
        ---------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets)

