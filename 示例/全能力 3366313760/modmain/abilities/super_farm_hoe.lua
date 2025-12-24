local params = require("containers").params

params.farm_hoe =
{
    widget =
    {
        slotpos = {
            Vector3(0, 2, 0),
        },
        animbank = "ui_antlionhat_1x1",
        animbuild = "ui_antlionhat_1x1",
        pos = Vector3(0, 40, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.farm_hoe.itemtestfn(container, item, slot)
    return item:HasTag("deployedplant") and item:HasTag("deployedfarmplant")
end

params.golden_farm_hoe = params.farm_hoe

----------------------------------------------------------------------------------------------------

local FIND_RADIUS = math.sqrt(8)
local SOILMUST = { "soil" }
local SOILMUSTNOT = { "farm_debris", "NOBLOCK" }

local function OnEquipped(inst, data)
    if data and data.owner then
        inst.components.container:Open(data.owner)
    end
end
local function OnUnequipped(inst, data)
    inst.components.container:Close()
end

for _, prefab in ipairs({
    "farm_hoe",
    "golden_farm_hoe"
}) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end

        if not inst.components.container then
            inst:AddComponent("container")
            inst.components.container:WidgetSetup(prefab)
        end

        inst:ListenForEvent("equipped", OnEquipped)
        inst:ListenForEvent("unequipped", OnUnequipped)

        local OldTill = inst.components.farmtiller.Till
        inst.components.farmtiller.Till = function(self, pt, doer, ...)
            --去除土堆
            local x, y, z = TheWorld.Map:GetTileCenterPoint(pt:Get())
            for _, v in ipairs(TheSim:FindEntities(x, y, z, FIND_RADIUS, { "farm_debris" })) do
                if v.components.workable then
                    v.components.workable:Destroy(doer or TheWorld)
                end
            end

            local res = false
            --挖坑
            local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
            if tile == WORLD_TILES.FARMING_SOIL then
                local soils = TheSim:FindEntities(x, 0, z, 2, SOILMUST, SOILMUSTNOT)
                if #soils < 9 then
                    local dist = 4 / 3
                    for dx = -dist, dist, dist do
                        for dz = -dist, dist, dist do
                            local localsoils = TheSim:FindEntities(x + dx, 0, z + dz, 0.21, SOILMUST, SOILMUSTNOT)
                            if #localsoils < 1 and TheWorld.Map:CanTillSoilAtPoint(x + dx, 0, z + dz) then
                                local actionPos = Vector3(x + dx - 0.02 + math.random() * 0.04, 0,
                                    z + dz - 0.02 + math.random() * 0.04)
                                res = OldTill(self, actionPos, doer, ...) or res
                            end
                        end
                    end
                end
            end

            --播种
            for _, v in ipairs(TheSim:FindEntities(x, y, z, FIND_RADIUS, { "soil" }, { "NOCLICK" })) do
                local seed = inst.components.container:GetItemInSlot(1)
                seed = seed and inst.components.container:RemoveItem(seed, false)
                if seed and seed.components.farmplantable then
                    if not seed.components.farmplantable:Plant(v, doer) then
                        inst.components.container:GiveItem(seed)
                        break
                    end
                else
                    break
                end
            end

            return res
        end
    end)
end
