------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    图鉴根节点

]]--
------------------------------------------------------------------------------------------------------------------------------------------------
---- 创建工作API根节点
    TBAT.FARM_PLANT_BOOK = Class()
    TBAT.FARM_PLANT_BOOK.data_sheet = "tbat_farm_plant_data"
    TBAT.FARM_PLANT_BOOK.info_txt = "风铃水母知道些什么"
------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function need_to_unlock_all_notes(target_plant_prefab)
        local plants = nil
        TheSim:GetPersistentString("plantregistry", function(load_success, data)
            if load_success and data ~= nil then
                local success, plant_registry = RunInSandboxSafeCatchInfiniteLoops(data)
                if success then
                    plants = plant_registry.plants
                end
            end
        end)
        if plants == nil then
            --- 空的表格
            return true
        end
        if plants[target_plant_prefab] == nil then
            --- 沒有解锁目标植物
            return true
        end
        if plants[target_plant_prefab][2] ~= true then
            --- 没解锁指定阶段
            return true
        end
        return false
    end
    function TBAT.FARM_PLANT_BOOK:IsPlantUnlocked(plant_prefab)
        if need_to_unlock_all_notes(plant_prefab) then
            return false
        end
        return true
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
------------------------------------------------------------------------------------------------------------------------------------------------
----
    AddGlobalClassPostConstruct("widgets/redux/plantspage", "PlantsPage", function(self)

        if not self.ismodded then
            return
        end

        local temp_inst = CreateEntity()
        temp_inst:DoStaticTaskInTime(0,function()
            local crash_flag,crash_reason = pcall(function()
                ---------------------------------------------------------
                ---
                    for k, temp_slot in pairs(self.plant_grid.list_root.grid.children) do
                        -------------------------------------------------
                        --- 显示格子序列
                            -- temp_slot:AddChild(Text(CODEFONT,26,tostring(k),{ 255/255 , 255/255 ,255/255 , 1}))
                        -------------------------------------------------
                        ---
                            if temp_slot.data and type(temp_slot.data.plant) == "string" then
                                local plant_prefab = temp_slot.data.plant
                                local plant_def = temp_slot.data.plant_def
                                if string.find(plant_prefab, "tbat_") ~= nil  --- 为了避免BUG，只处理本MOD的东西
                                    and string.find(plant_prefab, "_mutated") ~= nil  --- 为了避免BUG，只处理本MOD的东西
                                    then
                                        -- if TBAT.DEBUGGING then
                                        --     local text_info = temp_slot:AddChild(Text(CODEFONT,26,"变异植物",{ 255/255 , 0/255 ,0/255 , 1}))
                                        --     text_info:SetPosition(0,-50,0)
                                        --     print("变异植物",plant_prefab)
                                        --     print(plant_def.plantregistrysummarywidget)
                                        --     print(plant_def.unknownwidget)
                                        -- end
                                        TBAT.FARM_PLANT_BOOK:DisplayedSummarySlot(temp_slot,plant_prefab,plant_def)
                                    end
                            end
                        -------------------------------------------------
                    end
                ---------------------------------------------------------
            end)
            if crash_flag == false then
                print("crash_reason",crash_reason)
            end
            temp_inst:Remove()
        end)

    end)
------------------------------------------------------------------------------------------------------------------------------------------------