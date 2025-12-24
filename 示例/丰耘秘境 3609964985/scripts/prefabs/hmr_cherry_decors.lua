local prefs = {}

local pot_assets = {
    Asset("ANIM", "anim/hmr_cherry_decor_pot.zip"),
}

local function OnHitPot(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")

    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)
end

local function OnHammeredPot(inst, worker)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")

    inst:Remove()
end

local function pot_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:SetDeploySmartRadius(0)

    inst.AnimState:SetBank("hmr_cherry_decor_pot")
    inst.AnimState:SetBuild("hmr_cherry_decor_pot")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(OnHammeredPot)
    inst.components.workable:SetOnWorkCallback(OnHitPot)

    MakeHauntableLaunch(inst)

    return inst
end
table.insert(prefs, Prefab("hmr_cherry_decor_pot", pot_fn, pot_assets))



local function OnDeployPot(inst, pt, deployer)
    --inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
    local pot = SpawnPrefab("hmr_cherry_decor_pot", inst.linked_skinname, inst.skin_id)
    if pot ~= nil then
        pot.Transform:SetPosition(pt.x, 0, pt.z)
        pot.Transform:SetRotation(deployer.Transform:GetRotation())
        inst.components.stackable:Get():Remove()
        pot.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
        pot.AnimState:PlayAnimation("place")
        pot.AnimState:PushAnimation("idle", false)
    end
end

local function pot_item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- inst:SetDeploySmartRadius(0.1)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hmr_cherry_decor_pot")
    inst.AnimState:SetBuild("hmr_cherry_decor_pot")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetScale(0.7, 0.7)

    MakeInventoryFloatable(inst, "small", .1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hmr_cherry_decor_pot"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hmr_cherry_decor_pot.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = OnDeployPot
    -- inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

    MakeHauntableLaunch(inst)

    return inst
end
table.insert(prefs, Prefab("hmr_cherry_decor_pot_item", pot_item_fn, pot_assets))
table.insert(prefs, MakePlacer("hmr_cherry_decor_pot_item_placer", "hmr_cherry_decor_pot", "hmr_cherry_decor_pot", "idle"))

return unpack(prefs)