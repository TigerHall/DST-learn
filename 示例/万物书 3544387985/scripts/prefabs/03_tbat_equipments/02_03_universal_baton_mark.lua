--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_universal_baton_mark"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =    {
        Asset("ANIM", "anim/tbat_eq_universal_baton_mark.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local hud_create = function(inst)
    -----------------------------------------------
    ---
        if inst.staff == nil then
            inst:Remove()
            return
        end
    -----------------------------------------------
    --- 
        if inst.hud and inst.hud.inst:IsValid() then
            inst.hud:Kill()
        end
    -----------------------------------------------
    --- 前置根节点
        local front_root = ThePlayer.HUD:AddChild(Widget())
        inst.hud = front_root
        front_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
        front_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
        front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
        front_root.inst:ListenForEvent("onremove",function()
            front_root:Kill()
        end,inst)
        front_root:MoveToBack()
    -----------------------------------------------
    --- 跟随
        local location_update = function()

            if inst.target then
                inst.Transform:SetPosition(inst.target.Transform:GetWorldPosition())
            end

            local s_pt_x,s_pt_y = TheSim:GetScreenPos(inst.Transform:GetWorldPosition()) -- 左下角为原点。
            front_root:SetPosition(s_pt_x,s_pt_y)
            if inst:GetDistanceSqToInst(ThePlayer) > 144 then
                front_root:Kill()
                inst:Remove()
            end
            local weapon = ThePlayer.replica.combat:GetWeapon()
            if weapon and weapon.prefab == "tbat_eq_universal_baton" then
                ---- 
            else
                front_root:Kill()
                inst:Remove()
            end
        end
        location_update()
        TBAT:AddInputUpdateFn(front_root.inst,location_update)
    -----------------------------------------------
    --- 根节点
        local root = front_root:AddChild(Widget())
        local scale = 0.4
        root:SetScale(scale,scale,scale)
    -----------------------------------------------
    --- 
        local bank_build = "tbat_eq_universal_baton_mark"
        local box = root:AddChild(Widget())
        box:SetPosition(0,-70)
    -----------------------------------------------
    --- close button
        local close_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        close_button:SetPosition(0,0,0)
        close_button:SetOnClick(function()
            front_root:Kill()
            inst:Remove()
        end)
        local icon = close_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("close")
        close_button:SetScale(0.6,0.6)
    -----------------------------------------------
    --- rotation button
        local rotation_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        rotation_button:SetPosition(-245,-100,0)
        rotation_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "rotation",
            },inst.staff)
        end)
        local icon = rotation_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("rotate")
    -----------------------------------------------
    --- mirror button
        local mirror_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        mirror_button:SetPosition(-150,-50,0)
        mirror_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "mirror",
            },inst.staff)
        end)
        local icon = mirror_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("mirror")
    -----------------------------------------------
    --- big button
        local big_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        big_button:SetPosition(-55,-100,0)
        big_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "big",
            },inst.staff)
        end)
        local icon = big_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("big")
    -----------------------------------------------
    --- small button
        local small_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        small_button:SetPosition(55,-100,0)
        small_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "small",
            },inst.staff)
        end)
        local icon = small_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("small")
    -----------------------------------------------
    --- skin button
        local skin_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        skin_button:SetPosition(150,-50,0)
        skin_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "skin",
            },inst.staff)
        end)
        local icon = skin_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("skin")
    -----------------------------------------------
    --- reset button
        local reset_button = box:AddChild(AnimButton(bank_build,{
            idle = "pink",over = "white",disabled = "pink"
        }))
        reset_button:SetPosition(245,-100,0)
        reset_button:SetOnClick(function()
            TBAT.FNS:RPC_PushEvent(ThePlayer,"button",{
                type = "reset",
            },inst.staff)
        end)
        local icon = reset_button.anim:AddChild(UIAnim())
        icon:GetAnimState():SetBank(bank_build)
        icon:GetAnimState():SetBuild(bank_build)
        icon:GetAnimState():PlayAnimation("origin")
    -----------------------------------------------
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function hud_create_event(inst,staff)
        inst.staff = staff
        inst.ready = true
        hud_create(inst)
    end
    local function init(inst)
        if not inst.ready then
            inst:Remove()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        -- inst.AnimState:SetBank("cane")
        -- inst.AnimState:SetBuild("swap_cane")
        -- inst.AnimState:PlayAnimation("idle")
        inst:AddTag("tbat_eq_universal_baton_mark")
        if TheNet:IsDedicated() then
            return inst
        end
        inst:ListenForEvent("hud_create",hud_create_event)
        inst:DoTaskInTime(0,init)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
