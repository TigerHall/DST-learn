
-- AddComponentPostInit("dockmanager", function(self)
--     -- 我希望码头可以独立存在
--     self.ResolveDockSafetyAtPoint = function() return false end
-- end)

local function CLIENT_CanDeployDockKit(inst, pt, mouseover, deployer, rotation)
    local x, y, z = pt:Get()
    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    if not IsOceanTile(tile) then --只要是海洋地皮就行
        return false
    end

    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    if not TheWorld.Map:HasAdjacentLandTile(tx, ty) then
        return false
    end

    local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tx, ty))
    return TheWorld.Map:CanDeployDockAtPoint(center_pt, inst, mouseover)
end

AddPrefabPostInit("dock_kit", function(inst)
    inst._custom_candeploy_fn = CLIENT_CanDeployDockKit -- for DEPLOYMODE.CUSTOM

    if not TheWorld.ismastersim then return end
end)
