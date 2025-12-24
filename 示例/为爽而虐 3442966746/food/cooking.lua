local cooking = require("cooking")
local cookingchange = GetModConfigData("cooking_change")

local function OnAddFuel(inst) if inst.SoundEmitter then inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel") end end

local function OnFuelEmpty(inst)
    if inst.SoundEmitter then inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/down") end
    if inst.components.fueled and inst.components.fueled.done and inst.Light then inst.Light:Enable(false) end
end

local function OnFuelSectionChange(new, old, inst) if inst.fueledlevel2hm then inst.fueledlevel2hm:set(new) end end

AddClassPostConstruct("widgets/containerwidget", function(self)
    local oldOpen = self.Open
    self.Open = function(self, container, doer, ...)
        local result = oldOpen(self, container, doer, ...)
        if container and container:HasTag("fueledpot2hm") and container.fueledlevel2hm then
            local level = doer:HasTag("masterchef") and 4 or container.fueledlevel2hm:value()
            for k, v in pairs(self.inv) do
                if k + level > 4 then
                    v:SetBGImage2(resolvefilepath(CRAFTING_ICONS_ATLAS), "filter_fire.tex", {1, 1, 1, 0.25})
                    local w, h = v.bgimage:GetSize()
                    v.bgimage2:SetSize(w, h)
                end
            end
        end
        return result
    end
end)

local oldCOOKfn = ACTIONS.COOK.fn
ACTIONS.COOK.fn = function(act, ...)
    if act.doer and act.doer:HasTag("masterchef") and act.target then act.target.warlycook2hm = true end
    local success, resson = oldCOOKfn(act, ...)
    if act.target and act.target.warlycook2hm then act.target.warlycook2hm = nil end
    if not success and not resson and act.doer and act.doer.components.talker and act.target.components.stewer ~= nil and
        not act.target.components.stewer:CanCook() then act.doer.components.talker:Say(STRINGS.CHARACTERS.WINONA.DESCRIBE.FIRESUPPRESSOR.LOWFUEL) end
    return success, resson
end

local function updatebyfurnace(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 18, {"HASHEATER", "structure", "wildfireprotected"})
    for index, ent in ipairs(ents) do
        if ent and ent.prefab == "dragonflyfurnace" and inst.components.fueled then
            inst.components.fueled:SetPercent(1)
            inst.components.fueled.currentfuel = inst.components.fueled.maxfuel
            inst.components.fueled:StopConsuming()
            break
        end
    end
end
local function needfuel(inst)
    -- if not inst:HasTag("stewer") or inst:HasTag("spicer") then return end
    inst.fueledlevel2hm = net_byte(inst.GUID, "cookpot.hardmodefueled")
    inst.fueledlevel2hm:set(0)
    if not TheWorld.ismastersim then return end
    if inst.components.burnable then inst:RemoveComponent("burnable") end
    if inst.components.fueled then return end
    inst:DoTaskInTime(0, updatebyfurnace)
    inst:AddTag("fueledpot2hm")
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled:SetSections(4)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.CAMPFIRE_FUEL_MAX * 0.01)
    inst.components.fueled:StopConsuming()
    inst:ListenForEvent("onburnt", function() inst:RemoveComponent("fueled") end)
    local self = inst.components.stewer
    local oldCanCook = self.CanCook
    self.CanCook = function(self, ...)
        if oldCanCook(self, ...) then
            if self.inst.warlycook2hm or self.inst.components.fueled.currentfuel >= self.inst.components.fueled.maxfuel then return true end
            if self.inst.components.fueled:IsEmpty() then return false end
            local ingredient_prefabs = {}
            for k, v in pairs(self.inst.components.container.slots) do table.insert(ingredient_prefabs, v.prefab) end
            local product, cooktime = cooking.CalculateRecipe(self.inst.prefab, ingredient_prefabs)
            return self.inst.components.fueled.currentfuel >= cooktime * 20
        end
        return false
    end
    local oldStartCooking = self.StartCooking
    self.StartCooking = function(self, doer, ...)
        self.inst.components.fueled:StartConsuming()
        updatebyfurnace(self.inst)
        local cooktimemult = self.cooktimemult
        if self.inst.prefab == "cookpot" then self.cooktimemult = self.cooktimemult * (1 - self.inst.components.fueled:GetPercent() / 5) end
        local result = oldStartCooking(self, doer, ...)
        self.cooktimemult = cooktimemult
        return result
    end
    local olddonecookfn = self.ondonecooking
    self.ondonecooking = function(inst, ...)
        local result = olddonecookfn(inst, ...)
        if inst.Light and not inst.components.fueled:IsEmpty() then inst.Light:Enable(true) end
        return result
    end
    local oldHarvest = self.Harvest
    self.Harvest = function(self, ...)
        self.inst.components.fueled:StopConsuming()
        if self.inst.Light then self.inst.Light:Enable(false) end
        return oldHarvest(self, ...)
    end
    local oldOnLoad = self.OnLoad
    self.OnLoad = function(self, data, ...)
        if data.product ~= nil and data.remainingtime ~= nil then self.inst.components.fueled:StartConsuming() end
        oldOnLoad(self, data, ...)
    end
end
AddPrefabPostInit("cookpot", needfuel)
-- if TUNING.NDNR_ACTIVE then AddPrefabPostInit("archive_cookpot", needfuel) end
AddPrefabPostInit("portablecookpot", needfuel)

local function updatestewers(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 18, {"fueledpot2hm"})
    for index, ent in ipairs(ents) do
        if ent and ent.components.fueled then
            ent.components.fueled:SetPercent(1)
            ent.components.fueled.currentfuel = ent.components.fueled.maxfuel
            ent.components.fueled:StopConsuming()
        end
    end
end
local monstermeats = {cookedmonstermeat = "cookedmeat", cookedmonstersmallmeat = "cookedsmallmeat", um_monsteregg_cooked = "bird_egg_cooked"}
local function updatecookitem(inst, chance)
    if inst.components.cooker then
        local CookItem = inst.components.cooker.CookItem
        inst.components.cooker.CookItem = function(self, item, chef, ...)
            if item and item:IsValid() and item.components.cookable and item.components.cookable.product and monstermeats[item.components.cookable.product] and
                math.random() < chance then
                item.oldproduct2hm = item.components.cookable.product
                item.components.cookable.product = monstermeats[item.components.cookable.product]
            end
            local result = CookItem(self, item, chef, ...)
            if item and item:IsValid() and item.components.cookable and item.oldproduct2hm then
                item.components.cookable.product = item.oldproduct2hm
                item.oldproduct2hm = nil
            end
            return result
        end
    end
end
AddPrefabPostInit("dragonflyfurnace", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, updatestewers)
    updatecookitem(inst, 0.15)
    inst.updatecookitem2hm = updatecookitem
end)
AddPrefabPostInit("cotl_tabernacle_level3", function(inst)
    if not TheWorld.ismastersim then return end
    updatecookitem(inst, 0.15)
end)
AddPrefabPostInit("cotl_tabernacle_level2", function(inst)
    if not TheWorld.ismastersim then return end
    updatecookitem(inst, 0.1)
end)

AddPrefabPostInit("cotl_tabernacle_level1", function(inst)
    if not TheWorld.ismastersim then return end
    updatecookitem(inst, 0.05)
end)

AddRecipePostInit("portablecookpot_item", function(inst) table.insert(inst.ingredients, Ingredient("redgem", 1)) end)
AddRecipePostInit("portableblender_item", function(inst) table.insert(inst.ingredients, Ingredient("redgem", 1)) end)
AddRecipePostInit("portablespicer_item", function(inst) table.insert(inst.ingredients, Ingredient("redgem", 1)) end)

if cookingchange == -2 then
    -- 食材拥有食材度除怪物肉度不可食用度外都减少0.25
    local function ProcessFoodTags(tags)
        for tag, tagval in pairs(tags) do
            if tag ~= "precook" and tag ~= "dried" and tag ~= "monster" and tag ~= "inedible" and tagval and type(tagval) == "number" then
                tags[tag] = math.max((tagval or 0) - 0.25, 0)
                if tags[tag] == 0 then tags[tag] = nil end
            end
        end
    end
    for _, tagstable in pairs(cooking.ingredients) do if tagstable.tags and type(tagstable.tags) == "table" then ProcessFoodTags(tagstable.tags) end end
    local oldAddIngredientValues = env.AddIngredientValues
    env.AddIngredientValues = function(names, tags, cancook, candry, ...)
        if tags and type(tags) == "table" then ProcessFoodTags(tags) end
        oldAddIngredientValues(names, tags, cancook, candry, ...)
    end
end
