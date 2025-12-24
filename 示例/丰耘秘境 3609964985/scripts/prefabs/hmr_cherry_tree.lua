local prefs = {}

local tree_assets =
{
    Asset("ANIM", "anim/hmr_cherry_tree.zip"),
}

SetSharedLootTable("hmr_cherry_tree_s1",
{
    {'twigs',                   1.00},
    {'twigs',                   0.50},
})

SetSharedLootTable("hmr_cherry_tree_s2",
{
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     0.50},
})

SetSharedLootTable("hmr_cherry_tree_s3",
{
    {'hmr_cherry_tree_flower',  1.00},
    {'hmr_cherry_tree_flower',  1.00},
    {'hmr_cherry_tree_flower',  1.00},
    {'hmr_cherry_tree_flower',  0.20},
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     0.50},
})

SetSharedLootTable("hmr_cherry_tree_s4",
{
    {'hmr_cherry_fruit',        1.00},
    {'hmr_cherry_tree_seeds',   1.00},
    {'hmr_cherry_tree_seeds',   0.50},
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     1.00},
    {'log',                     0.50},
})


local anims = {
    s1 = {
        plant = "s1_plant",
        idle1 = "s1_idle1",
        idle2 = "s1_idle2",
        dug = "s1_dug",
        grow = "s1_grow",
    },
    s2 = {
        idle1 = "s2_idle1",
        idle2 = "s2_idle2",
        chop = "s2_chop",
        grow = "s2_grow",
        growleaves = "s2_growleaves",
        fallright = "s2_fallright",
        stump = "s2_stump",
        burnt_idle = "s2_burnt_idle",
        burnt_chop = "s2_burnt_chop",
        burnt_chop_idle = "s2_burnt_chop_idle",
        burnt_stump = "s2_burnt_stump",
    },
    s3 = {
        idle1 = "s3_idle1",
        idle2 = "s3_idle2",
        chop = "s3_chop",
        grow = "s3_grow",
        pickflower = "s3_pickflower",
        fallright = "s3_fallright",
        stump = "s3_stump",
        burnt_idle = "s3_burnt_idle",
        burnt_chop = "s3_burnt_chop",
        burnt_chop_idle = "s3_burnt_chop_idle",
        burnt_stump = "s3_burnt_stump",
    },
    s4 = {
        idle1 = "s4_idle1",
        idle2 = "s4_idle2",
        chop = "s4_chop",
        grow = "s4_grow",
        growfruit = "s4_growfruit",
        pickfruit = "s4_pickfruit",
        silkout = "s4_silkout",
        silkdisappear = "s4_silkdisappear",
        fallright = "s4_fallright",
        stump = "s3_stump",
        burnt_idle = "s3_burnt_idle",
        burnt_chop = "s3_burnt_chop",
        burnt_chop_idle = "s3_burnt_chop_idle",
        burnt_stump = "s3_burnt_stump",
    },
}

local function HideFruit(inst)
    for i = 0, 4 do
        inst.AnimState:Hide("fruit"..i)
    end
end

local function SetFruitAnim(inst)
    HideFruit(inst)
    for _, pos in ipairs(inst.fruits_pos or {}) do
        inst.AnimState:Show("fruit"..pos)
    end
end

local function dig_up_stump(inst, chopper)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end
    inst.AnimState:PlayAnimation(inst.anims.burnt_chop)
    RemovePhysicsColliders(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.pineconetask ~= nil then
        inst.pineconetask:Cancel()
        inst.pineconetask = nil
    end
end

local function OnBurnt(inst, immediate)
    if inst.components.growable ~= nil and inst.components.growable:GetStage() == 1 then
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:SpawnLootPrefab("ash")
        end
        inst:Remove()
        return
    end

    local function changes()
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        inst:RemoveComponent("hauntable")
        inst:RemoveComponent("petrifiable")
        inst:RemoveTag("shelter")
        MakeHauntableWork(inst)

        inst.components.lootdropper:SetLoot({})
        inst.components.lootdropper:AddChanceLoot("pinecone", 0.1)

        if inst.components.workable then
            inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_BURNT_CHOPS)
            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
        end
    end

    if immediate then
        changes()
    else
        inst:DoTaskInTime(.5, changes)
    end
    inst.AnimState:PlayAnimation(inst.anims.burnt_idle, true)

    --inst.AnimState:SetRayTestOnBB(true)
    inst:AddTag("burnt")

    inst.MiniMapEntity:SetIcon("evergreen_burnt.png")

    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.HMR_CHERRY_TREE_REGROWTH.DEAD_DECAY_TIME, TUNING.HMR_CHERRY_TREE_REGROWTH.DEAD_DECAY_TIME*0.5))
    end
end

local function DoRebirthLoot(inst)
    local rebirth_loot = {loot="twigs", max=2}
    if rebirth_loot ~= nil then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 8)
        local numloot = 0
        for i,ent in ipairs(ents) do
            if ent.prefab == rebirth_loot.loot then
                numloot = numloot + 1
            end
        end
        local prob = 1-(numloot/rebirth_loot.max)
        if math.random() < prob then
            inst:DoTaskInTime(17*FRAMES, function()
                inst.components.lootdropper:SpawnLootPrefab(rebirth_loot.loot)
            end)
        end
        inst._lastrebirth = GetTime()
    end
end

local function GrowS1(inst)
    local new = ReplacePrefab(inst, "hmr_cherry_tree_s2")
    new.AnimState:PlayAnimation(anims.s1.grow)
    new.AnimState:PushAnimation(anims.s1.idle2, true)
    new.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    -- DoRebirthLoot(new)
end

local function SetS1(inst)
    inst.anims = anims.s1
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_S1_DIGS)
    end
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_tree_s1")
    inst.AnimState:PlayAnimation(inst.anims.idle2, true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:AddTag("shelter")
    inst.MiniMapEntity:SetIcon("hmr_cherry_tree_s1.tex")
end

local function GrowS2(inst)
    -- 这里引用到的所有数据已经是阶段2的了
    local new = ReplacePrefab(inst, "hmr_cherry_tree_s2")
    new.AnimState:PlayAnimation(anims.s1.grow)
    new.AnimState:PushAnimation(anims.s2.growleaves)
    new.AnimState:PushAnimation(anims.s2.idle2, true)
    new.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    --DoRebirthLoot(new)
end

local function SetS2(inst)
    inst.anims = anims.s2
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_S2_CHOPS)
    end
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_tree_s2")
    inst.AnimState:PlayAnimation(inst.anims.idle2, true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:AddTag("shelter")
    inst.MiniMapEntity:SetIcon("hmr_cherry_tree_s2.tex")
end

local function GrowS3(inst)
    local new = ReplacePrefab(inst, "hmr_cherry_tree_s3")
    new.AnimState:PlayAnimation(anims.s2.grow)
    new.AnimState:PushAnimation(anims.s3.idle2, true)
    new.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function SetS3(inst)
    inst.anims = anims.s3
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_S3_CHOPS)
    end
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_tree_s3")
    inst.AnimState:PlayAnimation(inst.anims.idle2, true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:AddTag("shelter")
    inst.MiniMapEntity:SetIcon("hmr_cherry_tree_s2.tex")
end

local function GrowS4(inst)
    local new = ReplacePrefab(inst, "hmr_cherry_tree_s4")
    new.AnimState:PlayAnimation(anims.s3.grow)
    new.AnimState:PushAnimation(anims.s4.idle2, true)
    new.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function SetS4(inst)
    inst.anims = anims.s4
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_S4_CHOPS)
    end
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_tree_s4")
    inst.AnimState:PlayAnimation(inst.anims.idle2, true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:AddTag("shelter")
    inst.MiniMapEntity:SetIcon("hmr_cherry_tree_s4.tex")
end

local function inspect_tree(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("stump") and "CHOPPED")
        or nil
end

local day_time = TUNING.TOTAL_DAY_TIME
local GROW_TIME = {
    {base=1.5*day_time, random=0.5*day_time},   --s1
    {base=5*day_time, random=2*day_time},       --s2
    {base=5*day_time, random=2*day_time},       --s3
    {base=6*day_time, random=2.5*day_time}      --s4
}
local STAGES = {
    {
        name = "s1",
        time = function(inst) return GetRandomWithVariance(GROW_TIME[1].base, GROW_TIME[1].random) end,
        fn = SetS1,
        -- growfn = GrowS1,
        leifscale = .7,
    },
    {
        name = "s2",
        time = function(inst) return GetRandomWithVariance(GROW_TIME[2].base, GROW_TIME[2].random) end,
        fn = SetS2,
        growfn = GrowS2,
        leifscale = 1,
    },
    {
        name = "s3",
        time = function(inst) return GetRandomWithVariance(GROW_TIME[3].base, GROW_TIME[3].random) end,
        fn = SetS3,
        growfn = GrowS3,
        leifscale = 1.25,
    },
    {
        name = "s4",
        time = function(inst) return GetRandomWithVariance(GROW_TIME[4].base, GROW_TIME[4].random) end,
        fn = SetS4,
        growfn = GrowS4,
    },
}

local function WakeUpLeif(ent)
    ent.components.sleeper:WakeUp()
end

local LEIF_TAGS = { "leif" }
local function chop_tree(inst, chopper, chopsleft, numchops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)
    inst.AnimState:PushAnimation(inst.anims.idle1, true)

    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("pine_needles_chop").Transform:SetPosition(x, y + math.random() * 2, z)

    --tell any nearby leifs to wake up
    -- local ents = TheSim:FindEntities(x, y, z, TUNING.LEIF_REAWAKEN_RADIUS, LEIF_TAGS)
    -- for i, v in ipairs(ents) do
    --     if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
    --         v:DoTaskInTime(math.random(), WakeUpLeif)
    --     end
    --     v.components.combat:SuggestTarget(chopper)
    -- end
end

local function chop_down_tree_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03,
        inst.components.growable ~= nil and
        inst.components.growable.stage > 2 and .5 or .25,
        inst, 6)
end

local function find_leif_spawn_target(item)
    return not item.noleif
        and item.components.growable ~= nil
        and item.components.growable.stage <= 3
end

local function spawn_leif(target)
    --assert(GetBuild(target).leif ~= nil)
    local leif = SpawnPrefab(GetBuild(target).leif)
    leif.AnimState:SetMultColour(target.AnimState:GetMultColour())
    leif:SetLeifScale(target.leifscale)

    if target.chopper ~= nil then
        leif.components.combat:SuggestTarget(target.chopper)
    end

    local x, y, z = target.Transform:GetWorldPosition()
    target:Remove()

    leif.Transform:SetPosition(x, y, z)
    leif.sg:GoToState("spawn")
end

local function make_stump(inst)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")
    inst:RemoveComponent("hauntable")
    MakeHauntableIgnite(inst)
    if inst.components.pickable ~= nil then
        inst:RemoveComponent("pickable")
    end

    RemovePhysicsColliders(inst)

    inst:AddTag("stump")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst.MiniMapEntity:SetIcon("evergreen_stump.png")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_STUMP_DIGS)

    if inst.components.timer and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.HMR_CHERRY_TREE_REGROWTH.DEAD_DECAY_TIME, TUNING.HMR_CHERRY_TREE_REGROWTH.DEAD_DECAY_TIME*0.5))
    end
end

local function TransformIntoLeif(inst, chopper)
    inst.noleif = true
    inst.leifscale = GetGrowthStages(inst)[inst.components.growable.stage].leifscale or 1
    inst.chopper = chopper
    inst:DoTaskInTime(1 + math.random() * 3, spawn_leif)
end

local LEIFTARGET_MUST_TAGS = { "evergreens", "tree" }
local LEIFTARGET_CANT_TAGS = { "leif", "stump", "burnt" }
local function chop_down_tree(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
    local pt = inst:GetPosition()

    -- 树木倒下方向
    local he_right = true
    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end
    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallright)-- 暂时用向右倒
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        local stage = inst.components.growable and inst.components.growable:GetStage()
        if stage == 3 then
            inst.components.lootdropper:SpawnLootPrefab("hmr_cherry_tree_flower")
        elseif stage == 4 then
            if math.random() < 0.6 then
                inst.components.lootdropper:SpawnLootPrefab("hmr_cherry_tree_seeds")
            else
                inst.components.lootdropper:SpawnLootPrefab("hmr_cherry_tree_fruit")
            end
        end
    end

    -- 树倒后摇晃摄像机
    inst:DoTaskInTime(0.4, chop_down_tree_shake)

    -- 创建树墩
    make_stump(inst)
    inst.AnimState:PushAnimation(inst.anims.stump, false)

    -- 生成树精
    if false then
        -- 计算玩家存活的天数
        local days_survived = chopper.components.age ~= nil and chopper.components.age:GetAgeInDays() or TheWorld.state.cycles
        -- 检查玩家存活的天数是否达到 Leif 出现的最小天数
        if days_survived >= TUNING.LEIF_MIN_DAY then
            -- 计算 Leif 出现的概率
            local chance = TUNING.LEIF_PERCENT_CHANCE
            -- 如果砍树者是海狸，调整 Leif 出现的概率
            if chopper:HasTag("beaver") then
                chance = chance * TUNING.BEAVER_LEIF_CHANCE_MOD
            -- 如果砍树者是伐木工，调整 Leif 出现的概率
            elseif chopper:HasTag("woodcutter") then
                chance = chance * TUNING.WOODCUTTER_LEIF_CHANCE_MOD
            end
            -- 根据概率决定是否生成 Leif
            if math.random() < chance then
                -- 根据存活天数决定生成 Leif 的数量
                for k = 1, (days_survived <= 30 and 1) or math.random(days_survived <= 80 and 2 or 3) do
                    -- 查找 Leif 出现的目标位置
                    local target = FindEntity(inst, TUNING.LEIF_MAXSPAWNDIST, find_leif_spawn_target, LEIFTARGET_MUST_TAGS, LEIFTARGET_CANT_TAGS)
                    -- 如果找到目标位置，将其转换为 Leif
                    if target ~= nil then
                        target:TransformIntoLeif(chopper)
                    end
                end
            end
        end
    end
end


local function onpineconetask(inst)
    local pt = inst:GetPosition()
    local angle = math.random() * TWOPI
    pt.x = pt.x + math.cos(angle)
    pt.z = pt.z + math.sin(angle)
    --inst.components.lootdropper:DropLoot(pt)
    inst.pineconetask = nil
    inst.burntcone = true
end

local function tree_burnt(inst)
    OnBurnt(inst)
    if not inst.burntcone then
        if inst.pineconetask ~= nil then
            inst.pineconetask:Cancel()
        end
        inst.pineconetask = inst:DoTaskInTime(10, onpineconetask)
    end
end

local function handler_growfromseed(inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("s1_grow")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end

    if inst:HasTag("stump") then
        data.stump = true
    end

    if inst._lastrebirth ~= nil then
        data.lastrebirth = inst._lastrebirth - GetTime()
    end

    data.burntcone = inst.burntcone
end

local function onload(inst, data)
    if data ~= nil then
        if data.stump then
            make_stump(inst)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            if data.burnt or inst:HasTag("burnt") then
                DefaultBurntFn(inst)
            end
        elseif data.burnt and not inst:HasTag("burnt") then
            OnBurnt(inst, true)
        end

        if not inst:IsValid() then
            return
        end

        if data.lastrebirth ~= nil then
            inst._lastrebirth = data.lastrebirth + GetTime()
        end

        inst.burntcone = data.burntcone
    end
end

local function OnEntitySleep(inst)
    local doBurnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning()
    if doBurnt and inst:HasTag("stump") then
        DefaultBurntFn(inst)
    else
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("inspectable")
        if doBurnt then
            inst:RemoveComponent("growable")
            inst:RemoveComponent("petrifiable")
            inst:AddTag("burnt")
        end
    end
end

local function OnEntityWake(inst)
    if inst:HasTag("burnt") then
        tree_burnt(inst)
    else
        local isstump = inst:HasTag("stump")

        if not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
            if inst.components.burnable == nil then
                if isstump then
                    MakeSmallBurnable(inst)
                else
                    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
                    inst.components.burnable:SetFXLevel(5)
                    inst.components.burnable:SetOnBurntFn(tree_burnt)
                end
            end

            if inst.components.propagator == nil then
                if isstump then
                    MakeSmallPropagator(inst)
                else
                    MakeMediumPropagator(inst)
                end
            end
        end

        if not isstump then
            local growthcycletime = inst._lastrebirth
            for i, data in ipairs(TUNING.HMR_CHERRY_TREE_REGROWTH) do
                growthcycletime = growthcycletime + data.base
            end

            if growthcycletime < GetTime() then
                --DoRebirthLoot(inst)
            end
        end
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end


local REMOVABLE =
{
    ["log"] = true,
    ["pinecone"] = true,
    ["twigs"] = true,
    ["twiggy_nut"] = true,
    ["charcoal"] = true,
}

local DECAYREMOVE_MUST_TAGS = { "_inventoryitem" }
local DECAYREMOVE_CANT_TAGS = { "INLIMBO", "fire" }
local function OnTimerDone(inst, data)
    if data.name == "decay" then
        local x, y, z = inst.Transform:GetWorldPosition()
        if inst:IsAsleep() then
            -- before we disappear, clean up any crap left on the ground
            -- too many objects is as bad for server health as too few!
            local leftone = false
            for i, v in ipairs(TheSim:FindEntities(x, y, z, 6, DECAYREMOVE_MUST_TAGS, DECAYREMOVE_CANT_TAGS)) do
                if REMOVABLE[v.prefab] then
                    if leftone then
                        v:Remove()
                    else
                        leftone = true
                    end
                end
            end
        else
            SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
        end
        inst:Remove()
    end
end

local function onhauntwork(inst, haunter)
    if inst.components.workable ~= nil and math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.workable:WorkedBy(haunter, 1)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function onhauntevergreen(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE and
        find_leif_spawn_target(inst) and
        not (inst:HasTag("burnt") or inst:HasTag("stump")) then

        inst.leifscale = GetGrowthStages(inst)[inst.components.growable.stage].leifscale or 1
        spawn_leif(inst)

        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        inst.components.hauntable.cooldown_on_successful_haunt = false
        return true
    end
    return onhauntwork(inst, haunter)
end

local function MakeTree(name, data)
    local function fn()
        local inst = CreateEntity()

        if data.stage == 0 then
            if data.stump or data.burnt then
                data.stage = math.random(2, 4)
            else
                data.stage = math.random(1, 4)
            end
        end

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        inst.entity:AddDynamicShadow()

        inst.DynamicShadow:SetSize(data.stage, data.stage)

        MakeObstaclePhysics(inst, .25)

		inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2) --seed/planted_tree deployspacing/2

        inst.MiniMapEntity:SetIcon("hmr_cherry_tree.tex")

        inst:AddTag("shelter")
        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("hmr_cherry")
        inst:AddTag("hmr_cherry_tree")

        inst.MiniMapEntity:SetPriority(-1)

        inst.AnimState:SetBuild("hmr_cherry_tree")
        inst.AnimState:SetBank("hmr_cherry_tree")

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.anims = anims["s"..data.stage]

        local scale = 0.9 + math.random() * 0.2
        inst.AnimState:SetScale(scale, scale, scale)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        inst:AddComponent("lootdropper")
        if not data.stump and not data.burnt then
            inst.components.lootdropper:SetChanceLootTable("hmr_cherry_tree_s"..data.stage)
        end

        inst:AddComponent("growable")
        inst.components.growable.stages = STAGES
        inst.components.growable:SetStage(data.stage)
        inst.components.growable.loopstages = true
        inst.components.growable.loopstages_start = 3
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        inst.growfromseed = handler_growfromseed

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        inst:AddComponent("hauntable")
        -- inst.components.hauntable:SetOnHauntFn(onhauntevergreen)

        inst.OnSave = function(inst, data)
            onsave(inst, data)
            if data.onsave ~= nil then
                data.onsave(inst, data)
            end
        end
        inst.OnLoad = function(inst, data)
            onload(inst, data)
            if data.onload ~= nil then
                data.onload(inst, data)
            end
        end

        MakeSnowCovered(inst)

        MakeWaxablePlant(inst)

        inst._lastrebirth = 0
        for i,time in ipairs(TUNING.HMR_CHERRY_TREE_REGROWTH) do
            if i == inst.components.growable.stage then
                break
            end
            inst._lastrebirth = inst._lastrebirth - time.base
        end

        if data.stage == 1 then
            MakeSmallBurnable(inst)
            MakeSmallPropagator(inst)
        elseif data.stage == 2 then
            MakeMediumBurnable(inst)
            MakeMediumPropagator(inst)
        elseif data.stage >= 3 then
            MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
            inst.components.burnable:SetFXLevel(5)
            MakeLargePropagator(inst)
        end
        inst.components.burnable:SetOnBurntFn(tree_burnt)

        if data.stump then
            RemovePhysicsColliders(inst)
            inst:AddTag("stump")
            inst:RemoveTag("shelter")

            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)

            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)

            inst:RemoveComponent("growable")

            inst:RemoveComponent("pickable")

            inst:RemoveComponent("workable")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_TREE_STUMP_DIGS)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            inst.MiniMapEntity:SetIcon("evergreen_stump.png")
        elseif data.burnt then
            OnBurnt(inst)
            inst.AnimState:PlayAnimation(inst.anims.burnt_idle, true)
        else
            inst.AnimState:PlayAnimation(inst.anims.idle2, true)
        end
        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, tree_assets))
end


MakeTree("hmr_cherry_tree", {
    stage = 0,
})

MakeTree("hmr_cherry_tree_s1", {
    stage = 1,
    master_postinit = function(inst)
        local function OnWorkFinished(inst, worker)
            inst.AnimState:PlayAnimation(inst.anims.dug)
            inst.components.lootdropper:DropLoot()
            local anim_length = inst.AnimState:GetCurrentAnimationLength()
            inst:DoTaskInTime(anim_length, function()
                inst:Remove()
            end)
        end
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(OnWorkFinished)
    end,
})

MakeTree("hmr_cherry_tree_s2", {
    stage = 2,
})

MakeTree("hmr_cherry_tree_s3", {
    stage = 3,
    master_postinit = function(inst)
        local function onpickedfn(inst, picker)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
            inst.AnimState:PlayAnimation(inst.anims.idle2, true)

            local tx, ty, tz = inst.Transform:GetWorldPosition()
            for i = 1, math.random(1, 3) do
                local theta = math.random() * 2 * PI
                local r = 2 + math.random() * 2
                local fruit = SpawnPrefab("hmr_cherry_tree_flower")
                fruit.Transform:SetPosition(tx + math.cos(theta) * r, ty + 4 + math.random(), tz - math.sin(theta) * r)
            end

            if picker ~= nil then
                local px, py, pz = picker.Transform:GetWorldPosition()
                TheWorld:PushEvent("ms_forcenaughtiness", { player = picker, numspawns = math.clamp(#FindPlayersInRange(px, py, pz, 10, true), 1, 3) })
            end
        end
        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil, TUNING.HMR_CHERRYY_TREE_S3_PICK_RENGE)--total_day_time*3
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
        inst.components.pickable.onpickedfn = onpickedfn

        local function CancelPicking(inst, doer, nosound)
            local cb = inst._pickers and inst._pickers[doer] or nil
            if cb == nil then
                return
            end

            inst:RemoveEventCallback("newstate", cb, doer)
            inst:RemoveEventCallback("onremove", cb, doer)
            inst._pickers[doer] = nil

            if next(inst._pickers) == nil then
                inst.AnimState:PlayAnimation(inst.anims.idle2, true)
            end
        end

        local function OnStartPicking(inst, doer)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
            inst.AnimState:PlayAnimation(inst.anims.pickflower, true)

            local oldpickingstate = doer.sg.currentstate.name
            local cb = function(doer, data)
                if not (data and data.statename == oldpickingstate) then
                    inst:CancelPicking(doer)
                end
            end

            inst._pickers[doer] = cb

            inst:ListenForEvent("newstate", cb, doer)
            inst:ListenForEvent("onremove", cb, doer)
        end
        inst._pickers = {}
        inst.OnStartPicking = OnStartPicking
        inst.CancelPicking = CancelPicking
        inst:ListenForEvent("startlongaction", inst.OnStartPicking)
    end,
})

MakeTree("hmr_cherry_tree_s4", {
    stage = 4,
    master_postinit = function(inst)
        inst.fruits_pos = {}
        local function onregenfn(inst)
            local function ChooseFruit()
                local fruit_count = math.random(2, 5)
                local fruit_pos = {0, 1, 2, 3, 4}
                local result_pos = {}
                for i = 1, fruit_count do
                    local pos = fruit_pos[math.random(1, #fruit_pos)]
                    table.remove(fruit_pos, pos)
                    table.insert(result_pos, pos)
                end
                return result_pos
            end

            inst.fruits_pos = ChooseFruit()
            for _, pos in ipairs(inst.fruits_pos) do
                inst.AnimState:Show("fruit"..pos)
            end

            inst.AnimState:PlayAnimation(inst.anims.growfruit)
            inst.AnimState:PushAnimation(inst.anims.idle2, true)
        end

        local function makeemptyfn(inst)
            HideFruit(inst)
        end

        local function onpickedfn(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
            inst.AnimState:PlayAnimation(inst.anims.pickfruit)
            inst.AnimState:PushAnimation(inst.anims.idle2, true)
            inst:DoTaskInTime(FRAMES * 20, function()
                HideFruit(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                for i, pos in ipairs(inst.fruits_pos) do-- 现在掉落的位置根生成的位置对应不上，想想办法...
                    local theta = math.random() * 2 * PI
                    local r = 2 + math.random() * 2
                    local fruit = SpawnPrefab("hmr_cherry_tree_fruit")
                    fruit.Transform:SetPosition(x + math.cos(theta) * r, y + 4 + math.random(), z - math.sin(theta) * r)
                end
                inst.fruits_pos = {}
            end)
        end
        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil, TUNING.HMR_CHERRYY_TREE_S4_PICK_RENGE)--total_day_time*3
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        -- inst.components.pickable.max_cycles = 20--20
        -- inst.components.pickable.cycles_left = 20--20
        inst.components.pickable:MakeEmpty()
    end,
    onsave = function(inst, data)
        data.fruits_pos = inst.fruits_pos
    end,
    onload = function(inst, data)
        if data.fruits_pos ~= nil then
            inst.fruits_pos = data.fruits_pos
        end
        SetFruitAnim()
    end,
})

MakeTree("hmr_cherry_tree_burnt", {
    stage = 0,
    burnt = true,
})

MakeTree("hmr_cherry_tree_stump", {
    stage = 0,
    stump = true,
})

----------------------------------------------------------------------------
---[[产品]]
----------------------------------------------------------------------------
local function MakeProduct(name, data)
    local product_assets = {
        Asset("ANIM", "anim/hmr_cherry_tree_products.zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
    }
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("product")

        inst.AnimState:SetBank("hmr_cherry_tree_products")
        inst.AnimState:SetBuild("hmr_cherry_tree_products")
        inst.AnimState:PlayAnimation(string.sub(name, #"hmr_cherry_tree_" + 1), true)

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "small", 0.05, 1.0)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        local color = 0.9 + math.random() * 0.1
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
        MakeSmallPropagator(inst)

        MakeHauntableIgnite(inst)

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, product_assets))
end

MakeProduct("hmr_cherry_tree_seeds", {
    master_postinit = function(inst)
        local function OnDeploy(inst, pt, deployer)
            local tree = SpawnPrefab("hmr_cherry_tree_s1")
            if tree ~= nil then
                tree.Transform:SetPosition(pt:Get())
                inst.components.stackable:Get():Remove()

                tree.AnimState:PlayAnimation(tree.anims.plant)
                tree.AnimState:PushAnimation(tree.anims.idle2, true)

                if deployer ~= nil and deployer.SoundEmitter ~= nil then
                    deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
                end
            end
        end
        inst:AddComponent("deployable")
        --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
        inst.components.deployable.ondeploy = OnDeploy
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
    end,
})
table.insert(prefs, MakePlacer("hmr_cherry_tree_seeds_placer", "hmr_cherry_tree", "hmr_cherry_tree", "s1_idle2"))

MakeProduct("hmr_cherry_tree_fruit", {
    master_postinit = function(inst)
        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 2
        inst.components.edible.hungervalue = 5
        inst.components.edible.sanityvalue = 10
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible.secondaryfoodtype = FOODTYPE.BERRY

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"
    end,
})

MakeProduct("hmr_cherry_tree_flower", {
    common_postinit = function(inst)
        inst.Physics:SetMass(0.5)
        inst.Physics:SetDamping(0.5)
    end,
    master_postinit = function(inst)
        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = 1
        inst.components.edible.sanityvalue = 5
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible.secondaryfoodtype = FOODTYPE.BERRY

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"
    end,
})

return unpack(prefs)