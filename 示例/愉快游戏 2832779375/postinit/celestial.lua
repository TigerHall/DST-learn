

if GetModConfigData("one_celestial_task") then
    AddPrefabPostInit("moonstorm_static", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        inst:DoTaskInTime(1, function(inst)
            local _finished = inst.finished
            inst.finished = function(inst)
                local pt = inst:GetPosition()
                _finished(inst)
                inst:ListenForEvent("animover", function()
                    local item1 = SpawnPrefab("moonstorm_static_item")
                    local item2 = SpawnPrefab("moonstorm_static_item")
                    item1.Transform:SetPosition(pt.x, pt.y, pt.z)
                    item2.Transform:SetPosition(pt.x, pt.y, pt.z)
                end)
            end
        end)
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("nibility_alterguardianhat") then
    TUNING.SANITY_BECOME_ENLIGHTENED_THRESH = 0
    AddPrefabPostInit("alterguardianhat", function(inst)
        inst:AddTag("waterproofer")
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
        inst.components.insulator:SetSummer()

        if inst.components.equippable then
            inst.components.equippable.insulated = true

            local _onequip = inst.components.equippable.onequipfn
            inst.components.equippable:SetOnEquip(function(inst, owner)
                _onequip(inst, owner)

                if owner and owner:HasTag("player") then
                    owner.components.health.externalabsorbmodifiers:SetModifier(inst, 0.7)
                end

                if inst.components.container ~= nil then
                    inst.components.container:Close(owner)
                end
            end)

            local _onunequip = inst.components.equippable.onunequipfn
            inst.components.equippable:SetOnUnequip(function(inst, owner)
                _onunequip(inst, owner)

                if owner and owner:HasTag("player") then
                    owner.components.health.externalabsorbmodifiers:RemoveModifier(inst)
                end
            end)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------




























