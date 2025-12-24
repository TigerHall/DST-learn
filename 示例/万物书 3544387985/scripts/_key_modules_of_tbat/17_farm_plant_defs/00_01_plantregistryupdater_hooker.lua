------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    图册记录器

    名字一会  植物名字，一会 果实名字。导致无法 解锁图册。


    PLANT_DEFS 的index 为果实名字。

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
---
    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
------------------------------------------------------------------------------------------------------------------------------------------------
-----
    -- AddComponentPostInit("plantregistryupdater", function(self)
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    AddGlobalClassPostConstruct("plantregistrydata", "PlantRegistryData", function(self)
        -------------------------------------------------------------------------
        ---
            local function fix_plant_real_name(temp_input_plant_name)
                if type(temp_input_plant_name) == "string"
                        and PLANT_DEFS[temp_input_plant_name] == nil 
                        and string.find(temp_input_plant_name, "tbat_") ~= nil  --- 为了避免BUG，只处理本MOD的东西
                    then
                    local temp_name = temp_input_plant_name
                    local _list = {}
                    for real_plant_name, data in pairs(PLANT_DEFS) do
                        if data.product == temp_name
                            -- or data.seed == temp_name
                            -- or data.seed_oversized == temp_name
                            -- or data.prefab == temp_name
                            then
                                table.insert(_list,real_plant_name)
                            end
                    end
                    if #_list > 0 then --- 寻找名字短的那个（变异的都是名字加长的）
                        local shortest = _list[1]
                        for k, temp_name in pairs(_list) do
                            if string.len(temp_name) < string.len(shortest) then
                                shortest = temp_name
                            end
                        end
                        return shortest
                    end
                end
                return temp_input_plant_name
            end

        -------------------------------------------------------------------------
        --- 做通用HOOK
            local target_apis = {
                "GetKnownPlantStages","IsAnyPlantStageKnown",
                "KnowsPlantStage","KnowsSeed","KnowsPlantName",
                "HasOversizedPicture","GetOversizedPictureData",
                "GetPlantPercent","GetLastSelectedCard","SetLastSelectedCard",
                "LearnPlantStage","TakeOversizedPicture"
            }
            for _, api_name in ipairs(target_apis) do
                if self[api_name] ~= nil then
                    local old_api_fn = self[api_name]
                    self[api_name] = function(self,plant,...)
                        -- print(api_name,plant)
                        plant = fix_plant_real_name(plant)
                        -- print("fixed",plant)
                        return old_api_fn(self, plant,...)
                    end
                end
            end
        -------------------------------------------------------------------------
        --- 处理onload / onsave
            -- local function plants_data_fix_fn()
            --     local need_to_rebuild_plants_data = false
            --     local new_plants_data = {}
            --     for plant, data in pairs(self.plants or {}) do 
            --         if PLANT_DEFS[plant] == nil then
            --             need_to_rebuild_plants_data = true
            --         else
            --             new_plants_data[plant] = data
            --         end
            --     end
            --     if need_to_rebuild_plants_data then
            --         self.plants = new_plants_data
            --     end
            -- end
            -- local old_Load = self.Load
            -- self.Load = function(self,...)
            --     old_Load(self,...)
            --     plants_data_fix_fn()
            -- end
            -- local old_Save = self.Save
            -- self.Save = function(self,...)
            --     plants_data_fix_fn()
            --     return old_Save(self,...)
            -- end
            -- local temp_inst = CreateEntity()
            -- temp_inst:DoTaskInTime(3, function()
            --     plants_data_fix_fn()
            --     temp_inst:Remove()
            --     self:Save(true)
            --     self:Load()
            --     -- print("fake error plants data refresh")
            -- end)
        -------------------------------------------------------------------------
        
        -- -------------------------------------------------------------------------
        --     local old_IsAnyPlantStageKnown = self.IsAnyPlantStageKnown
        --     self.IsAnyPlantStageKnown = function(self,plant,...)
        --         plant = fix_plant_real_name(plant)
        --         return old_IsAnyPlantStageKnown(self, plant,...)
        --     end
        -- -------------------------------------------------------------------------

    end)