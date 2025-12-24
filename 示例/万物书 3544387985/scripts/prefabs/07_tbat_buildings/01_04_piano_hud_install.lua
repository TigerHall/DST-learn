--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 界面创建
    local function hud_open(inst)
        ------------------------------------------------------------------
        ---
            if inst.hud and inst.hud.inst:IsValid() then
                inst.hud:Kill()
            end
        ------------------------------------------------------------------
        --- 前置根节点
            local front_root = ThePlayer.HUD:AddChild(Widget())
            front_root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(0) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            inst.hud = front_root
        ------------------------------------------------------------------
        --- 检查、关闭
            front_root.inst:ListenForEvent("close",function()
                front_root:Kill()
                inst.hud = nil
            end)
            front_root.inst:ListenForEvent("onremove",function()
                front_root.inst:PushEvent("close")
            end,inst)
            front_root.inst:DoPeriodicTask(0.3,function()
                if inst:GetDistanceSqToInst(ThePlayer) > 5.5 then
                    front_root.inst:PushEvent("close")
                end
            end)
        ------------------------------------------------------------------
        --- 偏移
            local function refresh_hud_location()
                local player_x,player_y= TheSim:GetScreenPos(ThePlayer.Transform:GetWorldPosition()) -- 左下角为原点。
                local building_x,building_y = TheSim:GetScreenPos(inst.Transform:GetWorldPosition())
                local offset_x,offset_y = 0,0
                if player_x > building_x then
                    offset_x = -300
                else
                    offset_x = 300
                end
                front_root:SetPosition(offset_x,offset_y)
            end
            refresh_hud_location()
            front_root.inst:DoPeriodicTask(0.3,refresh_hud_location)
        ------------------------------------------------------------------
        ---
            local atlas = "images/widgets/tbat_container_cherry_blossom_rabbit_hud.xml"
        ------------------------------------------------------------------
        ---
            local root = front_root:AddChild(Widget())
            local scale = 0.4
            root:SetScale(scale, scale)
        ------------------------------------------------------------------
        ---
            local bg = root:AddChild(Image(atlas, "bg.tex"))
        ------------------------------------------------------------------
        ---
            local close_button = root:AddChild(ImageButton(atlas,"button_close.tex","button_close.tex","button_close.tex","button_close.tex","button_close.tex"))
            close_button:SetPosition(250,650,0)
            close_button:SetOnClick(function()
                front_root.inst:PushEvent("close")
            end)
        ------------------------------------------------------------------
        ---
            local points = {}
            local start_x,start_y = -40,350
            local delta_y = -100
            for i = 1, 9, 1 do
                table.insert(points,Vector3(start_x,start_y+(i-1)*delta_y,0))
            end
        ------------------------------------------------------------------
        -- --- 调试按钮
        --     for i = 1, 9, 1 do
        --         local test_button = root:AddChild(ImageButton(atlas,"button_normal.tex","button_normal.tex","button_normal.tex","button_normal.tex","button_normal.tex"))
        --         local pt = points[i]
        --         test_button:SetPosition(pt.x,pt.y,pt.z)
        --         test_button.clickoffset = Vector3(3,0,0)
        --         test_button.focus_scale = {1.05, 1.05, 1.05}
        --     end
        ------------------------------------------------------------------
        ---
            local type_data = require("prefabs/07_tbat_buildings/01_03_piano_type_data")
            local index = 1
            for prefab, data in pairs(type_data) do
                ---------------------------------------------------------
                --- 基础按钮
                    local test_button = root:AddChild(ImageButton(atlas,"button_normal.tex","button_normal.tex","button_normal.tex","button_normal.tex","button_normal.tex"))
                    local pt = points[index]
                    test_button:SetPosition(pt.x,pt.y,pt.z)
                    test_button.clickoffset = Vector3(3,0,0)
                    test_button.focus_scale = {1.05, 1.05, 1.05}
                    index = index + 1
                ---------------------------------------------------------
                --- 按钮内容
                    local text_atlas = data.atlas
                    local text_img = prefab..".tex"
                    local text = test_button.image:AddChild(Image(text_atlas,text_img))
                    local update_text_fn = function()
                        if not inst:HasTag(prefab.."_unlocked") then
                            text:SetTint(1,1,1,0.3)
                        else
                            text:SetTint(1,1,1,1)
                        end
                    end
                    update_text_fn()
                    text.inst:DoPeriodicTask(0.5,update_text_fn)
                ---------------------------------------------------------
                ---
                    test_button:SetOnClick(function()
                        if not inst:HasTag(prefab) then
                            TBAT.FNS:RPC_PushEvent(ThePlayer,"type_swtich",{
                                prefab = prefab,
                                userid = ThePlayer.userid,
                            },inst)
                        else
                            front_root.inst:PushEvent("close")
                        end
                    end)
                ---------------------------------------------------------
                --- 当前的类型为深色
                    if inst:HasTag(prefab) then
                        test_button:SetTextures(atlas,"button_deep.tex","button_deep.tex","button_deep.tex","button_deep.tex","button_deep.tex")
                    end
                ---------------------------------------------------------
            end
        ------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local function hud_open_event(inst)
        -- if TBAT.test_hud then
        --     TBAT.test_hud(inst)
        --     return
        -- end
        hud_open(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("open_hud",hud_open_event)
    end
end

