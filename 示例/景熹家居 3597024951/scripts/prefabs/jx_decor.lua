--装饰位点
local assets = 
{
  Asset("ANIM", "anim/jx_decor.zip"),
}

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()
  
  inst.AnimState:SetBank("jx_decor")
  inst.AnimState:SetBuild("jx_decor")
  inst.AnimState:PlayAnimation("idle", true)
    
  inst:AddTag("NOCLICK")

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end
  
  inst.persists = false
  
  return inst
end

return Prefab("jx_decor", fn, assets)