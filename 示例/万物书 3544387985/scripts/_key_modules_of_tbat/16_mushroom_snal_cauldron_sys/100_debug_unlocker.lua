--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local base_prefab = "tbat_potion_recipe_for_"
local item_list = {
    "tbat_item_wish_note_potion",			-- 【药剂】 愿望之笺
    "tbat_item_veil_of_knowledge_potion", 	-- 【药剂】 知识之纱
    "tbat_item_oath_of_courage_potion", 	-- 【药剂】 勇气之誓
    "tbat_item_lucky_words_potion", 		-- 【药剂】 幸运之语
    -- "tbat_item_peach_blossom_pact_potion",	-- 【药剂】 桃花之约
}


AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    inst:DoTaskInTime(5,function()
        
        for i,prefab in ipairs(item_list) do
            local this_prefab = base_prefab..prefab
            if PrefabExists(this_prefab) and not inst.components.tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(prefab) then
                inst.components.inventory:GiveItem(SpawnPrefab(this_prefab))
            end
        end
    end)


end)