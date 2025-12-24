local RECIPE_DERATE_MULT = GetModConfigData("recipe_derate_mult")

local function Modify(inst, self)
    if self and self.ingredientmod > RECIPE_DERATE_MULT then
        self.ingredientmod = RECIPE_DERATE_MULT
    end
end

-- 当值改变时立马改回来
local function ingredientmodBefore(self, ingredientmod)
    if ingredientmod and ingredientmod > RECIPE_DERATE_MULT and self.inst:IsValid() then
        self.inst:DoTaskInTime(0, Modify)
    end
end

local function Update(inst)
    if inst.components.builder and inst.components.builder.ingredientmod > RECIPE_DERATE_MULT then
        inst.components.builder.ingredientmod = RECIPE_DERATE_MULT
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    -- local self = inst.components.builder
    -- if self._ and self._.ingredientmod and self._.ingredientmod[2] then
    --     Utils.FnDecorator(self._.ingredientmod, 2, ingredientmodBefore) --不考虑移除组件再添加组件的情况
    -- end
    -- Modify(inst, self)

    inst:DoPeriodicTask(0.5, Update)
end)
