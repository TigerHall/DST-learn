--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    用来控制 界面 切换


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
    local function widget_open(inst,origin_root)
        --------------------------------------------------------------------
        --- 替换原本的root
            local front_root = origin_root.parent:AddChild(Widget())
            front_root:AddChild(origin_root)
            front_root.inst:DoPeriodicTask(0.1,function()
                if not origin_root.inst:IsValid() then
                    front_root:Kill()
                end
            end)
        --------------------------------------------------------------------
        --- 
            front_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            front_root:SetScaleMode(TBAT.PARAM.CONTAINER_HOOKED_HUD_SCALE_MODE)   --- 缩放模式
            local screen_w,screen_h = TheSim:GetScreenSize()
            front_root:SetPosition(screen_w/2,screen_h/2)
        --------------------------------------------------------------------
        --- hook 进官方UI
            local fn = require("prefabs/06_tbat_containers/08_03_02_little_crane_hud_origin")
            fn(inst,front_root,origin_root)
        --------------------------------------------------------------------
        ---
            front_root.inst:ListenForEvent("close_widget",function()
                front_root:Hide()
                TBAT.FNS:RPC_PushEvent(ThePlayer,"close_widget",{
                    userid = ThePlayer.userid,
                },inst)
            end)
            origin_root.__old_Close = origin_root.Close
            origin_root.Close = function(self)
                front_root:Hide()
                return self:__old_Close()
            end
        --------------------------------------------------------------------
    end
    local function hud_update_event_install(inst)
        inst:ListenForEvent("tbat_event.container_widget_open",widget_open)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    return function(inst)
        hud_update_event_install(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("close_widget",function(_,data)
            local userid = data.userid
            local player_inst = LookupPlayerInstByUserID(userid)
            inst.components.container:Close(player_inst)
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------