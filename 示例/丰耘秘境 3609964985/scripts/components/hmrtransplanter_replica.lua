local FLOWERPOT_DATA_LIST = require("hmrmain/hmr_lists").FLOWERPOT_DATA_LIST

local function DisplayNameFn(inst)
    local name = inst.replica.hmrtransplanter and inst.replica.hmrtransplanter:GetName() or ""
    if name ~= nil and name ~= "" then
        return name
    end
    return inst.name or inst.prefab
end

local Transplanter = Class(function(self, inst)
    self.inst = inst

    self._pot_data = net_string(inst.GUID, "hmrtransplanter.pot_data")

    self._name = net_string(inst.GUID, "hmrtransplanter.name")
    inst.displaynamefn = DisplayNameFn

    self._modes = net_string(inst.GUID, "hmrtransplanter.modes")
end)

function Transplanter:EncodeData(str)
    local success, data = pcall(json.encode, str)
    if success then
        return data
    else
        return nil
    end
end

function Transplanter:DecodeData(data)
    local success, str = pcall(json.decode, data)
    if success then
        return str
    else
        return nil
    end
end

function Transplanter:SetPotData(pot_data)
    self._pot_data:set(self:EncodeData(pot_data))
end

function Transplanter:GetPotData()
    local data = self._pot_data:value()
    if data ~= nil then
        return self:DecodeData(data)
    else
        return nil
    end
end

function Transplanter:SetName(name)
    self._name:set(name)
end

function Transplanter:GetName()
    return self._name:value()
end

function Transplanter:SetTransplantModes(modes)
    self._modes:set(self:EncodeData(modes))
end

function Transplanter:GetTransplantModes()
    local data = self._modes:value()
    if data ~= nil then
        return self:DecodeData(data)
    else
        return nil
    end
end

-- 农作物
function Transplanter:IsFarmPlant(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "farm_plant" then
        return true
    end
    return plant:HasTag("farm_plant") and not plant:HasTag("weed")
end

-- 杂草
function Transplanter:IsWeedPlant(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "weed_plant" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("weed") or string.find(bank, "weed") ~= nil
end

-- 所有可移栽植物
function Transplanter:IsPlantable(plant)
    return self:IsBerryBush(plant) or
           self:IsGrass(plant) or
           self:IsSapling(plant) or
           self:IsBananaBush(plant) or
           self:IsMarshBush(plant) or
           self:IsRockAvocadoBush(plant) or
           self:IsLurePlant(plant)
end

-- 小型可移栽植物
function Transplanter:IsSmallPlantable(plant)
    return self:IsGrass(plant) or
           self:IsSapling(plant) or
           self:IsBananaBush(plant) or
           self:IsRockAvocadoBush(plant) or
           self:IsLurePlant(plant)
end

-- 大型可移栽植物
function Transplanter:IsLargePlantable(plant)
    return self:IsBerryBush(plant) or
           self:IsMarshBush(plant) or
           self:IsLurePlant(plant)
end

-- 浆果丛
function Transplanter:IsBerryBush(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "berry_bush" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("bush") or string.find(bank, "berrybush_juicy") ~= nil or string.find(bank, "berrybush") ~= nil -- berrybush2
end

-- 草
function Transplanter:IsGrass(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "grass" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("grass") or string.find(bank, "grass") ~= nil
end

-- 树枝
function Transplanter:IsSapling(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "sapling" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("sapling") or string.find(bank, "sapling") ~= nil or string.find(bank, "sapling_moon") ~= nil
end

-- 香蕉丛
function Transplanter:IsBananaBush(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "banana_bush" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("bananabush") or string.find(bank, "bananabush") ~= nil
end

-- 荆棘丛
function Transplanter:IsMarshBush(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "marsh_bush" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("marshbush") or string.find(bank, "marsh_bush") ~= nil
end

-- 石果丛
function Transplanter:IsRockAvocadoBush(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "rock_avocado_bush" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant.prefab == "rock_avocado_bush" or string.find(bank, "rock_avocado") ~= nil
end

-- 食人花
function Transplanter:IsLurePlant(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "lure_plant" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("lureplant") or string.find(bank, "eyeplant_trap") ~= nil
end

-- 蘑菇
function Transplanter:IsMushroom(plant)
    return plant:HasTag("mushroom") or
        plant.prefab == "red_mushroom" or
        plant.prefab == "green_mushroom" or
        plant.prefab == "blue_mushroom"
end

-- 多肉植物
function Transplanter:IsSucculentPlant(plant)
    return plant:HasTag("succulent")
end

-- 蕨类植物
function Transplanter:IsFernsPlant(plant)
    return plant:HasTag("fernsplant") or plant.prefab == "cave_fern"
end

-- 花
function Transplanter:IsFlower(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "flower" then
        return true
    end

    return
        plant.prefab == "flower" or
        plant.prefab == "flower_rose" or
        plant.prefab == "planted_flower" or
        plant.prefab == "flower_withered" or
        plant.prefab == "flower_evil"
end


-- 所有小植物
function Transplanter:IsSmallPlant(plant)
    return self:IsMushroom(plant) or
        self:IsSucculentPlant(plant) or
        self:IsFernsPlant(plant) or
        self:IsFlower(plant)
end

function Transplanter:CanTransplant(plant)
    local modes = self:GetTransplantModes()
    if modes == nil then
        return false
    end

    if self.inst:HasTag("occupied") then
        return false
    end

    if self:IsFarmPlant(plant) and table.contains(modes, "farm_plant") then
        return true
    elseif self:IsWeedPlant(plant) and table.contains(modes, "weed_plant") then
        return true
    elseif self:IsPlantable(plant) and table.contains(modes, "plantable") then
        return true
    elseif self:IsSmallPlantable(plant) and table.contains(modes, "small_plantable") then
        return true
    elseif self:IsLargePlantable(plant) and table.contains(modes, "large_plantable") then
        return true
    elseif self:IsSmallPlant(plant) and table.contains(modes, "small_plant") then
        return true
    end

    return false
end

return Transplanter