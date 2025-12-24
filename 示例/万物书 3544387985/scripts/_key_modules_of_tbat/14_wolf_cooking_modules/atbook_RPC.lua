local cooking = require("cooking")

AddClientModRPCHandler("ATBOOK", "chefwolfwidget", function(machine, isopen, foods_zip)
    local widget = _G.ThePlayer.HUD.controls.chefwolfwidget
    if widget then
        if isopen then
            local foods = foods_zip and DecodeAndUnzipString(foods_zip) or {}
            widget:PreShow(machine, foods)
        else
            widget:PreHide()
        end
    end
end)

AddModRPCHandler("ATBOOK", "closecontainer", function(player, container)
    if container.components.container then
        container.components.container:Close(player)
    end
end)

AddModRPCHandler("ATBOOK", "chefwolfspice", function(player, container)
    if container.components.container then
        local food = container.components.container.slots[45]
        local spice = container.components.container.slots[46]
        if food and spice then
            local product, cooktime = cooking.CalculateRecipe("portablespicer", { food.prefab, spice.prefab })

            if product then
                if food.components.stackable == nil then
                    container.components.container:RemoveItem(food):Remove()
                elseif food.components.stackable.stacksize > 1 then
                    food.components.stackable:SetStackSize(food.components.stackable.stacksize - 1)
                else
                    container.components.container:RemoveItem(food, true):Remove()
                end

                if spice.components.stackable == nil then
                    container.components.container:RemoveItem(spice):Remove()
                elseif spice.components.stackable.stacksize > 1 then
                    spice.components.stackable:SetStackSize(spice.components.stackable.stacksize - 1)
                else
                    container.components.container:RemoveItem(spice, true):Remove()
                end

                local result = SpawnPrefab(product)
                if result then
                    container.components.container:GiveItem(result, nil, container:GetPosition())
                end
            end
        end
    end
end)

AddModRPCHandler("ATBOOK", "chefwolforder", function(player, machine, data)
    if machine and machine:IsValid() and data then
        local x, y, z = machine.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 20)
        local chefwolflist = {}
        local containers = {}
        local ordernum = 5
        for _, ent in ipairs(ents) do
            if ent.components.atbook_chefwolf then
                if ordernum >= #ent.components.atbook_chefwolf.orderlist then
                    ordernum = #ent.components.atbook_chefwolf.orderlist
                    table.insert(chefwolflist, 1, ent)
                else
                    table.insert(chefwolflist, ent)
                end
            end
            if not ent.components.inventoryitem and ent.components.container then
                table.insert(containers, ent)
            end
        end

        if #chefwolflist == 0 then
            player.components.talker:Say("附近好像没有小狼大厨呢...")
            return
        end

        if #chefwolflist > 0 and ordernum == 5 then
            player.components.talker:Say("目前要做的菜太多了，小狼记不住了...")
            return
        end

        local chefwolf = chefwolflist[1]
        data = DecodeAndUnzipString(data)
        if data then
            -- 扣除食材
            local need = {}
            for _, prefab in ipairs(data.combinations) do
                if need[prefab] then
                    need[prefab] = need[prefab] + data.numcook
                else
                    need[prefab] = data.numcook
                end
            end

            for prefab, num in pairs(need) do
                local flag = false
                local count = 0
                for _, container in ipairs(containers) do
                    local enough, num_found = container.components.container:Has(prefab, num)
                    count = count + num_found
                    if enough or count >= num then
                        flag = true
                        break
                    end
                end
                if not flag then
                    player.components.talker:Say("食材不足了...")
                    return
                end
            end

            for prefab, num in pairs(need) do
                for _, container in ipairs(containers) do
                    local enough, num_found = container.components.container:Has(prefab, num)
                    container.components.container:ConsumeByName(prefab, math.min(num, num_found))
                    num = num - num_found
                    if num <= 0 then
                        break
                    end
                end
            end

            player.components.talker:Say("点菜成功！")

            chefwolf.components.atbook_chefwolf:Order(data)
        end
    end
end)

AddClientModRPCHandler("ATBOOK", "atbook_wiki", function(isopen)
    local widget = _G.ThePlayer.HUD.controls.atbook_wikiwidget
    if widget then
        if isopen then
            widget:PreShow()
        else
            widget:PreHide()
        end
    end
end)