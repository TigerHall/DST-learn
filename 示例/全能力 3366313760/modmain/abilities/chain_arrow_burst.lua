local CHAIN_ARROW_BURST_KEY = GLOBAL["KEY_" .. GetModConfigData("chain_arrow_burst")]
local Utils = require("aab_utils/utils")
local Shapes = require("aab_utils/shapes")

table.insert(PrefabFiles, "aab_chain_arrow_projectile")

----------------------------------------------------------------------------------------------------

AAB_AddFx({
    name = "aab_chain_arrow_spawn_fx",
    bank = "lunar_fx",
    build = "merm_lunar_fx",
    anim = "pre",
    bloom = true,
    fn = function(inst)
        inst.AnimState:SetMultColour(1, .6, .2, 1)
    end
})
AAB_AddFx({
    name = "aab_chain_arrow_hit_fx",
    bank = "deer_fire_charge",
    build = "deer_fire_charge",
    anim = "blast",
    bloom = true,
    sound = "dontstarve/characters/walter/slingshot/shoot"
})
AAB_AddFx({
    name = "aab_chain_arrow_hit2_fx",
    bank = "deer_fire_charge",
    build = "deer_fire_charge",
    anim = "blast",
    bloom = true,
    sound = "dontstarve/common/together/reskin_tool",
    fn = function(inst)
        inst.AnimState:SetScale(1.5, 1.5)
    end
})

----------------------------------------------------------------------------------------------------
local function Launch(attacker, target, pos)
    if target:IsValid() then
        pos.y = 0.75
        local arrow = SpawnAt("aab_chain_arrow_projectile", pos)
        arrow.components.projectile:Throw(attacker, target, attacker)
    end
end

TUNING.TT = -1.5
local function SpawnArrow(attacker, target, pos)
    pos = pos or Shapes.GetRandomLocation(attacker:GetPosition(), 4, 8)
    SpawnPrefab("aab_chain_arrow_spawn_fx").Transform:SetPosition(pos.x, TUNING.TT, pos.z)
    attacker:DoTaskInTime(0.5, Launch, target, pos)
end

AddModRPCHandler(modname, "ChainArrowBurst", function(inst)
    local targets = {}
    for k, _ in pairs(inst._aab_burst_arrows) do
        local target = k:IsValid() and k.entity:GetParent()
        if target and target:IsValid()
            and not targets[target]
            and not IsEntityDead(target)
            and target.components.combat
            and target._aab_burst_arrow_count
        then
            SpawnAt("aab_chain_arrow_hit2_fx", target)
            local d = target._aab_burst_arrow_count
            targets[target] = d
            target.components.combat:GetAttacked(inst, 5 + (1 + d) * d) --伤害递增，就是一个等差数列
            target._aab_burst_arrow_count = nil
        end
        k:Remove()
    end

    for target, count in pairs(targets) do
        if IsEntityDead(target) then
            --击杀目标，生成新的长矛
            local targetpos = target:GetPosition()
            for _, v in ipairs(TheSim:FindEntities(targetpos.x, targetpos.y, targetpos.z, 16, { "_combat" }, { "INLIMBO" })) do
                if not IsEntityDead(v)
                    and (v.prefab == target.prefab
                        or (v.components.combat.target and v.components.combat.target:HasTag("player")))
                then
                    for i = 1, count do
                        SpawnArrow(inst, v, Shapes.GetRandomLocation(targetpos, 0, 2))
                    end
                end
            end
        end
    end

    inst._aab_burst_arrows = {}
end)


TheInput:AddKeyDownHandler(CHAIN_ARROW_BURST_KEY, function()
    if Utils.IsDefaultScreen() then
        SendModRPCToServer(MOD_RPC[modname]["ChainArrowBurst"])
    end
end)


----------------------------------------------------------------------------------------------------
local function OnAttackOther(inst, data)
    local target = data and data.target
    if not target or IsEntityDead(target) or (data.projectile and data.projectile.prefab == "aab_chain_arrow_projectile") then return end

    SpawnArrow(inst, target)
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst._aab_burst_arrows = {}
    inst:ListenForEvent("onattackother", OnAttackOther)
end)


----------------------------------------------------------------------------------------------------
local function OnEntitySleep(inst)
    inst._aab_burst_arrow_count = nil
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("entitysleep", OnEntitySleep)
end)
