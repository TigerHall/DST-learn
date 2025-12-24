local WaxWell = Class(function(self, inst)
    self.inst = inst
end)

local function ReskinPet(pet, player, nofx)
    pet._dressuptask = nil
    if player:IsValid() then
        if not nofx then
            local x, y, z = pet.Transform:GetWorldPosition()
            local fx = SpawnPrefab("slurper_respawn")
            fx.Transform:SetPosition(x, y, z)
        end
        pet.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function OnSkinsChanged(inst, data)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            if v._dressuptask ~= nil then
                v._dressuptask:Cancel()
                v._dressuptask = nil
            end
            if data and data.nofx then
                ReskinPet(v, inst, data.nofx)
            else
                v._dressuptask = v:DoTaskInTime(math.random() * 0.5 + 0.25, ReskinPet, inst)
            end
        end
    end
end

function WaxWell:OnLoad(data)
    --NOTE: Doing this outside of magician component, because we need to wait for inventory to load as well
    self.inst.components.magician:StopUsing()
    OnSkinsChanged(self.inst, { nofx = true })
end

return WaxWell
