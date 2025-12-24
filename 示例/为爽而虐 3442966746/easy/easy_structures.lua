local hardmode = TUNING.hardmode2hm

-- 给所有trade行为定义一个判定逻辑(简化代码并防止一个报错)
local function giveitem2hm (inventory, giver, item, inst)
    if inst.notactive2hm then
        if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
            giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
        end
    else
        if inventory == giver.components.inventory then
            inventory:GiveActiveItem(item)
        else
            inventory:GiveItem(item, nil, inst:GetPosition())
        end
    end
end

-- 科学机器精炼材料
if GetModConfigData("Science Machine Refine Materials") then
    local materials = {
        cutgrass = {n = 3, loot = "rope"},
        rocks = {n = 3, loot = "cutstone"},
        log = {n = 4, loot = "boards"},
        cutreeds = {n = 4, loot = "papyrus"}
    }
    local function OnRefuseItem(inst, giver)
        inst.components.workable.onwork(inst)
        giver.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl2_ding")
    end
    local function forProcess(inst, recipe, giver, prefab, blackprefabs, skinname, skin_id, alt_skin_ids)
        -- 没有解锁的配方不进行制作
        if not (recipe and recipe.ingredients and giver.components.builder:KnowsRecipe(recipe)) then return false end
        -- 制作成品的素材不足,则尝试制作将其的素材作为成品进行制作,但本次期间该成品不会再尝试制作了
        if not giver.components.builder:HasIngredients(recipe) then
            table.insert(blackprefabs, prefab)
            for k, v in pairs(recipe.ingredients) do
                if v and v.type and v.type ~= prefab and not table.contains(blackprefabs, v.type) and AllRecipes[v.type] then
                    if forProcess(inst, AllRecipes[v.type], giver, prefab, blackprefabs) then return true end
                end
            end
            return false
        end
        if skinname then
            local chooseskin = recipe.chooseskin
            recipe.chooseskin = skinname
            local result = giver.components.builder:DoBuild(recipe.name, nil, nil, skinname)
            recipe.chooseskin = chooseskin
            return result
        end
        return giver.components.builder:DoBuild(recipe.name)
    end
    local function OnGivenItem(inst, giver, item)
        local inventory = inst.traderitemowner2hm and inst.traderitemowner2hm.components.container or giver.components.inventory
        if item.prototyperfn2hm then
            if item:prototyperfn2hm(inst, giver) then
                inst:PushEvent("ms_giftopened")
                if item:IsValid() then
                    giveitem2hm (inventory, giver, item, inst)
                end
                return
            end
        end

        if item.prefab == "gears" and inst.level2hm and inst.level2hm:value() < 10 then
            item.components.stackable:Get(1):Remove()
            inst.level2hm:set(inst.level2hm:value() + 1)
            local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
            shinefx.AnimState:SetTime(10 * FRAMES)
            shinefx.entity:SetParent(inst.entity)
            inst:PushEvent("ms_giftopened")
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
            return
        end
        if materials[item.prefab] and item.components.stackable and item.components.stackable.stacksize >= materials[item.prefab].n then
            local loot = materials[item.prefab].loot
            local need = materials[item.prefab].n
            inst:PushEvent("ms_giftopened")
            local level = inst.level2hm:value()
            local num = math.min(math.floor(item.components.stackable.stacksize / need), level)
            item.components.stackable:Get(need * num):Remove()
            if item:IsValid() then
                if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
            local valueidx = num
            for i = 1, num do
                local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                if spawn.components.stackable then
                    local v = math.min(valueidx, spawn.components.stackable.maxsize)
                    spawn.components.stackable:SetStackSize(v)
                    valueidx = valueidx - v
                    if valueidx <= 0 then
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                        break
                    end
                end
                if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
        elseif AllRecipes[item.prefab] and giver and giver.components.builder then
            recipe = AllRecipes[item.prefab]
            local prefab = item.prefab
            local skinname = item.skinname
            local skin_id = item.skin_id
            local alt_skin_ids = item.alt_skin_ids
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
            local hasevent
            local _SpawnPrefab = GLOBAL.SpawnPrefab
            GLOBAL.SpawnPrefab = function(name, skin, _skin_id, creator, ...)
                if name == prefab then
                    skin = skin or skinname
                    _skin_id = _skin_id or skin_id
                end
                local ent = _SpawnPrefab(name, skin, _skin_id, creator, ...)
                if name == prefab then ent.alt_skin_ids = alt_skin_ids end
                return ent
            end
            for i = 1, inst.level2hm:value(), 1 do
                if forProcess(inst, recipe, giver, prefab, {}, skinname, skin_id, alt_skin_ids) then
                    if not hasevent then
                        hasevent = true
                        inst:PushEvent("ms_giftopened")
                    end
                else
                    if not hasevent then OnRefuseItem(inst, giver) end
                    break
                end
            end
            GLOBAL.SpawnPrefab = _SpawnPrefab
        else
            OnRefuseItem(inst, giver)
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
        end
    end

    local function AcceptTest(inst, item, giver)
        if not giver or not giver.components.inventory then return false end
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if item.prototyperfn2hm then return true end
        if materials[item.prefab] and item.components.stackable then return true end
        if inst.level2hm:value() < 10 and item.prefab == "gears" then return true end
        if AllRecipes[item.prefab] and giver and giver.components.builder then return true end
        return false
    end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value() .. (inst.level2hm:value() >= 10 and " Max" or "")
        else
            return inst.name
        end
    end
    local function OnSave(inst, data) data.level = inst.level2hm and inst.level2hm:value() or 1 end
    local function OnLoad(inst, data) if data ~= nil then if data.level ~= nil then inst.level2hm:set(data.level) end end end
    AddPrefabPostInit("researchlab", function(inst)
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "researchlab.level2hm", "upgrade2hmdirty")
        if not TheWorld.ismastersim then return end
        inst.level2hm:set(1)
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            inst.traderitemowner2hm = item.components.inventoryitem and item.components.inventoryitem.owner
            if materials[item.prefab] then count = count or (materials[item.prefab].n * self.inst.level2hm:value()) end
            local result = oldAcceptGift(self, giver, item, count)
            inst.traderitemowner2hm = nil
            return result
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst.components.persistent2hm.data.id = inst.GUID
        SetOnSave2hm(inst, OnSave)
        SetOnLoad2hm(inst, OnLoad)
    end)
end

-- 炼金引擎兑换金块
if GetModConfigData("Alchemy Engine Redeem Gold Nugget") then
    local disabletrader = GetModConfigData("Alchemy Engine Redeem Gold Nugget") == -1
    local materials = {
        twigs = {n = 3, loot = "log"},
        log = {n = 1, loot = "twigs", numtogive = 2},
        redgem = {n = 2, loot = "bluegem"},
        bluegem = {n = 2, loot = "redgem"},
        purplegem = {n = 3, loot = "orangegem"},
        orangegem = {n = 3, loot = "yellowgem"},
        yellowgem = {n = 3, loot = "greengem"},
        rocks = {n = 3, loot = "flint"},
        flint = {n = 2, loot = "rocks"},
        nitre = {n = 3, loot = "goldnugget"},
        goldnugget = {n = 2, loot = "nitre"},
        cutstone = {n = 2, loot = "marble"},
        marble = {n = 1, loot = "cutstone"},
        moonrocknugget = {n = 2, proxy = "marble", loot = "moonrocknugget"},
        smallmeat = {n = 3, loot = "meat"},
        meat = {n = 1, loot = "smallmeat", numtogive = 2},
        fishmeat = {n = 1, loot = "fishmeat_small", numtogive = 2},
        fishmeat_small = {n = 3, loot = "fishmeat"},
        beefalowool = {n = 2, loot = "beardhair"},
        beardhair = {n = 2, loot = "beefalowool"},
        houndstooth = {n = 2, loot = "boneshard"},
        boneshard = {n = 2, loot = "houndstooth"},
        spoiled_food = {n = 6, loot = "poop"},
        mosquitosack = {n = 2, loot = "spidergland"},
        spidergland = {n = 2, loot = "mosquitosack"},
        steelwool = {n = 1, loot = "silk", numtogive = TUNING.DSTU and 1 or 3},
        -- 需要等级大于30
        moonglass_charged = {n = 3, loot = "purebrilliance2hm", level = 30},  -- 改为生成 purebrilliance2hm
        purebrilliance = {n = 1, loot = "moonglass_charged", numtogive = 2, level = 30},
        purebrilliance2hm = {n = 1, loot = "moonglass_charged", numtogive = 2, level = 30},  -- 支持 purebrilliance2hm 反向合成
        horrorfuel = {n = 3, loot = "dreadstone", level = 30},
        dreadstone = {n = 1, loot = "horrorfuel", numtogive = 2, level = 30},
        nightmarefuel = {n = 1, proxy = "horrorfuel", loot = "nightmarefuel", numtogive = 2, level = 30}
    }

    if TUNING.DSTU then
        materials.monstersmallmeat = {n = 3, loot = "monstermeat"}
        materials.monstermeat = {n = 1, loot = "monstersmallmeat", numtogive = 2}
    end

    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        giver.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding")
    end

    local function OnGivenItem(inst, giver, item)
        local inventory = inst.traderitemowner2hm and inst.traderitemowner2hm.components.container or giver.components.inventory
        if item.prototyperfn2hm then
            if item:prototyperfn2hm(inst, giver) then
                inst:PushEvent("ms_giftopened")
            else
                OnRefuseItem(inst, giver)
            end
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
            return
        end
        if item.prefab == "gears" and inst.level2hm and inst.level2hm:value() < 40 and item.components.stackable and item.components.stackable.stacksize >= 4 then
            item.components.stackable:Get(4):Remove()
            inst.level2hm:set(inst.level2hm:value() + 1)
            local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
            shinefx.AnimState:SetTime(10 * FRAMES)
            shinefx.entity:SetParent(inst.entity)
            inst:PushEvent("ms_giftopened")
            if item:IsValid() then
                if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
            return
        end
        if materials[item.prefab] and item.components.stackable and
            (materials[item.prefab].proxy or item.components.stackable.stacksize >= materials[item.prefab].n) then
            local level = inst.level2hm:value()
            local loot = materials[item.prefab].loot
            local proxy = materials[item.prefab].proxy
            local need = materials[item.prefab].n
            if proxy then
                local prefab = item.prefab
                if item:IsValid() then
                    giveitem2hm (inventory, giver, item, inst)
                end
                local has, num_found = giver.components.inventory:Has(proxy, need)
                if has then
                    inst:PushEvent("ms_giftopened")
                    local num = math.min(math.floor(num_found / need), level)
                    giver.components.inventory:ConsumeByName(proxy, num * need)
                    local numtogive = (materials[prefab].numtogive or 1) * num
                    local valueidx = numtogive
                    for index = 1, numtogive do
                        local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                        if spawn.components.stackable then
                            local v = math.min(valueidx, spawn.components.stackable.maxsize)
                            spawn.components.stackable:SetStackSize(v)
                            valueidx = valueidx - v
                            if valueidx <= 0 then
                                if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                                end
                                break
                            end
                        end
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                    end
                else
                    OnRefuseItem(inst, giver)
                end
            else
                inst:PushEvent("ms_giftopened")
                local num = math.min(math.floor(item.components.stackable.stacksize / need), level)
                local numtogive = (materials[item.prefab].numtogive or 1) * num
                item.components.stackable:Get(num * need):Remove()
                if item:IsValid() then
                    if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                        giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                    end
                end
                for index = 1, numtogive do
                    local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                    inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end
        elseif not disabletrader and item.components.tradable and item.components.tradable.goldvalue > 0 then
            inst:PushEvent("ms_giftopened")
            local goldvalue = item.components.tradable.goldvalue * (item.components.stackable and item.components.stackable.stacksize or 1)
            item:Remove()
            local valueidx = goldvalue
            for k = 1, goldvalue do
                local spawn = inst.components.lootdropper:SpawnLootPrefab("goldnugget")
                if spawn.components.stackable then
                    local v = math.min(valueidx, spawn.components.stackable.maxsize)
                    spawn.components.stackable:SetStackSize(v)
                    valueidx = valueidx - v
                    if valueidx <= 0 then
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                        break
                    end
                end
                if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end
        else
            OnRefuseItem(inst, giver)
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
        end
    end

    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if item.prototyperfn2hm then return true end
        if materials[item.prefab] and item.components.stackable then
            return item.components.stackable.stacksize >= (materials[item.prefab].n or 1) and
                       (materials[item.prefab].level == nil or inst.level2hm:value() >= materials[item.prefab].level)
        end
        if inst.level2hm:value() < 40 and item.prefab == "gears" and item.components.stackable and item.components.stackable.stacksize >= 4 then
            return true
        end
        return not disabletrader and item.components.tradable ~= nil and item.components.tradable.goldvalue > 0
    end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value() .. (inst.level2hm:value() >= 40 and " Max" or "")
        else
            return inst.name
        end
    end
    local function OnSave(inst, data) data.level = inst.level2hm and inst.level2hm:value() or 1 end
    local function OnLoad(inst, data) if data ~= nil then if data.level ~= nil then inst.level2hm:set(data.level) end end end
    AddPrefabPostInit("researchlab2", function(inst)
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "researchlab.level2hm", "upgrade2hmdirty")
        if not TheWorld.ismastersim then return end
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.level2hm:set(1)
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            inst.traderitemowner2hm = item.components.inventoryitem and item.components.inventoryitem.owner
            if item.prefab == "gears" and self.inst.level2hm:value() < 40 then
                count = count or 4
            elseif materials[item.prefab] and not materials[item.prefab].proxy then
                count = count or (materials[item.prefab].n * self.inst.level2hm:value())
            elseif not disabletrader and item.components.tradable ~= nil and item.components.tradable.goldvalue > 0 then
                count = count or self.inst.level2hm:value()
            end
            local result = oldAcceptGift(self, giver, item, count)
            inst.traderitemowner2hm = nil
            return result
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst.components.persistent2hm.data.id = inst.GUID
        SetOnSave2hm(inst, OnSave)
        SetOnLoad2hm(inst, OnLoad)
    end)
end

-- 灵子分解器分解道具
if GetModConfigData("Shadow Manipulator Break Down Objects") then
    local DESTSOUNDS = {
        {
            -- magic
            soundpath = "dontstarve/common/destroy_magic",
            ing = {"nightmarefuel", "livinglog"}
        },
        {
            -- cloth
            soundpath = "dontstarve/common/destroy_clothing",
            ing = {"silk", "beefalowool"}
        },
        {
            -- tool
            soundpath = "dontstarve/common/destroy_tool",
            ing = {"twigs"}
        },
        {
            -- gem
            soundpath = "dontstarve/common/gem_shatter",
            ing = {"redgem", "bluegem", "greengem", "purplegem", "yellowgem", "orangegem"}
        },
        {
            -- wood
            soundpath = "dontstarve/common/destroy_wood",
            ing = {"log", "boards"}
        },
        {
            -- stone
            soundpath = "dontstarve/common/destroy_stone",
            ing = {"rocks", "cutstone"}
        },
        {
            -- straw
            soundpath = "dontstarve/common/destroy_straw",
            ing = {"cutgrass", "cutreeds"}
        }
    }
    local DESTSOUNDSMAP = {}
    for i, v in ipairs(DESTSOUNDS) do for i2, v2 in ipairs(v.ing) do DESTSOUNDSMAP[v2] = v.soundpath end end
    DESTSOUNDS = nil

    local lastitemprefab
    local levelchance = {0.5, 0.75, 1}
    local function processspawncomponents(spawn)
        if spawn.components.finiteuses then spawn.components.finiteuses:SetPercent(0.01) end
        if spawn.components.fueled then spawn.components.fueled:SetPercent(0.01) end
        if spawn.components.armor then spawn.components.armor:SetPercent(0.01) end
        if spawn.components.perishable then spawn.components.perishable:SetPercent(TUNING.PERISH_STALE) end
    end
    local function destroystructure(inst, item, giver)
        local inventory = inst.traderitemowner2hm and inst.traderitemowner2hm.components.container or giver.components.inventory
        local recipe = AllRecipes[item.prefab]
        if recipe == nil or FunctionOrValue(recipe.no_deconstruction, item) then
            if item.components.stackable ~= nil and lastitemprefab ~= item.prefab then
                lastitemprefab = item.prefab
                item.components.stackable:Get():Remove()
            else
                lastitemprefab = item.prefab
                item:Remove()
            end
            return
        end
        local itemcomponent = item.components.finiteuses or item.components.fueled or item.components.armor or item.components.perishable
        local ingredient_percent = math.min(itemcomponent and itemcomponent:GetPercent() or 1, 1) / recipe.numtogive
        if lastitemprefab == item.prefab and item.components.stackable ~= nil then
            ingredient_percent = ingredient_percent * item.components.stackable.stacksize
        end

        -- 检查是否为精炼栏物品
        local is_refine_item = table.contains(CRAFTING_FILTERS.REFINE.recipes, item.prefab)
        if CRAFTING_FILTERS.REFINE then
            if is_refine_item then 
                ingredient_percent = ingredient_percent * 0.5
            end
        end

        for i, v in ipairs(recipe.ingredients) do
            if giver ~= nil and DESTSOUNDSMAP[v.type] ~= nil then giver.SoundEmitter:PlaySound(DESTSOUNDSMAP[v.type]) end
            if string.sub(v.type, -3) ~= "gem" or string.sub(v.type, -11, -4) == "precious" then
                local amt = v.amount * ingredient_percent * (levelchance[inst.level2hm and inst.level2hm:value()] or 0.5)
                if amt > 0 then
                    local total = math.floor(amt)
                    local valueidx = total
                    for n = 1, total do
                        local spawn = inst.components.lootdropper:SpawnLootPrefab(v.type)
                        if spawn.components.stackable then
                            local v = math.min(valueidx, spawn.components.stackable.maxsize)
                            spawn.components.stackable:SetStackSize(v)
                            valueidx = valueidx - v
                            if valueidx <= 0 then
                                processspawncomponents(spawn)
                                if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                                end
                                break
                            end
                        end
                        processspawncomponents(spawn)
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                    end
                    local chance = amt - total
                    if chance > 0 and math.random() < chance then
                        local spawn = inst.components.lootdropper:SpawnLootPrefab(v.type)
                        processspawncomponents(spawn)
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                    end
                end
            end
        end
        local item_todelete = item
        if item.components.stackable ~= nil and lastitemprefab ~= item.prefab then item_todelete = item.components.stackable:Get() end
        lastitemprefab = item.prefab
        item_todelete.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if item_todelete.components.inventory ~= nil then item_todelete.components.inventory:DropEverything() end
        if item_todelete.components.container ~= nil then item_todelete.components.container:DropEverything() end
        if item_todelete.components.spawner ~= nil and item_todelete.components.spawner:IsOccupied() then item_todelete.components.spawner:ReleaseChild() end
        if item_todelete.components.occupiable ~= nil and item_todelete.components.occupiable:IsOccupied() then
            local item_todelete = item_todelete.components.occupiable:Harvest()
            if item_todelete ~= nil then
                item_todelete.Transform:SetPosition(item.Transform:GetWorldPosition())
                item_todelete.components.inventoryitem:OnDropped()
            end
        end
        if item_todelete.components.trap ~= nil then item_todelete.components.trap:Harvest() end
        if item_todelete.components.dryer ~= nil then item_todelete.components.dryer:DropItem() end
        if item_todelete.components.harvestable ~= nil then item_todelete.components.harvestable:Harvest() end
        if item_todelete.components.stewer ~= nil then item_todelete.components.stewer:Harvest() end
        item:PushEvent("ondeconstructstructure", giver)
        item_todelete:Remove()
    end

    local function OnGivenItem(inst, giver, item)
        local inventory = inst.traderitemowner2hm and inst.traderitemowner2hm.components.container or giver.components.inventory
        inst.components.prototyper.onactivate(inst)
        giver.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
        if item.prototyperfn2hm then
            if item:prototyperfn2hm(inst, giver) then
                if item:IsValid() then
                    giveitem2hm (inventory, giver, item, inst)
                end
                return
            end
        end
        if item.prefab == "greengem" and inst.level2hm and inst.level2hm:value() < 3 then
            item.components.stackable:Get(1):Remove()
            inst.level2hm:set(inst.level2hm:value() + 1)
            local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
            shinefx.AnimState:SetTime(10 * FRAMES)
            shinefx.entity:SetParent(inst.entity)
            if item:IsValid() then
                if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
            return
        end
        destroystructure(inst, item, giver)
    end

    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        giver.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_ding")
    end

    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if item.prototyperfn2hm then return true end
        if item and item:HasAnyTag("irreplaceable", "cursed", "curse2hm") then return false end
        if item and item.prefab == "greengem" and inst.level2hm:value() >= 3 then return false end
        if item and item.components.tempequip2hm then return false end
        return true
    end

    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value() .. (inst.level2hm:value() >= 3 and " Max" or "")
        else
            return inst.name
        end
    end
    local function OnSave(inst, data) data.level = inst.level2hm and inst.level2hm:value() or 1 end
    local function OnLoad(inst, data) if data ~= nil then if data.level ~= nil then inst.level2hm:set(data.level) end end end
    AddPrefabPostInit("researchlab4", function(inst)
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "researchlab.level2hm", "upgrade2hmdirty")
        if not TheWorld.ismastersim then return end
        inst.level2hm:set(1)
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(inst, giver, item, count)
            if item == nil then return end
            inst.traderitemowner2hm = item.components.inventoryitem and item.components.inventoryitem.owner
            if item.components.stackable and item.prefab == lastitemprefab then count = item.components.stackable.stacksize end
            local result = oldAcceptGift(inst, giver, item, count)
            inst.traderitemowner2hm = nil
            return result
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst.components.persistent2hm.data.id = inst.GUID
        SetOnSave2hm(inst, OnSave)
        SetOnLoad2hm(inst, OnLoad)
    end)
end

-- 暗影操控器兑换暗影魔法
if GetModConfigData("Prestihatitator Redeem shadowmagic Tag") then

    -- 获得vip效果：暗影标签，魔术师标签和组件，读书消耗减少为1倍
    local function apply_shadowmagic(inst)
        if not inst.components.persistent2hm then
            inst:AddComponent("persistent2hm")
        end
        if not inst:HasTag("shadowmagic") then 
            inst:AddTag("shadowmagic") 
            inst.components.persistent2hm.data.shadowmagic_tag = true
        end
        if not inst:HasTag("magician") then 
            inst:AddTag("magician")
            inst.components.persistent2hm.data.magician_tag = true 
        end
        if not inst.components.magician then 
            inst:AddComponent("magician") 
            inst.components.persistent2hm.data.magician_component = true
        end
        if inst.components.reader ~= nil and (inst.components.reader.sanity_mult or 1) > 1 then
            inst.components.reader:SetSanityPenaltyMultiplier(1)   
            inst.components.persistent2hm.data.reader_sanity = true 
        end
    end

    -- 暗影秘典施法速度翻倍 
    AddStategraphPostInit("wilson", function(sg)
        for _, statename in ipairs({"book", "book2"}) do
            local state = sg.states[statename]
            if state and not state.shadowmagic_speedup2hm then
                state.shadowmagic_speedup2hm = true
                local onenter = state.onenter
                state.onenter = function(stateInst, ...)
                    if onenter then onenter(stateInst, ...) end
                    -- 检查是否正在使用暗影秘典且玩家有暗影增强效果
                    local current_time = stateInst.components.persistent2hm.data.shadowmagic_expire_time or 0
                    if current_time > 0 and stateInst:HasTag("shadowmagic") and stateInst.bufferedaction and 
                        stateInst.bufferedaction.invobject and stateInst.bufferedaction.invobject:HasTag("shadowmagic") then
                        SpeedUpState2hm(stateInst, state, 2.0)
                    end
                end
                local onexit = state.onexit
                state.onexit = function(stateInst, ...)
                    if onexit then onexit(stateInst, ...) end
                    RemoveSpeedUpState2hm(stateInst, state, true)
                end
            end
        end
    end)

    -- 移除vip效果
    local function remove_shadow_magic(inst)
        if not inst.components.persistent2hm then return end
        if inst:HasTag("shadowmagic") and inst.components.persistent2hm.data.shadowmagic_tag then 
            inst:RemoveTag("shadowmagic") 
            inst.components.persistent2hm.data.shadowmagic_tag = nil
        end
        if inst:HasTag("magician") and inst.components.persistent2hm.data.magician_tag then 
            inst:RemoveTag("magician") 
            inst.components.persistent2hm.data.magician_tag = nil
        end
        if inst.components.magician and inst.components.persistent2hm.data.magician_component then 
            inst:RemoveComponent("magician") 
            inst.components.persistent2hm.data.magician_component = nil
        end
        if inst.components.reader ~= nil and inst.components.persistent2hm.data.reader_sanity then
            inst.components.reader:SetSanityPenaltyMultiplier(TUNING.MAXWELL_READING_SANITY_MULT) -- 恢复为2.5倍
            inst.components.persistent2hm.data.reader_sanity = nil
        end
        if inst.sg and inst.sg.currentstate then
            inst.sg:GoToState("hit_darkness")
        end
        if inst.components.talker then
            inst.components.talker:Say(TUNING.isCh2hm and "暗影的力量已经离我而去！" or "The power of shadows has left me！") 
        end
    end

    -- 接受燃料的函数
    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if item.prefab ~= "nightmarefuel" or giver == nil then return false end
        if not giver.components.persistent2hm then giver:AddComponent("persistent2hm") end
        
        local current_time = giver.components.persistent2hm.data.shadowmagic_expire_time or 0
        
        -- 检查是否需要暗影增强或者可以续期（剩余时间<=25天）
        if current_time == 0 then
            -- 没有暗影增强或已过期，需要4个燃料
            return item.components.stackable and item.components.stackable.stacksize >= 4
        elseif current_time <= 25 then
            -- 剩余时间<=25天，可以续期，只需要1个燃料
            return true
        end
        
        return false
    end

    -- 拒绝物品的函数
    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
    end

    -- 获得、续费vip的函数
    local function OnGivenItem(inst, giver, item)

        inst.components.prototyper.onactivate(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_alchemy_gift_recieve")

        if giver then
            local current_time = giver.components.persistent2hm.data.shadowmagic_expire_time or 0
            -- 检查是否有vip或需要续期
            if current_time == 0 then
                -- 首次获得或已过期，给予20天时长
                giver.components.persistent2hm.data.shadowmagic_expire_time = 20
                apply_shadowmagic(giver)
                item.components.stackable:Get(4):Remove()
                if giver.sg then
                    giver.sg:GoToState("changeoutsidewardrobe")
                end
                if giver.components.talker then
                    giver.components.talker:Say(TUNING.isCh2hm and "啊~暗影低语着我的名字..." or "The shadows whisper my name...") 
                end
            elseif current_time <= 25 then
                -- 还有剩余时间，只消耗1个燃料，增加5天
                item.components.stackable:Get(1):Remove()
                giver.components.persistent2hm.data.shadowmagic_expire_time = current_time + 5
            end
            local equip = giver.components.inventory and giver.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if equip and equip:IsValid() and equip.checkstatus2hm then equip:checkstatus2hm() end
        end
    end

    -- 更新vip天数的函数
    local function checkshadowmagic(inst)
        if not inst.components.persistent2hm then return end
        
        local current_time = inst.components.persistent2hm.data.shadowmagic_expire_time or 0
        
        -- 有效期还大于1的，减少有效期1天
        if current_time > 1 then
            inst.components.persistent2hm.data.shadowmagic_expire_time = current_time - 1
        -- 已经到期了，移除vip效果
        elseif current_time == 1 then
            inst.components.persistent2hm.data.shadowmagic_expire_time = current_time - 1
            remove_shadow_magic(inst)
        end

    end

    -- 为魔术帽添加显示暗影增强剩余时间
    local function UpdateHoverStr(inst)
        if not inst.components.magiciantool or not inst.components.hoverer2hm then return end
        local owner = inst.components.inventoryitem:GetGrandOwner()
        local current_time = 0
        if owner and owner:HasTag("player") and owner.components.persistent2hm then
            current_time = owner.components.persistent2hm.data.shadowmagic_expire_time or 0
        end
        inst.components.hoverer2hm.hoverStr = TUNING.isCh2hm and "暗影增强剩余时间：" ..current_time.. "天" or 
                                            "Shadow Magic Remaining Time: " ..current_time.. " day(s)"
    end

    local function ondropped(inst)
        inst.components.hoverer2hm.hoverStr = ""
        if inst.doUpdateHoverTask then
            inst.doUpdateHoverTask:Cancel()
            inst.doUpdateHoverTask = nil
        end
    end

    local function onputininventory(inst)
        ondropped(inst)
        UpdateHoverStr(inst)
        inst.doUpdateHoverTask = inst:WatchWorldState("cycles", function()
            inst:DoTaskInTime(0.1, function()
                UpdateHoverStr(inst)
            end)
        end)
    end

    AddPrefabPostInit("tophat", function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddComponent("hoverer2hm")
        inst:ListenForEvent("onputininventory", onputininventory)
        inst:ListenForEvent("ondropped", ondropped)
    end)

    -- 初始化角色
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end

        -- 延迟检查暗影增强状态，确保数据已经加载完毕
        inst:DoTaskInTime(0.1, function()
            if inst.components.persistent2hm.data.shadowmagic_expire_time and inst.components.persistent2hm.data.shadowmagic_expire_time > 0 then
                apply_shadowmagic(inst)
            end
        end)

        -- 每天检查暗影增强状态
        inst:WatchWorldState("cycles", function() checkshadowmagic(inst) end)

        -- 兼容其他角色召唤仆从时具有皮肤
        if inst.prefab ~= "waxwell" and inst.components.petleash then
            local oldOnSpawnPet = inst.components.petleash.onspawnfn
            inst.components.petleash:SetOnSpawnFn(function(inst, pet, ...)
                if pet and pet:HasTag("shadowminion") and pet.components.skinner and not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
                    pet.components.skinner:CopySkinsFromPlayer(inst)
                end
                return oldOnSpawnPet(inst, pet, ...)
            end)
        end

    end)

    -- 兼容其他角色使用秘典和暗影增强VIP功能
    AddPrefabPostInit("waxwelljournal", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 延迟执行，确保组件已初始化
        inst:DoTaskInTime(0, function()
            if inst.components.aoespell and inst.components.spellbook then
                local oldSetSpellFn = inst.components.aoespell.SetSpellFn
                inst.components.aoespell.SetSpellFn = function(self, fn, ...)
                    local spellname = inst.components.spellbook.spellname
                    
                    if fn then
                        -- 兼容其他角色使用暗影仆从
                        if spellname == STRINGS.SPELLS.SHADOW_WORKER or spellname == STRINGS.SPELLS.SHADOW_PROTECTOR then
                            return oldSetSpellFn(self, function(inst, doer, pos, ...)
                                if doer and doer.prefab ~= "waxwell" and doer.components.petleash and doer.components.petleash.numpets >=
                                    doer.components.petleash.maxpets then return false, "NO_MAX_SANITY" end
                                return fn(inst, doer, pos, ...)
                            end, ...)
                        -- 暗影陷阱和暗影囚笼VIP免理智消耗
                        elseif spellname == STRINGS.SPELLS.SHADOW_TRAP or spellname == STRINGS.SPELLS.SHADOW_PILLARS then
                            return oldSetSpellFn(self, function(inst, doer, pos, ...)

                                local is_vip = doer and doer.prefab == "waxwell" and doer.components.persistent2hm and 
                                              doer.components.persistent2hm.data.shadowmagic_expire_time and 
                                              doer.components.persistent2hm.data.shadowmagic_expire_time > 0
                                
                                if is_vip and doer.components.sanity then
                                    -- 保存原始的DoDelta函数
                                    local old_sanity_delta = doer.components.sanity.DoDelta
                                    doer.components.sanity.DoDelta = function(self, delta, overtime, cause, ignore_max, ...)
                                        if delta and delta < 0 then
                                            return
                                        end
                                        return old_sanity_delta(self, delta, overtime, cause, ignore_max, ...)
                                    end
                                    
                                    local result, reason = fn(inst, doer, pos, ...)
                                    
                                    -- 恢复原始的DoDelta函数
                                    doer.components.sanity.DoDelta = old_sanity_delta
                                    return result, reason
                                else
                                    return fn(inst, doer, pos, ...)
                                end
                            end, ...)
                        end
                    end
                    return oldSetSpellFn(self, fn, ...)
                end
            end
        end)

    end)

    -- 预处理暗影操纵器
    AddPrefabPostInit("researchlab3", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            if item.prefab == "nightmarefuel" then 
                local current_time = giver.components.persistent2hm and giver.components.persistent2hm.data.shadowmagic_expire_time or 0
                if current_time == 0 then
                    count = count or 4  -- 首次获得需要4个
                else
                    count = count or 1  -- 续期只需要1个
                end
            end
            return oldAcceptGift(self, giver, item, count)
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
    end)
end

-- 泰拉瑞亚宝箱彩蛋
if GetModConfigData("Terrariumchest_Extradrop") then
    local function process_upgrade(inst)
        -- 添加tempequip2hm组件
        if not inst.components.tempequip2hm then
            inst:AddComponent("tempequip2hm")
        end
        
        inst.components.tempequip2hm.onperishreplacement = nil
        inst.components.tempequip2hm:BecomePerishable()
        if inst.components.perishable then
            inst.components.perishable.localPerishMultiplyer = 0
        end

    end

    -- 处理临时道具的数据恢复
    local function processpersistent_tempequip(inst, data)
        if not data or not data.tempequip2hm then return end
        process_upgrade(inst)
    end

    AddPrefabPostInit("terrariumchest", function(inst)
        if not TheWorld.ismastersim then return end

        if inst.components.container ~= nil then inst.components.container:EnableInfiniteStackSize(true) end

        if not inst.components.workable then return end
        local oldonfinish = inst.components.workable.onfinish or nilfn
        inst.components.workable:SetOnFinishCallback(function(...)
            local loot = SpawnPrefab("chestupgrade_stacksize")
            if loot then 
                loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
                loot:DoTaskInTime(0, process_upgrade(loot))
                if loot.components.persistent2hm then
                    loot.components.persistent2hm.data.tempequip2hm = true
                end
            end
            oldonfinish(...)
        end)
    end)

    AddPrefabPostInit("chestupgrade_stacksize", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        SetOnLoad2hm(inst, function(inst, data)
            processpersistent_tempequip(inst, data)
        end)
    end)
end

-- 土地夯实器或强征传送塔兑换沙之石
local turfopt = GetModConfigData("Terra Firma Tamper Redeem Desert Stone")
if turfopt then
    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        giver.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
    end
    local function OnGivenItem(inst, giver, item)
        local inventory = inst.traderitemowner2hm and inst.traderitemowner2hm.components.container or giver.components.inventory
        if item.prototyperfn2hm then
            if item:prototyperfn2hm(inst, giver) then
                if inst.components.prototyper then inst.components.prototyper.onactivate(inst) end
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
            else
                OnRefuseItem(inst, giver)
            end
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
            return
        end
        if item.prefab == "thulecite" and inst.level2hm and inst.level2hm:value() < 40 then
            item.components.stackable:Get(1):Remove()
            inst.level2hm:set(inst.level2hm:value() + 1)
            local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
            shinefx.AnimState:SetTime(10 * FRAMES)
            shinefx.entity:SetParent(inst.entity)
            if inst.components.prototyper then inst.components.prototyper.onactivate(inst) end
            if item:IsValid() then
                if not inventory:GiveItem(item, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
            return
        end
        if item.components.tradable.goldvalue ~= nil and item.components.tradable.goldvalue > 0 then
            if inst.components.prototyper then inst.components.prototyper.onactivate(inst) end
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
            local goldvalue = item.components.tradable.goldvalue * (item.components.stackable and item.components.stackable.stacksize or 1)
            local valueidx = goldvalue
            for k = 1, goldvalue do
                local spawn = inst.components.lootdropper:SpawnLootPrefab("townportaltalisman")
                if spawn.components.stackable then
                    local v = math.min(valueidx, spawn.components.stackable.maxsize)
                    spawn.components.stackable:SetStackSize(v)
                    valueidx = valueidx - v
                    if valueidx <= 0 then
                        if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                            giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                        end
                        break
                    end
                end
                if not inventory:GiveItem(spawn, nil, inst:GetPosition()) and inventory ~= giver.components.inventory then
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end
            item:Remove()
        elseif item.components.tradable.rocktribute ~= nil and item.components.tradable.rocktribute > 0 then
            if inst.components.prototyper then inst.components.prototyper.onactivate(inst) end
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
            local rockvalue = item.components.tradable.rocktribute * (item.components.stackable and item.components.stackable.stacksize or 1)
            local valueidx = rockvalue
            for k = 1, rockvalue do
                local spawn = inst.components.lootdropper:SpawnLootPrefab("rocks")
                if spawn.components.stackable then
                    local v = math.min(valueidx, spawn.components.stackable.maxsize)
                    spawn.components.stackable:SetStackSize(v)
                    valueidx = valueidx - v
                    if valueidx <= 0 then
                        inventory:GiveItem(spawn, nil, inst:GetPosition())
                        break
                    end
                end
                inventory:GiveItem(spawn, nil, inst:GetPosition())
            end
            item:Remove()
        else
            OnRefuseItem(inst, giver)
            if item:IsValid() then
                giveitem2hm (inventory, giver, item, inst)
            end
        end
    end
    local function AcceptTest(inst, item)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if item.prototyperfn2hm then return true end
        if item.prefab == "thulecite" and inst.level2hm:value() < 40 then return true end
        return item.components.tradable ~= nil and item.components.tradable.rocktribute ~= nil and item.components.tradable.rocktribute > 0
    end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value() .. (inst.level2hm:value() >= 40 and " Max" or "")
        else
            return inst.name
        end
    end
    local function OnSave(inst, data) data.level = inst.level2hm and inst.level2hm:value() or 1 end
    local function OnLoad(inst, data) if data ~= nil then if data.level ~= nil then inst.level2hm:set(data.level) end end end
    AddPrefabPostInit(turfopt == -1 and "townportal" or "turfcraftingstation", function(inst)
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "researchlab.level2hm", "upgrade2hmdirty")
        if not TheWorld.ismastersim then return end
        inst.level2hm:set(1)
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.acceptnontradable = true
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            inst.traderitemowner2hm = item.components.inventoryitem and item.components.inventoryitem.owner
            if item.components.tradable ~= nil and item.components.tradable.rocktribute ~= nil and item.components.tradable.rocktribute > 0 then
                count = count or self.inst.level2hm:value()
            end
            local result = oldAcceptGift(self, giver, item, count)
            inst.traderitemowner2hm = nil
            return result
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst.components.persistent2hm.data.id = inst.GUID
        SetOnSave2hm(inst, OnSave)
        SetOnLoad2hm(inst, OnLoad)
    end)
end

-- 沙之石激活传送塔
if GetModConfigData("townportal use sandstone activate") then
    local function addfx(inst)
        if not inst.sandstonefx2hm then
            local fx = SpawnPrefab("reticuleaoeshadowtarget_6")
            fx.AnimState:SetMultColour(1, 1, 1, 0.5)
            fx.entity:SetParent(inst.entity)
            inst.sandstonefx2hm = fx
        end
        if inst:HasTag("channeled2hm") then
            inst.sandstonefx2hm:Show()
        else
            inst.sandstonefx2hm:Hide()
        end
    end
    AddComponentPostInit("channelable", function(self)
        local oldIsChanneling = self.IsChanneling
        self.IsChanneling = function(self, ...) return (self.inst.prefab == "townportal" and self.channeler == self.inst) or oldIsChanneling(self, ...) end
        local oldStartChanneling = self.StartChanneling
        self.StartChanneling = function(self, channeler, ...)
            if self.inst.prefab == "townportal" and channeler and channeler:IsValid() and channeler.prefab == "townportaltalisman" then
                TheWorld:PushEvent("townportaldeactivated", self.inst)
                channeler:Remove()
                self.channeler = self.inst
                if self.onchannelingfn ~= nil then self.onchannelingfn(self.inst, self.inst) end
                self.inst:StartUpdatingComponent(self)
                self.inst.components.persistent2hm.data.townportaltalisman = true
                self.inst:AddTag("channeled2hm")
                addfx(self.inst)
                return true
            end
            return oldStartChanneling(self, channeler, ...)
        end
        local oldStopChanneling = self.StopChanneling
        self.StopChanneling = function(self, aborted, ...)
            if self.inst.prefab == "townportal" and self.channeler == self.inst then
                self.inst.components.persistent2hm.data.townportaltalisman = nil
                self.inst:RemoveTag("channeled2hm")
                self.channeler = nil
                self.inst:StopUpdatingComponent(self)
                addfx(self.inst)
                if self.onstopchannelingfn ~= nil then self.onstopchannelingfn(self.inst, aborted) end
                self.inst.components.lootdropper:FlingItem(SpawnPrefab("townportaltalisman"))
                return
            end
            return oldStopChanneling(self, aborted, ...)
        end
    end)
    -- 打断正在沙之石激活的传送塔
    AddComponentAction("SCENE", "channelable", function(inst, doer, actions, right)
        if right and inst:HasTag("channelable") and inst:HasTag("channeled") and not doer:HasTag("channeling") and inst:HasTag("channeled2hm") then
            if ACTIONS.STOPCHANNELING.instant == true then ACTIONS.STOPCHANNELING.instant = false end
            table.insert(actions, ACTIONS.STOPCHANNELING)
        elseif ACTIONS.STOPCHANNELING.instant ~= true then
            ACTIONS.STOPCHANNELING.instant = true
        end
    end)
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.STOPCHANNELING, function(inst, action) return "dolongaction" end))
    AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.STOPCHANNELING, function(inst, action) return "dolongaction" end))
    local function processpersistent(inst)
        if inst.components.persistent2hm.data.townportaltalisman and inst.components.channelable then
            inst.components.channelable:StartChanneling(SpawnPrefab("townportaltalisman"))
        end
    end
    AddPrefabPostInit("townportal", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        inst:DoTaskInTime(0, processpersistent)
    end)
    local function marbleUSEITEM(inst, doer, actions, right, target) return target.prefab == "townportal" end
    local function marbleUSEITEMdoaction(inst, doer, target, pos, act)
        if target.components.channelable and not target:HasTag("channeled2hm") then
            if not target:HasTag("channeled") and target:HasTag("channelable") then
                local item = inst.components.stackable and inst.components.stackable:Get() or inst
                target.components.channelable:StartChanneling(item)
                return true
            elseif not target:HasTag("channeled") and not target:HasTag("channelable") and inst.components.teleporter then
                local teleporter = inst.components.teleporter.targetTeleporter
                if teleporter and teleporter:IsValid() and teleporter.prefab == "townportal" and teleporter.components.channelable and
                    teleporter:HasTag("channeled") and teleporter:HasTag("channeled2hm") then
                    teleporter.components.channelable:StopChanneling(true)
                    local item = inst.components.stackable and inst.components.stackable:Get() or inst
                    target.components.channelable:StartChanneling(item)
                    return true
                end
            end
        end
    end
    STRINGS.ACTIONS.ACTION2HM.TOWNPORTALTALISMAN = TUNING.isCh2hm and "激活" or "Activate"
    AddPrefabPostInit("townportaltalisman", function(inst)
        inst.actionothercondition2hm = marbleUSEITEM
        if not TheWorld.ismastersim then return end
        inst:AddComponent("action2hm")
        inst.components.action2hm.actionfn = marbleUSEITEMdoaction
    end)
end

-- 辉煌铁匠铺制造纯粹辉煌
if GetModConfigData("Alchemy Engine Redeem Gold Nugget") then
    local materials = {
        moonglass_charged = {n = 3, loot = "purebrilliance2hm"},                -- 改为生成 purebrilliance2hm
        purebrilliance = {n = 1, loot = "moonglass_charged", numtogive = 2},
        purebrilliance2hm = {n = 1, loot = "moonglass_charged", numtogive = 2}  -- 支持 purebrilliance2hm 反向合成
    }
    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_ding")
    end
    local function OnGivenItem(inst, giver, item)
        if materials[item.prefab] and item.components.stackable and item.components.stackable.stacksize >= materials[item.prefab].n then
            inst.components.prototyper.onactivate(inst)
            local loot = materials[item.prefab].loot
            local need = materials[item.prefab].n
            local num = 1
            local numtogive = (materials[item.prefab].numtogive or 1) * num
            item.components.stackable:Get(num * need):Remove()
            if item and item:IsValid() then giver.components.inventory:GiveItem(item, nil, inst:GetPosition()) end
            for index = 1, numtogive do
                local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
            end
        else
            inst.components.workable.onwork(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
            giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
        end
    end
    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if materials[item.prefab] and item.components.stackable then return true end
    end
    AddPrefabPostInit("lunar_forge", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            if materials[item.prefab] then count = count or (materials[item.prefab].n) end
            return oldAcceptGift(self, giver, item, count)
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
    end)

    -- 修改威尔逊炼金术配方，使其生成 purebrilliance2hm
    AddPrefabPostInit("world", function(inst)
        inst:DoTaskInTime(0, function()
            if AllRecipes and AllRecipes["transmute_purebrilliance"] then
                AllRecipes["transmute_purebrilliance"].product = "purebrilliance2hm"
            end
        end)
    end)
end

-- 暗影术基座制作绝望石
if GetModConfigData("Alchemy Engine Redeem Gold Nugget") then
    local materials = {
        horrorfuel = {n = 3, loot = "dreadstone"},
        dreadstone = {n = 1, loot = "horrorfuel", numtogive = 2},
        nightmarefuel = {n = 1, proxy = "horrorfuel", loot = "nightmarefuel", numtogive = 2}
    }
    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_ding")
    end
    local function OnGivenItem(inst, giver, item)
        if materials[item.prefab] and item.components.stackable and
            (materials[item.prefab].proxy or item.components.stackable.stacksize >= materials[item.prefab].n) then
            local loot = materials[item.prefab].loot
            local proxy = materials[item.prefab].proxy
            local need = materials[item.prefab].n
            if proxy then
                if item and item:IsValid() then giver.components.inventory:GiveItem(item, nil, inst:GetPosition()) end
                local has, num_found = giver.components.inventory:Has(proxy, need)
                if has then
                    inst.components.prototyper.onactivate(inst)
                    -- local num =math.floor(num_found / need)
                    local num = 1
                    giver.components.inventory:ConsumeByName(proxy, num * need)
                    local numtogive = (materials[item.prefab].numtogive or 1) * num
                    for index = 1, numtogive do
                        local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                        giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                    end
                else
                    OnRefuseItem(inst, giver)
                end
            else
                inst.components.prototyper.onactivate(inst)
                local num = 1
                local numtogive = (materials[item.prefab].numtogive or 1) * num
                -- local num = math.floor(item.components.stackable.stacksize / need)
                item.components.stackable:Get(num * need):Remove()
                if item and item:IsValid() then giver.components.inventory:GiveItem(item, nil, inst:GetPosition()) end
                for index = 1, numtogive do
                    local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end
        else
            OnRefuseItem(inst, giver)
            giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
        end
    end
    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if materials[item.prefab] and item.components.stackable then return true end
    end
    AddPrefabPostInit("shadow_forge", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            if materials[item.prefab] and not materials[item.prefab].proxy then count = count or (materials[item.prefab].n) end
            return oldAcceptGift(self, giver, item, count)
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
    end)
end

-- 智囊团制作浮木
if GetModConfigData("Alchemy Engine Redeem Gold Nugget") then
    local materials = {log = {n = 2, other = "saltrock", loot = "driftwood_log"}}
    local function OnGivenItem(inst, giver, item)
        if materials[item.prefab] and item.components.stackable and item.components.stackable.stacksize >= materials[item.prefab].n then
            inst.components.prototyper.onactivate(inst)
            local loot = materials[item.prefab].loot
            local need = materials[item.prefab].n
            local other = materials[item.prefab].other
            if other and giver.components.inventory:Has(other, 1, true) then
                giver.components.inventory:ConsumeByName(other, 1)
                local num = 1
                item.components.stackable:Get(num * need):Remove()
                local numtogive = (materials[item.prefab].numtogive or 1) * num
                if item and item:IsValid() then giver.components.inventory:GiveItem(item, nil, inst:GetPosition()) end
                for index = 1, numtogive do
                    local spawn = inst.components.lootdropper:SpawnLootPrefab(loot)
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
                return
            end
        end
        inst.components.workable.onwork(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
        giver.components.inventory:GiveItem(item, nil, inst:GetPosition())
    end
    local function OnRefuseItem(inst, giver, item)
        inst.components.workable.onwork(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
    end
    local function AcceptTest(inst, item, giver)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
        if materials[item.prefab] and item.components.stackable and item.components.stackable.stacksize >= materials[item.prefab].n then return true end
    end
    AddPrefabPostInit("seafaring_prototyper", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then return end
        inst:AddComponent("trader")
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnGivenItem
        inst.components.trader.onrefuse = OnRefuseItem
        local oldAcceptGift = inst.components.trader.AcceptGift
        inst.components.trader.AcceptGift = function(self, giver, item, count)
            if item == nil then return end
            if materials[item.prefab] then count = count or (materials[item.prefab].n) end
            return oldAcceptGift(self, giver, item, count)
        end
        inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
    end)
end

-- 钓具容器兑换鱼和海鱼
if GetModConfigData("Tackle Receptacle Use Fish Redeem") then
    local disabletrader = GetModConfigData("Tackle Receptacle Use Fish Redeem") == -1
    if disabletrader then
        local containers = require("containers")
        containers.params.tacklestation2hm = {
            widget = {slotpos = {}, animbank = "ui_fish_box_5x4", animbuild = "ui_fish_box_5x4", pos = Vector3(0, 220, 0), side_align_tip = 160},
            type = "chest"
        }
        for y = 2.5, -0.5, -1 do
            for x = -1, 3 do table.insert(containers.params.tacklestation2hm.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0)) end
        end
        local newitemtestfn = containers.params.shadow_container.itemtestfn
        local olditemtestfn = containers.params.tacklecontainer.itemtestfn
        containers.params.tacklestation2hm.itemtestfn = function(container, item, slot)
            if not container.containeritem2hm then container.containeritem2hm = true end
            return item.prefab ~= nil and (newitemtestfn == nil or newitemtestfn(container, item, slot)) and
                       ((olditemtestfn ~= nil and olditemtestfn(container, item, slot)) or table.contains(CRAFTING_FILTERS.FISHING.recipes, item.prefab) or
                           item:HasTag("preparedfood") or item.prefab == "seeds" or string.match(item.prefab, "_seeds") or item:HasTag("treeseed"))
        end
        local POCKETDIMENSIONCONTAINER_DEFS = require("prefabs/pocketdimensioncontainer_defs").POCKETDIMENSIONCONTAINER_DEFS
        table.insert(POCKETDIMENSIONCONTAINER_DEFS,
                     {name = "tacklestation2hm", prefab = "tacklestation2hm", ui = "anim/ui_fish_box_5x4.zip", widgetname = "tacklestation2hm"})
        AddClassPostConstruct("widgets/containerwidget", function(self)
            local oldOpen = self.Open
            self.Open = function(self, container, doer, ...)
                local result = oldOpen(self, container, doer, ...)
                if container.prefab == "tacklestation2hm" and self.bgimage and self.bganim then
                    if self.bgimage.SetTint then self.bgimage:SetTint(1, 1, 1, 0.25) end
                    if self.bganim.inst and self.bganim.inst.AnimState then self.bganim.inst.AnimState:SetMultColour(1, 1, 1, 0.25) end
                end
                return result
            end
        end)
        -- 种子袋永鲜
        TUNING.SEEDPOUCH_PRESERVER_RATE = 0
        local preserverrate = 0.15
        if CONFIGS_LEGION then preserverrate = 0 end
        local function perish_rate_multiplier(inst, item)
            return item and
                       ((item:HasTag("spider") or item:HasTag("spore") or item.prefab == "seeds" or string.match(item.prefab, "_seeds") or
                           item:HasTag("treeseed")) and 0 or (item:HasTag("preparedfood") and preserverrate)) or 1
        end
        AddPrefabPostInit("tacklestation2hm", function(inst)
            if not TheWorld.ismastersim then return end
            if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then preserverrate = 0 end
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(perish_rate_multiplier)
        end)
        local function onopen(inst)
            if not inst:HasTag("burnt") and inst.components.prototyper and inst.SoundEmitter then
                inst.components.prototyper.onactivate(inst)
                inst.SoundEmitter:PlaySound("hookline/common/tackle_station/recieive_item")
            end
        end
        local function onclose(inst)
            if not inst:HasTag("burnt") and inst.components.workable and inst.SoundEmitter then
                inst.components.workable.onwork(inst)
                inst.SoundEmitter:PlaySound("hookline/common/tackle_station/place")
            end
        end
        local function onwork(inst)
            if not inst:HasTag("burnt") then if inst.components.container_proxy ~= nil then inst.components.container_proxy:Close() end end
        end
        local function AttachShadowContainer(inst)
            if TheWorld and TheWorld.GetPocketDimensionContainer and inst.components.container_proxy then
                inst.components.container_proxy:SetMaster(TheWorld:GetPocketDimensionContainer("tacklestation2hm"))
            end
        end
        AddPrefabPostInit("tacklestation", function(inst)
            if inst.components.container_proxy then return end
            inst:AddComponent("container_proxy")
            -- inst.repairmaterials2hm = {moonstorm_spark = TUNING.SPEAR_WATHGRITHR_LIGHTNING_USES / 20}
            -- inst.displaynamefn = displaynamefn
            if not TheWorld.ismastersim then return end
            inst:ListenForEvent("worked", onwork)
            if not inst.OnLoadPostPass then
                inst.OnLoadPostPass = AttachShadowContainer
            else
                local OnLoadPostPass = inst.OnLoadPostPass
                inst.OnLoadPostPass = function(...)
                    AttachShadowContainer(...)
                    return OnLoadPostPass(...)
                end
            end
            inst.components.container_proxy:SetOnOpenFn(onopen)
            inst.components.container_proxy:SetOnCloseFn(onclose)
            if not POPULATING then AttachShadowContainer(inst) end
            --     inst:AddComponent("repairable2hm")
            --     inst.components.repairable2hm.customrepair = customrepair
            -- end)
            -- AddPrefabPostInit("tacklestation2hm",function (inst)
            --     inst.moongleamlevel2hm = net_smallbyte(inst.GUID, "wigfridspear.moongleamlevel2hm", "upgrade2hmdirty")
            --     inst.moongleamlevel2hm:set(0)
        end)
    else
        local trading_items = {
            {prefabs = {"kelp"}, min_count = 2, max_count = 4, reset = false, add_filler = false},
            {prefabs = {"kelp"}, min_count = 2, max_count = 3, reset = false, add_filler = false},
            {prefabs = {"seeds"}, min_count = 4, max_count = 6, reset = false, add_filler = false},
            {prefabs = {"tentaclespots"}, min_count = 1, max_count = 1, reset = false, add_filler = true},
            {prefabs = {"cutreeds"}, min_count = 1, max_count = 2, reset = false, add_filler = true},
            {
                prefabs = {
                    -- These trinkets are generally good for team play, but tend to be poor for solo play.
                    -- Theme
                    "trinket_12", -- Dessicated Tentacle
                    "trinket_25", -- Air Unfreshener
                    -- Team
                    "trinket_1", -- Melted Marbles
                    -- Fishing
                    "trinket_17", -- Bent Spork
                    "trinket_8" -- Rubber Bung
                },
                min_count = 1,
                max_count = 1,
                reset = false,
                add_filler = true
            },
            {
                prefabs = {"durian_seeds", "pepper_seeds", "eggplant_seeds", "pumpkin_seeds", "onion_seeds", "garlic_seeds"},
                min_count = 1,
                max_count = 2,
                reset = false,
                add_filler = true
            }
        }
        local trading_filler = {"seeds", "kelp", "seeds", "seeds"}

        local function OnGivenItem(inst, giver, item)
            inst.components.prototyper.onactivate(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_science_gift_recieve")
            local selected_index = math.random(1, #inst.trading_items)
            local selected_item = inst.trading_items[selected_index]

            local isabigheavyfish = item.components.weighable and item.components.weighable:GetWeightPercent() >= TUNING.WEIGHABLE_HEAVY_WEIGHT_PERCENT or false
            local bigheavyreward = isabigheavyfish and math.random(1, 2) or 0

            local filler_min = 2 -- Not biasing minimum for filler.
            local filler_max = 4 + bigheavyreward
            local reward_count = math.random(selected_item.min_count, selected_item.max_count) + bigheavyreward

            for k = 1, reward_count do
                local spawn = inst.components.lootdropper:SpawnLootPrefab(selected_item.prefabs[math.random(1, #selected_item.prefabs)])
                giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
            end

            if selected_item.add_filler then
                for i = filler_min, filler_max do
                    local spawn = inst.components.lootdropper:SpawnLootPrefab(trading_filler[math.random(1, #trading_filler)])
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end

            if item:HasTag("oceanfish") then
                local goldmin, goldmax, goldprefab = 1, 2, "goldnugget"
                if item.prefab:find("oceanfish_medium_") == 1 then
                    goldmin, goldmax = 2, 4
                    if item.prefab == "oceanfish_medium_6_inv" or item.prefab == "oceanfish_medium_7_inv" then -- YoT events.
                        goldprefab = "lucky_goldnugget"
                    end
                end

                local amt = math.random(goldmin, goldmax) + bigheavyreward
                for i = 1, amt do
                    local spawn = inst.components.lootdropper:SpawnLootPrefab(goldprefab)
                    giver.components.inventory:GiveItem(spawn, nil, inst:GetPosition())
                end
            end

            -- Cycle out rewards.
            table.remove(inst.trading_items, selected_index)
            if #inst.trading_items == 0 or selected_item.reset then inst.trading_items = deepcopy(trading_items) end
            item:Remove()
        end

        local function OnRefuseItem(inst, giver, item)
            inst.components.workable.onwork(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_ding")
        end

        local function AcceptTest(inst, item)
            if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then return false end
            return item:HasTag("fish")
        end
        AddPrefabPostInit("tacklestation", function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.trader then return end
            inst.trading_items = deepcopy(trading_items)
            inst:AddComponent("trader")
            inst.components.trader.deleteitemonaccept = false
            inst.components.trader.acceptnontradable = true
            inst.components.trader:SetAcceptTest(AcceptTest)
            inst.components.trader.onaccept = OnGivenItem
            inst.components.trader.onrefuse = OnRefuseItem
            inst:ListenForEvent("onburnt", function() inst:RemoveComponent("trader") end)
        end)
    end
end

-- 制图桌制作蓝图
if GetModConfigData("Cartographer's Desk Make Blueprint") then
    -- 蓝图草图可堆叠
    
    -- 可以添加女武神之力的图纸
    local valkyrie_sketchLoot
    if not TUNING.erasablepapertag2hm then
        TUNING.erasablepapertag2hm = true
        AddComponentPostInit("erasablepaper", function(self) self.inst:AddTag("erasablepaper") end)
    end
    local txt = TUNING.isCh2hm and "制图" or "Cartography"
    STRINGS.ACTIONS.BLUEPRINT2HM = txt
    local blueprintaction = Action({priority = -0.01})
    blueprintaction.id = "BLUEPRINT2HM"
    blueprintaction.str = txt
    blueprintaction.fn = function(act)
        if act.invobject and act.invobject:IsValid() and act.target and act.target:IsValid() and act.doer and act.doer:IsValid() and
            act.doer.components.inventory then
            if act.invobject.prefab == "papyrus" then
                local items = act.doer.components.inventory:GetItemsWithTag("erasablepaper")
                if #items > 0 then
                    for index, item in ipairs(items) do
                        if item:IsValid() and
                            (item.prefab == "blueprint" or item.prefab == "cookingrecipecard" or item:HasTag("scrapbook_note") or item.components.scrapbookable or
                                item:HasTag("sketch") or item.HasTag("tacklesketch") or item.components.yotb_skinunlocker) then
                            -- 不能复制女武神勋章需要的BOSS图纸
                            if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then
                                local sketchname = item.GetSpecificSketchPrefab and item:GetSpecificSketchPrefab() or nil
                                if sketchname and not valkyrie_sketchLoot then
                                    local medal = SpawnPrefab("valkyrie_certificate")
                                    if medal then
                                        if medal.valkyrie_sketchLoot then
                                            valkyrie_sketchLoot = medal.valkyrie_sketchLoot or {}
                                        else
                                            valkyrie_sketchLoot = {}
                                        end
                                        medal:Remove()
                                    else
                                        valkyrie_sketchLoot = {}
                                    end
                                end
                                if sketchname and valkyrie_sketchLoot[sketchname] then return end
                            end
                            local newitem = SpawnPrefab(item.prefab)
                            if newitem then
                                if act.doer.soundemitter then
                                    act.doer.soundemitter:PlaySound("dontstarve/common/together/packaged")
                                end
                                if act.invobject.components.stackable and act.invobject.components.stackable.stacksize > 1 then
                                    act.invobject.components.stackable:SetStackSize(act.invobject.components.stackable.stacksize - 1)
                                else
                                    act.invobject:Remove()
                                end
                                newitem:SetPersistData(item:GetPersistData())
                                if newitem.components.inventoryitem then
                                    act.doer.components.inventory:GiveItem(newitem, nil, act.target:GetPosition())
                                else
                                    newitem.Transform:SetPosition(act.target.Transform:GetWorldPosition())
                                    if act.target.lootdropper then act.target.lootdropper:FlingItem(newitem) end
                                end
                                return true
                            end
                        end
                    end
                end
            end
            local recipe = AllRecipes[act.invobject.prefab]
            if recipe and not recipe.nounlock and (recipe.builder_tag == nil or act.doer:HasTag(recipe.builder_tag)) and act.doer.components.builder and
                act.doer.components.builder:KnowsRecipe(recipe, true) and act.doer.components.inventory:Has("papyrus", 1) then
                local blueprint = SpawnPrefab("blueprint")
                if blueprint then
                    if act.doer.soundemitter then act.doer.soundemitter:PlaySound("dontstarve/common/together/packaged") end
                    act.doer.components.inventory:ConsumeByName("papyrus", 1)
                    blueprint.recipetouse = recipe.name or "unknown"
                    blueprint.components.teacher:SetRecipe(blueprint.recipetouse)
                    blueprint.components.named:SetName(STRINGS.NAMES[string.upper(blueprint.recipetouse)] .. " " .. STRINGS.NAMES.BLUEPRINT)
                    act.doer.components.inventory:GiveItem(blueprint, nil, act.target:GetPosition())
                    return true
                end
            end
        end
    end
    AddAction(blueprintaction)
    table.insert(TUNING.USEITEMFNS2HM, function(inst, doer, target, actions)
        if target.prefab == "cartographydesk" then
            if inst.prefab == "papyrus" then
                table.insert(actions, ACTIONS.BLUEPRINT2HM)
            else
                local recipe = AllRecipes[inst.prefab]
                if recipe and not recipe.nounlock and (recipe.builder_tag == nil or doer:HasTag(recipe.builder_tag)) and doer.replica and doer.replica.builder and
                    doer.replica.builder:KnowsRecipe(recipe, true) then table.insert(actions, ACTIONS.BLUEPRINT2HM) end
            end
        end
    end)
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BLUEPRINT2HM, function(inst, action) return "dolongaction" end))
    AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BLUEPRINT2HM, function(inst, action) return "dolongaction" end))
end

-- 制作食谱卡片
if GetModConfigData("Make Cooking Recipe Card") then
    AddPrefabPostInit("cookingrecipecard", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.inspectable then
            local getdesc = inst.components.inspectable.getspecialdescription
            inst.components.inspectable.getspecialdescription = function(inst, viewer, ...)
                if inst.ingredients2hm then
                    local ing_str = subfmt(STRINGS.COOKINGRECIPECARD_DESC.INGREDIENTS_FIRST, {
                        num = inst.ingredients2hm[1][2],
                        ing = STRINGS.NAMES[string.upper(inst.ingredients2hm[1][1])] or inst.ingredients2hm[1][1]
                    })
                    for i = 2, #inst.ingredients2hm do
                        ing_str = ing_str .. subfmt(STRINGS.COOKINGRECIPECARD_DESC.INGREDIENTS_MORE, {
                            num = inst.ingredients2hm[i][2],
                            ing = STRINGS.NAMES[string.upper(inst.ingredients2hm[i][1])] or inst.ingredients2hm[i][1]
                        })
                    end
                    return subfmt(STRINGS.COOKINGRECIPECARD_DESC.BASE,
                                  {name = STRINGS.NAMES[string.upper(inst.recipe_name)] or inst.recipe_name, ingredients = ing_str})
                end
                return getdesc(inst, viewer, ...)
            end
        end
        SetOnSave(inst, function(inst, data) data.i2hm = inst.ingredients2hm end)
        SetOnLoad(inst, function(inst, data) if data and data.i2hm then inst.ingredients2hm = data.i2hm end end)
    end)
    local function spawnfoodcard(recipe_name, cooker_name, ingredient_prefabs)
        local ingredients = {}
        for index, ingredientprefab in ipairs(ingredient_prefabs) do
            if not STRINGS.NAMES[string.upper(ingredientprefab)] then return end
            ingredients[ingredientprefab] = (ingredients[ingredientprefab] or 0) + 1
        end
        local card = SpawnPrefab("cookingrecipecard")
        if card then
            card.recipe_name = recipe_name
            card.cooker_name = cooker_name
            if card.components.named then
                card.components.named:SetName(subfmt(STRINGS.NAMES.COOKINGRECIPECARD, {item = STRINGS.NAMES[string.upper(recipe_name)] or recipe_name}))
            end
            card.ingredients2hm = {}
            for ingredientprefab, v in pairs(ingredients) do table.insert(card.ingredients2hm, {ingredientprefab, v}) end
            return card
        end
    end
    local function papyrusUSEITEM(inst, doer, actions, right, target) return target:HasTag("stewer") end
    local function papyrusUSEITEMdoaction(inst, doer, target, pos, act)
        if target.components.stewer and doer and doer.components.inventory then
            local stewer = target.components.stewer
            if stewer:IsDone() and stewer.chef_id and stewer.chef_id == doer.userid and stewer.product and STRINGS.NAMES[string.upper(stewer.product)] and
                stewer.product and stewer.ingredient_prefabs then
                local card = spawnfoodcard(stewer.product, target.prefab, stewer.ingredient_prefabs)
                if card then
                    local item = inst.components.stackable and inst.components.stackable:Get() or inst
                    item:Remove()
                    doer.components.inventory:GiveItem(card, nil, target:GetPosition())
                    return true
                end
            end
        end
    end
    STRINGS.ACTIONS.ACTION2HM.PAPYRUS = TUNING.isCh2hm and "制作食谱卡" or "Recipe Card"
    AddPrefabPostInit("papyrus", function(inst)
        inst.actionothercondition2hm = papyrusUSEITEM
        if not TheWorld.ismastersim then return end
        inst:AddComponent("action2hm")
        inst.components.action2hm.actionfn = papyrusUSEITEMdoaction
    end)
end

-- 假人交换随从
local mannequinmode = GetModConfigData("mannequin swap follower")
if mannequinmode then
    AddComponentPostInit("combat", function(class)
        local oldTryRetarget = class.TryRetarget
        class.TryRetarget = function(self)
            if self.inst.components.follower then
                local leader = self.inst.components.follower:GetLeader()
                if leader and leader.prefab == "sewing_mannequin" then
                    return
                end
            end
            return oldTryRetarget(self)
        end
    end)
    AddPrefabPostInit("sewing_mannequin", function(inst)
        if not TheWorld.ismastersim then return end
        if mannequinmode ~= -1 then
            if inst.components.inventory then inst:RemoveComponent("inventory") end
            inst:AddComponent("inventory")
            inst.components.inventory.maxslots = 20
            if not inst.components.preserver then
                inst:AddComponent("preserver")
                --跳过装备
                local function shouldpreserve2hm (inst, item) 
                    return item and item.components.equippable and 1 or 0
                end
                inst.components.preserver:SetPerishRateMultiplier(shouldpreserve2hm)
            end
        end

        if inst.components.activatable and not inst.components.leader then
            inst:AddComponent("leader")
            if inst.sg == nil then
                inst:SetStateGraph("SGwormhole")
                inst.AnimState:PlayAnimation("idle")
            end
            local OnActivate = inst.components.activatable.OnActivate
            inst.components.activatable.OnActivate = function(inst, doer, ...)
                local result, reason = OnActivate(inst, doer, ...)
                if doer and doer:IsValid() and doer.components.leader and inst.components.leader then
                    local time = GetTime()
                    local doerfollowers = {}
                    local instfollowers = {}
                    for follower, status in pairs(doer.components.leader.followers) do
                        if status and follower and follower:IsValid() and not follower:IsInLimbo() and not follower:HasTag("abigail") and
                            not follower.LinkToPlayer and not follower:HasTag("swc2hm") and follower.components.health and follower.components.follower and
                            follower.components.combat and follower.components.combat.defaultdamage > 0 and not follower.components.combat.target then
                            -- and (not follower.components.persistent2hm or (not follower.components.persistent2hm.data.rangemonster)) then
                            if follower:HasTag("swp2hm") and follower.components.childspawner2hm and follower.components.childspawner2hm.numchildrenoutside > 0 and
                                follower.components.playerprox2hm and follower.components.playerprox2hm.isclose then
                                follower.components.playerprox2hm.isclose = false
                                follower:PushEvent("onfar2hm")
                                if follower.components.playerprox2hm.onfar ~= nil then
                                    follower.components.playerprox2hm.onfar(follower)
                                end
                            end
                            doerfollowers[follower] = {
                                maxfollowtime = follower.components.follower.maxfollowtime,
                                time = follower.components.follower.targettime and follower.components.follower.targettime > time and
                                    math.floor(follower.components.follower.targettime - time)
                            }
                        end
                    end
                    local inventory = inst.components.inventory
                    if mannequinmode ~= -1 and inventory then
                        for k = 1, inventory.maxslots do
                            local v = inventory.itemslots[k]
                            if v ~= nil and v.components.health and v.components.follower and v.components.combat then
                                if v.components.follower.leader == nil then inst.components.leader:AddFollower(v) end
                                if v.components.combat.target then v.components.combat:DropTarget() end
                                inventory:DropItem(v, true, true)
                            end
                        end
                    end
                    for follower, status in pairs(inst.components.leader.followers) do
                        if status and follower and follower:IsValid() and not follower:IsInLimbo() and not follower:HasTag("swc2hm") and
                            follower.components.health and follower.components.follower and follower.components.combat and
                            follower.components.combat.defaultdamage > 0 and not follower.components.combat.target then
                            if follower:HasTag("swp2hm") and follower.components.childspawner2hm and follower.components.childspawner2hm.numchildrenoutside > 0 and
                                follower.components.playerprox2hm and follower.components.playerprox2hm.isclose then
                                follower.components.playerprox2hm.isclose = false
                                follower:PushEvent("onfar2hm")
                                if follower.components.playerprox2hm.onfar ~= nil then
                                    follower.components.playerprox2hm.onfar(follower)
                                end
                            end
                            instfollowers[follower] = {
                                maxfollowtime = follower.components.follower.maxfollowtime,
                                time = follower.components.follower.targettime and follower.components.follower.targettime > time and
                                    math.floor(follower.components.follower.targettime - time)
                            }
                        end
                    end
                    local leftslot = 0
                    if mannequinmode ~= -1 and inventory then
                        for k = 1, inventory.maxslots do if not inventory.itemslots[k] then leftslot = leftslot + 1 end end
                    end
                    if not result then
                        result = not IsTableEmpty(doerfollowers) or not IsTableEmpty(instfollowers)
                        if result then
                            inst.AnimState:PlayAnimation("swap")
                            inst.SoundEmitter:PlaySound("stageplay_set/mannequin/swap")
                            inst.AnimState:PushAnimation("idle", false)
                        end
                    end
                    for follower, data in pairs(doerfollowers) do
                        inst.components.leader:AddFollower(follower)
                        if data.maxfollowtime then follower.components.follower.maxfollowtime = data.maxfollowtime end
                        if data.time then follower.components.follower:AddLoyaltyTime(data.time) end
                        if mannequinmode ~= -1 and follower.components.inventoryitem and follower.components.inventoryitem.canbepickedupalive and leftslot > 0 then
                            leftslot = leftslot - 1
                            SpawnPrefab("spawn_fx_small").Transform:SetPosition(follower.Transform:GetWorldPosition())
                            inventory:GiveItem(follower)
                        end
                    end
                    for follower, data in pairs(instfollowers) do
                        doer.components.leader:AddFollower(follower)
                        if data.maxfollowtime then follower.components.follower.maxfollowtime = data.maxfollowtime end
                        if data.time then follower.components.follower:AddLoyaltyTime(data.time) end
                    end
                end
                return result, reason
            end
        end
    end)
end

-- 龙蝇火炉摧毁物品时转化为灰烬
if GetModConfigData("dragonfly furnace stewer") then
    
    local burn_conversions = {
        log = {result = "charcoal", ratio = 0.5},      -- 2个木头 → 1个木炭
        boards = {result = "charcoal", ratio = 2},     -- 1个木板 → 2个木炭
    }
    
    local Incinerator = require("components/incinerator")
    local OriginalOnPreDestroyItemCallbackFn = Incinerator.OnPreDestroyItemCallbackFn
    
    -- 可燃物→灰烬，木头和木板→木炭
    local function OnPreDestroyItemCallback2hm(furnace, item)

        if OriginalOnPreDestroyItemCallbackFn then
            OriginalOnPreDestroyItemCallbackFn(furnace, item)
        end
        

        local can_burn = item.components.burnable ~= nil
        
        if can_burn and furnace.components.container then
            local stack_size = item.components.stackable and item.components.stackable:StackSize() or 1
            local conversion = burn_conversions[item.prefab]
            
            if conversion then
                local result_count = math.floor(stack_size * conversion.ratio + 0.5)
                if result_count > 0 then
                    local result_item = SpawnPrefab(conversion.result)
                    if result_item and result_item.components.stackable then
                        result_item.components.stackable:SetStackSize(result_count)
                    end
                    furnace.components.container:GiveItem(result_item)
                end
            else
                local ash = SpawnPrefab("ash")
                if ash and ash.components.stackable then
                    ash.components.stackable:SetStackSize(stack_size)
                end
                furnace.components.container:GiveItem(ash)
            end
        end
    end
    

    AddPrefabPostInit("dragonflyfurnace", function(inst)
        if not TheWorld.ismastersim then return end
        
        inst:DoTaskInTime(0, function()
            if inst.components.incinerator then

                local original_should_incinerate = inst.components.incinerator.shouldincinerateitemfn

                inst.components.incinerator:SetShouldIncinerateItemFn(function(furnace, item)
                    if original_should_incinerate and not original_should_incinerate(furnace, item) then
                        return false
                    end
                    return true
                end)
            end
        end)
    end)

    Incinerator.OnPreDestroyItemCallbackFn = OnPreDestroyItemCallback2hm
end

-- 龙蝇火炉批量烹饪
local dragonflyfurnace = GetModConfigData("dragonfly furnace stewer")
if dragonflyfurnace then
    local cooking = require("cooking")
    local containers = require("containers")
    local ImageButton = require "widgets/imagebutton"
    cooking.recipes.dragonflyfurnace = cooking.recipes.portablecookpot
    -- 做饭期间可以加燃料缩短做饭时间
    local function clearfuel(inst) if inst.components.fueled then inst.components.fueled.currentfuel = 0 end end
    local function ontakefuel(inst, fuelvalue)
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        local self = inst.components.stewer
        if self and self:IsCooking() and self.task and self.targettime and fuelvalue then
            local dostew = self.task.fn
            if self.task ~= nil then self.task:Cancel() end
            self.targettime = math.max(self.targettime - fuelvalue, GetTime())
            self.task = self.inst:DoTaskInTime(self.targettime - GetTime(), dostew, self)
        end
        inst:DoTaskInTime(0, clearfuel)
    end
    local function startcookfn(inst)
        if inst.stewercooktask2hm then
            inst.stewercooktask2hm:Cancel()
            inst.SoundEmitter:KillSound("snd")
            inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
        else
            inst.SoundEmitter:KillSound("loop")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/place")
        end
        inst.AnimState:PlayAnimation("incinerate")
        inst.AnimState:PushAnimation("hi", true)
        local time = inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() + FRAMES
        inst.stewercooktask2hm = inst:DoTaskInTime(time, startcookfn)
        -- 做饭期间可以把东西放火炉上烹饪
        if not inst:HasTag("burnt") then inst:AddTag("burnt") end
        if not inst.components.cooker then
            inst:AddComponent("cooker")
            if inst.updatecookitem2hm then inst.updatecookitem2hm(inst, 0.15) end
        end
        -- 做饭期间可以给燃料缩短做饭时间
        if not inst.components.fueled then
            inst:AddComponent("fueled")
            inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
            inst.components.fueled.currentfuel = 0
            inst.components.fueled.accepting = true
            inst.components.fueled:SetTakeFuelFn(ontakefuel)
        end
    end
    -- local function autoHarvest(inst) inst.components.stewer:Harvest(inst) end
    local function donecookfn(inst)
        if inst.stewercooktask2hm then
            inst.stewercooktask2hm:Cancel()
            inst.stewercooktask2hm = nil
        end
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:KillSound("loop")
        -- inst:DoTaskInTime(0, autoHarvest)
        inst:RemoveTag("burnt")
        if inst.components.fueled then inst:RemoveComponent("fueled") end
    end
    -- 收获后，去除厨师食谱
    local function onharvest(inst, harvester)
        inst:RemoveComponent("cooker")
        if not inst.components.container:IsEmpty() and harvester and harvester:IsValid() and harvester:HasTag("player") then
            inst.components.container:Open(harvester)
        end
    end
    -- 如果是烹饪时进行的检测,需要判断是否是全食材;如果不是主厨，则不支持主厨食谱
    local itemtestfn = containers.params.cookpot.itemtestfn
    local function resetdragonflyfurnacerecipes(inst) cooking.recipes.dragonflyfurnace = cooking.recipes.portablecookpot end
    local function startcookfntest(inst, doer)
        if inst.components.stewer.targettime ~= nil then return false end
        for k, v in pairs(inst.components.container.slots) do if not itemtestfn(inst.components.container, v, k) then return false end end
        if dragonflyfurnace == -1 and doer and doer:IsValid() then
            cooking.recipes.dragonflyfurnace = doer:HasTag("masterchef") and cooking.recipes.portablecookpot or cooking.recipes.cookpot
            inst:DoTaskInTime(0, resetdragonflyfurnacerecipes)
        end
        return true
    end
    -- 兼容智能锅
    COOKINGPOTS = COOKINGPOTS or {}
    COOKINGPOTS.dragonflyfurnace = COOKINGPOTS.dragonflyfurnace or {}
    local function perish_rate_multiplier(inst, item) return inst.components.stewer:IsCooking() and 0 or 1 end
    AddPrefabPostInit("dragonflyfurnace", function(inst)
        inst:AddTag("stewer")
        if not TheWorld.ismastersim then return end
        if not (inst.components.container and inst.components.container.numslots == 4) or inst.components.stewer then return end
        -- 移除烧烤组件来避免做饭烹饪按钮复用问题
        inst:RemoveComponent("cooker")
        inst:AddComponent("stewer")
        local self = inst.components.stewer
        self.multi2hm = true
        -- self.autoharvest2hm = true
        self.startcookfntest2hm = startcookfntest
        self.onstartcooking = startcookfn
        self.oncontinuecooking = startcookfn
        self.ondonecooking = donecookfn
        self.onharvest = onharvest
        self.cooktimemult = 0.8
        if not inst.components.preserver then
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(perish_rate_multiplier)
        end
    end)
    -- 普通的烤熟按钮客户端响应
    local monstermeats = {cookedmonstermeat = "cookedmeat", cookedmonstersmallmeat = "cookedsmallmeat", um_monsteregg_cooked = "bird_egg_cooked"}
    local transformitems = {boards = "charcoal"}
    local function cookfn(doer, inst)
        local docook
        if inst.components.stewer and not inst.components.stewer:IsCooking() and inst.components.container and not inst.components.container:IsEmpty() then
            local replacelist = {}
            for i, v in pairs(inst.components.container.slots) do
                if v:IsValid() then
                    if transformitems[v.prefab] then
                        local size = v.components.stackable and v.components.stackable.stacksize or 1
                        local newitem = SpawnPrefab(transformitems[v.prefab])
                        v:Remove()
                        if newitem.components.stackable then newitem.components.stackable.stacksize = size end
                        inst.components.container:GiveItem(newitem, i)
                        if not docook then docook = true end
                    elseif v.components.cookable then
                        local size = v.components.stackable and v.components.stackable.stacksize or 1
                        local newitem = v.components.cookable:Cook(inst, doer)
                        v:Remove()
                        local replace = inst.updatecookitem2hm ~= nil and monstermeats[newitem.prefab]
                        local replacesize
                        if replace then
                            local replacesizechance = size * 0.15
                            replacesize = math.floor(replacesizechance)
                            local replacechance = replacesizechance - replacesize
                            if replacechance > 0 then replacesize = replacesize + (math.random() < replacechance and 1 or 0) end
                            if replacesize >= 1 then
                                size = size - replacesize
                            else
                                replace = nil
                            end
                        end
                        if size > 0 then
                            if newitem.components.stackable then newitem.components.stackable.stacksize = size end
                            inst.components.container:GiveItem(newitem, i)
                            if replace then
                                local item = SpawnPrefab(replace)
                                if item.components.stackable and replacesize then
                                    item.components.stackable.stacksize = replacesize
                                end
                                table.insert(replacelist, item)
                            end
                        else
                            newitem:Remove()
                            if replace then
                                local item = SpawnPrefab(replace)
                                if item.components.stackable and replacesize then
                                    item.components.stackable.stacksize = replacesize
                                end
                                inst.components.container:GiveItem(item, i)
                            end
                        end
                        if not docook then docook = true end
                    end
                end
            end
            for index, item in ipairs(replacelist) do inst.components.container:GiveItem(item) end
        end
        if docook then
            inst.AnimState:PlayAnimation("hi_hit")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/light")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop")
        end
    end
    AddModRPCHandler("MOD_HARDMODE", "cookbtn2hm", cookfn)
    local function cookbtnfn(inst, doer)
        if inst.components.container and inst.components.stewer and TheWorld.ismastersim then
            cookfn(doer, inst)
        elseif inst.replica.container ~= nil and inst:HasTag("stewer") then
            SendModRPCToServer(GetModRPC("MOD_HARDMODE", "cookbtn2hm"), inst)
        end
    end
    -- 添加一个做饭按钮和一个烤熟按钮，且做饭按钮替代原来的摧毁按钮作为主要按钮
    local cookpotbtnfn = containers.params.cookpot.widget.buttoninfo.fn
    local olddestroyfn = containers.params.dragonflyfurnace.widget.buttoninfo.fn
    containers.params.dragonflyfurnace.widget.buttoninfo.fn = cookpotbtnfn
    local function destroyfn(doer, inst) if inst.components.container then olddestroyfn(inst, doer) end end
    AddModRPCHandler("MOD_HARDMODE", "destroybtn2hm", destroyfn)
    local function destroybtnfn(inst, doer)
        if inst.components.container then
            olddestroyfn(inst, doer)
        elseif inst.replica.container ~= nil and inst:HasTag("stewer") then
            SendModRPCToServer(GetModRPC("MOD_HARDMODE", "destroybtn2hm"), inst)
        end
    end
    AddClassPostConstruct("widgets/containerwidget", function(self)
        local Open = self.Open
        self.Open = function(self, container, doer, ...)
            if container and container.prefab == "dragonflyfurnace" and dragonflyfurnace == -1 and doer and doer:IsValid() then
                container.masterchef2hm = doer:HasTag("masterchef")
            end
            Open(self, container, doer, ...)
            if container and container.prefab == "dragonflyfurnace" and self.button then
                local widget = container.replica.container and container.replica.container:GetWidget()
                if widget and widget.buttoninfo ~= nil and widget.slotpos ~= nil then
                    local finalslot = (widget.slotpos[3] + widget.slotpos[4]) / 2
                    local pos1 = Vector3(finalslot.x, finalslot.y - 57, finalslot.z)
                    local finalslot2 = (widget.slotpos[1] + widget.slotpos[2]) / 2
                    local pos2 = Vector3(finalslot2.x, finalslot.y + 130, finalslot2.z)
                    local btnpos = widget.buttoninfo.position
                    local posmain = Vector3(btnpos.x, finalslot.y - 100, btnpos.z)
                    -- 原摧毁按钮挪位置
                    self.button:SetPosition(pos2)
                    self.button.image:SetScale(1.07, 0.95, 1.07)
                    -- self.button.image:SetScale(0.77, 1.07, 1.07)
                    -- 添加一个烤熟按钮
                    local btn = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex", nil, nil,
                                                          {1, 1}, {0, 0}))
                    btn:SetPosition(pos1)
                    btn.image:SetScale(1.07)
                    btn.text:SetPosition(2, -2)
                    btn:SetFont(BUTTONFONT)
                    btn:SetDisabledFont(BUTTONFONT)
                    btn:SetTextSize(33)
                    btn.text:SetVAlign(ANCHOR_MIDDLE)
                    btn.text:SetColour(0, 0, 0, 1)
                    btn:SetText(STRINGS.ACTIONS.STORE.COOK)
                    -- 添加一个做饭按钮
                    local btn2 = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex", nil, nil,
                                                           {1, 1}, {0, 0}))
                    btn2:SetPosition(posmain)
                    btn2.image:SetScale(1.07)
                    btn2.text:SetPosition(2, -2)
                    btn2:SetFont(BUTTONFONT)
                    btn2:SetDisabledFont(BUTTONFONT)
                    btn2:SetTextSize(33)
                    btn2.text:SetVAlign(ANCHOR_MIDDLE)
                    btn2.text:SetColour(0, 0, 0, 1)
                    btn2:SetText(STRINGS.NAMES.COOKPOT)
                    container.destroybtn2hm = self.button
                    container.cookbtn2hm = btn
                    self.destroybtn2hm = self.button
                    self.cookbtn2hm = btn
                    self.button = btn2
                    self.destroybtn2hm:SetOnClick(function() destroybtnfn(container, doer) end)
                    self.cookbtn2hm:SetOnClick(function() cookbtnfn(container, doer) end)
                    self.button:SetOnClick(function() cookpotbtnfn(container, doer) end)
                    if widget.buttoninfo.validfn(container) then
                        self.button:Enable()
                    else
                        self.button:Disable()
                    end
                end
            end
        end
        local Close = self.Close
        self.Close = function(self, ...)
            if self.container and self.container.destroybtn2hm then self.container.destroybtn2hm = nil end
            if self.container and self.container.cookbtn2hm then self.container.cookbtn2hm = nil end
            if self.isopen then
                if self.cookbtn2hm then
                    self.cookbtn2hm:Kill()
                    self.cookbtn2hm = nil
                end
                if self.destroybtn2hm then
                    self.destroybtn2hm:Kill()
                    self.destroybtn2hm = nil
                end
            end
            Close(self, ...)
        end
    end) 
    
    -- 智能锅智能兼容火炉模式
    if dragonflyfurnace == -1 and isModuleAvailable("widgets/foodcrafting") then
        AddClassPostConstruct("widgets/foodcrafting", function(self, ...)
            local Open = self.Open
            self.Open = function(self, cooker_inst, ...)
                local container
                if cooker_inst.prefab then
                    container = cooker_inst
                elseif cooker_inst.inst.prefab then
                    container = cooker_inst.inst
                end
                if container.prefab == "dragonflyfurnace" then
                    container.prefab = container.masterchef2hm and "portablecookpot" or "cookpot"
                else
                    container = nil
                end
                Open(self, cooker_inst, ...)
                if container then container.prefab = "dragonflyfurnace" end
            end
        end)
    end
    -- 校验摧毁，烤熟和主要的做饭按钮
    local destroyvalidfn = containers.params.dragonflyfurnace.widget.buttoninfo.validfn
    local cookpotvalidfn = containers.params.cookpot.widget.buttoninfo.validfn
    containers.params.dragonflyfurnace.widget.buttoninfo.validfn = function(inst, ...)
        if inst.destroybtn2hm then
            if destroyvalidfn(inst, ...) then
                inst.destroybtn2hm:Enable()
            else
                inst.destroybtn2hm:Disable()
            end
        end
        if inst.cookbtn2hm then
            local result = false
            if inst.replica.container ~= nil and not inst.replica.container:IsEmpty() then
                for k, v in pairs(inst.replica.container:GetItems()) do
                    if v ~= nil and (v:HasTag("cookable") or transformitems[v.prefab]) then
                        result = true
                        break
                    end
                end
            end
            if result then
                inst.cookbtn2hm:Enable()
            else
                inst.cookbtn2hm:Disable()
            end
        end
        if cookpotvalidfn(inst, ...) then
            for k, v in pairs(inst.replica.container:GetItems()) do if not itemtestfn(inst.replica.container, v, k) then return false end end
            return true
        end
    end
end

-- 批量调味
local portablespicer = GetModConfigData("Portable Crock Pot Multi")
if portablespicer then
    local containers = require("containers")
    containers.params.portablespicer.acceptsstacks = true
    AddPrefabPostInit("portablespicer", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.stewer then inst.components.stewer.multi2hm = true end
    end)
end

if dragonflyfurnace or portablespicer then
    local cooking = require("cooking")
    local function givecontaineritem(container, item, src_pos)
        if item.components.stackable and not container.infinitestacksize then
            local slotsize = item.components.stackable.originalmaxsize or item.components.stackable.maxsize
            if slotsize and item.components.stackable.stacksize > slotsize then
                local size = item.components.stackable.stacksize
                local totalsize = size + slotsize
                for i = slotsize, totalsize, slotsize do
                    local giveitem = item.components.stackable:Get(slotsize)
                    container:GiveItem(giveitem, nil, i > size and src_pos or nil)
                    if giveitem and giveitem:IsValid() then giveitem.currplayer2hm = nil end
                end
                return
            end
        end
        container:GiveItem(item, nil, src_pos)
    end
    AddComponentPostInit("stewer", function(self)
        local StartCooking = self.StartCooking
        function self:StartCooking(doer)
            -- 防止右键火炉烹饪从而让火炉无视食材限制制作东西
            if self.startcookfntest2hm and not self.startcookfntest2hm(self.inst, doer) then return end
            -- 消耗食材时变为批量消耗食材
            local DestroyContents
            if self.multi2hm then
                DestroyContents = self.inst.components.container.DestroyContents
                self.inst.components.container.DestroyContents = function(container, ...)
                    local stacksize2hm = nil
                    for k, v in pairs(container.slots) do
                        if v.components.stackable then
                            stacksize2hm = stacksize2hm and math.min(stacksize2hm, v.components.stackable.stacksize) or v.components.stackable.stacksize
                        else
                            stacksize2hm = 1
                            break
                        end
                    end
                    self.stacksize2hm = stacksize2hm
                    if not stacksize2hm then return DestroyContents(container, ...) end
                    for k, v in pairs(container.slots) do
                        if v.components.stackable then
                            v.components.stackable:Get(stacksize2hm):Remove()
                        else
                            v:Remove()
                        end
                    end
                    -- 做饭时间翻倍
                    if not self.inst:HasTag("spicer") then
                        local cooktime = self.targettime - GetTime()
                        cooktime = cooktime * self.stacksize2hm
                        self.targettime = GetTime() + cooktime
                        if self.task ~= nil then
                            local fn = self.task.fn
                            self.task:Cancel()
                            self.task = self.inst:DoTaskInTime(cooktime, fn, self)
                        end
                    end
                end
            end
            StartCooking(self, doer)
            if DestroyContents then self.inst.components.container.DestroyContents = DestroyContents end
        end
        local OnSave = self.OnSave
        function self:OnSave()
            local data = OnSave(self)
            data.stacksize2hm = self.stacksize2hm
            return data
        end
        local OnLoad = self.OnLoad
        function self:OnLoad(data)
            if data and data.stacksize2hm then self.stacksize2hm = data.stacksize2hm end
            OnLoad(self, data)
        end
        -- 收获时变为批量收获;自动采收则全部收完,非自动采收则只收取部分,再调用一次收取接口
        local Harvest = self.Harvest
        function self:Harvest(harvester)
            if self.done and self.product and ((self.stacksize2hm and self.stacksize2hm > 1) or self.autoharvest2hm) then
                local loot = SpawnPrefab(self.product)
                if loot ~= nil then
                    local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
                    local stacksize = (recipe and recipe.stacksize or 1) * (self.autoharvest2hm and (self.stacksize2hm or 1) or (self.stacksize2hm - 1))
                    
                    -- 判断物品是否可堆叠
                    if loot.components.stackable then
                        -- 可堆叠物品：设置堆叠数量
                        if stacksize > 1 then 
                            loot.components.stackable:SetStackSize(stacksize) 
                        end
                        if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                            local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                            loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                            loot.components.perishable:StartPerishing()
                        end
                        if self.autoharvest2hm and harvester ~= nil and harvester.components.container ~= nil then
                            givecontaineritem(harvester.components.container, loot)
                        elseif harvester ~= nil and harvester.components.inventory ~= nil then
                            givecontaineritem(harvester.components.inventory, loot, self.inst:GetPosition())
                        elseif self.inst.components.lootdropper then
                            self.inst.components.lootdropper:FlingItem(loot)
                        else
                            loot:Remove()
                        end
                    else
                        -- 不可堆叠物品：循环生成多个独立物品
                        for i = 1, stacksize do
                            local item = (i == 1) and loot or SpawnPrefab(self.product)
                            if item ~= nil then
                                if self.spoiltime ~= nil and item.components.perishable ~= nil then
                                    local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                                    item.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                                    item.components.perishable:StartPerishing()
                                end
                                if self.autoharvest2hm and harvester ~= nil and harvester.components.container ~= nil then
                                    givecontaineritem(harvester.components.container, item)
                                elseif harvester ~= nil and harvester.components.inventory ~= nil then
                                    givecontaineritem(harvester.components.inventory, item, self.inst:GetPosition())
                                elseif self.inst.components.lootdropper then
                                    self.inst.components.lootdropper:FlingItem(item)
                                else
                                    item:Remove()
                                end
                            end
                        end
                    end
                end
                if self.autoharvest2hm then self.product = nil end
            end
            return Harvest(self, harvester)
        end
    end)
end

-- 帐篷恢复理智上限
if GetModConfigData("Tent restores sanity penalty") then

    AddComponentPostInit("sleepingbaguser", function(SleepingBagUser)
        local _DoSleep = SleepingBagUser.DoSleep
        local _DoWakeUp = SleepingBagUser.DoWakeUp
        SleepingBagUser.DoSleep = function(self, bed)
            _DoSleep(self, bed)
            
            if self.inst.components.sanity then
                local has_builder_penalty = self.inst.components.sanity.builderpenalty2hm ~= nil
                local has_ember_penalty = self.inst.prefab == "willow" and self.inst.components.sanity.emberpenalty2hm ~= nil

                if has_builder_penalty or has_ember_penalty then
                    -- 普通帐篷为基础速度，升级帐篷为2倍速度
                    local restore_multiplier = (self.bed.level2hm and self.bed.level2hm:value() > 1) and 2 or 1
                    
                    self.sanitytask2hm = self.inst:DoPeriodicTask(self.bed.components.sleepingbag.tick_period, function()
                        if self.inst.components.sanity then
                            -- 恢复制作消耗的理智上限
                            if self.inst.components.sanity.builderpenalty2hm then
                                -- 每次恢复1%的理智上限（升级后2%）
                                local restore_amount = 0.01 * restore_multiplier 
                                if self.inst.components.sanity.builderpenalty2hm > restore_amount then
                                    self.inst.components.sanity.builderpenalty2hm = self.inst.components.sanity.builderpenalty2hm - restore_amount
                                    -- 更新理智上限惩罚
                                    self.inst.components.sanity:AddSanityPenalty("builder2hm", self.inst.components.sanity.builderpenalty2hm)
                                else
                                    -- 完全恢复，清理所有相关数据
                                    self.inst.components.sanity.builderpenalty2hm = nil
                                    self.inst.components.sanity:RemoveSanityPenalty("builder2hm")
                                    if self.inst.components.sanity.buildersanitytask2hm then
                                        self.inst.components.sanity.buildersanitytask2hm:Cancel()
                                        self.inst.components.sanity.buildersanitytask2hm = nil
                                    end
                                end
                            end
                            
                            -- 恢复火女余烬黑化理智
                            if self.inst.prefab == "willow" and self.inst.components.sanity.emberpenalty2hm then
                                local restore_amount = 0.01 * restore_multiplier 
                                if self.inst.components.sanity.emberpenalty2hm > restore_amount then
                                    self.inst.components.sanity.emberpenalty2hm = self.inst.components.sanity.emberpenalty2hm - restore_amount
                                    self.inst.components.sanity:AddSanityPenalty("emberpenalty2hm", self.inst.components.sanity.emberpenalty2hm)
                                else
                                    self.inst.components.sanity.emberpenalty2hm = nil
                                    self.inst.components.sanity:RemoveSanityPenalty("emberpenalty2hm")
                                    if self.inst.components.sanity.embersanitytask2hm then
                                        self.inst.components.sanity.embersanitytask2hm:Cancel()
                                        self.inst.components.sanity.embersanitytask2hm = nil
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
        
        SleepingBagUser.DoWakeUp = function(self, nostatechange)
            if self.sanitytask2hm ~= nil then
                self.sanitytask2hm:Cancel()
                self.sanitytask2hm = nil
            end
            _DoWakeUp(self, nostatechange)
        end
    end)
end