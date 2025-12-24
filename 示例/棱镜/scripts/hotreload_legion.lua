--环境: modmain

--预制物

local hot = {
	--k: prefab名   v: 对应的lua文件名
	-- siving_foenix = 'boss_siving_phoenix',
	-- siving_moenix = 'boss_siving_phoenix',
	-- siving_feather_real = 'boss_siving_phoenix',
	-- dish_tomahawksteak = 'foods_cookpot',
	-- siving_mask = 'siving_related',
	-- hat_elepheetle = 'insectthings_l',
	animtest_l1 = 'animtest_legion',
	animtest_l2 = 'animtest_legion',
	animtest_l3 = 'animtest_legion',
	animtest_l4 = 'animtest_legion'
}
local old_sp = GLOBAL.SpawnPrefab
function GLOBAL.SpawnPrefab(prefab, ...)
	if hot[prefab] then
		LoadPrefabFile('prefabs/'..hot[prefab])
	end
	return old_sp(prefab, ...)
end

--类 (组件 界面 状态图 脑)

local class = {
	--路径名
	-- "widgets/skinlegiondialog",
	-- 'map/static_layouts/helpercemetery',
	-- 'map/rooms/forest/rooms_desertsecret',
	-- 'hotreload_legion',
}
-- local old_re = GLOBAL.require --！！！请把require写成_G.require，不然可能不成功
-- function GLOBAL.require(path)
-- 	for _, v in pairs(class)do
-- 		if v == path then
-- 			package.loaded[path] = nil
-- 			break
-- 		end
-- 	end
-- 	return old_re(path)
-- end
