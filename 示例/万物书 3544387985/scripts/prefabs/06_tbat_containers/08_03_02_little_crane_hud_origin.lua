--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
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
---
    local function create_hud(inst,front_root,container_root)
        -------------------------------------------------------------------------------
        ---
            local bank_build = "tbat_container_little_crane_bird"
            local scale = 0.6
        -------------------------------------------------------------------------------
        --- root
            local root = front_root:AddChild(Widget())
            root:SetScale(scale,scale)
            root:SetPosition(0,50,0)
            container_root:SetPosition(0,50,0)
        -------------------------------------------------------------------------------
        --- 背景
            local bg = root:AddChild(UIAnim())
            bg:GetAnimState():SetBank(bank_build)
            bg:GetAnimState():SetBuild(bank_build)
            bg:GetAnimState():PlayAnimation("frame")
        -------------------------------------------------------------------------------
        --- 容器图层顺序调整
            container_root:MoveToFront()
            container_root.bganim:Hide()
            local slot_num = inst.replica.container:GetNumSlots()
            for i = 1,slot_num, 1 do
                local ItemSlot = container_root.inv[i]
                ItemSlot.__old_OnGainFocus = ItemSlot.OnGainFocus
                ItemSlot.OnGainFocus = function(...)
                    ItemSlot:MoveToFront()
                    return ItemSlot.__old_OnGainFocus(...)
                end
            end
        -------------------------------------------------------------------------------
        --- 重新布局slots
            local start_x ,start_y = -245,240
            local delta = 70
            local ret_slot_points = {}
            for y = 1, 8, 1 do
                for x = 1, 8, 1 do
                    table.insert(ret_slot_points,Vector3(start_x + (x-1)*delta,start_y - (y-1)*delta,0))
                end
            end
            for i = 1,slot_num, 1 do 
                local pt = ret_slot_points[i]
                container_root.inv[i]:SetPosition(pt:Get())
            end
        -------------------------------------------------------------------------------
        --- 关闭按钮
            local close_button = root:AddChild(AnimButton(bank_build,{idle = "close_button",over = "close_button",disabled = "close_button"}))
            close_button:SetPosition(310,360)
            close_button:SetOnClick(function()
                front_root.inst:PushEvent("close_widget")
            end)
        -------------------------------------------------------------------------------
        --- 擦除按钮
            local erasa_button = root:AddChild(AnimButton(bank_build,{idle = "erasa_button",over = "erasa_button",disabled = "erasa_button"}))
            erasa_button:SetPosition(-180,-360)
            erasa_button:SetOnClick(function()
                if erasa_button.cd_task then
                    return
                end
                erasa_button.cd_task = erasa_button.inst:DoTaskInTime(0.5,function()
                    erasa_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"erasa_button_clicked",{userid = ThePlayer.userid},inst)
            end)
        -------------------------------------------------------------------------------
        --- 搜索按钮
            local search_button = root:AddChild(AnimButton(bank_build,{idle = "search_button",over = "search_button",disabled = "search_button"}))
            search_button:SetPosition(180,-360)
            search_button:SetOnClick(function()
                if search_button.cd_task then
                    return
                end
                search_button.cd_task = search_button.inst:DoTaskInTime(0.5,function()
                    search_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"search_button_clicked",{userid = ThePlayer.userid},inst)
            end)
        -------------------------------------------------------------------------------
        --- 拖动
            local moving_click_target = bg
            moving_click_target.__old_OnMouseButton = moving_click_target.OnMouseButton
            local MOUSE_RIGHT = 1001
            local MOUSE_LEFT = 1000
            moving_click_target.OnMouseButton = function(self,button, down, x, y)
                if down and button == MOUSE_RIGHT then 
                    if moving_click_target.mouse_handler then
                        moving_click_target.mouse_handler:Remove()
                    end
                    moving_click_target.mouse_handler = TheInput:AddMouseButtonHandler(function(button,down,x,y)
                            if not down and button == MOUSE_RIGHT then
                                moving_click_target.mouse_handler:Remove()
                                moving_click_target.mouse_handler = nil
                                front_root:StopFollowMouse()
                                local mouse_x,mouse_y = TheSim:GetPosition()
                                front_root:SetPosition(mouse_x,mouse_y)
                            end
                    end)
                    front_root:FollowMouse()
                    moving_click_target.inst:ListenForEvent("onremove",function()
                        if moving_click_target.mouse_handler then
                            moving_click_target.mouse_handler:Remove()
                        end
                    end)
                end
                return self.__old_OnMouseButton(self,button, down, x, y)
            end
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    return function(inst,front_root,container_root)
        create_hud(inst,front_root,container_root)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------