Assets ={
    Asset("SOUNDPACKAGE", "sound/mod_music.fev"),
    Asset("SOUND", "sound/mod_music_bank.fsb"),

    -- 制作栏图标
    Asset("ATLAS", "images/icons/honor_tech.xml"),
    Asset("IMAGE", "images/icons/honor_tech.tex"),
    Asset("ATLAS", "images/icons/terror_tech.xml"),
    Asset("IMAGE", "images/icons/terror_tech.tex"),
    Asset("ATLAS", "images/icons/hmr_tech.xml"),
    Asset("IMAGE", "images/icons/hmr_tech.tex"),

    Asset("ANIM", "anim/hmr_terrorbee_over.zip"),   -- 凶险事件屏幕动画
    Asset("ANIM", "anim/hmr_turfs.zip"),            -- 地皮
    Asset("ANIM", "anim/hmr_placement.zip"),        -- 放置圆圈
    Asset("ANIM", "anim/player_actions_surf.zip"),  -- 踏水
}

----------------------------------------------------------------------------
---[[小地图图标]]
----------------------------------------------------------------------------
local MINIMAPIMAGES_LIST = {
    -- 人物
    -- "hmr_lingna",

    -- 通用
    "honor_balance_maintainer", "honor_balance_maintainer_enabled",
    "honor_machine",
    "honor_tower",
    "honor_cookpot_icon",
    -- "honor_backpack",
    "hmr_cherry_rock",
    "hmr_cherry_grass",
    "hmr_cherry_tree_s1",
    "hmr_cherry_tree_s2",
    "hmr_cherry_tree_s3",
    "hmr_cherry_tree_s4",
}

for _, name in ipairs(MINIMAPIMAGES_LIST) do
    table.insert(Assets, Asset("ATLAS", "images/mapicons/" .. name .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/mapicons/" .. name .. ".tex"))
    AddMinimapAtlas("images/mapicons/" .. name .. ".xml")
end

AddMinimapAtlas("images/inventoryimages/honor_backpack.xml")

----------------------------------------------------------------------------
---[[物品图标]]
----------------------------------------------------------------------------
local INVENTORYIMAGES_LIST = {
    -- 精华
    "honor_coconut_prime",
    "honor_tea_prime",
    "honor_wheat_prime",
    "honor_rice_prime",
    "honor_goldenlanternfruit_prime",
    "honor_aloe_prime",
    "honor_nut_prime",
    "honor_hamimelon_prime",
    "terror_blueberry_prime",
    "terror_ginger_prime",
    "terror_snakeskinfruit_prime",
    "terror_coffee_prime",
    "terror_hawthorn_prime",
    "terror_lemon_prime",
    "terror_litchi_prime",
    "terror_passionfruit_prime",
    "hmr_bellpepper_prime",

    -- 调味料
    "spice_honor_coconut_prime", "spice_honor_tea_prime", "spice_honor_wheat_prime", "spice_honor_rice_prime",
    "spice_terror_blueberry_prime", "spice_terror_ginger_prime", "spice_terror_snakeskinfruit_prime",

    -- -- 料理
    -- "hmr_cherry_soda", "hmr_cherry_litchi_congee", "hmr_cherry_daifuku", "hmr_cherry_sorbet",

    -- 物品
    "honor_seeds", "terror_seeds",
    "honor_splendor", "honor_plantfibre", "terror_dangerous", "terror_mucous",
    "honor_greenjuice",
    "honor_hybrid_rice_seed",
    "honor_goldenlanternfruit_peel",
    "honor_aloe_mucous",
    "hmr_dug_cavebananatree",
    "honor_stower",
    "hmr_chest_factory_core_item",
    "hmr_chest_store_pack_big",
    "hmr_chest_store_pack_small",
    "hmr_blueberry_carpet_item",

    -- 装备
    "honor_backpack",
    "honor_armor", "honor_armor_broken",
    "honor_multitool", "honor_multitool_broken",
    "honor_hat", "honor_hat_broken",
    "honor_staff", "honor_staff_broken", "honor_staff_sakura", "honor_staff_broken_sakura",
    "honor_kit",
    "honor_blowdart_fire", "honor_blowdart_ice", "honor_blowdart_cure",
    "honor_coconut_hat",

    "terror_blueberry_hat",
    "terror_staff", "terror_staff_broken", "terror_staff_reverse", "terror_staff_broken_reverse",
    "terror_sword", "terror_sword_broken", "terror_sword_sakura", "terror_sword_broken_sakura",
    "terror_hat", "terror_hat_broken",
    "terror_armor", "terror_armor_broken",
    "terror_bomb",
    "terror_lemon_bomb",
    "terror_kit",

    -- 建筑
    "honor_machine",
    "honor_tower",
    "honor_cookpot",
    "honor_balance_maintainer", "honor_balance_maintainer_ground",
    "honor_goldenlanternfruit_lamp", "honor_goldenlanternfruit_lamp_coconut",
    "terror_machine", "terror_machine_bookshelf",
    "terror_tower", "terror_tower_hotspring", "terror_tower_fountain", "terror_tower_fountain_pink", "terror_tower_fountain_red",
    "hmr_chest_store",
    "hmr_chest_transmit",
    "hmr_chest_display",
    "hmr_chest_factory",
    "hmr_chest_recycle",

    -- 小生物
    "honor_bee", "terror_bee",

    -- 樱海岛
    "hmr_cherry_rock_item", "hmr_cherry_grass_seeds", "hmr_cherry_fluffy_ball", "hmr_cherry_grass_dug",
    "hmr_cherry_tree_flower", "hmr_cherry_tree_fruit", "hmr_cherry_tree_seeds",
    "hmr_cherry_lantern_post_item", "hmr_cherry_flowerpot_item", "hmr_cherry_flowerpot_large_item",
    "hmr_cherry_decor_pot", "hmr_cherry_decor_pot_b",
    "hmr_cherry_table", "hmr_cherry_table_lemon",
}

-- 农作物
local function AddFarmPlantImages(name, data)
    if data.fruits then
        for fruit, _ in pairs(data.fruits) do
            table.insert(INVENTORYIMAGES_LIST, fruit)
        end
    end

    if data.cooked then
        for cooked, _ in pairs(data.cooked) do
            table.insert(INVENTORYIMAGES_LIST, cooked)
        end
    end

    if data.seeds then
        for seed, seed_data in pairs(data.seeds) do
            if seed_data.common_seeds == nil then
                table.insert(INVENTORYIMAGES_LIST, seed)
            end
        end
    end

    local oversized = {
        name.."_oversized",
        name.."_oversized_waxed",
        name.."_oversized_rotten",
    }
    for _, image in pairs(oversized) do
        table.insert(INVENTORYIMAGES_LIST, image)
    end
end

local FARM_PLANTS_LIST = require("hmrmain/hmr_lists").FARM_PLANTS_LIST
for plant, data in pairs(FARM_PLANTS_LIST) do
    AddFarmPlantImages(plant, data)
end

-- 料理
local preparedfoods = require("hmrmain/hmr_preparedfoods")
for name, _ in pairs(preparedfoods) do
    table.insert(INVENTORYIMAGES_LIST, name)
end

-- 调味料
local spicedfoods = require("hmrmain/hmr_spicedfoods")
for _, data in pairs(spicedfoods.SPICES) do
    table.insert(INVENTORYIMAGES_LIST, data.product.."_over")
end

local ScrapBookData = require("screens/redux/scrapbookdata")
for _, item in pairs(INVENTORYIMAGES_LIST) do
    RegisterScrapbookIconAtlas(resolvefilepath("images/inventoryimages/".. item .. ".xml"), item.. ".tex")   -- 注册scrapbook图标
    RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/".. item .. ".xml"), item.. ".tex")   -- 注册物品栏图标
    ScrapBookData[item] = {name = item, tex=  item..".tex", prefab = item}                  -- 注册scrapbook图标(目前只为了用于TooManyItems)

    table.insert(Assets, Asset("ATLAS", "images/inventoryimages/".. item .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/inventoryimages/".. item .. ".tex"))
    table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/".. item .. ".xml", 256))  --生成小木牌需要的动画格式的贴图缓存
end

----------------------------------------------------------------------------
---[[物品栏背景图标]]
----------------------------------------------------------------------------
local SLOTIMAGES_LIST = {
    -- 辉煌炼化容器
    "honor_cookpot_prime_slot",
    -- 自然亲和塔
    "honor_tower_seeds_slot",
    "honor_tower_veggies_slot",
    -- 辉煌背包
    "honor_backpack_ice_slot",
    "honor_backpack_hot_slot",
    "honor_backpack_gift_slot",
    "honor_backpack_repair_slot",
    -- 青衢纳宝箱
    "hmr_chest_store_slot_1",
    "hmr_chest_store_slot_2",
    "hmr_chest_store_slot_3",
    "hmr_chest_store_slot_4",
    "hmr_chest_store_slot_5",
    "hmr_chest_store_slot_6",
    "hmr_chest_store_slot_7",
    "hmr_chest_store_slot_8",
    "hmr_chest_store_slot_9",
    "hmr_chest_store_slot_10",
    "hmr_chest_store_slot_11",
    "hmr_chest_store_slot_12",
    "hmr_chest_store_slot_13",
    "hmr_chest_store_slot_14",
    "hmr_chest_store_slot_15",
    "hmr_chest_store_slot_16",
    "hmr_chest_store_slot_17",
    "hmr_chest_store_slot_18",
    "hmr_chest_store_slot_19",
    "hmr_chest_store_slot_20",
    -- 龙龛探秘箱
    "hmr_chest_recycle_slot_1",
    "hmr_chest_recycle_slot_2",
    "hmr_chest_recycle_slot_3",
    "hmr_chest_recycle_slot_4",
    "hmr_chest_recycle_slot_5",
    "hmr_chest_recycle_slot_6",
    "hmr_chest_recycle_slot_7",
    "hmr_chest_recycle_slot_8",
    "hmr_chest_recycle_slot_9",
    "hmr_chest_recycle_slot_trashcan",

    -- 樱岩桌子
    "hmr_cherry_table_slot", "hmr_cherry_table_lemon_slot",
}

for _, item in pairs(SLOTIMAGES_LIST) do
    table.insert(Assets, Asset("ATLAS", "images/slotimages/".. item .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/slotimages/".. item .. ".tex"))
end

----------------------------------------------------------------------------
---[[UI图标]]
----------------------------------------------------------------------------
local UI_LIST = {
    "hmr_introduce",
    "hmr_buff", "hmr_buff_forest",
    "hmr_tech_bg",
    "hmr_tech_icons",
    "hmr_tech",
    "hmr_introduce_icons",
    "hmr_name",
}

for _, item in pairs(UI_LIST) do
    table.insert(Assets, Asset("ATLAS", "images/widgetimages/".. item .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/widgetimages/".. item .. ".tex"))
end

----------------------------------------------------------------------------
---[[小木牌]]
----------------------------------------------------------------------------
local function MiniSignPostinit(inst)
	if inst.components.drawable ~= nil then
		local oldondrawnfn = inst.components.drawable.ondrawnfn or nil
		inst.components.drawable.ondrawnfn = function(inst, image, src, atlas, bgimage, bgatlas, ...)
			if oldondrawnfn ~= nil then
				oldondrawnfn(inst, image, src, atlas, bgimage, bgatlas, ...)
			end

			if image ~= nil and table.contains(INVENTORYIMAGES_LIST, image) then
				local atlas_path = resolvefilepath_soft("images/inventoryimages/".. image.. ".xml")
				if atlas_path then
					inst.AnimState:OverrideSymbol("SWAP_SIGN", atlas_path, image..".tex")
				end
			end

            if bgimage ~= nil and table.contains(INVENTORYIMAGES_LIST, bgimage) then
                local atlas_path = resolvefilepath_soft("images/inventoryimages/".. bgimage.. ".xml")
                if atlas_path then
                    inst.AnimState:OverrideSymbol("SWAP_SIGN_BG", atlas_path, bgimage..".tex")
                end
            end
		end
	end
end

AddPrefabPostInit("minisign", MiniSignPostinit)
AddPrefabPostInit("minisign_drawn", MiniSignPostinit)
AddPrefabPostInit("decor_pictureframe", MiniSignPostinit)