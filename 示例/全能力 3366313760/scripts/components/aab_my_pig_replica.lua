local MyPig = Class(function(self, inst)
    self.inst = inst

    self.current = net_ushortint(inst.GUID, "aab_my_pig.current")
    self.pig = net_entity(inst.GUID, "aab_my_pig.pig")
end)

function MyPig:SetCurrent(current)
    self.current:set(current)
end

function MyPig:GetCurrent()
    return self.current:value()
end

function MyPig:SetPig(pig)
    self.pig:set(pig)
end

function MyPig:GetPig()
    return self.pig:value()
end

return MyPig
