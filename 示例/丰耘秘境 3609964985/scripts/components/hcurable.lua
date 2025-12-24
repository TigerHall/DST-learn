local HCurable = Class(function(self, inst)
    self.inst = inst

    self.curemult = 1
    self.canrespawnfromghost = true
end)

function HCurable:SetCureMult(mult)
    self.curemult = mult
end

function HCurable:SetCanRespawnFromGhost(can)
    self.canrespawnfromghost = can
end

function HCurable:Cure(num)
    num = num or 10
    if self.inst:IsValid() and self.inst.components.health and self.inst.components.health:IsHurt() then
        self.inst.components.health:DoDelta(num * self.curemult)
    end

    if self.inst:HasTag("playerghost") and self.canrespawnfromghost then
        self.inst:PushEvent("respawnfromghost")
    end
end

function HCurable:DoProjCure(doer, target)
    local weapon = doer.components.combat:GetWeapon()
    if weapon:HasTag("honor_blowdart_cure") then
        weapon.components.weapon:LaunchProjectile(doer, target, "cure")
        self:Cure(TUNING.HMR_HONOR_BLOWDART_CURE_DAMAGE * TUNING.HMR_HONOR_BLOWDART_CURE_PLAYER_MULT)
    end
end

function HCurable:OnSave()
    local data =
    {
        curemult = self.curemult
    }
    return next(data) and data or nil
end

function HCurable:OnLoad(data)
    self.curemult = data.curemult
end

return HCurable