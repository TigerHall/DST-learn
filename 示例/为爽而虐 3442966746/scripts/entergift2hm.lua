return function(inst)
    local gifts = {}
    table.insert(gifts, "smallcandy2hm")
    table.insert(gifts, "smallcandy2hm")
    table.insert(gifts, "diviningrod2hm") 
    if TUNING.util2hm.world_level == -6 then
        table.insert(gifts, "boat_grass_item")
        table.insert(gifts, "oar_monkey")
    end
    if #gifts > 0 and inst.components.inventory then
        local gift = SpawnPrefab("gift")
        local oldFunc = gift.components.unwrappable.onwrappedfn
        if oldFunc then
            gift.components.unwrappable.onwrappedfn = function(inst, num, doer)
                num = 5
                return oldFunc(inst, num, doer)
            end
        end
        gift.components.unwrappable:WrapItems(gifts)
        inst:DoTaskInTime(0, function()
            inst.components.inventory:GiveItem(gift)
        end)
    end
end