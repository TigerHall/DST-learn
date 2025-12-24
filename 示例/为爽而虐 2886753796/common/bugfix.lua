local checkCause = function(self, cause)
    if cause and type(cause) ~= "string" then
        -- local str = '检测到血量变化信息错误 ' ..tostring(self.inst) .. " 来源 " .. tostring(cause) .. ", 已规避崩溃"
        -- TheNet:Announce(str)
        -- print(str .. "\n" .. TUNING.util2hm.GetStack())
        if type(cause) == "table" and cause.GetDisplayName then
            cause = cause:GetDisplayName() or cause.prefab or "unknown"
        end
    end
    return cause
end

AddComponentPostInit("health", function(health)
    local oldDoDelta = health.DoDelta
    health.DoDelta = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        cause = checkCause(self, cause)
        return oldDoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end

    local oldSetPercent = health.SetPercent
    health.SetPercent = function(self, percent, overtime, cause)
        cause = checkCause(self, cause)
        return oldSetPercent(self, percent, overtime, cause)
    end

    local oldSetVal = health.SetVal
    health.SetVal = function(self, val, cause, afflicter)
        cause = checkCause(self, cause)
        return oldSetVal(self, val, cause, afflicter)
    end
end)

AddStategraphPostInit("wilson", function(sg)
    local wathomleap = sg.states.wathomleap
    if wathomleap then
        local oldonenter = wathomleap.onenter
        wathomleap.onenter = function(inst, data)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            if target then
                local canRange = inst.components.combat:CalcAttackRangeSq(target)
                canRange = math.min(canRange * 1.2, canRange + 12)
                if inst:GetDistanceSqToInst(target) > canRange then
                    inst.sg:GoToState("knockback2hm", {
                        propsmashed = true,
                        knocker = inst,
                        radius = 3,
                        strengthmult = 1,
                    })
                    return
                end
            end
            oldonenter(inst, data)
        end
    end
end)
