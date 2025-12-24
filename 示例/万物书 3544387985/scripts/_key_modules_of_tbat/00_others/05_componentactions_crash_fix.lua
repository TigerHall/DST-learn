--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 强制修一些 componentactions.lua 里 崩溃。至于为什么崩溃，不知道。
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




-- local old_UnregisterComponentActions = EntityScript.UnregisterComponentActions
-- EntityScript.UnregisterComponentActions = function(...)
--     -- print("tbat_test UnregisterComponentActions",...)
--     local crash_flg = pcall(old_UnregisterComponentActions,...)
--     if not crash_flg then
--         print("tbat error : UnregisterComponentActions",...)
--     end
-- end

if GLOBAL.EntityScript.UnregisterComponentActions_tbat_old == nil then


    -------------------------------------------------------------------------------------------
    ---- UnregisterComponentActions
        rawset(GLOBAL.EntityScript,"UnregisterComponentActions_tbat_old",rawget(GLOBAL.EntityScript,"UnregisterComponentActions"))
        rawset(GLOBAL.EntityScript, "UnregisterComponentActions", function(self,...)
                -- print("tbat_test UnregisterComponentActions",self,...)
            local crash_flg = pcall(self.UnregisterComponentActions_tbat_old,self,...)
            if not crash_flg then
                print("tbat error : UnregisterComponentActions",self,...)
            end
        end)
    -------------------------------------------------------------------------------------------
    -- 没看懂这个是要干什么，这个会和某些五格冲突
    ---- CollectActions
        -- rawset(GLOBAL.EntityScript,"CollectActions_tbat_old",rawget(GLOBAL.EntityScript,"CollectActions"))
        -- rawset(GLOBAL.EntityScript, "CollectActions", function(self,...)
        --         -- print("tbat_test CollectActions",self,...)
        --     local crash_flg,crash_reason = pcall(self.CollectActions_tbat_old,self,...)
        --     if not crash_flg then
        --         print("tbat error : CollectActions",self,...)
        --         print(crash_reason)
        --     end
        -- end)







end