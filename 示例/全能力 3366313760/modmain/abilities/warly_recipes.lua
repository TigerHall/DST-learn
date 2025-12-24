AddGamePostInit(function()
    AAB_ReplaceCharacterLines("warly")
end)

AddPlayerPostInit(function(inst)
    if inst.prefab == "warly" then return end

    inst:AddTag("masterchef")
    inst:AddTag("professionalchef")
    inst:AddTag("expertchef")
end)

----------------------------------------------------------------------------------------------------
-- masterchef标签导致每次吃东西都说“超好吃”，不要每次都说啊

-- components/wisecracker.lua代码拷贝
local function OnEat(inst, data)
    if data.food ~= nil and data.food.components.edible ~= nil then
        if data.food.prefab == "spoiled_food" then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SPOILED"))
        elseif data.food.components.edible:GetHealth(inst) < 0 and
            data.food.components.edible:GetSanity(inst) <= 0 and
            not (inst.components.eater ~= nil and (
                inst.components.eater.strongstomach and
                data.food:HasTag("monstermeat") or
                inst.components.eater.healthabsorption == 0
            )) and not (inst.components.foodaffinity and inst.components.foodaffinity:HasPrefabAffinity(data.food)) then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "PAINFUL"))
        elseif data.food.components.perishable ~= nil then
            if data.food.components.perishable:IsFresh() then
                local ismasterchef = inst:HasTag("masterchef") and inst.prefab == "warly" --###修改这里，只有大厨才为true
                if ismasterchef and data.food.prefab == "wetgoop" then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "PAINFUL"))
                else
                    local count = inst.components.foodmemory ~= nil and inst.components.foodmemory:GetMemoryCount(data.food.prefab) or 0
                    if count > 0 then
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SAME_OLD_" .. tostring(math.min(5, count))))
                    elseif ismasterchef then --大厨说话
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT",
                            (data.food:HasTag("masterfood") and "TASTY") or
                            (data.food:HasTag("preparedfood") and "PREPARED") or
                            (data.food.components.cookable ~= nil and "RAW") or
                            (data.food.components.perishable.perishtime == TUNING.PERISH_PRESERVED and "DRIED") or
                            "COOKED"
                        ))
                    end
                end
            elseif data.food.components.edible.degrades_with_spoilage then
                if data.food.components.perishable:IsStale() then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "STALE"))
                elseif data.food.components.perishable:IsSpoiled() then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SPOILED"))
                end
            end
        else
            local count = inst.components.foodmemory ~= nil and inst.components.foodmemory:GetMemoryCount(data.food.prefab) or 0
            if count > 0 then
                inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SAME_OLD_" .. tostring(math.min(5, count))))
            end
        end
    end
end

AddComponentPostInit("wisecracker", function(self, inst)
    local listener_fns = inst.event_listeners and inst.event_listeners.oneat and inst.event_listeners.oneat[inst]
    local OldOnEat = listener_fns and listener_fns[#listener_fns] --一般来说这最后一个函数就是组件的那个监听函数
    if OldOnEat then
        inst:RemoveEventCallback("oneat", OldOnEat)
        inst:ListenForEvent("oneat", OnEat)
    end
end)
