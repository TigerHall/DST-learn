Assets = 
{
  Asset("ATLAS", "images/jx_wardrobe_container.xml"),
  Asset("IMAGE", "images/jx_wardrobe_container.tex"),
  Asset("ATLAS", "images/jx_tab.xml"),
  Asset("IMAGE", "images/jx_tab.tex"),
  
  Asset("ANIM", "anim/ui_jx_basket_3x3.zip"),
  Asset("ANIM", "anim/ui_jx_car_5x5.zip"),
  Asset("ANIM", "anim/ui_jx_rug_bag_5x5.zip"),
  
  Asset("SOUND","sound/jx_sound_1.fsb"),
  Asset("SOUNDPACKAGE","sound/jx_sound_1.fev"),
  Asset("SOUND","sound/jx_sound_2.fsb"),
  Asset("SOUNDPACKAGE","sound/jx_sound_2.fev"),
  Asset("SOUND","sound/jx_sound_3.fsb"),
  Asset("SOUNDPACKAGE","sound/jx_sound_3.fev"),
  Asset("SOUND","sound/jx_sound_4.fsb"),
  Asset("SOUNDPACKAGE","sound/jx_sound_4.fev"),
  Asset("SOUND","sound/jx_sound_5.fsb"),
  Asset("SOUNDPACKAGE","sound/jx_sound_5.fev"),
  Asset("SOUND","sound/fire_machete.fsb"),
  Asset("SOUNDPACKAGE","sound/fire_machete.fev"),
}

local InventoryItem_LIST = {
    "jx_icebox",
    "jx_cookpot",
    "jx_chest",
    "jx_tent",
    "jx_fish_tank",
    "jx_phonograph",
    "jx_tapeplayer",
    "jx_tv",
    "jx_sofa_1",
    "jx_sofa_2",
    "jx_sofa_3",
    "jx_chair_1",
    "jx_chair_2",
    "jx_chair_3",
    "jx_table",
    "jx_table_2",
    "jx_table_3",
    "jx_table_4",
    "jx_table_5",
    "jx_table_6",
    "jx_mushroom_light",
    "jx_mushroom_light_2",
    "jx_lamp",
    "jx_furnace",
    "jx_wardrobe",
    "jx_sewingmachine",
    "jx_oven",
    "jx_backpack",
    "jx_backpack_2",
    "jx_pack",
    "jx_mailbox",
    "jx_bathtub",
    "jx_fan",
    "jx_well",
    "jx_washer",
    "jx_toilet_suction",
    "jx_wateringcan",
    "jx_toaster",
    "jx_toaster1",
    "jx_toaster2",
    "jx_toaster3",
    "jx_toaster4",
    "jx_toaster5",
    "jx_basket",
    "jx_bookcase",
    "jx_icemaker",
    "jx_lantern",
    "jx_car",
    "jx_rug_bag",
    
    "jx_potted",
    "jx_potted_sunflower",
    "jx_potted_cherry",
    "jx_potted_rose",
    "jx_potted_cactus",
    "jx_potted_anthurium",
    "jx_potted_narcissus",
    "jx_potted_snakeplant",
    "jx_red_rose_potted",
    "jx_green_palm",
    "jx_potted_gardenia",
    "jx_potted_monstera",
    "jx_xuncat",--喔喔！
    
    "jx_rug_oval",
    "jx_rug_oval_item",
    "jx_rug_forest",
    "jx_rug_forest_item",
    "jx_rug_triangle",
    "jx_rug_triangle_item",
    "jx_rug_aubusson",
    "jx_rug_aubusson_item",
    "jx_rug_tradition",
    "jx_rug_tradition_item",
    "jx_rug_savannah",
    "jx_rug_savannah_item",
    
    "turf_granite",
    
    "jx_hat_iron_pan",
    "jx_hat_white_rose",
    "jx_hat_sunflower",
    
    "jx_pan",
    "jx_weapon_1",
    "jx_weapon_2",
    "jx_weapon_3",
    "jx_weapon_4",
}

local ScrapBookData = require("screens/redux/scrapbookdata")
for _, item in pairs(InventoryItem_LIST) do
    RegisterScrapbookIconAtlas(resolvefilepath("images/inventoryimages/".. item .. ".xml"), item.. ".tex")
    RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/".. item .. ".xml"), item.. ".tex")
    ScrapBookData[item] = {name = item, tex=  item..".tex", prefab = item}

    table.insert(Assets, Asset("ATLAS", "images/inventoryimages/".. item .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/inventoryimages/".. item .. ".tex"))
    table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/".. item .. ".xml", 256))
end

local Minimap_LIST =
{
  "jx_backpack_2",
  "jx_backpack",
  "jx_basket",
  "jx_bathtub",
  "jx_bookcase",
  "jx_car",
  "jx_chest",
  "jx_cookpot",
  "jx_fish_tank",
  "jx_furnace",
  "jx_icebox",
  "jx_icemaker",
  "jx_mailbox",
  "jx_oven",
  "jx_pack",
  "jx_phonograph",
  "jx_rug_bag",
  "jx_sewingmachine",
  "jx_table_2",
  "jx_table_6",
  "jx_tent",
  "jx_tv",
  "jx_wardrobe",
  "jx_washer",
  "jx_well",
}

for _, name in ipairs(Minimap_LIST) do
    AddMinimapAtlas("images/inventoryimages/" .. name .. ".xml")
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

			if image ~= nil and table.contains(InventoryItem_LIST, image) then
				local atlas_path = resolvefilepath_soft("images/inventoryimages/".. image.. ".xml")
				if atlas_path then
					inst.AnimState:OverrideSymbol("SWAP_SIGN", atlas_path, image..".tex")
				end
			end

      if bgimage ~= nil and table.contains(InventoryItem_LIST, bgimage) then
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