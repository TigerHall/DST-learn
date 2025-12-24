-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("tbat_event.unlock_farm_plant_book_notes", function(inst,plant_prefab)
            print("event ++++ unlock_farm_plant_book_notes",plant_prefab)
            if TBAT.FARM_PLANT_BOOK:IsPlantUnlocked(plant_prefab) then
                print("event ++++ plant_prefab is already unlocked",plant_prefab)
                return
            end
            local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
            local plant_def = PLANT_DEFS[plant_prefab]
            local plantregistryinfo = plant_def.plantregistryinfo
            for i = 1, #plantregistryinfo, 1 do
                local crash_flag = pcall(function()
                    ThePlantRegistry:LearnPlantStage(plant_prefab,i)
                end)
                if not crash_flag then
                    pcall(function()
                        ThePlantRegistry:LearnPlantStage(plant_prefab,plant_def.plant_type_tag)
                    end)
                end
            end
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
        end)
    end
end)
