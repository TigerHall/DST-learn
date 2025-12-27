local function AbleToAcceptDecor(inst, item, giver)
    return (item ~= nil)
end

local function OnDecorGiven(inst, item, giver)
    if not item then return end

    inst.SoundEmitter:PlaySound("wintersfeast2019/winters_feast/table/food")

    if item.Physics then item.Physics:SetActive(false) end
    if item.Follower then item.Follower:FollowSymbol(inst.GUID, "swap_object") end
end

local function OnDecorTaken(inst, item)
    if item then
        if item.Physics then item.Physics:SetActive(true) end
        if item.Follower then item.Follower:StopFollowing() end
    end
end

--
local function TossDecorItem(inst)
    local item = inst.components.furnituredecortaker and inst.components.furnituredecortaker:TakeItem()
    if item then
        inst.components.lootdropper:FlingItem(item)
    end
end

local function OnHammer(inst, worker, workleft, workcount)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function OnHammered(inst, worker)
    local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial(inst._burnable and "wood" or "stone")

    inst.components.lootdropper:DropLoot()

    TossDecorItem(inst)

    inst:Remove()
end

--
local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)

    inst.SoundEmitter:PlaySound("dontstarve/common/repair_stonefurniture")
end

--
local function on_ignite(inst, source, doer)
    inst._controlled_burn = doer and doer:HasTag("controlled_burner") or source and source:HasTag("controlled_burner") or nil
    DefaultBurnFn(inst)
end

local function on_extinguish(inst)
    inst._controlled_burn = nil
    DefaultExtinguishFn(inst)
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    
    local item = inst.components.furnituredecortaker and inst.components.furnituredecortaker:TakeItem()
    if item then
        inst.components.lootdropper:FlingItem(item)
        if not inst._controlled_burn and item.components.burnable ~= nil then
            item.components.burnable:Ignite()
        end
    end
    if inst.components.furnituredecortaker then
      inst.components.furnituredecortaker:SetEnabled(false)
    end
    if inst.components.timer then
      inst.components.timer:StopTimer("complain_time")
    end
    if inst.burnt_build then
      inst.AnimState:SetBuild(inst.prefab.."_burnt_build")
      inst.AnimState:PlayAnimation("idle")
    end
end

local function onnear(inst, target)
  if inst:HasTag("burnt") or (inst.components.timer and inst.components.timer:TimerExists("complain_time")) then
    return
  end
  if target ~= nil then
    if target.components.health and not target.components.health:IsDead() and target.components.talker ~= nil then
      target.components.talker:Say(STRINGS.JX_TABLE_5_QUESTION)
      if inst.components.timer then
        inst.components.timer:StartTimer("complain_time", inst.talk_Period or 480)
      end
      inst:DoTaskInTime(1.5,function()
        if inst.components.talker then
          inst.components.talker:Say(STRINGS.JX_TABLE_5_ANSWER)
        end
      end)
    end
	end
end

--
local function OnSave(inst, data)
    if (inst.components.burnable and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
        data.burnt = true
    end
    data.controlled_burn = inst._controlled_burn
end

local function OnLoad(inst, data)
    if data then
        inst._controlled_burn = data.controlled_burn
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data and data.burnt then
        inst:PushEvent("onburnt")
        inst.components.burnable.onburnt(inst)
    end
end
--
local function AddTable(results, prefab_name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..data.bank..".zip"),
        Asset("ANIM", "anim/"..data.build..".zip"),
    }
    if data.burnt_build then
      table.insert(assets, Asset("ANIM", "anim/"..prefab_name.."_burnt_build.zip"))
    end

    local prefabs =
    {
        "collapse_small",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(data.deploy_smart_radius)

        MakeObstaclePhysics(inst, 0.6)

        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(-1)

    if data.facings == 0 then
			inst.Transform:SetNoFaced()
		elseif data.facings == 8 then
			inst.Transform:SetEightFaced()
		else
			inst.Transform:SetFourFaced()
		end
    
        if data.decortable then
          inst:AddTag("decortable")
        end
        inst:AddTag("structure")

        inst.entity:SetPristine()
        
        if data.talker then
          inst:AddComponent("talker")
          inst.components.talker.fontsize = 35
          inst.components.talker.font = TALKINGFONT
          inst.components.talker.colour = Vector3(143/255, 41/255, 41/255)
          inst.components.talker.offset = Vector3(0, -400, 0)
          inst.components.talker:MakeChatter()
          inst:AddComponent("npc_talker")
          inst.talk_Period = 480
        end

        if not TheWorld.ismastersim then
            return inst
        end

        inst._burnable = data.burnable

        --
        if data.decortable then
          local furnituredecortaker = inst:AddComponent("furnituredecortaker")
          furnituredecortaker.abletoaccepttest = AbleToAcceptDecor
          furnituredecortaker.ondecorgiven = OnDecorGiven
          furnituredecortaker.ondecortaken = OnDecorTaken
        end

        --
        local inspectable = inst:AddComponent("inspectable")
        --
        inst:AddComponent("lootdropper")

        --
        local savedrotation = inst:AddComponent("savedrotation")
        savedrotation.dodelayedpostpassapply = true

        --
        local workable = inst:AddComponent("workable")
        workable:SetWorkAction(ACTIONS.HAMMER)
        workable:SetWorkLeft(5)
        workable:SetOnWorkCallback(OnHammer)
        workable:SetOnFinishCallback(OnHammered)
        
        if data.talker then
          inst:AddComponent("timer")
          if not inst.components.timer:TimerExists("complain_time") then
            inst.components.timer:StartTimer("complain_time", 4)
          end
        
          inst:AddComponent("playerprox")
          inst.components.playerprox:SetDist(3, 5)
          inst.components.playerprox:SetOnPlayerNear(onnear)
        end

        MakeHauntableWork(inst)
        
        if data.decortable then
          inst:ListenForEvent("ondeconstructstructure", TossDecorItem)
        end
        inst:ListenForEvent("onbuilt", OnBuilt)

        if data.burnable then
            MakeMediumBurnable(inst, nil, nil, true)
            inst.components.burnable:SetOnIgniteFn(on_ignite)
            inst.components.burnable:SetOnExtinguishFn(on_extinguish)
            inst.components.burnable:SetOnBurntFn(OnBurnt)
            MakeMediumPropagator(inst)

            --inst:ListenForEvent("onburnt", OnBurnt)
        end
        if data.burnt_build then
          inst.burnt_build = true
        end

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnLoadPostPass = OnLoadPostPass

        return inst
    end

    table.insert(results, Prefab(prefab_name, fn, assets, prefabs))
    table.insert(results, MakePlacer(prefab_name.."_placer", data.bank, data.build, "idle", nil, nil, nil, nil, data.fixedcameraoffset, "four"))
end

local result_tables = {}

AddTable(
    result_tables,
    "jx_table",
    {
        bank = "jx_table",
        build = "jx_table",
		    facings = 0,
        deploy_smart_radius = 0.875,
        burnable = true,
        burnt_build = false,
        decortable = true,
        fixedcameraoffset = 105,
        talker = false,
    }
)
AddTable(
    result_tables,
    "jx_table_3",
    {
        bank = "jx_table_3",
        build = "jx_table_3",
		    facings = 4,
        deploy_smart_radius = 0.875,
        burnable = true,
        burnt_build = false,
        decortable = true,
        fixedcameraoffset = 105,
        talker = false,
    }
)
AddTable(
    result_tables,
    "jx_table_4",
    {
        bank = "jx_table_4",
        build = "jx_table_4",
		    facings = 0,
        deploy_smart_radius = 0.875,
        burnable = true,
        burnt_build = false,
        decortable = true,
        fixedcameraoffset = 105,
        talker = false,
    }
)

AddTable(
    result_tables,
    "jx_table_5",
    {
        bank = "jx_table_5",
        build = "jx_table_5",
		    facings = 4,
        deploy_smart_radius = 0.875,
        burnable = true,
        burnt_build = true,
        decortable = false,
        fixedcameraoffset = 15,
        talker = true,
    }
)

return unpack(result_tables)