--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function Set_Tile(inst,x,y,z,target_turf)
        if target_turf == "DIRT" then
            local item = inst.components.container and inst.components.container:GetItemInSlot(1)
            local turf_index = item and item.tile
            if turf_index then
                TBAT.MAP:SetTileAtPoint(x,y,z,turf_index)
                item.components.stackable:Get():Remove()
            else
                TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,target_turf)
            end
        else
            TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,target_turf)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local turf_by_seleted = {
        -- [1] = WORLD_TILES.DIRT,
        -- [2] = WORLD_TILES.OCEAN_COASTAL,
        -- [3] = WORLD_TILES.OCEAN_ROUGH,
        -- [4] = WORLD_TILES.OCEAN_HAZARDOUS,
        [1] = "DIRT",
        [2] = "OCEAN_COASTAL",
        [3] = "OCEAN_ROUGH",
        [4] = "OCEAN_HAZARDOUS",
    }
    local function remember_turf_xy(inst,tile_x,tile_y)
        inst.tile_x = tile_x
        inst.tile_y = tile_y
    end
    local function main_update_fn(inst,owner)
        local x,y,z = owner.Transform:GetWorldPosition()
        local tile_x,tile_y = TBAT.MAP:GetTileXYByWorldPoint(x,y,z)
        if inst.tile_x ~= tile_x or inst.tile_y ~= tile_y then
            local selected = inst.selected
            if selected == nil then
                remember_turf_xy(inst,tile_x,tile_y)
                return
            end
            if TheWorld.Map:IsDockAtPoint(x,y,z) then
                remember_turf_xy(inst,tile_x,tile_y)
                return
            end
            local current_is_land = TheWorld.Map:IsLandTileAtPoint(x,y,z)
            local target_turf = turf_by_seleted[selected]
            if target_turf == nil then
                remember_turf_xy(inst,tile_x,tile_y)
                return
            end
            if current_is_land and target_turf == "DIRT" then

            else
                -- TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,target_turf)
                Set_Tile(inst,x,y,z,target_turf)
            end
        end
        remember_turf_xy(inst,tile_x,tile_y)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    inst:ListenForEvent("turf_task_start",function()
        if inst.turf_task  then
            inst.turf_task:Cancel()
        end
        inst.turf_task = inst:DoPeriodicTask(0.1,function()
            local owner = inst.components.inventoryitem:GetGrandOwner()
            if owner == nil then
                inst.turf_task:Cancel()
                inst.turf_task = nil
                return
            end
            local equiped_hat = owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if equiped_hat ~= inst then
                inst.turf_task:Cancel()
                inst.turf_task = nil
                return
            end
            main_update_fn(inst,owner)
        end)
    end)
end