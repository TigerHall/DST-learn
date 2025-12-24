local assets =
{
    Asset("ANIM", "anim/bundle.zip"),
}

local function CanDeploy(inst, pt)
    local prefab = inst.entprefab:value()
    if not prefab then return false end

    if prefab == "moonbase" then --月亮石放船上升级的时候会崩溃的
        return TheWorld.Map:IsPassableAtPoint(pt.x, pt.y, pt.z, false, true)
    end

    return true
end

-- 当玩家打包天体门的时候，把玩家重生点移动到天体门的位置
local function ProcessPlayerPortal(ent, pt)
    local spawnpoint
    for _, v in pairs(Ents) do
        if v.prefab == "spawnpoint_master" then
            spawnpoint = v
            break
        end
    end

    if spawnpoint and not GetClosestInstWithTag("multiplayer_portal", spawnpoint, 4) then
        spawnpoint.Transform:SetPosition(pt:Get())
    end
end

local function on_deploy(inst, pt, deployer)
    local ent = SpawnSaveRecord(inst.entdata)
    if ent then
        ent.Transform:SetPosition(pt:Get())
    end

    if ent:HasTag("multiplayer_portal") then
        ProcessPlayerPortal(ent, pt)
    end

    local item = SpawnAt("waxpaper", pt)
    if deployer and deployer.components.inventory then
        deployer.components.inventory:GiveItem(item)
    else
        item.components.inventoryitem:OnDropped(true)
    end
    inst:Remove()
end

local function Setup(inst, target)
    inst.entdata = target:GetSaveRecord()
    inst.components.named:SetName(STRINGS.NAMES.AAB_SUPERBUNDLE .. "(" .. target:GetBasicDisplayName() .. ")")
    inst.entprefab:set(target.prefab)

    target:Remove()
end


----------------------------------------------------------------------------------------------------

local function OnSave(inst, data)
    data.entdata = inst.entdata
    data.entprefab = inst.entprefab:value()
end

local function OnLoad(inst, data)
    if not data then return end
    inst.entdata = data.entdata
    if data.entprefab then
        inst.entprefab:set(data.entprefab)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, nil, 0.15)

    inst._custom_candeploy_fn = CanDeploy
    inst.entprefab = net_string(inst.GUID, "aab_superbundle.entprefab")

    inst.AnimState:SetBank("bundle")
    inst.AnimState:SetBuild("bundle")
    inst.AnimState:PlayAnimation("idle_large")

    inst:AddTag("portableitem")
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveTag("_named")
    inst:AddComponent("named")

    inst.entdata = nil
    inst.Setup = Setup

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "bundle_large"

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = on_deploy

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("aab_superbundle", fn, assets),
    MakePlacer("aab_superbundle_placer", "bundle", "bundle", "idle_large")
