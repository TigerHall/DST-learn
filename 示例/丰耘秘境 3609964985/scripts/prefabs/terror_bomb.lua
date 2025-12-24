----------------------------------------------------------------------------------------
---[[凶险炸弹]]
----------------------------------------------------------------------------------------
local assets =
{
	Asset("ANIM", "anim/terror_bomb.zip"),
}

local prefabs =
{
	"terror_bomb_fx",
	"reticule",
	"reticuleaoe",
	"reticuleaoeping",
}

local function OnHit(inst, attacker, target)
	local x, y, z = inst.Transform:GetWorldPosition()

	inst.SoundEmitter:KillSound("toss")

	inst:AddComponent("explosive")
	inst.components.explosive.explosiverange = TUNING.HMR_TERROR_BOMB_EXPLOSION_RANGE
	inst.components.explosive.explosivedamage = TUNING.HMR_TERROR_BOMB_EXPLOSION_DAMAGE
	inst.components.explosive.buildingdamage = 0
	inst.components.explosive.lightonexplode = false
	if inst.ispvp then
		inst.components.explosive:SetPvpAttacker(attacker)
	else
		inst.components.explosive:SetAttacker(attacker)
	end
	inst.components.explosive:OnBurnt()
	--exploding should have removed me

	SpawnPrefab("terror_bomb_fx").Transform:SetPosition(x, y, z)

	SpawnPrefab("terror_bomb_flower").Transform:SetPosition(x, y, z)
end

local function onequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_object", inst.GUID, "terror_bomb")
	else
		owner.AnimState:OverrideSymbol("swap_object", "terror_bomb", "swap_object")
	end
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
end

local FX_TICKS = 30
local MAX_ADD_COLOUR = .6

local function UpdateSpin(inst, ticks)
	inst.spinticks:set_local(inst.spinticks:value() + ticks)
	--V2C: hack alert: using SetHightlightColour to achieve something like OverrideAddColour
	--     (that function does not exist), because we know this FX can never be highlighted!
	if inst.spinticks:value() < FX_TICKS then
		local k = inst.spinticks:value() / FX_TICKS
		k = k * k * MAX_ADD_COLOUR
		inst.AnimState:SetHighlightColour(k, k, k, 0)
		inst.AnimState:OverrideMultColour(1, 1, 1, k)
		if inst.core ~= nil then
			inst.core.AnimState:SetAddColour(k, k, k, 0)
			inst.core.AnimState:SetLightOverride(k / 3)
		end
	else
		inst.AnimState:SetHighlightColour(MAX_ADD_COLOUR, MAX_ADD_COLOUR, MAX_ADD_COLOUR, 0)
		inst.AnimState:OverrideMultColour(1, 1, 1, MAX_ADD_COLOUR)
		if inst.core ~= nil then
			inst.core.AnimState:SetAddColour(MAX_ADD_COLOUR, MAX_ADD_COLOUR, MAX_ADD_COLOUR, 0)
			inst.core.AnimState:SetLightOverride(MAX_ADD_COLOUR / 3)
		end
		inst.spintask:Cancel()
		inst.spintask = nil
	end
end

local function CreateSpinCore()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	if not TheWorld.ismastersim then
		inst.entity:SetCanSleep(false)
	end
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank("terror_bomb")
	inst.AnimState:SetBuild("terror_bomb")
	inst.AnimState:PlayAnimation("idle_spin")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	return inst
end

local function OnSpinTicksDirty(inst)
	if inst.spintask == nil then
		inst.spintask = inst:DoPeriodicTask(0, UpdateSpin, nil, 1)
		--Dedicated server does not need to trigger sfx
		if not TheNet:IsDedicated() then
			--restore teh bomb core at full opacity, since we're fading in the entire
			--entity to fadein the light rays (easier that way to optimize networking!)
			inst.core = CreateSpinCore()
			inst.core.entity:SetParent(inst.entity)
			inst.core.Follower:FollowSymbol(inst.GUID, "bomb", nil, nil, nil, true)
		end
	end
	UpdateSpin(inst, 0)
end

local function onthrown(inst, attacker)
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst.ispvp = attacker ~= nil and attacker:IsValid() and attacker:HasTag("player")

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:PlayAnimation("idle_spin", true)
	inst.AnimState:SetLightOverride(1)

	inst.SoundEmitter:PlaySound("rifts/lunarthrall_bomb/throw", "toss")

	inst.Physics:SetMass(1)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)
	inst.Physics:SetCapsule(.2, .2)

	inst.spinticks:set(3)
	OnSpinTicksDirty(inst)
end

local function ReticuleTargetFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	--Attack range is 8, leave room for error
	--Min range was chosen to not hit yourself (2 is the hit range)
	for r = 6.5, 3.5, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetTwoFaced()

	MakeInventoryPhysics(inst)

	inst:AddTag("toughworker")
	inst:AddTag("explosive")

	--projectile (from complexprojectile component) added to pristine state for optimization
	inst:AddTag("projectile")

	inst.AnimState:SetBank("terror_bomb")
	inst.AnimState:SetBuild("terror_bomb")
	inst.AnimState:PlayAnimation("idle")

	inst:AddComponent("reticule")
	inst.components.reticule.targetfn = ReticuleTargetFn
	inst.components.reticule.ease = true

	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "small", 0.1, 0.8)

	inst.spinticks = net_smallbyte(inst.GUID, "terror_bomb.spinticks", "spinticksdirty")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("spinticksdirty", OnSpinTicksDirty)

		return inst
	end

	inst:AddComponent("locomotor")

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(15)
	inst.components.complexprojectile:SetGravity(-35)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrown)
	inst.components.complexprojectile:SetOnHit(OnHit)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetRange(16, 16)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/terror_bomb.xml"

	inst:AddComponent("stackable")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipstack = true

	MakeHauntableLaunch(inst)

	return inst
end

----------------------------------------------------------------------------------------
---[[爆炸特效]]
----------------------------------------------------------------------------------------
local fx_assets =
{
	Asset("ANIM", "anim/terror_bomb_fx.zip"),
}

local function PlayExplodeSound(inst)
	inst.SoundEmitter:PlaySound("rifts/lunarthrall_bomb/explode")
end

local function fx_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("terror_bomb_fx")
	inst.AnimState:SetBuild("terror_bomb_fx")
	inst.AnimState:PlayAnimation("puff")
	inst.AnimState:SetSymbolBloom("fx_spark")
	inst.AnimState:SetSymbolBloom("fx_wings")
	inst.AnimState:SetSymbolLightOverride("fx_spark", 1)
	inst.AnimState:SetSymbolLightOverride("fx_wings", 1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoTaskInTime(0, PlayExplodeSound)

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

	return inst
end

----------------------------------------------------------------------------------------
---[[凶险虞子花]]
----------------------------------------------------------------------------------------
local flower_assets =
{
    Asset("ANIM", "anim/terror_bomb_flower.zip"),
}

local function OnDig(inst, worker)
	if not worker:HasTag("player") then
		inst.components.workable:SetWorkLeft(1)
	end
end

local function OnDug(inst, worker)
	if not worker:HasTag("player") then
		return
	end

    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot(inst:GetPosition())
	end

	local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")

    if not inst.components.health:IsDead() then
		inst.components.health:Kill()
	end
end

local function OnDeath(inst)
    inst.components.lootdropper:DropLoot(inst:GetPosition())
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

local function flower_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .3)

    -- inst.MiniMapEntity:SetIcon("resurrect.png")

    -- inst:AddTag("plant") -- 不能加，会被强制kill
    inst:AddTag("resurrector")
	inst:AddTag("notarget")
	inst:AddTag("companion") -- 不会被玩家攻击
	inst:AddTag("mocker") -- 嘲讽

    inst.AnimState:SetBank("terror_bomb_flower")
    inst.AnimState:SetBuild("terror_bomb_flower")
    inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetSymbolBloom("eye")
	inst.AnimState:SetSymbolLightOverride("eye", .5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(OnDig)
    inst.components.workable:SetOnFinishCallback(OnDug)

	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HMR_TERROR_FLOWER_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
    inst:ListenForEvent("death", OnDeath)

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeLargePropagator(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

	inst:SetStateGraph("SG_terror_bomb_flower")

    return inst
end

return  Prefab("terror_bomb", fn, assets, prefabs),
	    Prefab("terror_bomb_fx", fx_fn, fx_assets),
		Prefab("terror_bomb_flower", flower_fn, flower_assets)