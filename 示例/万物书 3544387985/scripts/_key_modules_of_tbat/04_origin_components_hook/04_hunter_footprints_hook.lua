---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    本文件用来  处理 脚印追踪  翻找出来的最终 生成怪物。

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- AI 来的代码。只能hook 实例化后的组件。(豆包AI 和 通义AI同时轮流搞，才搞定，现在的AI还是挺菜的)
    local function HookLocalFunction(hunter_instance, target_name, hook_callback, __common_methods)
        if not hunter_instance or type(hunter_instance) ~= "table" then
            print("[tbat][hunter][error] Invalid hunter instance")
            return false
        end
        if not target_name or type(target_name) ~= "string" then
            print("[tbat][hunter][error] Invalid target function name")
            return false
        end
        if not hook_callback or type(hook_callback) ~= "function" then
            print("[tbat][hunter][error] Invalid hook callback")
            return false
        end

        local original_func = nil  -- 每次 Hook 独立记录原始函数

        -- 关键点：将 visited_funcs 移到 find_and_hook 内部，每次递归都重新初始化
        local function find_and_hook(func, target_name, depth)
            local visited_funcs = {}  -- 每次调用 find_and_hook 时创建新表，避免跨 Hook 污染
            local function recursive_search(func, target_name, depth)
                if depth > 50 then
                    print("[tbat][hunter] ⚠️ 递归深度超过限制（", depth, "），跳过")
                    return false
                end
                if visited_funcs[func] then
                    return false  -- 仅在当前 Hook 内标记已访问，不影响其他 Hook
                end
                visited_funcs[func] = true

                for i = 1, math.huge do
                    local name, value = debug.getupvalue(func, i)
                    if not name then break end

                    if name == target_name and type(value) == "function" then
                        original_func = value
                        debug.setupvalue(func, i, function(...)
                            return hook_callback(original_func, ...)
                        end)
                        print("[tbat][hunter] ✅ 成功 Hook local 函数:", target_name)
                        return true
                    elseif type(value) == "function" then
                        if recursive_search(value, target_name, depth + 1) then
                            return true
                        end
                    end
                end
                return false
            end
            return recursive_search(func, target_name, depth or 0)
        end

        -- （后续查找逻辑不变：先查构造函数，再查 common_methods，最后查所有实例方法）
        if hunter_instance._ctor and type(hunter_instance._ctor) == "function" then
            if find_and_hook(hunter_instance._ctor, target_name, 0) then
                return true
            end
        end

        local common_methods = __common_methods or {
            "OnDirtInvestigated", "IsWargShrineActive", "IsSnakeShrineActive", "LongUpdate", "GetDebugString"
        }
        for _, method_name in ipairs(common_methods) do
            local method = hunter_instance[method_name]
            if type(method) == "function" and find_and_hook(method, target_name, 0) then
                return true
            end
        end

        for k, v in pairs(hunter_instance) do
            if type(v) == "function" and k:sub(1, 1) ~= "_" and find_and_hook(v, target_name, 0) then
                return true
            end
        end

        print("[tbat][hunter] ❌ 未找到 local 函数:", target_name)
        return false
    end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hook
    local function main_hook_fn(self)
        local common_methods = {
            "OnDirtInvestigated", "IsWargShrineActive",
            "IsSnakeShrineActive", "LongUpdate", "GetDebugString"
        }
        -- self:DebugForceHunt()
        print("[tbat][hunter] 启动 Hook")
        local temp_str = self:GetDebugString()
        if self.____tbat_hook_done then
            print("[tbat][hunter] ✅ Hook 已完成,退出任务")
            return
        end
        self.____tbat_hook_done = true

        local hunter = self
        local ret = HookLocalFunction(hunter, "GetHuntedBeast", function(original_fn, ...)
            local result = original_fn(...)  -- 先执行上一个Hook（或原始函数）
            -- 你的逻辑：修改result
            if TheWorld.components.tbat_com_hunter_repliacer then
                result = TheWorld.components.tbat_com_hunter_repliacer:GetReplaceMonster(result) or result
            end
            print("[tbat][hunter] ✅ 猎物获取成功",result)
            return result
        end,common_methods)
        if not ret then
            TheWorld:DoTaskInTime(10,function()
                TheNet:Announce("[万物书]警告，翻脚印功能异常，相关游戏机制失效")
            end)
        else
            TheWorld:DoTaskInTime(10,function()
                print("[tbat][hunter] ✅ 关键API HOOK 成功","GetHuntedBeast")
            end)
        end

        HookLocalFunction(hunter, "SpawnDirtAt", function(original_fn, ...)
            local result = original_fn(...)  -- 先执行上一个Hook（或原始函数）
            -- 你的逻辑：修改result
            print("[tbat][hunter] ✅ 脚印生成成功",result)
            if TheWorld.components.tbat_com_hunter_repliacer then
                TheWorld.components.tbat_com_hunter_repliacer:SpawnDirtAt(result)
            end
            return result
        end,common_methods)

    end
    AddComponentPostInit("hunter", function(self) 
        main_hook_fn(self)
        -- self.inst:DoTaskInTime(10, main_hook_fn)    --- 延时处理，保证实例化后再运行。
     end)