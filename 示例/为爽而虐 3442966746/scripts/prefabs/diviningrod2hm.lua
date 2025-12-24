-- 探测杖 
local assets = {
    Asset("ANIM", "anim/diviningrod.zip"),
    Asset("ANIM", "anim/swap_diviningrod.zip"),
    Asset("ANIM", "anim/diviningrod_fx.zip"),
}

local prefabs = {
    "dr_hot_loop",
    "dr_warmer_loop",
    "dr_warm_loop_2",
    "dr_warm_loop_1",
    "ash",
}

local EFFECTS = {
    hot = "dr_hot_loop",
    warmer = "dr_warmer_loop",
    warm = "dr_warm_loop_2",
    cold = "dr_warm_loop_1",
}

-- 距离
local DIVINING_DISTANCES = {
    {maxdist = 80, describe = "hot", pingtime = 0.5},
    {maxdist = 160, describe = "warmer", pingtime = 1},
    {maxdist = 320, describe = "warm", pingtime = 2},
    {maxdist = 600, describe = "cold", pingtime = 4},
}
local DIVINING_MAXDIST = 600
local DIVINING_DEFAULTPING = 5

-- 查找最近的发条生物
local function FindClosestChessMonster(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if not owner then return nil end

    local registry = TUNING.CHESSMONSTER_REGISTRY2HM or {}
    
    local closest = nil
    local closest_distsq = nil
    local ox, oy, oz = owner.Transform:GetWorldPosition()

    for guid, monster in pairs(registry) do
        if monster:IsValid() and not monster:IsInLimbo() then
            local mx, my, mz = monster.Transform:GetWorldPosition()
            local distsq = (ox - mx) * (ox - mx) + (oz - mz) * (oz - mz)
            if not closest_distsq or distsq < closest_distsq then
                closest = monster
                closest_distsq = distsq
            end
        end
    end

    return closest, closest_distsq
end

-- 检测目标距离
local function CheckTargetPiece(inst)
    if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner then
        local intensity = 0
        local closeness = nil
        local fxname = nil
        local target, distsq = FindClosestChessMonster(inst)
        local nextpingtime = DIVINING_DEFAULTPING

        if target ~= nil and distsq ~= nil then
            intensity = math.max(0, 1 - (distsq / (DIVINING_MAXDIST * DIVINING_MAXDIST)))

            for _, v in ipairs(DIVINING_DISTANCES) do
                closeness = v
                fxname = EFFECTS[v.describe]

                if v.maxdist and distsq <= v.maxdist * v.maxdist then
                    nextpingtime = closeness.pingtime
                    break
                end
            end
        end

        -- 台词
        if closeness ~= inst.closeness then
            inst.closeness = closeness
            local desc = inst.components.inspectable:GetDescription(inst.components.inventoryitem.owner)
            if desc then
                inst.components.inventoryitem.owner.components.talker:Say(desc)
            end
        end

        -- 特效 
        if fxname ~= nil then
            inst.fx = SpawnPrefab(fxname)
            if inst.fx then
                inst.fx.entity:AddFollower()
                inst.fx.Follower:FollowSymbol(inst.components.inventoryitem.owner.GUID, "swap_object", 80, -320, 0)
            end
        end

        -- 声音
        inst.SoundEmitter:KillSound("ping")
        inst.SoundEmitter:PlaySound("dontstarve/common/diviningrod_ping", "ping")
        inst.SoundEmitter:SetParameter("ping", "intensity", intensity)
        
        -- 持续检测循环
        inst.task = inst:DoTaskInTime(nextpingtime, CheckTargetPiece)
    end
end

local function onequip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:OverrideSymbol("swap_object", "swap_diviningrod", "swap_diviningrod")
    
    inst.closeness = nil
    -- 取消之前的任务
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task = inst:DoTaskInTime(0.5, CheckTargetPiece)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    
    if inst.fx ~= nil then
        if inst.fx:IsValid() then
            inst.fx:Remove()
        end
        inst.fx = nil
    end
    
    inst.closeness = nil
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

-- 检查状态描述
local function describe(inst)
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        if inst.closeness and inst.closeness.describe then
            return string.upper(inst.closeness.describe)
        end
        return "COLD"
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)


    inst.AnimState:SetBank("diviningrod")
    inst.AnimState:SetBuild("diviningrod")
    inst.AnimState:PlayAnimation("dropped")

    inst:AddTag("diviningrod2hm")
    inst:AddTag("nopunch")

    local swap_data = {sym_build = "swap_diviningrod", anim = "dropped"}
    MakeInventoryFloatable(inst, "large", 0.1, {0.8, 0.5, 0.8}, true, -30, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = describe

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"
    inst.components.inventoryitem.imagename = "diviningrod"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("tempequip2hm")
    inst.components.tempequip2hm.perishtime = TUNING.TOTAL_DAY_TIME * 10
    inst.components.tempequip2hm.remainingtime2hm = TUNING.TOTAL_DAY_TIME * 10
    inst.components.tempequip2hm.onperishreplacement = "ash"
    inst.components.tempequip2hm:BecomePerishable()

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("diviningrod2hm", fn, assets, prefabs)
