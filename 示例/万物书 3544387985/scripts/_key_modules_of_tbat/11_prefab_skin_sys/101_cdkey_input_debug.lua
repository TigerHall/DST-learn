-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
    local Menu = require "widgets/menu"
    local TEMPLATES = require "widgets/redux/templates"
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 自己的
    local function create_input_widget()
        ---------------------------------------------------------
        ---
            local front_root = ThePlayer.HUD
        ---------------------------------------------------------
        ---
            local root = front_root:AddChild(Widget())
            root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            root:SetVAnchor(0) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
        ---------------------------------------------------------
        ---
            local cdkey_box = root:AddChild(Widget())

        ---------------------------------------------------------
        ---
            local bg = cdkey_box:AddChild(Image("images/global_redux.xml","textbox3_gold_tiny_normal.tex"))
            local bg_scale = 5
            bg:SetScale(bg_scale,bg_scale)
        ---------------------------------------------------------
        ---
            local close_button = cdkey_box:AddChild(ImageButton(
                "images/global_redux.xml",
                "close.tex",
                "close.tex",
                "close.tex",
                "close.tex",
                "close.tex"
            ))
            close_button:SetPosition(200,180)
            close_button:SetOnClick(function()
                root:Kill()
            end)
        ---------------------------------------------------------
        ---
            local input_box = cdkey_box:AddChild(Image("images/global_redux.xml", "textbox3_gold_hover.tex"))
        ---------------------------------------------------------
        --- text  50, 81,122
            local font_size = 60
            local default_cdkey = "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX"
            local cdkey_input_box_root = cdkey_box:AddChild(TEMPLATES.StandardSingleLineTextEntry(default_cdkey, 650, font_size,CODEFONT,font_size))
            local cdkey_input_box = cdkey_input_box_root.textbox
            cdkey_input_box:SetTextLengthLimit(200)
            cdkey_input_box:SetForceEdit(true)
            cdkey_input_box:EnableWordWrap(false)
            cdkey_input_box:EnableScrollEditWindow(true)
            cdkey_input_box:SetHelpTextEdit("")
            cdkey_input_box:SetHelpTextApply("")
            cdkey_input_box:SetTextPrompt("", UICOLOURS.GREY)
            cdkey_input_box.prompt:SetHAlign(ANCHOR_MIDDLE)
            cdkey_input_box_root.textbox_bg:Hide()
            cdkey_input_box:SetColour({ 50/255 , 81/255 ,122/255 , 1})
            local last_input_flag = false
            cdkey_input_box.inst:DoPeriodicTask(2*FRAMES,function()
                local str = cdkey_input_box:GetLineEditString()
                local current_input_flag = cdkey_input_box.editing
                if current_input_flag then
                    if str == default_cdkey or not last_input_flag then
                        cdkey_input_box:SetString("")
                    end
                else
                    if str == "" then
                        cdkey_input_box:SetString(default_cdkey)
                    end
                end
                last_input_flag = cdkey_input_box.editing
            end)
        ---------------------------------------------------------
        ---
            local apply_button = cdkey_box:AddChild(ImageButton(
                "images/global_redux.xml",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex"
            ))
            apply_button:SetPosition(0,-150)
            apply_button:SetOnClick(function()
                local current_input = cdkey_input_box:GetLineEditString()
                -----------------------------------------------------
                ---
                    if current_input ~= "" and current_input ~= default_cdkey then
                        print("玩家提交了CDKEY:",current_input)
                        print("玩家输入CDKEY长度",string.len(current_input))
                        ThePlayer.replica.tbat_com_rpc_event:PushEvent("tbat_event.cdkey_input",current_input)
                        root:Kill()
                    end
                -----------------------------------------------------
                cdkey_input_box:SetString(default_cdkey)
            end)
        ---------------------------------------------------------
        ---
            return root
        ---------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 所有人的
    local function create_debug_input_widget()
        ---------------------------------------------------------
        ---
            local front_root = ThePlayer.HUD
        ---------------------------------------------------------
        ---
            local root = front_root:AddChild(Widget())
            root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            root:SetVAnchor(0) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
        ---------------------------------------------------------
        ---
            local cdkey_box = root:AddChild(Widget())

        ---------------------------------------------------------
        ---
            local bg = cdkey_box:AddChild(Image("images/global_redux.xml","textbox3_gold_tiny_normal.tex"))
            local bg_scale = 5
            bg:SetScale(bg_scale,bg_scale)
        ---------------------------------------------------------
        ---
            local close_button = cdkey_box:AddChild(ImageButton(
                "images/global_redux.xml",
                "close.tex",
                "close.tex",
                "close.tex",
                "close.tex",
                "close.tex"
            ))
            close_button:SetPosition(200,180)
            close_button:SetOnClick(function()
                root:Kill()
            end)
        ---------------------------------------------------------
        ---
            local userid_input_box_bg = cdkey_box:AddChild(Image("images/global_redux.xml", "textbox3_gold_hover.tex"))
            userid_input_box_bg:SetPosition(0,100)
        ---------------------------------------------------------
        --- text  50, 81,122
            local font_size = 60
            local default_userid = ThePlayer.userid
            local userid_input_box_root = cdkey_box:AddChild(TEMPLATES.StandardSingleLineTextEntry(default_userid, 650, font_size,CODEFONT,font_size))
            userid_input_box_root:SetPosition(0,100)
            local userid_input_box = userid_input_box_root.textbox
            userid_input_box:SetTextLengthLimit(200)
            userid_input_box:SetForceEdit(true)
            userid_input_box:EnableWordWrap(false)
            userid_input_box:EnableScrollEditWindow(true)
            userid_input_box:SetHelpTextEdit("")
            userid_input_box:SetHelpTextApply("")
            userid_input_box:SetTextPrompt("", UICOLOURS.GREY)
            userid_input_box.prompt:SetHAlign(ANCHOR_MIDDLE)
            userid_input_box_root.textbox_bg:Hide()
            userid_input_box:SetColour({ 50/255 , 81/255 ,122/255 , 1})
            local last_input_flag = false
            userid_input_box.inst:DoPeriodicTask(2*FRAMES,function()
                local str = userid_input_box:GetLineEditString()
                local current_input_flag = userid_input_box.editing
                if current_input_flag then
                    if str == default_userid or not last_input_flag then
                        userid_input_box:SetString("")
                    end
                else
                    if str == "" then
                        userid_input_box:SetString(default_userid)
                    end
                end
                last_input_flag = userid_input_box.editing
            end)
        ---------------------------------------------------------
        ---
            local input_box = cdkey_box:AddChild(Image("images/global_redux.xml", "textbox3_gold_hover.tex"))
        ---------------------------------------------------------
        --- text  50, 81,122
            local font_size = 60
            local default_cdkey = "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX"
            local cdkey_input_box_root = cdkey_box:AddChild(TEMPLATES.StandardSingleLineTextEntry(default_cdkey, 650, font_size,CODEFONT,font_size))
            local cdkey_input_box = cdkey_input_box_root.textbox
            cdkey_input_box:SetTextLengthLimit(200)
            cdkey_input_box:SetForceEdit(true)
            cdkey_input_box:EnableWordWrap(false)
            cdkey_input_box:EnableScrollEditWindow(true)
            cdkey_input_box:SetHelpTextEdit("")
            cdkey_input_box:SetHelpTextApply("")
            cdkey_input_box:SetTextPrompt("", UICOLOURS.GREY)
            cdkey_input_box.prompt:SetHAlign(ANCHOR_MIDDLE)
            cdkey_input_box_root.textbox_bg:Hide()
            cdkey_input_box:SetColour({ 50/255 , 81/255 ,122/255 , 1})
            local last_input_flag = false
            cdkey_input_box.inst:DoPeriodicTask(2*FRAMES,function()
                local str = cdkey_input_box:GetLineEditString()
                local current_input_flag = cdkey_input_box.editing
                if current_input_flag then
                    if str == default_cdkey or not last_input_flag then
                        cdkey_input_box:SetString("")
                    end
                else
                    if str == "" then
                        cdkey_input_box:SetString(default_cdkey)
                    end
                end
                last_input_flag = cdkey_input_box.editing
            end)
        ---------------------------------------------------------
        ---
            local apply_button = cdkey_box:AddChild(ImageButton(
                "images/global_redux.xml",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex",
                "button_carny_square_normal.tex"
            ))
            apply_button:SetPosition(0,-150)
            apply_button:SetOnClick(function()
                local current_input_cdkey = cdkey_input_box:GetLineEditString()
                local current_input_userid = userid_input_box:GetLineEditString()
                -----------------------------------------------------
                ---                        
                    ThePlayer.replica.tbat_com_rpc_event:PushEvent("tbat_event.cdkey_input_debug",{
                        userid = current_input_userid,
                        cdkey = current_input_cdkey,
                    })
                -----------------------------------------------------
                cdkey_input_box:SetString(default_cdkey)
                root:Kill()
            end)
        ---------------------------------------------------------
        ---
            return root
        ---------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -- AddPlayerPostInit(function(inst)
    --     if not TheNet:IsDedicated() then
    --        inst:DoTaskInTime(1,function()
    --         if inst.HUD then
    --             function inst.HUD:DebugShowCDKEYInput()
    --                 create_input_widget(inst)
    --             end
    --             function inst.HUD:DebugShowCDKEYInput2()
    --                 create_debug_input_widget(inst)
    --             end
    --         end
    --         inst:ListenForEvent("tbat_event.debug_cdkey_input_window",function(_,index)
    --             if index == 1 then
    --                 inst.HUD:DebugShowCDKEYInput()
    --             else
    --                 inst.HUD:DebugShowCDKEYInput2() 
    --             end
    --         end)
    --        end)
    --     end

    --     if not TheWorld.ismastersim then
    --         return
    --     end

    --     inst:ListenForEvent("tbat_event.talker_say",function(inst,str)
    --         if str == "cdkey" then
    --             TBAT.FNS:RPC_PushEvent(inst,"tbat_event.debug_cdkey_input_window",1)
    --         end
    --         if str == "cdkey2" then
    --             TBAT.FNS:RPC_PushEvent(inst,"tbat_event.debug_cdkey_input_window",2)
    --         end
    --     end)

    -- end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------