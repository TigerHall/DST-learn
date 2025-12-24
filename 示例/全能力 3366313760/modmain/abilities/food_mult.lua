local Utils = require("aab_utils/utils")

local FOOD_MULT = GetModConfigData("food_mult") / 100

local function GetValAfter(retTab, self, eater)
    return eater and eater:HasTag("player") and { retTab[1] * FOOD_MULT } or retTab
end

AddComponentPostInit("edible", function(self)
    Utils.FnDecorator(self, "GetHealth", nil, GetValAfter)
    Utils.FnDecorator(self, "GetSanity", nil, GetValAfter)
    Utils.FnDecorator(self, "GetHunger", nil, GetValAfter)
end)
