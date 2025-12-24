local Constructor = require("aab_utils/constructor")
local Utils = require("aab_utils/utils")

AddReplicableComponent("aab_attack_speed")

----------------------------------------------------------------------------------------------------

local STATES = {
    "attack",
    "blowdart"
}

local function RescaleTimeline(self, val)
    local timeline = self.currentstate and self.currentstate.timeline
    if timeline then
        for _, v in pairs(timeline) do
            if val == nil or val == 1 then
                v.time = v.aab_time or v.time
                v.aab_time = nil
            else
                v.aab_time = v.aab_time or v.time
                v.time = v.time / val
            end
        end
    end
end

AddComponentPostInit("combat", function(self)
    local OldSetAttackPeriod = self.SetAttackPeriod

    -- 根据当前攻速等比例缩放攻击间隔
    function self:SetAttackPeriod(period, ...)
        -- if not period then
        --     return OldSetAttackPeriod(self, period, ...)
        -- end

        local attack_speed = 1
        local weapon = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if weapon and weapon.components.aab_attack_speed then
            attack_speed = weapon.components.aab_attack_speed:GetAttackSpeed()
            weapon.components.aab_attack_speed.min_attack_period = period
        end

        return OldSetAttackPeriod(self, period / attack_speed, ...)
    end
end)
AddStategraphPostInit("wilson", function(sg)
    for _, state in ipairs(STATES) do
        if sg.states[state] then
            local OldOnEnter = sg.states[state] and sg.states[state].onenter
            sg.states[state].onenter = function(inst, ...)
                if OldOnEnter then
                    OldOnEnter(inst, ...)
                end


                if not inst.components.rider:IsRiding() and inst.sg.currentstate.name == state then
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    local equippablehelper = equip and equip.components.aab_attack_speed
                    local attack_speed = equippablehelper and equippablehelper:GetAttackSpeed() or 1
                    if attack_speed ~= 1 then
                        inst.AnimState:SetDeltaTimeMultiplier(attack_speed)
                        RescaleTimeline(inst.sg, attack_speed)
                        if inst.sg.timeout then
                            inst.sg:SetTimeout(inst.sg.timeout / 2)
                        end
                    end
                end
            end

            local OldOnExit = sg.states[state].onexit
            sg.states[state].onexit = function(inst, ...)
                if OldOnExit then
                    OldOnExit(inst, ...)
                end
                inst.AnimState:SetDeltaTimeMultiplier(1)
                RescaleTimeline(inst.sg)
            end
        end
    end
end)

AddStategraphPostInit("wilson_client", function(sg)
    for _, state in ipairs(STATES) do
        if sg.states[state] then
            local OldOnEnter = sg.states[state] and sg.states[state].onenter
            sg.states[state].onenter = function(inst, ...)
                if OldOnEnter then
                    OldOnEnter(inst, ...)
                end

                if not inst.replica.rider:IsRiding() and inst.sg.currentstate.name == state then
                    local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    local equippablehelper = equip and equip.components.aab_attack_speed
                    local attack_speed = equippablehelper and equippablehelper:GetAttackSpeed() or 1
                    if attack_speed ~= 1 then
                        inst.AnimState:SetDeltaTimeMultiplier(attack_speed)
                        RescaleTimeline(inst.sg, attack_speed)
                        if inst.sg.timeout then
                            inst.sg:SetTimeout(inst.sg.timeout / 2)
                        end
                    end
                end
            end

            local OldOnExit = sg.states[state].onexit
            sg.states[state].onexit = function(inst, ...)
                if OldOnExit then
                    OldOnExit(inst, ...)
                end
                inst.AnimState:SetDeltaTimeMultiplier(1)
                RescaleTimeline(inst.sg)
            end
        end
    end
end)

----------------------------------------------------------------------------------------------------

Constructor.AddAction({}, "AAB_UPGRADE_ATTACK_SPEED", AAB_L("Upgrade Attack Speed", "升级攻速"), function(act)
    local attack_speed = act.target and act.target.components.aab_attack_speed and act.target.components.aab_attack_speed.attack_speed
    if attack_speed and attack_speed < 2.5 then
        act.target.components.aab_attack_speed:SetAttackSpeed(attack_speed + 0.1)
        act.invobject.components.stackable:Get():Remove()
        if act.doer.SoundEmitter then
            act.doer.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
        end
        return true
    end
    return false
end, "domediumaction", "domediumaction")

AAB_AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if right and inst.prefab == "goldnugget" and target.replica.aab_attack_speed and target.replica.aab_attack_speed.attack_speed:value() < 2.5 then
        table.insert(actions, ACTIONS.AAB_UPGRADE_ATTACK_SPEED)
    end
end)

----------------------------------------------------------------------------------------------------

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS and inst.components.inventoryitem then
        inst:AddComponent("aab_attack_speed") --不会有预制件延迟一帧再加equippable组件吧
    end
end)

----------------------------------------------------------------------------------------------------


AddClassPostConstruct("widgets/hoverer", function(self)
    local OldSetString = self.text.SetString
    self.text.SetString = function(text, str)
        local target = TheInput:GetHUDEntityUnderMouse()
        target = (target and target.widget and target.widget.parent and target.widget.parent.item)
            or TheInput:GetWorldEntityUnderMouse()
        if not target or not target.replica or not target.components then return OldSetString(text, str) end --好像target有可能不是预制件

        -- 修改str
        if target.replica.aab_attack_speed then
            str = str .. "\n" .. AAB_L("Attack Speed: ", "攻速：") .. Utils.FormatNumber(target.replica.aab_attack_speed.attack_speed:value())
        end

        return OldSetString(text, str)
    end
end)
