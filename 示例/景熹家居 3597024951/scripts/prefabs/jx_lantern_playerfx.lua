local assets = 
{
  Asset("ANIM", "anim/jx_lantern_playerfx.zip"),
}

local function onanimover(inst)
  if inst.fx_parent and inst.fx_parent:IsValid() then
    if inst.fx_parent.components.inventory and inst.fx_parent.components.inventory:EquipHasTag("jx_lantern") then
      --[[local rnd = math.random(1,3)
      local anim = rnd == 1 and "sparks_sml" or rnd == 2 and "sparks_med" or "sparks_lrg"
      inst.AnimState:PlayAnimation(anim)]]
      inst.AnimState:PlayAnimation(math.random() < .7 and "sparks_sml" or "sparks_med")
      return
    end
  end
  inst:Remove()
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()
  
  inst.AnimState:SetBank("jx_lantern_playerfx")
  inst.AnimState:SetBuild("jx_lantern_playerfx")
  inst.AnimState:SetScale(.75, .75, .75)
  
  --[[local rnd = math.random(1,3)
  local anim = rnd == 1 and "sparks_sml" or rnd == 2 and "sparks_med" or "sparks_lrg"
  inst.AnimState:PlayAnimation(anim)]]
  
  inst.AnimState:PlayAnimation(math.random() < .7 and "sparks_sml" or "sparks_med")
    
  inst:AddTag("FX")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:ListenForEvent("animover", onanimover)

  inst.persists = false

  return inst
end

return Prefab("jx_lantern_playerfx", fn, assets)