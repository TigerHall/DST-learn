require("prefabutil")

local assets =
{
	Asset("ANIM", "anim/jx_rug.zip"),
}

local prefabs = 
{
}

local ret = {}

local function onworkfinished(inst)
  if inst.components.lootdropper then
    inst.components.lootdropper:DropLoot()
  end
  local item = SpawnPrefab(tostring(inst.prefab).."_item")
  if item then
    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    if item.components.inventoryitem then
      item.components.inventoryitem:OnDropped(true)
    end
  end
  inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    if deployer then
      deployer.SoundEmitter:PlaySound("aqol/new_test/cloth")
    end
    local rug_string, count = string.gsub(tostring(inst.prefab), "_item$", "")
    local rug = SpawnPrefab(rug_string)
    if rug then
      rug.Transform:SetPosition(pt.x, 0, pt.z)
      --rug.Transform:SetRotation(deployer and deployer.Transform:GetRotation() or 0)
      rug.Transform:SetRotation(0)
      
      if rug:HasTag("rotatableobject") 
        and deployer and deployer.components.inventory 
        and deployer.components.inventory:EquipHasTag("fence_rotator") 
      then
        rug:RemoveTag("NOCLICK")
        if rug.NOCLICK_Tag_Task then
          rug.NOCLICK_Tag_Task:Cancel()
          rug.NOCLICK_Tag_Task = nil
        end
        rug.NOCLICK_Tag_Task = rug:DoTaskInTime(rug.NOCLICK_Tag_Task_Time,function() rug:AddTag("NOCLICK") end)
      end
    end
    inst:Remove()
end

local function onsave(inst, data)
  data.rotation = inst.Transform:GetRotation()
end	

local function onload(inst, data)
  if data and data.rotation then
    inst.Transform:SetRotation(data.rotation)
  end
end

local function MakeRug(name, scale_x, scale_y, scale_z, rotatable, rotatable_angle, placer_scale)
  local function fn()
  	local inst = CreateEntity()
  
	  inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBuild("jx_rug")
    inst.AnimState:SetBank("jx_rug")
    inst.AnimState:PlayAnimation(name)
	  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	  inst.AnimState:SetLayer(LAYER_BACKGROUND)
	  inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(scale_x, scale_y, scale_z)

    inst:AddTag("jx_rug")
	  inst:AddTag("NOCLICK")
  	inst:AddTag("NOBLOCK")
    if rotatable then
      inst:AddTag("rotatableobject")
    end
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.JX_RUG_DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworkfinished)
    
    if rotatable then
      inst.rotatable_angle = rotatable_angle
    end
    inst.NOCLICK_Tag_Task_Time = 5
    
  	inst.OnSave = onsave 
    inst.OnLoad = onload
    
    inst.Transform:SetRotation(0)

	  return inst
  end
  
  local function item_fn()
  	local inst = CreateEntity()
  
	  inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    
    MakeInventoryPhysics(inst)
    
    inst:AddTag("jx_rug_item")

    inst.AnimState:SetBuild("jx_rug")
    inst.AnimState:SetBank("jx_rug_item")
    inst.AnimState:PlayAnimation(name.."_item")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM
    
    MakeHauntableLaunch(inst)
    
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)

	  return inst
  end
  
  table.insert(ret, Prefab(name, fn, assets, prefabs))
  table.insert(ret, Prefab(name.."_item", item_fn, assets, prefabs))
  table.insert(ret, MakePlacer(name.."_item_placer", "jx_rug", "jx_rug", name, true, nil, nil, placer_scale))
end

--       name,               scale_x, scale_y, scale_z, rotatable,  rotatable_angle,   placer_scale
MakeRug("jx_rug_oval",       1.3,     1.3,     1.3,     false,         nil,             1.1       )--椭圆形地毯
MakeRug("jx_rug_forest",     1.31,    1.34,    1.3,     false,         nil,             1.13      )--森林之歌方形地毯
MakeRug("jx_rug_aubusson",   1.31,    1.34,    1.3,     false,         nil,             1.13      )--奥布松丝绸挂毯
MakeRug("jx_rug_tradition",  1.31,    1.34,    1.3,     false,         nil,             1.13      )--传统平织方格地毯
MakeRug("jx_rug_savannah",   1.31,    1.34,    1.3,     true,          90,              1.13      )--萨瓦纳瑞手工地毯
MakeRug("jx_rug_triangle",   1.44,    1.44,    1.44,    true,          180,             1.15      )--印第安图腾三角毯

return unpack(ret)