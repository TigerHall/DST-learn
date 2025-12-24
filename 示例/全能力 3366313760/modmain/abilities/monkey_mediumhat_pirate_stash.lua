local Shapes = require("aab_utils/shapes")

AAB_AddCharacterRecipe("aab_monkey_mediumhat", { Ig("rope", 3), Ig("pigskin", 4), Ig("goldnugget", 10) }, {
    product = "monkey_mediumhat",
    image = "monkey_mediumhat.tex"
}, { "CHARACTER", "SEAFARING" })

STRINGS.RECIPE_DESC.MONKEY_MEDIUMHAT = "不可思议。它增加了找到宝藏的几率！"

----------------------------------------------------------------------------------------------------
local STASH_MAX = 5 --每个帽子能刷的上限

local function FindStashLocation(inst)
    local pos = inst:GetPosition()
    local map = TheWorld.Map
    for i = 1, 100 do
        local spawnpos = Shapes.GetRandomLocation(pos, 24, 44)
        if map:IsPassableAtPoint(spawnpos.x, spawnpos.y, spawnpos.z, false, true) then
            return spawnpos
        end
    end
end

local function ShouldRemoveItem(inst)
    return
        not inst.components.inventoryitem.canbepickedup or
        not inst.components.inventoryitem.cangoincontainer or
        inst.components.inventoryitem.canonlygoinpocket or
        inst:HasTag("personal_possession") or
        inst:HasTag("cursed")
end

local function ProcessLoot(item, stash, owner)
    if not item:HasTag("irreplaceable") and ShouldRemoveItem(item) then
        item:Remove()
        return
    end

    if owner ~= nil and owner.components.inventory ~= nil then
        owner.components.inventory:DropItem(item, true)
    end

    if not item:HasTag("irreplaceable") then
        stash:StashLoot(item)
    end
end

local function SendLootToStash(inst, stash)
    if inst.components.container ~= nil then
        for i = 1, inst.components.container.numslots do
            local item = inst.components.container.slots[i]

            if item ~= nil then
                --V2C: DropItem(item) does not drop whole stack
                --inst.components.container:DropItem(item)
                item = inst.components.container:DropItemBySlot(i, nil, true)

                ProcessLoot(item, stash)
            end
        end
    end

    if inst.components.inventoryitem ~= nil then
        ProcessLoot(inst, stash)
    elseif inst.components.inventory ~= nil then
        inst.components.inventory:ForEachItem(ProcessLoot, stash, inst)
    end
end

local function generateloot(stash)
    local function additem(name)
        local item = SpawnPrefab(name)
        SendLootToStash(item, stash)
    end

    local lootlist = {}

    for i = 1, math.random(2, 4) do
        table.insert(lootlist, "palmcone_scale")
    end

    for i = 1, math.random(2, 4) do
        table.insert(lootlist, "cave_banana")
    end

    if math.random() < 0.3 then
        for i = 1, math.random(2, 4) do
            table.insert(lootlist, "treegrowthsolution")
        end
    end

    if math.random() < 0.3 then
        for i = 1, math.random(2, 4) do
            table.insert(lootlist, "goldnugget")
        end
    end

    if math.random() < 0.5 then
        for i = 1, math.random(3, 6) do
            if math.random() < 0.3 then
                table.insert(lootlist, "meat_dried")
            end
        end
    end

    if math.random() < 0.5 then
        for i = 1, math.random(1, 3) do
            table.insert(lootlist, "bananajuice")
        end
    end

    --蓝图少刷点
    if math.random() < 0.2 then
        table.insert(lootlist, "pirate_flag_pole_blueprint")
    end

    if math.random() < 0.2 then
        table.insert(lootlist, "polly_rogershat_blueprint")
    end

    for i, loot in ipairs(lootlist) do
        additem(loot)
    end
end

local function FindTrackIndex(inst)
    local self = inst.components.entitytracker
    for i = 1, STASH_MAX do
        if not self:GetEntity("aab_stash" .. i) then
            return i
        end
    end
end

local function OnTimerDone(inst, data)
    if data.name == "aab_spawn_stash" then
        local index = FindTrackIndex(inst)
        if not index then --已经满了
            inst.components.timer:StartTimer("aab_spawn_stash", TUNING.TOTAL_DAY_TIME / 2)
            return
        end

        local pt = FindStashLocation(inst)
        if not pt then
            inst.components.timer:StartTimer("aab_spawn_stash", TUNING.TOTAL_DAY_TIME / 2)
            return
        end

        local stash = SpawnPrefab("pirate_stash")
        stash.Transform:SetPosition(pt.x, 0, pt.z)

        generateloot(stash)

        inst.components.entitytracker:TrackEntity("aab_stash" .. index, stash)

        inst.components.timer:StartTimer("aab_spawn_stash", TUNING.TOTAL_DAY_TIME - 60 + math.random(120))
    end
end

local function OnEquipped(inst, data)
    if data and data.owner and data.owner.components.locomotor then --给假人戴不行
        inst.components.timer:StopTimer("aab_spawn_stash")
        inst.components.timer:StartTimer("aab_spawn_stash", TUNING.TOTAL_DAY_TIME - 60 + math.random(120))
    end
end

local function OnUnequipped(inst, data)
    inst.components.timer:StopTimer("aab_spawn_stash")
end

AddPrefabPostInit("monkey_mediumhat", function(inst)
    if not TheWorld.ismastersim then return end

    -- inst.components.fueled:InitializeFuelLevel(TUNING.MONKEY_MEDIUM_HAT_PERISHTIME) --只能戴6天，要不要增加耐久呢

    if not inst.components.timer then
        inst:AddComponent("timer")
    end

    if not inst.components.entitytracker then
        inst:AddComponent("entitytracker")
    end

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("equipped", OnEquipped)
    inst:ListenForEvent("unequipped", OnUnequipped)
end)
