local cache = {}
local function modconfigs(key, ...)
    if cache[key] == nil then cache[key] = GetModConfigData(key, ...) end
    return cache[key]
end

local function enddisableregentask(inst)
    inst:RemoveTag("disableregen2hm")
    inst.disableregen2hmtask = nil
end
local function healthregen(inst, self, v) if self and not self:IsDead() then self:DoDelta(v, true, "regen") end end
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim or not inst.components or inst:HasTag("player") then return inst end
    if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
        if modconfigs("boss_speed") and inst.components.locomotor then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "HappyPatchExtra", modconfigs("boss_speed"))
        end
        if modconfigs("boss_damage") and inst.components.combat then
            inst.components.combat.externaldamagemultipliers:SetModifier(inst, modconfigs("boss_damage"), "HappyPatchExtra")
        end
        if modconfigs("boss_damagetake") and inst.components.combat then
            inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1 - modconfigs("boss_damagetake"), "HappyPatchExtra")
        end
        if modconfigs("boss_maxdamagetake") and inst.components.health then
            inst.components.health:SetMaxDamageTakenPerHit(modconfigs("boss_maxdamagetake"))
        end
        if modconfigs("boss_healthregen") and inst.components.health then
            inst:DoPeriodicTask(1, healthregen, nil, inst.components.health, modconfigs("boss_healthregen"))
        end
        if modconfigs("boss_notenemyregen") and inst.components.health then
            inst:ListenForEvent("onhitother", function(inst, data)
                if data and data.target and not data.target:HasTag("epic") and not data.target:HasTag("shadowchesspiece") and not data.target:HasTag("crabking") then
                    if data.target.disableregen2hmtask then data.target.disableregen2hmtask:Cancel() end
                    data.target:AddTag("disableregen2hm")
                    data.target.disableregen2hmtask = data.target:DoTaskInTime(15, enddisableregentask)
                end
            end)
        end
    elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
        if modconfigs("notboss_speed") and inst.components.locomotor then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "HappyPatchExtra", modconfigs("notboss_speed"))
        end
        if modconfigs("notboss_damage") and inst.components.combat then
            inst.components.combat.externaldamagemultipliers:SetModifier(inst, modconfigs("notboss_damage"), "HappyPatchExtra")
        end
        if modconfigs("notboss_damagetake") and inst.components.combat then
            inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1 - modconfigs("notboss_damagetake"), "HappyPatchExtra")
        end
        if modconfigs("notboss_maxdamagetake") and inst.components.health then
            inst.components.health:SetMaxDamageTakenPerHit(modconfigs("notboss_maxdamagetake"))
        end
        if modconfigs("notboss_healthregen") and inst.components.health then
            inst:DoPeriodicTask(1, healthregen, nil, inst.components.health, modconfigs("notboss_healthregen"))
        end
    end
end)

if modconfigs("boss_damagetake2") or modconfigs("notboss_damagetake2") or modconfigs("boss_notenemyregen") or modconfigs("boss_health") or
    modconfigs("notboss_health") then
    local damagetake2 = modconfigs("boss_damagetake2") or modconfigs("notboss_damagetake2") or modconfigs("boss_notenemyregen")
    local health2 = modconfigs("boss_health") or modconfigs("notboss_health")
    AddComponentPostInit("health", function(self)
        if damagetake2 then
            local oldDoDelta = self.DoDelta
            self.DoDelta = function(self, amount, ...)
                local inst = self.inst
                if modconfigs("boss_notenemyregen") and not inst:HasTag("epic") and inst:HasTag("disableregen2hm") and amount > 0 then amount = 0 end
                if self.inst:HasTag("player") then return oldDoDelta(self, amount, ...) end
                if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                    if modconfigs("boss_damagetake2") and amount < 0 and not self._ignore_maxdamagetakenperhit then
                        return oldDoDelta(self, amount * (1 - modconfigs("boss_damagetake2")), ...)
                    end
                elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
                    if modconfigs("notboss_damagetake2") and amount < 0 and not self._ignore_maxdamagetakenperhit then
                        return oldDoDelta(self, amount * (1 - modconfigs("notboss_damagetake2")), ...)
                    end
                end
                return oldDoDelta(self, amount, ...)
            end
        end
        if health2 then
            if self.inst:HasTag("player") then return end
            local oldSetMaxHealth = self.SetMaxHealth
            self.SetMaxHealth = function(self, amount)
                local inst = self.inst
                if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                    if modconfigs("boss_health") then return oldSetMaxHealth(self, amount * modconfigs("boss_health")) end
                elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
                    if modconfigs("notboss_health") then return oldSetMaxHealth(self, amount * modconfigs("notboss_health")) end
                end
                return oldSetMaxHealth(self, amount)
            end
        end
    end)
end

if modconfigs("boss_notfreezable") then
    AddComponentPostInit("freezable", function(self)
        if self.inst:HasTag("player") then return end
        local oldAddColdness = self.AddColdness
        self.AddColdness = function(self, ...)
            local inst = self.inst
            if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then return end
            return oldAddColdness(self, ...)
        end
        local oldFreeze = self.Freeze
        self.Freeze = function(self, ...)
            local inst = self.inst
            if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                self.coldness = 0
                self:UpdateTint()
                return
            end
            return oldFreeze(self, ...)
        end
    end)
end

if modconfigs("boss_notsleeper") then
    AddComponentPostInit("sleeper", function(self)
        if self.inst:HasTag("player") then return end
        local oldAddSleepiness = self.AddSleepiness
        self.AddSleepiness = function(self, ...)
            local inst = self.inst
            if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then return end
            return oldAddSleepiness(self, ...)
        end
        local oldGoToSleep = self.GoToSleep
        self.GoToSleep = function(self, ...)
            local inst = self.inst
            if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                self.sleepiness = 0
                return
            end
            return oldGoToSleep(self, ...)
        end
    end)
end

if modconfigs("boss_attackspeed") or modconfigs("boss_attackrange") or modconfigs("notboss_attackspeed") or modconfigs("notboss_attackrange") then
    if modconfigs("boss_attackrange") then TUNING.DEERCLOPS_ATTACK_RANGE = TUNING.DEERCLOPS_ATTACK_RANGE * modconfigs("boss_attackrange") end
    AddComponentPostInit("combat", function(self)
        if self.inst:HasTag("player") then return end
        local inst = self.inst
        if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
            if modconfigs("boss_attackspeed") then self.min_attack_period = self.min_attack_period / modconfigs("boss_attackspeed") end
            if modconfigs("boss_attackrange") and not inst:HasTag("deerclops") then
                self.attackrange = self.attackrange * modconfigs("boss_attackrange")
                self.hitrange = self.attackrange * modconfigs("boss_attackrange")
            end
        elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
            if modconfigs("notboss_attackspeed") then self.min_attack_period = self.min_attack_period / modconfigs("notboss_attackspeed") end
            if modconfigs("notboss_attackrange") then
                self.attackrange = self.attackrange * modconfigs("notboss_attackrange")
                self.hitrange = self.hitrange * modconfigs("notboss_attackrange")
            end
        end
        if modconfigs("boss_attackspeed") or modconfigs("notboss_attackspeed") then
            local oldSetAttackPeriod = self.SetAttackPeriod
            self.SetAttackPeriod = function(self, period, ...)
                local inst = self.inst
                if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                    if modconfigs("boss_attackspeed") then
                        if period and type(period) == "table" then
                            local newperiod = {}
                            for index, value in pairs(period) do newperiod[index] = value and value / modconfigs("boss_attackspeed") end
                            return oldSetAttackPeriod(self, newperiod, ...)
                        else
                            return oldSetAttackPeriod(self, period and period / modconfigs("boss_attackspeed") or period, ...)
                        end
                    end
                elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
                    if modconfigs("notboss_attackspeed") then
                        if period and type(period) == "table" then
                            local newperiod = {}
                            for index, value in pairs(period) do
                                newperiod[index] = value and value / modconfigs("notboss_attackspeed")
                            end
                            return oldSetAttackPeriod(self, newperiod, ...)
                        else
                            return oldSetAttackPeriod(self, period and period / modconfigs("notboss_attackspeed") or period, ...)
                        end
                    end
                end
                return oldSetAttackPeriod(self, period, ...)
            end
        end
        if modconfigs("boss_attackrange") or modconfigs("notboss_attackrange") then
            local oldSetRange = self.SetRange
            self.SetRange = function(self, attack, hit, ...)
                local inst = self.inst
                if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                    if modconfigs("boss_attackrange") then
                        return oldSetRange(self, attack and attack * modconfigs("boss_attackrange") or attack,
                                           hit and hit * modconfigs("boss_attackrange") or hit, ...)
                    end
                elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
                    if modconfigs("notboss_attackrange") then
                        return oldSetRange(self, attack and attack * modconfigs("notboss_attackrange") or attack,
                                           hit and hit * modconfigs("notboss_attackrange") or hit, ...)
                    end
                end
                return oldSetRange(self, attack, hit, ...)
            end
            local oldSetAreaDamage = self.SetAreaDamage
            self.SetAreaDamage = function(self, range, ...)
                local inst = self.inst
                if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
                    if modconfigs("boss_attackrange") then
                        return oldSetAreaDamage(self, range and range * modconfigs("boss_attackrange") or range, ...)
                    end
                elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
                    if modconfigs("notboss_attackrange") then
                        return oldSetAreaDamage(self, range and range * modconfigs("notboss_attackrange") or range, ...)
                    end
                end
                return oldSetAreaDamage(self, range, ...)
            end
        end
    end)
end
if modconfigs("boss_ocean") or modconfigs("notboss_ocean") then
    AddPrefabPostInitAny(function(inst)
        if inst:HasTag("player") or not inst.Physics or not TheWorld.has_ocean then return end
        if inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking") then
            if modconfigs("boss_ocean") then
                RemovePhysicsColliders(inst)
                if inst.components.drownable then inst.components.drownable.ShouldDrown = falsefn end
                if inst.components.inventoryitem then inst.components.inventoryitem:SetSinks(false) end
            end
        elseif not modconfigs("notboss_range") or inst:HasTag("hostile") then
            if modconfigs("notboss_ocean") then
                RemovePhysicsColliders(inst)
                if inst.components.drownable then inst.components.drownable.ShouldDrown = falsefn end
                if inst.components.inventoryitem then inst.components.inventoryitem:SetSinks(false) end
            end
        end
    end)
end
