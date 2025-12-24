--------------------------------
--[[ 导入科技,配方,动作,状态等]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local pcall = GLOBAL.pcall
local require = GLOBAL.require

-- 导入科技栏
local tab_status,recipe_tab = pcall(require,"resources/recipe_tab")
if tab_status then
    -- 导入自定义制作栏图标
    if recipe_tab.Recipetabs then
        for _,data in pairs(recipe_tab.Recipetabs) do
            AddRecipeTab(data.id, data.sort, data.atlas, data.icon, data.owner_tag, data.crafting_station)
        end
    end
end

-- 导入可制作物品/烹饪品/食物值
local thing_status,thing_data = pcall(require,"resources/recipe_thing")
if thing_status then
    -- 导入自定义可制作物品
    if thing_data.Recipes then
        for _,data in pairs(thing_data.Recipes) do
            --if false then -- 新版
            if AddRecipe2 then -- 新版
                --"MAGIC"
                --[[
                -- Recipe2 = Class(Recipe, function(self, name, ingredients, tech, config)
                --  if config ~= nil then
                --		Recipe._ctor(self, name, ingredients, nil, tech, config, config.min_spacing, config.nounlock, config.numtogive, config.builder_tag, config.atlas, config.image, config.testfn, config.product, config.build_mode, config.build_distance)
                --	else
                --		Recipe._ctor(self, name, ingredients, nil, tech)
                --	end

                -- Recipe = Class(function(self, name, ingredients, tab, level, placer_or_more_data, min_spacing, nounlock, numtogive, builder_tag, atlas, image, testfn, product, build_mode, build_distance)

                -- env.AddRecipe2 = function(name, ingredients, tech, config, filters)
                ]]
                if data.placer_or_more_data then
                    if type(data.placer_or_more_data) == "table" then
                        for k,v in pairs(data.placer_or_more_data) do
                            data[k] = v
                        end
                    else
                        data.placer = data.placer_or_more_data
                    end
                end
                AddRecipe2(data.name, data.ingredients, data.level, data,data.filters)
                --AddRecipe2(data.name, data.ingredients, data.level, data)
            else
                AddRecipe(data.name, data.ingredients, data.tab, data.level, data.placer_or_more_data, data.min_spacing, data.nounlock,data.numtogive, data.builder_tag, data.atlas, data.image, data.testfn)
            end
            -- 绑定图片名称和对应atlas ,以便在新建造栏favorite中显示贴图
            RegisterInventoryItemAtlas(data.atlas,data.image)
        end
    end
    -- 导入自定义食物值
    if thing_data.IngredientValues then
        for _,data in pairs(thing_data.IngredientValues) do
            AddIngredientValues(data.names, data.tags, data.cancook, data.candry)
        end
    end
    -- 导入自定义料理
    if thing_data.CookerRecipes then
        for _,data in pairs(thing_data.CookerRecipes) do
            for _,cooker in pairs(data.cookers) do
                AddCookerRecipe(cooker, data.recipe)
            end
        end
    end
end

 -- 导入服务器state
local server_states_status,server_states_data = pcall(require,"resources/server_states")
if server_states_status then
    -- 导入state
    if server_states_data.states then
        for _,state in pairs(server_states_data.states) do
            AddStategraphState("wilson", state)
        end
    end
end
-- 导入客户端state
local client_states_status,client_states_data = pcall(require,"resources/client_states")
if client_states_status then
     -- 导入state
     if client_states_data.states then
         for _,state in pairs(client_states_data.states) do
             AddStategraphState("wilson_client", state)
         end
     end
 end

-- 导入动作
local actions_status,actions_data = pcall(require,"resources/actions")
if actions_status then
    -- 导入自定义动作
    if actions_data.actions then
        for _,act in pairs(actions_data.actions) do
            local action = Action({priority = act.priority})
            action.id = act.id
            action.str = act.str
            action.strfn = act.strfn
            action.fn = act.fn
            AddAction(action)
            -- 声明动作名称(必须在添加动作之后),主要针对strfn的使用
            if act.stringsDefineFn then
                act.stringsDefineFn()
            end
            if act.actiondata then
                for k,data in pairs(act.actiondata) do
                    action[k] = data
                end
            end
            AddStategraphActionHandler("wilson",GLOBAL.ActionHandler(action, act.state))
            AddStategraphActionHandler("wilson_client",GLOBAL.ActionHandler(action,act.state))
        end
    end
    -- 导入动作与组件的绑定
    if actions_data.component_actions then
        for _,v in pairs(actions_data.component_actions) do
            local fn = function(...)
                local actions = GLOBAL.select (-2,...)
                for _,data in pairs(v.tests) do
                    if data  then
                        if data.testfn and data.testfn(...) then
                            data.action_id = string.upper( data.action_id )
                            table.insert( actions, GLOBAL.ACTIONS[data.action_id] )
                        end
                    end
                end
            end
            AddComponentAction(v.type, v.component, fn)
        end
    end
end

