local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    inst.Remove = function() end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        if not POPULATING and
            TheWorld:HasTag("forest") and
            TheWorld.components and
            TheWorld.components.hmrcherryislandmanager ~= nil and
            TheWorld.components.hmrcherryislandmanager.center_pos == nil and
            not TheWorld.components.hmrcherryislandmanager.init_complete
        then
            TheWorld.components.hmrcherryislandmanager:SetCenterPos(inst:GetPosition())
            TheWorld.components.hmrcherryislandmanager:Init()
        end
    end)

    return inst
end

return Prefab("hmr_cherry_island_center", fn)
