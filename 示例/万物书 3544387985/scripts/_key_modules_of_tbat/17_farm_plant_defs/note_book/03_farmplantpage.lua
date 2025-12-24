------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    任意阶段解锁后，点进去的详情页面

    plant_def.plantregistrywidget

    ThePlantRegistry:IsAnyPlantStageKnown(w.data.plant) == true

    ./scripts/widgets/redux/plantspage.lua
    
]]--
------------------------------------------------------------------------------------------------------------------------------------------------
local Widget = require "widgets/widget"
local PlantPageWidget = require "widgets/redux/plantpagewidget"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local TEMPLATES = require "widgets/redux/templates"
local Image = require "widgets/image"
local Puppet = require "widgets/skinspuppet"
local FarmPlantPage = require("widgets/redux/farmplantpage")
return FarmPlantPage


--------------------------------------------------------------------------------------------------
--- 不能使用的方案，会hook掉所有的 FarmPlantPage
    -- local old_SetFocus = FarmPlantPage.SetFocus
    -- FarmPlantPage.SetFocus = function(self,...)
    --     -- print("FarmPlantPage.SetFocus",self.data.plant)
    --     if self.__tbat_hooked then

    --     else
    --         TBAT.FARM_PLANT_BOOK:DisplayFarmPlantPage(self,self.data.plant)
    --         self.__tbat_hooked = true
    --     end
    -- end
    -- return FarmPlantPage
--------------------------------------------------------------------------------------------------


-- local TBAT_FarmPlantPage = Class(PlantPageWidget, function(self, plantspage, data)
--     PlantPageWidget._ctor(self, "FarmPlantPage", plantspage, data)
--     print("fake error TBAT_FarmPlantPage",self.data.plant)
--     TBAT.FARM_PLANT_BOOK:DisplayFarmPlantPage(self,self.data.plant)
-- end)

-- -- local TBAT_FarmPlantPage = Class(FarmPlantPage, function(self,...)
-- --     FarmPlantPage._ctor(self,"TBAT_FarmPlantPage",...)


-- --     print("fake error TBAT_FarmPlantPage",self.data.plant)
-- --     TBAT.FARM_PLANT_BOOK:DisplayFarmPlantPage(self,self.data.plant)
    
-- -- end)

-- return TBAT_FarmPlantPage
