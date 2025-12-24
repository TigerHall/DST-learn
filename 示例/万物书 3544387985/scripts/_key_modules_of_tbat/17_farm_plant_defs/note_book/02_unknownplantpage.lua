------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    未解锁任何阶段的显示页面。

    plant_def.unknownwidget 

    ThePlantRegistry:IsAnyPlantStageKnown(w.data.plant) == false

    具体前往 ./scripts/widgets/redux/plantspage.lua

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local PlantPageWidget = require "widgets/redux/plantpagewidget"
local Tbat_UnknownPlantPage = Class(PlantPageWidget, function(self, plantspage, data)
    PlantPageWidget._ctor(self, "Tbat_UnknownPlantPage", plantspage, data)
    --------------------------------------------------------
    --- 已经解锁
        if TBAT.FARM_PLANT_BOOK:IsPlantUnlocked(data.plant) then
            return
        end
    --------------------------------------------------------
    -- print("UnknownPlantPage",data.plant)
    TBAT.FARM_PLANT_BOOK:DisplayedUnknownPage(self,data.plant)
    
end)

return Tbat_UnknownPlantPage