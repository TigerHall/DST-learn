--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    种植逻辑

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置参数准备
    -- local TIME_FOR_ONE_PLANT_SLOT = 0.07
    -- local TIME_FOR_ONE_TILE = TIME_FOR_ONE_PLANT_SLOT*10
    local TIME_FOR_ONE_PLANT_SLOT = FRAMES/2
    local TIME_FOR_ONE_TILE = TIME_FOR_ONE_PLANT_SLOT*10
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 已经种植植物判定
    local function IsPlanted(pt_or_x,yy,zz)
        local x,y,z = pt_or_x,yy,zz
        if type(pt_or_x) == "table" then
            x,y,z = pt_or_x.x,pt_or_x.y,pt_or_x.z
        end
        local plants = TheSim:FindEntities(x,0,z,0.5,nil,nil,{"plantedsoil","farm_plant","planted_seed","plant"})
        return #plants > 0
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 清理垃圾
    local function remove_area_trush(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local musthavetags = nil
        local canthavetags = {"plantedsoil","farm_plant"}
        local musthaveoneoftags = {"plantedsoil","soil"}
        local radius = inst:GeRadius()
        local ents = TheSim:FindEntities(x, y, z , radius*1.5, musthavetags, canthavetags, musthaveoneoftags)
        for k, tempInst in pairs(ents) do
            local tx,ty,tz = tempInst.Transform:GetWorldPosition()
            local delta_x = math.abs(x - tx)
            local delta_z = math.abs(z - tz)
            if delta_x <= radius and delta_z <= radius then
                tempInst:Remove()
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 单个位置种植
    local function one_slot_do_plant(inst,item,avalable_points)
        if #avalable_points == 0 then
            return
        end
        local item_num = item.components.stackable:StackSize()
        local avalable_work_times = math.min(item_num,#avalable_points)
        if avalable_work_times <= 0 then
            return
        end
        local seed_prefab = item.prefab
        local doer = inst:GetVisualDoer()
        item.components.stackable:Get(avalable_work_times):Remove()
        for i = 1,avalable_work_times, 1 do
            local temp_inst = CreateEntity()            
            local temp_on_plant_fn = function()
                temp_inst:Remove()
                local pt = avalable_points[i]
                local seed = SpawnPrefab(seed_prefab)
                local farm_soil = SpawnPrefab("farm_soil")
                farm_soil.Transform:SetPosition(pt.x,pt.y,pt.z)
                doer.Transform:SetPosition(pt.x,pt.y,pt.z)
                seed.components.farmplantable:Plant(farm_soil,doer)
            end
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,TIME_FOR_ONE_PLANT_SLOT*i,temp_on_plant_fn)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 开始种植 入口
    local function start_farmming_work(inst,data)
        local flag,all_center_points = inst:GetAllTileCenters()
        if not flag then
            return
        end
        ------------------------------------------------------------------------------------------------------------
        --- 锁,callback
            data = data or {}
            if inst.farmming_working then
                data.succeed = false
                return
            end
            inst.farmming_working = true
            local temp_inst = CreateEntity()
            local fn = function()
                inst.farmming_working = false
                temp_inst:Remove()
            end
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,#all_center_points*TIME_FOR_ONE_TILE,fn)
            data.succeed = true
        ------------------------------------------------------------------------------------------------------------
        --- 清理垃圾
            remove_area_trush(inst)
        ------------------------------------------------------------------------------------------------------------
        --- 每个地皮里，3X3位置。间隔 1.2
            local delta = 1.2
            local plant_offsets = {
                Vector3(-delta,0,-delta) , Vector3(0,0,-delta) , Vector3(delta,0,-delta) ,
                Vector3(-delta,0,   0  ) , Vector3(0,0,0) , Vector3(delta,0,0) ,
                Vector3(-delta,0,delta) , Vector3(0,0,delta) , Vector3(delta,0,delta) ,
            }
        ------------------------------------------------------------------------------------------------------------
        --- 所有可种植点
            local all_farm_points = {} -- 所有的1号位置，都放一张表里，顺序插入。
            for i = 1, 9, 1 do
                all_farm_points[i] = {}
            end
            for i = 1, #all_center_points, 1 do
                local current_center_point = all_center_points[i]
                for j = 1, 9, 1 do
                    local current_offset = plant_offsets[j]
                    local ret_pt = Vector3(current_center_point.x + current_offset.x, 0, current_center_point.z + current_offset.z)
                    if TheWorld.Map:IsFarmableSoilAtPoint(ret_pt.x, 0, ret_pt.z) and not IsPlanted(ret_pt) then
                        table.insert(all_farm_points[j],ret_pt)
                    end
                end
            end
        ------------------------------------------------------------------------------------------------------------
        --- 开始工作
            for i = 1, 9, 1 do
                local item = inst.components.container:GetItemInSlot(i)
                if item ~= nil and item.components.farmplantable and item.components.stackable then
                    one_slot_do_plant(inst,item,all_farm_points[i])
                end
            end
        ------------------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return function(inst)
        -------------------------------------------------------------------------------
        --- 
            inst:ListenForEvent("start_farmming",start_farmming_work)
            inst:ListenForEvent("do_plant_button_clicked",start_farmming_work)
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------