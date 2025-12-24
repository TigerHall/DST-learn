--------------------------------
--[[ 秘密垃圾桶/洞销毁组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-15]]
--[[ @updateTime: 2022-03-15]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
-- 奖品
local allBonusItems = require("resources/bonus_item_list")

local SecretGarbageCan = Class(function(self, inst)
    self.inst = inst
    self.destroy_item_num = 0 -- 销毁物品数量
    self.bonus_item_count = 0 -- 奖励物品次数
    self.bonus_item_limit = TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_BONUS_LIMIT -- 奖励物品临界值
    self.big_bonus_per_count = TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_BIG_BONUS_PER_COUNT -- 大奖励,每5个一次
    -- 更新组件以实现删除其上的物品 废弃
    --self.inst:StartUpdatingComponent(self)
end)

--[[说话]]
local function say(doer,script,...)
    if TUNING.DORAEMON_TECH.CONFIG.DESTROY_BONUS and doer.components.talker ~= nil
            and doer.components.health ~= nil and not doer.components.health:IsDead() and doer:HasTag("idle")
    then -- 提示玩家销毁更多物品
        doer.components.talker:Say(script,...)
    end
end
--[[获取所有实体数量]]
local function getAllItemsNumInContainer(inst)
    local total = 1 -- inst 本身
    -- inst 必然不为空 且是容器
    local allItems = inst.components.container:GetAllItems()
    for _,v in ipairs(allItems) do
        if v.components.container then -- 容器则继续递归
            total = total + getAllItemsNumInContainer(v)
        else
            if v.components.stackable then
                total  = total + v.components.stackable:StackSize()
            else
                total  = total + 1
            end
        end
    end
    return total
end



--[[销毁其中的物品]]
function SecretGarbageCan:Destroy(doer)
    local inst = self.inst
    -- 存在容器组件
    if inst.components.container ~= nil then
        -- 关闭容器(在客户端操作,即在widget中处理)
        inst.components.container:Close() -- 此方法会关闭所有人的打开容器
        if not inst.components.container:IsOpenedByOthers(doer) then -- 没有被他人打开
            -- 销毁容器内物品
            inst.components.container:ForEachItem(function (item)
                if item.components.stackable then
                    self.destroy_item_num  = self.destroy_item_num + item.components.stackable:StackSize()
                else
                    self.destroy_item_num  = self.destroy_item_num + 1
                end
                item:Remove()
            end)
            -- 销毁处于秘密垃圾洞上面的物品(背包和重物)，
            if TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_BACKPACK or TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_HEAVY then
                local x,y,z = self.inst.Transform:GetWorldPosition()
                local oneOfTags = {}
                if TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_BACKPACK then
                    table.insert(oneOfTags,"backpack")
                end
                if TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_HEAVY then
                    table.insert(oneOfTags,"heavy")
                end
                local ents = TheSim:FindEntities(x , y , z , math.ceil(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_RANGE),
                        nil,-- MUSTTAG
                        {"flying", "shadow", "ghost", "FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost"}, --CANT TAG
                        oneOfTags) -- ONEOFTAG
                for _ , v in ipairs(ents) do
                    if v:IsValid() and v.components.health == nil then -- 反正不能是生物,做下判断
                        if v.components.container then -- 是容器
                            self.destroy_item_num  = self.destroy_item_num + getAllItemsNumInContainer(v)
                        else
                            self.destroy_item_num  = self.destroy_item_num + 1
                        end
                        v:Remove()
                    end
                end
            end
            -- 处理奖品
            self:HandleBonus(doer)
            return true
        end
    end
    return true -- 不管怎样都返回成功
end

local function getGiftFrom(itemList)
    local prefab = itemList[math.random(#itemList)]
    Logger:Debug({"中奖物品",prefab})
    if prefab then
        return SpawnPrefab(prefab)
    end
end

--[[奖励物品]]
function SecretGarbageCan:BonusItems()
    -- 存在奖励物品设置,数量大于等于限制
    local gifts = {}
    local cantWrapItems = {} -- 不能包装的奖品
    local hasBigGift = false
    while TUNING.DORAEMON_TECH.CONFIG.DESTROY_BONUS and self.destroy_item_num >= self.bonus_item_limit do
        -- 减少销毁数量
        self.destroy_item_num = self.destroy_item_num - self.bonus_item_limit
        -- 奖励物品次数 + 1
        self.bonus_item_count = self.bonus_item_count + 1

        local gift
        local items = {} -- 奖品物品集合
        local giftItem = getGiftFrom(allBonusItems.festivalItemList) -- 节日
        if giftItem then
            -- 物品且可以放入容器
            if giftItem.components.inventoryitem and giftItem.components.inventoryitem.cangoincontainer then
                table.insert(items, giftItem)
            else
                table.insert(cantWrapItems, giftItem)
            end
        end
        giftItem = getGiftFrom(allBonusItems.materialItemList) -- 材料
        if giftItem then
            if giftItem.components.inventoryitem and giftItem.components.inventoryitem.cangoincontainer then
                table.insert(items, giftItem)
            else
                table.insert(cantWrapItems, giftItem)
            end
        end
        giftItem = getGiftFrom(allBonusItems.propItemList) -- 道具
        if giftItem then
            if giftItem.components.inventoryitem and giftItem.components.inventoryitem.cangoincontainer then
                table.insert(items, giftItem)
            else
                table.insert(cantWrapItems, giftItem)
            end
        end
        -- 如果是5的倍数，则提供珍贵物品
        -- 这里因为先加次数所以不用判断self.bonus_item_count大于0
        if self.bonus_item_count % self.big_bonus_per_count == 0 then
            giftItem = getGiftFrom(allBonusItems.rareItemList)
            if giftItem then
                if giftItem.components.inventoryitem and giftItem.components.inventoryitem.cangoincontainer then
                    gift = SpawnPrefab("redpouch_yotp") -- 珍贵物品且可以包装,则用福袋
                    table.insert(items, giftItem)
                else
                    gift = SpawnPrefab("gift")
                    table.insert(cantWrapItems, giftItem)
                end
                if not hasBigGift then
                    hasBigGift = true
                end
            end
        else
            gift = SpawnPrefab("gift")
            giftItem = getGiftFrom(allBonusItems.valuableItemList)
            if giftItem then
                if giftItem.components.inventoryitem and giftItem.components.inventoryitem.cangoincontainer then
                    table.insert(items, giftItem)
                else
                    table.insert(cantWrapItems, giftItem)
                end
            end
        end
        gift.components.unwrappable:WrapItems(items) -- 放入
        table.insert(gifts,gift)
    end
    -- DEGREES = PI/180
    local down = TheCamera:GetDownVec()
    local angle
    local sp
    local positon = Vector3(self.inst.Transform:GetWorldPosition()) + Vector3(0,2.5,0)
    for _,gift in ipairs(gifts) do
        gift.Transform:SetPosition(positon:Get())
        if gift.Physics == nil then
            MakeInventoryPhysics(gift)
        end
        angle = math.atan2(down.z, down.x) + (math.random()*60-30) * DEGREES
        sp = math.random()*4+2
        gift.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
    end
    for _,cantWrapItem in ipairs(cantWrapItems) do
        cantWrapItem.Transform:SetPosition(positon:Get())
        if cantWrapItem.Physics == nil then
            if cantWrapItem.components.inventoryitem then
                MakeInventoryPhysics(cantWrapItem)
            else
                if cantWrapItem:HasTag("heavy") then -- 重物
                    MakeHeavyObstaclePhysics(cantWrapItem)
                else
                    -- 暂时这样一般处理,后期再说,不一定所有奖品都能走这个
                    -- 也或许随便一个physics就行 ,不了解
                    -- TODO
                    MakeObstaclePhysics(cantWrapItem)
                end
            end
        end
        angle = math.atan2(down.z, down.x) + (math.random()*60-30) * DEGREES
        sp = math.random()*4+2
        cantWrapItem.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
    end
    return gifts,cantWrapItems,hasBigGift
end

function SecretGarbageCan:HandleBonus(doer)
    -- 奖励物品
    local gifts,cantWrapItems,hasBigGift = self:BonusItems()
    -- 生成特效,此特效会自动删除
    if #gifts > 0 or #cantWrapItems > 0 then
        SpawnPrefab("sand_puff_large_front").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if not hasBigGift then -- 普通奖励
            say(doer,subfmt(STRINGS.DORAEMON_TECH.DORAEMON_ACTION_GARBAGE_BONUS_PROMPT , { number = self.big_bonus_per_count -  self.bonus_item_count % self.big_bonus_per_count}))
        else
            say(doer,STRINGS.DORAEMON_TECH.DORAEMON_ACTION_GARBAGE_BIG_BONUS_PROMPT)
        end
    else
        SpawnPrefab("sand_puff").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        say(doer,subfmt(STRINGS.DORAEMON_TECH.DORAEMON_ACTION_GARBAGE_DESTROY_PROMPT , { number = self.bonus_item_limit - self.destroy_item_num}))
    end
end

--[[更新]]
function SecretGarbageCan:OnUpdate(dt)
    -- 更新获取
    -- 只能是heavy 或者背包
    -- 本来打算获取放置秘密垃圾洞上的背包和重物 , 且玩家不在附近时进行删除
    -- 改为手动销毁时,同时删除秘密垃圾洞上的背包和重物
    -- 废弃,代码也未完成
    local ents = TheSim:FindEntities(self.inst.Transform:GetWorldPosition(), math.ceil(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_RANGE), nil,{"flying", "shadow", "ghost", "FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost"},{"heavy","backpack","player"})
    if #ents > 0 then
        local hasRemove = false
        local hasPlayer = false
        for _ , v in ipairs(ents) do
            if v:IsValid() and v.components.health == nil then -- 不能是生物,保险起见增加此判断
                if not hasRemove then
                    hasRemove = true
                end

            end
        end

        if hasRemove then

        end
    end
end


function SecretGarbageCan:OnSave()
    return {
        destroy_item_num = self.destroy_item_num,
        bonus_item_count = self.bonus_item_count
    }
end
function SecretGarbageCan:OnLoad(data)
    if data.destroy_item_num then
        self.destroy_item_num = data.destroy_item_num
    end
    if data.bonus_item_count then
        self.bonus_item_count = data.bonus_item_count
    end
end
return SecretGarbageCan