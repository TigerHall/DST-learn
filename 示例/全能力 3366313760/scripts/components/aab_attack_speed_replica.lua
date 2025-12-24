local AttackSpeed = Class(function(self, inst)
    self.inst = inst

    self.attack_speed = net_float(self.inst.GUID, "aab_attack_speed.attack_speed") --攻击速度
end)

return AttackSpeed
