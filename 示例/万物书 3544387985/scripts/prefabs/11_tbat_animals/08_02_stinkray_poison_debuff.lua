------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local MAX_POISON_TIME = 20
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnDetached(inst) -- 被外部命令。默认情况下，内部的onremove不会执行，需要自己手动添加event
        local target = inst.entity:GetParent()
    end
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
        -----------------------------------------------------
        --- 鳐鱼本身不会中毒
            if target.prefab == "tbat_animal_stinkray" then
                inst:Remove()
                return
            end
        -----------------------------------------------------
        --- 初始化计时器
            if inst.components.tbat_data:Get("timer") == nil then
                inst.components.tbat_data:Set("timer",MAX_POISON_TIME)
            end
        -----------------------------------------------------
        ---
            inst:DoPeriodicTask(1,function()
                local time = inst.components.tbat_data:Add("timer",-1)
                if time <= 0 then
                    inst:Remove()
                end
                if target.components.health then
                    local damage = -1
                    if inst.damage then
                        damage = -1 * math.abs(inst.damage)
                    end
                    target.components.health:DoDelta(damage,nil,inst.prefab)
                end
            end)
        -----------------------------------------------------
        --- 添加事件 : 修改伤害值
            inst:ListenForEvent("set_override_stinkray_poison_damage",function(_,damage)
                inst.damage = damage
            end,target)
        -----------------------------------------------------
    end
    local function ExtendDebuff(inst)  --- 添加同一索引的时候执行
        inst.components.tbat_data:Set("timer",MAX_POISON_TIME)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("tbat_data")
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(ExtendDebuff)
    return inst
end

return Prefab("tbat_debuff_stinkray_poison", fn)
