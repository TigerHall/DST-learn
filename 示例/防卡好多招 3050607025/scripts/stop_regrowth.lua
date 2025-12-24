-- 可采摘类优化，设置为原生植物，不会枯萎
local function GrowthOptimization(inst)
    if not inst or not inst:IsValid() then return end
    
    if inst.components.pickable then
        inst.components.pickable.transplanted = false
        if inst.components.pickable:IsBarren() then
            inst.components.pickable:MakeEmpty()
            inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        end
    end 

    if inst.components.witherable then
        inst:RemoveComponent("witherable")
    end
    inst:AddTag("wildfireprotected")
end

-- 判断表中是否存在某一元素
local function table_key_exists(tables, key)
    return tables[key] ~= nil
end

-- 常青树、多枝树列表
local plantregrowth_evergreen_list={}
plantregrowth_evergreen_list["evergreen"]=true
plantregrowth_evergreen_list["evergreen_sparse"]=true
plantregrowth_evergreen_list["twiggytree"]=true

-- 常青树、多枝树去除循环(禁止循环，开档前若是枯木则转为三级状态)
for k,v in pairs(plantregrowth_evergreen_list) do
	AddPrefabPostInit(k, function(inst)
		inst:DoTaskInTime(0.1,function(inst)
			if not TheWorld.ismastersim then
				return
			end
			if inst.components and inst.components.growable then
				-- 所需最终阶段
				local need_final_stage = #inst.components.growable.stages - 1
				local real_final_stage = #inst.components.growable.stages
				inst.components.growable.stages[real_final_stage] = inst.components.growable.stages[need_final_stage]
				-- 禁止循环生长
				inst.components.growable.loopstages = false
				-- 世界已经存在的枯木自动转为三级
				if inst.components.growable.stage > need_final_stage then
					inst.components.growable:SetStage(need_final_stage)
				end
				if inst.components.growable.stage >= need_final_stage then
					inst.components.growable:StopGrowing()
				end
			end
			if inst.components and inst.components.plantregrowth then
				inst:RemoveComponent("plantregrowth")
			end
			
		end)
	end)
end

-- 长到最高级停止生长，常青树、多枝树只生长到第三级（第四级为枯萎状态）
AddComponentPostInit("growable",
	function(self)
		local old_StartGrowing = self.StartGrowing
		function self:StartGrowing(time)
			-- 若为常青树、多枝树等树，到第三阶段后立即停止生长
			if (table_key_exists(plantregrowth_evergreen_list, self.inst.prefab) and self.stage >= (#self.stages-1)) 
				or (self.inst.prefab == "lg_litchi_tree" and self.stage == #self.stages)
			then
				self:StopGrowing()
			else
				old_StartGrowing(self,time)
			end
		end
	end
)

-- 桦树、月树、蘑菇树列表
local plantregrowth_list={}
table.insert(plantregrowth_list,"deciduoustree")
table.insert(plantregrowth_list,"moon_tree")
table.insert(plantregrowth_list,"mushtree_tall")
table.insert(plantregrowth_list,"mushtree_medium")
table.insert(plantregrowth_list,"mushtree_small")
table.insert(plantregrowth_list,"marbleshrub")
table.insert(plantregrowth_list,"palmconetree")
for k,v in pairs(plantregrowth_list) do
	AddPrefabPostInit(v, function(inst)
		inst:DoTaskInTime(0.1,function(inst)
			if TheWorld.ismastersim then
				if inst.components and inst.components.growable then
					inst.components.growable.loopstages = false
				end
			end
		end)
	end)
end

-- 海洋传说：荔枝树优化。（适用可采摘、需要到最大阶段停止）
AddPrefabPostInit("lg_litchi_tree", function(inst)
	inst:DoTaskInTime(0.1,function(inst)
		-- 不会枯萎
		GrowthOptimization(inst)
	end)
end)

-- 海洋传说：柠檬树优化（适用可采摘、禁止变枯萎）
AddPrefabPostInit("lg_lemon_tree", function(inst)
	inst:DoTaskInTime(0.1,function(inst)
		-- 不会枯萎
		GrowthOptimization(inst)
	end)
end)

-- 海洋传说：柠檬树优化（适用可采摘、禁止变枯萎）
AddPrefabPostInit("lg_palmtree", function(inst)
	inst:DoTaskInTime(0.1,function(inst)
		if inst.components and inst.components.growable then
			inst.components.growable.loopstages = false
		end
	end)
end)

-- 棱镜三花优化
local lengion_list={"rosebush","lilybush","orchidbush"}
for k,v in pairs(lengion_list) do
	AddPrefabPostInit(v, function(inst)
		inst:DoTaskInTime(0.1,function(inst)
			-- 不会枯萎
			GrowthOptimization(inst)
		end)
	end)
end
