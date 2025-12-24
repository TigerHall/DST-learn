--将多枝书替换为小树苗
local twiggytree_list={
	"twiggy_nut_sapling",
	"twiggytree",
}

-- for _,v in pairs(GLOBAL.Ents) do
	-- if v.prefab ~= nil and v.prefab == "twiggy_nut_sapling" or v.prefab == "twiggy_nut_sapling"  then
		-- v:DoTaskInTime(0, function(inst)
			-- local x, y, z = inst.Transform:GetWorldPosition()
			-- inst: Remove()
			-- GLOBAL.SpawnPrefab("sapling").Transform:SetPosition(x, y, z)
		-- end)
	-- end
-- end

for k,v in pairs(twiggytree_list) do 
	AddPrefabPostInit(v, function(inst)
		inst: DoTaskInTime(0, function(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			inst: Remove()
			GLOBAL.SpawnPrefab("sapling").Transform:SetPosition(x, y, z)
		end)
	end)
end