local Utils = require("aab_utils/utils")

-- 等于1消耗理智，等于2消耗饱食度
local WAXWELLJOURNAL_CONSUME = GetModConfigData("waxwelljournal_consume")
local NUM_MINIONS_PER_SPAWN = GetModConfigData("waxwell_shadow_num") or 1 --每次生成的个数
local SUMMON_COST = 15

----------------------------------------------------------------------------------------------------
local function KillPet(pet)
    if pet.components.health:IsInvincible() then
        --reschedule
        pet._killtask = pet:DoTaskInTime(.5, KillPet)
    else
        pet.components.health:Kill()
    end
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            if WAXWELLJOURNAL_CONSUME == 1 then
                inst.components.sanity:DoDelta(-SUMMON_COST) --每个扣除SUMMON_COST
            elseif WAXWELLJOURNAL_CONSUME == 2 then
                inst.components.hunger:DoDelta(-SUMMON_COST)
            else
                inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
            end
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
            pet.components.skinner:CopySkinsFromPlayer(inst)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
        return nil, true
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.petleash:SetMaxPets(100) --数量放宽一点

    Utils.FnDecorator(inst.components.petleash, "onspawnfn", OnSpawnPet)
end)

----------------------------------------------------------------------------------------------------

local SPELLS

local function SpellCost(pct)
    return pct * TUNING.LARGE_FUEL * -4
end

local function NotBlocked(pt)
    return not TheWorld.Map:IsGroundTargetBlocked(pt)
end

local function FindSpawnPoints(doer, pos, num, radius)
    local ret = {}
    local theta, delta, attempts
    if num > 1 then
        delta = TWOPI / num
        attempts = 3
        theta = doer:GetAngleToPoint(pos) * DEGREES
        if num == 2 then
            theta = theta + PI * (math.random() < .5 and .5 or -.5)
        else
            theta = theta + PI
            if math.random() < .5 then
                delta = -delta
            end
        end
    else
        theta = 0
        delta = 0
        attempts = 1
        radius = 0
    end
    for i = 1, num do
        local offset = FindWalkableOffset(pos, theta, radius, attempts, false, false, NotBlocked, true, true)
        if offset ~= nil then
            table.insert(ret, Vector3(pos.x + offset.x, 0, pos.z + offset.z))
        end
        theta = theta + delta
    end
    return ret
end

local function TrySpawnMinions(prefab, doer, pos)
    if doer.components.petleash ~= nil then
        local spawnpts = FindSpawnPoints(doer, pos, NUM_MINIONS_PER_SPAWN, 1)
        if #spawnpts > 0 then
            for i, v in ipairs(spawnpts) do
                local pet = doer.components.petleash:SpawnPetAt(v.x, 0, v.z, prefab)
                if pet ~= nil then
                    if pet.SaveSpawnPoint ~= nil then
                        pet:SaveSpawnPoint()
                    end
                    if #spawnpts > 1 and i <= 3 then
                        --restart "spawn" state with specified time multiplier
                        pet.sg.statemem.spawn = true
                        pet.sg:GoToState("spawn",
                            (i == 1 and 1) or
                            (i == 2 and .8) or
                            .87 + math.random() * .06
                        )
                    end
                end
            end
            return true
        end
    end
    return false
end

-- 判断的时候只判断是否够一个的数量
local function _CheckMaxSanity(doer, minionprefab)
    if WAXWELLJOURNAL_CONSUME == 1 then
        --理智
        return doer.replica.sanity and doer.replica.sanity:GetCurrent() >= SUMMON_COST
    elseif WAXWELLJOURNAL_CONSUME == 2 then
        --饱食度
        return doer.replica.hunger and doer.replica.hunger:GetCurrent() >= SUMMON_COST
    else
        -- 理智上限
        return doer.replica.sanity ~= nil and
            doer.replica.sanity:GetPenaltyPercent() + (TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(minionprefab)] or 0) <= TUNING.MAXIMUM_SANITY_PENALTY
    end
end

local function CheckMaxSanity(doer, minionprefab)
    return _CheckMaxSanity(doer, minionprefab)
end

local function ShouldRepeatCastWorker(inst, doer)
    return _CheckMaxSanity(doer, "shadowworker")
end

local function ShouldRepeatCastProtector(inst, doer)
    return _CheckMaxSanity(doer, "shadowprotector")
end

local function WorkerSpellFn(inst, doer, pos)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    elseif not CheckMaxSanity(doer, "shadowworker") then
        return false, "NO_MAX_SANITY"
    elseif TrySpawnMinions("shadowworker", doer, pos) then
        inst.components.fueled:DoDelta(SpellCost(TUNING.WAXWELLJOURNAL_SPELL_COST.SHADOW_WORKER), doer)
        return true
    end
    return false
end

local function ProtectorSpellFn(inst, doer, pos)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    elseif not CheckMaxSanity(doer, "shadowprotector") then
        return false, "NO_MAX_SANITY"
    elseif TrySpawnMinions("shadowprotector", doer, pos) then
        inst.components.fueled:DoDelta(SpellCost(TUNING.WAXWELLJOURNAL_SPELL_COST.SHADOW_PROTECTOR), doer)
        return true
    end
    return false
end

AddPrefabPostInit("waxwelljournal", function(inst)
    if not SPELLS then
        SPELLS = inst.components.spellbook.items
        Utils.FnDecorator(SPELLS[1], "onselect", nil, function(retTab, inst)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCastWorker)
            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(WorkerSpellFn)
            end
        end)

        Utils.FnDecorator(SPELLS[2], "onselect", nil, function(retTab, inst)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCastProtector)
            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(ProtectorSpellFn)
            end
        end)
    end

    if not TheWorld.ismastersim then return end
end)
