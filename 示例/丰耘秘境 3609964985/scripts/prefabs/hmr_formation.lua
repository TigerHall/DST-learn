local assets =
{
    Asset("ANIM", "anim/lightflier.zip"),
}

-- 编队相关的常量定义
local FORMATION_ROTATION_SPEED = 0.9    -- 编队旋转速度
local FORMATION_RADIUS = 10             -- 编队半径
local FORMATION_SEARCH_RADIUS = 100     -- 编队搜索半径
local FORMATION_MAX_SPEED = 10.5        -- 编队最大速度
local FORMATION_MAX_OFFSET = 0.4        -- 编队最大偏移量
local FORMATION_OFFSET_LERP = 0.2       -- 编队位置插值速度
local VALIDATE_FORMATION_FREQ = 1       -- 编队验证频率
local FIND_TARGET_MUSTTAGS = { "player" }  -- 必须是带"player"标签的目标
local FIND_TARGET_NOTAGS = { "playerghost" }  -- 不包括"playerghost"标签的目标

-- 生成新编队函数
local MakeFormation

-----------------------------------------------------------------------------------------
---[[编队领导者部分]]
-----------------------------------------------------------------------------------------

-- 处理编队解散的逻辑
local function onformationdisband(inst)
    if inst.components.formationleader.target ~= nil then
        inst.components.formationleader.target._hmr_formation = nil
    end
end

local function LeaderOnUpdate(inst)
    local leader = inst.components.formationleader
    if leader.target ~= nil and leader.target:IsValid() then
        local tx, ty, tz = leader.target.Transform:GetWorldPosition()

        local r = -(leader.target.Transform:GetRotation() / RADIANS)

        -- 计算目标的偏移位置
        local targetoffsetdistance = leader.target.components.locomotor.walkspeed * (leader.target.components.locomotor.wantstomoveforward and FORMATION_MAX_OFFSET or 0)
        local targetoffset_x = tx + math.cos(r) * targetoffsetdistance
        local targetoffset_z = tz + math.sin(r) * targetoffsetdistance

        -- 初始化偏移量并通过线性插值调整位置
        inst._offset.x = Lerp(inst._offset.x, targetoffset_x, FORMATION_OFFSET_LERP)
        inst._offset.z = Lerp(inst._offset.z, targetoffset_z, FORMATION_OFFSET_LERP)

        inst.Transform:SetPosition(inst._offset.x, ty, inst._offset.z)
    end
end

-- 验证编队的有效性
local function LeaderValidateFormation(inst)
    if inst.components.formationleader:GetFormationSize() <= 0 or
            inst.components.formationleader.target == nil or not inst.components.formationleader.target:IsValid() then
        inst.components.formationleader:DisbandFormation()
        inst:Remove()
    end

    -- 将外圈成员移入未满的内圈
    local leaders = {}
    local mx, my, mz = inst.Transform:GetWorldPosition()
    local formations = TheSim:FindEntities(mx, my, mz, 10, {"formationleader"})
    for _, formation in pairs(formations) do
        if formation.components.formationleader.target == inst.components.formationleader.target then
            table.insert(leaders, formation)
        end
    end

    if #leaders > 0 then
        -- 按照领导者年龄排序,年龄大的排在前面
        local sort = function(w1, w2)
            if w1.components.formationleader.age > w2.components.formationleader.age then
                return true
            end
        end
        table.sort(leaders, sort)

        for i = 2, #leaders do
            if leaders[i] == inst and
                    leaders[i].components.formationleader:GetFormationSize() > 0 and
                    not leaders[i - 1].components.formationleader:IsFormationFull()
            then
                local last_formation = next(inst.components.formationleader.formation)
                leaders[i].components.formationleader:OnLostFormationMember(last_formation)
                leaders[i - 1].components.formationleader:NewFormationMember(last_formation)
            end
        end
    end
end

-- 创建新的編隊
MakeFormation = function(inst, target, radius_override, rotation_speed_override)
    local leader = SpawnPrefab("formationleader")
    local x, y, z = inst.Transform:GetWorldPosition()
    leader.Transform:SetPosition(x, y, z)
    leader._offset = leader:GetPosition()

    leader.components.formationleader:SetUp(target, inst)  -- 设置首领的目标和成员

    target._hmr_formation = leader  -- 设置目标的编队标记
    leader.components.formationleader.ondisbandfn = onformationdisband  -- 设置解散时的回调

    -- 成员数量设置官方也没用到
    leader.components.formationleader.min_formation_size = 1
    leader.components.formationleader.max_formation_size = 5

    leader.components.formationleader.radius = radius_override or FORMATION_RADIUS  -- 设置编队半径
    leader.components.formationleader.thetaincrement = rotation_speed_override or FORMATION_ROTATION_SPEED  -- 设置旋转速度

    leader.components.formationleader.onupdatefn = LeaderOnUpdate  -- 设置更新函数

    leader:DoPeriodicTask(VALIDATE_FORMATION_FREQ, LeaderValidateFormation)  -- 定期校验编队
end

-----------------------------------------------------------------------------------------
---[[编队成员部分]]
-----------------------------------------------------------------------------------------

-- 跟随者更新逻辑
local function FollowerOnUpdate(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()
    local dist = VecUtil_Length(targetpos.x - x, targetpos.z - z)

    inst.components.locomotor.walkspeed = math.min(dist * 8, FORMATION_MAX_SPEED)
    inst:FacePoint(targetpos.x, 0, targetpos.z)
    if inst.updatecomponents[inst.components.locomotor] == nil then
        inst.components.locomotor:WalkForward(true)
    end
end

-- 离开编队时的处理逻辑
local function OnLeaveFormation(inst, leader)
    if not inst.already_remove then
        inst.already_remove = true
        inst:DoTaskInTime(2, function()
            if not inst.components.formationfollower.in_formation or inst.components.formationfollower.formationleader == nil then
                inst:Remove()
            end
        end)
    end
end

-- 进入编队时的处理逻辑
local function OnEnterFormation(inst, leader)
    inst.components.locomotor:Stop()
    inst:AddTag("NOBLOCK")
end

-----------------------------------------------------------------------------------------
---[[初始化（必执行）]]
-----------------------------------------------------------------------------------------
local function SetLeader(inst, target, data)
    if target == nil or not target:IsValid() or not target:HasTag("player") then
        return
    end

    local leaders_for_target = {}
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local leaders = TheSim:FindEntities(tx, ty, tz, 10, {"formationleader"})
    if #leaders > 0 then
        for _, leader in pairs(leaders) do
            if leader.components.formationleader.target == target then
                table.insert(leaders_for_target ,leader)
            end
        end
    end

    if not inst.components.formationfollower:SearchForFormation(leaders_for_target) then  -- 寻找当前编队
        MakeFormation(inst, target, data.radius, data.rotation_speed)  -- 创建新的编队
    end

    FORMATION_ROTATION_SPEED = data.rotation_speed or FORMATION_ROTATION_SPEED
    FORMATION_RADIUS = data.radius or FORMATION_RADIUS
    FORMATION_SEARCH_RADIUS = data.search_radius or FORMATION_SEARCH_RADIUS
    FORMATION_MAX_SPEED = data.max_speed or FORMATION_MAX_SPEED

    if data.initfn ~= nil then
        data.initfn(inst, target)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeGhostPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(1, .5)

    inst.AnimState:SetBank("lightflier")
    inst.AnimState:SetBuild("lightflier")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetLightOverride(1)

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1.8)
    inst.Light:SetColour(237 / 255, 237 / 255, 209 / 255)
    inst.Light:Enable(true)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.LIGHTFLIER.WALK_SPEED
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("inspectable")

    inst:AddComponent("follower")

    -- formationleader要求
    inst:AddComponent("combat")

    inst:AddComponent("formationfollower")
    inst.components.formationfollower.searchradius = FORMATION_SEARCH_RADIUS
    inst.components.formationfollower.formation_type = "lightflier"
    inst.components.formationfollower.onupdatefn = FollowerOnUpdate
    inst.components.formationfollower.onleaveformationfn = OnLeaveFormation
    inst.components.formationfollower.onenterformationfn = OnEnterFormation

    inst.SetLeader = SetLeader

    return inst
end

return Prefab("hmr_formation_common", fn, assets)