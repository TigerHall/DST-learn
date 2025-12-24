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
    local Menu = require "widgets/menu"
    local TEMPLATES = require "widgets/redux/templates"
    local ScrollableList = require "widgets/scrollablelist"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function create_hud(inst)
        -------------------------------------------------------------------
        --- 前置根节点
            local temp_root = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls
            if temp_root == nil then
                return
            end
            local front_root = temp_root:AddChild(Widget())
            front_root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(0) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            front_root.inst:ListenForEvent("onremove",function()
                front_root:Kill()
            end,inst)
            front_root.inst:DoPeriodicTask(0.5,function()
                if inst and inst:IsValid() and ThePlayer
                    and inst.replica.inventoryitem
                    and inst.replica.inventoryitem:IsGrandOwner(ThePlayer) then
                        
                else
                    front_root:Kill()
                end
            end)
            SetAutopaused(true)
            front_root.inst:ListenForEvent("onremove",function()
                SetAutopaused(false)            
            end)
        -------------------------------------------------------------------
        --- 根节点
            local root = front_root:AddChild(Widget())
            local scale = 0.45
            root:SetScale(scale, scale, scale)
            root:SetPosition(0, 50, 0)
            local atlas = "images/widgets/tbat_ui_notes_of_adventurer.xml"
        -------------------------------------------------------------------
        --- bg
            local bg = root:AddChild(Image(atlas,"background.tex"))
        -------------------------------------------------------------------
        --- button_close
            local button_close = root:AddChild(ImageButton(atlas,"button_close.tex","button_close.tex","button_close.tex","button_close.tex","button_close.tex"))
            button_close:SetPosition(600,520,0)
            button_close:SetOnClick(function()
                front_root:Kill()
            end)
        -------------------------------------------------------------------
        --- 内容
            local index = inst.index
            local data = TBAT.MODULES:GetNotesOfAdventurerUI(index)
            if type(data) == "table" then
                local info_atlas,info_image = data.atlas,data.image
                local info_build,info_bank,info_anim = data.build,data.bank,data.anim
                local scale = data.scale or 1
                local x,y = data.x or 0,data.y or 0
                if info_atlas and info_image then
                    local info = root:AddChild(Image(info_atlas,info_image))
                    info:SetScale(scale,scale,scale)
                    info:SetPosition(x,y,0)
                elseif info_build and info_bank and info_anim then
                    local info = root:AddChild(UIAnim())
                    info:GetAnimState():SetBuild(info_build)
                    info:GetAnimState():SetBank(info_bank)
                    info:GetAnimState():PlayAnimation(info_anim)
                    info:SetScale(scale,scale,scale)
                    info:SetPosition(x,y,0)
                end
            end
        -------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    inst:ListenForEvent("open_hud",create_hud)
end