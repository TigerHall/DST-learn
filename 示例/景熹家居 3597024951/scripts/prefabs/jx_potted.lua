local prefs = {}

local function onhammered(inst)
  local fx = SpawnPrefab("collapse_small")
  fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
  fx:SetMaterial("pot")
  inst.components.lootdropper:DropLoot()
  inst:Remove()
end

local function onbuilt(inst)
  inst.AnimState:PlayAnimation("place")
  inst.AnimState:PushAnimation("idle", false)
  inst.SoundEmitter:PlaySound("dontstarve/common/together/succulent_craft")
end

local function GetDescription(inst)
  local now_time = GetTime()
  local last_time = inst.last_inspect_time
  inst.last_inspect_time = now_time
  local desc_list = 
  {
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.JX_XUNCAT,
    STRINGS.JX_XUNCAT_CHECK,
  }
  if last_time == nil or now_time - last_time > 30 then
    return desc_list[1]
  else
    return desc_list[2]
  end
end

local function MakePotted(name)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:SetDeploySmartRadius(0.45)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("cavedweller")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        if name == "jx_xuncat" then
          inst.components.inspectable.descriptionfn = GetDescription
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableWork(inst)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)

        inst:AddComponent("lootdropper")

        MakeHauntableWork(inst)

        inst:ListenForEvent("onbuilt", onbuilt)

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
    table.insert(prefs, MakePlacer(name.. "_placer", name, name, "idle"))
end

MakePotted("jx_potted")            --巴西木
MakePotted("jx_potted_sunflower")  --向日葵
MakePotted("jx_potted_cherry")     --酢浆草
MakePotted("jx_potted_rose")       --白玫瑰
MakePotted("jx_potted_cactus")     --仙人球
MakePotted("jx_potted_anthurium")  --红掌
MakePotted("jx_potted_narcissus")  --水仙花
MakePotted("jx_potted_snakeplant") --虎皮兰
MakePotted("jx_xuncat") --橘猫
MakePotted("jx_red_rose_potted") --红玫瑰
MakePotted("jx_green_palm") --绿豆瓣
MakePotted("jx_potted_gardenia") --栀子花
MakePotted("jx_potted_monstera") --龟背竹

return unpack(prefs)
