-- 由注能玻璃碎片合成的纯粹辉煌具有临时属性

local function fn()

    local original = SpawnPrefab("purebrilliance")
    if not original then
        print("Error: Cannot create purebrilliance2hm - purebrilliance prefab not found")
        return CreateEntity() -- 返回空实体避免崩溃
    end
    
    local original_fn = Prefabs.purebrilliance.fn
    
    local inst = original_fn()
    
    -- 清理临时的原版实例
    original:Remove()
    
    -- 设置预制体名称覆盖，使其使用原版的贴图和字符串
    inst:SetPrefabNameOverride("purebrilliance")
    
    if not TheWorld.ismastersim then return inst end
    
    -- 确保使用原版图标
    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = "purebrilliance"
    end
    
    -- 添加tempequip2hm组件使其永久保鲜且无法用于制作
    inst:AddComponent("tempequip2hm")
    inst.components.tempequip2hm.onperishreplacement = nil
    inst.components.tempequip2hm:BecomePerishable()
    if inst.components.perishable then
        inst.components.perishable.localPerishMultiplyer = 0  -- 永久保鲜
    end

    -- 添加特殊描述文本
    if inst.components.inspectable then
        local old_getspecialdescription = inst.components.inspectable.getspecialdescription
        inst.components.inspectable.getspecialdescription = function(inst, viewer)
            local base_desc = old_getspecialdescription and old_getspecialdescription(inst, viewer) or ""
            local extra_desc = TUNING.isCh2hm and "它的状态比之前稳定多了，但仍不足以制作东西。" or 
                               "Its state is much more stable than before, but still not enough to craft anything."
            return base_desc ~= "" and (base_desc .. "\n" .. extra_desc) or extra_desc
        end
    end

    -- 添加持久化支持
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    inst.components.persistent2hm.data.tempequip2hm_purebrilliance = true

    return inst
end

return Prefab("purebrilliance2hm", fn, {}, {"purebrilliance"})
