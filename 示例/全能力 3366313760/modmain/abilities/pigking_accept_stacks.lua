for _, v in ipairs({
    "pigking",
    "lg_shopfish" --海传瑞克五代
}) do
    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader and not inst.components.trader:IsAcceptingStacks() and inst.components.trader.onaccept then
            inst.components.trader:SetAcceptStacks()

            --执行好几遍没问题的，state里面没有重要的逻辑，但是一次生成太多，有些玩家的电脑会卡，尤其是圣诞活动下的猪王
            local OldOnGetItemFromPlayer = inst.components.trader.onaccept
            inst.components.trader.onaccept = function(inst, giver, item, ...)
                for i = 1, GetStackSize(item) do
                    OldOnGetItemFromPlayer(inst, giver, item, ...)
                end
            end
        end
    end)
end
