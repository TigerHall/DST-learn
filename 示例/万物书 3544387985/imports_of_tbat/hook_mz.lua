-- 食物buff双倍恢复
AddComponentPostInit("edible", function(edible)
    local oldGetSanity = edible.GetSanity
    edible.GetSanity = function(self, eater, ...)
        if eater and eater:HasDebuff("tbat_food_double_recover") then
            local sanity = oldGetSanity(self, eater, ...)
            if sanity > 0 then
                return sanity * 2
            end
            return oldGetSanity(self, eater, ...)
        end
        return oldGetSanity(self, eater, ...)
    end

    local oldGetHunger = edible.GetHunger
    edible.GetHunger = function(self, eater, ...)
        if eater and eater:HasDebuff("tbat_food_double_recover") then
            local hunger = oldGetHunger(self, eater, ...)
            if hunger > 0 then
                return hunger * 2
            end
            return oldGetHunger(self, eater, ...)
        end
        return oldGetHunger(self, eater, ...)
    end

    local oldGetHealth = edible.GetHealth
    edible.GetHealth = function(self, eater, ...)
        if eater and eater:HasDebuff("tbat_food_double_recover") then
            local health = oldGetHealth(self, eater, ...)
            if health > 0 then
                return health * 2
            end
            return oldGetHealth(self, eater, ...)
        end
        return oldGetHealth(self, eater, ...)
    end
end)
-- 全科技buff
AddComponentPostInit("builder", function(self)
    local old_KnowsRecipe = self.KnowsRecipe
    self.KnowsRecipe = function(self, recipe, ignore_tempbonus, ...)
        if type(recipe) == "string" then
            recipe = GetValidRecipe(recipe)
        end
        if recipe == nil then
            return false
        end
        if self.inst and self.inst:HasTag("tbat_wishnote_buff") then
            return true
        end
        return old_KnowsRecipe(self, recipe, ignore_tempbonus, ...)
    end
end)
AddClassPostConstruct("components/builder_replica", function(self)
    local old_KnowsRecipe = self.KnowsRecipe
    self.KnowsRecipe = function(self, recipe, ignore_tempbonus, ...)
        if type(recipe) == "string" then
            recipe = GetValidRecipe(recipe)
        end
        if self.inst and self.inst:HasTag("tbat_wishnote_buff") then
            return true
        end
        return old_KnowsRecipe(self, recipe, ignore_tempbonus, ...)
    end
end)

-- 屏蔽暗影伞的那个圈
local function onchangetbatsensangucanopyzone(inst, underleaves)
    inst._tbatsensanguunderleafcanopy:set(underleaves)
end
AddPlayerPostInit(function(inst)
    inst._tbatsensanguunderleafcanopy = net_bool(inst.GUID, "localplayer._tbatsensanguunderleafcanopy", "tbatsensanguunderleafcanopydirty")
    inst:ListenForEvent("onchangetbatsensangucanopyzone", onchangetbatsensangucanopyzone)
end)

AddComponentPostInit("raindomewatcher", function(raindomewatcher)
    local oldOnUpdate = raindomewatcher.OnUpdate
    raindomewatcher.OnUpdate = function(self, dt)
        if self.inst and self.inst._tbatsensanguunderleafcanopy ~= nil and self.inst._tbatsensanguunderleafcanopy:value() then
            self.underdome = false
            self.inst:PushEvent("exitraindome")
        else
            return oldOnUpdate(self, dt)
        end
    end
end)

-- 物品可交易
local tradabletable = { 'tbat_item_crystal_bubble'}
if TheNet:GetIsServer() then
    for _, v in ipairs(tradabletable) do
        AddPrefabPostInit(v, function(inst)
            if inst.components.tradable == nil then
                inst:AddComponent("tradable") -- 可交易
            end
        end)
    end
end

-- buff显示
AddReplicableComponent("tbat_showbufftime")
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        if TUNING.TBAT_SHOW_BUFFS then
            inst:AddComponent("tbat_showbufftime") --buff信息显示
        end
    end
end)
