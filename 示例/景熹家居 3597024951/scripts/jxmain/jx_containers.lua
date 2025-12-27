local containers = require "containers"
local params = containers.params
local cooking = require("cooking")

------------------------------------------------------------------------------
---[[复古枫叶木盒]]
------------------------------------------------------------------------------
params.jx_chest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chester_upgraded_3x4",
        animbuild = "ui_chester_upgraded_3x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2.5, -0.5, -1 do
    for x = 0, 2 do
        table.insert(params.jx_chest.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
    end
end

------------------------------------------------------------------------------
---[[复古电煮锅]]
------------------------------------------------------------------------------
params.jx_cookpot = params.cookpot

------------------------------------------------------------------------------
---[[复古电冰箱]]
------------------------------------------------------------------------------
params.jx_icebox = deepcopy(params.treasurechest)
params.jx_icebox.widget.animbank = "ui_boat_ancient_4x4"
params.jx_icebox.widget.animbuild = "ui_boat_ancient_4x4"
params.jx_icebox.widget.slotpos = {}

for y = 3, 0, -1 do
    for x = 0, 3 do
        table.insert(params.jx_icebox.widget.slotpos, Vector3(80 * x - 80 * 2.5 + 80, 80 * y - 80 * 2.5 + 80, 0))
    end
end

function params.jx_icebox.itemtestfn(container, item, slot)
    if item:HasTag("icebox_valid") then
        return true
    end

    --Perishable
    if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        return false
    end

	if item:HasTag("smallcreature") then
		return false
	end

    --Edible
    for k, v in pairs(FOODTYPE) do
        if item:HasTag("edible_"..v) then
            return true
        end
    end

    return false
end

------------------------------------------------------------------------------
---[[洛可可海缸柜]]
------------------------------------------------------------------------------
params.jx_fish_tank = params.jx_chest

------------------------------------------------------------------------------
---[[复古电视机]]
------------------------------------------------------------------------------
params.jx_tv = params.yots_lantern_post

------------------------------------------------------------------------------
---[[洗衣机]]
------------------------------------------------------------------------------
params.jx_washer = {
    widget =
    {
        slotpos =
        {
             Vector3(-2, 38, 0),
        },
        animbank = "ui_chest_1x2",
        animbuild = "ui_chest_1x2",
        pos = Vector3(0, 160, 0),
        side_align_tip = 100,
        buttoninfo =
        {
            text = STRINGS.ACTIONS.GIVE.WASH,
            position = Vector3(0, -50, 0),
        }
    },
    acceptsstacks = false,
    type = "chest",
}
function params.jx_washer.itemtestfn(container, item, slot)
    return item:HasTag("_equippable") and not item:HasAnyTag("tool", "weapon", "pocketwatch", "icebox_valid")
end

function params.jx_washer.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.INCINERATE):Do()--(RPC还不会用)
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.INCINERATE.code, inst, ACTIONS.INCINERATE.mod_name)
    end
end

function params.jx_washer.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

------------------------------------------------------------------------------
---[[诺伊堡绿色煤油暖炉]]
------------------------------------------------------------------------------
params.jx_furnace = 
{
    widget =
    {
        slotpos =
        {
            Vector3(-159.5, 106, 0),
            Vector3(-84.5, 106, 0),
            Vector3(-159.5, 34, 0),
            Vector3(-84.5, 34, 0),
            Vector3(-159.5, -38, 0),
            Vector3(-84.5, -38, 0),
        },
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(300, 0, 0),
        side_align_tip = 120,
        buttoninfo =
        {
            text = STRINGS.ACTIONS.INCINERATE,
            position = Vector3(-122, -102, 0),
        }
    },
    type = "cooker",
}

function params.jx_furnace.itemtestfn(container, item, slot)
    return not item:HasTag("irreplaceable")
end

function params.jx_furnace.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.INCINERATE):Do()
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.INCINERATE.code, inst, ACTIONS.INCINERATE.mod_name)
    end
end

function params.jx_furnace.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end
------------------------------------------------------------------------------
--衣柜
------------------------------------------------------------------------------

local wardrobe_tags = {
    "_equippable",
    "reloaditem_ammo",
    "tool",
    "weapon",
    "heatrock",
    "fan",
    "pocketwatch",
    "trap",
    "mine",
    "broken",
}

local wardrobe_prefabs = {
    "razor",
    "beef_bell",
    "pocketwatch_parts",
    "pocketwatch_dismantler",
    "sewing_tape",
    "sewing_kit",
    "lunarplant_kit",
    "voidcloth_kit",
    "wagpunkbits_kit",
	  "spiderden_bedazzler",
	  "spider_whistle",
  	"spider_repellent",
    "sludge_oil",
    "saddle_basic",
    "saddle_race",
    "saddle_war",
    "saddle_wathgrithr",
    "saddle_shadow",
}

local function CheckWardrobeItem(container, item, slot)
    if item:HasOneOfTags(wardrobe_tags) then
        return true
    end
    for _, prefab in pairs(wardrobe_prefabs) do
        if item.prefab == prefab then
            return true
        end
    end

    return string.match(item.prefab, "wx78module_") ~= nil
end

params.jx_wardrobe =
{
    widget =
    {
        slotpos = {},
        animbank = nil,
        animbuild = nil,
        bgatlas = "images/jx_wardrobe_container.xml",
        bgimage = "jx_wardrobe_container.tex",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = CheckWardrobeItem,
}

for y = 2.5, -1.5, -1 do
    for x = 0, 4 do
        table.insert(params.jx_wardrobe.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 85 * 2 + 120, 0))
    end
end
------------------------------------------------------------------------------
--甲壳虫车
------------------------------------------------------------------------------
params.jx_car =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_jx_car_5x5",
        animbuild = "ui_jx_car_5x5",
        pos = Vector3(400, -70, 0),
        side_align_tip = 160,
    },
    type = "chest",
}
for y = 2.5, -2.5, -1 do
    for x = -1, 4 do
        table.insert(params.jx_car.widget.slotpos, Vector3(80 * x - 120, 80 * y - 15, 0))
    end
end
------------------------------------------------------------------------------
--兔子背包
------------------------------------------------------------------------------
params.jx_backpack =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
--        pos = Vector3(-5, -50, 0),
        pos = Vector3(-5, -90, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

for y = 0, 5 do
    table.insert(params.jx_backpack.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(params.jx_backpack.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end

params.jx_backpack_2 = params.jx_backpack
------------------------------------------------------------------------------
--熊熊野餐盒
------------------------------------------------------------------------------
params.jx_pack =
{
    widget =
    {
        slotpos = 
        {
          Vector3(38, 38, 0),
          Vector3(38, -38, 0),
          Vector3(-38, -38, 0),
          Vector3(-38, 38, 0),
        },
        animbank = "ui_chest_2x2",
        animbuild = "ui_chest_2x2",
        pos = Vector3(160, 20, 0),
    },
    type = "chest",
    openlimit = 1,
}

function params.jx_pack.itemtestfn(container, item, slot)
    if item:HasTag("icebox_valid") then
        return true
    end

    --Perishable
    if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        return false
    end

	if item:HasTag("smallcreature") then
		return false
	end

    --Edible
    for k, v in pairs(FOODTYPE) do
        if item:HasTag("edible_"..v) then
            return true
        end
    end

    return false
end
------------------------------------------------------------------------------
--手工菜篮
------------------------------------------------------------------------------
params.jx_basket =
{
    widget =
    {
        slotpos = {},
        animbank  = "ui_jx_basket_3x3",
        animbuild = "ui_jx_basket_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.jx_basket.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

function params.jx_basket.itemtestfn(container, item, slot)
    if item:HasTag("icebox_valid") then
        return true
    end

    if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        return false
    end

  	if item:HasTag("smallcreature") then
	  	return false
	  end

    --Edible
    for k, v in pairs(FOODTYPE) do
        if item:HasTag("edible_"..v) then
            return true
        end
    end

    return false
end
------------------------------------------------------------------------------
--展示柜
------------------------------------------------------------------------------
params.jx_bookcase = 
{
    widget =
    {
        slotpos =
        {
            Vector3(-159.5, -86, 0),
            Vector3(-84.5,  -86, 0),
            Vector3(-159.5, 0,   0),
            Vector3(-84.5,  0,   0),
            Vector3(-159.5, 86,  0),
            Vector3(-84.5,  86,  0),
        },
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(300, 0, 0),
        side_align_tip = 120,
    },
    acceptsstacks = false,
    type = "cooker",
}

function params.jx_bookcase.itemtestfn(container, item, slot)
  return item:HasTag("preparedfood")
end
-------------------------------------------------------------------------------
--制冰机
--------------------------------------------------------------------------------
params.jx_icemaker =
{
    widget =
    {
        slotpos =
        {
            Vector3(-37.5, 32 + 4, 0),
            Vector3(37.5, 32 + 4, 0),
            Vector3(-37.5, -(32 + 4), 0),
            Vector3(37.5, -(32 + 4), 0),
        },
        animbank = "ui_bundle_2x2",
        animbuild = "ui_bundle_2x2",
        pos = Vector3(200, 0, 0),
        side_align_tip = 120,
        buttoninfo =
        {
            text = STRINGS.JX_MAKE_ICE,
            position = Vector3(0, -100, 0),
        }
    },
    type = "cooker",
}

function params.jx_icemaker.itemtestfn(container, item, slot)
    return item:HasAnyTag("ice", "rocks")
end

function params.jx_icemaker.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.INCINERATE):Do()--(RPC还不会用)
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.INCINERATE.code, inst, ACTIONS.INCINERATE.mod_name)
    end
end

function params.jx_icemaker.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and inst.replica.container:HasItemWithTag("rocks", 1)--至少一个
end
-------------------------------------------------------------------------------
--地毯包
--------------------------------------------------------------------------------
params.jx_rug_bag =
{
    widget =
    {
        slotpos = {},
        animbank  = "ui_jx_rug_bag_5x5",
        animbuild = "ui_jx_rug_bag_5x5",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2.5, -2.5, -1 do
    for x = -1, 4 do
        table.insert(params.jx_rug_bag.widget.slotpos, Vector3(80 * x - 120, 80 * y - 5, 0))
    end
end

function params.jx_rug_bag.itemtestfn(container, item, slot)
    return item:HasTag("jx_rug_item") or item:HasTag("groundtile") and item.tile
end
------------------------------------------------------------------------------
---[[更新最大插槽数]]

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end