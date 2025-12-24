--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    尝试兼容showme mod


    从其他 魔卡少女小樱（百变小樱） 那得到的代码。


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




local container_prefabs = {
    "tbat_container_pear_cat",
    "tbat_container_cherry_blossom_rabbit_mini",
    "tbat_container_cherry_blossom_rabbit",
    "tbat_container_emerald_feathered_bird_collection_chest",
    "tbat_container_squirrel_stash_box",
    "tbat_the_tree_of_all_things_vine_maple_squirrel",
    "tbat_the_tree_of_all_things_vine_snow_plum_chieftain",
    "tbat_the_tree_of_all_things_vine_osmanthus_cat",
    "tbat_building_stump_table",
    "tbat_building_magic_potion_cabinet",
    "tbat_building_plum_blossom_table",
    "tbat_building_plum_blossom_hearth",
    "atbook_chefwolf",

}

for k, mod in pairs(ModManager.mods) do
    if mod and _G.rawget(mod, "SHOWME_STRINGS") then --showme特有的全局变量
        if
            mod.postinitfns and mod.postinitfns.PrefabPostInit and
            mod.postinitfns.PrefabPostInit.treasurechest
        then
            for _,v in ipairs(container_prefabs) do
				mod.postinitfns.PrefabPostInit[v] = mod.postinitfns.PrefabPostInit.treasurechest
			end
        end
        break
    end
end

--showme优先级如果比本mod低，那么这部分代码会生效
TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
for _, v in ipairs(container_prefabs) do
	TUNING.MONITOR_CHESTS[v] = true
end