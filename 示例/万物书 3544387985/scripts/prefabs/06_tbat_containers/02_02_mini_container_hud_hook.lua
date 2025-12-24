--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面 hook
    
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local hud_x,hud_y = nil,nil
    local function hud_hook_fn(inst,front_root)
        --------------------------------------------------------
        --- 新建根节点
            local new_root = front_root.parent:AddChild(Widget())
            new_root:AddChild(front_root)
            new_root.inst:DoPeriodicTask(0.5,function()
                if not front_root.inst:IsValid() then
                    new_root:Kill()
                end
            end)
        --------------------------------------------------------
        --- 重置缩放
            new_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            new_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            new_root:SetScaleMode(TBAT.PARAM.CONTAINER_HOOKED_HUD_SCALE_MODE)   --- 缩放模式
            local scale = 0.4
            front_root:SetScale(scale,scale)

            local screen_w,screen_h = TheSim:GetScreenSize()                
            local offset_x,offset_y = 0,100
            local x,y = screen_w/2+offset_x,screen_h/2+offset_y
            if hud_x and hud_y then
                x,y = hud_x,hud_y
            end
            new_root:SetPosition(x,y)
        --------------------------------------------------------
        --- 清除
            inst.hud_data = inst.hud_data or {}
            for k, v in pairs(inst.hud_data) do
                v:Kill()
            end
            inst.hud_data = {}
            front_root.inst:ListenForEvent("close",function()
                for k, v in pairs(inst.hud_data) do
                    v:Kill()
                end
                inst.hud_data = {}
            end)
        --------------------------------------------------------
        --- 关闭事件。让按钮 在关闭的瞬间 清除。
            local tempAnimState = TBAT.FNS:Hook_Inst_AnimState(front_root.bganim.inst)
            tempAnimState.old_PlayAnimation = tempAnimState.PlayAnimation
            tempAnimState.PlayAnimation = function(self,anim,flag)
                if anim == "close" then
                    front_root.inst:PushEvent("close")
                end
                self.old_PlayAnimation(self,anim,flag)
            end                
        --------------------------------------------------------                        
        --- close button
            local close_button = front_root:AddChild(AnimButton("tbat_container_cherry_blossom_rabbit",{
                idle = "button_close",
                over = "button_close",
                disabled = "button_close",
            }))
            close_button:SetPosition(170,-280,0)
            close_button:SetOnClick(function()
                front_root:Hide()
                TBAT.FNS:RPC_PushEvent(ThePlayer,"close_contianer",nil,inst)
            end)
            local button_scale = 0.6
            close_button:SetScale(button_scale,button_scale)
            table.insert(inst.hud_data,close_button)
        --------------------------------------------------------                        
        --- 点击拖动
            -- local move_btm = front_root:AddChild(AnimButton("tbat_container_cherry_blossom_rabbit",{
            --     idle = "window_mini",
            --     over = "window_mini",
            --     disabled = "window_mini",
            -- }))
            -- move_btm.anim:GetAnimState():OverrideSymbol("window_big","tbat_container_cherry_blossom_rabbit","frame")
            -- -- move_btm:SetPosition(0.9,0.9,0)
            -- move_btm:MoveToBack()
            -- move_btm:SetClickable(true)
            -- move_btm:SetOnClick(function()end)
            -- move_btm.clickoffset = Vector3(0,0,0)
            -- table.insert(inst.hud_data, move_btm)
            -- -----
            -- local start_pt = Vector3(0,0,0)
            -- local start_window_pt = Vector3(0,0,0)
            -- local function start_follow()
            --     start_pt = TheInput:GetScreenPosition()
            --     start_window_pt = new_root:GetPosition()
            --     if move_btm.inst.__task then
            --         move_btm.inst.__task:Cancel()
            --     end
            --     move_btm.inst.__task = move_btm.inst:DoPeriodicTask(FRAMES,function()
            --         local current_pt = TheInput:GetScreenPosition()
            --         local offset = current_pt - start_pt
            --         -- print(offset)
            --         local new_window_pt = start_window_pt + offset
            --         new_root:SetPosition(new_window_pt.x,new_window_pt.y)
            --     end)
            -- end
            -- local function stop_follow()
            --     if move_btm.inst.__task then
            --         move_btm.inst.__task:Cancel()
            --         move_btm.inst.__task = nil
            --     end
            --     local new_pt = new_root:GetPosition()
            --     hud_x,hud_y = new_pt.x,new_pt.y
            -- end
            -- local mouse_handler = TheInput:AddMouseButtonHandler(function(button, down, x, y)
            --     if down and button == MOUSEBUTTON_RIGHT then
            --         local ent = TheInput:GetHUDEntityUnderMouse()
            --         if ent == move_btm.anim.inst then
            --             start_follow()
            --         end
            --     else
            --         stop_follow()
            --     end
            -- end)
            -- front_root.inst:ListenForEvent("onremove", function()
            --     mouse_handler:Remove()
            -- end)
        --------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function widget_open(inst,front_root)
        -- if TBAT.DEBUGGING and TBAT.hud_hook_fn then
        --     TBAT.hud_hook_fn(inst,front_root)
        --     return
        -- end
        hud_hook_fn(inst,front_root)
    end
    local function hud_update_event_install(inst)
        inst:ListenForEvent("tbat_event.container_widget_open",widget_open)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function container_close_event(inst)
        inst.components.container:Close()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    hud_update_event_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("close_contianer", container_close_event)
end