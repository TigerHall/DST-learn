local assets =
{
    Asset("ANIM", "anim/hmr_dug_cavebananatree.zip"),
    Asset("ATLAS", "images/inventoryimages/hmr_dug_cavebananatree.xml"),
    Asset("IMAGE", "images/inventoryimages/hmr_dug_cavebananatree.tex"),
}

local function ondeploy(inst, pt, deployer)
    local tree = SpawnPrefab("cave_banana_tree")
    if tree ~= nil then
        tree.components.pickable:MakeEmpty()
        tree.Transform:SetPosition(pt:Get())

        inst.components.stackable:Get():Remove()

        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            --V2C: WHY?!! because many of the plantables don't
            --     have SoundEmitter, and we don't want to add
            --     one just for this sound!
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end

        if TheWorld.components.lunarthrall_plantspawner and tree:HasTag("lunarplant_target") then
            TheWorld.components.lunarthrall_plantspawner:setHerdsOnPlantable(tree)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("deployedplant")

    inst.AnimState:SetBank("hmr_dug_cavebananatree")
    inst.AnimState:SetBuild("hmr_dug_cavebananatree")
    inst.AnimState:PlayAnimation("idle")
    inst.scrapbook_anim = "idle"

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hmr_dug_cavebananatree.xml"
    inst.components.inventoryitem.imagename = "hmr_dug_cavebananatree"

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)

    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return  Prefab("hmr_dug_cavebananatree", fn, assets),
        MakePlacer("hmr_dug_cavebananatree_placer", "cave_banana_tree", "cave_banana_tree", "idle_loop")