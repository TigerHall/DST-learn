local TOOLS_L = require("tools_legion")
local assets = {
    Asset("ANIM", "anim/sand_spike.zip"),
    Asset("ANIM", "anim/sand_splash_fx.zip"),
}

-- local block_assets =
-- {
--     Asset("ANIM", "anim/sand_block.zip"),
--     Asset("ANIM", "anim/sand_splash_fx.zip"),
-- }

local SPIKE_SIZES = {
    "short",
    "med",
    "tall",
}

local RADIUS = {
    ["short"] = .2,
    ["med"] = .4,
    ["tall"] = .6,
    ["block"] = 1.1,
}

local DAMAGE_RADIUS_PADDING = .5
local GLASS_TIME = 24 * FRAMES

local function KeepTargetFn()
    return false
end

local function OnHit(inst)
    inst.AnimState:PlayAnimation(inst.animname.."_hit")
end

-- local function ChangeToObstacle(inst)
--     inst:RemoveEventCallback("animover", ChangeToObstacle)
--     local x, y, z = inst.Transform:GetWorldPosition()
--     inst.Physics:Stop()
--     inst.Physics:SetMass(0)
--     inst.Physics:ClearCollisionMask()
--     inst.Physics:CollidesWith(COLLISION.ITEMS)
--     inst.Physics:CollidesWith(COLLISION.CHARACTERS)
--     inst.Physics:CollidesWith(COLLISION.GIANTS)
--     inst.Physics:Teleport(x, 0, z)
-- end

local function SpikeLaunch(inst, launcher, basespeed, startheight, startradius)
    local x0, y0, z0 = launcher.Transform:GetWorldPosition()
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local dx, dz = x1 - x0, z1 - z0
    local dsq = dx * dx + dz * dz
    local angle
    if dsq > 0 then
        local dist = math.sqrt(dsq)
        angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
    else
        angle = 2 * PI * math.random()
    end
    local sina, cosa = math.sin(angle), math.cos(angle)
    local speed = basespeed + math.random()
    inst.Physics:Teleport(x0 + startradius * cosa, startheight, z0 + startradius * sina)
    inst.Physics:SetVel(cosa * speed, speed * 5 + math.random() * 2, sina * speed)
end

-- local COLLAPSIBLE_WORK_ACTIONS =
-- {
--     CHOP = true,
--     DIG = true,
--     HAMMER = true,
--     MINE = true,
-- }
local ONE_TAGS = { "_combat", "siv_boss_block" }
-- for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
--     table.insert(COLLAPSIBLE_TAGS, k.."_workable")
-- end
local NO_TAGS = TOOLS_L.TagsCombat3({ "player", "antlion", "groundspike", "flying", "ghost" })

local function DoBreak(inst)
    inst.task = nil
    inst.components.health:Kill()
end

local function DoDamage(inst, OnIgnite)
    inst.task = inst:DoTaskInTime(0.5+2*math.random(), DoBreak)
    inst:RemoveTag("notarget")
    -- inst.Physics:SetActive(true)
    inst:AddComponent("inspectable")
    inst.components.health:SetInvincible(false)
    inst.components.combat:SetOnHit(OnHit)

    if inst.animname == "short" then
        MakeSmallBurnable(inst, GLASS_TIME)
    else
        MakeMediumBurnable(inst, GLASS_TIME)
    end
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
    inst.components.burnable:SetOnExtinguishFn(nil)
    inst.components.burnable:SetOnBurntFn(nil)

    -- local isblock = inst.animname == "block"
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, inst.spikeradius + DAMAGE_RADIUS_PADDING, nil, NO_TAGS, ONE_TAGS)
    for _, v in ipairs(ents) do
        if v:IsValid() and v.entity:IsVisible() then
            if v.components.combat ~= nil then
                if TOOLS_L.MaybeEnemy_player(inst, v, true) and inst.components.combat:IsValidTarget(v) then
                    inst.components.combat:DoAttack(v)
                end
            elseif v.components.workable ~= nil then --这里主要用来破坏子圭突触
                if v.components.workable:CanBeWorked() then
                    v.components.workable:WorkedBy(inst, 3)
                end
            end
        end
    end

    local totoss = TheSim:FindEntities(x, 0, z, inst.spikeradius + DAMAGE_RADIUS_PADDING,
                        { "_inventoryitem" }, { "locomotor", "INLIMBO" })
    for _, v in ipairs(totoss) do
        if v.components.mine ~= nil then
            v.components.mine:Deactivate()
        end
        if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
            -- if isblock then
            --     SpikeLaunch(v, inst, 1.2, 0.6, inst.spikeradius + v:GetPhysicsRadius(0))
            -- else
                SpikeLaunch(v, inst, 0.8+inst.spikeradius, inst.spikeradius*0.4, inst.spikeradius + v:GetPhysicsRadius(0))
            -- end
        end
    end
end

local function ChangeToGlass(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    -- local glass = SpawnPrefab(inst.animname == "block" and "glassblock" or "glassspike_"..inst.animname)
    local glass = SpawnPrefab("glassspike_"..inst.animname)
    glass.Transform:SetPosition(x, y, z)
    glass:Sparkle()
end

local function PlayGlassFX(inst)
    inst.task = nil
    SpawnPrefab("glass_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnIgnite(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(GLASS_TIME - 2 * FRAMES, PlayGlassFX)
    inst:AddTag("NOCLICK")
    inst.components.health:SetInvincible(true)
    inst.components.combat:SetOnHit(nil)
    inst.components.burnable:SetOnIgniteFn(nil)
    inst.components.burnable.canlight = false
    inst.components.burnable.flammability = 0
    -- inst:RemoveEventCallback("animover", ChangeToObstacle)
    inst:ListenForEvent("animover", ChangeToGlass)
    inst.AnimState:PlayAnimation(inst.animname.."_transform")
end

local function StartSpikeAnim(inst)
    inst.task = inst:DoTaskInTime(2 * FRAMES, DoDamage, OnIgnite)
    inst:RemoveEventCallback("animover", StartSpikeAnim)
    -- inst:ListenForEvent("animover", ChangeToObstacle)
    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(0)
    inst.AnimState:PlayAnimation(inst.animname.."_pst")
    inst.SoundEmitter:PlaySound(
        "dontstarve/creatures/together/antlion/sfx/break",
        nil,
        (inst.spikesize == "short" and .6) or
        (inst.spikesize == "med" and .8) or
        nil
    )
end

local function OnDeath(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst:AddTag("NOCLICK")
    -- inst.Physics:SetActive(false)
    inst.components.combat:SetOnHit(nil)
    inst:RemoveComponent("burnable")
    inst:RemoveEventCallback("animover", StartSpikeAnim)
    -- inst:RemoveEventCallback("animover", ChangeToObstacle)
    inst:RemoveEventCallback("animover", ChangeToGlass)
    inst:ListenForEvent("animover", inst.Remove)
    inst.AnimState:PlayAnimation(inst.animname.."_break")
    inst.SoundEmitter:PlaySound(
        "dontstarve/creatures/together/antlion/sfx/break_spike",
        nil,
        (inst.spikesize == "short" and .6) or
        (inst.spikesize == "med" and .8) or
        nil
    )
end

-- local function PlayBlockSound(inst)
--     inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/block")
-- end

local function MakeSpikeFn(shape, size)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        -- inst.entity:AddPhysics()
        inst.entity:AddNetwork()

        -- if shape == "spike" then
            inst.spikesize = size or SPIKE_SIZES[math.random(#SPIKE_SIZES)]
            inst.animname = inst.spikesize
            if size == nil then
                inst:SetPrefabName("sandspike_"..inst.spikesize.."_legion")
            end
            inst:SetPrefabNameOverride("sandspike")
        -- else
        --     inst.animname = "block"
        -- end
        inst.spikeradius = RADIUS[inst.animname]

        inst.AnimState:SetBank("sand_"..shape)
        inst.AnimState:SetBuild("sand_"..shape)
        inst.AnimState:OverrideSymbol("sand_splash", "sand_splash_fx", "sand_splash")
        inst.AnimState:PlayAnimation(inst.animname.."_pre")
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        -- inst.Physics:SetMass(999999)
        -- inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        -- inst.Physics:ClearCollisionMask()
        -- inst.Physics:CollidesWith(COLLISION.ITEMS)
        -- -- inst.Physics:CollidesWith(COLLISION.CHARACTERS) --不与部分生物发生碰撞
        -- inst.Physics:CollidesWith(COLLISION.GIANTS)
        -- inst.Physics:CollidesWith(COLLISION.WORLD)
        -- inst.Physics:SetActive(false)
        -- inst.Physics:SetCapsule(inst.spikeradius, 2)

        inst:AddTag("notarget")
        -- inst:AddTag("hostile")
        inst:AddTag("groundspike")

        --For impact sound
        inst:AddTag("object")
        inst:AddTag("stone")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(TUNING.SANDSPIKE.HEALTH[string.upper(inst.animname)])
        inst.components.health:SetInvincible(true)
        inst.components.health.fire_damage_scale = 0
        inst.components.health.canheal = false
        inst.components.health.nofadeout = true

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(TUNING.SANDSPIKE.DAMAGE[string.upper(inst.animname)])
        -- inst.components.combat.playerdamagepercent = .5
        inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

        inst:ListenForEvent("animover", StartSpikeAnim)
        inst:ListenForEvent("death", OnDeath)

        -- if shape == "block" then
        --     inst:DoTaskInTime(0, PlayBlockSound)
        -- end

        inst.persists = false

        return inst
    end
end

local prefabs = {}
local ret = {}
for i, v in ipairs(SPIKE_SIZES) do
    local name = "sandspike_"..v.."_legion"
    table.insert(prefabs, name)
    table.insert(ret, Prefab(name, MakeSpikeFn("spike", v), assets, { "glass_fx", "glassspike_"..v }))
end
table.insert(ret, Prefab("sandspike_legion", MakeSpikeFn("spike"), assets, prefabs))
prefabs = nil

-- table.insert(ret, Prefab("sandblock", MakeSpikeFn("block"), block_assets, { "glass_fx", "glassblock" }))

return unpack(ret)
