local assets =
{
        Asset("ANIM", "anim/alterguardian_meteor.zip"),
}

local projectile_prefabs =
{
    "medal_origin_flowertrap",
}

local trap_prefabs =
{
    "medal_origin_flowertrap_groundfx",
    "alterguardian_phase3trappst",
    "gestalt",
}

SetSharedLootTable("moonglass_trap",
{
    {"moonglass",   1.00},
})

local function set_guardian(inst, guardian)
    inst._guardian = guardian
end

local LANDEDAOE_CANT_TAGS = {
    "brightmareboss", "brightmare", "FX", "ghost", "INLIMBO", "NOCLICK", "playerghost",
}
local LANDEDAOE_ONEOF_TAGS = { "_combat", "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" }
local LANDEDAOE_RANGE = 2.25
local LANDEDAOE_RANGE_PADDING = 3
local function do_landed(inst)
    -- Start with a nice simple camera shake... Should be mild, since we're dropping a bunch of these.
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, 0.1, 0.1, inst, 35)

    -- Now do the complicated damage & destruction AOE.
    local attacker = (inst._guardian ~= nil and inst._guardian:IsValid() and inst._guardian)
            or inst
    local attacker_combat = attacker.components.combat
    local old_damage = nil

    if attacker_combat ~= nil then
        old_damage = attacker_combat.defaultdamage
        attacker_combat.ignorehitrange = true
        attacker_combat:SetDefaultDamage(TUNING.ALTERGUARDIAN_PHASE3_TRAP_LANDEDDAMAGE)
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local potential_targets = TheSim:FindEntities(
		x, y, z, LANDEDAOE_RANGE + LANDEDAOE_RANGE_PADDING, nil, LANDEDAOE_CANT_TAGS, LANDEDAOE_ONEOF_TAGS
    )
    for _, target in ipairs(potential_targets) do
		if target:IsValid() then
			local range = LANDEDAOE_RANGE + target:GetPhysicsRadius(0)
			if target:GetDistanceSqToPoint(x, y, z) < range * range then
				local health = target.components.health

				if health ~= nil and target:HasTag("smashable") then
					health:Kill()
				elseif target.components.workable ~= nil
						and target.components.workable:CanBeWorked()
						and target.components.workable.action ~= ACTIONS.NET then
					local tx, ty, tz = target.Transform:GetWorldPosition()
					if not target:HasTag("moonglass") then
						local collapse_fx = SpawnPrefab("collapse_small")
						collapse_fx.Transform:SetPosition(tx, ty, tz)
					end

					target.components.workable:Destroy(inst)
				elseif health ~= nil and not health:IsDead() then
					if attacker_combat ~= nil then
						attacker_combat:DoAttack(target)
					elseif target.components.combat ~= nil then
						target.components.combat:GetAttacked(attacker, TUNING.ALTERGUARDIAN_PHASE3_TRAP_LANDEDDAMAGE)
					end
                end
            end
        end
    end

    if attacker_combat ~= nil then
        attacker_combat.ignorehitrange = false
        attacker_combat:SetDefaultDamage(old_damage)
    end
end

local function spawn_trap(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()

    local trap = SpawnPrefab("medal_origin_flowertrap")
    trap.Transform:SetPosition(ix, iy, iz)

    if inst._guardian ~= nil and inst._guardian:IsValid() then
        inst._guardian:TrackTrap(trap)
    end

    inst:Remove()
end

local function projectile_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(0.85)
    inst.Light:SetColour(0.05, 0.05, 1)

    inst.AnimState:SetBank("alterguardian_meteor")
    inst.AnimState:SetBuild("alterguardian_meteor")
    inst.AnimState:PlayAnimation("meteor_pre")

    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_traps")

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetGuardian = set_guardian

    inst:DoTaskInTime(31*FRAMES, do_landed)
    inst:ListenForEvent("animover", spawn_trap)

    inst.persists = false

    return inst
end

local PULSE_MUST_TAGS = { "_health" }
local PULSE_CANT_TAGS =
{
    "brightmareboss",
    "brightmare",
    "DECOR",
    "epic",
    "FX",
    "ghost",
    "INLIMBO",
    "noauradamage",
    "playerghost",
    "chaos_creature",
}
--昏睡脉冲
local function do_groggy_pulse(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local nearby_targets = TheSim:FindEntities(
        ix, iy, iz, TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_AOERANGE,
        PULSE_MUST_TAGS, PULSE_CANT_TAGS
    )

    for _, target in ipairs(nearby_targets) do
        if target.entity:IsVisible()
				and target.components.health ~= nil
                and not target.components.health:IsDead()
                and target.sg ~= nil then
            --使进入范围的生物昏昏沉沉
            if target.components.grogginess ~= nil and not target.sg:HasStateTag("knockout") then
                target.components.grogginess:AddGrogginess(TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_GROGGINESS, TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_KNOCKOUTTIME)
                if target.components.grogginess.knockoutduration == 0 then
                    target:PushEvent("attacked", {attacker = inst, damage = 0})--0伤害攻击播受击动画
                    -- if target.components.sanity ~= nil then
                        -- target.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY)
                    -- end
                end
            elseif target.components.sleeper ~= nil and not target.sg:HasStateTag("sleeping") then
                target.components.sleeper:AddSleepiness(TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_GROGGINESS, TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_KNOCKOUTTIME)
                if not target.components.sleeper:IsAsleep() then
                    target:PushEvent("attacked", {attacker = inst, damage = 0})
                    -- if target.components.sanity ~= nil then
                        -- target.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY)
                    -- end
                end
			elseif target:HasTag("shadowminion") then
				target:PushEvent("attacked", { attacker = inst, damage = 0 })
            end
			--玩家混乱，生物恐慌
			if target:HasTag("player") then
				target:AddDebuff("buff_medal_confusion","buff_medal_confusion",{add_duration = TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_CONFUSION_TIME})
			elseif target.components.hauntable ~= nil and target.components.hauntable.panicable then
                target.components.hauntable:Panic(TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_PANIC_TIME)
			end
        end
    end
end

local START_CHARGE_TIME = 3.0--间歇期持续时间
--脉冲结束,进入间歇期
local function finish_pulse(inst)
    --脉冲特效收束,而后隐藏特效
    if inst._pulse_fx ~= nil and inst._pulse_fx:IsValid() then
        inst._pulse_fx.AnimState:PlayAnimation("meteorground_pst")
        local pulse_pst_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()
        inst._pulse_fx:DoTaskInTime(pulse_pst_len, inst._pulse_fx.Hide)
    end
    inst.components.timer:StopTimer("pulse")--停止释放脉冲
    inst.components.timer:StartTimer("spawn_glowfly", 24*FRAMES)--生成发光飞虫
    inst.components.timer:StartTimer("start_charge", START_CHARGE_TIME)--间歇期结束后重新开始脉冲
    inst.SoundEmitter:KillSound("trap_LP")
end

local NUM_PULSE_LOOPS = 3--脉冲持续时间
--开始释放脉冲
local function start_pulse(inst)
    --生成脉冲特效,如果已经有了那就通过Show/Hide来控制显示或隐藏就行了
    if inst._pulse_fx == nil or not inst._pulse_fx:IsValid() then
        inst._pulse_fx = SpawnPrefab("medal_origin_flowertrap_groundfx")
        inst._pulse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        inst._pulse_fx:Show()
    end

    inst._pulse_fx.AnimState:PlayAnimation("meteorground_pre")
    local pulse_pre_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()

    inst._pulse_fx.AnimState:PushAnimation("meteorground_loop", true)
    local pulse_loop_len = inst._pulse_fx.AnimState:GetCurrentAnimationLength()

    --第一次脉冲在脉冲范围扩散足够大的时候触发，后续的则定时触发即可
    inst.components.timer:StartTimer("pulse", pulse_pre_len * 0.66)

    --持续一段时间后进入间歇期
    inst.components.timer:StartTimer("finish_pulse", pulse_pre_len + (pulse_loop_len * NUM_PULSE_LOOPS))
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_trap_LP","trap_LP")
end
--充能
local function start_charge(inst)
    inst.AnimState:PlayAnimation("meteor_charge")
    inst.AnimState:PushAnimation("meteor_idle", true)
    inst.components.timer:StopTimer("spawn_glowfly")--停止生成飞虫
	--充能结束开始释放脉冲
    inst.components.timer:StartTimer("start_pulse", inst.AnimState:GetCurrentAnimationLength())
end

-- local function go_to_gestaltdeath(gestalt)
--     gestalt:PushEvent("death")
-- end

-- local function spawn_gestalt(inst)
--     local gestalt = SpawnPrefab("gestalt")
--     gestalt._ignorerelocating = true
--     gestalt.Transform:SetPosition(inst.Transform:GetWorldPosition())
--     gestalt:SetTrackingTarget(nil, 3)

--     gestalt:DoTaskInTime(15, go_to_gestaltdeath)
-- end

--生成飞虫
local function do_spawn_glowfly(inst)
    local tree = TheWorld and TheWorld.medal_origin_tree
    local insect_num = tree and tree.origin_insect_num or math.huge
    --飞虫数量不能超过上限
    if insect_num < TUNING_MEDAL.MEDAL_ORIGIN_TREE_INSECT_NUM_MAX then
        local insect = SpawnPrefab(tree.GetRandomInsect and tree:GetRandomInsect() or "medal_origin_glowfly")
        if insect ~= nil then
            insect.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if tree.RegisterOriginInsect ~= nil then
                tree:RegisterOriginInsect(insect)--加入本源之树列表
            end
            --飞虫快速结茧
            if insect.SetCocoonTime then
                insect:SetCocoonTime(TUNING_MEDAL.MEDAL_ORIGIN_GLOWFLY_COCOON_FAST)
            end
        end
    end
end

local PULSE_TICK_TIME = 24*FRAMES--脉冲释放周期(0.8秒)
--定时器监听
local function on_trap_timer(inst, data)
    --充能(播放充能动画来提示玩家要开始脉冲了)
	if data.name == "start_charge" then
        start_charge(inst)
    --充能完毕后开始释放脉冲
	elseif data.name == "start_pulse" then
        start_pulse(inst)
    --释放脉冲
	elseif data.name == "pulse" then
        do_groggy_pulse(inst)--昏睡脉冲
        inst.components.timer:StartTimer("pulse", PULSE_TICK_TIME)--循环释放
    --间歇期
	elseif data.name == "finish_pulse" then
        finish_pulse(inst)
    --生成飞虫
    elseif data.name == "spawn_glowfly" then
        do_spawn_glowfly(inst)--生成飞虫
        inst.components.timer:StartTimer("spawn_glowfly", PULSE_TICK_TIME)--循环生成
        --存活时间到了就移除
	elseif data.name == "trap_lifetime" then
        inst:Remove()
    end
end
--移除
local function on_trap_removed(inst)
    --移除脉冲特效
	if inst._pulse_fx ~= nil and inst._pulse_fx:IsValid() then
        inst._pulse_fx:Remove()
        inst._pulse_fx = nil
    end
    local ipos = inst:GetPosition()
    inst.components.lootdropper:DropLoot(ipos)--生成掉落
	--爆炸特效
    SpawnPrefab("alterguardian_phase3trappst").Transform:SetPosition(ipos:Get())
end

local function trap_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(0.85)
    inst.Light:SetColour(0.05, 0.05, 1)

    inst:AddTag("moonglass")

    inst.AnimState:SetBank("alterguardian_meteor")
    inst.AnimState:SetBuild("alterguardian_meteor")
    inst.AnimState:PlayAnimation("meteor_idle", true)

    MakeObstaclePhysics(inst, 1)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING_MEDAL.MEDAL_ORIGIN_FLOWERTRAP_WORKLEFT)
    inst.components.workable:SetOnFinishCallback(inst.Remove)
    inst.components.workable:SetRequiresToughWork(true)--需要高强度工作
    inst.components.workable.savestate = true

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("moonglass_trap")

    inst:AddComponent("timer")

    inst:ListenForEvent("timerdone", on_trap_timer)
    inst:ListenForEvent("onremove", on_trap_removed)
    -- inst:ListenForEvent("onalterguardianlasered", spawn_gestalt)

    inst.components.timer:StartTimer("start_charge", START_CHARGE_TIME)
    -- inst.components.timer:StartTimer("trap_lifetime", TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT + 10*math.random())

    return inst
end
--脉冲
local function groundfx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("alterguardian_meteor")
    inst.AnimState:SetBuild("alterguardian_meteor")
    inst.AnimState:PlayAnimation("meteorground_pre")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("medal_origin_flowertrap_projectile", projectile_fn, assets, projectile_prefabs),
        Prefab("medal_origin_flowertrap", trap_fn, assets, trap_prefabs),
        Prefab("medal_origin_flowertrap_groundfx", groundfx_fn, assets)
