-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    -- 自制的modimport函数，用来加载MOD根目录的脚本。


]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    function TBAT.FNS:modimport(lua_file_addr)
        -- local addr = TBAT.MODROOT.."definitions/test_table.lua"
        local addr = TBAT.MODROOT..lua_file_addr
        local ret = kleiloadlua(addr)
        if type(ret) == "function" then
            return ret()
        end
        return ret
    end