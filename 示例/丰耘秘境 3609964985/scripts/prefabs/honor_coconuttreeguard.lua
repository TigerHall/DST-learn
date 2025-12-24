----------------------------------------------------------------------------
---[[椰子树精]]
----------------------------------------------------------------------------
local brain = require "brains/honor_coconuttreeguard_brain"

local assets =
{
    Asset("ANIM", "anim/treeguard_walking.zip"),
    Asset("ANIM", "anim/treeguard_actions.zip"),
    Asset("ANIM", "anim/treeguard_attacks.zip"),
    Asset("ANIM", "anim/treeguard_idles.zip"),
    Asset("ANIM", "anim/treeguard_build.zip"),
}

local prefabs =
{
    "meat",
    "log",
    "character_fire",
    "livinglog",
    "honor_coconut_thrown",
}

SetSharedLootTable("honor_coconuttreeguard",
{
    {"livinglog",   1.0},
    {"livinglog",   1.0},
    {"livinglog",   1.0},
    {"livinglog",   0.5},
    {"livinglog",   0.2},
    {"livinglog",   0.05},
    {"honor_coconut",     1.0},
    {"honor_coconut",     1.0},
})

local function OnLoad(inst, data)
    if data and data.hibernate then
        inst.components.sleeper.hibernate = true
    end
    if data and data.sleep_time then
        inst.components.sleeper.testtime = data.sleep_time
    end
    if data and data.sleeping then
        inst.components.sleeper:GoToSleep()
    end
end

local function OnSave(inst, data)
    if inst.components.sleeper:IsAsleep() then
        data.sleeping = true
        data.sleep_time = inst.components.sleeper.testtime
    end

    if inst.components.sleeper:IsHibernating() then
        data.hibernate = true
    end
end

local function CalcSanityAura(inst, observer)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_LARGE
    else
        return -TUNING.SANITYAURA_MED
    end

    return 0
end

local function OnBurnt(inst)
    if inst.components.propagator and inst.components.health and not inst.components.health:IsDead() then
        inst.components.propagator.acceptsheat = true
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnAttack(inst, data)
    local numshots = 3
    if data.target then
        for i = 0, numshots - 1 do
            local offset = Vector3(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
            inst.components.thrower:Throw(data.target:GetPosition() + offset)
        end
    end
end

local function SetRangeMode(inst)
    if inst.combatmode == "RANGE" then
        return
    end

    local scale = inst.Transform:GetScale()

    inst.combatmode = "RANGE"
    inst.components.combat:SetDefaultDamage(0)
    inst.components.combat:SetAttackPeriod(6)
    inst.components.combat:SetRange(20 * scale, 25 * scale)
    inst:ListenForEvent("onattackother", OnAttack)
end

local function SetMeleeMode(inst)
    if inst.combatmode == "MELEE" then
        return
    end

    local scale = inst.Transform:GetScale()

    inst.combatmode = "MELEE"
    inst.components.combat:SetDefaultDamage(TUNING.PALMTREEGUARD_DAMAGE * scale)
    inst.components.combat:SetAttackPeriod(TUNING.PALMTREEGUARD_ATTACK_PERIOD)
    inst.components.combat:SetRange(20 * scale, 3 * scale)
    inst:RemoveEventCallback("onattackother", OnAttack)
end

local COMBAT_MUSHAVE_TAGS = { "_combat", "_health" }
local COMBAT_CANTHAVE_TAGS = { "INLIMBO", "noauradamage", "player", "companion" }

local function retargetfn(inst)
    local leader = inst.components.follower.leader
    if leader == nil then
        return nil
    else
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local entities_near_me = TheSim:FindEntities(
            ix, iy, iz, 8,
            COMBAT_MUSHAVE_TAGS, COMBAT_CANTHAVE_TAGS
        )

        for _, v in ipairs(entities_near_me) do
            if v ~= inst and v ~= leader and v.entity:IsVisible()
                and v:GetDistanceSqToInst(leader) < 8 * 8
                and inst.components.combat:CanTarget(v)
                and v.components.minigame_participator == nil
                and (v.components.combat.target == leader or
                        leader.components.combat.target == v or
                        v.components.combat.target == inst) then
                return v
            end
        end

        return nil
    end
end

local function keeptarget(inst, target)
    local leader = inst.components.follower.leader
    return (leader == nil or inst:IsNear(leader, 8))
        and inst.components.combat:CanTarget(target)
        and inst:IsNear(target, 8)
end

local function OnTimerDown(inst, data)
    if data.name == "disappear" then
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    end
end

local function SetDisappear(inst, time)
    inst.components.timer:StartTimer("disappear", time)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4, 1.5)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 1000, .5)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("leif")
    inst:AddTag("tree")
    inst:AddTag("largecreature")
    inst:AddTag("epic")

    inst.AnimState:SetBank("treeguard")
    inst.AnimState:SetBuild("treeguard_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 2

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    MakeLargeBurnableCharacter(inst, "marker")
    inst.components.burnable.flammability = TUNING.PALMTREEGUARD_FLAMMABILITY
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.propagator.acceptsheat = true

    MakeHugeFreezableCharacter(inst, "marker")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(2000)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "marker"
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat:SetAttackPeriod(0)
    inst.components.combat:SetRange(20, 25)
    inst.components.combat.playerdamagepercent = .33
    inst.components.combat:SetRetargetFunction(3,retargetfn)
    inst.components.combat:SetKeepTargetFunction(keeptarget)

    inst:AddComponent("follower")

    inst:AddComponent("thrower")
    inst.components.thrower.throwable_prefab = "honor_coconut_thrown"

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("honor_coconuttreeguard")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDown)

    inst:SetStateGraph("SG_honor_coconuttreeguard")
    inst:SetBrain(brain)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    inst.SetRange = SetRangeMode
    inst.SetMelee = SetMeleeMode
    inst.SetDisappear = SetDisappear

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

----------------------------------------------------------------------------
---[[扔出的椰子]]
----------------------------------------------------------------------------
local thrown_assets=
{
	Asset("ANIM", "anim/coconut_cannon.zip"),
}

local thrown_prefabs = 
{
	"small_puff",
	"coconut_chunks",
	"bombsplash",
}

local function onthrown(inst, thrower, pt, time_to_target)
    inst.Physics:SetFriction(.2)
	inst.Transform:SetFourFaced()
	inst:FacePoint(pt:Get())
    inst.AnimState:PlayAnimation("throw", true)

    local shadow = SpawnPrefab("warningshadow")
    shadow.Transform:SetPosition(pt:Get())
    -- shadow:shrink(time_to_target, 1.75, 0.5)

	inst.TrackHeight = inst:DoPeriodicTask(FRAMES, function()
		local pos = inst:GetPosition()

		if pos.y <= 0.3 then

		    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 1.5, nil, inst.noTags)

		    for k,v in pairs(ents) do
	            if v.components.combat and v ~= inst and v.prefab ~= "treeguard" then
	                v.components.combat:GetAttacked(thrower, 50)
	            end
		    end

			local pt = inst:GetPosition()
			-- if inst:GetIsOnWater() then
            if inst:IsOnOcean(false) then
				-- local splash = SpawnPrefab("bombsplash")
				-- splash.Transform:SetPosition(pos.x, pos.y, pos.z)

				inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/cannonball_impact")
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")

			else
				local smoke = SpawnPrefab("small_puff")

				local other = nil

				-- if math.random() < 0.01 then
				-- 	other = SpawnPrefab("coconut")
				-- else
				-- 	other = SpawnPrefab("coconut_chunks")
				-- end
				smoke.Transform:SetPosition(pt:Get())
				-- other.Transform:SetPosition(pt:Get())
			end

			inst:Remove()
            if shadow then
                shadow:Remove()
            end
		end
	end)
end

local function onremove(inst)
	if inst.TrackHeight then
		inst.TrackHeight:Cancel()
		inst.TrackHeight = nil
	end
end

local function thrown_fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("coconut_cannon")
	inst.AnimState:SetBuild("coconut_cannon")
	inst.AnimState:PlayAnimation("throw", true)

	inst:AddTag("thrown")
	inst:AddTag("projectile")

	inst.noTags = {"FX", "DECOR", "INLIMBO", "shadow"}

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("throwable")
	inst.components.throwable.onthrown = onthrown
	inst.components.throwable.random_angle = 0
	inst.components.throwable.max_y = 50
	inst.components.throwable.yOffset = 3

	inst.OnRemoveEntity = onremove

	return inst
end

return Prefab("honor_coconuttreeguard", fn, assets, prefabs),
    Prefab("honor_coconut_thrown", thrown_fn, thrown_assets, thrown_prefabs)

