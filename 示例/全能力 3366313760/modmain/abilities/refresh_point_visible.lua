local REFRESH_POINT_VISIBLE = GetModConfigData("refresh_point_visible")

AddPrefabPostInitAny(function(inst)
    if inst:HasTag("herd") or (REFRESH_POINT_VISIBLE == 2 and inst.components.objectspawner) then
        if not inst.Transform then
            inst.entity:AddTransform()
        end

        if not inst.Network then
            inst.entity:AddNetwork()
            -- 标记为本地实体，避免同步过多数据
            inst:AddTag("CLASSIFIED")
        end

        if not inst.AnimState then
            inst.entity:AddAnimState()
        end

        -- 延迟一帧确保组件初始化完成
        inst:DoTaskInTime(0, function()
            inst.AnimState:SetBank("boatrace_checkpoint_indicator")
            inst.AnimState:SetBuild("boatrace_checkpoint_indicator")
            inst.AnimState:PlayAnimation("idle_closed", true)
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.AnimState:SetSortOrder(1)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetHaunted(true)
        end)
    end
end)
