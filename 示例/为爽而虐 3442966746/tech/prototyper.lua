local TechTree = require("techtree")
-- 原型工具和制作站科技削弱
AddRecipePostInit("researchlab", function(inst) table.insert(inst.ingredients, Ingredient("gears", 1)) end)
AddRecipePostInit("researchlab2", function(inst) table.insert(inst.ingredients, Ingredient("gears", 4)) end)
AddRecipePostInit("researchlab4", function(inst) table.insert(inst.ingredients, Ingredient("greengem", 1)) end)
AddRecipePostInit("researchlab3", function(inst) table.insert(inst.ingredients, Ingredient("shadowheart", 1)) end)
AddRecipePostInit("seafaring_prototyper", function(inst) table.insert(inst.ingredients, Ingredient("driftwood_log", 8)) end)
AddRecipePostInit("tacklestation", function(inst) table.insert(inst.ingredients, Ingredient("slurtle_shellpieces", 4)) end)
AddRecipePostInit("cartographydesk", function(inst) table.insert(inst.ingredients, Ingredient("stash_map", 1)) end)
AddRecipePostInit("sculptingtable", function(inst) table.insert(inst.ingredients, Ingredient("fossil_piece", 1)) end)
-- 无限制开礼物
AddComponentPostInit("giftreceiver", function(self)
    self.giftmachine = TheWorld
    self.SetGiftMachine = nilfn
end)
-- 蓝图不可作祟
if GetModConfigData("Cartographer's Desk Make Blueprint") then AddPrefabPostInit("blueprint", function(inst) inst:AddTag("haunted") end) end
-- 锯马直接解锁
AddRecipePostInit("carpentry_station", function(inst)
    table.insert(inst.ingredients, Ingredient("gears", 2))
    inst.level = TechTree.Create()
end)
-- 优化科技研究动作
AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self)
    local specialtechs = {seafaring_prototyper = CRAFTING_FILTERS.SEAFARING.name, tacklestation = CRAFTING_FILTERS.FISHING.name}
    local researchtechlevels = {
        researchlab = TUNING.PROTOTYPER_TREES.SCIENCEMACHINE,
        researchlab2 = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE,
        researchlab3 = TUNING.PROTOTYPER_TREES.SHADOWMANIPULATOR,
        researchlab4 = TUNING.PROTOTYPER_TREES.PRESTIHATITATOR,
        turfcraftingstation = TUNING.PROTOTYPER_TREES.TURFCRAFTING,
        bookstation = TUNING.PROTOTYPER_TREES.BOOKCRAFT,
        carpentry_station = TUNING.PROTOTYPER_TREES.CARPENTRY_STATION,
        tacklestation = TUNING.PROTOTYPER_TREES.FISHING,
        seafaring_prototyper = TUNING.PROTOTYPER_TREES.SEAFARING_STATION
    }
    local sortedrecipes = {}
    for _, v in pairs(CRAFTING_FILTERS) do
        if v and v.recipes then
            for _, k in ipairs(FunctionOrValue(v.recipes)) do if not table.contains(sortedrecipes, k) then table.insert(sortedrecipes, k) end end
        end
    end
    for k, v in pairs(AllRecipes) do if not table.contains(sortedrecipes, k) then table.insert(sortedrecipes, k) end end
    local function whenopenprototyper(self, forceprefab)
        if not self or not self.owner then return end
        if not self.crafting_hud or not self.crafting_hud.valid_recipes then return end
        local builder = self.owner.replica and self.owner.replica.builder or nil
        if not builder then return end
        local prototyper = builder:GetCurrentPrototyper()
        local crafting_station_def = prototyper and prototyper.prefab and PROTOTYPER_DEFS[prototyper.prefab] or nil
        local at_crafting_station = crafting_station_def ~= nil and crafting_station_def.is_crafting_station
        if (prototyper and prototyper.prefab and not at_crafting_station) or forceprefab then
            self.prototyperprefab2hm = forceprefab or prototyper.prefab
            local text = crafting_station_def ~= nil and crafting_station_def.filter_text or STRINGS.NAMES[string.upper(self.prototyperprefab2hm)] or
                             self.prototyperprefab2hm
            self.crafting_station_filter:SetHoverText(text)
            self.search_box.textbox.prompt:SetString(text)
            if crafting_station_def ~= nil then
                self.crafting_station_filter.filter_img:SetTexture(crafting_station_def.icon_atlas, crafting_station_def.icon_image)
            else
                local recipe = AllRecipes[self.prototyperprefab2hm]
                if recipe then
                    local image = recipe.imagefn ~= nil and recipe.imagefn() or recipe.image
                    self.crafting_station_filter.filter_img:SetTexture(recipe:GetAtlas(), image, image ~= recipe.image and recipe.image or nil)
                else
                    self.crafting_station_filter.filter_img:SetTexture(resolvefilepath(CRAFTING_ICONS_ATLAS), "filter_none.tex")
                end
            end
            self.crafting_station_filter.filter_img:ScaleToSize(54, 54)
            self.crafting_station_filter:Show()
            if specialtechs[self.prototyperprefab2hm] then
                self:SelectFilter(specialtechs[self.prototyperprefab2hm], false)
                if self.recipe_grid.dirty then self:UpdateRecipeGrid(false) end
                return
            end
            local techlevel = researchtechlevels[self.prototyperprefab2hm]
            if techlevel == nil or (self.prototyperprefab2hm == "bookstation" and GetModConfigData("role_nerf") and GetModConfigData("wickerbottom")) then
                if not (builder and builder.classified) then return end
                techlevel = {}
                for i, v in ipairs(TechTree.AVAILABLE_TECH) do
                    local vlevel = builder.classified[string.lower(v) .. "level"]
                    techlevel[v] = vlevel and vlevel:value() or 0
                end
            end
            if not self.crafting_hud or not self.crafting_hud.valid_recipes then return end
            if self.current_filter_name ~= nil and self.filter_buttons[self.current_filter_name] ~= nil then
                self.filter_buttons[self.current_filter_name].button:Unselect()
            end
            self.filtered_recipes = {}
            for _, recipe_name in ipairs(sortedrecipes) do
                local data = self.crafting_hud and self.crafting_hud.valid_recipes and self.crafting_hud.valid_recipes[recipe_name]
                if data and data.meta and data.meta.build_state ~= "hide" and data.recipe and data.recipe.level then
                    local result
                    for key, value in pairs(data.recipe.level) do
                        if value ~= 0 then
                            if techlevel[key] ~= value then
                                result = false
                                break
                            else
                                result = true
                            end
                        end
                    end
                    if result == true then table.insert(self.filtered_recipes, data) end
                end
            end
            self:UpdateRecipeGrid(self.focus and not TheFrontEnd.tracking_mouse)

            -- self.current_filter_name = nil
        else
            self.prototyperprefab2hm = nil
        end
    end
    self.whenopenprototyper = whenopenprototyper
    local OnCraftingMenuOpen = self.OnCraftingMenuOpen
    self.OnCraftingMenuOpen = function(self, ...)
        local ishudopen = self.crafting_hud and self.crafting_hud:IsCraftingOpen()
        OnCraftingMenuOpen(self, ...)
        if not ishudopen or (self.filtered_recipes and #self.filtered_recipes == 0) then whenopenprototyper(self) end
    end
    if self.crafting_station_filter and self.crafting_station_filter.button then
        local onclick = self.crafting_station_filter.button.onclick
        self.crafting_station_filter.button.onclick = function(...)
            if self.prototyperprefab2hm and whenopenprototyper then
                whenopenprototyper(self, self.prototyperprefab2hm)
            elseif onclick then
                onclick(...)
            end
        end
    end
end)
AddClassPostConstruct("screens/playerhud", function(self)
    local OpenCrafting = self.OpenCrafting
    self.OpenCrafting = function(self, ...)
        local ishudopen = self:IsCraftingOpen()
        OpenCrafting(self, ...)
        if ishudopen and self.controls and self.controls.craftingmenu and self.controls.craftingmenu.craftingmenu and
            self.controls.craftingmenu.craftingmenu.whenopenprototyper then
            self.controls.craftingmenu.craftingmenu:whenopenprototyper()
        end
    end
end)
