GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end,
})


local STACK_RADIUS = GetModConfigData('STACK_RADIUS')
local function FindEntities(x, y, z)
    return TheSim:FindEntities(x, y, z, STACK_RADIUS, {
        '_stackable',
    }, {
        'INLIMBO',
        'NOCLICK',
        'penguin_egg',
        'lootpump_oncatch',
        'lootpump_onflight',
    })
end
local function Put(inst, item)
    if item ~= inst and item.prefab == inst.prefab and item.skinname == inst.skinname then
        SpawnPrefab('sand_puff').Transform:SetPosition(item.Transform:GetWorldPosition())
        inst.components.stackable:Put(item)
    end
end
AddComponentPostInit('stackable', function(Stackable)
    local Get = Stackable.Get
    function Stackable:Get(...)
        local instance = Get(self, ...)
        if instance.xt_stack_task then
            instance.xt_stack_task:Cancel()
            instance.xt_stack_task = nil
        end
        return instance
    end
end)
AddPrefabPostInitAny(function(inst)
    if inst:HasTag('smallcreature') or inst:HasTag('heavy') or inst:HasTag('trap') or inst:HasTag('NET_workable') then
        return
    end
    if inst.components.stackable == nil or inst:IsInLimbo() or inst:HasTag('NOCLICK') then
        return
    end
    inst.xt_stack_task = inst:DoTaskInTime(.5, function()
        if inst:HasTag('penguin_egg') then
            return
        end
        if inst.components.stackable == nil or inst:IsInLimbo() or inst:HasTag('NOCLICK') then
            return
        end
        if inst:IsValid() and not inst.components.stackable:IsFull() then
            for _, item in ipairs(FindEntities(inst.Transform:GetWorldPosition())) do
                if item:IsValid() and not item.components.stackable:IsFull() then
                    Put(inst, item)
                end
            end
        end
    end)
end)
