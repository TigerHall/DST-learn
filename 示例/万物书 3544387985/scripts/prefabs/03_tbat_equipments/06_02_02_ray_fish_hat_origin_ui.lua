--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 界面控件
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
--- 前置准备函数
    local current_offset_x = nil
    local current_offset_y = nil
    local function get_current_offset()
        if current_offset_x and current_offset_y then
            return current_offset_x, current_offset_y
        end
        local offset_data = TBAT.ClientSideData:PlayerGet("ray_fish_hat_ui",{x = 450,y = 165})
        current_offset_x, current_offset_y = offset_data.x, offset_data.y
        return offset_data.x, offset_data.y
    end
    local function set_current_offset(x,y)
        TBAT.ClientSideData:PlayerSet("ray_fish_hat_ui",{x = x,y = y})
        current_offset_x, current_offset_y = x, y
    end
    local MOUSE_RIGHT = 1001
    local MOUSE_LEFT = 1000
    local MOUSE_MOVING_FLAG = false
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 界面生成逻辑函数
    local function hud_create(inst,container_widget_root)
        ---------------------------------------------------------
        --- 准备
            inst.selected = nil
            if inst.hud and inst.hud.inst:IsValid() then
                inst.hud:Kill()
            end
        ---------------------------------------------------------
        --- front_root
            -- local front_root = ThePlayer.HUD:AddChild(Widget())
            local front_root = container_widget_root
            front_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            -- front_root:SetPosition(1000,500)
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            inst.hud = front_root
        ---------------------------------------------------------
        ---
        ---------------------------------------------------------
        --- root
            local root = front_root:AddChild(Widget())
            root.inst:DoPeriodicTask(0.3,function()
                local hat = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if hat ~= inst then
                    front_root:Kill()
                end
            end)
            root:Hide()
            -- root:SetPosition(0,200,0)
        ---------------------------------------------------------
        --- update
            TBAT:AddInputUpdateFn(front_root.inst,function()
                -- local x,y = TheSim:GetScreenPos(ThePlayer.Transform:GetWorldPosition())
                local x,y = get_current_offset()
                if MOUSE_MOVING_FLAG then
                    x,y = TheSim:GetPosition()                
                end
                root:Show()
                front_root:SetPosition(x,y)
            end)
        ---------------------------------------------------------
        --- box
            local box = root:AddChild(Widget())
            local scale = 0.5
            box:SetScale(scale,scale)
        ---------------------------------------------------------
        --- 
            local ui_bank_build = "tbat_eq_ray_fish_hat_ui"
        ---------------------------------------------------------
        --- 图标
            local icon = box:AddChild(UIAnim())
            icon:GetAnimState():SetBank(ui_bank_build)
            icon:GetAnimState():SetBuild(ui_bank_build)
            icon:GetAnimState():PlayAnimation("icon",true)
            icon:SetPosition(0,0,0)
            icon.__OnMouseButton_old = icon.OnMouseButton
            icon.OnMouseButton = function(self,button,down,x,y,...)
                if button == MOUSE_RIGHT then
                    --- 右键拖动
                    if down then
                        MOUSE_MOVING_FLAG = true
                        icon.inst:PushEvent("mouse_moving_down")
                    else
                        MOUSE_MOVING_FLAG = false
                        set_current_offset(TheSim:GetPosition())
                    end
                end
                if button == MOUSE_LEFT and down then
                    TBAT.FNS:RPC_PushEvent(ThePlayer,"button_clicked",nil,inst)
                    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                end
                return self.__OnMouseButton_old(self,button,down,x,y,...)
            end
            icon.inst:ListenForEvent("mouse_moving_down",function()
                if icon.mouse_handler then
                    icon.mouse_handler:Remove()
                end
                icon.mouse_handler = TheInput:AddMouseButtonHandler(function(button,down,x,y)
                    -- print(button,down,x,y)
                    if not down and button == MOUSE_RIGHT then
                        icon.mouse_handler:Remove()
                        icon.mouse_handler = nil
                        MOUSE_MOVING_FLAG = false
                        set_current_offset(TheSim:GetPosition())
                    end
                end)
            end)
        ---------------------------------------------------------
        --- 四个位置数据      
            local start_x = 320      
            local delta_x = 100
            local delta_y = 0
            local buttons_data = {
                [1] = {
                    pt = Vector3(start_x-1.5*delta_x,delta_y,0),
                    anim = "land",
                },
                [2] = {
                    pt = Vector3(start_x-0.5*delta_x,delta_y,0),
                    anim = "shallow",
                },
                [3] = {
                    pt = Vector3(start_x+0.5*delta_x,delta_y,0),
                    anim = "middle",
                },
                [4] = {
                    pt = Vector3(start_x+1.5*delta_x,delta_y,0),
                    anim = "deep",
                },
            }
        ---------------------------------------------------------
        --- 四个按钮、外框
            local button_selected = {}
            local buttons = {}
            for index, data in pairs(buttons_data) do
                ------------------------------------------------------------------------------
                --- 选择框
                    local temp_selected = box:AddChild(UIAnim())
                    temp_selected:GetAnimState():SetBank(ui_bank_build)
                    temp_selected:GetAnimState():SetBuild(ui_bank_build)
                    temp_selected:GetAnimState():PlayAnimation("bubble_selected")
                    temp_selected:SetPosition(data.pt.x,data.pt.y,data.pt.z)
                    button_selected[index] = temp_selected
                    temp_selected:Hide()

                    local temp_text = temp_selected:AddChild(UIAnim())
                    temp_text:GetAnimState():SetBank(ui_bank_build)
                    temp_text:GetAnimState():SetBuild(ui_bank_build)
                    temp_text:GetAnimState():PlayAnimation(data.anim.."_selected")
                ------------------------------------------------------------------------------
                --- 按钮
                    local test_button = box:AddChild(AnimButton("tbat_eq_ray_fish_hat_ui",{
                        idle = "bubble",
                        over = "bubble",
                        disabled = "bubble",
                    }))
                    buttons[index] = test_button
                    test_button:SetPosition(data.pt.x,data.pt.y,data.pt.z)
                    test_button:SetOnClick(function()
                        TBAT.FNS:RPC_PushEvent(ThePlayer,"button_clicked", index~=0 and index or nil,inst)
                    end)
                    if index == 0 then
                        test_button:SetScale(0.7,0.7)
                    end
                ------------------------------------------------------------------------------
                ---
                    local txt_anim = test_button.anim:AddChild(UIAnim())
                    txt_anim:GetAnimState():SetBank(ui_bank_build)
                    txt_anim:GetAnimState():SetBuild(ui_bank_build)
                    txt_anim:GetAnimState():PlayAnimation(data.anim)
                    txt_anim:SetPosition(0,0)
                ------------------------------------------------------------------------------
            end
        ---------------------------------------------------------
        --- 指示器
            local function create_indecator()
                local fx = SpawnPrefab("tbat_sfx_tile_outline")
                fx:PushEvent("Set",{})
                local color = {255/255,255/255,0/255}
                fx.AnimState:SetAddColour(color[1],color[2],color[3], 0)
                fx.AnimState:SetMultColour(color[1],color[2],color[3], 1)
                fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                fx.AnimState:SetFinalOffset(1)
                fx.AnimState:SetSortOrder(1)
                front_root.inst:ListenForEvent("onremove",function()
                fx:Remove() 
                end)
                return fx
            end
            local fx = create_indecator()
            local fx_offsets = {
                [1] = Vector3(-4,0,0),
                [2] = Vector3(4,0,0),
                [3] = Vector3(0,0,4),
                [4] = Vector3(0,0,-4),
            }
            for k, offset in pairs(fx_offsets) do
                local temp = create_indecator()
                fx:AddChild(temp)
                temp.Transform:SetPosition(offset.x,offset.y,offset.z)
            end
        ---------------------------------------------------------
        --- 显示选择框、指示器update
            front_root.inst:DoPeriodicTask(FRAMES,function()
                local selected = inst.selected
                for k, temp_frame in pairs(button_selected) do
                    if k == selected then
                        button_selected[k]:Show()
                        buttons[k]:Hide()
                    else
                        button_selected[k]:Hide()
                        buttons[k]:Show()
                    end
                end
                fx.Transform:SetPosition(TBAT.MAP:GetTileCenterPoint(ThePlayer.Transform:GetWorldPosition()))
            end)
        ---------------------------------------------------------
        --- 监听服务器来的事件
            front_root.inst:ListenForEvent("open_hud_selected",function(_,index)
                inst.selected = index
            end,inst)
        ---------------------------------------------------------
        --- display_hud
            local function display_switch()
                if display_hud then
                    front_root:Show()
                    fx:Show()
                else
                    front_root:Hide()
                    fx:Hide()
                end 
            end
            display_switch()
            front_root.inst:ListenForEvent("display_hud_switch",function()
                display_hud = not display_hud
                display_switch()
            end,inst)
        ---------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return hud_create