require("tuning")
local foods_spiced = {}

local function OnEat_garlic(inst, eater)
    eater:AddDebuff("buff_playerabsorption", "buff_playerabsorption")
end
local function OnEat_sugar(inst, eater)
    eater:AddDebuff("buff_workeffectiveness", "buff_workeffectiveness")
end
local function OnEat_chili(inst, eater)
    eater:AddDebuff("buff_attack", "buff_attack")
end

------生成通用料理调料版数据

local function SetSpicedFood(foodname, fooddata, spicenameupper, spicedata)
    local newdata = shallowcopy(fooddata)
    local spicename = string.lower(spicenameupper)
    -- if foodname == "wetgoop" then
    --     newdata.test = function(cooker, names, tags) return names[spicename] end
    --     newdata.priority = -10
    -- else
        newdata.test = function(cooker, names, tags) return names[foodname] and names[spicename] end
        newdata.priority = 100
    -- end
    newdata.cooktime = .12
    newdata.stacksize = nil
    newdata.spice = spicenameupper
    newdata.basename = foodname
    newdata.name = foodname.."_"..spicename

    --这两个设置应该没用吧
    -- newdata.official = true
    -- newdata.cookbook_category = fooddata.cookbook_category ~= nil and ("spiced_"..fooddata.cookbook_category) or nil

    if newdata.float ~= nil then --原本就会沉的料理，即使加了调料一样会沉
        newdata.float = {nil, "med", 0.05, {0.8, 0.7, 0.8}} --改成通用格式，因为带调料的料理动画格式一样的
    end
    foods_spiced[newdata.name] = newdata

    if spicename == "spice_chili" then
        if newdata.temperature == nil then
            --Add permanent "heat" to regular food
            newdata.temperature = TUNING.HOT_FOOD_BONUS_TEMP
            newdata.temperatureduration = TUNING.FOOD_TEMP_LONG
            newdata.nochill = true
        elseif newdata.temperature > 0 then
            --Upgarde "hot" food to permanent heat
            newdata.temperatureduration = math.max(newdata.temperatureduration, TUNING.FOOD_TEMP_LONG)
            newdata.nochill = true
        end
    end

    if spicedata.prefabs ~= nil then
        newdata.prefabs = newdata.prefabs ~= nil and ArrayUnion(newdata.prefabs, spicedata.prefabs) or spicedata.prefabs
    end

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
local function GenerateSpicedFoods(foods, spices)
    for foodname, fooddata in pairs(foods) do
        for spicenameupper, spicedata in pairs(spices) do
            SetSpicedFood(foodname, fooddata, spicenameupper, spicedata)
        end
    end
end

------生成特殊物品调料版数据

local items = require("prepareditems_legion")
local function SetSpicedItem(foodname, fooddata, spicenameupper, spicedata)
    local newdata = shallowcopy(fooddata)
    local spicename = string.lower(spicenameupper)
    newdata.test = function(cooker, names, tags) return names[foodname] and names[spicename] end
    newdata.priority = 100
    newdata.cooktime = .12
    newdata.stacksize = nil
    newdata.spice = spicenameupper
    newdata.basename = foodname
    newdata.name = foodname.."_"..spicename
    foods_spiced[newdata.name] = newdata
    --后续的数据就不需要了，毕竟不需要用到通用预制物逻辑
end
local function GenerateSpicedItems(foodname, spices)
    local fooddata = items[foodname]
    if fooddata == nil then
        return
    end
    for spicenameupper, spicedata in pairs(spices) do
        SetSpicedItem(foodname, fooddata, spicenameupper, spicedata)
    end
end

--------------------------------------------------------------------------
--[[ 通用料理 ]]
--------------------------------------------------------------------------

local spices_base = {
    SPICE_GARLIC = { oneatenfn = OnEat_garlic, prefabs = { "buff_playerabsorption" } },
    SPICE_SUGAR  = { oneatenfn = OnEat_sugar, prefabs = { "buff_workeffectiveness" } },
    SPICE_CHILI  = { oneatenfn = OnEat_chili, prefabs = { "buff_attack" } },
    SPICE_SALT   = {}
}

GenerateSpicedFoods(require("preparedfoods_legion"), spices_base)

--------------------------------------------------------------------------
--[[ 特殊物品 ]]
--------------------------------------------------------------------------

------牛排战斧

local spices_steak = {
    SPICE_GARLIC = true,
    SPICE_SUGAR  = true,
    SPICE_CHILI  = true,
    SPICE_SALT   = true
}
if CONFIGS_LEGION.ENABLEDMODS.FnMedal then --兼容勋章的香料
    spices_steak.SPICE_VOLTJELLY = true
    spices_steak.SPICE_PHOSPHOR = true
    spices_steak.SPICE_CACTUS_FLOWER = true
    spices_steak.SPICE_RAGE_BLOOD_SUGAR = true
    spices_steak.SPICE_POTATO_STARCH = true
end
GenerateSpicedItems("dish_tomahawksteak", spices_steak)

------
------

return foods_spiced
