local ret = {}

local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_hat", inst.prefab, "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    if owner.isplayer then
      owner.AnimState:Hide("HEAD")
      owner.AnimState:Show("HEAD_HAT")
			owner.AnimState:Show("HEAD_HAT_NOHELM")
			owner.AnimState:Hide("HEAD_HAT_HELM")
    end
    
    if inst.components.fueled ~= nil then
			inst.components.fueled:StartConsuming()
		end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("headbase_hat")    
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    if owner.isplayer then
      owner.AnimState:Show("HEAD")
      owner.AnimState:Hide("HEAD_HAT")
			owner.AnimState:Hide("HEAD_HAT_NOHELM")
			owner.AnimState:Hide("HEAD_HAT_HELM")
    end
    
    if inst.components.fueled ~= nil then
      inst.components.fueled:StopConsuming()
    end
end

local function onequiptomodel(inst, owner)
    if inst.components.fueled ~= nil then
      inst.components.fueled:StopConsuming()
    end
end

local function ontakedamage_iron_pan(inst, damage_amount)
  local owner = inst.components.inventoryitem:GetGrandOwner()
  if owner and owner.SoundEmitter then
    owner.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  end
end

local function MakeHat(prefab_name, tradable, armor_amount, armor_absorb_percent, waterproofer_percent, insulator_percent, fueled_maxfuel, fuel_fuelvalue)
  local assets =
  {
    Asset("ANIM", "anim/"..prefab_name..".zip"),
  }
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_name)
    inst.AnimState:SetBuild(prefab_name)
    inst.AnimState:PlayAnimation("anim")
    
    inst:AddTag("hat")
    
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    
    if tradable then
      inst:AddComponent("tradable")
    end
    
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    
    if armor_amount then
      inst:AddComponent("armor")
      inst.components.armor:InitCondition(armor_amount, armor_absorb_percent)
      if prefab_name == "jx_hat_iron_pan" then
        inst.components.armor.ontakedamage = ontakedamage_iron_pan
      end
    end
    
    if waterproofer_percent then
      inst:AddComponent("waterproofer")
      inst.components.waterproofer:SetEffectiveness(waterproofer_percent)
    end
    
    local _insulator_percent = insulator_percent
    if _insulator_percent then
      inst:AddComponent("insulator")
      if _insulator_percent < 0 then
        _insulator_percent = - _insulator_percent
        inst.components.insulator:SetSummer()
      end
      inst.components.insulator:SetInsulation(_insulator_percent)
    end
    
    if fueled_maxfuel then
      inst:AddComponent("fueled")
      inst.components.fueled.fueltype = FUELTYPE.USAGE
      inst.components.fueled:InitializeFuelLevel(fueled_maxfuel)
      inst.components.fueled:SetDepletedFn(inst.Remove)
    end
    
    if fuel_fuelvalue then
      inst:AddComponent("fuel")
      inst.components.fuel.fuelvalue = fuel_fuelvalue
    end

    MakeHauntableLaunch(inst)

    return inst
  end
  table.insert(ret, Prefab(prefab_name, fn, assets))
end

--       prefab_name,        tradable, armor_amount,              armor_absorb_percent,                  waterproofer_percent,              insulator_percent,       fueled_maxfuel,             fuel_fuelvalue      
MakeHat("jx_hat_iron_pan",   true,     TUNING.ARMOR_FOOTBALLHAT,  TUNING.ARMOR_FOOTBALLHAT_ABSORPTION,   TUNING.WATERPROOFNESS_MED,         nil,                     nil,                        nil)
MakeHat("jx_hat_white_rose", true,     TUNING.ARMOR_FOOTBALLHAT,  TUNING.ARMOR_FOOTBALLHAT_ABSORPTION,   3/2 * TUNING.WATERPROOFNESS_SMALL, TUNING.INSULATION_SMALL, nil,                        nil)
MakeHat("jx_hat_sunflower",  true,     nil,                       nil,                                   3/2 * TUNING.WATERPROOFNESS_SMALL, -TUNING.INSULATION_MED,  TUNING.STRAWHAT_PERISHTIME, TUNING.LARGE_FUEL)

return unpack(ret)