local function CanDeploy()
    return true
end

AddPrefabPostInitAny(function(inst)
    if not inst:HasTag("groundtile") then return end

    inst._custom_candeploy_fn = CanDeploy

    if not TheWorld.ismastersim then return end

    if not inst.components.deployable then
        inst:AddComponent("deployable")
    end
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
end)

----------------------------------------------------------------------------------------------------


ACTIONS.TERRAFORM.distance = 4

----------------------------------------------------------------------------------------------------

require "components/map"

Map.CanTerraformAtPoint = function() return true end

AddComponentPostInit("terraformer", function(self)
    --无地皮和海洋地皮直接相互转换
    local OldTerraform = self.Terraform
    self.Terraform = function(self, pt, doer, ...)
        if not self.inst.components.equippable then
            return OldTerraform(self, pt, doer, ...) --把耕地机排除
        end

        local world = TheWorld
        local map = world.Map
        local _x, _y, _z = pt:Get()
        local original_tile_type = map:GetTileAtPoint(_x, _y, _z)
        if original_tile_type == WORLD_TILES.DIRT then
            local old_turf = self.turf
            self.turf = WORLD_TILES.OCEAN_COASTAL
            local res = OldTerraform(self, pt, doer, ...)
            self.turf = old_turf
            return res
        else
            return OldTerraform(self, pt, doer, ...)
        end
    end
end)

----------------------------------------------------------------------------------------------------

for _, v in ipairs({
    "pitchfork",
    "goldenpitchfork"
}) do
    AddPrefabPostInit(v, function(inst)
        inst:AddTag("allow_action_on_impassable") -- Allow on ocean.
    end)
end
