--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_plum_blossom_hearth"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_plum_blossom_hearth.zip"),
        Asset("ANIM", "anim/tbat_building_plum_blossom_hearth_abysshell_stand.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_pbh_abysshell_stand"] = {                    --- 
            bank = "tbat_building_plum_blossom_hearth_abysshell_stand",
            build = "tbat_building_plum_blossom_hearth_abysshell_stand",
            atlas = "images/map_icons/tbat_building_plum_blossom_hearth_abysshell_stand.xml",
            image = "tbat_building_plum_blossom_hearth_abysshell_stand",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.abysshell_stand"),        --- 切名字用的
            name_color = "purple",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_plum_blossom_hearth_abysshell_stand",
                build = "tbat_building_plum_blossom_hearth_abysshell_stand",
                anim = "test",
                scale = 0.4,
                offset = Vector3(0, 0, 0)
            },
            server_fn = function(inst)
                inst.MiniMapEntity:SetIcon("tbat_building_plum_blossom_hearth_abysshell_stand.tex")
                inst.AnimState:SetTime(4*math.random())
            end,
            server_switch_out_fn = function(inst)
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                inst.AnimState:SetTime(4*math.random())
            end,
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_plum_blossom_hearth_abysshell_stand")
                inst.AnimState:SetBuild("tbat_building_plum_blossom_hearth_abysshell_stand")
                inst.AnimState:PlayAnimation("test",true)
            end,
            no_flame = true,    --- 禁用火苗
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_floating_dreams_and_fantasies","tbat_pbh_abysshell_stand")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 只能放烹饪出来的东西
    local cooking = require("cooking")
    local function is_cooked_product(prefab)
        for cookpot, data in pairs(cooking.recipes) do
            for product, _ in pairs(data) do
                if product == prefab then
                    return true
                end
            end
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = this_prefab
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        local params = all_container_widgets.params
        if params[container_widget_name] == nil then
            params[container_widget_name] = {
                widget =
                {
                    slotpos = {
                        Vector3(-2, 18, 0),
                    },
                    slotbg = {},
                    animbank = "ui_chest_1x1",
                    animbuild = "ui_chest_1x1",
                    pos = Vector3(0, 160, 0),
                    side_align_tip = 100,
                },
                type = "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return is_cooked_product(item.prefab)
                end
            ------------------------------------------------------------------------------------------
        end
    -----------------------------------------------------------------------------------
    local function container_Widget_change(theContainer)       
        theContainer:WidgetSetup(container_widget_name)
        ------------------------------------------------------------------------
        --- 声音关闭
        -- if theContainer.SetSkipOpenSnd then
        --     theContainer:SetSkipOpenSnd(true)   ---- 打开时候的声音
        --     theContainer:SetSkipCloseSnd(true)  ---- 关闭时候的声音
        -- end
        ------------------------------------------------------------------------
    end
    local function container_replica_init(inst,replica_com)
        container_Widget_change(replica_com)        
    end    
    local function on_open(inst,_table)
    end
    local function on_close(inst,_table)
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ----
            inst:ListenForEvent("TBAT_OnEntityReplicated.container",container_replica_init)
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                inst.components.container.openlimit = 10  ---- 限制10个人打开
                container_Widget_change(inst.components.container)
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
                inst.components.container:EnableInfiniteStackSize(true)
            end
        -------------------------------------------------------------------------------------------------
        ------ 添加背包container组件    --- 必须在 SetPristine 之后，
            -- if TheWorld.ismastersim then
            --     inst:AddComponent("container")
            --     inst.components.container.openlimit = 10  ---- 限制10个人打开
            --     container_Widget_change(inst.components.container)    
            -- else
            --     inst.OnEntityReplicated = function(inst)
            --         container_Widget_change(inst.replica.container)
            --     end
            -- end
        -------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品显示
    local function display_item(inst)
        local item = inst.components.container:GetItemInSlot(1)
        if inst.item_fx then
            inst.item_fx:Remove()
            inst.item_fx = nil
        end
        if item then
            local item_fx = TBAT.FNS:BlankStateClone(item,{"INLIMBO","NOCLICK","NOBLOCK","FX","fx"})
            item_fx.entity:SetParent(inst.entity)
            item_fx.entity:AddFollower()
            item_fx.Follower:FollowSymbol(inst.GUID, "slot",0,40,0,true)
            inst.item_fx = item_fx
        end
        ------------------------------------------------------------------------------------------------------
        --- 火焰和灯光
            local need_2_create_flame_and_light = true
            if inst.flame_fx then
                inst.flame_fx:Remove()
                inst.flame_fx = nil
                inst.light_fx:Remove()
                inst.light_fx = nil
            end
            local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
            if current_skin_data and current_skin_data.no_flame then
                need_2_create_flame_and_light = false
            end
            if item and need_2_create_flame_and_light then
                local fx = inst:SpawnChild("tbat_sfx_flame")
                fx.entity:AddFollower()
                fx.Follower:FollowSymbol(inst.GUID, "flame_slot",0,10,0)
                local scale = 0.15
                fx.AnimState:SetScale(scale,scale,scale)
                inst.flame_fx = fx
                local light_fx = inst:SpawnChild("minerhatlight")
                inst.light_fx = light_fx
                light_fx.Light:SetRadius(0.7)
                light_fx.Light:SetFalloff(0.8)
            end
        ------------------------------------------------------------------------------------------------------
    end
    local function on_close_event(inst)
        display_item(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- destroy com
--- 参数
    local MAX_HIT_NUM = 9
    local function onhammered(inst, worker)
        inst.components.lootdropper:DropLoot()
        if inst.components.container then
            inst.components.container:DropEverything()
        end
        local fx = SpawnPrefab("collapse_big")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        inst:Remove()
    end
    local function onhit(inst, worker)
        inst.components.container:Close()
    end
    local old_WorkedByFn = nil
    local new_workedbyfn = function(self,worker, numworks,...)
        if worker and worker:HasTag("player") then
            old_WorkedByFn(self,worker, numworks,...)
        end
    end
    local function destory_com_install(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(MAX_HIT_NUM)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)
        old_WorkedByFn = old_WorkedByFn or inst.components.workable.WorkedBy
        inst.components.workable.WorkedBy = new_workedbyfn
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
        inst.MiniMapEntity:SetIcon("tbat_building_plum_blossom_hearth.tex")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_plum_blossom_hearth","tbat_building_plum_blossom_hearth")
        -- inst.AnimState:SetBank("tbat_building_plum_blossom_hearth")
        -- inst.AnimState:SetBuild("tbat_building_plum_blossom_hearth")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:OverrideSymbol("slot","tbat_building_plum_blossom_hearth","empty")
        inst.AnimState:OverrideSymbol("flame_slot","tbat_building_plum_blossom_hearth","empty")
        inst.AnimState:SetTime(4*math.random())
        inst:AddTag("structure")
        inst.entity:SetPristine()
        ---------------------------------------------------
        --- 容器
            add_container_before_not_ismastersim_return(inst)
        ---------------------------------------------------
        --- 摧毁
            destory_com_install(inst)
        ---------------------------------------------------
        --- 常规
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ---------------------------------------------------
        --- 显示
            inst:ListenForEvent("onclose",on_close_event)
            inst:DoTaskInTime(0,display_item)
        ---------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            -- inst.components.preserver:SetPerishRateMultiplier(-0.1)
            inst.components.preserver:SetPerishRateMultiplier(0)
        ---------------------------------------------------
        --- 皮肤+名称
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
            inst:ListenForEvent("tbat_com_skin_data.skin_change",display_item)
        ---------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "test", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

