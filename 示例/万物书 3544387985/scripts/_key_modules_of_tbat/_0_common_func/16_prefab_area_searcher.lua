--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    用于扫描 合适的 范围


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
        local function GetTargetAreaMid(search_radius,cmd_prefab_table)
            ----------------------------------------------------------
            --- 目标列表。 做两种索引模式的转置兼容。
                -- local target_prefabs = {
                --     ["rock1"] = weigh,   --- prefab + 权重
                --     ["rock2"] = weigh,
                -- }
                local target_prefabs = {}
                if type(cmd_prefab_table) ~= "table" then
                    return
                end
                for k, v in pairs(cmd_prefab_table) do
                    if type(k) == "string" then
                        target_prefabs[k] = v ~= true and v or 1
                    elseif type(v) == "string" then
                        target_prefabs[v] = (target_prefabs[v] or 0) + 1
                    end
                end
            ----------------------------------------------------------
            ---
                local all_points = {}   -- 所有坐标，每个元素是 {x, y, z} 表
            ----------------------------------------------------------
            -- 获取所有目标岩石（正确处理 GetWorldPosition 返回的三个值）
                for k, v in pairs(Ents) do
                    if v.prefab and target_prefabs[v.prefab] and v.Transform then
                        for i = 1, target_prefabs[v.prefab], 1 do --- 添加权重
                            table.insert(all_points, Vector3(v.Transform:GetWorldPosition()))
                        end
                    end
                end
            ----------------------------------------------------------
            -- 根据指定半径搜索半径内实体最多的中心点
                local MARK_RADIUS = search_radius or 80
                local radius_sq = MARK_RADIUS * MARK_RADIUS  -- 避免重复计算平方
                local max_count = 0
                local best_center = nil

                if #all_points > 0 then
                    for i = 1, #all_points do
                        local center = all_points[i]
                        local count = 0                    
                        for j = 1, #all_points do
                            local dx = center.x - all_points[j].x
                            -- local dy = center.y - all_points[j].y
                            local dz = center.z - all_points[j].z
                            local dist_sq = dx*dx + dz*dz                        
                            if dist_sq <= radius_sq then
                                count = count + 1
                            end
                        end                    
                        if count > max_count then
                            max_count = count
                            best_center = center
                        end
                    end
                    ---- 得到最佳中心点
                    -- print("Best center (max rocks in radius): " .. best_center.x .. ", " .. best_center.y .. ", " .. best_center.z)
                    -- print("Rock count: " .. max_count)
                    -- best_center = Vector3(best_center.x, best_center.y, best_center.z)
                    
                    ---- 冲洗一次坐标，获取最佳范围。
                    local ents = TheSim:FindEntities(best_center.x, 0, best_center.z,MARK_RADIUS+20)
                    local avg_x,avg_z = 0,0
                    local num = 0
                    for k, tempInst in pairs(ents) do
                        if tempInst and tempInst:IsValid() and target_prefabs[tempInst.prefab] then
                            local tx,ty,tz = tempInst.Transform:GetWorldPosition()
                            avg_x = avg_x + tx
                            avg_z = avg_z + tz
                            num = num + 1
                        end
                    end
                    return Vector3(avg_x/num,0,avg_z/num)
                else
                    -- print("No rocks found for radius search")
                end
            ----------------------------------------------------------
            return nil
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    function TBAT.FNS:PrefabAreaCenterSearch(radius,cmd)
        return GetTargetAreaMid(radius,cmd)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---