
if not TBAT.DEBUGGING then
    return
end
------------------------------------------------------------
--- DebugSpawn
    local temp_DebugSpawn = rawget(_G,"DebugSpawn")
    local function new_debug_fn(str,...)
        print("DebugSpawn: ",str)
        local other_args = {...}
        if type(other_args[1]) == "number" then
            for i = 1, other_args[1], 1 do
                local ret = temp_DebugSpawn(str,...)
                if i == other_args[1] then
                    return ret
                end
            end
        else        
            return temp_DebugSpawn(str,...)
        end
    end
    rawset(_G,"D",new_debug_fn)
    rawset(_G,"d",new_debug_fn)
------------------------------------------------------------
--- 测试用
    local inst = CreateEntity()
    inst:DoTaskInTime(1,function()
        ------------------------------------------------------------
            rawset(_G,"reload",rawget(_G,"c_reset"))
        ------------------------------------------------------------
            local temp_give = rawget(_G,"c_give")
            local new_give = function(...)
                print("c_give: ",...)
                return temp_give(...)
            end
            rawset(_G,"C_GIVE",new_give)
        ------------------------------------------------------------

            local function d_give(...)
                local n = select("#", ...)  -- 获取参数个数
                if n < 1 or n > 2 then
                    error("d_give requires 1 or 2 arguments", 2)
                end

                local args = { ... }
                local prefab = args[1]
                
                -- 验证第一个参数必须是字符串
                if type(prefab) ~= "string" then
                    error("First argument must be a string", 2)
                end

                -- 1. 替换字符串内容中的中文双引号 → 英文双引号
                -- 2. 转换为小写
                prefab = prefab:gsub("“", "\""):gsub("”", "\""):lower()

                -- 处理第二个参数（默认为 1）
                local num = 1
                if n == 2 then
                    local second = args[2]
                    if type(second) == "number" then
                        num = second
                    elseif type(second) == "string" then
                        -- 尝试转换字符串为数字（支持 "5"、"5.5" 等格式）
                        num = tonumber(second)
                        if num == nil then
                            error("Second argument must be a number or a string representing a number", 2)
                        end
                    else
                        error("Second argument must be a number or a string", 2)
                    end
                end

                -- 调用原始 API
                c_give(prefab, num)
            end
            rawset(_G,"D_GIVE",d_give)
            rawset(_G,"DGIVE",d_give)
            rawset(_G,"d_give",d_give)
            rawset(_G,"dgive",d_give)
        ------------------------------------------------------------
        --- debug inst
            rawset(_G,"d_select",function()
                local inst = c_select()
                if inst then
                    print("d_select: \n",inst:GetDebugString())
                end
            end)
        ------------------------------------------------------------








        inst:Remove()
    end)
------------------------------------------------------------
--- 移除的容易干扰项
    AddPrefabPostInit("bat",function(inst)
        inst:Remove()
    end)
    AddPrefabPostInit("frog",function(inst)
        inst:Remove()
    end)
    -- AddPrefabPostInit("butterfly",function(inst)
    --     inst:DoTaskInTime(1,inst.Remove)
    -- end)
------------------------------------------------------------