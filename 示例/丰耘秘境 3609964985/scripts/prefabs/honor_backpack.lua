local REPAIR_BLACK_LIST = require("hmrmain/hmr_lists").REPAIR_BLACK_LIST

local LARGE_BACKPACK = HMR_CONFIGS.HONOR_BACKPACK_SLOTS == 30

local preparedfoods = {}
local preparedfoods_warly = {}
local spicedfoods = {}

for name, _ in pairs(require("preparedfoods")) do
    table.insert(preparedfoods, tostring(name))
end
for name, _ in pairs(require("preparedfoods_warly")) do
    table.insert(preparedfoods_warly, tostring(name))
end
for name, _ in pairs(require("spicedfoods")) do
    table.insert(spicedfoods, name)
end

local gifts = {
    {  -- 高级材料包
        name = "bundle",
        weight = 10,
        gift = {
            honor_splendor = 0.2,       -- 自然辉煌
            honor_plantfibre = 0.4,     -- 植物纤维
            terror_dangerous = 0.01,    -- 自然凶险
            terror_mucous = 0.05,       -- 恐怖粘液
            purebrilliance = 0.05,      -- 纯粹辉煌
            lunarplant_husk = 0.1,      -- 亮茄外壳
            horrorfuel = 0.03,          -- 纯粹恐惧
            voidcloth = 0.03,           -- 暗影碎布
        },
    },
    {    -- 宝石包
        name = "gift",
        weight = 10,
        gift = {
            redgem = 0.3,               -- 红宝石
            bluegem = 0.4,              -- 蓝宝石
            greengem = 0.05,            -- 绿宝石
            yellowgem = 0.08,           -- 黄宝石
            purplegem = 0.1,            -- 紫宝石
            orangegem = 0.06,           -- 橙宝石
            opalpreciousgem = 0.01,     -- 彩虹玉石
        },
    },
    {    -- 石材类材料包
        name = "redpouch",
        weight = 30,
        gift = {
            goldnugget = 0.1,           -- 黄金矿石
            ice = 0.3,                  -- 冰块
            marble = 0.2,               -- 大理石
            nitre = 0.1,                -- 硝石
            flint = 0.2,                -- 燧石
            rocks = 0.5                 -- 岩石
        },
    },
    {   -- 低级材料包
        name = "redpouch_yotp",
        weight = 50,
        gift = {
            cutgrass = 0.3,             -- 草
            rope = 0.1,                 -- 绳子
            log = 0.2,                  -- 木头
            boards = 0.1,               -- 木板
            rocks = 0.2,                -- 岩石
            cutstone = 0.05             -- 石块
        },
    },
    {   -- 发光植物包
        name = "redpouch_yotc",
        weight = 20,
        gift = {
            foliage = 0.1,              -- 厥叶
            lightbulb = 0.5,            -- 荧光果
            wormlight = 0.2,            -- 发光浆果
            wormlight_lesser = 0.1,     -- 较小发光浆果
            spore_small = 0.1,          -- 绿色孢子
            spore_medium = 0.1,         -- 红色孢子
            spore_tall = 0.1            -- 蓝色孢子
        },
    },
    {  -- 纸
        name = "redpouch_yotb",
        weight = 10,
        gift = {
            cutreeds = 0.1,             -- 芦苇
            papyrus = 0.05,             -- 莎草纸
            waxpaper = 0.05,            -- 蜡纸
            beeswax = 0.1,              -- 蜜蜡
            giftwrap = 0.1              -- 礼物包装纸
        },
    },
    {  -- 隐士的礼物包（包含壳）
        name = "hermit_bundle_shells",
        weight = 10,
    },
    {  -- 春节种子包
        name = "yotc_seedpacket",
        weight = 10,
    },
    {  -- 稀有春节种子包
        name = "yotc_seedpacket_rare",
        weight = 10,
    },
    {  -- 嘉年华活动种子包
        name = "carnival_seedpacket",
        weight = 10,
    },
    {  -- 起皱的包裹
        name = "wetpouch",
        weight = 10,
    },
}

local function ChoosePack()
    local total_weight = 0
    for _, gift in ipairs(gifts) do
        total_weight = total_weight + gift.weight
    end
    local rand = math.random() * total_weight
    local weight_sum = 0
    for _, gift in ipairs(gifts) do
        weight_sum = weight_sum + gift.weight
        if rand <= weight_sum then
            return gift
        end
    end
    return gifts[math.random(1, #gifts)]
end

local function ChooseGift(pack)
    local total_weight = 0
    if pack.gift ~= nil then
        for name, weight in pairs(pack.gift) do
            total_weight = total_weight + weight
        end
        local rand = math.random() * total_weight
        local weight_sum = 0
        for name, weight in pairs(pack.gift) do
            weight_sum = weight_sum + weight
            if rand <= weight_sum then
                return name
            end
        end
    end
    return nil
end

local function WrapGift(inst)
    local owner = inst and inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:HasTag("player") then
        local pack_data = ChoosePack()
        local pack = SpawnPrefab(pack_data.name)
        if pack then
            if pack_data.gift ~= nil then
                local gift_list = {}
                for i = 1, math.random(3, 4) do
                    local gift = ChooseGift(pack_data)
                    if gift then
                        table.insert(gift_list, gift)
                    end

                end
                if pack.components.unwrappable then
                    pack.components.unwrappable:WrapItems(gift_list, owner)
                end
            end
            return pack
        end
    end
end

local assets =
{
    Asset("ANIM", "anim/honor_backpack.zip"),
    Asset("ANIM", "anim/honor_backpack_ui_10x3.zip"),
    Asset("ANIM", "anim/honor_backpack_ui_8x2.zip"),
}

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "honor_backpack" )
    else
        owner.AnimState:OverrideSymbol("swap_body", "honor_backpack", "swap_body")
    end

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")

    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function onequiptomodel(inst, owner)
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function GetWalkSpeedMult(inst)
    if inst.components.container ~= nil then
        local max_valid_items_count = LARGE_BACKPACK and 18 or 12
        local items_count = math.min(#inst.components.container:GetAllItems(), max_valid_items_count)
        local speed_mult = (items_count / max_valid_items_count) * 0.5
        local setbonus_enabled = inst.components.setbonus and inst.components.setbonus:IsEnabled("HONOR")
        return HMR_UTIL.FormatNumber(1 + speed_mult * (setbonus_enabled and 1 or -1))
    end
    return 1
end

local function OnItemChanged(inst, data)
    if inst:GetSlotType(data.slot) == "gift" then
        local timer_name = "honor_gift_slot"..data.slot
        if inst.components.container.slots[data.slot] == nil then
            if not inst.components.timer:TimerExists(timer_name) then
                inst.components.timer:StartTimer(timer_name, TUNING.HMR_HONOR_BACKPACK_GIFTWAITTIME)
            end
        else
            inst.components.timer:StopTimer(timer_name)
        end
    end

    inst.components.equippable.walkspeedmult = GetWalkSpeedMult(inst)
end

local function UpdateGiftSlots(inst)
    if inst.components.container ~= nil then
        for i = 1, inst.components.container.numslots do
            local slot_type = inst:GetSlotType(i)
            if slot_type == "gift" then
                OnItemChanged(inst, {slot = i})
            end
        end
    end
end

local function OnTimerDown(inst, timer_data)
    if string.sub(timer_data.name, 1, 15) == "honor_gift_slot" then
        local slot = tonumber(string.sub(timer_data.name, 16))
        local pack = WrapGift(inst)
        inst.components.container:GiveItem(pack, slot)
    end
end

local function GetSlotType(inst, slot)
    if not slot then
        return "empty"
    end
    if LARGE_BACKPACK then
        if slot >= 19 and slot <= 21 then
            return "ice"
        elseif slot >= 22 and slot <= 24 then
            return "hot"
        elseif slot >= 25 and slot <= 27 then
            return "gift"
        elseif slot >= 28 and slot <= 30 then
            return "time"
        else
            return "empty"
        end
    else
        return slot == 13 and "ice" or
               slot == 14 and "hot" or
               slot == 15 and "gift" or
               slot == 16 and "time" or
               "empty"
    end
end

local function PerishRateMult(inst, item)
    if item and inst.components.container then
        local slot = inst.components.container:GetItemSlot(item)
        if slot then
            if inst:GetSlotType(slot) == "ice" then
                return TUNING.HMR_HONOR_BACKPACK_PERISHABLE_MULTIPLIER
            elseif inst:GetSlotType(slot) == "time" then
                return TUNING.HMR_HONOR_BACKPACK_REPAIRSPEED.PERISHABLE
            else
                return 1
            end
        end
    end
    return 1
end

local function FindAvailableSlot(inst, item)
    if item == "ash" then
        return nil
    end

    -- 熟食放置顺序：冷藏--修复--普通--炽热--礼物，优先寻找可堆叠的格子
    local order_nums = LARGE_BACKPACK and {
        {19, 20, 21, 28, 29, 30},
        {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 25, 26, 27}
    } or {
        {13, 16},
        {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15}
    }
    for _, order_group in ipairs(order_nums) do
        local empty_slot = -1
        for _, order in ipairs(order_group) do
            local slot = inst.components.container.slots[order]
            if slot then
                -- 检查物品是否可堆叠且未满
                if slot.prefab == item and
                    slot.components.stackable and
                    not slot.components.stackable:IsFull()
                then
                    return order
                end
            elseif empty_slot == -1 then
                empty_slot = order
            end
        end
        if empty_slot ~= -1 then
            return empty_slot
        end
    end
end

local function CookItem(inst, item)
    if item and item.components.cookable ~= nil and item.components.cookable.product ~= nil then
        if item.components.stackable ~= nil and item.components.stackable:StackSize() > 1 then
            item.components.stackable:Get()
        else
            item:Remove()
        end

        local product = nil
        local product_num = 0
        local product_rand = math.random()

        if product_rand < 0.02 then
            product = preparedfoods[math.random(1, #preparedfoods)]
            product_num = 1
        elseif product_rand < 0.025 then
            product = preparedfoods_warly[math.random(1, #preparedfoods_warly)]
            product_num = 1
        elseif product_rand < 0.03 then
            product = spicedfoods[math.random(1, #spicedfoods)]
            product_num = 1
        elseif product_rand < 0.13 then
            product = item.components.cookable.product
            product_num = 2
        elseif product_rand < 0.7 then
            product = item.components.cookable.product
            product_num = 1
        else
            product = "ash"
            product_num = 1
        end

        for i = 1, product_num do
            local slot = FindAvailableSlot(inst, product)
            inst.components.container:GiveItem(SpawnPrefab(product), slot)
        end
    end
end

local function GetRepairAmount(cur, max, amount, max_per)
    local max_possible_repair = max_per * max
    local needed_repair = max - cur
    local actual_repair = math.min(needed_repair, amount, max_possible_repair)
    return actual_repair
end

local function RepairItem(inst, item)
    if REPAIR_BLACK_LIST[item.prefab] then
        return
    end

    -- 护甲类型耐久度
    if item.components.armor ~= nil and item.components.armor:IsDamaged() then
        local max = item.components.armor.maxcondition
        local cur = item.components.armor.condition
        local delta = TUNING.HMR_HONOR_BACKPACK_REPAIRSPEED.ARMOR
        local max_per = TUNING.HMR_HONOR_BACKPACK_REPAIRPERCENT.ARMOR
        local amount = GetRepairAmount(cur, max, delta, max_per)
        item.components.armor:Repair(amount)
    end

    -- 工具类型耐久度
    if item.components.finiteuses and item.components.finiteuses:GetPercent() < 1 then
        local max = item.components.finiteuses.total
        local cur = item.components.finiteuses.current
        local delta = TUNING.HMR_HONOR_BACKPACK_REPAIRSPEED.FINITEUSES
        local max_per = TUNING.HMR_HONOR_BACKPACK_REPAIRPERCENT.FINITEUSES
        local amount = GetRepairAmount(cur, max, delta, max_per)
        item.components.finiteuses:Repair(amount)
    end

    -- 新鲜度
    -- 在preserver中处理

    -- 燃料类耐久度
    if item.components.fueled ~= nil and not item.components.fueled:IsFull() then
        local max = item.components.fueled.maxfuel
        local cur = item.components.fueled.currentfuel
        local delta = TUNING.HMR_HONOR_BACKPACK_REPAIRSPEED.FUELED
        local max_per = TUNING.HMR_HONOR_BACKPACK_REPAIRPERCENT.FUELED
        local amount = GetRepairAmount(cur, max, delta, max_per)
        item.components.fueled:DoDelta(amount)
    end

    -- 破损修理
    if item.components.forgerepairable and item.components.forgerepairable.onrepaired then
        item.components.forgerepairable.onrepaired(item)
    end
    if item.components.hmrrepairable then
        item.components.hmrrepairable:OnRepaired()
    end
end

local function UpdateItemsStatus(inst)
    if inst.components.container ~= nil then
        for i = 1, inst.components.container.numslots do
            local item = inst.components.container:GetItemInSlot(i)
            if item then
                if inst:GetSlotType(i) == "hot" then
                    CookItem(inst, item)
                elseif inst:GetSlotType(i) == "time" then
                    RepairItem(inst, item)
                end
            end
        end
    end
end

local function SetBonusEnabled(inst)
    inst.components.equippable.walkspeedmult = GetWalkSpeedMult(inst)
end

local function SetBonusDisabled(inst)
    inst.components.equippable.walkspeedmult = GetWalkSpeedMult(inst)
end

local function SlotTemperature(inst, slot)
    if inst:GetSlotType(slot) == "hot" then
        return 55, TUNING.HMR_HONOR_BACKPACK_HEATING_RATE
    elseif inst:GetSlotType(slot) == "ice" then
        return 5, TUNING.HMR_HONOR_BACKPACK_COOLING_RATE
    end
    return 0
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("honor_backpack.tex")

    inst.AnimState:SetBank("honor_backpack")
    inst.AnimState:SetBuild("honor_backpack")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/krampuspack"

    inst:AddTag("backpack")
    inst:AddTag("honor_backpack")
    inst:AddTag("waterproofer")
    inst:AddTag("zoomablecontainerui")
    inst:AddTag("dragablecontainerui")

    local swap_data = {bank = "honor_backpack", anim = "idle"}
    MakeInventoryFloatable(inst, "med", 0.1, 0.65, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_backpack.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = HMR_EQUIPSLOTS.BACKPACK
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.2)

    inst:AddComponent("timer")

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")
    inst.components.setbonus:SetOnEnabledFn(SetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetBonusDisabled)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("honor_backpack")

    inst:AddComponent("hmrcontainermanager")
    inst.components.hmrcontainermanager:SetSlotTemperature(SlotTemperature)

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(PerishRateMult)

    inst:ListenForEvent("itemget", OnItemChanged)
    inst:ListenForEvent("itemlose", OnItemChanged)
    inst:ListenForEvent("timerdone", OnTimerDown)

    inst:DoTaskInTime(0, UpdateGiftSlots)
    inst:DoPeriodicTask(1, UpdateItemsStatus)

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst.GetSlotType = GetSlotType

    return inst
end

return Prefab("honor_backpack", fn, assets)