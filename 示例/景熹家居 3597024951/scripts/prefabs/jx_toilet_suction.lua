local assets =
{
    Asset("ANIM", "anim/jx_toilet_suction.zip"),
    Asset("ANIM", "anim/swap_jx_toilet_suction.zip"),
}

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_jx_toilet_suction", "swap_jx_toilet_suction")
  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")
  owner.jx_toilet_suction_task = owner:DoPeriodicTask(1,function()
    local x, y, z = owner.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4, {"jx_rug"})
    for k, v in pairs(ents) do
      if v:HasTag("NOCLICK") then
        v:RemoveTag("NOCLICK")
        if v.NOCLICK_Tag_Task then
          v.NOCLICK_Tag_Task:Cancel()
          v.NOCLICK_Tag_Task = nil
        end
        v.NOCLICK_Tag_Task = v:DoTaskInTime(v.NOCLICK_Tag_Task_Time,function() v:AddTag("NOCLICK") end)
      end
    end
  end, 0)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if owner.jx_toilet_suction_task then
      owner.jx_toilet_suction_task:Cancel()
      owner.jx_toilet_suction_task = nil
    end
end

local function common_fn(bank, build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("jx_toilet_suction")

    MakeInventoryFloatable(inst, "med", 0.05, {0.78, 0.4, 0.78}, true, 7, {sym_build = "swap_jx_toilet_suction"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.PITCHFORK_USES)
    inst.components.finiteuses:SetUses(TUNING.PITCHFORK_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.JX_RUG_DIG, .125)
    -------

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.PITCHFORK_DAMAGE)

    inst:AddInherentAction(ACTIONS.JX_RUG_DIG)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("jx_rug_dig")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function normal()
    return common_fn("jx_toilet_suction", "jx_toilet_suction")
end

return Prefab("jx_toilet_suction", normal, assets)
