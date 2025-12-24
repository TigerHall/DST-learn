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
            local bank_build = "tbat_container_lavender_kitty"
            local scale = 0.6
        -------------------------------------------------------------------------------
        --- root
            local root = front_root:AddChild(Widget())
            root:SetScale(scale,scale)
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
            local start_x ,start_y = -68,65
            local delta = 70
            local ret_slot_points = {}
            for y = 1, 3, 1 do
                for x = 1, 3, 1 do
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
            close_button:SetPosition(98,160)
            close_button:SetOnClick(function()
                front_root.inst:PushEvent("close_widget")
            end)
        -------------------------------------------------------------------------------
        --- info 用来显示当前状态
            local info_pt = Vector3(0,0,0)
            local info_bubble = root:AddChild(UIAnim())
            local info_bubble_ANIMSTATE = info_bubble:GetAnimState()
            info_bubble_ANIMSTATE:SetBank(bank_build)
            info_bubble_ANIMSTATE:SetBuild(bank_build)
            info_bubble_ANIMSTATE:PlayAnimation("info_bubble_auto",true)
            info_bubble_ANIMSTATE:PlayAnimation("info_bubble_manual",true)
            local info_update_fn = function()
                if inst:HasTag("auto") and not info_bubble_ANIMSTATE:IsCurrentAnimation("info_bubble_auto") then
                    info_bubble_ANIMSTATE:PlayAnimation("info_bubble_auto",true)
                elseif not inst:HasTag("auto") and not info_bubble_ANIMSTATE:IsCurrentAnimation("info_bubble_manual") then
                    info_bubble_ANIMSTATE:PlayAnimation("info_bubble_manual",true)
                end                
            end
            info_update_fn()
            root.inst:DoPeriodicTask(0.1,info_update_fn)
        -------------------------------------------------------------------------------
        --- swtich_button
            local switch_button_pt = Vector3(0,-165,0)
            local switch_auto_button = root:AddChild(AnimButton(bank_build,{idle = "switch_auto_button",over = "switch_auto_button",disabled = "switch_auto_button"}))
            switch_auto_button:SetPosition(switch_button_pt:Get())
            switch_auto_button:SetOnClick(function()
                if switch_auto_button.cd_task then
                    return
                end
                switch_auto_button.cd_task = switch_auto_button.inst:DoTaskInTime(0.5,function()
                    switch_auto_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"switch_auto_button_clicked",{
                    auto = false
                },inst)
            end)
            switch_auto_button:Hide()
            local switch_manual_button = root:AddChild(AnimButton(bank_build,{idle = "switch_manual_button",over = "switch_manual_button",disabled = "switch_manual_button"}))
            switch_manual_button:SetPosition(switch_button_pt:Get())
            switch_manual_button:SetOnClick(function()
                if switch_manual_button.cd_task then
                    return
                end
                switch_manual_button.cd_task = switch_manual_button.inst:DoTaskInTime(0.5,function()
                    switch_manual_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"switch_auto_button_clicked",{
                    auto = true
                },inst)
            end)
            switch_manual_button:Hide()
            local switch_auto_button_update_fn = function()
                if inst:HasTag("auto") then
                    switch_auto_button:Show()
                    switch_manual_button:Hide()
                else
                    switch_auto_button:Hide()
                    switch_manual_button:Show()
                end
            end
            switch_auto_button_update_fn()
            switch_auto_button.inst:DoPeriodicTask(0.1,switch_auto_button_update_fn)
        -------------------------------------------------------------------------------
        --- 种植按钮
            local do_plant_button = root:AddChild(AnimButton(bank_build,{idle = "do_plant_button",over = "do_plant_button",disabled = "do_plant_button"}))
            do_plant_button:SetPosition(-105,-160,0)
            do_plant_button:SetOnClick(function()
                if do_plant_button.cd_task then
                    return
                end
                do_plant_button.cd_task = do_plant_button.inst:DoTaskInTime(0.5,function()
                    do_plant_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"do_plant_button_clicked",{
                    userid = ThePlayer.userid,
                },inst)
            end)
        -------------------------------------------------------------------------------
        --- 采收按钮
            local do_pick_button = root:AddChild(AnimButton(bank_build,{idle = "do_pick_button",over = "do_pick_button",disabled = "do_pick_button"}))
            do_pick_button:SetPosition(105,-160,0)
            do_pick_button:SetOnClick(function()
                if do_pick_button.cd_task then
                    return
                end
                do_pick_button.cd_task = do_pick_button.inst:DoTaskInTime(0.5,function()
                    do_pick_button.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"do_pick_button_clicked",{
                    userid = ThePlayer.userid,
                },inst)
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
                                front_root.inst:PushEvent("save_moved_pt",Vector3(mouse_x,mouse_y,0))
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
        --- 储存拖动坐标
            local saved_data_sheet_name = "tbat_container_lavender_kitty_ui"
            local pt = TBAT.FreeClientSideData:Get(saved_data_sheet_name,"ui_pt")
            if pt then
                front_root:SetPosition(pt.x,pt.y)
            end
            front_root.inst:ListenForEvent("save_moved_pt",function(inst,pt)
                TBAT.FreeClientSideData:Set(saved_data_sheet_name,"ui_pt",{x = pt.x,y = pt.y})
            end)
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    return function(inst,front_root,container_root)
        create_hud(inst,front_root,container_root)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------