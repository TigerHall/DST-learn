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
        --- 
            local bank_build = "tbat_container_emerald_feathered_bird_collection_chest"
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
            local function __get_updated_pos()
                local player_x,player_y= TheSim:GetScreenPos(ThePlayer.Transform:GetWorldPosition()) -- 左下角为原点。
                local building_x,building_y = TheSim:GetScreenPos(inst.Transform:GetWorldPosition())
                local offset_x2,offset_y2 = 0,0
                if player_x > building_x then
                    offset_x2 = -400
                else
                    offset_x2 = 400
                end
                local x,y = screen_w/2  +  offset_x + offset_x2 ,   screen_h/2+offset_y
                return x,y
            end
            local function get_updated_pos()
                local flag,x,y = pcall(__get_updated_pos)
                if flag then
                    return x,y
                else
                    front_root.inst:PushEvent("close")
                    return 0,0
                end
            end
            local x,y = get_updated_pos()
            if hud_x and hud_y then
                x,y = hud_x,hud_y
            end
            new_root.inst:DoPeriodicTask(0.5,function()
                if hud_x and hud_y then
                else
                    x,y = get_updated_pos()
                    new_root:SetPosition(x,y)
                end
            end)
            new_root:SetPosition(x,y)
        --------------------------------------------------------
        --- 清除
            inst.hud_data = inst.hud_data or {}
            for k, v in pairs(inst.hud_data) do
                v:Kill()
            end
            inst.hud_data = {}
            local close_fn = function()
                for k, v in pairs(inst.hud_data) do
                    v:Kill()
                end
                inst.hud_data = {}
            end
            front_root.inst:ListenForEvent("close",close_fn)
            front_root.inst:ListenForEvent("onremove",close_fn,inst)
            front_root.inst:ListenForEvent("entitysleep",close_fn,inst)
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
        --- exp text
            if inst:HasTag("lv2") then

            else
                local exp_text = front_root:AddChild(Text(CODEFONT,80,"EXP:10000/10000",{ 167/255 , 192/255 ,110/255 , 1}))
                exp_text:SetPosition(0,-450,0)
                local function update_exp_text()
                    local exp = inst:GetExp()
                    local max = inst.max_exp or 10000
                    local str = "EXP : "..exp.." / "..max
                    exp_text:SetString(str)                    
                end
                update_exp_text()
                exp_text.inst:ListenForEvent("exp_update",update_exp_text,inst)
                table.insert(inst.hud_data,exp_text)
            end
        --------------------------------------------------------                        
        --- 收集按钮
            local button_collect = front_root:AddChild(AnimButton(bank_build,{
                idle = "button_collect",
                over = "button_collect",
                disabled = "button_collect",
            }))
            button_collect:SetPosition(-380,-30,0)
            button_collect:SetOnClick(function()
                if button_collect.cd then
                    return
                end
                button_collect.cd = button_collect.inst:DoTaskInTime(2,function()
                    button_collect.cd = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"button_collect",nil,inst)
            end)
            table.insert(inst.hud_data,button_collect)
        --------------------------------------------------------                        
        --- 删除 /拆解 按钮
            local button2anim = "button_delete"
            if inst:GetType() == 2 then
                button2anim = "button_deconstruct"
            end
            local button_2 = front_root:AddChild(AnimButton(bank_build,{
                idle = button2anim,
                over = button2anim,
                disabled = button2anim,
            }))
            button_2:SetPosition(380,-120,0)
            button_2:SetOnClick(function()
                if button_2.cd then
                    return
                end
                button_2.cd = button_2.inst:DoTaskInTime(2,function()
                    button_2.cd = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"button_2",nil,inst)
            end)
            table.insert(inst.hud_data,button_2)
        --------------------------------------------------------                        
        --- 点击拖动
            -- local move_btm = front_root:AddChild(AnimButton(bank_build,{
            --     idle = "test",
            --     over = "test",
            --     disabled = "test",
            -- }))
            -- -- move_btm.anim:GetAnimState():PlayAnimation("open")
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
            --     if down then
            --         local ent = TheInput:GetHUDEntityUnderMouse()
            --         if ent == move_btm.anim.inst then
            --             stop_follow()
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