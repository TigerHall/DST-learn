--    水土流失    --

-- 田地削弱,农作物长好时0.1概率水土流失,刚耕的地也必定水土流失
local destoryentstag = {"farm_plant", "soil"}
local farmplanttags = {"farm_plant"}
if CONFIGS_LEGION then
    table.insert(destoryentstag, "crop_legion")
    table.insert(destoryentstag, "crop2_legion")
    table.insert(farmplanttags, "crop_legion")
    table.insert(farmplanttags, "crop2_legion")
end
local function OnIsWinter(inst, iswinter) if iswinter then inst:DoTaskInTime(0, inst.Remove) end end
-- 定时消耗养料,养料和水分不足则周围的农作物全部铲除视为干死,耕地铲除;等于一株杂草的消耗速率
local function ConsumeNutrients(inst, drink)
    if TheWorld.components.farming_manager then
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.components.farming_manager:CycleNutrientsAtPoint(x, 0, z, {
            TUNING.FARM_PLANT_CONSUME_NUTRIENT_LOW / 4,
            TUNING.FARM_PLANT_CONSUME_NUTRIENT_LOW / 4,
            TUNING.FARM_PLANT_CONSUME_NUTRIENT_LOW / 4
        }) and TheWorld.state.issummer and inst.components.farmsoildrinker:CalcPercentTimeHydrated() < TUNING.FARM_PLANT_DROUGHT_TOLERANCE then
            local tileents = TheWorld.Map:GetEntitiesOnTileAtPoint(x, 0, z)
            local ents = TheSim:FindEntities(x, 0, z, 3, destoryentstag)
            for _, ent in ipairs(tileents) do
                if ent and ent:IsValid() and not table.contains(ents, ent) and ent:HasOneOfTags(destoryentstag) then table.insert(ents, ent) end
            end
            for i, v in ipairs(ents) do
                if v and v:IsValid() and v ~= inst then
                    if v.components.workable then
                        v.components.workable:Destroy(inst)
                    elseif v:HasTag("soil") then
                        v:PushEvent("collapsesoil")
                    end
                end
            end
            if TheWorld.Map:IsFarmableSoilAtPoint(x, 0, z) then
                inst:AddComponent("terraformer")
                inst.components.terraformer:Terraform(Vector3(x, 0, z))
                inst:RemoveComponent("terraformer")
            end
        end
    end
end
local function GetDrinkRate(inst) return TUNING.FARM_PLANT_DRINK_HIGH end
local function onsave(inst, data) data.pro2hm = inst.pro2hm end
local function onload(inst, data)
    inst.pro2hm = data and data.pro2hm
    if inst.pro2hm then
        if inst.components.repairable then inst:RemoveComponent("repairable") end
        inst.AnimState:SetMultColour(1, 0.7, 0.7, 1)
        inst:AddTag("farmdock2hm")
        inst:AddTag("farm_plant_killjoy")
        inst.Transform:SetRotation(math.random() * 360)
        inst.weed_def = {
            nutrient_consumption = {TUNING.FARM_PLANT_CONSUME_NUTRIENT_HIGH, TUNING.FARM_PLANT_CONSUME_NUTRIENT_HIGH, TUNING.FARM_PLANT_CONSUME_NUTRIENT_HIGH}
        }
        inst:WatchWorldState("iswinter", OnIsWinter)
        -- 定时消耗水分养料
        inst.consumetask2hm = inst:DoPeriodicTask(240, ConsumeNutrients, math.random() * 180 + 60)
        inst:AddComponent("farmsoildrinker")
        inst.components.farmsoildrinker.getdrinkratefn = GetDrinkRate
    end
end
AddPrefabPostInit("dock_damage", function(inst)
    if not TheWorld.ismastersim then return end
    SetOnSave(inst, onsave)
    SetOnLoad(inst, onload)
end)
local function spawnnewfarmdock(pos)
    if not pos then return end
    if #(TheSim:FindEntities(pos.x, 0, pos.z, TUNING.DAYLIGHT_SEARCH_RANGE, {"farmdockfix2hm"})) > 0 then return end
    local inst = SpawnPrefab("dock_damage")
    inst.persists = true
    inst.Transform:SetPosition(pos.x, 0, pos.z)
    onload(inst, {pro2hm = true})
end
local function losewaterandsoil(inst) if not TheWorld.state.iswinter and math.random() < 0.1 then spawnnewfarmdock(inst:GetPosition()) end end
local function clearfarmdock(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.DAYLIGHT_SEARCH_RANGE, {"farmdock2hm"})) do if v and v:IsValid() then v:Remove() end end
end
local function OnTerraform(inst, data, isloading)
    if not isloading and data.tile == WORLD_TILES.FARMING_SOIL and not TheWorld.state.iswinter then
        local pos = Vector3(inst.Map:GetTileCenterPoint(data.x, data.y))
        pos.x = pos.x + math.random() * 3 - 1.5
        pos.z = pos.z + math.random() * 3 - 1.5
        spawnnewfarmdock(pos)
    end
end
AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then return end
    inst:ListenForEvent("onterraform", OnTerraform)
end)
AddPrefabPostInit("staffcoldlight", function(inst)
    inst:AddTag("farmdockfix2hm")
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, clearfarmdock, TUNING.DAYLIGHT_SEARCH_RANGE)
end)
AddPrefabPostInit("staffcoldlightfx", function(inst)
    inst:AddTag("farmdockfix2hm")
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, clearfarmdock, TUNING.DAYLIGHT_SEARCH_RANGE)
end)
AddPrefabPostInit("deerclopseyeball_sentryward", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.inventoryitemholder then
        local self = inst.components.inventoryitemholder
        local onitemgivenfn = self.onitemgivenfn
        self.onitemgivenfn = function(inst, ...)
            onitemgivenfn(inst, ...)
            inst:AddTag("farmdockfix2hm")
            if not POPULATING then clearfarmdock(inst, TUNING.DEERCLOPSEYEBALL_SENTRYWARD_RADIUS) end
        end
        local onitemtakenfn = self.onitemtakenfn
        self.onitemtakenfn = function(inst, ...)
            onitemtakenfn(inst, ...)
            inst:RemoveTag("farmdockfix2hm")
        end
    end
end)
-- 采集后会概率刷出农田杂物
AddComponentPostInit("pickable", function(self)
    if not self.inst:HasOneOfTags(farmplanttags) then return end
    if not POPULATING and self.inst:IsValid() then
        if not self.inst.notlosewaterandsoil then
            losewaterandsoil(self.inst)
        else
            self.inst.notlosewaterandsoil = false
        end
    end
    local oldPick = self.Pick
    self.Pick = function(self, picker, ...)
        if self.inst and self.remove_when_picked and picker and picker:IsValid() and picker.prefab ~= "wormwood" and math.random() < 0.35 then
            SpawnPrefab("farm_soil_debris").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        end
        return oldPick(self, picker, ...)
    end
end)
local function processworkable(_inst, self)
    if self and self.onfinish then
        local onfinish = self.onfinish
        self.onfinish = function(inst, ...)
            if math.random() < 0.35 then SpawnPrefab("farm_soil_debris").Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            onfinish(inst, ...)
        end
    end
end
AddComponentPostInit("workable", function(self)
    if not self.inst:HasOneOfTags(farmplanttags) then return end
    self.inst:DoTaskInTime(0, processworkable, self)
end)

-- 留声机需要齿轮修理
local function phonographonfinished(inst)
    if inst.components.machine then
        if inst.components.machine:IsOn() then inst.components.machine:TurnOff() end
        inst.components.machine.enabled = false
    end
end
local phonographtime = TUNING.isCh2hm and "齿轮修理2hm" or "Gears Repair 2hm"
local function phonographontimerdone(inst, data)
    if data and data.name == phonographtime then
        inst.components.finiteuses:Use(1)
        if inst.components.machine.enabled and inst.components.machine:IsOn() then inst.components.timer:StartTimer(phonographtime, 480) end
    end
end
local function onrepaired(inst, repairuse, doer, repair_item, useitems) if inst.components.machine then inst.components.machine.enabled = true end end
AddPrefabPostInit("phonograph", function(inst)
    inst.repairmaterials2hm = {gears = 3}
    if not TheWorld.ismastersim then return end
    inst:AddComponent("repairable2hm")
    inst.components.repairable2hm.onrepaired = onrepaired
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", phonographontimerdone)
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(15)
    inst.components.finiteuses:SetUses(0)
    inst.components.finiteuses:SetDoesNotStartFull(true)
    inst.components.finiteuses:SetOnFinished(phonographonfinished)
    if inst.components.machine then
        local turnonfn = inst.components.machine.turnonfn
        inst.components.machine.turnonfn = function(inst, ...)
            if inst.components.finiteuses and inst.components.finiteuses:GetPercent() <= 0 then
                inst.components.machine.enabled = false
                return
            end
            turnonfn(inst, ...)
            if inst.components.machine.enabled then
                if not inst.components.timer:TimerExists(phonographtime) then
                    inst.components.timer:StartTimer(phonographtime, 480)
                else
                    inst.components.timer:ResumeTimer(phonographtime)
                end
            end
        end
        local turnofffn = inst.components.machine.turnofffn
        inst.components.machine.turnofffn = function(inst, ...)
            inst.components.timer:PauseTimer(phonographtime)
            turnofffn(inst, ...)
        end
    end
end)


--动态肥耗
local nutrientlevel = 3
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local plantstochoose
local function initseasonnutrients(data)
    data.season = TheWorld.state.season
    data.addon = nil
    if plantstochoose == nil then
        plantstochoose = {}
        for _, def in pairs(PLANT_DEFS) do
            if def and def.nutrient_consumption and def.nutrient_restoration then
                for _, count in ipairs(def.nutrient_consumption) do
                    if count and count ~= 0 and def.prefab then
                        table.insert(plantstochoose, def)
                        break
                    end
                end
            end
        end
    end
    local currdef = plantstochoose[math.random(#plantstochoose)]
    if currdef and currdef.nutrient_consumption and currdef.nutrient_restoration then
        -- 季节本季节的参考作物
        data.prefab = currdef.prefab
        local updatenutrients = {0, 0, 0}
        local total_restore_count = 0
        for n_type, consumptioncount in ipairs(currdef.nutrient_consumption) do
            updatenutrients[n_type] = updatenutrients[n_type] - consumptioncount
            total_restore_count = total_restore_count + consumptioncount
        end
        local nutrients_to_restore_count = GetTableSize(currdef.nutrient_restoration)
        local nutrient_restore_count = math.floor(total_restore_count / nutrients_to_restore_count)
        for n_type = 1, 3 do if currdef.nutrient_restoration[n_type] then updatenutrients[n_type] = updatenutrients[n_type] + nutrient_restore_count end end
        -- 记录本季节的作物加成，有正整数有负整数
        data.updatenutrients = updatenutrients
        -- 默认要取这些数值的1/3，数值大概是浮点数，整数以外的浮点数需要按概率给予才行
    else
        data.updatenutrients = data.updatenutrients or {-1, -1, -1}
    end
    if data.nutrients then data.nutrients = nil end
    if data.chance then data.chance = nil end
end
-- 根据季节额外消耗肥料
AddComponentPostInit("farming_manager", function(self)
    local CycleNutrientsAtPoint = self.CycleNutrientsAtPoint
    self.CycleNutrientsAtPoint = function(self, ...)
        self.dodepleted2hm = true
        local depleted = CycleNutrientsAtPoint(self, ...)
        self.dodepleted2hm = nil
        return depleted
    end
    local AddTileNutrients = self.AddTileNutrients
    self.AddTileNutrients = function(self, x, y, nutrient1, nutrient2, nutrient3, ...)
        if self.dodepleted2hm and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm.data.seasonnutrients
            if data == nil or data.season ~= TheWorld.state.season or data.updatenutrients == nil then
                data = data or {}
                TheWorld.components.persistent2hm.data.seasonnutrients = data
                initseasonnutrients(data)
            end
            if data and data.updatenutrients then
                if data.addon == nil or data.nutrientlevel ~= nutrientlevel then
                    data.nutrientlevel = nutrientlevel
                    data.addon = {}
                    for i = 1, 3 do
                        data.addon[i] = {}
                        local value = data.updatenutrients[i] * data.nutrientlevel / 9
                        local floorv = math.floor(value)
                        data.addon[i].floorv = floorv
                        data.addon[i].chance = value - floorv
                    end
                end
                nutrient1 = nutrient1 + data.addon[1].floorv + (data.addon[1].chance > 0 and math.random() < data.addon[1].chance and 1 or 0)
                nutrient2 = nutrient2 + data.addon[2].floorv + (data.addon[2].chance > 0 and math.random() < data.addon[2].chance and 1 or 0)
                nutrient3 = nutrient3 + data.addon[3].floorv + (data.addon[3].chance > 0 and math.random() < data.addon[3].chance and 1 or 0)
            end
        end
        return AddTileNutrients(self, x, y, nutrient1, nutrient2, nutrient3, ...)
    end
end)
-- 检查高级耕地帽
local function onequipped(inst, data)
    if inst.components.inspectable and data and data.owner and data.owner:IsValid() and data.owner:HasTag("player") and data.owner.components.talker then
        local desc, text_filter_context, original_author = inst.components.inspectable:GetDescription(data.owner)
        if desc ~= nil then data.owner.components.talker:Say(desc, 20, true, nil, nil, nil, text_filter_context, original_author) end
    end
end
AddPrefabPostInit("nutrientsgoggleshat", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.inspectable then
        local GetDescription = inst.components.inspectable.GetDescription
        inst.components.inspectable.GetDescription = function(self, ...)
            local txt
            if TheWorld.components.persistent2hm then
                local data = TheWorld.components.persistent2hm.data.seasonnutrients
                if data == nil or data.season ~= TheWorld.state.season or data.updatenutrients == nil then
                    data = data or {}
                    TheWorld.components.persistent2hm.data.seasonnutrients = data
                    initseasonnutrients(data)
                end
                if data and data.prefab and data.updatenutrients then
                    txt = "\n" ..
                              (TUNING.isCh2hm and "本季节各耕地单位养分加成为下数值的" or
                                  "Current Season's Per Farm Nutrients Addon as following's ") .. nutrientlevel .. "/9\n"
                    for i, v in ipairs(data.updatenutrients) do
                        local prefix = v >= 0 and STRINGS.UI.PLANTREGISTRY.NUTRIENTS.RESTORE or STRINGS.UI.PLANTREGISTRY.NUTRIENTS.CONSUME
                        txt =
                            txt .. prefix .. (STRINGS.UI.PLANTREGISTRY.NUTRIENTS[string.upper("nutrient_" .. i)] or ("nutrient_" .. i)) .. " " .. math.abs(v) ..
                                "\n"
                    end
                    txt = txt .. (TUNING.isCh2hm and "可参考" or "Just Like ") .. (STRINGS.NAMES[string.upper(data.prefab)] or data.prefab)
                end
            end
            local desc, filter_context, author = GetDescription(self, ...)
            desc = (desc or "") .. (txt or "")
            return desc, filter_context, author
        end
    end
    inst:ListenForEvent("equipped", onequipped)
end)

-- 娇生惯养的作物，种子培育难度增加

-- 杂草概率提高

TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE = 0.80

-- 0到1压力点，长出巨型农作物；2到3压力点，产生1个正常产品和1个作物种子；4到6压力点，产生1个正常产品。

-- AddComponentPostInit("FarmPlantStress", function(self)
--     if TheWorld.ismastersim then
--         self.CalcFinalStressState = function()
--             local stress = self.stress_points
--             self.final_stress_state = stress <= 1 and FARM_PLANT_STRESS.NONE  -- 0 到 1 个压力点
--                                    or stress <= 6 and FARM_PLANT_STRESS.MODERATE  -- 2 到 6 个压力点
--                                    or FARM_PLANT_STRESS.HIGH                 -- 超过 6 个压力点 
--             return self.final_stress_state
--         end
--     end
-- end)

-- 压力点累计到大于6时农作物枯萎。

-- 巨型农作物，但是只有1个种子