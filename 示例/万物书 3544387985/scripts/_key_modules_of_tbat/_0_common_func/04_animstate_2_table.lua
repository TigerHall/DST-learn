--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    转换任何animstate 从userdata 到table

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Hook_Inst_AnimState 函数：将 AnimState 从 userdata 转换为 table 并挂载代理逻辑
    local function Hook_Inst_AnimState(inst)
        -- 安全检查：确保 AnimState 是 userdata 类型（防止重复转换）
        if type(inst.AnimState) == "userdata" then
            -- 保存原始 userdata 指针，用于后续函数调用
            inst.__AnimState_userdata_tbat = inst.AnimState
            
            -- 创建新的 table 代理对象
            local proxy = {
                inst = inst,         -- 关联实体实例
                name = "AnimState"   -- 用于标识类型
            }
            
            -- 获取原始 AnimState 的方法表（通过元表）
            local mt = getmetatable(inst.AnimState)
            local original_methods = mt and mt.__index or nil
            
            -- 设置元表实现动态函数代理
            setmetatable(proxy, {
                __index = function(table_proxy, fn_name)
                    -- 验证结构完整性
                    if table_proxy and table_proxy.inst and original_methods then
                        -- 从原始方法表中获取方法
                        if original_methods[fn_name] then
                            -- 创建闭包包装器
                            local wrapper = function(self, ...)
                                -- 调用原始方法并转发参数
                                return original_methods[fn_name](
                                    table_proxy.inst.__AnimState_userdata_tbat,
                                    ...
                                )
                            end
                            
                            -- 缓存方法避免重复查找
                            rawset(table_proxy, fn_name, wrapper)
                            return wrapper
                        end
                    end
                end
            })
            
            -- 替换 AnimState 为代理对象
            inst.AnimState = proxy
        else
            print("警告: inst.AnimState 已经是 table 类型")
        end
        
        -- 确保 inst 关联正确（容错处理）
        if inst.AnimState.inst ~= inst then
            inst.AnimState.inst = inst
        end       
        return inst.AnimState
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    function TBAT.FNS:Hook_Inst_AnimState(inst)
        return Hook_Inst_AnimState(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------