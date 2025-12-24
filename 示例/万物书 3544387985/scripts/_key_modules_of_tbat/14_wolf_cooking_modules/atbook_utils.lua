--由prefab名称映射为代码命名方式
local aliases = {
    cookedsmallmeat     = "smallmeat_cooked",
    cookedmonstermeat   = "monstermeat_cooked",
    cookedmeat          = "meat_cooked"
}

--由代码命名方式映射为prefab名称
local aliases_reverse =
{
	smallmeat_cooked    = "cookedsmallmeat",
	monstermeat_cooked  = "cookedmonstermeat",
	meat_cooked         = "cookedmeat",
}

--由prefab名称映射为tex图标名称（连接".tex"后作为GetInventoryItemAtlas的参数获取图标）
--其中acorn（桦栗果）的映射是由于仅烤桦栗果可以入锅
local ingredient_icon_remap =
{
	onion	 		    = "quagmire_onion",
	onion_cooked 	    = "quagmire_onion_cooked",
	tomato	 		    = "quagmire_tomato",
	tomato_cooked	    = "quagmire_tomato_cooked",
	acorn	 		    = "acorn_cooked",
}

--由prefab名称映射为食材显示名称（作为STRINGS.NAMES的键获取食材显示名称）
--其中acorn（桦栗果）的映射是由于仅烤桦栗果可以入锅
local ingredient_name_remap =
{
    acorn               = "acorn_cooked"
}

--输出table的内容，在dprint函数中使用。
local function print_tbl(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then
                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end

--调试输出，由配置项决定是否输出。参数可以为1或2个。参数为1个时，可以打印任何类型；参数为2个时，第1个参数默认为非table。
local function dprint(name, node)

    if true then
        if node == nil then
            if type(name) == "table" then
                print_tbl(name)
            else
                print(name)
            end
        else
            if type(node) == "table" then
                print(name)
                print_tbl(node)
            else
                print(name, node)
            end
        end
    end
end

--检验列表中是否含有某个值
local function check_value(array, value)
	if next(array) == nil then
		return false
	end
	for _, v in ipairs(array) do
	  	if v == value then
			return true
	  	end
	end
	return false
end

--判断两个数组是否相同
local function array_match(t1, t2)
    if #t1 == #t2 then
        for _, v1 in ipairs(t1) do
            if not table.contains(t2, v1) then
                return false
            end
        end
        for _, v2 in ipairs(t2) do
            if not table.contains(t1, v2) then
                return false
            end
        end
        return true
    else
        return false
    end
end

--判断两个表是否相同
local function map_match(t1, t2)
    local common_key = {}
    for k,v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
        common_key[k] = 1
    end
    for k,_ in pairs(t2) do
        if common_key[k] == nil then
            return false
        end
    end
    return true
end

--获得非烤/干的原始食材
local function get_raw(name)
    if string.find(name, "_cooked") ~= nil then
        return string.gsub(name, "_cooked", "")
    elseif string.find(name, "_dried") ~= nil then
        return string.gsub(name, "_dried", "")
    else
        return name
    end
end

--Don't Starve: Dehydrated中的函数
local function CheckConstants(foodname)
	if TUNING.MOD_DSD_ENABLED then
		local ingredient_drinkable = FOODTYPEGROUP.INGREDIENT_DRINKABLE
		local iced = FOODTYPEGROUP.ICED
		local drinkable = FOODTYPEGROUP.DRINKABLE
		local drinkable_alcoho = FOODTYPEGROUP.DRINKABLE_ALCOHO
		local drinkable_holiday = FOODTYPEGROUP.DRINKABLE_HOLIDAY
		local drinkable_holiday_alcoho = FOODTYPEGROUP.DRINKABLE_HOLIDAY_ALCOHO

		for Hydration, v in pairs(ingredient_drinkable) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		for Hydration, v in pairs(iced) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		for Hydration, v in pairs(drinkable) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		for Hydration, v in pairs(drinkable_alcoho) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		for Hydration, v in pairs(drinkable_holiday) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		for Hydration, v in pairs(drinkable_holiday_alcoho) do
			for _, name in pairs(v) do
				if foodname == name then
					return TUNING["HYDRATION_"..Hydration]
				end
			end
		end

		return false
	else
		return nil
	end
end

local function Calchungerforthirst(data)
	if TUNING.MOD_DSD_ENABLED then
		return RoundBiasedUp(data.hunger * 2 ^ (math.abs(data.hunger / 300) - 1), 4) * 0.25
	else
		return 0.0
	end
end


local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}

for _, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir)
    local name = info and info.name or "unknow"
    enablemods[dir] = name
end
-- MOD是否开启
local function check_mod_enabled(name)
    -- dprint("enablemods", enablemods)
    local function check_single(n)
        for k, v in pairs(enablemods) do
            -- if v and (k == n or v == n) then return true end
            if v and (k:match(n) or v:match(n)) then return true end
        end
        return false
    end
    if type(name) == "string" then
        return check_single(name)
    elseif type(name) == "table" then
        local res = false
        for _, v in pairs(name) do
            res = res or check_single(v)
        end
        return res
    else
        return false
    end
end


return {
    aliases = aliases,
    aliases_reverse = aliases_reverse,
    ingredient_icon_remap = ingredient_icon_remap,
    ingredient_name_remap = ingredient_name_remap,
    print_tbl = print_tbl,
    dprint = dprint,
    check_value = check_value,
    array_match = array_match,
    map_match = map_match,
    get_raw = get_raw,
    CheckConstants = CheckConstants,
    Calchungerforthirst = Calchungerforthirst,
    check_mod_enabled = check_mod_enabled
}
