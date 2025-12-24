local assets =
{
    Asset("ANIM", "anim/tbat_building_cherry_blossom_rabbit_swing.zip"),
    Asset("ANIM", "anim/tbat_building_red_spider_lily_rocking_chair.zip"),
    Asset("ANIM", "anim/atbook_sit2.zip"),
}

local function OnFinish(inst, worker)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function InitFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("tbat_building_cherry_blossom_rabbit_swing.tex")

    MakeObstaclePhysics(inst, 0.4, 0.6)

    inst.AnimState:SetBank("tbat_building_cherry_blossom_rabbit_swing")
    inst.AnimState:SetBuild("tbat_building_cherry_blossom_rabbit_swing")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:OverrideSymbol("slot", "tbat_building_cherry_blossom_rabbit_swing", "empty")

    inst:AddTag("structure")
    inst:AddTag("tbat_building_cherry_blossom_rabbit_swing")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("atbook_swing")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(9)
    inst.components.workable:SetOnFinishCallback(OnFinish)
    local OldWorkedBy = inst.components.workable.WorkedBy
    local function WorkedBy(self, worker, numworks, ...)
        if worker and worker:HasTag("player") then
            return OldWorkedBy(self, worker, numworks, ...)
        end
    end
    inst.components.workable.WorkedBy = WorkedBy

    inst:ListenForEvent("ms_playerleft", function(world, player)
        if inst.passenger == player and inst:HasTag("isusing") then
            inst.AnimState:PlayAnimation("swing_pst")
            inst.AnimState:PushAnimation("idle", true)
            inst:RemoveTag("isusing")
        end
    end, TheWorld)

    return inst
end

local function InitFn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("tbat_building_red_spider_lily_rocking_chair.tex")

    MakeObstaclePhysics(inst, 0.4, 0.6)

    inst.AnimState:SetBank("tbat_building_red_spider_lily_rocking_chair")
    inst.AnimState:SetBuild("tbat_building_red_spider_lily_rocking_chair")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:OverrideSymbol("slot", "tbat_building_red_spider_lily_rocking_chair", "empty")

    inst:AddTag("structure")
    inst:AddTag("tbat_building_red_spider_lily_rocking_chair")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("atbook_swing")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(9)
    inst.components.workable:SetOnFinishCallback(OnFinish)
    local OldWorkedBy = inst.components.workable.WorkedBy
    local function WorkedBy(self, worker, numworks, ...)
        if worker and worker:HasTag("player") then
            return OldWorkedBy(self, worker, numworks, ...)
        end
    end
    inst.components.workable.WorkedBy = WorkedBy

    inst:ListenForEvent("ms_playerleft", function(world, player)
        if inst.passenger == player and inst:HasTag("isusing") then
            inst.AnimState:PlayAnimation("swing_pst")
            inst.AnimState:PushAnimation("idle", true)
            inst:RemoveTag("isusing")
        end
    end, TheWorld)

    return inst
end

-- RegisterInventoryItemAtlas("images/map_icons/tbat_building_cherry_blossom_rabbit_swing.xml",
--     "tbat_building_cherry_blossom_rabbit_swing.tex")
-- RegisterInventoryItemAtlas("images/map_icons/tbat_building_red_spider_lily_rocking_chair.xml",
--     "tbat_building_red_spider_lily_rocking_chair.tex")

return Prefab("tbat_building_cherry_blossom_rabbit_swing", InitFn, assets),
    MakePlacer("tbat_building_cherry_blossom_rabbit_swing_placer", "tbat_building_cherry_blossom_rabbit_swing",
        "tbat_building_cherry_blossom_rabbit_swing", "swing_pst"),
    Prefab("tbat_building_red_spider_lily_rocking_chair", InitFn2, assets),
    MakePlacer("tbat_building_red_spider_lily_rocking_chair_placer", "tbat_building_red_spider_lily_rocking_chair",
        "tbat_building_red_spider_lily_rocking_chair", "swing_pst")
