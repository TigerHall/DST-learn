--------------------------------
--[[ InventoryUtil: 物品栏工具方法]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-03]]
--[[ @updateTime: 2022-01-03]]
--[[ @email: x7430657@163.com]]
--------------------------------

local InventoryUtil = {}

--[[将giver的物品和装备栏全部给到receiver(服务器)]]
--[[@param giver: 给予者]]
--[[@param receiver: 接收者]]
--[[@return boolean: 成功给予则返回true]]
function InventoryUtil:TransferInventory(giver,receiver)
    if not giver.components.inventory or not receiver.components.inventory then
        return false
    end
    local inv = receiver.components.inventory
    local item
    local restrictedTag
    -- 必须先同步装备栏，物品栏给予可装备物品会自动装备
    -- 装备栏
    for k,v in pairs(giver.components.inventory.equipslots) do
        item = giver.components.inventory:Unequip(k)
        if item then
            -- 装备存在限定
            restrictedTag = self:GetEquipRestrictedTag(item)
            if restrictedTag ~= nil and restrictedTag ~= 0 and not receiver:HasTag(restrictedTag) then
                receiver:AddTag(restrictedTag)
            end
            inv:Equip(item)
        end
    end
    -- 物品栏
    for k,v in pairs(giver.components.inventory.itemslots) do
        item = giver.components.inventory:RemoveItemBySlot(k)
        -- 注意这里未判断物品是否存在捡起限定
        -- 在本mod中使用中，是在main_sensory_monitor中 重写了DropItem
        -- 以去除限定（仅参考了神话物品捡起限定，增加了onpickfn，如果不符合会丢弃）
        if item then
            -- 物品的装备存在限定，保险起见也加上该限定
            restrictedTag = self:GetEquipRestrictedTag(item)
            if restrictedTag ~= nil and restrictedTag ~= 0 and not receiver:HasTag(restrictedTag) then
                receiver:AddTag(restrictedTag)
            end
            inv:GiveItem(item,k)
        end
    end
    -- 鼠标上的物品 丢出来
    item = giver.components.inventory.activeitem
    if item then
        giver.components.inventory:DropItem(item, true, true)
    end
    return true
end

--[[获取装备的限定tag（服务器/客户端）]]
--[[@param item: 物品]]
--[[@return RestrictedTag: 限定tag]]
function InventoryUtil:GetEquipRestrictedTag(item)
    if item == nil or item.components == nil then
        return nil
    end
    -- 服务器
    if item.components.equippable ~= nil then
        return item.components.equippable.restrictedtag
    end
    -- 客户端
    return item.replica.inventoryitem:GetEquipRestrictedTag()
end


--[[获取owner的装备栏(服务器/客户端)]]
--[[@param owner: 给予者]]
--[[@return table: key:索引，value:装备]]
function InventoryUtil:GetEquips(owner)
    if owner == nil or owner.replica == nil or owner.replica.inventory == nil then
        return false
    end
    return owner.replica.inventory:GetEquips()
end


function InventoryUtil:CopyEquips(giver,receiver)
    if not giver.components.inventory or not receiver.components.inventory then
        return false
    end
    -- 装备栏
    local inv = receiver.components.inventory
    local item
    for k,v in pairs(giver.components.inventory.equipslots) do
        if v then
            item = SpawnPrefab(v.prefab,v.AnimState:GetBuild())
            inv:Equip(item)
        end
    end
    return true
end



return InventoryUtil