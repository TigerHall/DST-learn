------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    主图鉴里的 省略显示页面。

    plant_def.plantregistrysummarywidget

    ./scripts/widgets/redux/plantspage.lua

    没啥用。直接侵入 主页面节点修改才方便 。

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local Widget = require "widgets/widget"
    local Text = require "widgets/text"
    local UIAnim = require "widgets/uianim"
    local TEMPLATES = require "widgets/redux/templates"
    local Image = require "widgets/image"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 预览格子触发
    function TBAT.FARM_PLANT_BOOK:DisplayedSummarySlot(root,plant_prefab,plant_def)
        -- if TBAT.DisplayedSummarySlot then
        --     TBAT.DisplayedSummarySlot(root,plant_prefab,plant_def)
        -- end
        -- print("DisplayedSummarySlot",plant_prefab)

        --------------------------------------------------------
        --- 已经解锁
            if TBAT.FARM_PLANT_BOOK:IsPlantUnlocked(plant_prefab) then
                return
            end
        --------------------------------------------------------
        --- 隐藏不需要的元素
            for k, v in pairs(root.children) do
                for k1, v1 in pairs(v.children) do
                    local check_str = tostring(v1)
                    if string.find(check_str, "Image") == nil
                        or string.find(check_str, "locked.tex")
                        then
                        v1:Hide()
                    else
                        -- print(check_str)
                    end

                end
            end
        --------------------------------------------------------
            local text_info = root:AddChild(Text(CODEFONT,26,TBAT.FARM_PLANT_BOOK.info_txt or "水母知道些什么",{ 255/255 , 255/255 ,255/255 , 1}))
        --------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 未解锁任何阶段触发
    function TBAT.FARM_PLANT_BOOK:DisplayedUnknownPage(root,plant_prefab)
        -- if TBAT.DisplayedUnknownPage then
        --     TBAT.DisplayedUnknownPage(root,plant_prefab)
        -- end
        -- print("DisplayedUnknownPage",plant_prefab)
        local text_info = root:AddChild(Text(CODEFONT,30,TBAT.FARM_PLANT_BOOK.info_txt or "水母知道些什么",{ 255/255 , 255/255 ,255/255 , 1}))
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 解锁任意阶段后打开的页面
    -- function TBAT.FARM_PLANT_BOOK:DisplayFarmPlantPage(root,plant_prefab)
    --     if TBAT.DisplayFarmPlantPage then
    --         TBAT.DisplayFarmPlantPage(root,plant_prefab)
    --     end
    --     print("DisplayFarmPlantPage",plant_prefab)
    -- end
