local assets = {
    Asset("ANIM", "anim/atbook_wiki.zip"),
    Asset("ATLAS", "images/inventoryimages/atbook_wiki.xml"),
    Asset("IMAGE", "images/inventoryimages/atbook_wiki.tex"),
}

local WIKIRESOURCE = require "widgets/atbook_wikiwidget_resource"

for _, value in pairs(WIKIRESOURCE) do
    table.insert(assets, Asset("ATLAS", value[1]))
end

local CONTENT = require "widgets/atbook_wikiwidget_defs"

for category, value in pairs(CONTENT) do
    for _, tab in pairs(value) do
        if type(tab) == "table" then
            for _, info in ipairs(tab) do
                if info.prefab then
                    table.insert(assets,
                        Asset("ATLAS",
                            "images/ui/atbook_wiki/content/" .. string.lower(category) .. "/" .. info.prefab .. ".xml"))
                    if info.haspage then
                        table.insert(assets,
                            Asset("ATLAS",
                                "images/ui/atbook_wiki/content/" ..
                                string.lower(category) .. "/page/" .. info.prefab .. ".xml"))
                    end
                    if info.hasimg then
                        table.insert(assets,
                            Asset("ATLAS",
                                "images/ui/atbook_wiki/content/" ..
                                string.lower(category) .. "/img/" .. info.prefab .. ".xml"))
                    end
                end
            end
        end
    end
end

local function OnDismantle(inst, doer)
    inst.AnimState:PlayAnimation("close")
    local pos = inst:GetPosition()
    local item = SpawnPrefab("atbook_wiki")
    if doer and doer.components.inventory then
        doer.components.inventory:GiveItem(item, nil, pos)
    else
        item.Transform:SetPosition(pos.x, 0, pos.y)
    end
    inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    local wiki = SpawnPrefab("atbook_wiki_place")
    if wiki ~= nil then
        wiki.Transform:SetPosition(pt:Get())
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(true)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(0.33)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(255 / 255, 255 / 255, 192 / 255)

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.05)

    inst.AnimState:SetBank("atbook_wiki")
    inst.AnimState:SetBuild("atbook_wiki")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetScale(0.5, 0.5, 0.5)

    inst:AddTag("atbook_wiki")
    inst:AddTag("portableitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.players = {}

    inst:AddComponent("inspectable")

    inst:AddComponent("atbook_wiki")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "atbook_wiki"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/atbook_wiki.xml"

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

    return inst
end

local function placefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(true)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(0.33)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(255 / 255, 255 / 255, 192 / 255)

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("atbook_wiki")
    inst.AnimState:SetBuild("atbook_wiki")
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("idle_open", true)

    inst:AddTag("atbook_wiki_place")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("atbook_wiki")

    inst:AddComponent("portablestructure")
    inst.components.portablestructure:SetOnDismantleFn(OnDismantle)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

    return inst
end

-- RegisterInventoryItemAtlas("images/inventoryimages/atbook_wiki.xml", "atbook_wiki.tex")

-- STRINGS.NAMES.ATBOOK_WIKI = "万物书"
-- STRINGS.CHARACTERS.GENERIC.DESCRIBE.ATBOOK_WIKI = "万物书的奇幻世界，此刻为你敞开"
-- STRINGS.RECIPE_DESC.ATBOOK_WIKI = "万物书"
-- STRINGS.NAMES.ATBOOK_WIKI_PLACE = "万物书"
-- STRINGS.CHARACTERS.GENERIC.DESCRIBE.ATBOOK_WIKI_PLACE = "万物书的奇幻世界，此刻为你敞开"

return Prefab("atbook_wiki", fn, assets),
    Prefab("atbook_wiki_place", placefn, assets),
    MakePlacer("atbook_wiki_placer", "atbook_wiki", "atbook_wiki", "idle")
