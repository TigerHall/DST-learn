--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_eq_ray_fish_hat"
    local display_hud = true
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器界面HOOK
    local origin_hud_create_fn = require("prefabs/03_tbat_equipments/06_02_02_ray_fish_hat_origin_ui")
    --- 切换成容器界面HOOK入模式
    local function container_widget_open_event(inst,front_root)
        front_root.bganim:Hide()
        -----------------------------------------------------------------
        ---
            -- hud_create(inst,front_root)
            local hud_create_fn = origin_hud_create_fn
            local slot_offset = Vector3(0,7,0)
            local current_skin_data = inst.replica.tbat_com_skin_data:GetCurrentData()
            if current_skin_data then
                if current_skin_data.ui_fn then
                    hud_create_fn = current_skin_data.ui_fn
                end
                if current_skin_data.ui_slot_offset then
                    slot_offset = current_skin_data.ui_slot_offset
                end
            end
            hud_create_fn(inst,front_root)
        -----------------------------------------------------------------
        local slot = front_root.inv[1]
        if slot then
            slot:MoveToFront()
            local temp_layer = front_root:AddChild(Widget())
            temp_layer:AddChild(slot)
            local slot_scale = 0.5
            temp_layer:SetScale(slot_scale,slot_scale,slot_scale)
            temp_layer:SetPosition(slot_offset.x,slot_offset.y,slot_offset.z)
            slot.bgimage:SetTint(1,1,1,0)
        end
        front_root.inst:ListenForEvent("onremove",function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button_clicked",nil,inst)
        end)
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
                    slotpos = {Vector3(0,0,0)},
                    slotbg = {{ image = "turf_slot.tex", atlas = "images/hud2.xml" },},
                    animbank = "ui_chest_1x1",
                    animbuild = "ui_chest_1x1",
                    pos = Vector3(0, 0, 0),
                    -- side_align_tip = 100,
                },
                type = this_prefab or "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return item:HasTag("groundtile") and item.tile
                    -- return true
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
        inst.components.container.canbeopened = false
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ----
            inst:ListenForEvent("TBAT_OnEntityReplicated.container",container_replica_init)
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                inst.components.container.openlimit = 1
                container_Widget_change(inst.components.container)
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
                inst.components.container:EnableInfiniteStackSize(true)
                inst.components.container.canbeopened = false
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
return function(inst)
    add_container_before_not_ismastersim_return(inst)
    if not TheNet:IsDedicated() then
        -- inst:ListenForEvent("open_hud",hud_create)
        inst:ListenForEvent("tbat_event.container_widget_open",container_widget_open_event)

    end
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("button_clicked",function(_,index)
        inst.selected = index
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner then
            TBAT.FNS:RPC_PushEvent(owner,"open_hud_selected",index,inst)
            inst.tile_x = nil
            inst.tile_y = nil
        end
    end)
end