--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    采集工作区域内的所有物品植物

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 单个区块采集
    local function harvest_single_area(inst,center_pt)
        local radius = 3
        local musthavetags = nil
        local canthavetags = nil
        local musthaveoneoftags = {"plantedsoil","farm_plant"}
        local plants = TheSim:FindEntities(center_pt.x,0,center_pt.z,radius,musthavetags,canthavetags,musthaveoneoftags)
        local work_time = 0
        local delta_time = 0.05
        for k, single_plant in pairs(plants) do
            if single_plant and single_plant.components.pickable and single_plant.components.pickable:CanBePicked() then
                local temp_inst = CreateEntity()
                local fn = function()
                    local doer = inst:GetVisualDoer()
                    if single_plant:IsValid() then
                        doer.Transform:SetPosition(single_plant.Transform:GetWorldPosition())
                        single_plant.components.pickable:Pick(doer)
                        doer.components.inventory:DropEverything()
                    end
                    temp_inst:Remove()
                end
                TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,work_time,fn)
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁巨大作物
    local function destroy_huge_plant(inst,center_pt)
        local radius = 3
        local musthavetags = nil
        local canthavetags = nil
        local musthaveoneoftags = {"plantedsoil","farm_plant","heavy","_inventoryitem","oversized_veggie"}
        local plants = TheSim:FindEntities(center_pt.x,0,center_pt.z,radius,musthavetags,canthavetags,musthaveoneoftags)
        local ret_targets = {}
        for k, single_plant in pairs(plants) do 
            if single_plant 
                and single_plant.components.workable and single_plant.components.workable:CanBeWorked()
                and single_plant.components.inventoryitem and single_plant.components.inventoryitem.owner == nil
                and single_plant.entity:GetParent() == nil then
                    table.insert(ret_targets,single_plant)
                end
        end
        if #ret_targets == 0 then
            return
        end
        for k, plant in pairs(ret_targets) do
            local temp_inst = CreateEntity()
            local fn = function()
                if plant:IsValid() then
                    local doer = inst:GetVisualDoer()
                    doer.Transform:SetPosition(plant.Transform:GetWorldPosition())
                    plant.components.workable:Destroy(doer)
                end
                temp_inst:Remove()
            end
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,k*0.06,fn)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 入口
    local function start_havest(inst,data)
        local flag,all_center_points = inst:GetAllTileCenters()
        if not flag then
            return
        end
        ------------------------------------------------------------------------------------------
        --- 锁
            data = data or {}
            if inst.havest_working  then
                data.succeed = false
                return
            end
            inst.havest_working = true
            data.succeed = true
        ------------------------------------------------------------------------------------------

        local avalable_center_points = {}
        local max_time = 0
        for index, pt in pairs(all_center_points) do
            if TheWorld.Map:IsFarmableSoilAtPoint(pt.x, 0, pt.z) then
                local temp_inst = CreateEntity()
                local fn = function()
                    harvest_single_area(inst,pt)
                    temp_inst:Remove()
                end
                local current_time = (index-1)*0.06
                max_time = math.max(max_time,current_time)
                TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,current_time,fn)
            end
        end
        for index, pt in pairs(all_center_points) do
            local tempInst = CreateEntity()
            local fn = function()
                destroy_huge_plant(inst,pt)
                tempInst:Remove()
            end
            local current_time = (index-1)*0.06 + max_time
            max_time = math.max(max_time,current_time)
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(tempInst,current_time,fn)
        end
        ------------------------------------------------------------------------------------------
        --- 解锁
            local temp_inst = CreateEntity()
            local fn = function()
                inst.havest_working = false
                temp_inst:Remove()
            end
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,max_time + 1,fn)
        ------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return function(inst)
        inst:ListenForEvent("start_havest",start_havest)
        inst:ListenForEvent("do_pick_button_clicked",start_havest)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------