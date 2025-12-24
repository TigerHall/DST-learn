local cooking = require("cooking")
local selected_count = 4
local can_cook_cache = {}

local function MakeIngredientNode(inst, count)
    return {
        inst = inst,
        count = count
    }
end

-- 获取唯一的key,根据配方，因为不同的配方可以合成相同的物品
local function GetIngredientKey(selected_ingredient)
    local ings_list = {}
    for _, item in ipairs(selected_ingredient) do
        table.insert(ings_list, item.inst.prefab)
    end
    table.sort(ings_list)
    return table.concat(ings_list, ","), ings_list
end


-- 根据 selectedIngredient（节点数组）计算配方产物与烹饪时间，带缓存
local function CalculateRecipeForSelectedNodes(selected_ingredient)
    if #selected_ingredient ~= selected_count then
        return false
    end
    local key, ings_list  = GetIngredientKey(selected_ingredient)
    if can_cook_cache[key] then
        local cache = can_cook_cache[key]
        return cache.product, cache.cooktime
    end
    local product, cooktime = cooking.CalculateRecipe("cookpot", ings_list)
    local cache = { product = product, cooktime = cooktime }
    can_cook_cache[key] = cache
    return product, cooktime
end

-- 保存从玩家背包组合中首次发现的某道菜（只保存代表性一个组合）
local function SaveInventoryRecipeResult(selected_ingredient, product, cooktime, product_result, can_cook)
    if not product_result[product] then
        local cook_table = {}
        cook_table.cooktime = cooktime
        cook_table.recipe = cooking.recipes["cookpot"][product]
        cook_table.ingredients_list = {}
        product_result[product] = cook_table
    end
   
    -- 复制配方
    local tmp = {}
    tmp.can_cook = can_cook
    tmp.selected_ingredient = {}
    for _, item in ipairs(selected_ingredient) do
        table.insert(tmp.selected_ingredient, item)
    end
    table.insert(product_result[product].ingredients_list, tmp)
end

-- 递归枚举玩家背包（nodes 为 {inst,count} 节点）中所有可能的组合（考虑堆叠数量）

local function EnumerateInventoryRecipeCombinations(selected_ingredient, start_index, n, nodes, product_result, can_cook)
    local nodes_len = #nodes

    -- 剪枝：如果还需要 n 个但已无可用节点，直接返回
    if start_index > nodes_len then
        return
    end

    -- 计算剩余总数量（从 start_index 到末尾），若不足则剪枝
    local remaining_total = 0
    for i = start_index, nodes_len do
        remaining_total = remaining_total + (nodes[i].count or 0)
    end
    if remaining_total < n then
        return
    end

    -- 基底：选满 n（即 selected_count）后才计算配方
    if n == 0 then
        local product, cooktime = CalculateRecipeForSelectedNodes(selected_ingredient)
        if product and product ~= "wetgoopnil" and product ~= "wetgoop" then
            SaveInventoryRecipeResult(selected_ingredient, product, cooktime, product_result, can_cook)
        end
        return
    end

    -- 热路径：用局部别名加速
    local sel = selected_ingredient

    for i = start_index, nodes_len do
        local node = nodes[i]
        if node.count and node.count > 0 then
            -- 选取一个单位
            node.count = node.count - 1
            sel[#sel + 1] = node

            -- 允许重复选择同一节点 -> 递归仍从 i 开始
            EnumerateInventoryRecipeCombinations(sel, i, n - 1, nodes, product_result, can_cook)

            -- 回溯
            sel[#sel] = nil
            node.count = node.count + 1
        end
    end
end

-- 从容器收集可用的烹饪原料（转换为节点并截断到 selected_count）
local function CollectContainerIngredients(container, result_list)
    for i = 1, container:GetNumSlots() do
        local item = container:GetItemInSlot(i)
        if item and cooking.IsCookingIngredient(item.prefab) then
            local count = 1
            if item.components.stackable then
                count = item.components.stackable:StackSize()
            end
            if count > selected_count then
                count = selected_count
            end
            table.insert(result_list, MakeIngredientNode(item, count))
        end
    end
end

-- 对外 API：获取玩家当前背包/装备中可在 cookpot 下锅制作的菜品（考虑物品数量）
local function GetAvailableInventoryCookpotRecipes()
    local player = GetPlayer()
    local ingredients_list = {}
    CollectContainerIngredients(player.components.inventory, ingredients_list)
    local back_item = player.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
    if back_item and back_item.components and back_item.components.container then
        CollectContainerIngredients(back_item.components.container, ingredients_list)
    end

    local product_result = {}
    EnumerateInventoryRecipeCombinations({}, 1, selected_count, ingredients_list, product_result, true)
    return product_result
end

local cook_book_recipes = {}
-- 有些食材名字似乎没有，需要有一个对应关系，比如 egg->bird_egg
local ingredient_aliases = {
    egg = "bird_egg",
    -- 其他食材的别名可以在这里添加
}

local function GenerateCookbookRecipes()
    -- 如果 cook_book_recipes 不为空则直接返回
    if next(cook_book_recipes) ~= nil then
      return cook_book_recipes
    end


  local ingredients = {}
  for name, _ in pairs(cooking.ingredients) do
    -- 处理食材别名
    local alias = ingredient_aliases[name]
    if alias then
      name = alias
    end

    local inst = {}
    inst.prefab = name
    table.insert(ingredients, MakeIngredientNode(inst, 4))
    if #ingredients >= 20 then
      break
    end
  end
  
  EnumerateInventoryRecipeCombinations({}, 1, selected_count, ingredients, cook_book_recipes, false)
  return cook_book_recipes
end

-- 对外导出：保留兼容的函数名
return { GetAvailableInventoryCookpotRecipes = GetAvailableInventoryCookpotRecipes, GenerateCookbookRecipes = GenerateCookbookRecipes}