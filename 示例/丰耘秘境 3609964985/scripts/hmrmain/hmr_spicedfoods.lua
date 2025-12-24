----------------------------------------------------------------------------
---[[生成模组调味料理信息]]
----------------------------------------------------------------------------
local SPICE_DEFS = require("hmrmain/hmr_lists").SPICE_DATA_LIST
local SPICES = {}
for name, data in pairs(SPICE_DEFS) do
    if data.source ~= nil and data.source == "hmr" then
        SPICES[string.upper(data.product)] = data
    end
end

local spicedfoods = {}

local function GenerateSpicedFoods(foods)
    for foodname, fooddata in pairs(foods) do
        if not (fooddata.spice or fooddata.notinitprefab) then
            for spicenameupper, spicedata in pairs(SPICES) do
                local newdata = shallowcopy(fooddata)
                local spicename = string.lower(spicenameupper)
                if foodname == "wetgoop" then
                    newdata.test = function(cooker, names, tags) return names[spicename] end
                    newdata.priority = -10
                else
                    newdata.test = function(cooker, names, tags) return names[foodname] and names[spicename] end
                    newdata.priority = 100
                end
                newdata.cooktime = .12
                newdata.stacksize = nil
                newdata.spice = spicenameupper          --调料
                newdata.basename = foodname             --基础料理名
                newdata.name = foodname.."_"..spicename --调味后料理名
                newdata.floater = {"med", nil, {0.85, 0.7, 0.85}}
                newdata.official = true
                if spicedata.foodtype then
                    newdata.foodtype = spicedata.foodtype
                end
                spicedfoods[newdata.name] = newdata

                -- 合并prefab
                if spicedata.prefabs ~= nil then
                    newdata.prefabs = newdata.prefabs ~= nil and ArrayUnion(newdata.prefabs, spicedata.prefabs) or spicedata.prefabs
                end

                -- 合并oneatenfn
                if spicedata.oneatenfn ~= nil then
                    if newdata.oneatenfn ~= nil then
                        local oneatenfn_old = newdata.oneatenfn
                        newdata.oneatenfn = function(inst, eater)
                            spicedata.oneatenfn(inst, eater)
                            oneatenfn_old(inst, eater)
                        end
                    else
                        newdata.oneatenfn = spicedata.oneatenfn
                    end
                end
            end
        end
    end
end

local function GetSpicedFoods()
    return spicedfoods
end

return {
    SPICED_FOODS = spicedfoods,
    SPICES = SPICES,
    GenerateSpicedFoods = GenerateSpicedFoods,
    GetSpicedFoods = GetSpicedFoods
}