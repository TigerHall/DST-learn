local containers = require "containers"
local params = containers.params
local cooking = require("cooking")

local function CanTakeItemInSlot(container, item, slot)
    local other_item = container:GetItemInSlot(slot)
    if other_item == nil or (
        container.acceptsstacks and
        other_item.replica.stackable and
        not other_item.replica.stackable:IsFull() and
        other_item.prefab == item.prefab and other_item.skinname == item.skinname)
    then
        return true
    end
    return false
end

------------------------------------------------------------------------------
---[[自然亲和塔]]
------------------------------------------------------------------------------
params.honor_tower =
{
    widget =
    {
        slotpos = {},
        animbank = "honor_tower_ui_6x12",
        animbuild = 'honor_tower_ui_6x12',
        pos = Vector3(0, 150, 0),
        side_align_tip = 100,
        animloop = true,
        slotbg ={},
    },
    type = "chest",
    usespecificslotsforitems = true,
}

for j = 1, 2 do
    for y = 5, 0, -1 do
        for x = 0, 5 do
            table.insert(params.honor_tower.widget.slotpos, Vector3(80 * (x - 2.5) + (j - 1.5) * 550, 80 * (y - 2.5), 0))
            if j == 1 then
                table.insert(params.honor_tower.widget.slotbg, {image = "honor_tower_veggies_slot.tex", atlas = "images/slotimages/honor_tower_veggies_slot.xml"})
            else
                table.insert(params.honor_tower.widget.slotbg, {image = "honor_tower_seeds_slot.tex", atlas = "images/slotimages/honor_tower_seeds_slot.xml"})
            end
        end
    end
end

function params.honor_tower.itemtestfn(container, item, slot)
    return container.inst:CanStore(item, slot)
end

------------------------------------------------------------------------------
---[[辉煌法杖]]
------------------------------------------------------------------------------
params.honor_weapon =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "ui_alterguardianhat_1x6",
        animbuild = "ui_alterguardianhat_1x6",
        pos = Vector3(106, 150, 0),
    },
    acceptsstacks = false,
    type = "hand_inv",
    excludefromcrafting = true,
}

local AGHAT_SLOTSTART = 95
local AGHAT_SLOTDIFF = 72
local SLOT_BG = { image = "spore_slot.tex", atlas = "images/hud2.xml" }
for i = 2, 4 do
    local sp = Vector3(0, AGHAT_SLOTSTART - (i*AGHAT_SLOTDIFF), 0)
    table.insert(params.honor_weapon.widget.slotpos, sp)
    -- table.insert(params.honor_weapon.widget.slotbg, SLOT_BG)
end

-- function params.honor_weapon.itemtestfn(container, item, slot)
--     return item:HasTag("honor_prime")
-- end

------------------------------------------------------------------------------
---[[辉煌背包]]
------------------------------------------------------------------------------
local ice_slot =        {image = "honor_backpack_ice_slot.tex", atlas = "images/slotimages/honor_backpack_ice_slot.xml"} --雪花背景
local sun_slot =        {image = "honor_backpack_hot_slot.tex", atlas = "images/slotimages/honor_backpack_hot_slot.xml"} --太阳背景
local gift_slot =       {image = "honor_backpack_gift_slot.tex", atlas = "images/slotimages/honor_backpack_gift_slot.xml"} --科技背景
local time_slot =       {image = "honor_backpack_repair_slot.tex", atlas = "images/slotimages/honor_backpack_repair_slot.xml"} --宝石背景

local LARGE_BACKPACK = HMR_CONFIGS.HONOR_BACKPACK_SLOTS == 30
params.honor_backpack =
{
    widget =
    {
        slotpos = {},
        slotbg = LARGE_BACKPACK and {
            nil,            nil,            nil,
            nil,            nil,            nil,
            nil,            nil,            nil,
            nil,            nil,            nil,
            nil,            nil,            nil,
            nil,            nil,            nil,
            ice_slot,       ice_slot,       ice_slot,
            sun_slot,       sun_slot,       sun_slot,
            gift_slot,      gift_slot,      gift_slot,
            time_slot,      time_slot,      time_slot,
        } or {
            nil, nil,
            nil, nil,
            nil, nil,
            nil, nil,
            nil, nil,
            nil, nil,
            ice_slot, sun_slot,
            gift_slot, time_slot,
        },
        animbank = LARGE_BACKPACK and "honor_backpack_ui_10x3" or "honor_backpack_ui_8x2",
        animbuild = LARGE_BACKPACK and "honor_backpack_ui_10x3" or "honor_backpack_ui_8x2",
        pos = LARGE_BACKPACK and Vector3(-120, -50, 0) or Vector3(-90, -50, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

if LARGE_BACKPACK then
    for y = 9, 0, -1 do
        for x = -1, 1 do
            table.insert(params.honor_backpack.widget.slotpos, Vector3(x * 75, (y - 4.5) * 75 + 10, 0))
        end
    end
else
    for y = 7, 0, -1 do
        for x = 0, 1 do
            table.insert(params.honor_backpack.widget.slotpos, Vector3((x - 0.5) * 80, (y - 3.5) * 80 + 10, 0))
        end
    end
end

------------------------------------------------------------------------------
---[[金盏灯]]
------------------------------------------------------------------------------
params.honor_goldenlanternfruit_lamp =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(200, 0, 0),
        side_align_tip = 160,
    },
    acceptsstacks = false,
    type = "cooker",
}

for y = 4, 1, -1 do
    table.insert(params.honor_goldenlanternfruit_lamp.widget.slotpos, Vector3(0, 72 * (y - 2.5), 0))
end

function params.honor_goldenlanternfruit_lamp.itemtestfn(container, item, slot)
    return item.prefab and string.find(item.prefab, "goldenlanternfruit") ~= nil
end

------------------------------------------------------------------------------
--[[装饰栅栏墙]]
------------------------------------------------------------------------------
params.hmr_decorate_wall =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(300, 0, 0),
        side_align_tip = 160,
    },
    type = "wall",
}

local DECORATION_INTERVAL = 30
for y = 19, 0, -1 do
    for x = 0, y % 2 == 0 and 7 or 6 do
        local x_offset = y % 2 == 0 and 0 or DECORATION_INTERVAL / 2
        table.insert(params.hmr_decorate_wall.widget.slotpos, Vector3(DECORATION_INTERVAL * (x - 3) + x_offset , DECORATION_INTERVAL * (y - 9), 0))
    end
end

------------------------------------------------------------------------------
--[[装饰栅栏拱门]]
------------------------------------------------------------------------------
params.hmr_flower_arch_basket =
{
    widget =
    {
        slotpos = {Vector3(-2, 18, 0)},
        animbank = "ui_chest_1x1",
        animbuild = "ui_chest_1x1",
        pos = Vector3(0, 160, 0),
        side_align_tip = 100,
    },
    acceptsstacks = false,
    type = "chest",
}

function params.hmr_flower_arch_basket.itemtestfn(container, item, slot)
    return item:HasTag("hmr_flower") and not container.inst:HasTag("burnt")
end


------------------------------------------------------------------------------
--[[箱子]]
------------------------------------------------------------------------------

------------------------------------------------------------------------------
--[[青衢纳宝箱【收纳整理】]]
------------------------------------------------------------------------------
params.hmr_chest_store =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_store_ui_1x3",
        animbuild = "hmr_chest_store_ui_1x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    table.insert(params.hmr_chest_store.widget.slotpos, Vector3(0, 80 * y - 80, 0))
    local rand = math.random(1, 5)
    table.insert(params.hmr_chest_store.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand..".xml", image = "hmr_chest_store_slot_"..rand..".tex"})
end

------------------------------------------------------------------------------
--[[青衢纳宝箱阵列]]
------------------------------------------------------------------------------
params.hmr_chest_store_array =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_store_ui_18x9",
        animbuild = "hmr_chest_store_ui_18x9",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
        animloop = true,
    },
    type = "chest",
    usespecificslotsforitems = true,
}

-- x是正向的， y是反向的
for j = 3, 1, -1 do
    for i = 1, 4 do
        for y = 3, 1, -1 do
            for x = 1, 3 do
                table.insert(params.hmr_chest_store_array.widget.slotpos, Vector3(75 * (x-2) + 240 * (i-2.5), 75 * (y-2) + 240 * (j-2), 0))
                local rand = math.random(1, 5)
                table.insert(params.hmr_chest_store_array.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand..".xml", image = "hmr_chest_store_slot_"..rand..".tex"})
            end
        end
    end
end

-- 为了便于升级与降级，分两次插入
for i = 1, 3 do
    for j = 3, 1, -1 do
        for y = 3, 1, -1 do
            table.insert(params.hmr_chest_store_array.widget.slotpos, Vector3(240 * 3 + 75 * (i-3), 75 * (y-2) + 250 * (j-2), 0))
            table.insert(params.hmr_chest_store_array.widget.slotpos, Vector3(- 240 * 3 - 75 * (i-3), 75 * (y-2) + 250 * (j-2), 0))

            local rand = math.random(1, 5) + i * 5
            table.insert(params.hmr_chest_store_array.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand..".xml", image = "hmr_chest_store_slot_"..rand..".tex"})
            table.insert(params.hmr_chest_store_array.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand..".xml", image = "hmr_chest_store_slot_"..rand..".tex"})
        end
    end
end

function params.hmr_chest_store_array.itemtestfn(container, item, slot)
    return container.inst.replica.hmrcontainermanager and
        container.inst.replica.hmrcontainermanager:ShouldShowSlot(slot) and
        CanTakeItemInSlot(container, item, slot)
end

------------------------------------------------------------------------------
--[[青衢纳宝箱阵列解体包]]
------------------------------------------------------------------------------
params.hmr_chest_store_pack_big =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_store_ui_18x9",
        animbuild = "hmr_chest_store_ui_18x9",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
        animloop = true,
    },
    type = "hmr_pack",
}

-- x是正向的， y是反向的
for j = 3, 1, -1 do
    for i = 1, 4 do
        for y = 3, 1, -1 do
            for x = 1, 3 do
                table.insert(params.hmr_chest_store_pack_big.widget.slotpos, Vector3(75 * (x-2) + 240 * (i-2.5), 75 * (y-2) + 240 * (j-2), 0))
                local rand = math.random(1, 5)
                table.insert(params.hmr_chest_store_pack_big.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand..".xml", image = "hmr_chest_store_slot_"..rand..".tex"})
            end
        end
    end
end

------------------------------------------------------------------------------
--[[青衢纳宝箱阵列降级包]]
------------------------------------------------------------------------------
params.hmr_chest_store_pack_small =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_store_ui_3x6",
        animbuild = "hmr_chest_store_ui_3x6",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160
    },
    type = "hmr_pack",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.hmr_chest_store_pack_small.widget.slotpos, Vector3(80 * (x - 1) - 140, 80 * (y - 1), 0))
        table.insert(params.hmr_chest_store_pack_small.widget.slotpos, Vector3(80 * (x - 1) + 140, 80 * (y - 1), 0))

        local rand1 = math.random(1, 5)
        table.insert(params.hmr_chest_store_pack_small.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand1..".xml", image = "hmr_chest_store_slot_"..rand1..".tex"})
        local rand2 = math.random(1, 5)
        table.insert(params.hmr_chest_store_pack_small.widget.slotbg, {atlas = "images/slotimages/hmr_chest_store_slot_"..rand2..".xml", image = "hmr_chest_store_slot_"..rand2..".tex"})
    end
end

------------------------------------------------------------------------------
--[[云梭递运箱【传送】]]
------------------------------------------------------------------------------
params.hmr_chest_transmit =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_transmit_ui_1x3",
        animbuild = "hmr_chest_transmit_ui_1x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    table.insert(params.hmr_chest_transmit.widget.slotpos, Vector3(0, 75 * (y - 1), 0))
end

------------------------------------------------------------------------------
--[[华樽耀勋箱【展示】]]
------------------------------------------------------------------------------
params.hmr_chest_display =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_display_ui_1x3",
        animbuild = "hmr_chest_display_ui_1x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    table.insert(params.hmr_chest_display.widget.slotpos, Vector3(0, 80 * y - 80, 0))
end

------------------------------------------------------------------------------
--[[灵枢织造箱【自动化工厂】]]
------------------------------------------------------------------------------
params.hmr_chest_factory =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_factory_ui_r5",
        animbuild = "hmr_chest_factory_ui_r5",
        pos = Vector3(0, 150, 0),
        side_align_tip = 160,
    },
    type = "chest"
}

for i = 0, 4 do
    local radius = 120
    local angle = (i * (2 * math.pi / 5)) + (math.pi / 2)
    local x = radius * math.cos(angle)
    local y = radius * math.sin(angle)
    table.insert(params.hmr_chest_factory.widget.slotpos, Vector3(-x, y, 0))
end

------------------------------------------------------------------------------
--[[龙龛探秘箱【翻找垃圾】]]
------------------------------------------------------------------------------
params.hmr_chest_recycle =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_chest_recycle_ui_5p4",
        animbuild = "hmr_chest_recycle_ui_5p4",
        pos = Vector3(0, 300, 0),
        side_align_tip = 160,
    },
    type = "chest",
    excludefromcrafting = true,
    acceptsstacks = false,
    usespecificslotsforitems = true,
}

for y = 7, 1, -1 do
    for x = 1, 8 - y do
        table.insert(params.hmr_chest_recycle.widget.slotpos, Vector3((x - (7 - y) / 2 - 1) * 75, (y - 3.5) * 75, 0))
        local rand = math.random(1, 3) + (y <= 2 and 0 or y <= 4 and 3 or 6)
        table.insert(params.hmr_chest_recycle.widget.slotbg, {atlas = "images/slotimages/hmr_chest_recycle_slot_"..rand..".xml", image = "hmr_chest_recycle_slot_"..rand..".tex"})
    end
end

function params.hmr_chest_recycle.itemtestfn(container, item, slot)
    local RECYCLE_CHEST_LIST = require("hmrmain/hmr_lists").RECYCLE_CHEST_LIST
    return container.inst.replica.hmrcontainermanager:ShouldShowSlot(slot) and
        CanTakeItemInSlot(container, item, slot) and
        RECYCLE_CHEST_LIST[item.prefab] ~= nil
end

------------------------------------------------------------------------------
--[[龙龛探秘箱垃圾销毁子箱]]
------------------------------------------------------------------------------
params.hmr_chest_recycle_virtual =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        pos = Vector3(0, 115, 0),
        side_align_tip = 160,
        buttoninfo =
        {
            text = STRINGS.ACTIONS.INCINERATE,  -- 按钮显示的文本
            position = Vector3(0, -100, 0),  -- 按钮位置
        }
    },
    type = "hmr_virtual_chest",
}

for y = 1, 0, -1 do
    for x = 0, 1 do
        table.insert(params.hmr_chest_recycle_virtual.widget.slotpos, Vector3(75 * (x - 0.5), 75 * (y - 0.5), 0))
        table.insert(params.hmr_chest_recycle_virtual.widget.slotbg, {image = "hmr_chest_recycle_slot_trashcan.tex", atlas = "images/slotimages/hmr_chest_recycle_slot_trashcan.xml"})
    end
end

function params.hmr_chest_recycle_virtual.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.INCINERATE):Do()  -- 执行燃烧动作
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.INCINERATE.code, inst, ACTIONS.INCINERATE.mod_name)  -- 发送RPC到服务器
    end
end

function params.hmr_chest_recycle_virtual.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

------------------------------------------------------------------------------
---[[辉煌炼化容器]]
------------------------------------------------------------------------------
params.honor_cookpot =
{
    widget =
    {
        slotpos = {
            Vector3(-160, 160, 0),
            Vector3(-80, 160, 0),
            Vector3(-160, 80, 0),
            Vector3(-80, 80, 0),
            Vector3(-120, -80, 0),

            Vector3(120, 120, 0),
            Vector3(120, -80, 0),

            Vector3(0, -160, 0),
        },
        slotbg = {
            {image = "inv_slot_morsel.tex", atlas = "images/hud.xml"},
            {image = "inv_slot_morsel.tex", atlas = "images/hud.xml"},
            {image = "inv_slot_morsel.tex", atlas = "images/hud.xml"},
            {image = "inv_slot_morsel.tex", atlas = "images/hud.xml"},
            {image = "preparedfood_slot.tex", atlas = "images/hud2.xml"},

            {image = "honor_cookpot_prime_slot.tex", atlas = "images/slotimages/honor_cookpot_prime_slot.xml"},
            {image = "cook_slot_spice.tex", atlas = "images/hud.xml"},

            {image = "cook_slot_food.tex", atlas = "images/hud.xml"},
        },
        animbank = "ui_honor_cookpot_6x6",
        animbuild = "ui_honor_cookpot_6x6",
        pos = Vector3(0, 115, 0),
        side_align_tip = 160,
    },
    type = "cooker",
    usespecificslotsforitems = true,
}

local SPICE_DATA_LIST = require("hmrmain/hmr_lists").SPICE_DATA_LIST
function params.honor_cookpot.itemtestfn(container, item, slot)
    if container.inst:HasTag("burnt") then
        return false
    end

    if slot ~= nil then
        if not CanTakeItemInSlot(container, item, slot) then
            return false
        end
        if slot >= 1 and slot <= 4 then
            -- 烹饪栏
            return cooking.IsCookingIngredient(item.prefab) or item:HasTag("saltbox_valid")
        elseif slot == 5 then
            -- 料理(用冰箱的测试函数)
            return params.icebox.itemtestfn(container, item, slot)
        elseif slot == 6 then
            -- 调味品原料
            return SPICE_DATA_LIST[item.prefab] ~= nil
        elseif slot == 7 then
            -- 调味品
            return item:HasTag("spice")
        elseif slot == 8 then
            -- 调味料理
            return string.find(item.prefab, "spice") ~= nil
        end
    else
        if cooking.IsCookingIngredient(item.prefab) or item:HasTag("saltbox_valid") then
            for i = 1, 4 do
                if CanTakeItemInSlot(container, item, i) then
                    return true
                end
            end
        elseif params.icebox.itemtestfn(container, item, slot) and CanTakeItemInSlot(container, item, 5) then
            return true
        elseif SPICE_DATA_LIST[item.prefab] ~= nil and CanTakeItemInSlot(container, item, 6) then
            return true
        elseif item:HasTag("spice") and CanTakeItemInSlot(container, item, 7) then
            return true
        elseif string.find(item.prefab, "spice") ~= nil and CanTakeItemInSlot(container, item, 8) then
            return true
        end
    end

    return false
end

------------------------------------------------------------------------------
--[[凶险法杖]]
------------------------------------------------------------------------------
params.terror_staff =
{
    widget =
    {
        slotpos = {
            Vector3(0, 36, 0),
        },
        slotbg = {},
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.terror_staff.itemtestfn(container, item, slot)
    return item:HasTag("terror_staff_consumable")
end

------------------------------------------------------------------------------
--[[凶险威澜台]]
------------------------------------------------------------------------------
local terror_tower_offset = -160
params.terror_tower =
{
    widget =
    {
        slotpos = {
            Vector3(-80, 200 + terror_tower_offset, 0),
            Vector3(0, 200 + terror_tower_offset, 0),
            Vector3(80, 200 + terror_tower_offset, 0),
        },
        slotbg = {},
        animbank = "ui_bookstation_4x5",
        animbuild = "ui_bookstation_4x5",
        pos = Vector3(0, 200, 0),
    },
    type = "chest",
    excludefromcrafting = true,
    acceptsstacks = false,
    usespecificslotsforitems = true,
}

for y = 4, 1, -1 do
    for x = 1, 4 do
        table.insert(params.terror_tower.widget.slotpos, Vector3(80 * (x - 2.5), 80 * (y - 2.5) + terror_tower_offset, 0))
        -- table.insert(params.terror_tower.widget.slotbg, {image = "inv_slot_empty.tex", atlas = "images/hud.xml"})
    end
end

function params.terror_tower.itemtestfn(container, item, slot)
    local item_slot = container.inst.item_slot
    if item_slot == nil then
        return true
    end
    if slot ~= nil then
        return (slot == 1 and item.prefab == item_slot[0]) or
            (slot == 2 and item.prefab == item_slot[1]) or
            (slot == 3 and item.prefab == item_slot[2]) or
            (slot >= 4 and (item:HasTag("heatrock") or item:HasTag("icebox_valid") or item:HasTag("HASHEATER")) and CanTakeItemInSlot(container, item, slot))
    end
    return item.prefab == item_slot[0] or
        item.prefab == item_slot[1] or
        item.prefab == item_slot[2] or
        item:HasTag("heatrock") or item:HasTag("icebox_valid") or item:HasTag("HASHEATER")
end

------------------------------------------------------------------------------
---[[樱花灯柱]]
------------------------------------------------------------------------------
params.hmr_cherry_lantern_post = {
    widget =
    {
        slotpos =
        {
            Vector3(-1, 18, 0),
        },
        animbank = "ui_chest_1x1",
        animbuild = "ui_chest_1x1",
        pos = Vector3(0, 80, 0),
        side_align_tip = 100,
    },
    acceptsstacks = false,
    type = "chest",
}

function params.hmr_cherry_lantern_post.itemtestfn(container, item, slot)
    return (item:HasTag("lightbattery") or item:HasTag("spore") or item:HasTag("lightcontainer") or item:HasTag("hmr_cherry_rock_item")) and not container.inst:HasTag("burnt")
end

------------------------------------------------------------------------------
--[[樱花桌子]]
------------------------------------------------------------------------------
params.hmr_cherry_table =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "hmr_cherry_table_ui_r5",
        animbuild = "hmr_cherry_table_ui_r5",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "table",
}

for i = 0, 4 do
    local radius = 120
    local angle = (i * (2 * math.pi / 5)) - (math.pi * 7 / 10)
    local x = radius * math.cos(angle)
    local y = radius * math.sin(angle)
    table.insert(params.hmr_cherry_table.widget.slotpos, Vector3(x, y, 0))
    table.insert(params.hmr_cherry_table.widget.slotbg, {image = "hmr_cherry_table_slot.tex", atlas = "images/slotimages/hmr_cherry_table_slot.xml"})
end

-- 柠檬桌子
params.hmr_cherry_table_lemon =
{
    widget =
    {
        slotbg = {},
        animbank = "hmr_cherry_table_lemon_ui_r5",
        animbuild = "hmr_cherry_table_lemon_ui_r5",
    },
}
for i = 0, 4 do
    table.insert(params.hmr_cherry_table_lemon.widget.slotbg, {image = "hmr_cherry_table_lemon_slot.tex", atlas = "images/slotimages/hmr_cherry_table_lemon_slot.xml"})
end

------------------------------------------------------------------------------
---[[更新最大插槽数]]
------------------------------------------------------------------------------
for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end