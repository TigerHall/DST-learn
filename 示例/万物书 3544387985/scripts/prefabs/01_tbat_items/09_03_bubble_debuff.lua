------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面调试
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 计时器
    local BUFF_TIME = 4*60
    local function InitTime(inst)
        if inst.components.tbat_data:Get("time") == nil then
            inst.components.tbat_data:Set("time",BUFF_TIME)
            inst.__time:set(BUFF_TIME)
        end
    end
    local function AddTime(inst,value)
        local time = inst.components.tbat_data:Add("time",-1)
        inst.__time:set(time)
        -- print("time",time)
        return time
    end
    local function ResetTime(inst)
        inst.components.tbat_data:Set("time",BUFF_TIME)
        inst.__time:set(BUFF_TIME)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 水上行走
    local function turn_on_ocean_walk(owner)
        if owner.components.drownable and owner.components.drownable.enabled ~= false then
            owner.components.drownable.enabled = false
        end
        owner.Physics:ClearCollisionMask()
        owner.Physics:CollidesWith(COLLISION.GROUND)
        owner.Physics:CollidesWith(COLLISION.OBSTACLES)
        owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        owner.Physics:CollidesWith(COLLISION.CHARACTERS)
        owner.Physics:CollidesWith(COLLISION.GIANTS)
        owner.Physics:Teleport(owner.Transform:GetWorldPosition())
    end
    local function turn_off_ocean_walk(owner)
        if owner.components.drownable then
            owner.components.drownable.enabled = true
        end
        owner.Physics:ClearCollisionMask()
        owner.Physics:CollidesWith(COLLISION.WORLD)
        owner.Physics:CollidesWith(COLLISION.OBSTACLES)
        owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        owner.Physics:CollidesWith(COLLISION.CHARACTERS)
        owner.Physics:CollidesWith(COLLISION.GIANTS)
        owner.Physics:Teleport(owner.Transform:GetWorldPosition())
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function timer_hud_open(inst)
        -----------------------------------------------------------
        ---
            local time = inst.__time:value()
            local owner = inst.entity:GetParent()
            if owner ~= ThePlayer then
                return
            end
        -----------------------------------------------------------
        ---
            local hud = inst.hud
            if hud == nil or not hud.inst:IsValid() then
                local front_root = ThePlayer.HUD.controls:AddChild(Widget())
                inst.hud = front_root
                hud = front_root
                front_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
                front_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
                -- front_root:SetPosition(1000,500)
                front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
                local text_box = front_root:AddChild(Text(CODEFONT,15,"1",{ 200/255 , 255/255 ,255/255 , 1}))
                inst:ListenForEvent("onremove",function()
                    front_root:Kill()
                end)
                hud.text_box = text_box
                local offset_x,offset_y = 0,-30
                TBAT:AddInputUpdateFn(front_root.inst,function()
                    local x,y = TheSim:GetScreenPos(ThePlayer.Transform:GetWorldPosition())
                    front_root:SetPosition(x+offset_x,y+offset_y)
                end)
            end
        -----------------------------------------------------------
        ---
            hud.text_box:SetString(tostring(time))
        -----------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnDetached(inst) -- 被外部命令。默认情况下，内部的onremove不会执行，需要自己手动添加event
        local target = inst.entity:GetParent()
        -- print("debuff OnDetached",inst,target)
        if not inst.__working then
            return
        end
        turn_off_ocean_walk(target)
    end
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
            inst:ListenForEvent("onremove",OnDetached)
        -----------------------------------------------------
        --- 
            InitTime(inst)
        -----------------------------------------------------
        ---
            inst:DoPeriodicTask(1,function()
                local time = AddTime(inst,-1)
                if time <= 0 then
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
        ---
            inst:DoTaskInTime(1,function()
                if TheWorld:HasTag("cave") then
                    return
                end
                inst.__working = true
                turn_on_ocean_walk(target)
            end)
        -----------------------------------------------------
        --- 处理某些装备穿脱导致的 水上行走解除
            inst:ListenForEvent("unequipped",turn_on_ocean_walk,target)
        -----------------------------------------------------
    end
    local function ExtendDebuff(inst)  --- 添加同一索引的时候执行
        ResetTime(inst)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function debuff_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("tbat_item_crystal_bubble")
        inst.AnimState:SetBuild("tbat_item_crystal_bubble")
        inst.AnimState:PlayAnimation("big",true)
        inst:AddTag("CLASSIFIED")
        inst.__time = net_float(inst.GUID, "time", "timeupdate")
        inst.entity:SetPristine()
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("timeupdate",timer_hud_open)
        end
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
        -- inst.components.debuff:SetDetachedFn(inst.Remove)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(ExtendDebuff)
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_item_crystal_bubble_debuff", debuff_fn)