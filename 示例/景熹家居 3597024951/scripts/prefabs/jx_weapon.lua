local ret = {}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_"..inst.prefab, "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function MakeWeapon(prefab_name, damage, uses)
  local assets =
  {
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_"..prefab_name..".zip"),
  }

  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("swap_"..prefab_name)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(damage)

    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(uses)
    inst.components.finiteuses:SetUses(uses)

    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
  end
  
  table.insert(ret, Prefab(prefab_name, fn, assets))
end
--         name,          damage, uses,
MakeWeapon("jx_weapon_1", 50,     150)
MakeWeapon("jx_weapon_2", 50,     150)
MakeWeapon("jx_weapon_3", 50,     150)
MakeWeapon("jx_weapon_4", 40,     150)

return unpack(ret)