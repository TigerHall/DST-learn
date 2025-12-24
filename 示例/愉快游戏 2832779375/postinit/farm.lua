
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("farm_high_stress") then
    local veggieprefabs = {}
    local veggie_oversizedprefabs = {}
    for veggie, data in pairs(PLANT_DEFS) do
        if veggie ~= "randomseed" then
            table.insert(veggieprefabs, data.prefab)
            table.insert(veggie_oversizedprefabs, veggie .. "_oversized")
            AddPrefabPostInit("farm_plant_"..veggie, function(inst)
                if not TheWorld.ismastersim then
                    return inst
                end

                inst:DoTaskInTime(FRAMES, function(inst)
                    inst.force_oversized = true
                end)
            end)
            AddPrefabPostInit(veggie.."_oversized", function(inst)
                -- inst.Physics:SetActive(false)

                if not TheWorld.ismastersim then
                    return inst
                end
                if inst.components.perishable then
                    inst:RemoveComponent("perishable")
                end
            end)
        end
    end
    AddClassPostConstruct("components/growable", function(self)
        local _DoGrowth = self.DoGrowth
        function self:DoGrowth()
            if table.contains(veggieprefabs, self.inst.prefab) and self:GetStage() == 5 then
                return
            end
            return _DoGrowth(self)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("niubility_gardening") then
    TUNING.BOOK_GARDENING_MAX_TARGETS = 999
    TUNING.BOOK_GARDENING_UPGRADED_MAX_TARGETS = 999
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("hoe_9x9") then
    AddComponentPostInit("farmtiller", function(self, inst)
        local _Till = self.Till
        -- 3x3耕地，代码来自musha
        function self:Till(pt, doer)
            if table.contains({"farm_hoe", "golden_farm_hoe", "shovel_lunarplant"}, self.inst.prefab) then
                local NewX, Newy, Newz = TheWorld.Map:GetTileCenterPoint(pt.x, pt.y, pt.z)

                local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(NewX, 0, Newz)
                for _, ent in ipairs(ents) do
                    if ent ~= inst and ent:HasTag("soil") then
                        ent:PushEvent("collapsesoil")
                    elseif ent:HasTag("antlion_sinkhole") then -- 这段逻辑貌似没效
                        if ent.remainingrepairs then
                            for i = 1, ent.remainingrepairs do
                                ent:PushEvent("timerdone", {
                                    name = "nextrepair"
                                })
                            end
                        else
                            ent.remainingrepairs = 1
                            ent:PushEvent("timerdone", { name = "nextrepair" })
                        end
                    end
                end

                local TILLSOIL_IGNORE_TAGS = {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "WALKABLEPLATFORM", "soil", "medal_farm_plow"}
                for i = 0, 2 do
                    for k = 0, 2 do
                        local loction_x = NewX + 1.3 * i - 1.3
                        local loction_z = Newz + 1.3 * k - 1.3
                        if TheWorld.Map:IsDeployPointClear(Vector3(loction_x, 0, loction_z), nil, GetFarmTillSpacing(), nil,
                            nil, nil, TILLSOIL_IGNORE_TAGS) then
                            SpawnPrefab("farm_soil").Transform:SetPosition(loction_x, 0, loction_z)
                        end
                    end
                end
                return true
            else
                return _Till(self, pt, doer)
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("staffcoldlight_grow_farmplants") then
    AddPrefabPostInit("staffcoldlight", function(inst)
        inst:AddTag("daylight")
    end)
end
--------------------------------------------------------------------------------------------------------------------




























