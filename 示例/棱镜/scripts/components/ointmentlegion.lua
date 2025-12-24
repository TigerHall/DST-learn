local OintmentLegion = Class(function(self, inst)
    self.inst = inst
    -- self.noremoved = nil
    -- self.fn_check = nil
    -- self.fn_smear = nil
end)

function OintmentLegion:Check(doer, target)
    if self.fn_check ~= nil then
        return self.fn_check(self.inst, doer, target)
    end
    return false, "NOUSE"
end

function OintmentLegion:Smear(doer, target)
    if self.fn_smear ~= nil then
        self.fn_smear(self.inst, doer, target)
    end
    if doer ~= target then
        local sound = target.SoundEmitter or doer.SoundEmitter
        if sound ~= nil then
            sound:PlaySound("dontstarve/creatures/together/toad_stool/spore_grow")
        end
    end
    if not self.noremoved then
        if self.inst.components.stackable ~= nil then
            self.inst.components.stackable:Get():Remove()
        else
            self.inst:Remove()
        end
    end
end

return OintmentLegion
