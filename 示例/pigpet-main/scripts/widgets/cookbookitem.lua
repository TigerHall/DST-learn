-- 优化并注释版：CookbookItem（食谱条目 UI），变量名统一为 snake_case（仅修改变量名，不改函数名）

local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"

-- CookbookItem 类：表示食谱列表中的一项条目
-- 参数：
--   cookbook: 上层食谱界面控制器（用于刷新等回调）
--   ingredient: 包含 recipe 和 selected_ingredient 的表（由自动烹饪逻辑生成）
--   pos_x, pos_y: 背景在父控件内的位置
--   scale: 缩放系数
local CookbookItem = Class(Widget, function(self, cookbook, ingredient, pos_x, pos_y, scale)
    Widget._ctor(self, "CookbookItem")
    self.ingredient = ingredient
    self.cookbook = cookbook

    -- 背景图（作为整体容器）
    self.bg = self:AddChild(Image("images/recipe_hud.xml", "recipe_hud.tex"))
    self.bg:SetPosition(pos_x, pos_y)
    self.bg:SetScale(scale * 0.5)

    -- 内容层（相对于背景的位置）
    self.contents = self.bg:AddChild(Widget(""))
    self.contents:SetPosition(20, 120, 0)

    -- 菜名（从 STRINGS 中取本地化名字）
    self.name = self.contents:AddChild(Text(UIFONT, 42))
    self.name:SetPosition(3, 0, 0)
    -- ingredient.recipe.name 应为 prefab 名；用大写索引 STRINGS.NAMES 获取本地化名字
    self.name:SetString(STRINGS.NAMES[string.upper(ingredient.recipe.name)])

    -- 菜品图标（inventoryimages）
    self.image = self.contents:AddChild(Image(resolvefilepath("images/inventoryimages.xml"), ingredient.recipe.name .. ".tex"))
    self.image:SetPosition(-90, 0, 0)

    -- 三维属性文本：饥饿/理智/生命（显示 recipe 表里的数值）
    self.hunger_text = self.contents:AddChild(Text(BODYTEXTFONT, 28))
    self.hunger_text:SetPosition(5, 82, 0)
    self.hunger_text:SetString(tostring(ingredient.recipe.hunger))

    self.sanity_text = self.contents:AddChild(Text(BODYTEXTFONT, 28))
    self.sanity_text:SetPosition(-73, 54, 0)
    self.sanity_text:SetString(tostring(ingredient.recipe.sanity))

    self.health_text = self.contents:AddChild(Text(BODYTEXTFONT, 28))
    self.health_text:SetPosition(84, 54, 0)
    self.health_text:SetString(tostring(ingredient.recipe.health))

    -- 显示所需食材的图标（按照 selected_ingredient 列表）
    local num_ingredients = #ingredient.selected_ingredient
    local ingredient_spacing = 70
    local ingredient_start_x = -((num_ingredients - 1) * ingredient_spacing) / 2
    for i, selected_item in ipairs(ingredient.selected_ingredient) do
        -- selected_item.inst 是实际物品实体，显示对应 prefab 的图标
        local ingredient_image = self.contents:AddChild(Image(resolvefilepath("images/inventoryimages.xml"), selected_item.inst.prefab .. ".tex"))
        ingredient_image:SetPosition(ingredient_start_x + (i - 1) * ingredient_spacing, -70, 0)
    end
    if ingredient.can_cook then
        -- 烹饪按钮：点击时尝试把选中的食材放入附近空闲的烹饪锅并开始烹饪
        self.cook_button = self.contents:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.cook_button:SetPosition(0, -280)
        self.cook_button:SetScale(scale)
        self.cook_button:SetText("烹饪")
        self.cook_button:SetFont(BUTTONFONT)
        self.cook_button:SetOnClick(function()
            self:Cook()
        end)
    end
end)

-- 辅助函数：判断给定实体是否为“可用的烹饪锅”
-- 语义：返回 true 表示该实体是 cookpot、处于空闲状态且锅内没有食材
-- 兼容性说明：不同版本 stewer 组件的 API 可能不同，优先使用组件方法，其次 fallback 到常见字段
local function FindAvailableCookpot(ent)
    if not ent or ent.prefab ~= "cookpot" then
        return false
    end

    local stewer_comp = ent.components.stewer
    if not stewer_comp then
        -- 该实体没有 stewer 组件，不能用作 cookpot
        return false
    end

    -- 检查是否正在烹饪或已经完成（兼容不同实现）
    -- 优先调用方法（如果存在），否则检查常见字段
    local is_cooking = false
    if stewer_comp.IsCooking then
        local ok, val = pcall(function() return stewer_comp:IsCooking() end)
        is_cooking = ok and val or false
    elseif stewer_comp.cooking ~= nil then
        is_cooking = stewer_comp.cooking
    end

    local is_done = false
    if stewer_comp.IsDone then
        local ok, val = pcall(function() return stewer_comp:IsDone() end)
        is_done = ok and val or false
    elseif stewer_comp.done ~= nil then
        is_done = stewer_comp.done
    end

    if is_cooking or is_done then
        return false
    end

    -- 检查容器内是否已有食材（如果 container 组件存在）
    if ent.components.container then
        local container_slots = ent.components.container:GetNumSlots()
        for i = 1, container_slots do
            local slot_item = ent.components.container:GetItemInSlot(i)
            if slot_item then
                -- 有任意物品则认为锅不空闲
                return false
            end
        end
    end

    return true
end

-- 方法：把选中的食材放入附近的可用烹饪锅并开始烹饪
function CookbookItem:Cook()
    -- 获取本地玩家（单机模式）
    local player = GetPlayer()
    if not player then
        return
    end

    -- 在玩家附近查找任意一个满足 FindAvailableCookpot 的实体（查找半径为 10）
    local cook_pot = FindEntity(player, 10, function(ent)
        return FindAvailableCookpot(ent)
    end)

    if cook_pot == nil then
        -- 没找到可用烹饪锅，提示玩家
        if player.components.talker then
            player.components.talker:Say("附近没有可用的烹饪锅")
        end
        return
    end

    -- 将选中的食材逐一放入锅里
    for _, selected_item in ipairs(self.ingredient.selected_ingredient) do
        -- 如果是堆叠的物品，取出一个单位（stackable:Get 会返回一个新实体）
        if selected_item.inst.components.stackable and selected_item.inst.components.stackable.stacksize > 1 then
            local single_unit = selected_item.inst.components.stackable:Get(1)
            if single_unit then
                cook_pot.components.container:GiveItem(single_unit)
            end
        else
            -- 非堆叠或仅剩一个，直接移动实体到锅里
            cook_pot.components.container:GiveItem(selected_item.inst)
            -- 同时尝试从玩家背包移除（防止重复）
            if player.components.inventory then
                player.components.inventory:RemoveItem(selected_item.inst, true) -- true = do not spawn on ground
            end
        end
    end

    -- 启动烹饪（开始计时）
    if cook_pot.components.stewer and cook_pot.components.stewer.StartCooking then
        cook_pot.components.stewer:StartCooking()
    end

    -- 刷新上层食谱界面，反映已搬运的食材状态
    if self.cookbook and self.cookbook.RefreshItems then
        self.cookbook:RefreshItems()
    end
end

return CookbookItem