local assets =
{
    Asset("ANIM", "anim/hmr_junkpile.zip")
}

local function MakeJunkPile(name, data)
    local function OnStartPicking(inst, doer)
        inst.SoundEmitter:PlaySound(data.sound, "hmr_junkpile")
        inst.AnimState:PlayAnimation("shake_"..data.anim, true)

        inst:DoTaskInTime(FRAMES * 60, function()
            inst.SoundEmitter:KillSound("hmr_junkpile")
            inst.AnimState:PlayAnimation("idle_"..data.anim)
        end)
    end

    local function OnPickedFn(inst, digger)
        inst.components.lootdropper:DropLoot()
        inst.AnimState:PlayAnimation("break_"..data.anim)
        inst.SoundEmitter:KillSound("hmr_junkpile")
        local fx = SpawnPrefab("junk_break_fx")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, data.radius)

        inst.MiniMapEntity:SetIcon("junk_pile.png")

        inst.AnimState:SetBank("hmr_junkpile")
        inst.AnimState:SetBuild("hmr_junkpile")
        inst.AnimState:PlayAnimation("idle_".. data.anim)
        local color = 0.4 + math.random() * 0.5
        inst.AnimState:SetMultColour(color, color + 0.1, color, 1)
        local scale = 0.8 + math.random() * 0.4
        inst.AnimState:SetScale(scale, scale)

        inst:AddTag("junk_pile")
        inst:AddTag("NPC_workable")
        inst:AddTag("pickable_rummage_str")  -- 使用“翻找”动作名称

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        data.lootfn(inst)

        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil, 0)
        inst.components.pickable.onpickedfn = OnPickedFn
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

        inst:ListenForEvent("startlongaction", OnStartPicking)

        MakeSnowCovered(inst)
        MakeHauntableWork(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end


local RECIPESLIST = {}
for k, v in pairs(AllRecipes) do
    if v.placer == nil then
        table.insert(RECIPESLIST, v.product)
    end
end

local CLOTHINGRECIPES = CRAFTING_FILTERS.CLOTHING.recipes
local TOOLSRECIPES = CRAFTING_FILTERS.TOOLS.recipes

-- 初级产物：配方物品
local function GenerateLowLoot(inst)
    local loot = {}
    for i = 1, math.random(1, 3) do
        table.insert(loot, RECIPESLIST[math.random(1, #RECIPESLIST)])
    end
    inst.components.lootdropper:SetLoot(loot)
end

-- 中级产物：精炼材料
local function GenerateMidLoot(inst)
    local list = {
        "rope", "boards", "cutstone", "papyrus", "transistor", "livinglog", "waxpaper", "beeswax",
        "marblebean", "bearger_fur", "nightmarefuel", "purplegem", "moonrockcrater"
    }
    local loot = {}
    for i = 1, math.random(2, 4) do
        table.insert(loot, list[math.random(1, #list)])
    end
    if math.random() <= 0.001 then
        table.insert(loot, "krampus_sack")
    end
    inst.components.lootdropper:SetLoot(loot)
end

-- 高级常规产物：配方蓝图
local function GenerateHighNormalLoot(inst)
    local loot = {}
    for i = 1, math.random(1, 3) do
        table.insert(loot, tostring(RECIPESLIST[math.random(1, #RECIPESLIST)]).."_blueprint")
    end
    inst.components.lootdropper:SetLoot(loot)
end

-- 高级玩具产物：服装
local function GenerateHighToyLoot(inst)
    local loot = {}
    for i = 1, math.random(1, 2) do
        table.insert(loot, CLOTHINGRECIPES[math.random(1, #CLOTHINGRECIPES)])
    end
    if math.random() <= 0.03 then
        table.insert(loot, "krampus_sack")
    end
    inst.components.lootdropper:SetLoot(loot)
end

-- 高级玩具产物：工具
local function GenerateHighWagpunkBitsLoot(inst)
    local loot = {}
    for i = 1, math.random(2, 4) do
        table.insert(loot, TOOLSRECIPES[math.random(1, #TOOLSRECIPES)])
    end
    if math.random() <= 0.08 then
        table.insert(loot, "chestupgrade_stacksize")
    end
    inst.components.lootdropper:SetLoot(loot)
end


local data = {
    low = {
        anim = "low",
        lootfn = GenerateLowLoot,
        sound = "qol1/wagstaff_ruins/rummagepile_sml",
        shaketimes = 4,
        radius = 0.3
    },
    mid = {
        anim = "mid",
        lootfn = GenerateMidLoot,
        sound = "qol1/wagstaff_ruins/rummagepile_med",
        shaketimes = 4,
        radius = 0.5
    },
    high_1 = {
        anim = "high_1",
        lootfn = GenerateHighNormalLoot,
        sound = "qol1/wagstaff_ruins/rummagepile_lrg",
        shaketimes = 8,
        radius = 1
    },
    high_2 = {
        anim = "high_2",
        lootfn = GenerateHighToyLoot,
        sound = "qol1/wagstaff_ruins/rummagepile_lrg",
        shaketimes = 8,
        radius = 1
    },
    high_3 = {
        anim = "high_3",
        lootfn = GenerateHighWagpunkBitsLoot,
        sound = "qol1/wagstaff_ruins/rummagepile_lrg",
        shaketimes = 8,
        radius = 1
    }
}

return  MakeJunkPile("hmr_junkpile_low",                 data.low),
        MakeJunkPile("hmr_junkpile_mid",                 data.mid),
        MakeJunkPile("hmr_junkpile_high_normal",         data.high_1),
        MakeJunkPile("hmr_junkpile_high_toy",            data.high_2),
        MakeJunkPile("hmr_junkpile_high_wagpunk_bits",   data.high_3)