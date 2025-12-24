--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    安装界面给 宠物

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    -- local function creat_hud(inst)
    --     if TBAT._____test_hud then
    --         TBAT._____test_hud(inst)
    --     end
    -- end
    local creat_hud = function(inst)
        -----------------------------------------------------------------------
        ---
            if inst.__hud and inst.__hud.inst:IsValid() then
                return
            end
        -----------------------------------------------------------------------
        ---
            local bank_build = "tbat_pet_lavender_kitty_ui"
        -----------------------------------------------------------------------
        --- 创建前置根节点
            local front_root = ThePlayer.HUD.controls:AddChild(Widget())
            front_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            -- front_root:SetPosition(1000,500)
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            inst.__hud = front_root
            front_root.inst:ListenForEvent("force_kill",function()
                front_root:Kill()
                inst.__hud = nil
            end)
            front_root:MoveToBack()
            inst:ListenForEvent("onremove",function()
                front_root.inst:PushEvent("force_kill")
            end)
        -----------------------------------------------------------------------
        --- 创建根节点
            local root = front_root:AddChild(Widget())
            local scale = 0.5
            root:SetScale(scale,scale)
        -----------------------------------------------------------------------
        --- 坐标
            local button_pt = Vector3(110,20,0)
        -----------------------------------------------------------------------
        --- 开启按钮
            local button_open = root:AddChild(AnimButton(bank_build,{
                idle = "open",over = "open",disabled = "open",
            }))
            button_open:SetPosition(button_pt.x,button_pt.y,button_pt.z)
            button_open:SetOnClick(function()
                if button_open.cd_task then
                    return
                end
                button_open.cd_task = button_open.inst:DoTaskInTime(0.5,function()
                    button_open.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"open_button_clicked",{
                    userid = ThePlayer.userid,
                },inst)
                button_open:Hide()
            end)
            button_open:Hide()
        -----------------------------------------------------------------------
        --- 关闭按钮
            local button_close = root:AddChild(AnimButton(bank_build,{
                idle = "close",over = "close",disabled = "close",
            }))
            button_close:SetPosition(button_pt.x,button_pt.y,button_pt.z)
            button_close:SetOnClick(function()
                if button_close.cd_task then
                    return
                end
                button_close.cd_task = button_close.inst:DoTaskInTime(0.5,function()
                    button_close.cd_task = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"close_button_clicked",{
                    userid = ThePlayer.userid,
                },inst)
                button_close:Hide()
            end)
            button_close:Hide()
        -----------------------------------------------------------------------
        --- icon
            local icon = root:AddChild(UIAnim())
            local icon_AnimState = icon:GetAnimState()
            icon_AnimState:SetBank("kitcoon")
            icon_AnimState:SetBuild("tbat_pet_lavender_kitty")
            icon_AnimState:PlayAnimation("idle_loop",true)
            -- icon_AnimState:SetDeltaTimeMultiplier(0.7)
            icon:SetFacing(FACING_DOWNRIGHT)
            local icon_scale = 0.8
            icon:SetScale(icon_scale,icon_scale,icon_scale)
        -----------------------------------------------------------------------
        --- 指示器 193,163,213
            local indicator = ThePlayer:SpawnChild("tbat_sfx_dotted_circle_client")
            indicator:PushEvent("Set",{
                radius = 10
            })
            local color = {153/255, 51/255, 255/255}
            indicator.AnimState:SetAddColour(color[1], color[2], color[3], 0)
            indicator.AnimState:SetMultColour(color[1], color[2], color[3], 1)
            indicator.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            indicator:Hide()
            front_root.inst:ListenForEvent("onremove",function()
                indicator:Remove()
            end)
        -----------------------------------------------------------------------
        --- update
            TBAT:AddInputUpdateFn(inst,function()
                -----------------------------------------------------
                --- 检查
                    if not inst:IsValid() then
                        front_root.inst:PushEvent("force_kill")
                        return
                    end
                    if inst._client_following_player ~= ThePlayer then
                        front_root.inst:PushEvent("force_kill")
                        return
                    end
                    if ThePlayer:HasTag("playerghost") then
                        front_root:Hide()
                        return
                    end
                -----------------------------------------------------
                --- 坐标跟随
                    -- local x,y = TheSim:GetScreenPos(inst.Transform:GetWorldPosition()) 
                    -- front_root:SetPosition(x,y + 120)
                -----------------------------------------------------
                ---
                    if inst:HasTag("item_searching") then
                        button_open:Hide()
                        button_close:Show()
                        indicator:Show()
                    else
                        button_open:Show()
                        button_close:Hide()
                        indicator:Hide()
                    end
                -----------------------------------------------------                        
            end)
        -----------------------------------------------------------------------
        --- 坐标储存、读取
            local save_data_sheet = "tbat_pet_lavender_kitty_ui"
            local save_pos = function(x,y)
                local screen_w,screen_h = TheSim:GetScreenSize()
                local x_precent = x/screen_w
                local y_precent = y/screen_h
                TBAT.FreeClientSideData:Set(save_data_sheet,"pt",{
                    x = x_precent,
                    y = y_precent,
                })
                -- print("saved pos:",x_precent,y_precent)
            end
            local read_pos = function()
                local default = {
                    x = 0.46,
                    y = 0.65,
                }
                local pt = TBAT.FreeClientSideData:Get(save_data_sheet,"pt") or default
                local screen_w,screen_h = TheSim:GetScreenSize()
                return pt.x * screen_w,pt.y * screen_h
            end
            front_root:SetPosition(read_pos())
        -----------------------------------------------------------------------
        --- 拖动
            local moving_click_target = icon
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
                                -- local screen_w,screen_h = TheSim:GetScreenSize()
                                save_pos(mouse_x,mouse_y)
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
        -----------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    -------------------------------------------------------------------------------------------------------
    --- 用来下发绑定的玩家
        inst.__net_following_target = net_entity(inst.GUID, "__net_following_target","net_following_target_updated")
        inst:ListenForEvent("net_following_target_updated",function(inst)
            local temp = inst.__net_following_target:value()
            if temp == inst then
                return
            end
            if temp and temp:IsValid() and temp:HasTag("player") and temp == ThePlayer then
                inst._client_following_player = temp
                creat_hud(inst)
            else
                inst._client_following_player = nil
            end
        end)
    -------------------------------------------------------------------------------------------------------
    --- ismastersim
        if not TheWorld.ismastersim then
            return
        end
    -------------------------------------------------------------------------------------------------------
    --- 周期性检查并下发命令
        inst:DoPeriodicTask(1,function()
            local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
            if following_player == nil then
                inst.__net_following_target:set(nil)
                return
            end
            if inst.__net_following_target:value() == inst then
                inst.__net_following_target:set(following_player)
            else
                inst.__net_following_target:set(inst)
            end
        end)
    -------------------------------------------------------------------------------------------------------
end