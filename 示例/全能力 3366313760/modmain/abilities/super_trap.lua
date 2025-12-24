local SUPER_TRAP = GetModConfigData("super_trap")
local Utils = require("aab_utils/utils")
AllRecipes.trap_bramble.builder_tag = nil

----------------------------------------------------------------------------------------------------

local function Reset(inst, self)
    if self.issprung and not self.inactive then
        self:Reset()
    end
end

local function ExplodeAfter(retTab, self)
    if self.inst:IsValid() and self.issprung then
        self.inst:DoTaskInTime(4, Reset, self)
    end
    return retTab
end

for _, v in ipairs({
    "trap_teeth",
    "trap_bramble"
}) do
    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        if SUPER_TRAP == 2 or SUPER_TRAP == 4 then
            --自动重置
            Utils.FnDecorator(inst.components.mine, "Explode", nil, ExplodeAfter)
        end
        if SUPER_TRAP == 3 or SUPER_TRAP == 4 then
            --无限耐久
            if inst.components.finiteuses then
                inst.components.finiteuses.Use = function() end
            end
        end
    end)
end
