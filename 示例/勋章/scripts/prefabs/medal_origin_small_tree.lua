local assets =
{
    Asset("ANIM", "anim/oceantree_short.zip"),
    Asset("ANIM", "anim/oceantree_normal.zip"),
    Asset("ANIM", "anim/oceantree_tall.zip"),
    Asset("ANIM", "anim/medal_origin_tree_tall_jammed.zip"),
    Asset("ANIM", "anim/medal_origin_tree_short.zip"),
    Asset("ANIM", "anim/medal_origin_tree_normal.zip"),
    Asset("ANIM", "anim/medal_origin_tree_tall.zip"),
    
    Asset("SOUND", "sound/forest.fsb"),
    
	Asset("ATLAS", "minimap/medal_origin_small_tree.xml" ),
	Asset("ATLAS", "minimap/medal_origin_small_tree_stump.xml" ),
}

local prefabs =
{
    "log",
    "pine_needles_chop",
    "small_puff",
    "oceantreenut",
    "collapse_small",
    "oceantree_leaf_fx_chop",
}

local tree_data =
{
    prefab_name="medal_origin_small_tree",
    normal_loot = {"log", "log"},
    short_loot = {"log"},
    tall_loot = {"log", "log", "log"},
    chop_camshake_delay=0.4,
}

local anims = {
    idle="idle",
    sway1="sway1_loop",
    sway2="sway2_loop",
    chop="chop",
    fallleft="fallleft",
    fallright="fallright",
    stump="stump",
}

local STAGES_TO_SUPERTALL = TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_STAGES_TO_SUPERTALL--变成巨大需要的花朵数量

local function IsEnriched(inst)
    return inst.components.timer ~= nil and inst.components.timer:TimerExists("enriched_cooldown")
end

local function dig_up_stump(inst, chopper)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function PushSway(inst)
    inst.AnimState:PushAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function Sway(inst)
    inst.AnimState:PlayAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function Sprout(inst)
    inst.AnimState:PlayAnimation("grow_seed_to_short")

    PushSway(inst)
end

--生长阶段表
local growth_stages =
{
    {
        name = "short",
        time = function(inst) return GetRandomWithVariance(TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.base, TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.random) end,
        fn = function(inst)
            inst.AnimState:SetBank("oceantree_short")
            inst.AnimState:SetBuild("medal_origin_tree_short")
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_SMALL)
            end
            inst.components.lootdropper:SetLoot(tree_data.short_loot)
            Sway(inst)
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_tall_to_short")
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            PushSway(inst)
        end,
    },
    {
        name = "normal",
        time = function(inst) return GetRandomWithVariance(TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.base, TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.random) end,
        fn = function(inst)
            inst.AnimState:SetBank("oceantree_normal")
            inst.AnimState:SetBuild("medal_origin_tree_normal")
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_NORMAL)
            end
            inst.components.lootdropper:SetLoot(tree_data.normal_loot)
            Sway(inst)
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_short_to_normal")
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            PushSway(inst)
        end,
    },
    {
        name = "tall",
        time = function(inst) return GetRandomWithVariance(TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.base, TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.random) end,
        fn = function(inst)
            inst.AnimState:SetBank("oceantree_tall")
            inst.AnimState:SetBuild("medal_origin_tree_tall")
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_TALL)
            end
            inst.components.lootdropper:SetLoot(tree_data.tall_loot)
            Sway(inst)
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_normal_to_tall")
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            PushSway(inst)
        end,
    },
}

--砍伐
local function chop_tree(inst, chopper, chopsleft, numchops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasAnyTag("beaver", "boat") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)
    inst.AnimState:PushAnimation(inst.anims.sway1, true)
    
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("oceantree_leaf_fx_chop").Transform:SetPosition(x, y + math.random() * 2, z)
end
--变成树桩
local function make_stump(inst)
    inst:RemoveComponent("workable")
    inst:RemoveComponent("timer")
    inst:RemoveTag("shelter")
    inst:RemoveComponent("hauntable")
    -- MakeHauntableIgnite(inst)

    local x, _, z = inst.Transform:GetWorldPosition()
    if not TheWorld.Map:IsOceanAtPoint(x, 0, z) then
        RemovePhysicsColliders(inst)
    end

    inst:AddTag("stump")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst:RemoveEventCallback("timerdone", inst.OnTimerDone)

    inst.MiniMapEntity:SetIcon("medal_origin_small_tree_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    inst.AnimState:PlayAnimation(inst.anims.stump)
end
--砍倒
local function chop_down_tree(inst, chopper)
    local pt = inst:GetPosition()

    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    local falling_tree = SpawnPrefab("oceantree_falling")
    falling_tree.Transform:SetPosition(inst:GetPosition():Get())
    if  inst.buds_used then
        for i,bud in ipairs(inst.buds_used) do
            falling_tree.AnimState:Show("tree_bud"..bud)
        end
    end

    local stage = inst.components.growable and inst.components.growable.stage or 3
    local bank = "oceantree_"..growth_stages[stage].name

    if he_right then
        falling_tree:start_falling_fn(inst.AnimState:GetBuild(), bank, true, stage, TheCamera:GetRightVec())
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        falling_tree:start_falling_fn(inst.AnimState:GetBuild(), bank, false, stage, TheCamera:GetRightVec())
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    if chopper ~= nil and chopper.components.boatphysics ~= nil then
        inst.components.lootdropper:SpawnLootPrefab("log")
        inst:Remove()
    else
        make_stump(inst)
        
    end
end

local DAMAGE_SCALE = 0.5
local function OnCollide(inst, data)
    local boat_physics = data.other.components.boatphysics
    if boat_physics ~= nil then
        local hit_velocity = math.floor(math.abs(boat_physics:GetVelocity() * data.hit_dot_velocity) * DAMAGE_SCALE / boat_physics.max_velocity + 0.5)
        if inst:HasTag("stump") then
            if hit_velocity >= 0.75 then
                inst.components.lootdropper:SpawnLootPrefab("log")
                SpawnPrefab("collapse_small").Transform:SetPosition(inst:GetPosition():Get())
                inst:Remove()
            end
        elseif inst.components.workable ~= nil then
            inst.boat_collided = true -- NOTES(JBK): Hack workaround a physics callback calling another Physics mask clearing function will be a race condition if the physics engine crashes.
            inst.components.workable:WorkedBy(data.other, hit_velocity * TUNING.OCEANTREE_CHOPS_NORMAL)
            inst.boat_collided = nil
        end
    end
end
--进入施肥状态
local function MakeEnriched(inst)
    inst:DoTaskInTime(15*FRAMES, function() inst.AnimState:SetBuild("medal_origin_tree_tall_jammed") end)
    -- inst:AddTag("no_force_grow")
    inst:AddTag("no_medal_grow")

    inst.AnimState:PlayAnimation("gooped")
    PushSway(inst)

    if inst.components.growable ~= nil then
        inst:RemoveComponent("growable")
    end

    inst.no_grow = true
end
--显示花朵
local function showbuds(inst)
    for i,num in ipairs(inst.buds_used) do
        inst.AnimState:Show("tree_bud"..num)
    end
end
--解除施肥状态,花朵+1
local function MakeNotEnriched(inst)

    inst:DoTaskInTime(15*FRAMES, function() inst.AnimState:SetBuild("medal_origin_tree_tall") end)
    inst.AnimState:PlayAnimation("ungooped")
    PushSway(inst)

    local budscount = #inst.buds
    if budscount > 0 then -- NOTES(JBK): In case STAGES_TO_SUPERTALL gets changed we do not want to exceed the 7 buds the tree has.
        local random = math.random(1, budscount)
        table.insert(inst.buds_used, inst.buds[random])
        table.remove(inst.buds, random)
    end

    showbuds(inst)
        
    -- inst:RemoveTag("no_force_grow")
    inst:RemoveTag("no_medal_grow")
end
--成长为本源之树
local function SpawnOriginTree(inst)
    local x, _, z = inst.Transform:GetWorldPosition()

    local pillar = SpawnPrefab("medal_origin_tree")
    pillar.Transform:SetPosition(x, 0, z)

    if pillar.sproutfn ~= nil then
        pillar:sproutfn()
    end

    inst:Remove()

    return pillar -- Mods.
end
--肥料定时器结束,吸收肥料
local function OnTimerDone(inst, data)
    if data.name ~= "enriched_cooldown" then return end
    --花朵数量没达到最大，继续开花
    if inst.supertall_growth_progress < STAGES_TO_SUPERTALL then
        MakeNotEnriched(inst)
        return
    end
    --花朵数量达到上限，长成巨树
    inst:RemoveComponent("workable")

    if inst:IsAsleep() then
        SpawnOriginTree(inst)
    else
        inst.AnimState:PlayAnimation("grow_tall_to_pillar", false)
        inst.SoundEmitter:PlaySound("waterlogged2/common/watertree_pillar/grow")

        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + FRAMES, SpawnOriginTree)
    end
end
--本源精华施肥
local function OnTreeGrowthOriginEssence(inst, item)
    --最大形态,进入施肥状态
    if (inst.supertall_growth_progress ~= nil and inst.supertall_growth_progress > 0) or inst.components.growable.stage == 3 then
        inst.supertall_growth_progress = (inst.supertall_growth_progress or 0) + 1
        MakeEnriched(inst)

        if inst.components.timer ~= nil then
            inst.components.timer:StartTimer("enriched_cooldown", GetRandomWithVariance(TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.base, TUNING_MEDAL.MEDAL_ORIGIN_SMALL_TREE_GROW_TIME.random))
        end
    else--否则强制成长到下一形态
        inst.components.growable.need_medal_growth = false--设为false,强制催长
        inst.components.growable:DoGrowth()
    end
end
--强制催长、吸收
local function DoMedalMagicGrowth(inst)
    --施肥状态强制吸收
    if IsEnriched(inst) then
        inst.components.timer:StopTimer("enriched_cooldown")
        OnTimerDone(inst,{name = "enriched_cooldown"})
        return true
    --非最大形态强制生长
    elseif inst.components.growable and inst.components.growable.stage < 3 then
        inst.components.growable.need_medal_growth = false--设为false,强制催长
        return inst.components.growable:DoGrowth()
    end
end
--检查语句
local function inspect_tree(inst)
    return (inst:HasTag("stump") and "CHOPPED") or nil
end

local function onsave(inst, data)
    if inst:HasTag("stump") then
        data.stump = true
    end

    if inst.no_grow ~= nil then
        data.no_grow = inst.no_grow
    end

    if inst.buds then
        data.buds = inst.buds
    end
    if inst.buds_used then
        data.buds_used = inst.buds_used
    end

    data.supertall_growth_progress = inst.supertall_growth_progress
end

local function onload(inst, data)
    if data ~= nil then
        if data.stump then
            make_stump(inst)
            -- inst.AnimState:PlayAnimation(inst.anims.stump)
        end

        if not inst:IsValid() then
            return
        end

        inst.no_grow = data.no_grow
        if inst.no_grow then
            -- SetTall(inst)
            growth_stages[3].fn(inst)
            if inst.components.growable ~= nil then
                inst:RemoveComponent("growable")
            end
        end
        

        if data.buds then
            inst.buds = data.buds
        end

        if data.buds_used then
            inst.buds_used = data.buds_used
        end

        inst.supertall_growth_progress = data.supertall_growth_progress
    end
end

local function onloadpostpass(inst, newents, data)
    if not inst:HasTag("stump") then
        if IsEnriched(inst) then
            MakeEnriched(inst)

        elseif inst.supertall_growth_progress >= STAGES_TO_SUPERTALL then
            SpawnOriginTree(inst)
        end
    end

    if inst:IsValid() then --生成本源之树会移除inst,所以要判断下有效性
        showbuds(inst)
    end
end

local function OnEntitySleep(inst)
    inst:RemoveComponent("inspectable")
end

local function OnEntityWake(inst)
    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local function tree(name, stage, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("medal_origin_small_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        -- inst:SetPhysicsRadiusOverride(2.35)
        MakeObstaclePhysics(inst, .5)
        -- MakeWaterObstaclePhysics(inst, 0.80, 2, 0.75)

        inst:AddTag("ignorewalkableplatforms")
        inst:AddTag("shelter")
        inst:AddTag("plant")
        inst:AddTag("event_trigger")
        inst:AddTag("tree")
        inst:AddTag("small_origin_tree")
        inst:AddTag("no_force_grow")--禁用树肥

        local scale = 1.1
        inst.Transform:SetScale(scale, scale, scale)

        inst:SetPrefabName(tree_data.prefab_name)

        MakeSnowCoveredPristine(inst)

        -- inst.scrapbook_specialinfo = "OCEANTREE"
        -- inst.scrapbook_proxy = "oceantree_tall"
        -- inst.scrapbook_speechname = inst.prefab
        -- inst.scrapbook_anim = "sway1_loop"

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        stage = stage == 0 and math.random(1, 3) or stage

        local bank = "oceantree_"..growth_stages[stage].name
        local build = bank
        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)

        inst.sproutfn = Sprout
        inst.OnTimerDone = OnTimerDone
        inst.DoMedalMagicGrowth = DoMedalMagicGrowth

        inst.OnTreeGrowthOriginEssence = OnTreeGrowthOriginEssence
        inst.supertall_growth_progress = 0
        -- inst.no_grow = nil

        -- inst.falling_left = nil

        inst.anims = anims

        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)

        -------------------
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        -------------------
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        -------------------
        inst:AddComponent("lootdropper")

        ---------------------
        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        -- inst.components.growable.magicgrowable = true
        inst.components.growable.need_medal_growth = true--不能被造林学等方式强制催熟
        inst.components.growable:StartGrowing()

        -- inst:AddComponent("simplemagicgrower")
        -- inst.components.simplemagicgrower:SetLastStage(nil)--#inst.components.growable.stages)

        ---------------------

        inst:AddComponent("timer")

        ---------------------

        inst:AddComponent("hauntable")

        inst:ListenForEvent("on_collide", OnCollide)
        inst:ListenForEvent("timerdone", inst.OnTimerDone)

        ---------------------

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnLoadPostPass = onloadpostpass

        MakeSnowCovered(inst)

        MakeWaxablePlant(inst)

        ---------------------

        if data == "stump" then
            inst:AddTag("stump")
            inst:RemoveTag("shelter")

            -- inst:RemoveComponent("workable")
            -- inst:RemoveComponent("growable")
            -- inst:RemoveComponent("timer")
            -- inst:RemoveEventCallback("timerdone", inst.OnTimerDone)
            -- inst.AnimState:PlayAnimation(inst.anims.stump)
            -- inst.MiniMapEntity:SetIcon("medal_origin_small_tree_stump.tex")

            make_stump(inst)

            -- inst:DoTaskInTime(0, function()
            --     RemovePhysicsColliders(inst)
            -- end)
        else
			inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
            inst:DoTaskInTime(0, function()
                local x, _, z = inst.Transform:GetWorldPosition()
                if not TheWorld.Map:IsOceanAtPoint(x, 0, z) then
                    RemovePhysicsColliders(inst)
                    MakeObstaclePhysics(inst, .25)
                end
            end)
        end

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        inst.buds = {1,2,3,5,6,7}
        inst.buds_used = {}
        for i=1,7 do
            inst.AnimState:Hide("tree_bud"..i)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  tree("medal_origin_small_tree", 0),
        tree("medal_origin_small_tree_normal", 2),
        tree("medal_origin_small_tree_tall", 3),
        tree("medal_origin_small_tree_short", 1),
        tree("medal_origin_small_tree_stump", 0, "stump")
