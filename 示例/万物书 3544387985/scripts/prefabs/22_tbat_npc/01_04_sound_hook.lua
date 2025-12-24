--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    不改sg的情况下，替换声音的方式


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -- Hook_Inst_SoundEmitter 函数：将 SoundEmitter 从 userdata 转换为 table 并挂载代理逻辑
    local function Hook_Inst_SoundEmitter(inst)
        -- 安全检查：确保 SoundEmitter 是 userdata 类型（防止重复转换）
        if type(inst.SoundEmitter) == "userdata" then
            -- 保存原始 userdata 指针，用于后续函数调用
            inst.__SoundEmitter_userdata_tbat = inst.SoundEmitter
            
            -- 创建新的 table 代理对象
            local proxy = {
                inst = inst,         -- 关联实体实例
                name = "SoundEmitter"   -- 用于标识类型
            }
            
            -- 获取原始 SoundEmitter 的方法表（通过元表）
            local mt = getmetatable(inst.SoundEmitter)
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
                                    table_proxy.inst.__SoundEmitter_userdata_tbat,
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
            
            -- 替换 SoundEmitter 为代理对象
            inst.SoundEmitter = proxy
        else
            print("警告: inst.SoundEmitter 已经是 table 类型")
        end
        
        -- 确保 inst 关联正确（容错处理）
        if inst.SoundEmitter.inst ~= inst then
            inst.SoundEmitter.inst = inst
        end       
        return inst.SoundEmitter
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hook api
    local function hook_api(inst)
        local old_PlaySound = inst.SoundEmitter.PlaySound
        inst.SoundEmitter.PlaySound = function(self, sound,flag,...)
            -- if sound == "summerevent/characters/corvus/speak" then
            if flag == "talk" then
                flag = "test_talk"
                sound = "tbat_sound_stage_1/tbat_npc_emerald_feather_bird/talk_"..math.random(5)
                inst.SoundEmitter:KillSound("test_talk")
            end
            return old_PlaySound(self, sound,flag,...)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(inst)
    inst:DoTaskInTime(1,function()
        Hook_Inst_SoundEmitter(inst)
        if type(inst.SoundEmitter) == "table" then
            hook_api(inst)
        else
            print("[TBAT][ERROR] 翠羽鸟 SoundEmitter 转换失败")
        end
    end)    
end