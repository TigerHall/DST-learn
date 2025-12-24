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
    local BUFF_TIME = 4*40
    -- local BUFF_TIME = 10
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
--- 
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnDetached(inst) -- 被外部命令。默认情况下，内部的onremove不会执行，需要自己手动添加event
        -- local target = inst.entity:GetParent()
        -- if inst:IsValid() then
        --     inst:Remove()
        -- end
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
        --- 饥饿自然下降速度倍率
            if target.components.hunger then
                target.components.hunger.burnratemodifiers:SetModifier(inst,0)
            end
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
        inst:AddTag("CLASSIFIED")
        inst.__time = net_float(inst.GUID, "time", "timeupdate")
        inst.entity:SetPristine()
        -- if not TheNet:IsDedicated() then
        --     inst:ListenForEvent("timeupdate",timer_hud_open)
        -- end
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
return Prefab("tbat_food_cooked_honey_meat_tower_debuff", debuff_fn)