------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnDetached(inst) -- 被外部命令。默认情况下，内部的onremove不会执行，需要自己手动添加event
        inst:Remove()
    end
    local function OnAttached(inst,target) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(target.entity)
            inst.Transform:SetPosition(0,0,0)
            target:ListenForEvent("onremove",OnDetached,inst)
            -- inst.Network:SetClassifiedTarget(target)  -- 不建议用，容易在客户端丢失实体
            -- local player = inst.entity:GetParent()
        -----------------------------------------------------
        --- 
            inst:ListenForEvent("test",function()
                print("test66666666")
            end,target)
            print("fake error OnAttached rod_debuff_excample")
        -----------------------------------------------------
    end
    local function ExtendDebuff(inst)  --- 添加同一索引的时候执行

    end
------------------------------------------------------------------------------------------------------------------------------------------------
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
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
        --[[
            target:AddDebuff(name_index,debuff_prefab) 的瞬间执行 OnAttached
            这一瞬不执行 ExtendDebuff
        ]]--
    inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
        --[[
            留存到下次存档重载、留存到洞穴跨越。
            会在存档重载的瞬间，执行 OnAttached ，不执行 ExtendDebuff
        ]]--
    inst.components.debuff:SetDetachedFn(OnDetached)
        --[[
            target:RemoveDebuff(name_index) 的瞬间执行。
            【注意】debuff_inst:Remove() 的瞬间【不】执行。        
            【注意】debuff_inst:Remove() 的瞬间【不】执行。
        ]]--
    inst.components.debuff:SetExtendedFn(ExtendDebuff)
        --[[
            target:AddDebuff(name_index,...) 的瞬间执行。
            同款 name_index 的瞬间执行，不会执行 OnAttached ，不会生成新的 debuff_inst 实体。
            【注意】 name_index 是唯一的，会无视 拥有这个 index 的debuff_prefab是谁。该功能通常用于多个同款debuff_prefab独立运行。
            通常用来：时间累积、时间重置、BUFF层数叠加。
        ]]--

    --[[
    
        其他：
            · 建议不要执行 inst.Network:SetClassifiedTarget(target)
                    这句代码会导致客户端丢失实体，无法触发各种 net 下发。
                    如果本BUFF不涉及任何客户端的事情，可以添加。
            · 如果需要debuff 跟着在客户端做某些操作，需要做好延时检查。

            · debuff_inst 的移除，注意处理好 OnDetached 和 debuff_inst:Remove() 的不同。

    ]]--
    return inst
end

return Prefab("rod_debuff_excample", fn)
