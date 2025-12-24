local DROP_STACK_RANGE = GetModConfigData("drop_stack")

local function CheckItem(inst)
    local c = inst.components
    return c.stackable
        and not c.stackable:IsFull()
        and c.inventoryitem
        and c.inventoryitem.is_landed
        and not c.inventoryitem.owner
        and c.inventoryitem.canbepickedup
end

local STACK_MUST_TAGS = { "_inventoryitem" }
local STACK_CANT_TAGS = { "INLIMBO", "fire", "smolder" }

local function TryStack(inst)
    if not CheckItem(inst) then return end

    local items = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, y, z, DROP_STACK_RANGE, STACK_MUST_TAGS, STACK_CANT_TAGS)) do
        if v.prefab == inst.prefab and v.skinname == inst.skinname and CheckItem(v) then
            table.insert(items, v)
        end
    end
    --从前后两头开工，后面的物品给前面的物品东西
    local index1 = 1
    local index2 = #items

    while index1 < index2 do
        local item1 = items[index1]
        local item2 = items[index2]

        item1.components.stackable:Put(item2)
        if item1.components.stackable:IsFull() then
            index1 = index1 + 1
        end
        if not item2:IsValid() then
            index2 = index2 - 1
            SpawnPrefab("sand_puff").Transform:SetPosition(item2.Transform:GetWorldPosition())
        end
    end
end

local function OnLanded(inst, data)
    if inst:IsValid() then inst:DoTaskInTime(0, TryStack) end
end

AddComponentPostInit("stackable", function(self, inst)
    inst:RemoveEventCallback("on_landed", OnLanded)
    inst:ListenForEvent("on_landed", OnLanded)
end)
