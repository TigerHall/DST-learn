local pattern = " ../mods/([^/]+)/" --前面加个空格，只找行首

local function FindErrorMods(error)
    local mods = {}
    for mod in error:gmatch(pattern) do
        table.insert(mods, mod)
    end

    local visisted = {} --去重
    local res = {}
    for _, modname in ipairs(mods) do
        if not visisted[modname] then
            table.insert(res, ModInfoname(modname))
            visisted[modname] = true
        end
    end
    return res
end

local function FormatErrorMods(mods)
    return #mods > 0 and ("（崩溃检测）报错相关的mod：\n" .. table.concat(mods, "，") .. "\n") or "\n"
end

-- hook DisplayError就行，不需要print
-- local ERROR_TITLE = "LUA ERROR stack traceback"
-- local oldfn = GLOBAL.print
-- GLOBAL.print = function(...)
--     local log = ...
--     if type(log) == "string"
--         and log:sub(1, 1) == '[' --检查是否[开头，节省一点计算量
--         and string.find(log, ERROR_TITLE)
--     then
--         oldfn(FormatErrorMods(FindErrorMods(log)))
--     end
--     return oldfn(...)
-- end


-- 把报错mod和日志显示出来，仿造DisplayError
AddClientModRPCHandler(modname, "ShowErrorMods", function(error)
    SetPause(true, "DisplayError")
    if global_error_widget ~= nil then
        return nil
    end

    local modnames = ModManager:GetEnabledModNames()

    local modnamesstr = ""
    for k, modname in ipairs(modnames) do
        modnamesstr = modnamesstr .. "\"" .. KnownModIndex:GetModFancyName(modname) .. "\" "
    end

    SetGlobalErrorWidget(
        STRINGS.UI.MAINSCREEN.MODFAILTITLE,
        error,
        {
            {
                text = STRINGS.UI.NETWORKDISCONNECT.OK,
                cb = function()
                    if global_error_widget then
                        global_error_widget:GoAway()
                    end
                end
            },
            {
                text = STRINGS.UI.SERVERCREATIONSCREEN.OPENSAVEFOLDER,
                cb = function()
                    if (IsSteam() or IsRail()) and not IsLinux() then
                        TheSim:GetPersistentString("ede_save_slot", function(load_success, slot)
                            TheSim:OpenSaveFolder(load_success and slot or 1)
                        end)
                    end
                end
            }
        },
        ANCHOR_LEFT,
        STRINGS.UI.MAINSCREEN.SCRIPTERRORMODWARNING .. modnamesstr,
        20
    )
end)

local OldDisplayError = GLOBAL.DisplayError
GLOBAL.DisplayError = function(error, ...)
    if type(error) ~= "string" then
        return OldDisplayError(error, ...)
    end

    error = FormatErrorMods(FindErrorMods(error)) .. error
    if TheWorld.ismastersim then
        --主机报错，发给客机显示
        SendModRPCToClient(GetClientModRPC(modname, "ShowErrorMods"), nil, error)
    end

    return OldDisplayError(error, ...)
end
