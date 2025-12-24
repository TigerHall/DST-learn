local function OnEquipped(inst, data)
    local self = inst.components.aab_attack_speed
    if data and data.owner and data.owner.components.combat then
        self.min_attack_period = data.owner.components.combat and data.owner.components.combat.min_attack_period or nil
        data.owner.components.combat:SetAttackPeriod(self.min_attack_period) --刷新一下
    end
end
local function OnUnequipped(inst, data)
    local self = inst.components.aab_attack_speed
    if data and data.owner and data.owner.components.combat then
        data.owner.components.combat:SetAttackPeriod(self.min_attack_period) --刷新一下
        self.min_attack_period = nil
    end
end

local function onattack_speed(self, attack_speed)
    self.inst.replica.aab_attack_speed.attack_speed:set(attack_speed)
end

local AttackSpeed = Class(function(self, inst)
    self.inst = inst

    self.attack_speed = 1        --攻速倍率，只针对手持武器
    self.min_attack_period = nil --真正的攻击间隔

    inst:ListenForEvent("equipped", OnEquipped)
    inst:ListenForEvent("unequipped", OnUnequipped)
end, nil, {
    attack_speed = onattack_speed
})

function AttackSpeed:GetOwner()
    return self.inst.components.equippable and self.inst.components.equippable:IsEquipped()
        and self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
end

function AttackSpeed:GetAttackSpeed()
    return self.attack_speed
end

function AttackSpeed:SetAttackSpeed(mult)
    if self.attack_speed then
        self.attack_speed = mult

        local owner = self:GetOwner()
        if owner and owner.components.combat then
            owner.components.combat:SetAttackPeriod(self.min_attack_period) --刷新一下
        end
    end
end

function AttackSpeed:OnSave()
    return {
        attack_speed = self.attack_speed
    }
end

function AttackSpeed:OnLoad(data)
    if not data then return end

    if data.attack_speed then
        self.attack_speed = data.attack_speed
    end
end

return AttackSpeed
