local function _PlayAnimation(inst, anim, loop)
	inst.AnimState:PlayAnimation(anim, loop)
	if inst.back then
		inst.back.AnimState:PlayAnimation(anim, loop)
	end
end

local function _PushAnimation(inst, anim, loop)
	inst.AnimState:PushAnimation(anim, loop)
	if inst.back then
		inst.back.AnimState:PushAnimation(anim, loop)
	end
end

local function _AnimSetTime(inst, t)
	inst.AnimState:SetTime(t)
	if inst.back then
		inst.back.AnimState:SetTime(t)
	end
end

local function CancelSitterAnimOver(inst)
	if inst._onsitteranimover then
		inst:RemoveEventCallback("animover", inst._onsitteranimover, inst._onsitteranimover_sitter)
		inst._onsitteranimover = nil
		inst._onsitteranimover_sitter = nil
	end
end

local function OnHit(inst, worker, workleft, numworks)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
		if inst.back ~= nil then
			inst.back.AnimState:PlayAnimation("hit")
			inst.back.AnimState:PushAnimation("idle", false)
		end
    if inst.side ~= nil then
			inst.side.AnimState:PlayAnimation("hit")
			inst.side.AnimState:PushAnimation("idle", false)
		end
	end
end

local function OnHammered(inst, worker)
	local collapse_fx = SpawnPrefab("collapse_small")
	collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	collapse_fx:SetMaterial("wood")

	inst.components.lootdropper:DropLoot()

	inst:Remove()
end

local function OnBuilt(inst, data)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	if inst.back ~= nil then
		inst.back.AnimState:PlayAnimation("place")
		inst.back.AnimState:PushAnimation("idle", false)
	end
  if inst.side ~= nil then
		inst.side.AnimState:PlayAnimation("place")
		inst.side.AnimState:PushAnimation("idle", false)
	end

	inst.SoundEmitter:PlaySound("dontstarve/common/repair_stonefurniture")

	local builder = (data and data.builder) or nil
	TheWorld:PushEvent("CHEVO_makechair", {target = inst, doer = builder})
end

local function OnSyncChairRocking(inst, sitter)
	if inst.components.sittable:IsOccupiedBy(sitter) then
		if sitter.AnimState:IsCurrentAnimation("rocking_pre") then
			_PlayAnimation(inst, "rocking_pre")
			local t = sitter.AnimState:GetCurrentAnimationTime()
			local len = inst.AnimState:GetCurrentAnimationLength()
			if t < len then
				_AnimSetTime(inst, t)
				_PushAnimation(inst, "rocking_loop")
			else
				_PlayAnimation(inst, "rocking_loop", true)
				_AnimSetTime(inst, t - len)
			end
			CancelSitterAnimOver(inst)
		elseif sitter.AnimState:IsCurrentAnimation("rocking_loop") then
			_PlayAnimation(inst, "rocking_loop", true)
			_AnimSetTime(inst, sitter.AnimState:GetCurrentAnimationTime())
			CancelSitterAnimOver(inst)
		elseif sitter.AnimState:IsCurrentAnimation("sit_off") then
			CancelSitterAnimOver(inst)
		elseif sitter.AnimState:IsCurrentAnimation("sit_jump_off") then
			_PlayAnimation(inst, "rocking_pst")
			_PushAnimation(inst, "idle", false)
			CancelSitterAnimOver(inst)
		else
			if sitter.AnimState:IsCurrentAnimation("sit_loop_pre") then
				_PlayAnimation(inst, "rocking_pst")
				_PushAnimation(inst, "idle", false)
			elseif inst.AnimState:IsCurrentAnimation("rocking_loop") or inst.AnimState:IsCurrentAnimation("rocking_pre") then
				_PlayAnimation(inst, "idle")
			end
			if sitter ~= inst._onsitteranimover_sitter then
				CancelSitterAnimOver(inst)
				inst._onsitteranimover = function(sitter) OnSyncChairRocking(inst, sitter) end
				inst._onsitteranimover_sitter = sitter
				inst:ListenForEvent("animover", inst._onsitteranimover, sitter)
			end
		end
	end
end

local function OnBecomeSittable(inst)
	if inst.AnimState:IsCurrentAnimation("rocking_loop") then
		_PlayAnimation(inst, "rocking_pst")
		_PushAnimation(inst, "idle", false)
	elseif inst.AnimState:IsCurrentAnimation("rocking_pre") then
		_PlayAnimation(inst, "idle")
	end
	CancelSitterAnimOver(inst)
end

local function OnChairBurnt(inst)
	DefaultBurntStructureFn(inst)

	if inst.back and inst.back:IsValid() then
		inst.back:Remove()
    inst.back = nil
	end
  if inst.side and inst.side:IsValid() then
		inst.side:Remove()
    inst.side = nil
	end

	inst:RemoveComponent("sittable")
  
  if inst.burn_build then
    inst.AnimState:SetBuild(tostring(inst.prefab).."_burnt_build")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Show("back_over")
  end
end

local function OnSave(inst, data)
	local burnable = inst.components.burnable
	if (burnable and burnable:IsBurning()) or inst:HasTag("burnt") then
		data.burnt = true
	end
end

local function OnLoad(inst, data)
	if data then
		if data.burnt then
			inst.components.burnable.onburnt(inst)
		end
	end
end

local function AddChair(ret, name, bank, build, facings, hasback, hasside, deploy_smart_radius, burnable, burn_build, isrocking)
	local assets =
	{
		Asset("ANIM", "anim/"..build..".zip"),
    Asset("ANIM", "anim/"..bank..".zip"),
	}
  if burnable and burn_build then
    table.insert(assets, Asset("ANIM", "anim/"..name.."_burnt_build.zip"))
  end
  
  local side_assets = 
  {
    Asset("ANIM", "anim/"..name.."_1_build.zip"),
    Asset("ANIM", "anim/"..bank..".zip"),
  }

	local prefabs =
	{
		"collapse_small",
	}
  
  local function OnReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and (parent.prefab == inst.prefab:sub(1, -6)) then
      parent.highlightchildren = parent.highlightchildren or {}
      table.insert(parent.highlightchildren, inst)
    end
  end

	if hasback then
		local function backfn()
			local inst = CreateEntity()

			inst.entity:AddTransform()
			inst.entity:AddAnimState()
			inst.entity:AddNetwork()

			if facings == 0 then
				inst.Transform:SetNoFaced()
			elseif facings == 8 then
				inst.Transform:SetEightFaced()
			else
				inst.Transform:SetFourFaced()
			end

			inst:AddTag("FX")

			inst.AnimState:SetBank(bank)
			inst.AnimState:SetBuild(build)
			inst.AnimState:PlayAnimation("idle")
			inst.AnimState:SetFinalOffset(3)
			inst.AnimState:Hide("parts")

			inst.entity:SetPristine()

			if not TheWorld.ismastersim then
				inst.OnEntityReplicated = OnReplicated
				return inst
			end

			inst.persists = false

			return inst
		end
    
    table.insert(ret, Prefab(name.."_back", backfn, assets))
		table.insert(prefabs, name.."_back")
  end
  
  if hasside then
    local function sidefn()
			local inst = CreateEntity()

			inst.entity:AddTransform()
			inst.entity:AddAnimState()
			inst.entity:AddNetwork()

			if facings == 0 then
				inst.Transform:SetNoFaced()
			elseif facings == 8 then
				inst.Transform:SetEightFaced()
			else
				inst.Transform:SetFourFaced()
			end

			inst:AddTag("FX")

			inst.AnimState:SetBank(bank)
			inst.AnimState:SetBuild(name.."_1_build")
			inst.AnimState:PlayAnimation("idle")
			inst.AnimState:SetFinalOffset(-1)

			inst.entity:SetPristine()

			if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnReplicated
				return inst
			end

			inst.persists = false

			return inst
		end

    table.insert(ret, Prefab(name.."_side", sidefn, side_assets))
		table.insert(prefabs, name.."_side")
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(deploy_smart_radius)

		MakeObstaclePhysics(inst, 0.25)

		if facings == 0 then
			inst.Transform:SetNoFaced()
		elseif facings == 8 then
			inst.Transform:SetEightFaced()
		else
			inst.Transform:SetFourFaced()
		end
    
    inst:AddTag("structure")
    if isrocking then
			inst:AddTag("limited_chair")
			inst:AddTag("rocking_chair")
		else
			inst:AddTag("faced_chair")
			inst:AddTag("rotatableobject")
		end
    
		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation("idle")
		inst.AnimState:SetFinalOffset(-1)
		inst.AnimState:Hide("back_over")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		--inst._burnable = burnable

		if hasback then
			inst.back = SpawnPrefab(name.."_back")
			inst.back.entity:SetParent(inst.entity)
			inst.highlightchildren = inst.highlightchildren or {}
      table.insert(inst.highlightchildren, inst.back)
		end
    
    if hasside then
      inst.side = SpawnPrefab(name.."_side")
      inst.side.entity:SetParent(inst.entity)
      inst.highlightchildren = inst.highlightchildren or {}
      table.insert(inst.highlightchildren, inst.side)
    end

		--inst.scrapbook_facing  = FACING_DOWN

		inst:AddComponent("inspectable")
    
		inst:AddComponent("lootdropper")

		inst:AddComponent("sittable")

		inst:AddComponent("savedrotation")
		inst.components.savedrotation.dodelayedpostpassapply = true

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnWorkCallback(OnHit)
		inst.components.workable:SetOnFinishCallback(OnHammered)

		inst:ListenForEvent("onbuilt", OnBuilt)
    
    if isrocking then
			inst:ListenForEvent("ms_sync_chair_rocking", OnSyncChairRocking)
			inst:ListenForEvent("becomesittable", OnBecomeSittable)
		end

		MakeHauntableWork(inst)

		if burnable then
      inst.burn_build = burn_build
      local burnable = inst:AddComponent("burnable")
      burnable:SetFXLevel(2)
      burnable:SetBurnTime(30)
      burnable:AddBurnFX("fire", Vector3(0, 0, 0), nil)
      inst.components.burnable:SetOnBurntFn(OnChairBurnt)
      
      MakeSmallPropagator(inst)
		end

		inst.OnLoad = OnLoad
		inst.OnSave = OnSave

		return inst
	end

	table.insert(ret, Prefab(name, fn, assets, prefabs))
	table.insert(ret, MakePlacer(name.."_placer", bank, build, "idle", nil, nil, nil, nil, 15, "four"))
end

local ret = {}

--       ret,     name,      bank,              build,             facings  hasback, hasside,  deploy_smart_radius, burnable, burn_build, isrocking
AddChair(ret, "jx_sofa_1",  "jx_sofa_1_bank",  "jx_sofa_1_build",   4,      true,    true,     0.875,               true,      true,      false )
AddChair(ret, "jx_sofa_2",  "jx_sofa_2_bank",  "jx_sofa_2_build",	  4,      true,    false,    0.875,               true,      true,      false )
AddChair(ret, "jx_sofa_3",  "jx_sofa_3_bank",  "jx_sofa_3_build",	  4,      true,    true,     0.875,               true,      true,      false )
AddChair(ret, "jx_chair_1", "jx_chair_1_bank", "jx_chair_1_build",  4,      false,   false,    0.875,               false,     false,     false )
AddChair(ret, "jx_chair_2", "jx_chair_2_bank", "jx_chair_2_build",  4,      false,   false,    0.875,               false,     false,     false )
AddChair(ret, "jx_chair_3", "jx_chair_3_bank", "jx_chair_3_build",  0,      true,    false,    1,                   true,      false,     true )

return unpack(ret)
