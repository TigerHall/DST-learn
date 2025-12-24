local Utils = require("aab_utils/utils")
local Shapes = require("aab_utils/shapes")

local function GiveAllItem(inst)
    local leader = inst.components.follower.leader
    if leader and leader.components.inventory then
        for _, v in ipairs(inst.components.inventory:ReferenceAllItems()) do
            if not v:HasTag("aab_temp") then
                v:AddTag("aab_picktag")
                v:DoTaskInTime(8, function() v:RemoveTag("aab_picktag") end)
                inst.components.inventory:RemoveItem(v, true)
                leader.components.inventory:GiveItem(v)
            end
        end
    end
end

local function OnDeath(inst, data)
    if not inst.disappear then --说明不是我杀死的
        local leader = inst.components.follower.leader
        if leader then
            if leader.components.sanity then
                leader.components.sanity:DoDelta(-30)
            end
        end
    end

    GiveAllItem(inst)
end

-- 虽然已经有on_landed了，但是这个能更快的移除，掉落动画都看不见的
local function OnDropItem(inst, data)
    local item = data and data.item
    if item and item:HasTag("aab_temp") then
        item:Hide() --先隐藏一下，因为延迟一帧还是能看见装备掉出来
        item:DoTaskInTime(0, item.Remove)
    end
end

local function OnItemGet(inst, data)
    inst:DoTaskInTime(0, GiveAllItem)
end

local brain = require("brains/aab_minionbrain")

local function Init(inst)
    inst:RemoveTag("notarget")
    inst:RemoveTag("INLIMBO")
    inst.components.health:SetInvincible(false)

    if inst.type == "attack" then
        inst.components.combat:SetTarget(inst.target)
    end
end


local function Setup(inst, leader, target)
    inst.target = target
    inst.targetprefab = target.prefab


    if target.components.inventoryitem
        and not target.components.inventoryitem:IsHeld()
        and target.components.inventoryitem.canbepickedup
        and target.components.inventoryitem.cangoincontainer
    then
        inst.type = "pickup"
    elseif target.components.pickable and target:HasTag("pickable") then
        inst.type = "pick"
    elseif target.components.workable and target.components.workable:CanBeWorked() then
        inst.type = "work"
    else
        inst.type = "attack"
    end

    local character = TUNING.AAB_CHARACTERS[math.random(#TUNING.AAB_CHARACTERS)]
    inst.AnimState:SetBuild(character)
    inst.MiniMapEntity:SetIcon(character .. ".png")
    if IsRestrictedCharacter(character) then
        inst.components.skinner:SetSkinMode("normal_skin")
    end

    inst.AnimState:SetErosionParams(0, -0.125, -0.4)
    inst.components.follower:SetLeader(leader)

    -- 在活动之前无敌且不可见
    inst:AddTag("notarget")
    inst:AddTag("INLIMBO")
    inst.components.health:SetInvincible(true)

    local pos = Shapes.GetRandomLocation(target:GetPosition(), target:GetPhysicsRadius(0.5) + 0.5, target:GetPhysicsRadius(0.5) + 0.5 + 4)
    inst.Transform:SetPosition(pos:Get())
    -- SpawnAt("dreadstone_spawn_fx", pos)
    inst.AnimState:SetMultColour(1, 1, 1, 0)
    inst.components.colourtweener:StartTween({ 1, 1, 1, 0.65 }, 0.6, Init)

    -- 拷贝玩家装备
    for _, v in ipairs({
        EQUIPSLOTS.HEAD,
        EQUIPSLOTS.BODY
    }) do
        local item = leader.components.inventory:GetEquippedItem(v)
        if item then
            inst.components.inventory:Equip(inst:SpawnTempItem(item.prefab))
        end
    end
end

local function SpawnTempItem(inst, prefab)
    local it = type(prefab) == "string" and SpawnPrefab(prefab) or prefab

    it.persists = false
    if not it.components.vanish_on_sleep then
        it:AddComponent("vanish_on_sleep")
    end
    it:ListenForEvent("on_landed", function() it:DoTaskInTime(0, it.Remove) end) --物品掉地上移除
    it:AddTag("aab_temp")
    return it
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetMultColour(1, 1, 1, 0.65)

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")

    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:OverrideSymbol("fx_liquid", "wilson_fx", "fx_liquid")
    inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
    inst.AnimState:OverrideSymbol("snap_fx", "player_actions_fishing_ocean_new", "snap_fx")

    --Additional effects symbols for hit_darkness animation
    inst.AnimState:AddOverrideBuild("player_hit_darkness")
    inst.AnimState:AddOverrideBuild("player_receive_gift")
    inst.AnimState:AddOverrideBuild("player_actions_uniqueitem")
    inst.AnimState:AddOverrideBuild("player_wrap_bundle")
    inst.AnimState:AddOverrideBuild("player_lunge")
    inst.AnimState:AddOverrideBuild("player_attack_leap")
    inst.AnimState:AddOverrideBuild("player_superjump")
    inst.AnimState:AddOverrideBuild("player_multithrust")
    inst.AnimState:AddOverrideBuild("player_parryblock")
    inst.AnimState:AddOverrideBuild("player_emote_extra")
    inst.AnimState:AddOverrideBuild("player_boat_plank")
    inst.AnimState:AddOverrideBuild("player_boat_net")
    inst.AnimState:AddOverrideBuild("player_boat_sink")
    inst.AnimState:AddOverrideBuild("player_oar")

    inst.AnimState:AddOverrideBuild("player_actions_fishing_ocean_new")
    inst.AnimState:AddOverrideBuild("player_actions_farming")
    inst.AnimState:AddOverrideBuild("player_actions_cowbell")

    inst.DynamicShadow:SetSize(1.3, .6)

    inst.MiniMapEntity:SetIcon("wilson.png")
    inst.MiniMapEntity:SetPriority(10)
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    MakeGhostPhysics(inst, 1, .5)

    inst:AddTag("scarytoprey")
    inst:AddTag("character")
    inst:AddTag("companion")
    inst:AddTag("crazy")
    inst:AddTag("stronggrip")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(0.6)
    inst.components.locomotor.pathcaps = { player = true, ignorecreep = true } -- 'player' cap not actually used, just useful for testing
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED             -- 4
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED               -- 6
    inst.components.locomotor.fasteronroad = true
    inst.components.locomotor:SetFasterOnCreep(inst:HasTag("spiderwhisperer"))
    inst.components.locomotor:SetTriggersCreep(not inst:HasTag("spiderwhisperer"))
    inst.components.locomotor.pusheventwithdirection = true

    inst:AddComponent("skinner")

    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.DEFAULT_ATTACK_RANGE)
    inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)

    inst:AddComponent("follower")
    inst.components.follower.keepdeadleader = true
    inst.components.follower:KeepLeaderOnAttacked()

    inst:AddComponent("health")
    inst.components.health.nofadeout = true

    inst:AddComponent("inventory")
    inst.components.inventory:DisableDropOnDeath()


    -- inst:AddComponent("inspectable")
    inst:AddComponent("vanish_on_sleep")
    inst:AddComponent("lootdropper")
    inst:AddComponent("colourtweener")

    inst.soundsname = "wendy"
    inst.persists = false
    inst.Setup = Setup
    inst.SpawnTempItem = SpawnTempItem

    inst:SetBrain(brain)
    inst:SetStateGraph("SGaab_minion")

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("dropitem", OnDropItem)

    return inst
end

return Prefab("aab_minion", fn)
