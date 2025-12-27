--驯猫糕手：平底锅的代码是本人另一个模组搬运来的，自产自销
local assets =
{
    Asset("ANIM", "anim/jx_pan.zip"),
    Asset("ANIM", "anim/swap_jx_pan.zip"),
    
    Asset("SOUND","sound/fire_machete.fsb"),
    Asset("SOUNDPACKAGE","sound/fire_machete.fev"),
}

--[[local prefab = 
{
  "halloween_firepuff_1",
  "halloween_firepuff_2",
  "halloween_firepuff_3",
  "firering_fx",
  "firesplash_fx",
}]]

local AtkTags = 
{
	{name = "jx_pan_lunge"}, --快划
	--{name = "fire_machete_hop"}, --跳劈
	--{name = "fire_machete_multithrust"}, --连刺
  {name = "jx_pan_chop"}, --挥砍
	--{name = "jx_pan_none"},
}

local function AddRandomAtkTag(inst)
	for _,v in pairs(AtkTags) do
    if inst:HasTag(v.name) then
      inst:RemoveTag(v.name)
    end
	end
  
  local rnd = math.random()
  if rnd < .8 then
    return
  else
    local tag = AtkTags[math.random(1, #AtkTags)].name
    inst:AddTag(tag)
  end
end

local function onequip(inst, owner)
  local anim_state = owner.AnimState
	anim_state:Show("ARM_carry")
	anim_state:Hide("ARM_normal")
  anim_state:OverrideSymbol("swap_object", "swap_jx_pan", "swap_fire_machete")
  
  --[[local tem = inst.components.temperature:GetCurrent()
  if tem < 25 then
    if inst.ChangeSymbol then
      inst.ChangeSymbol = "normal"
    end
    anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete")
  elseif tem >= 25 and tem < 35 then
    if inst.ChangeSymbol ~= "yellow" then
      inst.ChangeSymbol = "yellow"
    end
    anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_yellow")
  elseif tem >= 35 and tem < 45 then
    if inst.ChangeSymbol ~= "orange" then
      inst.ChangeSymbol = "orange"
    end
    anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_orange")
  elseif tem >= 45 then
    if inst.ChangeSymbol ~= "red" then
      inst.ChangeSymbol = "red"
    end
    anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_red")
  end
  
  if inst.components.rechargeable then
    inst.components.rechargeable:Discharge(7)
  end]]
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

--[[local function ontemperaturedelta(inst,data)
  local new=data.new
  local isequipped = inst.components.equippable and inst.components.equippable:IsEquipped()
  local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or nil
  local anim_state = owner ~= nil and owner.AnimState or nil
  
  if new < 25 then
    if inst.ChangeSymbol ~= "normal" then
      inst.ChangeSymbol = "normal"
      if isequipped and anim_state then
        anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete")
      end
    end
  elseif new >= 25 and new < 35 then
    if inst.ChangeSymbol ~= "yellow" then
      inst.ChangeSymbol = "yellow"
      if isequipped and anim_state then
        anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_yellow")
      end
    end
  elseif new >= 35 and new < 45 then
    if inst.ChangeSymbol ~= "orange" then
      inst.ChangeSymbol = "orange"
      if isequipped and anim_state then
        anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_orange")
      end
    end
  elseif new >= 45 then
    if inst.ChangeSymbol ~= "red" then
      inst.ChangeSymbol = "red"
      if isequipped and anim_state then
        anim_state:OverrideSymbol("swap_object", "swap_fire_machete", "swap_fire_machete_red")
      end
    end
    
    if new >= 55 then
      if inst.components.finiteuses:GetPercent() < 1 then
        inst.components.finiteuses:Repair(0.033)
        
        if inst:HasTag("onfinished_moyu") then
          inst.components.weapon:SetDamage(51)
          inst:RemoveTag("onfinished_moyu")
        end
      end
    end
    
  end
end]]

local function onattack(inst, attacker, target)
  --[[if not inst.components.timer:TimerExists("onattack_fx_cd") then
    inst.components.timer:StartTimer("onattack_fx_cd", 0.3)
    
    local px, py, pz = attacker.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local fx_x = (px + tx) / 2
    local fx_z = (pz + tz) / 2
    local rnd_1 = math.random(-50, 50)*0.01
    local rnd_2 = math.random()
    local fx = SpawnPrefab(prefab[math.random(1, 3)])
    fx.Transform:SetPosition(fx_x + rnd_1, rnd_2, fx_z + rnd_1)
  end
  
  local tem = inst.components.temperature:GetCurrent()
  if tem < 54 then
    inst.components.temperature:SetTemperature(tem + 0.7)
  end
  
  if not target.components.health then return end
  local symbol = inst.ChangeSymbol
  if symbol == "normal" then
    return
  elseif symbol == "yellow" then
    target.components.health:DoFireDamage(5, attacker, true)
  elseif symbol == "orange" then
    target.components.health:DoFireDamage(12, attacker, true)
  elseif symbol == "red" then
    target.components.health:DoFireDamage(20, attacker, true)
  end]]
  
  AddRandomAtkTag(inst)
end

--[[local function onfinished(inst)
  if inst.components.weapon then
    inst.components.weapon:SetDamage(17)
    inst:AddTag("onfinished_moyu")
  end
end]]

--[[local function HarvestPickable(inst, ent, doer)
  if ent.components.pickable.picksound ~= nil then
    doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
  end

  local success, loot = ent.components.pickable:Pick(TheWorld)
  
  if loot ~= nil then
    for i, item in ipairs(loot) do
      Launch(item, doer, 1.5)
    end
  end
end]]

--[[local function IsEntityInFront(inst, entity, doer_rotation, doer_pos)
  local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

  return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
end]]

--[[local HARVEST_MUSTTAGS  = {"pickable"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local function DoScythe(inst, target, doer)
  if target.components.pickable ~= nil then
    local doer_pos = doer:GetPosition()
    local x, y, z = doer_pos:Get()

    local doer_rotation = doer.Transform:GetRotation()

    local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
    for _, ent in pairs(ents) do
      if ent:IsValid() and ent.components.pickable ~= nil then
        if inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
          inst:HarvestPickable(ent, doer)
        end
      end
    end
  end
end]]

--[[local CREATURES_MUST = { "_combat", "_health" }
local CREATURES_CANT = { "INLIMBO", "companion", "wall", "abigail", "shadowminion", "player", "playerghost", "invisible" }
    
local function SpawnFx(inst, attacker, target)
  if target then
    local x, y, z = target.Transform:GetWorldPosition()
    
    local ring = SpawnPrefab("firering_fx")
    ring.Transform:SetPosition(x, y, z)
    ring.Transform:SetScale(0.8, 0.8, 0.8)
    
    local bird = SpawnPrefab("moyu_fire_fx_3")
    bird.Transform:SetPosition(x, y, z)
    bird.Transform:SetScale(1.2, 1.2, 1.2)

    local theta = math.random(TWOPI)
    for i=1,6 do
        local radius = 4
        local newtheta = theta  + (PI/3*i)
        local new_x = radius * math.cos( newtheta ) + x
        local new_z = -radius * math.sin( newtheta ) + z
        local puff = SpawnPrefab("firesplash_fx")
        puff.Transform:SetPosition(new_x, 0, new_z)
    end
        
    local ents = TheSim:FindEntities(x, 0, z, 8, CREATURES_MUST, CREATURES_CANT)
    for i, v in ipairs(ents) do
      if v.components.health and not v.components.health:IsDead() and v.components.combat then
        v.components.combat:GetAttacked(attacker, 102 + v.components.health.maxhealth * 0.0015)    
      end
    end
  end
end]]

--[[local function ReticuleTargetFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  for r = 7, 0, -.25 do
    pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
    if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
      return pos
    end
  end
  return pos
end]]

--[[local function OnLeap(inst, doer, startingpos, targetpos)
  local ring = SpawnPrefab("firering_fx")
  ring.Transform:SetPosition(targetpos.x, targetpos.y, targetpos.z)
  ring.Transform:SetScale(0.8, 0.8, 0.8)
  
  local bird = SpawnPrefab("moyu_fire_fx_3")
  bird.Transform:SetPosition(targetpos.x, targetpos.y, targetpos.z)
  bird.Transform:SetScale(1.2, 1.2, 1.2)
  
  local theta = math.random(TWOPI)
  for i=1,6 do
    local radius = 4
    local newtheta = theta  + (PI/3*i)
    local new_x = radius * math.cos( newtheta ) + targetpos.x
    local new_z = -radius * math.sin( newtheta ) + targetpos.z
    local puff = SpawnPrefab("firesplash_fx")
    puff.Transform:SetPosition(new_x, 0, new_z)
    puff.Transform:SetScale(0.8, 0.8, 0.8)
  end
        
  local ents = TheSim:FindEntities(targetpos.x, 0, targetpos.z, 8, CREATURES_MUST, CREATURES_CANT)
  for _, ent in ipairs(ents) do
    if ent:IsValid() and ent ~= doer and ent.components.health and not ent.components.health:IsDead() then
      if ent.components.combat then
        ent.components.combat:GetAttacked(doer, 41 + ent.components.health.maxhealth * 0.007)
        inst.components.finiteuses:Use(1)
      end
    end
  end
end]]

--[[local function SpellFn(inst, doer, pos)
  inst.components.rechargeable:Discharge(7)
  doer:PushEvent("combat_leap", {targetpos = pos, weapon = inst})
end]]

local function fn()
	local inst = CreateEntity()
  
	inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()
  
  inst.AnimState:SetBank("jx_pan")
	inst.AnimState:SetBuild("jx_pan")
	inst.AnimState:PlayAnimation("idle")
    
  inst:AddTag("weapon")
  inst:AddTag("jx_pan")
  inst:AddTag("sharp")
  --inst:AddTag("fire_machete_aoeweapon_leap")
  --inst:AddTag("rechargeable")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", nil, 0.75)
  
  inst.entity:SetPristine()
  
  --[[inst:AddComponent("aoetargeting")
	inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
	inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting:SetRange(12)
  inst.components.aoetargeting.allowriding = false]]
  
  if not TheWorld.ismastersim then
    return inst
  end
      
  inst:AddComponent("inventoryitem")
  -----
  inst:AddComponent("equippable")
  inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
  --inst.components.equippable.walkspeedmult = 1.1
  ------
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(38)
  inst.components.weapon:SetOnAttack(onattack)
	-----
	--[[inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.SCYTHE)
  inst.components.tool:SetAction(ACTIONS.CHOP)]]
	-------
  --[[inst:AddComponent("temperature")
  inst.components.temperature.current = TheWorld.state.temperature
  inst.components.temperature.mintemp= 0]]
  ------
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(150)
	inst.components.finiteuses:SetUses(150)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	inst.components.finiteuses:SetConsumption(ACTIONS.SCYTHE, 1)
  inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
	-------
  --[[inst:AddComponent("waterproofer")
  inst.components.waterproofer:SetEffectiveness(1)]]
  --------
	inst:AddComponent("inspectable")
  -------
  --[[inst:AddComponent("aoeweapon_leap")
  inst.components.aoeweapon_leap:SetWorkActions()
  inst.components.aoeweapon_leap:SetOnLeaptFn(OnLeap)]]
  -----
  --[[inst:AddComponent("aoespell")
  inst.components.aoespell:SetSpellFn(SpellFn)]]
  ---
  --inst:AddComponent("rechargeable")
  ---
  --inst:AddComponent("timer")
  
  --inst:ListenForEvent("temperaturedelta",ontemperaturedelta)

	MakeHauntableLaunch(inst)
  
  --inst.DoScythe = DoScythe
  --inst.IsEntityInFront = IsEntityInFront
  --inst.HarvestPickable = HarvestPickable
  --inst.SpawnFx = SpawnFx
  --inst.ChangeSymbol = "normal"

	return inst
end

return Prefab("jx_pan", fn, assets)