---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    缺省文本库初始化。

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 专属蓝图
    local all_blue_print_names = {}
    local function add_mod_blueprints(prefab,name)
        local blueprint_prefab = prefab.."_blueprint2"
        all_blue_print_names[blueprint_prefab] = name
    end
    AddPrefabPostInit("world",function(inst)
        for prefab, name in pairs(all_blue_print_names) do
            STRINGS.NAMES[string.upper(prefab)] = name..TBAT:GetString2("tbat_item_blueprint","name")
            STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper(prefab)] = TBAT:GetString2("tbat_item_blueprint","inspect_str")
        end
    end)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local current_strings = TBAT.STRINGS[TBAT.LANGUAGE] or TBAT.STRINGS["ch"] or {}
local init_fn = function()
    for prefab, data in pairs(current_strings) do
        if type(data) == "table" then
            if data.name then
                STRINGS.NAMES[string.upper(prefab)] = data.name
                add_mod_blueprints(prefab,data.name) --- 蓝图
            end
            if data.inspect_str then
                STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper(prefab)] = data.inspect_str
            end
            if data.recipe_desc then
                STRINGS.RECIPE_DESC[string.upper(prefab)] = data.recipe_desc
            end
        end
    end
end
init_fn()

function TBAT:AllStringTableInit()
    init_fn()
end


function TBAT:GetString(prefab,index)
    --- 检查语言是否存在，不存在则缺省中文
    local current_strings = TBAT.STRINGS[TBAT.LANGUAGE] or {}
    if current_strings[prefab] == nil then
        current_strings = TBAT.STRINGS["ch"]
    end
    if current_strings[prefab] == nil then
        return nil
    end
    if current_strings[prefab][index] then
        return current_strings[prefab][index]
    else
        return TBAT.STRINGS["ch"][prefab][index]
    end
end
--- 通义灵码AI 补全
function TBAT:GetString2(prefab, ...)
    local index_args = {...}

    -- Step 1: 确定当前语言的字符串表，若不存在则使用中文
    local current_strings = TBAT.STRINGS[TBAT.LANGUAGE] or {}
    if current_strings[prefab] == nil then
        current_strings = TBAT.STRINGS["ch"] or {}
    end
    if current_strings[prefab] == nil then
        return nil
    end

    -- Step 2: 使用当前语言路径查找
    local t = current_strings[prefab]
    for _, key in ipairs(index_args) do
        t = t and t[key]
        if not t then
            break
        end
    end

    if t then
        return t
    end

    -- Step 3: 如果当前语言路径失败，则尝试中文路径
    local default_strings = TBAT.STRINGS["ch"] or {}
    if default_strings[prefab] == nil then
        return nil
    end

    t = default_strings[prefab]
    for _, key in ipairs(index_args) do
        t = t and t[key]
        if not t then
            break
        end
    end

    return t
end
-----------------------------------------------------------------
--- 中英文调试
    function TBAT:SetStringData(prefab,data)
        TBAT.STRINGS[TBAT.LANGUAGE or "ch"][prefab] = data
    end
    function TBAT:GetStringData(prefab)
        return TBAT.STRINGS[TBAT.LANGUAGE or "ch"][prefab]
    end
-----------------------------------------------------------------