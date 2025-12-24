local prefs = {}

local function AddCarpet(name, data)
    local assets =
    {
        Asset("ANIM", "anim/hmr_cherry_carpet.zip"),
        -- Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        -- Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
    }

    local function OnDeploy(inst, pt, deployer, rot)
        local carpet = SpawnPrefab(name)
        if carpet ~= nil then
            carpet.Transform:SetPosition(pt:Get())
            --carpet.Transform:SetRotation(rot)
            inst:Remove()
        end
    end

    local function item_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("item")

        inst:AddTag("carpet_item")

        if data.item_common_postinit ~= nil then
            data.item_common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = name.."_item"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_item.xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeploySpacing(0)
        inst.components.deployable.ondeploy = OnDeploy

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)

        if data.item_master_postinit ~= nil then
            data.item_master_postinit(inst)
        end

        return inst
    end

    local function OnWorked(inst)
        inst.components.lootdropper:SpawnLootPrefab(name.."_item")

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("hmr_cherry_carpet")
        inst.AnimState:SetBuild("hmr_cherry_carpet")
        inst.AnimState:PlayAnimation("creamy_white1")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetFinalOffset(1)

        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("carpet")

        -- 配合叉子做移除动作
        inst:AddTag("hmr_carpet")
        inst.radius = data.radius or 3

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("savedrotation")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.TERRAFORM)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnWorked)

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    --table.insert(prefs, Prefab(name.."_item", item_fn, assets))
    --table.insert(prefs, MakePlacer(name.."_item_placer", name, name, "ground", true, nil, nil, nil, 90))

    table.insert(prefs, Prefab(name, fn, assets))
end

AddCarpet("hmr_cherry_carpet_creamy_white1",
    {
        radius = 3,
    }
)

return unpack(prefs)