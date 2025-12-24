local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WEED_DEFS = require("prefabs/weed_defs").WEED_DEFS
local FLOWERPOT_DATA_LIST = require("hmrmain/hmr_lists").FLOWERPOT_DATA_LIST

local Transplanter = Class(function(self, inst)
    self.inst = inst

    self.transplant_modes = {}
    --[[all modes:
        "farm_plant",
        "weed_plant",
        "plantable", -- all plantable items
        "small_plantable",
        "large_plantable",
    ]]
end)

function Transplanter:OnRemoveFromEntity()
    self.inst:RemoveTag("occupied")
end

function Transplanter:SetPotPrefab(prefab)
    self.pot_prefab = prefab
end

function Transplanter:SetOnDeploy(fn)
    self.ondeployfn = fn
end

function Transplanter:SetOnTransplant(fn)
    self.ontransplantfn = fn
end

function Transplanter:SetTransplantModes(modes)
    self.transplant_modes = modes
    self.inst.replica.hmrtransplanter:SetTransplantModes(modes)
end

function Transplanter:CanTransplant(mode)
    return table.contains(self.transplant_modes, mode)
end

----------------------------------------------------------------------------
---[[农作物]]
----------------------------------------------------------------------------
function Transplanter:IsFarmPlant(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "farm_plant" then
        return true
    end
    return plant:HasTag("farm_plant") and not plant:HasTag("weed")
end

function Transplanter:GetFarmPlantStageName(plant)
    if plant.plant_def ~= nil and plant.plant_def.is_randomseed then
        return "randomseed"
    end

    local stagedata = plant.components.growable ~= nil and plant.components.growable:GetCurrentStageData() or nil

    if stagedata ~= nil then
        return stagedata.name .. (plant.is_oversized and "_oversized" or "")
    end

    return "full"
end

local FARMPLANT_ANIMSET = {
    randomseed       = { anim = "sow_idle"                                              },
    seed             = { anim = "crop_seed",            grow_anim = "grow_seed"         },
    sprout           = { anim = "crop_sprout",          grow_anim = "grow_sprout"       },
    small            = { anim = "crop_small",           grow_anim = "grow_small"        },
    med              = { anim = "crop_med",             grow_anim = "grow_med"          },
    full             = { anim = "crop_full",            grow_anim = "grow_full"         },
    full_oversized   = { anim = "crop_oversized",       grow_anim = "grow_oversized"    },
    rotten           = { anim = "crop_rot",             grow_anim = "grow_rot"          },
    rotten_oversized = { anim = "crop_rot_oversized",   grow_anim = "grow_rot_oversized"},
}
for k, v in pairs(FARMPLANT_ANIMSET) do
    v.hide_symbols = {"soil01"}
end

function Transplanter:GetFarmPlantAnim(plant)
    return FARMPLANT_ANIMSET[self:GetFarmPlantStageName(plant)]
end

----------------------------------------------------------------------------
---[[杂草]]
----------------------------------------------------------------------------
function Transplanter:IsWeedPlant(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.type ~= nil and plant_data.type == "weed_plant" then
        return true
    end
    local bank = HMR_UTIL.GetAnimData(plant)

    return plant:HasTag("weed") or string.find(bank, "weed") ~= nil
end

local WEEDPLANT_ANIMSET = {
    small         = { anim = "crop_small",  grow_anim = "grow_small"  },
    small_mature  = { anim = "crop_picked", grow_anim = "grow_picked" },
    med           = { anim = "crop_med",    grow_anim = "grow_med"    },
    full          = { anim = "crop_full",   grow_anim = "grow_full"   },
    bolting       = { anim = "crop_bloomed",grow_anim = "grow_bloomed"},
}
for k, v in pairs(WEEDPLANT_ANIMSET) do
    v.hide_symbols = {"soil01"}
end

function Transplanter:GetWeedPlantStageName(plant)
    local stagedata = plant.components.growable ~= nil and plant.components.growable:GetCurrentStageData() or nil

    if stagedata ~= nil then
        if plant.mature and stagedata.name == "small" then
            return "small_mature"
        end

        return stagedata.name
    end

    return "full"
end

function Transplanter:GetWeedPlantAnim(plant)
    return WEEDPLANT_ANIMSET[self:GetWeedPlantStageName(plant)]
end

----------------------------------------------------------------------------
---[[可移栽植物]]
----------------------------------------------------------------------------
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

function Transplanter:GetPlantableStageName(plant)
    if self:IsBananaBush(plant) then
        if (plant.components.pickable ~= nil and plant.components.pickable:IsBarren()) or
            (plant.components.witherable ~= nil and plant.components.witherable:IsWithered())
        then
            return "dead"
        end

        local stagedata = plant.components.growable ~= nil and plant.components.growable:GetCurrentStageData() or nil

        if stagedata ~= nil then
            return stagedata.name
        end

        return "tall"
    elseif self:IsRockAvocadoBush(plant) then
        if (plant.components.pickable ~= nil and plant.components.pickable:IsBarren()) or
            (plant.components.witherable ~= nil and plant.components.witherable:IsWithered())
        then
            return "dead"
        end

        local stagedata = plant.components.growable ~= nil and plant.components.growable:GetCurrentStageData() or nil

        if stagedata ~= nil then
            return stagedata.name
        end

        return "stage_1"
    elseif self:IsLurePlant(plant) then
        if plant.sg ~= nil then
            if plant.sg:HasStateTag("hiding") then
                return "hiding"
            else
                return "out"
            end
        end

        return "out"
    else
        if plant.components.pickable ~= nil and plant.components.pickable:CanBePicked() then
            return "idle"
        end

        if (plant.components.pickable ~= nil and plant.components.pickable:IsBarren()) or
            (plant.components.witherable ~= nil and plant.components.witherable:IsWithered())
        then
            return "dead"
        end

        return "picked"
    end
end

local BERRYBUSH_ANIMSET = {
    idle = { anim = "idle", hide_layers = {"berries", "berriesmore"}, show_layers = {"berriesmost"}},
    picked = { anim = "idle", hide_layers = {"berries", "berriesmore", "berriesmost"}},
    dead = { anim = "dead" },
}
local GRASS_ANIMSET = {
    idle         = { anim = "idle"      },
    picked       = { anim = "picked"    },
    dead         = { anim = "idle_dead" },
}
local SAPLING_ANIMSET = {
    idle         = { anim = "sway"      },
    picked       = { anim = "empty"     },
    dead         = { anim = "idle_dead" },
}
local BANANABUSH_ANIMSET = {
    empty    = { anim = "idle_empty"  },
    small    = { anim = "idle_small"  },
    normal   = { anim = "idle_medium" },
    tall     = { anim = "idle_big"    },
    dead     = { anim = "dead"        },
}
local MARSH_BUSH_ANIMSET = {
    idle   = { anim = "idle"      },
    picked = { anim = "picked"    },
    dead   = { anim = "idle_dead" },
}
local ROCK_AVOCADO_BUSH_ANIMSET = {
    dead   = { anim = "dead1"      },
}
for i = 1, 4 do
    ROCK_AVOCADO_BUSH_ANIMSET["stage_"..i] = { anim = "idle"..i}
end
local LURE_PLANT_ANIMSET = {
    out = { anim = "idle_out", hide_symbols = {"vine1", "vine2", "vine3", "vine4"}, override_symbols = {{"swap_dried", "meat_rack_food", "plantmeat"}} },
    hiding = { anim = "idle" },
}

function Transplanter:GetPlantableAnim(plant)
    if self:IsBerryBush(plant) then
        return BERRYBUSH_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsGrass(plant) then
        return GRASS_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsSapling(plant) then
        return SAPLING_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsBananaBush(plant) then
        return BANANABUSH_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsMarshBush(plant) then
        return MARSH_BUSH_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsRockAvocadoBush(plant) then
        return ROCK_AVOCADO_BUSH_ANIMSET[self:GetPlantableStageName(plant)]
    elseif self:IsLurePlant(plant) then
        local anim_set = LURE_PLANT_ANIMSET[self:GetPlantableStageName(plant)]
        if anim_set.anim == "idle_out" and plant.lure ~= nil and plant.lure.prefab ~= nil then
            anim_set.override_symbols[1][3] = plant.lure.prefab
        end
        return anim_set
    end
end

----------------------------------------------------------------------------
---[[小植物]]
----------------------------------------------------------------------------
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

local SUCCULENT_ANIMSET = {}
for i = 1, 5 do
    SUCCULENT_ANIMSET["id_"..i] = { anim = "idle", override_symbols = {{"Symbol_1", "succulent", "Symbol_"..tostring(i)}}}
end

local FERN_ANIMSET = {}
for i = 1, 10 do
    FERN_ANIMSET["id_f"..i] = { anim = "f"..tostring(i) }
end

local FLOWER_ANIMSET = {}
for i = 1, 10 do -- 恶魔花8种，普通花10种，通用
    FLOWER_ANIMSET["id_f"..i] = { anim = "f"..tostring(i) }
end

function Transplanter:GetSmallPlantAnim(plant)
    local plant_data = FLOWERPOT_DATA_LIST[plant.prefab]
    if plant_data ~= nil and plant_data.anim_set ~= nil then
        return plant_data.anim_set
    end
    if self:IsMushroom(plant) then
        return nil
    elseif self:IsSucculentPlant(plant) then
        return SUCCULENT_ANIMSET["id_"..plant.plantid]
    elseif self:IsFernsPlant(plant) then
        return FERN_ANIMSET["id_"..plant.animname]
    elseif self:IsFlower(plant) then
        return FLOWER_ANIMSET["id_"..plant.animname]
    end
end

-- 来自于生长于地面的植物
function Transplanter:TransPlant(plant, doer)
    if self:IsFarmPlant(plant) and self:CanTransplant("farm_plant") then
        local plant_data
        for k, v in pairs(PLANT_DEFS) do
            if v.prefab == plant.prefab then
                plant_data = v
                break
            end
        end

        if plant_data ~= nil then
            local pot_data = {
                prefab = plant.prefab,
                skindata = {build = plant:GetSkinBuild(), id = plant.skin_id}, -- 看看谁先给农作物做皮肤
                bank = plant_data.bank,
                build = plant_data.build,
                animdata = self:GetFarmPlantAnim(plant),
                scale = plant.scale or 1, -- 农作物受压力值影响会改变大小
            }
            self:SetPotData(pot_data)

            local name = self:CreateName(plant)
            self:SetName(name)

            if self.ontransplantfn ~= nil then
                self.ontransplantfn(self.inst, pot_data, plant, doer)
            end

            self.inst:AddTag("occupied")

            -- plant:Remove() -- 在ontransplantfn中移除
            return true
        end
    end

    if self:IsWeedPlant(plant) and self:CanTransplant("weed_plant") then
        local plant_data
        for k, v in pairs(WEED_DEFS) do
            if v.prefab == plant.prefab then
                plant_data = v
                break
            end
        end

        if plant_data ~= nil then
            local pot_data = {
                prefab = plant.prefab,
                skindata = {build = plant:GetSkinBuild(), id = plant.skin_id}, -- 看看谁先给杂草做皮肤
                bank = plant_data.bank,
                build = plant_data.build,
                animdata = self:GetWeedPlantAnim(plant),
                -- scale = plant.scale or 1, -- 杂草受压力值影响会改变大小
            }
            self:SetPotData(pot_data)

            local name = self:CreateName(plant)
            self:SetName(name)

            if self.ontransplantfn ~= nil then
                self.ontransplantfn(self.inst, pot_data, plant, doer)
            end

            self.inst:AddTag("occupied")

            -- plant:Remove() -- 在ontransplantfn中移除
            return true
        end
    end

    if (self:IsPlantable(plant) and self:CanTransplant("plantable")) or
        (self:IsSmallPlantable(plant) and self:CanTransplant("small_plantable")) or
        (self:IsLargePlantable(plant) and self:CanTransplant("large_plantable"))
    then
        local bank, build = HMR_UTIL.GetAnimData(plant)

        local pot_data = {
            prefab = plant.prefab,
            skindata = {build = plant:GetSkinBuild(), id = plant.skin_id, name = plant:GetSkinName()},
            bank = bank or plant.prefab,
            build = build or plant.build,
            animdata = self:GetPlantableAnim(plant),
        }
        self:SetPotData(pot_data)

        local name = self:CreateName(plant)
        self:SetName(name)

        if self.ontransplantfn ~= nil then
            self.ontransplantfn(self.inst, pot_data, plant, doer)
        end

        self.inst:AddTag("occupied")

        -- plant:Remove() -- 在ontransplantfn中移除
        return true
    end

    if self:IsSmallPlant(plant) and self:CanTransplant("small_plant") then
        local bank, build, anim = HMR_UTIL.GetAnimData(plant)

        local pot_data = {
            prefab = plant.prefab,
            skindata = {build = plant:GetSkinBuild(), id = plant.skin_id, name = plant:GetSkinName()},
            bank = bank or plant.prefab,
            build = build or plant.build,
            animdata = self:GetSmallPlantAnim(plant) or { anim = anim or "idle" },
        }
        self:SetPotData(pot_data)

        local name = self:CreateName(plant)
        self:SetName(name)

        if self.ontransplantfn ~= nil then
            self.ontransplantfn(self.inst, pot_data, plant, doer)
        end

        self.inst:AddTag("occupied")

        -- plant:Remove() -- 在ontransplantfn中移除
        return true
    end

    return false
end

-- 来自于花盆
function Transplanter:SetPotData(pot_data)
    self.pot_data = pot_data
    self.inst.replica.hmrtransplanter:SetPotData(pot_data)
end

function Transplanter:GetPotData()
    return self.pot_data
end

function Transplanter:DeployPot(doer, pos, rot)
    local pot = SpawnPrefab(self.pot_prefab)
    pos = pos or doer:GetPosition()
    pot.Transform:SetPosition(pos:Get())
    pot.Transform:SetRotation(rot or doer:GetRotation())
    if self.pot_data ~= nil then
        pot.pot_data = deepcopy(self.pot_data)
        pot:SpawnPlantFx(self.pot_data)
        -- self.inst:Remove() -- 在ondeployfn中移除
    end
    if self.ondeployfn ~= nil then
        self.ondeployfn(self.inst, pot, doer, pos)
    end
end

function Transplanter:CreateName(plant)
    local name = (plant.components.named ~= nil and plant.components.named.name) or
        STRINGS.NAMES[string.upper(plant.prefab)] or
        plant:GetDisplayName()

    -- 无效的名字
    if name == nil and plant ~= nil or name == "MISSING NAME" then
        return STRINGS.HMR.FLOWERPOT.UNKNOWN_PLANT
    end

    if self:IsFarmPlant(plant) then
        name = string.format(STRINGS.HMR.FLOWERPOT[string.upper(self:GetFarmPlantStageName(plant))], name)
    end

    -- 获取物品形容词
    local adj = plant:GetAdjective()
    if adj ~= nil then
        name = adj .. name
    end

    return STRINGS.HMR.FLOWERPOT.ADJ_PRE .. " ".. name .. STRINGS.HMR.FLOWERPOT.ADJ_PST .. " " .. (STRINGS.NAMES[string.upper(self.inst.prefab)] or self.inst:GetDisplayName())
end

function Transplanter:SetName(name)
    self.name = name
    self.inst.replica.hmrtransplanter:SetName(name)
end

-- 不能保存函数和userdata
function Transplanter:OnSave()
    local data = {
        pot_data = self.pot_data,
        name = self.name,
    }
    return data
end

function Transplanter:OnLoad(data)
    self.pot_data = data.pot_data
    if self.pot_data ~= nil then
        if self.ontransplantfn ~= nil then
            self.inst:DoTaskInTime(0, function() self.ontransplantfn(self.inst, self.pot_data) end)
        end

        self.inst.replica.hmrtransplanter:SetPotData(self.pot_data)
        self.inst:AddTag("occupied")
    end

    if data.name ~= nil then
        self:SetName(data.name)
    end
end

return Transplanter