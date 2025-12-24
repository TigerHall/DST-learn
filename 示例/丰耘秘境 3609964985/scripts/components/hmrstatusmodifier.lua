local function Init(StatusModifier, inst)
    local weapon = inst.components.weapon
    if weapon ~= nil then
        local oldGetDamage = weapon.GetDamage
        function weapon:GetDamage(...)
            local dmg, spdmg = oldGetDamage(self, ...)
            if StatusModifier.weapon.damage ~= nil then
                dmg = StatusModifier.weapon.damage + dmg
            end
            return dmg, spdmg
        end
    end
end

local StatusModifier = Class(function(self, inst)
    self.inst = inst

    self.force_addcomponent = false

    self.armor = {
        absorb_percent_orig = nil,
        absorb_percent = nil,
        maxcondition_orig = nil,
        maxcondition = nil,
    }

    self.finiteuses = {
        total_orig = nil,
        total = nil,
    }

    self.fueled = {
        maxfuel_orig = nil,
        maxfuel = nil,
    }

    self.perishable = {
        time_left_orig = nil,
        time_left = nil,
    }

    self.tool = {
        effectiveness_orig = nil,
        effectiveness = nil,
    }

    self.weapon = {
        damage = nil,
    }

    self.equippable = {
        walkspeedmult_orig = nil,
        walkspeedmult = nil,
    }

    Init(self, inst)
end)

----------------------------------------------------------------------------
---[[护甲]armor]
----------------------------------------------------------------------------
-- 护甲防御值
function StatusModifier:GetOriginalArmorAbsorbPercent()
    if self.armor.absorb_percent_orig == nil then
        self.armor.absorb_percent_orig =
            self.inst.components.armor and
            self.inst.components.armor.absorb_percent or
            0
    end
    return self.armor.absorb_percent_orig
end

function StatusModifier:AddArmorAbsorbPercent(percent, min, max)
    local target_percent = percent

    local armor = self.inst.components.armor
    if armor ~= nil then
        if self.armor.absorb_percent_orig == nil then
            self.armor.absorb_percent_orig = armor.absorb_percent or 0
        end
        target_percent = (self.inst.components.armor.absorb_percent or 0) + percent
    end

    self:SetArmorAbsorbPercent(target_percent, min, max)
end

function StatusModifier:SetArmorAbsorbPercent(percent, min, max)
    percent = math.clamp(percent, min or 0, max or 100)
    self.armor.absorb_percent = percent

    local armor = self.inst.components.armor
    if armor == nil then
        if self.force_addcomponent then
            armor = self.inst:AddComponent("armor")
        else
            return
        end
    end
    if self.armor.absorb_percent_orig == nil then
        self.armor.absorb_percent_orig = armor.absorb_percent or 0
    end
    armor:SetAbsorption(self.armor.absorb_percent)
end

-- 护甲耐久
function StatusModifier:GetOriginalArmorMaxCondition()
    if self.armor.maxcondition_orig == nil then
        self.armor.maxcondition_orig =
            self.inst.components.armor and
            self.inst.components.armor.maxcondition or
            100
    end
    return self.armor.maxcondition_orig
end

function StatusModifier:AddArmorMaxCondition(amount, min, max)
    local target_amount = amount

    local armor = self.inst.components.armor
    if armor ~= nil then
        if self.armor.maxcondition_orig == nil then
            self.armor.maxcondition_orig = armor.maxcondition or 0
        end
        target_amount = (self.inst.components.armor.maxcondition or 0) + amount
    end

    self:SetArmorMaxCondition(target_amount, min, max)
end

function StatusModifier:SetArmorMaxCondition(amount, min, max)
    amount = math.clamp(amount, min or 0, max or 1000)
    self.armor.maxcondition = amount

    local armor = self.inst.components.armor
    if armor == nil then
        if self.force_addcomponent then
            armor = self.inst:AddComponent("armor")
        else
            return
        end
    end
    if self.armor.maxcondition_orig == nil then
        self.armor.maxcondition_orig = armor.maxcondition or 100
    end

    local perc = armor:GetPercent()
    armor.maxcondition = self.armor.maxcondition
    if perc ~= 0 then
        armor:SetPercent(perc)
    end
end

----------------------------------------------------------------------------
---[[使用finiteuses]]
----------------------------------------------------------------------------
-- 最大次数
function StatusModifier:GetOriginalFiniteUsesMaxUses()
    if self.finiteuses.total_orig == nil then
        self.finiteuses.total_orig =
            self.inst.components.finiteuses and
            self.inst.components.finiteuses.total or
            100
    end
    return self.finiteuses.total_orig
end

function StatusModifier:AddFiniteUsesMaxUses(amount, min, max)
    local target_amount = amount

    local finiteuses = self.inst.components.finiteuses
    if finiteuses ~= nil then
        if self.finiteuses.total_orig == nil then
            self.finiteuses.total_orig = finiteuses.total or 0
        end
        target_amount = (self.inst.components.finiteuses.total or 0) + amount
    end

    self:SetFiniteUsesMaxUses(target_amount, min, max)
end

function StatusModifier:SetFiniteUsesMaxUses(amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    self.finiteuses.total = amount

    local finiteuses = self.inst.components.finiteuses
    if finiteuses == nil then
        if self.force_addcomponent then
            finiteuses = self.inst:AddComponent("finiteuses")
        else
            return
        end
    end
    if self.finiteuses.total_orig == nil then
        self.finiteuses.total_orig = finiteuses.total or 100
    end

    local perc = finiteuses:GetPercent()
    finiteuses:SetMaxUses(self.finiteuses.total)
    if perc ~= 0 then
        finiteuses:SetPercent(perc)
    end
end

----------------------------------------------------------------------------
---[[使用fueled]]
----------------------------------------------------------------------------
-- 最长时间
function StatusModifier:GetOriginalFueledMaxFuel()
    if self.fueled.maxfuel_orig == nil then
        self.fueled.maxfuel_orig =
            self.inst.components.fueled and
            self.inst.components.fueled.maxfuel or
            1
    end
    return self.fueled.maxfuel_orig
end

function StatusModifier:AddFueledMaxFuel(amount, min, max)
    local target_amount = amount

    local fueled = self.inst.components.fueled
    if fueled ~= nil then
        if self.fueled.maxfuel_orig == nil then
            self.fueled.maxfuel_orig = fueled.maxfuel or 0
        end
        target_amount = (self.inst.components.fueled.maxfuel or 0) + amount
    end

    self:SetFueledMaxFuel(target_amount, min, max)
end

function StatusModifier:SetFueledMaxFuel(amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    self.fueled.maxfuel = amount

    local fueled = self.inst.components.fueled
    if fueled == nil then
        if self.force_addcomponent then
            fueled = self.inst:AddComponent("fueled")
        else
            return
        end
    end
    if self.fueled.maxfuel_orig == nil then
        self.fueled.maxfuel_orig = fueled.maxfuel or 100
    end

    local perc = fueled:GetPercent()
    fueled.maxfuel = self.fueled.maxfuel
    if perc ~= 0 then
        fueled:SetPercent(perc)
    end
end

----------------------------------------------------------------------------
---[[使用perishable]]
----------------------------------------------------------------------------
function StatusModifier:GetOriginalPerishableMaxTime()
    if self.perishable.time_orig == nil then
        self.perishable.time_orig =
            self.inst.components.perishable and
            self.inst.components.perishable.perishtime or
            0
    end
    return self.perishable.time_orig
end

function StatusModifier:AddPerishableMaxTime(amount, min, max)
    local target_amount = amount

    local perishable = self.inst.components.perishable
    if perishable ~= nil then
        if self.perishable.time_orig == nil then
            self.perishable.time_orig = perishable.perishtime or 0
        end
        target_amount = (self.inst.components.perishable.perishtime or 0) + amount
    end

    self:SetPerishableMaxTime(target_amount, min, max)
end

function StatusModifier:SetPerishableMaxTime(amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    self.perishable.time = amount

    local perishable = self.inst.components.perishable
    if perishable == nil then
        if self.force_addcomponent then
            perishable = self.inst:AddComponent("perishable")
        else
            return
        end
    end
    if self.perishable.time_orig == nil then
        self.perishable.time_orig = perishable.perishtime or 0
    end

    perishable:SetNewMaxPerishTime(self.perishable.time)
end

----------------------------------------------------------------------------
---[[工具tool]]
----------------------------------------------------------------------------
function StatusModifier:GetOriginalToolEffectiveness(action)
    if self.tool.effectiveness_orig == nil then
        self.tool.effectiveness_orig = {}
    end

    local action_id = action.id or "INVALID_ACTION"

    if self.tool.effectiveness_orig[action_id] == nil then
        self.tool.effectiveness_orig[action_id] =
            self.inst.components.tool and
            self.inst.components.tool:GetEffectiveness(action) or
            1
    end
    return self.tool.effectiveness_orig[action_id]
end

function StatusModifier:AddToolEffectiveness(action, amount, min, max)
    local target_amount = amount

    local action_id = action.id or "INVALID_ACTION"

    local tool = self.inst.components.tool
    if tool ~= nil then
        if self.tool.effectiveness_orig == nil then
            self.tool.effectiveness_orig = {}
        end
        if self.tool.effectiveness_orig[action_id] == nil then
            self.tool.effectiveness_orig[action_id] = tool:GetEffectiveness(action) or 1
        end
        target_amount = (self.inst.components.tool:GetEffectiveness(action) or 1) + amount
    end

    self:SetToolEffectiveness(action, target_amount, min, max)
end

function StatusModifier:SetToolEffectiveness(action, amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    local action_id = action.id or "INVALID_ACTION"
    self.tool.effectiveness = self.tool.effectiveness or {}
    self.tool.effectiveness[action_id] = amount

    if self.tool.effectiveness_orig == nil then
        self.tool.effectiveness_orig = {}
    end
    self.tool.effectiveness_orig[action_id] = amount

    local tool = self.inst.components.tool
    if tool == nil then
        if self.force_addcomponent then
            tool = self.inst:AddComponent("tool")
        else
            return
        end
    end

    tool.actions[action] = self.tool.effectiveness[action_id]
end

----------------------------------------------------------------------------
---[[武器weapon]]
----------------------------------------------------------------------------
function StatusModifier:AddWeaponDamage(amount, min, max)
    local target_amount = amount
    if self.weapon.damage == nil then
        self.weapon.damage = 0
    end
    target_amount = self.weapon.damage + amount
    self:SetWeaponDamage(target_amount, min, max)
end

function StatusModifier:SetWeaponDamage(amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    self.weapon.damage = amount
end

----------------------------------------------------------------------------
---[[装备equippable]]
----------------------------------------------------------------------------
function StatusModifier:GetOriginalEquippableWalkSpeed()
    if self.equippable.walkspeedmult_orig == nil then
        self.equippable.walkspeedmult_orig =
            self.inst.components.equippable and
            self.inst.components.equippable.walkspeedmult or
            1
    end
    return self.equippable.walkspeedmult_orig
end

function StatusModifier:AddEquippableWalkSpeed(amount, min, max)
    local target_amount = amount

    local equippable = self.inst.components.equippable
    if equippable ~= nil then
        if self.equippable.walkspeedmult_orig == nil then
            self.equippable.walkspeedmult_orig = equippable.walkspeedmult or 1
        end
        target_amount = (self.inst.components.equippable.walkspeedmult or 1) + amount
    end

    self:SetEquippableWalkSpeed(target_amount, min, max)
end

function StatusModifier:SetEquippableWalkSpeed(amount, min, max)
    if min and max then
        amount = math.clamp(amount, min, max)
    end
    self.equippable.walkspeedmult = HMR_UTIL.FormatNumber(amount)

    local equippable = self.inst.components.equippable
    if equippable == nil then
        if self.force_addcomponent then
            equippable = self.inst:AddComponent("equippable")
        else
            return
        end
    end
    if self.equippable.walkspeedmult_orig == nil then
        self.equippable.walkspeedmult_orig = equippable.walkspeedmult or 1
    end

    equippable.walkspeedmult = self.equippable.walkspeedmult
end

----------------------------------------------------------------------------
---[[保存状态]]
----------------------------------------------------------------------------
local function ValueOrNil(value, orig)
    if orig == nil then
        return value
    elseif value == orig then
        return nil
    else
        return value
    end
end


function StatusModifier:OnSave()
    return {
        armor = {
            absorb_percent_orig = ValueOrNil(self.armor.absorb_percent_orig, 0),
            absorb_percent = ValueOrNil(self.armor.absorb_percent),
            maxcondition_orig = ValueOrNil(self.armor.maxcondition_orig, 100),
            maxcondition = ValueOrNil(self.armor.maxcondition),
        },
        finiteuses = {
            total_orig = ValueOrNil(self.finiteuses.total_orig, 100),
            total = ValueOrNil(self.finiteuses.total),
        },
        fueled = {
            maxfuel_orig = ValueOrNil(self.fueled.maxfuel_orig, 1),
            maxfuel = ValueOrNil(self.fueled.maxfuel),
        },
        perishable = {
            time_left_orig = ValueOrNil(self.perishable.time_left_orig, 0),
            time_left = ValueOrNil(self.perishable.time_left),
        },
        tool = {
            effectiveness_orig = self.tool.effectiveness_orig,
            effectiveness = self.tool.effectiveness,
        },
        weapon = {
            damage = ValueOrNil(self.weapon.damage),
        },
        equippable = {
            walkspeedmult_orig = ValueOrNil(self.equippable.walkspeedmult_orig, 1),
            walkspeedmult = ValueOrNil(self.equippable.walkspeedmult),
        },
    }
end

function StatusModifier:OnLoad(data)
    if data ~= nil then
        if data.armor ~= nil then
            self.armor = {
                absorb_percent_orig = data.armor.absorb_percent_orig or 0,
                maxcondition_orig = data.armor.maxcondition_orig or 100,
            }
            if data.armor.absorb_percent ~= nil then
                self:SetArmorAbsorbPercent(data.armor.absorb_percent)
            end
            if data.armor.maxcondition ~= nil then
                self:SetArmorMaxCondition(data.armor.maxcondition)
            end
        end

        if data.finiteuses ~= nil then
            self.finiteuses = {
                total_orig = data.finiteuses.total_orig or 100,
            }
            if data.finiteuses.total ~= nil then
                self:SetFiniteUsesMaxUses(data.finiteuses.total)
            end
        end

        if data.fueled ~= nil then
            self.fueled = {
                maxfuel_orig = data.fueled.maxfuel_orig or 1,
            }
            if data.fueled.maxfuel ~= nil then
                self:SetFueledMaxFuel(data.fueled.maxfuel)
            end
        end

        if data.perishable ~= nil then
            self.perishable = {
                time_left_orig = data.perishable.time_left_orig or 0,
            }
            if data.perishable.time_left ~= nil then
                self:SetPerishableMaxTime(data.perishable.time_left)
            end
        end

        if data.tool ~= nil then
            self.tool = {
                effectiveness_orig = data.tool.effectiveness_orig,
            }
            if data.tool.effectiveness ~= nil then
                for action_id, effectiveness in pairs(data.tool.effectiveness) do
                    self:SetToolEffectiveness(ACTIONS[action_id], effectiveness)
                end
            end
        end

        if data.weapon ~= nil then
            if data.weapon.damage ~= nil then
                self:SetWeaponDamage(data.weapon.damage)
            end
        end

        if data.equippable ~= nil then
            self.equippable = {
                walkspeedmult_orig = data.equippable.walkspeedmult_orig or 1,
            }
            if data.equippable.walkspeedmult ~= nil then
                self:SetEquippableWalkSpeed(data.equippable.walkspeedmult)
            end
        end
    end
end

return StatusModifier