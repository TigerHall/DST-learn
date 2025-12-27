local assets =
{
    Asset("ANIM", "anim/jx_tent.zip"),
    Asset("ANIM", "anim/jx_tent_snow_build.zip"),
}

local function PlaySleepLoopSoundTask(inst, stopfn)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_sleep")--??这是帐篷睡觉声音的原路径，为什么原版播放这个声音是静音的
end

local function stopsleepsound(inst)
    if inst.sleep_tasks ~= nil then
        for i, v in ipairs(inst.sleep_tasks) do
            v:Cancel()
        end
        inst.sleep_tasks = nil
    end
end

local function startsleepsound(inst, len)
    stopsleepsound(inst)
    inst.sleep_tasks =
    {
        inst:DoPeriodicTask(len, PlaySleepLoopSoundTask, 33 * FRAMES),
        inst:DoPeriodicTask(len, PlaySleepLoopSoundTask, 47 * FRAMES),
    }
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        stopsleepsound(inst)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    end
    if inst.components.sleepingbag ~= nil and inst.components.sleepingbag.sleeper ~= nil then
        inst.components.sleepingbag:DoWakeUp()
    end
end

local function onfinishedsound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_twirl")
end

local function onfinished(inst)
    if not inst:HasTag("burnt") then
        stopsleepsound(inst)
        inst.AnimState:PlayAnimation("destroy")
        inst:ListenForEvent("animover", inst.Remove)
        inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_pre")
        inst.persists = false
        inst:DoTaskInTime(16 * FRAMES, onfinishedsound)
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_craft")
end

local function onignite(inst)
    inst.components.sleepingbag:DoWakeUp()
end

local function onwake(inst, sleeper, nostatechange)
    sleeper:RemoveEventCallback("onignite", onignite, inst)

    inst.AnimState:PushAnimation("idle", true)
    stopsleepsound(inst)

    inst.components.finiteuses:Use()
end

local function onsleep(inst, sleeper)
    sleeper:ListenForEvent("onignite", onignite, inst)

    inst.AnimState:PlayAnimation("enter")
    inst.AnimState:PushAnimation("sleep_loop", true)
    startsleepsound(inst, inst.AnimState:GetCurrentAnimationLength())
end

local function OnSnowCovered(inst, issnowcovered)
  if issnowcovered then
    inst.AnimState:SetBuild("jx_tent_snow_build")
  else
    inst.AnimState:SetBuild("jx_tent")
  end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function temperaturetick(inst, sleeper)
    if sleeper.components.temperature ~= nil then
        if inst.is_cooling then
            if sleeper.components.temperature:GetCurrent() > TUNING.SLEEP_TARGET_TEMP_TENT then
                sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() - TUNING.SLEEP_TEMP_PER_TICK)
            end
        elseif sleeper.components.temperature:GetCurrent() < TUNING.SLEEP_TARGET_TEMP_TENT then
            sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() + TUNING.SLEEP_TEMP_PER_TICK)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	  inst:SetDeploySmartRadius(1.6) --recipe min_spacing/2
    MakeObstaclePhysics(inst, 1)

    inst:AddTag("tent")
    inst:AddTag("structure")

    inst.AnimState:SetBank("jx_tent")
    inst.AnimState:SetBuild("jx_tent")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("jx_tent.tex")

    --MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:WatchWorldState("issnowcovered", OnSnowCovered)
    if TheWorld.state.issnowcovered then
      OnSnowCovered(inst, true)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetMaxUses(30)
    inst.components.finiteuses:SetUses(30)

    inst:AddComponent("sleepingbag")
    inst.components.sleepingbag.onsleep = onsleep
    inst.components.sleepingbag.onwake = onwake
    inst.components.sleepingbag.health_tick = TUNING.SLEEP_HEALTH_PER_TICK * 2
    --convert wetness delta to drying rate
    inst.components.sleepingbag.dryingrate = math.max(0, -TUNING.SLEEP_WETNESS_PER_TICK / TUNING.SLEEP_TICK_PERIOD)
    inst.components.sleepingbag:SetTemperatureTickFn(temperaturetick)
    inst.components.sleepingbag.hunger_tick = TUNING.SLEEP_HUNGER_PER_TICK

    --MakeSnowCovered(inst)
    SetLunarHailBuildupAmountLarge(inst)
    inst:ListenForEvent("onbuilt", OnBuilt)

    MakeLargeBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload
    
    MakeHauntableWork(inst)

    return inst
end

return Prefab("jx_tent", fn, assets),
    MakePlacer("jx_tent_placer", "jx_tent", "jx_tent", "idle")