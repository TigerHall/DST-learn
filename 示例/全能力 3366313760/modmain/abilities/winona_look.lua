local Utils = require("aab_utils/utils")

-- 女工文本
-- 要不要这么长啊
AddGamePostInit(function()
    AAB_ReplaceCharacterLines("winona")
end)

----------------------------------------------------------------------------------------------------
--没有佩戴玫瑰眼镜时只能检查一些特殊的目标，不要什么都仔细检查

local CAN_INSPECT_PREFABS = {
    wormhole = true,             --虫洞
    tentacle_pillar_hole = true, --触手洞
    charlieresidue = true        --小地图传送用的标记
}

Utils.FnDecorator(CLOSEINSPECTORUTIL, "CanCloseInspect", function(doer, targetorpos)
    if targetorpos:is_a(EntityScript)
        and doer
        and doer.replica.inventory
        and not CAN_INSPECT_PREFABS[targetorpos.prefab] then
        doer._aab_true_closeinspector = true --执行真的EquipHasTag方法
        local isskip = not doer.replica.inventory:EquipHasTag("closeinspector")
        doer._aab_true_closeinspector = nil
        if isskip then
            return { false }, true
        end
    end
end)


----------------------------------------------------------------------------------------------------

local function EquipHasTagBefore(self, tag)
    return { true }, not self.inst._aab_true_closeinspector and tag == "closeinspector"
end

-- CLOSEINSPECTORUTIL判定可以生成桥需要的标签
AddComponentPostInit("inventory", function(self)
    Utils.FnDecorator(self, "EquipHasTag", EquipHasTagBefore)
end)

AddClassPostConstruct("components/inventory_replica", function(self)
    Utils.FnDecorator(self, "EquipHasTag", EquipHasTagBefore)
end)

----------------------------------------------------------------------------------------------------
AAB_AddSpecialAction(function(inst, pos, useitem, right, bufs, usereticulepos)
    if right then
        --match ReticuleTargetFn
        if usereticulepos then
            local pos2 = Vector3()
            for r = 2.5, 1, -.25 do
                pos2.x, pos2.y, pos2.z = inst.entity:LocalToWorldSpace(r, 0, 0)
                if CLOSEINSPECTORUTIL.IsValidPos(inst, pos2) then
                    return { ACTIONS.LOOKAT }, pos2
                end
            end
        end

        --default
        if CLOSEINSPECTORUTIL.IsValidPos(inst, pos) then
            return { ACTIONS.LOOKAT }
        end
    end
    return {}
end)

local function IsActivatedBefore(self, skill)
    return { true }, skill == "winona_charlie_1" or skill == "winona_charlie_2"
end

AddPlayerPostInit(function(inst)
    inst:AddTag("closeinspector")
    inst:AddTag("wormholetracker")

    Utils.FnDecorator(inst.components.skilltreeupdater, "IsActivated", IsActivatedBefore)

    if not TheWorld.ismastersim then return end

    if not inst.components.roseinspectableuser then
        inst:AddComponent("roseinspectableuser")
    end
end)

----------------------------------------------------------------------------------------------------

local function ShouldLOOKATStopLocomotor(act)
    return not (
        (act.doer.components.playercontroller ~= nil and act.doer.components.playercontroller.directwalking) or
        (act.doer.sg ~= nil and act.doer.sg:HasStateTag("overridelocomote"))
    )
end

--没有眼镜也可以造桥
local OldLookAtFn = ACTIONS.LOOKAT.fn
ACTIONS.LOOKAT.fn = function(act)
    --Try close inspection first
    if act.invobject == nil and act.doer.components.roseinspectableuser then
        if act.target then
            if CLOSEINSPECTORUTIL.CanCloseInspect(act.doer, act.target) then
                if ShouldLOOKATStopLocomotor(act) then
                    act.doer.components.locomotor:Stop()
                end
                local success, reason = act.doer.components.roseinspectableuser:TryToDoRoseInspectionOnTarget(act.target)
                if not success then
                    local sgparam = { closeinspect = true }
                    act.doer.components.talker:Say(GetActionFailString(act.doer, "LOOKAT", reason), nil, nil, nil, nil, nil, nil, nil, nil, sgparam)
                end
                return success, reason
            end
        else
            local pt = act:GetActionPoint()
            if pt and CLOSEINSPECTORUTIL.CanCloseInspect(act.doer, pt) then
                if ShouldLOOKATStopLocomotor(act) then
                    act.doer.components.locomotor:Stop()
                end
                local success, reason = act.doer.components.roseinspectableuser:TryToDoRoseInspectionOnPoint(pt)
                if not success then
                    local sgparam = { closeinspect = true }
                    act.doer.components.talker:Say(GetActionFailString(act.doer, "LOOKAT", reason), nil, nil, nil, nil, nil, nil, nil, nil, sgparam)
                end
                return success, reason
            end
        end
    end

    return OldLookAtFn(act)
end

----------------------------------------------------------------------------------------------------

--没有眼镜也可以造桥
AddPrefabPostInit("charlieresidue", function(inst)
    if not TheWorld.ismastersim then return end

    local OldSetFXOwner = inst.SetFXOwner
    inst.SetFXOwner = function(inst, owner, ...)
        local oldfn = owner and owner.components.playervision and owner.components.playervision.HasRoseGlassesVision
        if oldfn then
            owner.components.playervision.HasRoseGlassesVision = function() return true end
        end

        local res = OldSetFXOwner(inst, owner, ...)

        if oldfn then
            owner.components.playervision.HasRoseGlassesVision = oldfn
        end

        return res
    end
end)

----------------------------------------------------------------------------------------------------
