--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_item_crystal_bubble_box"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面调试
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_crystal_bubble.zip"),
    }
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
                    slotbg = {
                        { image = "tbat_item_crystal_bubble_slot.tex", atlas = "images/widgets/tbat_item_crystal_bubble_slot.xml" }
                    },
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
                    return true
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
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- container hud hook
    local function container_widget_open_event(inst,front_root)
        -------------------------------------------------------------------
            -- if TBAT.___test_deubg_widget then
            --     TBAT.___test_deubg_widget(inst,front_root)
            --     return
            -- end
        -------------------------------------------------------------------
        ---
            front_root.bganim:Hide()
        -------------------------------------------------------------------
        ---
            local bank_build = "tbat_item_crystal_bubble"
        -------------------------------------------------------------------
        ---
            local bubble = front_root:AddChild(UIAnim())
            local bubble_anim = bubble:GetAnimState()
            bubble_anim:SetBank(bank_build)
            bubble_anim:SetBuild(bank_build)
            bubble_anim:PlayAnimation("box",true)
            bubble_anim:OverrideSymbol("slot",bank_build,"empty")
            bubble_anim:HideSymbol("shadow")
            local scale = 0.5
            bubble:SetScale(scale,scale,scale)
            bubble:SetClickable(false)
            bubble:SetPosition(0,-135,0)
        -------------------------------------------------------------------
        ---
            local new_slot_layer = front_root:AddChild(Widget())
            local slot = front_root.inv[1]
            new_slot_layer:AddChild(slot)
            local slot_scale = 1.5
            new_slot_layer:SetScale(slot_scale,slot_scale,slot_scale)
        -------------------------------------------------------------------
        ---
        -------------------------------------------------------------------
        ---
            bubble:MoveToFront()
        -------------------------------------------------------------------
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
            item_fx.Follower:FollowSymbol(inst.GUID, "slot",0,-20,0,true)
            inst.item_fx = item_fx
        end
    end
    local function on_close_event(inst)
        display_item(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- destroy com
--- 参数
    local MAX_HIT_NUM = 1
    local function onhammered(inst, worker)
        if inst.components.container then
            inst.components.container:Close()
            inst.components.container:DropEverything()
        end
        inst.components.lootdropper:SpawnLootPrefab("tbat_item_crystal_bubble")
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
        -- inst.entity:AddMiniMapEntity()
        -- inst.MiniMapEntity:SetIcon("tbat_item_crystal_bubble.tex")
        inst.AnimState:SetBank("tbat_item_crystal_bubble")
        inst.AnimState:SetBuild("tbat_item_crystal_bubble")
        inst.AnimState:PlayAnimation("box",true)
        inst.AnimState:OverrideSymbol("slot","tbat_item_crystal_bubble","empty")
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
        ---
            inst:ListenForEvent("tbat_event.container_widget_open",container_widget_open_event)
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
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)