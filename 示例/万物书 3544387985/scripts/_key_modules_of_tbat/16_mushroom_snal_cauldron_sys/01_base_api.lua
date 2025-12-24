--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    为了让锅 能预览配方成品。配方注册遵循下面原则：
    · 配方注册同时在客户端和服务端
    · 配方注册有增序索引id
    · 顺着索引id序号，找到第一个合适的配方立马退出寻找。
    · 【注意】配方物品种类同样，数量不一样的情况交由策划处理。代码上永远只找第一个符合的出来。
    · 每次只制作一组。多余的材料返还。
    · 所有配方都是指定物品指定数量



        data = {
            -----------------------------------------
            ---
                product = product,
                time = 30,      --- 烹饪时间
                stacksize = 1,  --- 每次烹饪得到个数
            -----------------------------------------
            --- 配方
                recipe = {
                    {item1,1},
                    {item1,1},
                    {item1,1},
                    {item1,1},
                },
            -----------------------------------------
            --- 锅子上的贴图
                overridebuild = "",
                overridesymbolname = "",
            -----------------------------------------
            --- ui 预览使用两种形式。fn 或者data
                preview = function(box)
                    
                end,
                -- preview = {
                --     atlas = "images/inventoryimages/test.xml",
                --     image = "test.tex",
                --     offset = Vector3(0,0,0),
                --     scale = Vector3(1,1,1),
                -- },
            -----------------------------------------                        
            ----------------------------------------- 
            -----------------------------------------                        
            --- 失败产品 ( 可以全是nil )
                fail_product_prefab = "item_name",  --- 为nil的时候，该配方不会失败
                fail_stacksize = 1,
                fail_overridebuild = "",
                fail_overridesymbolname = "",
            -----------------------------------------
            --- 失败UI预览预览使用两种形式。fn 或者data
                fail_preview = function(box)
                    
                end,
                -- fail_preview = {
                --     atlas = "images/inventoryimages/test.xml",
                --     image = "test.tex",
                --     offset = Vector3(0,0,0),
                --     scale = Vector3(1,1,1),
                -- },
            -----------------------------------------
        }

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- lib
    TBAT.MSC = Class()
    local self = TBAT.MSC
    self.recipes = {}
    self.recipes_prefab_index = {}
    self.index = 0
    self.avalable_items = {}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 注册配方
    function TBAT.MSC:RegisterRecipe(product,data)
        self.index = self.index + 1
        data.id = self.index
        data.product = product

        data.test_data = {}
        for i,v in ipairs(data.recipe) do
            local prefab = v[1]
            local num = v[2]
            self.avalable_items[prefab] = true
            data.test_data[prefab] = (data.test_data[prefab] or 0) + num
        end
        data.test = function(names)
            -- print("Recipe : ",product)
            -- for prefab, num in pairs(names) do
            --     print("+++++ slot:",prefab,num)
            -- end
            -- print("----- test:")
            -- for prefab, num in pairs(data.test_data) do
            --     print("----- test:",prefab,num)
            -- end
            
            local temp_list = {}
            --- 输入的物品数量少于当前配方要求
            for prefab, num in pairs(data.test_data) do
                if (names[prefab] or 0) < num then
                    return false
                end
                temp_list[prefab] = true
            end
            --- 输入的物品里有不是当前配方的东西的情况
            for prefab, _ in pairs(names) do
                if not temp_list[prefab] then
                    return false
                end
            end
            return true
        end
        self.recipes[self.index] = data
        self.recipes_prefab_index[product] = data
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 获取配方
    function TBAT.MSC:GetRecipeData(product)
        return self.recipes_prefab_index[product]
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 获取物品数量
    local function GetStack(item)
        local stackable_replica = item.replica.stackable or item.replica._.stackable
        if stackable_replica then
            return stackable_replica:StackSize()
        else
            return 1
        end
    end
    function TBAT.MSC:GetItemStack(item)
        return GetStack(item)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 预览配方成品
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    --- 上一次扫描，节省时间
        local last_prefab_1, last_prefab_2, last_prefab_3, last_prefab_4 = nil, nil, nil, nil
        local last_stack_1, last_stack_2, last_stack_3, last_stack_4 = nil, nil, nil, nil
        local last_product = nil
        local last_recipe_data = nil
    ---------------------------------------------------------------------------
    --- 核心TEST （通义AI优化）
        function TBAT.MSC:TestByItems(item1, item2, item3, item4)
            -- 快速验证物品有效性
            if not (item1 and item1:IsValid() and item2 and item2:IsValid() and item3 and item3:IsValid() and item4 and item4:IsValid()) then
                return nil
            end
            
            -- 获取物品状态（避免重复调用GetStack）
            local stack_1, stack_2, stack_3, stack_4 = GetStack(item1), GetStack(item2), GetStack(item3), GetStack(item4)
            local prefab_1, prefab_2, prefab_3, prefab_4 = item1.prefab, item2.prefab, item3.prefab, item4.prefab

            -- ✅ 优化点：直接比较缓存的8个独立值（快速短路）
            if prefab_1 == last_prefab_1 and stack_1 == last_stack_1 and
            prefab_2 == last_prefab_2 and stack_2 == last_stack_2 and
            prefab_3 == last_prefab_3 and stack_3 == last_stack_3 and
            prefab_4 == last_prefab_4 and stack_4 == last_stack_4 then
                return last_product, last_recipe_data
            end

            -- 构建物品名映射（仅在缓存未命中时执行）
            local names = {}
            names[prefab_1] = (names[prefab_1] or 0) + stack_1
            names[prefab_2] = (names[prefab_2] or 0) + stack_2
            names[prefab_3] = (names[prefab_3] or 0) + stack_3
            names[prefab_4] = (names[prefab_4] or 0) + stack_4


            -- 遍历配方（缓存未命中时执行）
            for _, current_recipe_data in ipairs(self.recipes) do
                if current_recipe_data.test(names) then
                    -- ✅ 优化点：仅更新缓存（避免重复字符串操作）
                    last_prefab_1, last_prefab_2, last_prefab_3, last_prefab_4 = prefab_1, prefab_2, prefab_3, prefab_4
                    last_stack_1, last_stack_2, last_stack_3, last_stack_4 = stack_1, stack_2, stack_3, stack_4
                    last_product, last_recipe_data = current_recipe_data.product, current_recipe_data
                    return last_product, last_recipe_data
                end
            end
            
            return nil
        end
    ---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品检查使用
    function TBAT.MSC:CheckItem(item)
        if item and item:IsValid() and self.avalable_items[item.prefab] then
            return true
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
