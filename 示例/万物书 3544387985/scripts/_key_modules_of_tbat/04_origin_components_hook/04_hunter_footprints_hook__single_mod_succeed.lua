---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    本文件用来  处理 脚印追踪  翻找出来的最终 生成怪物。

    【注意】 本文件的方法 不兼容其他MOD，如果其他MOD用同样的方法，则会覆盖替换。

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- AI 来的代码。只能hook 实例化后的组件。

            -- -- Hook API: 传入组件实例和要 Hook 的 local 函数名
        local visited_funcs = {}  -- 全局表，记录已处理的函数
        local function HookLocalFunction(hunter_instance, target_name, hook_callback,__common_methods)
            if not hunter_instance or type(hunter_instance) ~= "table" then
                error("Invalid hunter instance")
                return false
            end

            if not target_name or type(target_name) ~= "string" then
                error("Invalid target function name")
                return false
            end

            if not hook_callback or type(hook_callback) ~= "function" then
                error("Invalid hook callback")
                return false
            end

            local original_func = nil
            visited_funcs = {}  -- 每次 Hook 新目标函数时重置

            local function find_and_hook(func, target_name, depth)
                if depth > 50 then
                    print("[tbat][hunter] ⚠️ 递归深度超过限制（", depth, "），跳过")
                    return false
                end

                if visited_funcs[func] then
                    return false
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
                        if find_and_hook(value, target_name, depth + 1) then
                            return true
                        end
                    end
                end
                return false
            end

            -- 1. 尝试从构造函数中查找
            if hunter_instance._ctor and type(hunter_instance._ctor) == "function" then
                if find_and_hook(hunter_instance._ctor, target_name, 0) then
                    return true
                end
            end

            -- 2. 尝试从常用方法中查找
            local common_methods = __common_methods or {
                "OnDirtInvestigated", "IsWargShrineActive",
                "IsSnakeShrineActive", "LongUpdate", "GetDebugString"
            }

            for _, method_name in ipairs(common_methods) do
                local method = hunter_instance[method_name]
                if type(method) == "function" then
                    if find_and_hook(method, target_name, 0) then
                        return true
                    end
                end
            end

            -- 3. 尝试从所有实例方法中查找
            for k, v in pairs(hunter_instance) do
                if type(v) == "function" and k:sub(1, 1) ~= "_" then
                    if find_and_hook(v, target_name, 0) then
                        return true
                    end
                end
            end

            print("[tbat][hunter] ❌ 未找到 local 函数:", target_name)
            return false
        end
        -- -- -- 【使用示例】
        -- -- 获取 hunter 实例
        -- local hunter = TheWorld.components.hunter

        -- -- Hook GetHuntedBeast
        -- HookLocalFunction(hunter, "GetHuntedBeast", function(original_fn, ...)
        --     local original_beast = original_fn(...)
        --     print("[tbat][hunter] 原始刷出对象:", original_beast)
        --     return "tbat_animal_snow_plum_chieftain"
        -- end)

        -- -- Hook SpawnDirtAt
        -- HookLocalFunction(hunter, "SpawnDirtAt", function(original_fn, ...)
        --     local original_ret = { original_fn(...) }
        --     print("[tbat][hunter] SpawnDirtAt 返回值:", unpack(original_ret))
        --     return unpack(original_ret)
        -- end)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hook
    AddComponentPostInit("hunter", function(self)
        

        local common_methods = {
            "OnDirtInvestigated", "IsWargShrineActive",
            "IsSnakeShrineActive", "LongUpdate", "GetDebugString"
        }
        --- 延时，等组件彻底实例化后再hook
        self.inst:DoTaskInTime(1,function()
            
            local hunter = self
            -- Hook GetHuntedBeast
            HookLocalFunction(hunter, "GetHuntedBeast", function(original_fn, ...)
                local original_beast = original_fn(...)
                print("[tbat][hunter] 原始刷出对象:", original_beast)
                if TheWorld.components.tbat_com_hunter_repliacer then
                    original_beast = TheWorld.components.tbat_com_hunter_repliacer:GetReplaceMonster(original_beast) or original_beast
                end
                return original_beast
            end)

            -- Hook SpawnDirtAt
            HookLocalFunction(hunter, "SpawnDirtAt", function(original_fn, ...)
                local original_ret = { original_fn(...) }
                print("[tbat][hunter] SpawnDirtAt 返回值:", unpack(original_ret))
                if TheWorld.components.tbat_com_hunter_repliacer then
                    ThePlayer.components.tbat_com_hunter_repliacer:SpawnDirtAt(unpack(original_ret))
                end
                return unpack(original_ret)
            end)

        end)


    end)