

local function builder_onbuilt(inst,_table)
    local builder = _table and _table.builder or nil
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.onBuild = function(builder,inst)
        print("onBuild",builder,inst)
    end

    inst:ListenForEvent("onbuilt",builder_onbuilt)

    return inst
end

return Prefab("spell_reject_the_npc", fn)


