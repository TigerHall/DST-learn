local prefabId = 1

local function SortByCount(left, right)
    if (left.count == right.count) then
        return left.item.prefab < right.item.prefab
    end
    return left.count > right.count
end


local function CollectItems(container, result) 
    local num =  container:GetNumSlots()
    for i = 1, num, 1 do
       local item = container:GetItemInSlot(i)
       if item ~= nil then
            --判断是否可堆叠
            if item.components.stackable then
                --可堆叠的物品判断是否已经存在
                if not result[item.prefab] then
                    --第一次直接放入表中
                    result[item.prefab] = {item = item, count = item.components.stackable:StackSize()}
                else
                    --已经存在的物品，增加数量
                    local inst = result[item.prefab]
                    inst.item.components.stackable:SetStackSize(inst.item.components.stackable:StackSize() + item.components.stackable:StackSize())
                    inst.count = inst.item.components.stackable:StackSize()
                end  
            else
                --不可堆叠的物品生成一个数字累加id
                prefabId = prefabId + 1
                result[tostring(prefabId)] = {item = item, count = 0}
            end

          --从物品栏中先删除
          container:RemoveItemBySlot(i)
       end
    end
end

local function Arrange()
    local items = {}
    local player = GetPlayer()
    
    CollectItems(player.components.inventory, items)
    CollectItems(player.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK).components.container, items)
   
    --将items 放入数组中
    local itemsArray = {}
    for k, v in pairs(items) do
        table.insert(itemsArray, v)
    end
    --调用排序
    table.sort(itemsArray, SortByCount)
    local slot = 1
    local inventory = player.components.inventory
    for i = 1, #itemsArray, 1 do       
        inventory:GiveItem(itemsArray[i].item, slot)
        slot = slot + 1
    end
end



return Arrange