TUNING.ANCIENT_ALTAR_COMPLETE_WORK = 4
local shadowchesspieces = {"shadow_knight", "shadow_bishop", "shadow_rook"}
-- 交换暴动和平息的阶段时间
local oldshort = math.min(TUNING.NIGHTMARE_SEGS.CALM, TUNING.NIGHTMARE_SEGS.WILD)
local oldlong = math.max(TUNING.NIGHTMARE_SEGS.CALM, TUNING.NIGHTMARE_SEGS.WILD)
TUNING.NIGHTMARE_SEGS.CALM = oldshort
TUNING.NIGHTMARE_SEGS.WILD = oldlong

local function processrecipe(inst, recipe, worker)
    if inst:IsValid() and recipe then
        worker = worker or inst
        if recipe.name == "greenamulet" or recipe.name == "greenstaff" then
            SpawnPrefab("sporecloud").Transform:SetPosition(worker.Transform:GetWorldPosition())
        elseif recipe.name == "yellowamulet" or recipe.name == "yellowstaff" then
            if TheWorld.has_ocean then
                SpawnPrefab("sporecloud").Transform:SetPosition(worker.Transform:GetWorldPosition())
            else
                CreateMiasma2hm(inst, true)
            end
        elseif recipe.name == "orangeamulet" or recipe.name == "orangestaff" then
            local sinkhole = SpawnPrefab("antlion_sinkhole")
            sinkhole.Transform:SetPosition(inst.Transform:GetWorldPosition())
            sinkhole:PushEvent("startcollapse")
        elseif recipe.name == "telestaff" or recipe.name == "purpleamulet" then
            if math.random() < 0.5 then StalkerSpawnSnares2hm(inst, {worker}) end
            SpawnSpell2hm(inst, math.random() <= 0.5 and "deer_fire_circle" or "deer_ice_circle", 6, worker)
        elseif recipe.name == "icestaff" or recipe.name == "blueamulet" then
            SpawnSpell2hm(inst, "deer_ice_circle", 6, worker)
        elseif recipe.name == "firestaff" or recipe.name == "amulet" then
            SpawnSpell2hm(inst, "deer_fire_circle", 6, worker)
        elseif recipe.nounlock then
            SpawnMonster2hm(worker, "nightmarebeak")
            SpawnMonster2hm(worker, math.random() < 0.5 and "knight_nightmare" or "bishop_nightmare", 4)
        else
            SpawnMonster2hm(worker, "nightmarebeak")
        end
    end
end

AddPrefabPostInit("ancient_altar", function(inst)
    if TheWorld.ismastersim then
        inst.fx = SpawnPrefab("tophat_shadow_fx")
        inst.fx.entity:SetParent(inst.entity)
        inst.fx.Transform:SetScale(2, 3, 2)
    end
    if not TheWorld.ismastersim or not inst.components.prototyper or not inst.components.workable then return inst end
    inst.components.prototyper.trees.SCIENCE = 3
    inst.components.prototyper.trees.MAGIC = 3
    local ancient_altar_config = GetModConfigData("ancient_altar")
    local oldonactivate = inst.components.prototyper.onactivate
    inst.components.prototyper.onactivate = function(inst, doer, recipe, ...)
        oldonactivate(inst, doer, recipe, ...)
        if (ancient_altar_config == -1 or ancient_altar_config == -3) and inst.components.workable and doer.components.sanity and doer.components.sanity:GetPercent() < 0.95 and math.random() <
            (1 - doer.components.sanity:GetPercent() * 3 / 4) then
            inst.components.workable:WorkedBy(doer, 1)
            processrecipe(inst, recipe, doer)
        end
    end
    local oldonwork = inst.components.workable.onwork
    inst.components.workable:SetOnWorkCallback(function(inst, worker, ...)
        if oldonwork then oldonwork(inst, worker, ...) end
        DoRandomRuinMagic2hm(inst, worker)
    end)
    local oldonfinish = inst.components.workable.onfinish
    inst.components.workable:SetOnFinishCallback(function(inst, worker, ...)
        oldonfinish(inst, worker, ...)
        if worker and worker:HasTag("player") then
            SpawnMonster2hm(worker, shadowchesspieces[math.random(3)])
            SpawnMonster2hm(worker, shadowchesspieces[math.random(3)])
            SpawnMonster2hm(worker, "oceanhorror2hm")
        end
    end)
end)

AddPrefabPostInit("ancient_altar_broken", function(inst)
    if TheWorld.ismastersim then
        inst.fx = SpawnPrefab("tophat_shadow_fx")
        inst.fx.entity:SetParent(inst.entity)
        inst.fx.Transform:SetScale(2, 3, 2)
    end
    if not TheWorld.ismastersim or not inst.components.prototyper or not inst.components.workable then return inst end
    inst.components.prototyper.trees.SCIENCE = 2
    inst.components.prototyper.trees.MAGIC = 2
    local ancient_altar_config = GetModConfigData("ancient_altar")
    local oldonactivate = inst.components.prototyper.onactivate
    inst.components.prototyper.onactivate = function(inst, doer, recipe, ...)
        oldonactivate(inst, doer, recipe, ...)
        if (ancient_altar_config == -1 or ancient_altar_config == -3) and 
           inst.components.workable and doer.components.sanity and 
           math.random() < (1 - doer.components.sanity:GetPercent() * 2 / 3) then
            inst.components.workable:WorkedBy(doer, 1)
            processrecipe(inst, recipe, doer)
        end
    end
    local oldonfinish = inst.components.workable.onfinish
    inst.components.workable:SetOnFinishCallback(function(inst, worker, ...)
        oldonfinish(inst, worker, ...)
        if worker and worker:HasTag("player") then
            SpawnMonster2hm(worker, shadowchesspieces[math.random(3)])
        end
    end)
end)



local moonprototypers = {
    "moon_altar",
    "moon_altar_cosmic",
    "moon_altar_astral",
    "alterguardian_phase1",
    "alterguardian_phase2",
    "alterguardian_phase3",
    "moonrockseed"
}

AddComponentPostInit("prototyper", function(self)
    local Activate = self.Activate
    self.Activate = function(self, doer, recipe, ...)
        if table.contains(moonprototypers, self.inst.prefab) and not self.inst._upgraded and doer and doer.components.sanity and
            doer.components.sanity:GetPercent() > 0.05 then
            if math.random() < doer.components.sanity:GetPercent() * 3 / 4 then
                local cloud = SpawnPrefab("sleepcloud_lunar")
                if cloud then
                    cloud.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                    if self.lastcloud2hm and self.lastcloud2hm:IsValid() and self.lastcloud2hm:IsNear(cloud, 1) then
                        self.lastcloud2hm:Remove()
                    end
                    self.lastcloud2hm = cloud
                    self.inst:ListenForEvent("onremove", function() if self.lastcloud2hm == cloud then self.lastcloud2hm = nil end end, cloud)
                    cloud:SetOwner(self.inst)
                    if cloud._drowsytask and cloud._drowsytask.fn then
                        local fn = cloud._drowsytask.fn
                        cloud._drowsytask.fn = function(...)
                            local oldGetPVPEnabled = getmetatable(TheNet).__index["GetPVPEnabled"]
                            getmetatable(TheNet).__index["GetPVPEnabled"] = truefn
                            fn(...)
                            getmetatable(TheNet).__index["GetPVPEnabled"] = oldGetPVPEnabled
                        end
                    end
                end
                -- elseif math.random() < doer.components.sanity:GetPercent() then
                --     local monster = SpawnPrefab("gestalt")
                --     if monster then
                --         monster.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                --         monster.components.combat:SetTarget(doer)
                --         monster.components.combat:TryAttack()
                --     end
            end
        end
        return Activate(self, doer, recipe, ...)
    end
end)

-- 建造护符不再能使无法解锁原型的物品（远古天体科技等）制作材料减半了
local ancient_altar_config = GetModConfigData("ancient_altar")
if ancient_altar_config == -2 or ancient_altar_config == -3 then
    AddComponentPostInit("builder", function(self)
        local _GetIngredients = self.GetIngredients
        function self:GetIngredients(recname)
            local recipe = AllRecipes[recname]
            if recipe then
                local ingredients = {}
                local discounted = false
                -- 对于nounlock配方，临时禁用护符效果
                local original_ingredientmod = self.ingredientmod
                if recipe.nounlock then
                    self.ingredientmod = 1
                end
                
                for k,v in pairs(recipe.ingredients) do
                    if v.amount > 0 then
                        local amt = math.max(1, RoundBiasedUp(v.amount * self.ingredientmod))
                        local items = self.inst.components.inventory:GetCraftingIngredient(v.type, amt)
                        ingredients[v.type] = items
                        if amt < v.amount then
                            discounted = true
                        end
                    end
                end
                
                -- 恢复原来的ingredientmod
                self.ingredientmod = original_ingredientmod
                
                return ingredients, discounted
            end
        end
        
        local _HasIngredients = self.HasIngredients
        function self:HasIngredients(recipe)
            if type(recipe) == "string" then
                recipe = GetValidRecipe(recipe)
            end
            if recipe and recipe.nounlock then
                -- 对于nounlock配方，临时禁用护符效果进行检查
                local original_ingredientmod = self.ingredientmod
                self.ingredientmod = 1
                local result = _HasIngredients(self, recipe)
                self.ingredientmod = original_ingredientmod
                return result
            end
            return _HasIngredients(self, recipe)
        end
    end)

    AddComponentPostInit("builder_replica", function(self)
        local _HasIngredients = self.HasIngredients
        function self:HasIngredients(recipe)
        if self.inst.components.builder ~= nil then
            return self.inst.components.builder:HasIngredients(recipe)
        elseif self.classified ~= nil then
            if type(recipe) == "string" then 
                recipe = GetValidRecipe(recipe)
            end
            if recipe ~= nil then
                if self.classified.isfreebuildmode:value() then
                    return true
                end
                
                -- 对于nounlock配方，强制使用原始材料数量检查
                local ingredientmod = (recipe.nounlock and 1.0) or self:IngredientMod()
                
                for i, v in ipairs(recipe.ingredients) do
                    if not self.inst.replica.inventory:Has(v.type, math.max(1, RoundBiasedUp(v.amount * ingredientmod)), true) then
                        return false
                    end
                end
                for i, v in ipairs(recipe.character_ingredients) do
                    if not self:HasCharacterIngredient(v) then
                        return false
                    end
                end
                for i, v in ipairs(recipe.tech_ingredients) do
                    if not self:HasTechIngredient(v) then
                        return false
                    end
                end
                return true
            end
        end
            return false
        end
    end)
end

-- 修改制作界面材料组件的护符检查逻辑
if ancient_altar_config == -2 or ancient_altar_config == -3 then
    local CraftingMenuIngredients = require("widgets/redux/craftingmenu_ingredients")
    local original_SetRecipe = CraftingMenuIngredients.SetRecipe
    function CraftingMenuIngredients:SetRecipe(recipe)
    if recipe and recipe.nounlock then
        local owner = self.owner
        if owner and owner.replica and owner.replica.builder then
            local builder = owner.replica.builder
            local original_IngredientMod = builder.IngredientMod
            
            -- 临时强制返回1.0
            builder.IngredientMod = function(self) return 1.0 end

            original_SetRecipe(self, recipe)

            builder.IngredientMod = original_IngredientMod
            return
        end
    end
        
        original_SetRecipe(self, recipe)
    end
    
    AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
        local _RebuildRecipes = self.RebuildRecipes
        function self:RebuildRecipes()
            _RebuildRecipes(self)
            
            if self.owner and self.owner.replica and self.owner.replica.builder then
                local builder = self.owner.replica.builder
                local freecrafting = builder:IsFreeBuildMode()
                local tech_trees = builder:GetTechTrees()
                
                for recipe_name, recipe_data in pairs(self.valid_recipes) do
                    if recipe_data.recipe and recipe_data.recipe.nounlock then
                        local meta = recipe_data.meta
                        local recipe = recipe_data.recipe
                        
                        -- 重新计算材料检查，不使用护符折扣
                        local has_ingredients_no_discount = true
                        if not freecrafting then
                            for i, v in ipairs(recipe.ingredients) do
                                if not self.owner.replica.inventory:Has(v.type, v.amount, true) then
                                    has_ingredients_no_discount = false
                                    break
                                end
                            end
                            if has_ingredients_no_discount then
                                for i, v in ipairs(recipe.character_ingredients) do
                                    if not builder:HasCharacterIngredient(v) then
                                        has_ingredients_no_discount = false
                                        break
                                    end
                                end
                            end
                            if has_ingredients_no_discount then
                                for i, v in ipairs(recipe.tech_ingredients) do
                                    if not builder:HasTechIngredient(v) then
                                        has_ingredients_no_discount = false
                                        break
                                    end
                                end
                            end
                        end

                        -- 配方是否解锁
                        local knows_recipe = builder:KnowsRecipe(recipe)
                        local can_prototype = CanPrototypeRecipe(recipe.level, tech_trees)
                        local is_build_tag_restricted = not builder:CanLearn(recipe.name)
                        
                        if builder:IsBuildBuffered(recipe.name) and not is_build_tag_restricted then
                            meta.can_build = true
                            meta.build_state = "buffered"
                        elseif freecrafting then
                            meta.can_build = true
                            meta.build_state = "freecrafting"
                        elseif is_build_tag_restricted then
                            meta.can_build = false
                            meta.build_state = "hide"
                        elseif knows_recipe then
                            meta.can_build = has_ingredients_no_discount
                            meta.build_state = has_ingredients_no_discount and "has_ingredients" or "no_ingredients"
                        elseif can_prototype then
                            meta.can_build = has_ingredients_no_discount
                            meta.build_state = has_ingredients_no_discount and "has_ingredients" or "no_ingredients"
                        else
                            meta.can_build = false
                            meta.build_state = "hide"
                        end
                    end
                end
            end
        end
    end)
end





